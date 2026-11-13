#!/usr/bin/env python3
"""C3: a module over the C API, with typed handles, methods and optionals.

Based on gen_cpp.py of Raven's tools/bindgen, and written against the same
reader of the headers (cparse.py). It can be used two ways:

  - as one more generator of Raven's bindgen (python tools/bindgen/bindgen.py c3);
    it writes bindings/c3/raven.c3l/src/;
  - on its own:

        python tools/bindgen/gen_c3.py                  clones Raven, writes bindings/c3/raven.c3l/src
        python tools/bindgen/gen_c3.py path/to/Raven    uses a checkout of Raven
        python tools/bindgen/gen_c3.py --ref v0.2.3     clones that tag or branch
        python tools/bindgen/gen_c3.py --check          fails when the output is stale
        python tools/bindgen/gen_c3.py -o some/dir      writes somewhere else

It writes two files:

  raven_c.c3   module raven::c   the whole C API as it is, 1:1: every type,
                                 constant and function of the headers, the
                                 functions as `extern fn` bound by @cname,
                                 named in snake_case as C3 wants them (Rinit
                                 is r_init, Rbutton_set_text r_button_set_text)
  raven.c3     module raven      the C3 API: types, constants, faults, typed
                                 handles with methods, Optionals, slices,
                                 vectors, and memory released the C3 way

cparse.py leaves out the headers that "only make sense from C" (Vulkan,
backends): the C3 binding reads them too, and raven_web.h, whose functions are
part of the same library, so that raven::c is the whole library.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

RAVEN_REPOSITORY = "https://github.com/oscar-soirey/Raven"

# Headers read on top of the ones cparse.py reads (paths from the root of Raven).
# raven_emscripten.h is not one of them: it only exists in the WebAssembly build.
EXTRA_HEADERS = ["include/raven/raven_vulkan.h", "include/raven/raven_backend.h", "web/include/raven_web.h"]
NOT_BOUND_HEADERS = ("raven_emscripten.h",)

# ---------------------------------------------------------------------------
# What becomes a type with methods (as the classes of gen_cpp.py)
# ---------------------------------------------------------------------------

# prefix of the C functions -> a widget type. More are found in RWidgetType:
# every R_WIDGET_X that has Rx_ functions gets one.
WIDGET_PREFIXES = [
    "label", "button", "checkbox", "slider", "progress_bar", "image", "text_input", "spin_box", "combo_box", "separator",
    "list_view", "tree_view", "menu_item", "menu", "panel", "uniform_grid", "grid", "border", "size_box", "spacer", "scroll_box",
    "splitter", "switcher", "tab_view", "expander", "text_editor", "header_bar", "dock_area", "island", "file_browser",
    "viewport", "custom", "web_view",
]
# R_WIDGET_X whose prefix is not the one of the C functions
WIDGET_TYPE_ALIASES = {"progressbar": "progress_bar"}
# widget types with no functions of their own, made as another widget type
WIDGET_TYPE_CLASS = {"vbox": "panel", "hbox": "panel", "wrap_box": "panel"}
# handles that are not widgets
HANDLE_PREFIXES = ["window", "tree_item", "font", "texture", "timer", "xml_document", "xml_node", "tray", "shader"]
# free functions returning a handle whose type their name does not tell
RETURN_CLASS = {"Rvulkan_texture_create_from_image_view": "Texture", "Rvulkan_texture_create_shared": "Texture"}

# C names whose C3 name would hide a type of the standard library of C3
# (std::core is always imported: `Allocator a = mem;` must keep working)
TYPE_RENAMES = {"RAllocator": "MemoryAllocator"}

# ---------------------------------------------------------------------------
# Error handling: which functions report a failure, turned into an Optional
# ---------------------------------------------------------------------------

# int functions where R_FALSE is a failure (and not an answer): void? in C3
FALLIBLE_BOOL = {
    "Rinit", "Rinit_ex", "Ropen_url", "Rwindow_set_theme", "Rtheme_use", "Rwidget_set_theme", "Rdock_area_load_layout",
    "Rcolor_picker_set_hex", "Rtimeline_set_track_style", "Rnode_graph_set_node_style", "Rfile_browser_set_directory",
    "Rviewport_set_native", "Rxml_register_tag", "Rxml_node_move", "Rfile_write", "Rfile_register_memory",
}
# Rid functions where R_INVALID_ID is a failure: Type? in C3. Also every
# create/load/parse function whose documentation says it returns R_INVALID_ID
# and every one that reads a file, XML, SVG or pixels.
FALLIBLE_ID = {"Rtray_create", "Rxml_document_parse", "Rxml_document_load"}
FALLIBLE_ID_NAME = re.compile(r"_(from_file|from_xml|from_svg|from_pixels|load|parse)")
NOT_FALLIBLE_ID = {"Rwidget_create"}

# int parameters that are R_TRUE / R_FALSE: bool in the methods
BOOL_PARAMS = {
    "enabled", "visible", "pressed", "read_only", "tint", "expanded", "repeat", "closable", "checked", "selected",
    "multiple", "deletable", "topmost", "shown", "inside", "eraser", "dark", "hit_testable", "clip", "focusable", "wrap",
    "selectable", "password", "whole_tree", "native", "checkable", "sortable", "descending", "striped", "copy",
    "transparent", "modal", "resizable", "animated", "active", "visible_only", "recursive",
}
# int functions that answer yes or no: bool in C3
BOOL_RETURN_PREFIX = ("is_", "has_", "can_", "wants_", "was_", "contains_")
BOOL_RETURNS = {"Rwait_frame", "Rdraw_frame"}

# a parameter giving the length of the pointers before it: they become one slice each
LENGTH_PARAM = re.compile(r"^(count|size|data_size|\w+_count)$")
# kinds of parameters (cparse.classify) read as arrays
ARRAY_KINDS = ("carray", "cbytes", "cptr", "cstr_array", "cstruct_ptr")

# ---------------------------------------------------------------------------
# Macros of the headers (#define with parameters), written in C3
# ---------------------------------------------------------------------------

# name -> the C3 macro of raven::c. A new macro in the headers is reported.
C_MACROS = {
    "R_ID_INDEX": ["macro Ruint r_id_index(Rid id) => id & 0xFFFFF;"],
    "Rerror_check": [
        "macro void r_error_check()",
        "{",
        "\tchar* detail = null;",
        "\tRSeverity severity = R_SEVERITY_WEAK_WARNING;",
        "\tRError error = r_error_get_last(&detail, &severity);",
        "\tif (error != R_NO_ERROR)",
        "\t{",
        "\t\tio::printfn(\"[Raven] %s | %s | %s | %s:%d\", (ZString)r_error_to_string(error),",
        "\t\t\t(ZString)r_severity_to_string(severity), detail ? (ZString)detail : (ZString)\"\", $$FILE, $$LINE);",
        "\t}",
        "}",
    ],
}

# ---------------------------------------------------------------------------
# Names
# ---------------------------------------------------------------------------

KEYWORDS = {
    "alias", "asm", "assert", "attrdef", "bitstruct", "bool", "break", "case", "catch", "char", "const", "constset",
    "continue", "def", "default", "defer", "distinct", "do", "double", "else", "enum", "excuse", "extern", "false",
    "fault", "faultdef", "float", "float16", "float128", "fn", "for", "foreach", "foreach_r", "if", "import", "in",
    "inline", "inout", "int", "int128", "ichar", "iptr", "isz", "sz", "long", "macro", "module", "nextcase", "null",
    "out", "return", "short", "static", "struct", "switch", "tlocal", "true", "try", "typedef", "typeid", "uint",
    "uint128", "ulong", "union", "uptr", "usz", "ushort", "var", "void", "while", "any", "lengthof", "interface",
    "bfloat", "self", "c",
}

SCALAR = {"int": "CInt", "float": "float", "double": "double", "char": "char", "size_t": "usz", "uint64": "ulong",
          "uintptr": "uptr", "uint32": "uint", "uint8": "char", "id": "Id"}


def safe(name):
    name = name[0].lower() + name[1:] if name[:1].isupper() else name
    return name + "_" if name in KEYWORDS else name


def snake_ident(name):
    """CreateSurface -> create_surface (C3 wants members and parameters in snake_case)."""
    return re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", name).lower()


def ident(name):
    """The name of a parameter or a member in C3."""
    return safe(snake_ident(name))


def pascal(prefix):
    return "".join(part.capitalize() for part in prefix.split("_"))


def type_name(cname):
    """RWidgetType -> WidgetType"""
    if cname in TYPE_RENAMES:
        return TYPE_RENAMES[cname]
    return cname[1:] if cname.startswith("R") and cname[1:2].isupper() else cname


def type_snake(name):
    """ShaderLook -> shader_look"""
    return "_".join(w.lower() for w in re.findall(r"[A-Z][a-z0-9]*", name))


def c_function(function_name):
    """The name of a C function in raven::c: in snake_case, since a C3 function
    cannot start with a capital: Rinit is r_init, Rbutton_set_text r_button_set_text."""
    if function_name[:1].isupper():
        return function_name[0].lower() + "_" + snake_ident(function_name[1:])
    return snake_ident(function_name)


def snake(function_name):
    """Rbutton_set_text -> button_set_text"""
    return function_name[1:] if function_name.startswith("R") else function_name


def constant_name(cname):
    return re.sub(r"^(RAVEN_|R_)", "", cname)


def enum_member_names(enum):
    """{C name: C3 name} of the items of an enumeration, without their common prefix."""
    names = [item for item, _, _ in enum.items]
    words = [n.split("_") for n in names]
    common = []
    if len(names) > 1:
        for group in zip(*words):
            if len(set(group)) != 1:
                break
            common.append(group[0])
        # never the whole name of an item
        while common and any(len(w) == len(common) for w in words):
            common.pop()
    prefix = "_".join(common) + "_" if common else ""
    if prefix in ("", "R_"):
        # R_NO_ERROR, R_ERROR_XML...: the prefix of the type, where most items have it
        type_words = re.findall(r"[A-Z][a-z0-9]*", type_name(enum.name))
        for count in range(len(type_words), 0, -1):
            candidate = "R_" + "_".join(w.upper() for w in type_words[:count]) + "_"
            if sum(n.startswith(candidate) and len(n) > len(candidate) for n in names) * 2 > len(names):
                prefix = candidate
                break
    result = {}
    for name in names:
        short = name[len(prefix):] if prefix and name.startswith(prefix) and len(name) > len(prefix) else constant_name(name)
        if short[:1].isdigit():
            # R_KEY_0 -> KEY_0
            short = (prefix.rstrip("_").split("_")[-1] if prefix else "N") + "_" + short
        result[name] = short
    if len(set(result.values())) != len(result):
        raise ValueError("%s: two items have the same name in C3" % enum.name)
    return result


# ---------------------------------------------------------------------------
# Documentation
# ---------------------------------------------------------------------------

def doc_text(doc):
    """
    The lines of a documentation comment of the headers, as plain text: the
    description and what is returned, without the @param lines (the names are
    in the signature) and without any @ that C3 would read as a contract.
    """
    if not doc:
        return []
    lines = []
    skipping = False
    for raw in doc.split("\n"):
        line = raw.rstrip()
        stripped = line.strip()
        tag = re.match(r"@(\w+)\s*(.*)", stripped)
        if tag:
            skipping = False
            name, rest = tag.groups()
            if name == "return":
                line = "Returns " + rest if rest else ""
            elif name == "deprecated":
                line = "Deprecated" + (": " + rest if rest else ".")
            else:
                skipping = True             # @param and its continuation lines
                continue
        elif skipping:
            if stripped:
                continue
            skipping = False
        line = line.replace("*>", "* >").replace("<*", "< *").replace("/*", "/ *").replace("*/", "* /")
        if line.lstrip().startswith("@"):
            line = line.replace("@", "", 1)
        lines.append(line)
    while lines and not lines[-1].strip():
        lines.pop()
    while lines and not lines[0].strip():
        lines.pop(0)
    return lines


def doc_block(doc, indent="", extra=None):
    """A C3 documentation comment, <* ... *>, from one of the headers (and `extra`, a line of the binding)."""
    lines = doc_text(doc)
    if extra:
        lines = lines + [extra]
    if not lines:
        return []
    if len(lines) == 1:
        return ["%s<* %s *>" % (indent, lines[0].strip())]
    return ["%s<*" % indent] + [("%s %s" % (indent, line)).rstrip() for line in lines] + ["%s*>" % indent]


# the C types as they are, for raven::c
C_BASE = {"int": "CInt", "float": "float", "double": "double", "char": "char", "size_t": "usz", "uint64_t": "ulong",
          "uintptr_t": "uptr", "intptr_t": "iptr", "uint32_t": "uint", "uint8_t": "char", "void": "void"}


# ---------------------------------------------------------------------------
# The headers: those cparse.py skips, and what it leaves out of the others
# ---------------------------------------------------------------------------

def default_root():
    return os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def header_paths(root):
    """Every header of the library the binding covers, in the order of Raven.h."""
    include = os.path.join(root, "include")
    order = re.findall(r'#include "raven/(\w+\.h)"', open(os.path.join(include, "Raven.h"), encoding="utf-8").read())
    paths = [os.path.join(include, "raven", h) for h in order if h not in NOT_BOUND_HEADERS]
    for rel in EXTRA_HEADERS:
        path = os.path.join(root, *rel.split("/"))
        if os.path.exists(path) and path not in paths:
            paths.append(path)
    return paths


def known_values(api):
    known = {n: v for n, k, v in api.defines if k != "str"}
    for e in api.enums:
        for item, value, _ in e.items:
            known[item] = value
    return known


def full_api(api, root):
    """
    A copy of `api` with the headers cparse.py leaves out (EXTRA_HEADERS).
    `api` itself is shared with the other generators of bindgen.py and stays
    as it is.
    """
    import cparse
    full = cparse.Api()
    full.enums, full.structs, full.opaque = list(api.enums), list(api.structs), list(api.opaque)
    full.callbacks, full.functions, full.defines = list(api.callbacks), list(api.functions), list(api.defines)
    full.version = api.version
    parsed = {f.header for f in api.functions}
    known = known_values(api)
    work = tempfile.mkdtemp(prefix="gen_c3-")
    try:
        for rel in EXTRA_HEADERS:
            path = os.path.join(root, *rel.split("/"))
            if not os.path.exists(path) or os.path.basename(path) in parsed:
                continue
            # raven_web.h names RAVEN_API RAVEN_WEB_API ("part of the Raven library itself")
            text = open(path, encoding="utf-8").read().replace("RAVEN_WEB_API", "RAVEN_API")
            copy = os.path.join(work, os.path.basename(path))
            with open(copy, "w", encoding="utf-8") as handle:
                handle.write(text)
            cparse.parse_header(copy, full, known)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return full


class Scan:
    def __init__(self):
        self.marks = {}         # enum -> [(R_WIDGET_LAST_, value)]: the end marks cparse drops
        self.constants = []     # [(name, value, doc)]: defines computed from the marks (R_COLOR_COUNT)
        self.macros = {}        # name -> doc: the defines with parameters
        self.fnptrs = {}        # (struct, field) -> (ret, [Param]): the function pointers of the structures


def scan_headers(paths, api):
    """What cparse.py does not keep of the headers (see Scan)."""
    from cparse import clean_doc, evaluate, normalize_type, split_params
    scan = Scan()
    known = known_values(api)
    defined = {n for n, _, _ in api.defines}
    sources = []
    for path in paths:
        source = open(path, encoding="utf-8").read()
        comments = []

        def keep(match):
            comments.append((match.start(), match.end(), match.group(0)))
            return " " * (match.end() - match.start())

        code = re.sub(r"/\*.*?\*/", keep, source, flags=re.S)
        code = re.sub(r"//[^\n]*", lambda m: " " * len(m.group(0)), code)
        code = code.replace("\\\n", "  ")
        sources.append((code, comments))

        for match in re.finditer(r"typedef\s+enum\s+\w*\s*\{(.*?)\}\s*(\w+)\s*;", code, flags=re.S):
            value = -1
            for entry in match.group(1).split(","):
                entry = entry.strip()
                if not entry:
                    continue
                if "=" in entry:
                    item, expr = entry.split("=", 1)
                    item = item.strip()
                    value = evaluate(expr, known)
                else:
                    item = entry
                    value += 1
                known[item] = value
                if item.endswith("_"):
                    scan.marks.setdefault(match.group(2), []).append((item, value))

        for match in re.finditer(r"typedef\s+struct\s+\w*\s*\{(.*?)\}\s*(\w+)\s*;", code, flags=re.S):
            for field in re.finditer(r"([\w\s\*]+?)\(\s*\*\s*(\w+)\s*\)\s*\((.*?)\)\s*;", match.group(1), flags=re.S):
                scan.fnptrs[(match.group(2), field.group(2))] = (normalize_type(field.group(1)), split_params(field.group(3)))

    def doc_before(comments, code, position):
        for start, end, text in reversed(comments):
            if end <= position:
                if code[end:position].strip() == "" and text.startswith("/**"):
                    return clean_doc(text)
                return ""
        return ""

    for code, comments in sources:
        for match in re.finditer(r"^[ \t]*#[ \t]*define[ \t]+(R_[A-Z0-9_]+|RAVEN_[A-Z0-9_]+)[ \t]+(.+)$", code, flags=re.M):
            name = match.group(1)
            if name in defined or name.endswith("_H") or name in ("RAVEN_API", "RAVEN_WEB_API"):
                continue
            try:
                value = evaluate(match.group(2), known)
            except (ValueError, SyntaxError, NameError):
                continue
            known[name] = value
            defined.add(name)
            scan.constants.append((name, value, doc_before(comments, code, match.start())))
        for match in re.finditer(r"^[ \t]*#[ \t]*define[ \t]+(R\w+)\(", code, flags=re.M):
            scan.macros[match.group(1)] = doc_before(comments, code, match.start())
    return scan


# ---------------------------------------------------------------------------
# The generator
# ---------------------------------------------------------------------------

def generate(api, module="raven", root=None):
    from cparse import classify

    root = root or default_root()
    scan = Scan()
    if os.path.exists(os.path.join(root, "include", "Raven.h")):
        api = full_api(api, root)
        scan = scan_headers(header_paths(root), api)

    unknown_macros = set(scan.macros) - set(C_MACROS)
    if unknown_macros:
        print("gen_c3: macros of the headers with no C3 version (C_MACROS): %s" % ", ".join(sorted(unknown_macros)),
              file=sys.stderr)

    def kind(ctype):
        if ctype == "intptr_t":
            return ("scalar", "intptr")
        return classify(ctype, api)

    flag_enums = []
    for e in api.enums:
        if e.flags:
            stem = re.sub(r"(Flags|Buttons|Button|Modifier)$", "", type_name(e.name))
            stem_snake = "_".join(w.lower() for w in re.findall(r"[A-Z][a-z0-9]*", stem))
            flag_enums.append((type_name(e.name), stem_snake))

    def flag_type(name, context):
        """The flags constset a Ruint holds, from its name and the one of its function or structure."""
        context = re.sub(r"^R(?=[a-z])", "", context)        # Rwindow_create -> window_create
        context = "_".join(w.lower() for w in re.findall(r"[A-Z]?[a-z0-9]+|[A-Z]+(?![a-z])", context))
        suffix = {"flags": ("Flags",), "buttons": ("Button", "Buttons"), "modifiers": ("Modifier",)}.get(name)
        if not suffix:
            return None
        best = None
        for enum_name, stem in flag_enums:
            if enum_name.endswith(suffix) and (stem == "" or re.search(r"(^|_)%s(_|$)" % stem, context)):
                if best is None or len(stem) > len(best[1]):
                    best = (enum_name, stem)
        return best[0] if best else None

    def c3_type(ctype, name=None, context=""):
        if ctype == "Ruint" and name:
            flags = flag_type(name, context)
            if flags:
                return flags
        k, detail = kind(ctype)
        if k == "void":
            return "void"
        if k == "scalar":
            return "iptr" if detail == "intptr" else SCALAR[detail]
        if k in ("enum", "callback", "struct"):
            return type_name(detail)
        if k in ("fnptr", "ptr", "cptr"):
            return "void*"
        if k in ("cstr", "owned_str"):
            return "ZString"
        if k in ("cstr_out", "cstr_array"):
            return "ZString*"
        if k in ("bytes", "cbytes"):
            return "char*"
        if k == "out":
            return "%s*" % (SCALAR[detail[1]] if detail[0] == "scalar" else type_name(detail[1]))
        if k == "carray":
            return "%s*" % SCALAR[detail]
        if k in ("struct_ptr", "cstruct_ptr", "opaque_ptr"):
            return "%s*" % type_name(detail)
        raise ValueError(ctype)

    def ret_type(f):
        """Rwindow_get_modifiers returns Modifier, Rshader_get_flags ShaderFlags."""
        return c3_type(f.ret, f.name.split("_")[-1], f.name)

    c_named = ({"Rid", "Ruint"} | {e.name for e in api.enums} | {s.name for s in api.structs}
               | {cb.name for cb in api.callbacks} | set(api.opaque))
    enum_names = {e.name for e in api.enums}

    def c_type(ctype, qualifier="", resolve=False):
        """
        The C type as it is, for raven::c: Rid, RWidgetType, const char* is char*.
        With a qualifier (c::), the same type named from the module raven; with
        resolve, the type it is an alias of (CInt for an enumeration).
        """
        if ctype == "fnptr":
            return "void*"
        bare = re.sub(r"\bconst\b", "", ctype).replace(" ", "")
        stars = len(bare) - len(bare.rstrip("*"))
        base = bare.rstrip("*")
        if base in C_BASE:
            name = C_BASE[base]
        elif resolve and base in ("Rid", "Ruint"):
            name = "uint"
        elif resolve and base in enum_names:
            name = "CInt"
        elif base in c_named:
            name = qualifier + base
        else:
            raise ValueError("no C3 type for the C type '%s'" % ctype)
        return name + "*" * stars

    def is_struct_value(ctype):
        return kind(ctype)[0] == "struct"

    def to_c(expr, c3t, ctype):
        """expr, of the C3 type c3t, as the C type of raven::c."""
        if c3t == c_type(ctype, "c::", resolve=True):
            return expr
        if is_struct_value(ctype):
            return "bitcast(%s, %s)" % (expr, c_type(ctype, "c::"))
        return "(%s)%s" % (c_type(ctype, "c::"), expr)

    def from_c(expr, c3t, ctype):
        """expr, a value of raven::c of the C type ctype, as the C3 type c3t."""
        if c3t == c_type(ctype, "c::", resolve=True):
            return expr
        if is_struct_value(ctype):
            return "bitcast(%s, %s)" % (expr, c3t)
        return "(%s)%s" % (c3t, expr)

    def fnptr_alias(struct_name, field_name):
        """The name of the function pointer type of a member: RAllocator.alloc -> RAllocatorAllocFn."""
        return struct_name + pascal(snake_ident(field_name)) + "Fn"

    function_names = {f.name for f in api.functions}

    # ---- the widget types: those of gen_cpp.py, and every R_WIDGET_X with functions
    widget_prefixes = list(WIDGET_PREFIXES)
    widget_enum = api.enum("RWidgetType")
    widget_type_items = {}
    if widget_enum:
        for item, _, _ in widget_enum.items:
            prefix = item[len("R_WIDGET_"):].lower()
            prefix = WIDGET_TYPE_ALIASES.get(prefix, prefix)
            widget_type_items[prefix] = item
            if prefix not in widget_prefixes and any(n.startswith("R%s_" % prefix) for n in function_names):
                widget_prefixes.append(prefix)
    handle_prefixes = list(HANDLE_PREFIXES)
    all_prefixes = sorted(widget_prefixes + handle_prefixes + ["widget", "slot"], key=len, reverse=True)

    def class_of(function_name):
        body = function_name[1:]
        for prefix in all_prefixes:
            if body.startswith(prefix + "_"):
                return prefix, body[len(prefix) + 1:]
        return None

    class_name = {p: pascal(p) for p in widget_prefixes + handle_prefixes}
    class_name["widget"] = "Widget"
    class_name["slot"] = "Widget"

    # every name of a type must be one
    taken = {}
    for what, names in (("enum", [type_name(e.name) for e in api.enums]),
                        ("struct", [type_name(s.name) for s in api.structs]),
                        ("opaque", [type_name(o) for o in api.opaque]),
                        ("callback", [type_name(c.name) for c in api.callbacks]),
                        ("handle", sorted(set(class_name.values()))),
                        ("base", ["Id", "Error", "Pixels"])):
        for name in names:
            if name in taken and not (name == "Error" and taken[name] == "enum"):
                raise ValueError("the C3 type %s is both a %s and a %s" % (name, taken[name], what))
            taken[name] = what

    def struct_method(f):
        """Rspring_kick(RSpring* spring, ...) is a method of Spring: (struct name, method name), or None."""
        if not f.params:
            return None
        k, detail = kind(f.params[0].ctype)
        if k not in ("struct_ptr", "cstruct_ptr"):
            return None
        stem = type_snake(type_name(detail)) + "_"
        if snake(f.name).startswith(stem):
            return detail, snake(f.name)[len(stem):]
        return None

    by_class = {}
    free = []
    painter = []
    struct_methods = []
    for f in api.functions:
        owner = class_of(f.name)
        method = struct_method(f)
        if f.params and f.params[0].ctype == "RPainter*":
            painter.append(f)
        elif method:
            struct_methods.append((f, method[0], method[1]))
        elif owner:
            by_class.setdefault(owner[0], []).append((f, owner[1]))
        else:
            free.append(f)

    unknown = (FALLIBLE_BOOL | FALLIBLE_ID | BOOL_RETURNS | set(RETURN_CLASS)) - function_names
    if unknown:
        print("gen_c3: not in the headers any more: %s" % ", ".join(sorted(unknown)), file=sys.stderr)

    def is_fallible(f):
        if f.ret == "int":
            return f.name in FALLIBLE_BOOL
        if f.ret == "Rid" and f.name not in NOT_FALLIBLE_ID:
            if f.name in FALLIBLE_ID or FALLIBLE_ID_NAME.search(f.name):
                return True
            return bool(re.search(r"_(create|load|parse)", f.name)) and "R_INVALID_ID" in f.doc
        return False

    def returns_bool(f, rest):
        if f.ret != "int":
            return False
        if f.name in BOOL_RETURNS or rest.startswith(BOOL_RETURN_PREFIX):
            return True
        if re.match(r"get_\w+able$", rest):        # get_selectable; not get_selected, an index
            return True
        # "Returns R_TRUE when...", "R_FALSE when..." in the description (the @param lines left out)
        return bool(re.search(r"\bR_(TRUE|FALSE)\b", "\n".join(doc_text(f.doc))))

    def returned_class(owner, rest, is_static):
        """The type of handle a function of `owner` returns, from its name."""
        if is_static:
            for prefix in sorted(class_name, key=len, reverse=True):
                if rest.endswith("_" + prefix) and prefix not in ("slot",):
                    return class_name[prefix]
            return class_name[owner]
        for prefix in sorted(class_name, key=len, reverse=True):
            # "panel" of a dock area is any widget, not a Panel
            if prefix not in ("slot", "panel") and (rest == prefix or rest.endswith("_" + prefix)):
                return class_name[prefix]
        if re.search(r"(^|_)content$", rest):
            return "Widget"
        if re.search(r"(^|_)(child|children|parent|sibling)", rest) or rest in ("find", "hit_test"):
            return class_name[owner] if owner in handle_prefixes else "Widget"
        item_class = owner.split("_")[0] + "_item"
        if item_class in class_name and item_class != owner and re.search(r"(^|_)item(_|$)", rest):
            return class_name[item_class]
        return "Id"

    # ======================================================================
    # raven::c: the C API as it is
    # ======================================================================
    ext = []
    x = ext.append
    x("// Raven for C3: the C API.")
    x("//")
    x("// Generated from the C headers by tools/bindgen/gen_c3.py (Raven %s): do not edit." % api.version)
    x("//")
    x("// The C API of Raven as it is in the headers, 1:1, for anything the module %s" % module)
    x("// does not cover: its types (Rid, RWidgetType, RRect...), its constants")
    x("// (R_INVALID_ID, R_WIDGET_BUTTON...), its macros, and its functions as")
    x("// `extern fn`, each bound to the C function by @cname. The names are the ones")
    x("// of C, in the snake_case C3 wants: a function cannot start with a capital, so")
    x("// Rinit is r_init and Rbutton_set_text is r_button_set_text; a member or a")
    x("// parameter named like a keyword of C3 takes a _ at its end. An enumeration of")
    x("// C is a CInt, a text a char*.")
    x("//")
    x("//   import %s::c;" % module)
    x("//")
    x("//   if (!c::r_init(c::R_BACKEND_VULKAN)) return 1;")
    x("//   c::Rid window = c::r_window_create(\"Hello\", 420, 220, c::R_WINDOW_DEFAULT);")
    x("module %s::c;" % module)
    x("")
    x("import std::io;")
    x("")
    x("<* The handle of an object of the library: a window, a widget, a font... *>")
    x("alias Rid = uint;")
    x("<* An unsigned 32-bit integer: flags, colors. *>")
    x("alias Ruint = uint;")
    x("")
    for name, k, value in api.defines:
        if k == "str":
            x("const char* %s = \"%s\";" % (name, value))
        elif k == "id":
            x("const Rid %s = 0x%08X;" % (name, value))
        else:
            x("const CInt %s = %d;" % (name, value))
    for name, value, doc in scan.constants:
        ext.extend(doc_block(doc))
        x("const CInt %s = %d;" % (name, value))
    x("")
    for e in api.enums:
        ext.extend(doc_block(e.doc))
        x("alias %s = CInt;" % e.name)
        for item, value, doc in e.items:
            ext.extend(doc_block(doc))
            x("const %s %s = %s;" % (e.name, item, "0x%04X" % value if value > 9 else str(value)))
        for item, value in scan.marks.get(e.name, []):
            x("const %s %s = %s;" % (e.name, item, "0x%04X" % value if value > 9 else str(value)))
        x("")
    for name in api.opaque:
        x("<* Only seen through a pointer. *>")
        x("typedef %s = void;" % name)
        x("")
    for cb in api.callbacks:
        ext.extend(doc_block(cb.doc))
        params = ", ".join("%s %s" % (c_type(p.ctype), ident(p.name)) for p in cb.params)
        x("alias %s = fn %s(%s);" % (cb.name, c_type(cb.ret), params))
    x("")
    for s in api.structs:
        for field in s.fields:
            if field.ctype == "fnptr" and (s.name, field.name) in scan.fnptrs:
                ret, params = scan.fnptrs[(s.name, field.name)]
                x("alias %s = fn %s(%s);" % (fnptr_alias(s.name, field.name), c_type(ret),
                                             ", ".join("%s %s" % (c_type(p.ctype), ident(p.name)) for p in params)))
        ext.extend(doc_block(s.doc))
        x("struct %s" % s.name)
        x("{")
        for field in s.fields:
            ext.extend(doc_block(field.doc, "\t"))
            if field.ctype == "fnptr" and (s.name, field.name) in scan.fnptrs:
                t = fnptr_alias(s.name, field.name)
            else:
                t = c_type(field.ctype)
            if field.array:
                t = "%s[%d]" % (t, field.array)
            x("\t%s %s;" % (t, ident(field.name)))
        x("}")
        x("")
    for f in api.functions:
        ext.extend(doc_block(f.doc))
        params = ", ".join("%s %s" % (c_type(p.ctype), ident(p.name)) for p in f.params)
        x("extern fn %s %s(%s) @cname(\"%s\");" % (c_type(f.ret), c_function(f.name), params, f.name))
        x("")
    for name in sorted(scan.macros):
        if name not in C_MACROS:
            continue
        doc = scan.macros[name].replace("Requires <stdio.h>.", "")
        ext.extend(doc_block(doc))
        ext.extend(C_MACROS[name])
        x("")

    # ======================================================================
    # raven: the C3 API
    # ======================================================================
    out = []
    w = out.append
    version = ".".join(str(v) for n, k, v in api.defines if n in ("RAVEN_VERSION_MAJOR", "RAVEN_VERSION_MINOR", "RAVEN_VERSION_PATCH")) or api.version
    w("// Raven for C3.")
    w("//")
    w("// Generated from the C headers by tools/bindgen/gen_c3.py (Raven %s): do not edit." % version)
    w("//")
    w("// The C API with the names of C3: types and constsets in PascalCase without")
    w("// the R (RWidgetType is WidgetType), their values without their common prefix")
    w("// (R_WIDGET_BUTTON is WidgetType.BUTTON), constants in MACRO_CASE (R_INVALID_ID")
    w("// is INVALID_ID), functions in snake_case. Texts are ZString: a string literal")
    w("// passes as it is, a String through .zstr_tcopy() (or any zero-terminated copy).")
    w("// It is written over %s::c, the C API as it is, which is there for anything" % module)
    w("// this module does not cover.")
    w("//")
    w("//   - a type for each kind of handle (Window, Widget, Button, TextEditor,")
    w("//     XmlNode...), whose methods are the C functions of that object:")
    w("//     Rbutton_set_text(button, \"OK\") is button.set_text(\"OK\"). The types are")
    w("//     typedefs of Id, inline the one in the other (a Button is a Widget, a")
    w("//     Widget is an Id); a cast goes the other way: (Button)widget;")
    w("//   - what makes a handle is a function: button_create(\"OK\") returns a Button;")
    w("//   - the errors of Raven (RError) are faults, ERROR_INVALID_ID...: what can")
    w("//     fail returns an Optional, with the fault of Rerror_get_last (or")
    w("//     ERROR_FAILED when nothing was recorded); check() returns the last error;")
    w("//   - what answers yes or no returns a bool, and takes a bool for R_TRUE;")
    w("//   - a pointer and its count are a slice: plot.set_series_data(0, xs, ys);")
    w("//   - what C fills through pointers is returned: window.get_size() is a")
    w("//     CInt[<2>], window.get_frame_stats() a FrameStats;")
    w("//   - functions of a structure are its methods: spring.kick(2.0);")
    w("//   - memory of Raven is released the C3 way: file_read() copies the file")
    w("//     with an Allocator (mem by default), window.capture() returns Pixels,")
    w("//     released with pixels.free() (defer pixels.free(););")
    w("//   - Painter is what a paint callback draws with: painter.rect(...).")
    w("//")
    w("//   import %s;" % module)
    w("//")
    w("//   fn int main()")
    w("//   {")
    w("//       %s::init(Backend.VULKAN)!!;" % module)
    w("//       defer %s::shutdown();" % module)
    w("//       Window window = %s::window_create(\"Hello\", 400, 200, WindowFlags.DEFAULT);" % module)
    w("//       Button button = %s::button_create(\"Quit\");" % module)
    w("//       button.set_clicked_callback(fn (Id b, void* data) { %s::quit(0); }, null);" % module)
    w("//       window.set_content(button);")
    w("//       while (%s::wait_frame(-1.0)) {}" % module)
    w("//       return %s::get_exit_code();" % module)
    w("//   }")
    w("module %s;" % module)
    w("")
    w("import %s::c;" % module)
    w("")

    # ---- handles and constants
    w("<* A handle of the library: a window, a widget, a font... INVALID_ID names nothing. *>")
    w("typedef Id = uint;")
    w("")
    for name, k, value in api.defines:
        if k == "str":
            w("const ZString %s = \"%s\";" % (constant_name(name), value))
        elif k == "id":
            w("const Id %s = (Id)0x%08X;" % (constant_name(name), value))
        else:
            w("const CInt %s = %d;" % (constant_name(name), value))
    for name, value, doc in scan.constants:
        out.extend(doc_block(doc))
        w("const CInt %s = %d;" % (constant_name(name), value))
    w("")
    w("<* Whether the handle names something (is not INVALID_ID). *>")
    w("fn bool Id.is_valid(self) @inline => self != INVALID_ID;")
    w("")
    if "R_ID_INDEX" in scan.macros:
        out.extend(doc_block(scan.macros["R_ID_INDEX"]))
        w("fn uint Id.index(self) @inline => c::r_id_index((c::Rid)self);")
        w("")

    # ---- errors
    error_enum = api.enum("RError")
    if error_enum:
        names = enum_member_names(error_enum)
        faults = [(item, "ERROR_" + names[item] if not names[item].startswith("ERROR_") else names[item])
                  for item, _, _ in error_enum.items if item != "R_NO_ERROR"]
        w("<* The errors of Raven (Error) as faults, and ERROR_FAILED for a failure without one. *>")
        w("excuse")
        for item, fault in faults:
            w("\t%s," % fault)
        w("\tERROR_FAILED;")
        w("")
        w("<* The fault of an error; ERROR_FAILED for NO_ERROR. *>")
        w("fn fault Error.to_fault(self)")
        w("{")
        w("\tswitch (self)")
        w("\t{")
        for item, fault in faults:
            w("\t\tcase Error.%s: return %s;" % (names[item], fault))
        w("\t\tdefault: return ERROR_FAILED;")
        w("\t}")
        w("}")
        w("")
        w("<* The last error recorded (and cleared) as a fault, ERROR_FAILED when there is none. *>")
        w("fn fault last_fault()")
        w("{")
        w("\tError error = (Error)c::r_error_get_last(null, null);")
        w("\treturn error.to_fault();")
        w("}")
        w("")
        w("<*")
        w(" Returns the last error recorded (and clears it) as a fault: raven::check()!;")
        w(" Nothing when no error was recorded. The C3 form of the macro Rerror_check.")
        w("*>")
        w("fn void? check()")
        w("{")
        w("\tError error = (Error)c::r_error_get_last(null, null);")
        w("\tif (error != Error.NO_ERROR) return error.to_fault()~;")
        w("}")
        w("")

    # ---- enumerations: constsets, since their values are the ones of C
    for e in api.enums:
        out.extend(doc_block(e.doc))
        names = enum_member_names(e)
        w("constset %s : CInt" % type_name(e.name))
        w("{")
        for item, value, doc in e.items:
            out.extend(doc_block(doc, "\t"))
            w("\t%s = %s," % (names[item], "0x%04X" % value if value > 9 else str(value)))
        w("}")
        if e.flags:
            w("")
            w("<* Whether every flag of `flags` is set. *>")
            w("fn bool %s.has(self, %s flags) @inline => (self & flags) == flags;" % (type_name(e.name), type_name(e.name)))
        w("")

    # ---- opaque types, callbacks, structures
    for name in api.opaque:
        w("<* Only seen through a pointer. *>")
        w("typedef %s = void;" % type_name(name))
        w("")
    for cb in api.callbacks:
        out.extend(doc_block(cb.doc))
        params = ", ".join("%s %s" % (c3_type(p.ctype), ident(p.name)) for p in cb.params)
        w("alias %s = fn %s(%s);" % (type_name(cb.name), c3_type(cb.ret), params))
    w("")
    for s in api.structs:
        for field in s.fields:
            if field.ctype == "fnptr" and (s.name, field.name) in scan.fnptrs:
                ret, params = scan.fnptrs[(s.name, field.name)]
                w("alias %s = fn %s(%s);" % (
                    fnptr_alias(type_name(s.name), field.name), c3_type(ret),
                    ", ".join("%s %s" % (c3_type(p.ctype, p.name, s.name), ident(p.name)) for p in params)))
        out.extend(doc_block(s.doc))
        w("struct %s" % type_name(s.name))
        w("{")
        for field in s.fields:
            out.extend(doc_block(field.doc, "\t"))
            if field.ctype == "fnptr":
                t = fnptr_alias(type_name(s.name), field.name) if (s.name, field.name) in scan.fnptrs else "void*"
            else:
                t = c3_type(field.ctype, field.name, s.name)
            if field.array:
                t = "%s[%d]" % (t, field.array)
            w("\t%s %s;" % (t, ident(field.name)))
        w("}")
        w("")

    # ---- functions
    def wrapper(f, name, owner=None, rest=None, receiver=None, by_pointer=False):
        """
        A function (or a method of `receiver`, `&self` when by_pointer) calling
        f; None when an alias does.
        """
        rest = rest if rest is not None else snake(f.name)
        is_method = receiver is not None
        params = f.params[1:] if is_method else f.params
        kinds = [kind(p.ctype) for p in params]
        names = [ident(p.name) for p in params]
        n = len(params)

        # ---- what C fills through pointers, returned instead (hidden parameters)
        mode = None
        hidden = set()
        out_names = [p.name for p in params]
        if (f.ret == "uint8_t*" and n >= 2 and out_names[-2:] == ["width", "height"]
                and all(k == ("out", ("scalar", "int")) for k in kinds[-2:])):
            mode = "pixels"                                     # Rwindow_capture, Rimage_decode
            hidden = {n - 2, n - 1}
        elif kinds and kind(f.ret)[0] == "owned_str" and kinds[-1] == ("out", ("scalar", "size_t")):
            mode = "owned_bytes"                                # Rfile_read
            hidden = {n - 1}
        elif kind(f.ret)[0] == "cstr_array" and n == 1 and kinds[0][0] == "out" and out_names[0] == "count":
            mode = "string_slice"                               # Rvulkan_get_required_*_extensions
            hidden = {0}
        elif kinds and kinds[-1][0] == "struct_ptr" and f.ret in ("void", "int"):
            mode = "struct_out"                                 # Rmemory_get_stats, Rwindow_get_native_handle
            hidden = {n - 1}
        elif (f.ret == "void" and 2 <= n <= 4 and all(k[0] == "out" and k[1][0] == "scalar" for k in kinds)
              and len(set(kinds)) == 1 and kinds[0][1][1] in ("int", "float", "double")):
            mode = "vector"                                     # Rwindow_get_size, Rwidget_get_rect
            hidden = set(range(n))

        # ---- slices: the pointers before a count
        slice_of = {}       # index of a pointer -> type of its elements
        group_last = {}     # index of a pointer -> index of the last pointer of its group
        length_of = {}      # index of a count -> index of the pointer whose length it is
        for i, p in enumerate(params):
            if i == 0 or i in hidden or kinds[i][0] != "scalar" or not LENGTH_PARAM.match(p.name):
                continue
            group = []
            j = i - 1
            while j >= 0 and kinds[j][0] in ARRAY_KINDS and j not in slice_of and j not in hidden:
                group.insert(0, j)
                j -= 1
            if not group and kinds[i - 1][0] == "cstr" and p.ctype == "size_t":
                group = [i - 1]                                 # Rxml_document_parse(xml, size, ...)
            for g in group:
                k, detail = kinds[g]
                slice_of[g] = {"carray": SCALAR.get(detail, "char"), "cbytes": "char", "cptr": "char",
                               "cstr_array": "ZString", "cstruct_ptr": type_name(detail) if detail else "char",
                               "cstr": "char"}[k]
                group_last[g] = group[-1]
            if group:
                length_of[i] = group[-1]

        used = set(names) | {"self"}

        def local(base):
            name_ = base
            while name_ in used:
                name_ += "_"
            used.add(name_)
            return name_

        signature = []
        args = []
        prelude = []
        hidden_locals = {}
        converted = False
        if is_method:
            self_type = receiver + "*" if by_pointer else receiver
            args.append(to_c("self", self_type, f.params[0].ctype))
        for i, p in enumerate(params):
            pname = names[i]
            if i in hidden:
                k, detail = kinds[i]
                if k == "struct_ptr":
                    t = type_name(detail)
                elif detail[0] == "scalar":
                    t = SCALAR[detail[1]]
                else:
                    t = type_name(detail[1])
                hidden_locals[i] = (pname, t)
                prelude.append("\t%s %s;" % (t, pname))
                args.append(to_c("&" + pname, t + "*", p.ctype))
                converted = True
                continue
            if i in length_of:
                args.append(to_c("%s.len" % names[length_of[i]], "usz", p.ctype))
                converted = True
                continue
            if i in slice_of:
                element = slice_of[i]
                t = "String" if kinds[i][0] == "cstr" else element + "[]"
                arg = to_c(pname + ".ptr", element + "*", p.ctype)
                if group_last[i] != i:
                    arg = "(%s.len ? %s : null)" % (pname, arg)    # Rplot_set_series_data: x NULL is 0, 1, 2...
                args.append(arg)
                signature.append("%s %s" % (t, pname))
                converted = True
                continue
            t = c3_type(p.ctype, p.name, f.name)
            if p.ctype == "int" and p.name in BOOL_PARAMS:
                t = "bool"
            arg = to_c(pname, t, p.ctype)
            converted = converted or arg != pname
            args.append(arg)
            signature.append("%s %s" % (t, pname))
        call = "c::%s(%s)" % (c_function(f.name), ", ".join(args))

        fallible = is_fallible(f)
        ret = ret_type(f)
        body = None
        extra_doc = None
        if f.ret == "Rid" and owner:
            ret = returned_class(owner, rest, not is_method)
        if f.name in RETURN_CLASS:
            ret = RETURN_CLASS[f.name]

        if mode == "pixels":
            (wname, _), (hname, _) = hidden_locals[n - 2], hidden_locals[n - 1]
            pixels = local("pixels")
            ret = "Pixels?"
            body = prelude + [
                "\tchar* %s = %s;" % (pixels, call),
                "\tif (!%s) return last_fault()~;" % pixels,
                "\treturn { .data = %s, .width = %s, .height = %s };" % (pixels, wname, hname)]
            extra_doc = "Release the pixels with Pixels.free()."
        elif mode == "owned_bytes":
            size = hidden_locals[n - 1][0]
            data = local("data")
            allocator = local("allocator")
            signature.append("Allocator %s = mem" % allocator)
            ret = "char[]?"
            body = prelude + [
                "\tchar* %s = %s;" % (data, call),
                "\tif (!%s) return last_fault()~;" % data,
                "\tdefer c::r_memory_free(%s);" % data,
                "\treturn alloc::clone_slice(%s, %s[:%s]);" % (allocator, data, size)]
            extra_doc = "The bytes are a copy made with `allocator`: free them with it."
        elif mode == "string_slice":
            count = hidden_locals[0][0]
            ret = "ZString[]"
            body = prelude + ["\treturn ((ZString*)%s)[:%s];" % (call, count)]
            extra_doc = "The texts belong to the library."
        elif mode == "struct_out":
            value, t = hidden_locals[n - 1]
            if f.ret == "int":
                ret = t + "?"
                body = prelude + ["\tif (!%s) return last_fault()~;" % call, "\treturn %s;" % value]
            else:
                ret = t
                body = prelude + ["\t%s;" % call, "\treturn %s;" % value]
        elif mode == "vector":
            element = hidden_locals[0][1]
            ret = "%s[<%d>]" % (element, n)
            body = prelude + ["\t%s;" % call,
                              "\treturn { %s };" % ", ".join(hidden_locals[i][0] for i in range(n))]
            extra_doc = "Returned as { %s }." % ", ".join(hidden_locals[i][0] for i in range(n))
        elif fallible and f.ret == "int":
            ret = "void?"
            body = prelude + ["\tif (!%s) return last_fault()~;" % call]
        elif fallible:
            result_var = local("result")
            body = prelude + [
                "\tId %s = (Id)%s;" % (result_var, call),
                "\tif (%s == INVALID_ID) return last_fault()~;" % result_var,
                "\treturn %s;" % (result_var if ret == "Id" else "(%s)%s" % (ret, result_var))]
            ret += "?"
        elif returns_bool(f, rest):
            ret = "bool"
            call = "%s != 0" % call
        else:
            returned = from_c(call, ret, f.ret)
            if returned == call and not converted and not is_method:
                return None
            call = returned

        if by_pointer:
            head = "fn %s %s.%s(&self%s)" % (ret, receiver, name, "".join(", " + s for s in signature))
        elif is_method:
            head = "fn %s %s.%s(self%s)" % (ret, receiver, name, "".join(", " + s for s in signature))
        else:
            head = "fn %s %s(%s)" % (ret, name, ", ".join(signature))
        lines = doc_block(f.doc, extra=extra_doc)
        if body:
            lines += [head, "{"] + body + ["}"]
        else:
            lines.append("%s @inline => %s;" % (head, call))
        return lines

    # ---- what Raven allocates for the application
    if any(f.ret == "uint8_t*" for f in api.functions) and "Rpixels_free" in function_names:
        w("<*")
        w(" Pixels made by Raven (Window.capture, image_decode): `width` x `height`")
        w(" tightly packed RGBA8 pixels. Release them with free(): defer pixels.free();")
        w("*>")
        w("struct Pixels")
        w("{")
        w("\tchar* data;")
        w("\tCInt width;")
        w("\tCInt height;")
        w("}")
        w("")
        w("<* The bytes of the pixels: width * height * 4 of them. *>")
        w("fn char[] Pixels.bytes(&self) @inline => self.data[:(usz)self.width * (usz)self.height * 4];")
        w("")
        w("<* Releases the pixels (Rpixels_free). *>")
        w("fn void Pixels.free(&self)")
        w("{")
        w("\tif (self.data) c::r_pixels_free(self.data);")
        w("\t*self = {};")
        w("}")
        w("")

    # ---- functions of the structures, as their methods: spring.kick(2.0)
    if struct_methods:
        w("// ---- methods of the structures")
        w("")
        for f, sname, rest in struct_methods:
            out.extend(wrapper(f, safe(rest), None, rest, type_name(sname), by_pointer=True))
            w("")

    def emit_class(prefix, base):
        name = class_name[prefix]
        members = list(by_class.get(prefix, []))
        if prefix == "widget":
            members += [(f, "slot_" + rest) for f, rest in by_class.get("slot", [])]
        w("// ---- %s" % name)
        w("")
        w("typedef %s = inline %s;" % (name, base))
        w("")
        has_create = any(rest == "create" for f, rest in members)
        if base == "Widget" and not has_create and prefix in widget_type_items:
            w("<* A new %s (widget_create(WidgetType.%s)). *>" % (name, enum_names_widget[widget_type_items[prefix]]))
            w("fn %s %s_create() @inline => (%s)c::r_widget_create(c::%s);" % (
                name, prefix, name, widget_type_items[prefix]))
            w("")
        for f, rest in members:
            is_method = bool(f.params) and f.params[0].ctype == "Rid"
            if is_method:
                lines = wrapper(f, safe(rest), prefix, rest, name)
            else:
                lines = wrapper(f, safe(snake(f.name)), prefix, rest) or (
                    doc_block(f.doc) + ["alias %s = c::%s;" % (safe(snake(f.name)), c_function(f.name))])
            out.extend(lines)
            w("")

    enum_names_widget = enum_member_names(widget_enum) if widget_enum else {}
    emit_class("widget", "Id")
    for prefix in widget_prefixes:
        emit_class(prefix, "Widget")
    for prefix in handle_prefixes:
        emit_class(prefix, "Id")

    # widget types with no type of their own: vbox_create() ...
    made = {p + "_create" for p in widget_prefixes} | {snake(f.name) for f in api.functions}
    extra = [(p, item) for p, item in widget_type_items.items() if p not in widget_prefixes and p + "_create" not in made]
    if extra:
        w("// ---- the other widget types")
        w("")
        for prefix, item in extra:
            cls = class_name.get(WIDGET_TYPE_CLASS.get(prefix, "widget"), "Widget")
            w("<* A new %s widget (widget_create(WidgetType.%s)). *>" % (prefix, enum_names_widget[item]))
            w("fn %s %s_create() @inline => (%s)c::r_widget_create(c::%s);" % (cls, prefix, cls, item))
            w("")

    # ---- painter
    w("// ---- Painter")
    w("")
    for f in painter:
        name = re.sub(r"^Rdraw_", "", f.name)
        name = safe(snake(f.name) if name == f.name else name)
        out.extend(wrapper(f, name, None, name, "Painter", by_pointer=True))
        w("")

    # ---- the rest
    w("// ---- functions")
    w("")
    for f in free:
        lines = wrapper(f, safe(snake(f.name)))
        if lines is None:
            lines = doc_block(f.doc) + ["alias %s = c::%s;" % (safe(snake(f.name)), c_function(f.name))]
        out.extend(lines)
        w("")

    generate.counts = (len(api.functions), len(api.enums), len(api.structs), len(api.callbacks))
    return {"c3/raven.c3l/src/raven.c3": "\n".join(out).rstrip() + "\n",
            "c3/raven.c3l/src/raven_c.c3": "\n".join(ext).rstrip() + "\n"}


# ---------------------------------------------------------------------------
# On its own
# ---------------------------------------------------------------------------

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(description="Writes the C3 bindings of Raven from its C headers.")
    parser.add_argument("raven", nargs="?", help="a checkout of Raven (cloned from %s when not given)" % RAVEN_REPOSITORY)
    default_out = os.path.normpath(os.path.join(here, "..", "..", "bindings", "c3", "raven.c3l", "src"))
    parser.add_argument("-o", "--out", default=default_out, help="where to write (default: bindings/c3/raven.c3l/src)")
    parser.add_argument("--ref", help="the tag or branch of Raven to clone")
    parser.add_argument("--module", default="raven", help="the name of the C3 module (default: raven)")
    parser.add_argument("--check", action="store_true", help="fail when the files are not what would be written")
    args = parser.parse_args()

    clone = None
    root = args.raven
    if not root:
        clone = tempfile.mkdtemp(prefix="raven-")
        command = ["git", "clone", "--depth", "1", "--quiet"] + (["--branch", args.ref] if args.ref else []) + [RAVEN_REPOSITORY, clone]
        print("cloning %s%s" % (RAVEN_REPOSITORY, " (%s)" % args.ref if args.ref else ""))
        subprocess.run(command, check=True)
        root = clone
    try:
        bindgen = os.path.join(root, "tools", "bindgen")
        if not os.path.exists(os.path.join(bindgen, "cparse.py")):
            print("gen_c3: %s is not a checkout of Raven (no tools/bindgen/cparse.py)" % root, file=sys.stderr)
            return 1
        sys.path.insert(0, bindgen)
        import cparse
        api = cparse.parse(os.path.join(root, "include"))
        files = generate(api, args.module, os.path.abspath(root))
    finally:
        if clone:
            shutil.rmtree(clone, ignore_errors=True)

    stale = []
    for path, text in sorted(files.items()):
        full = os.path.join(args.out, os.path.basename(path))
        current = open(full, encoding="utf-8").read() if os.path.exists(full) else None
        if current == text:
            continue
        stale.append(full)
        if not args.check:
            os.makedirs(args.out, exist_ok=True)
            with open(full, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(text)
    if args.check and stale:
        print("out of date (run tools/bindgen/gen_c3.py): " + ", ".join(stale))
        return 1
    print("%d functions, %d enums, %d structures, %d callbacks -> %s%s" % (
        generate.counts + (args.out, "" if args.check else " (%d written)" % len(stale))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
