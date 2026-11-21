"""Zig: the idiomatic layer over zig/raven.zig, written to zig/src/raven.zig.

zig/raven.zig (gen_zig.py) is the C API as it is. This is the API as a Zig
program wants it, over the same functions:

  - a type for each kind of handle, `enum(Rid) { _ }`, whose methods are the C
    functions of that object: Rbutton_set_text(button, "OK") is
    button.setText("OK"). A widget of a kind gives its Widget with .widget(),
    a Widget its kind with .as(Button);
  - enumerations are Zig enums (`.vulkan`, `.left`), groups of flags packed
    structs of bools (`.{ .no_resize = true }`);
  - structures are Zig structs with bools, enums, optional handles and
    slices, converted to the structures of C when they are given;
  - texts are slices: `[:0]const u8` in (a string literal passes as it is),
    `[:0]const u8` out (borrowed from the library); a text with its length
    (`const char*`, `size_t`) is a `[]const u8`, an array with its count a slice;
  - what can fail returns an error union, `Error!T`, with the error the
    library recorded; a handle that may be none is an optional;
  - values written through pointers are returned (a struct when several);
  - memory the library hands over is copied into an allocator given by the
    caller (`fileRead(allocator, path)`);
  - callbacks are Zig functions known at compile time, with a typed context:
    button.setClickedCallback(&app, onClicked), `fn onClicked(app: *App, button: Button) void`.

Decisions the headers cannot tell (which int is a bool, which function fails)
come from the same tables as gen_c3.py, kept here so that each generator
stands alone. Anything it does not know (a new shape in a header) is not left
out and does not stop it: that function is written with the types of raven.c,
and listed in zig/FALLBACKS.md, so that a new version of Raven is always
followed (tools/bindgen/update_zig_wrapper.py). It is run on its own
(`python tools/bindgen/gen_zig_wrapper.py [--check]`), not from bindgen.py.
"""

import re

from cparse import classify, doc_lines

# ---------------------------------------------------------------------------
# What becomes a type with methods
# ---------------------------------------------------------------------------

# prefix of the C functions -> a widget kind. More are found in RWidgetType:
# every R_WIDGET_X that has Rx_ functions gets one.
WIDGET_PREFIXES = [
    "label", "button", "checkbox", "slider", "progress_bar", "image", "text_input", "spin_box", "combo_box", "separator",
    "list_view", "tree_view", "menu_item", "menu", "panel", "uniform_grid", "grid", "border", "size_box", "spacer", "scroll_box",
    "splitter", "switcher", "tab_view", "expander", "text_editor", "header_bar", "dock_area", "island", "file_browser",
    "viewport", "custom",
]
# R_WIDGET_X whose prefix is not the one of the C functions
WIDGET_TYPE_ALIASES = {"progressbar": "progress_bar"}
# widget types made as another kind (they have no functions of their own)
WIDGET_TYPE_KIND = {"vbox": "panel", "hbox": "panel", "wrap_box": "panel"}
# handles that are not widgets
HANDLE_PREFIXES = ["window", "tree_item", "font", "texture", "timer", "xml_document", "xml_node", "tray", "shader", "pdf_document"]
# functions outside the types whose Rid is a handle the name does not tell
FREE_RETURNS = {"Rtheme_get_wallpaper": "texture", "Reffect_get": "shader", "Reffect_find": "shader"}

# Rid results the name of the function does not tell
RETURNS = {
    "Rwidget_pick": "widget", "Rtree_view_get_selection": "tree_item", "Rmenu_add_separator": "menu_item",
    "Rmenu_add_header": "menu_item", "Rmenu_bar_add_divider": "menu_item", "Rborder_get_effect": "shader",
    "Rtab_view_get_tab": "widget", "Rdock_area_float_panel": "window", "Rwindow_get_owner": "window",
    "Rwindow_get_inspector": "window", "Rwindow_get_popup": "widget", "Rfont_get_variant": "font",
    "Rxml_document_get_root": "xml_node", "Rxml_node_get_document": "xml_document", "Rxml_node_add_comment": "xml_node",
    "Rxml_node_add_xml": "xml_node", "Rxml_node_duplicate": "xml_node",
}
# Rid parameters (not the first of a method) -> the handle they are
HANDLE_PARAMS = {
    "window": "window", "owner": "window", "texture": "texture", "font": "font", "fallback": "font", "variant": "font",
    "shader": "shader", "item": "tree_item", "parent_item": "tree_item", "new_parent": "xml_node", "timer": "timer",
    "tray": "tray", "node": "xml_node", "document": "xml_document",
    # any widget
    "widget": "widget", "content": "widget", "child": "widget", "panel": "widget", "relative": "widget", "menu": "widget",
    "label": "widget", "sender": "widget", "scope": "widget", "parent": "widget", "root": "widget", "target": "widget",
    "source": "widget", "drag_source": "widget", "from": "widget", "to": "widget",
}
# Rid fields of the structures -> the handle they are
HANDLE_FIELDS = {"window": "window", "parent": "window", "anchor": "widget", "target": "widget", "drag_source": "widget", "viewport": "viewport",
                 "icon": "texture", "texture": "texture"}
# Rid parameters of callbacks whose handle the name does not tell
CALLBACK_HANDLES = {("RTreeEventCallback", "item"): "tree_item", ("RTreeContextCallback", "item"): "tree_item",
                    ("RDockFloatWindowCallback", "floating_area"): "dock_area"}

# ---------------------------------------------------------------------------
# Error handling, booleans
# ---------------------------------------------------------------------------

# int functions where R_FALSE is a failure (and not an answer): Error!void
FALLIBLE_BOOL = {
    "Rinit", "Rinit_ex", "Ropen_url", "Rwindow_set_theme", "Rtheme_use", "Rwidget_set_theme", "Rdock_area_load_layout",
    "Rcolor_picker_set_hex", "Rtimeline_set_track_style", "Rnode_graph_set_node_style", "Rfile_browser_set_directory",
    "Rviewport_set_native", "Rxml_register_tag", "Rxml_node_move",
    # files and documents that are written or read
    "Rfile_write", "Rfile_register_memory", "Rtheme_save", "Rxml_document_save", "Rpdf_document_save",
    "Rpdf_document_draw_window", "Rpdf_view_load_file", "Rpdf_view_load_memory", "Rlanguage_register", "Rblock_editor_load",
}
# Rid functions where R_INVALID_ID is a failure: Error!Handle. Also every
# create/load/parse function whose documentation says it returns R_INVALID_ID
# and every one that reads a file, XML, SVG or pixels.
FALLIBLE_ID = {"Rtray_create", "Rxml_document_parse", "Rxml_document_load"}
FALLIBLE_ID_NAME = re.compile(r"_(from_file|from_xml|from_svg|from_pixels|load|parse)")
NOT_FALLIBLE_ID = {"Rwidget_create"}

# int parameters and fields that are R_TRUE / R_FALSE: bool
BOOL_NAMES = {
    "enabled", "visible", "pressed", "read_only", "tint", "expanded", "repeat", "closable", "checked", "selected",
    "multiple", "deletable", "topmost", "shown", "inside", "eraser", "dark", "hit_testable", "clip", "focusable", "wrap",
    "selectable", "password", "whole_tree", "native", "checkable", "sortable", "descending", "striped", "copy",
    "transparent", "modal", "resizable", "animated", "active", "visible_only", "recursive", "ok", "started", "cancelled",
    "wheel_precise", "animate", "pointer",
}
# int functions that answer yes or no: bool
BOOL_RETURN_WORDS = re.compile(r"(^|_)(is|has|can|wants|was|contains|exists)(_|$)")
BOOL_RETURNS = {
    "Rwait_frame", "Rdraw_frame",
    # done or not (not a failure: nothing to report)
    "Rwindow_inject_drop", "Rwindow_replace_text_input", "Rwindow_set_text_input_selection", "Rblock_editor_attach",
    "Rlocale_set_language", "Rtimeline_set_item_style", "Rnode_graph_set_type_style", "Rnode_graph_set_pin_style",
    "Rblock_editor_set_kind_label",
    # printed, or cancelled
    "Rpdf_print", "Rpdf_print_file", "Rpdf_view_print", "Rpdf_document_print",
    # what the system can do: R_FALSE where it has no such thing
    "Rtaskbar_set_menu", "Rtaskbar_set_jump_list", "Rtaskbar_set_badge", "Rwindow_request_attention",
    "Rwindow_set_taskbar_progress",
}

# Structures a function may read and write (the others given by pointer are filled)
INOUT_STRUCTS = {"RSpring", "RTileItem"}
# Structures given by pointer that describe a mistake: an optional parameter.
# Given, the library records no error: a failure is then this error.
DIAGNOSTIC_STRUCTS = {"RXmlError": "Xml"}

# ---------------------------------------------------------------------------
# Names
# ---------------------------------------------------------------------------

# reserved words: quoted (@"error") wherever they name something
RESERVED = {
    "addrspace", "align", "allowzero", "and", "anyframe", "anytype", "asm", "break", "callconv", "catch", "comptime",
    "const", "continue", "defer", "else", "enum", "errdefer", "error", "export", "extern", "fn", "for", "if", "inline",
    "linksection", "noalias", "noinline", "nosuspend", "opaque", "or", "orelse", "packed", "pub", "resume", "return",
    "struct", "suspend", "switch", "test", "threadlocal", "try", "union", "unreachable", "var", "volatile", "while",
}
# primitive values and types: fine as the name of a field, not of a parameter
PRIMITIVES = {
    "null", "true", "false", "undefined", "type", "void", "bool", "noreturn", "anyerror", "anyopaque", "f16", "f32",
    "f64", "f80", "f128", "usize", "isize", "c_char", "c_short", "c_ushort", "c_int", "c_uint", "c_long", "c_ulong",
    "c_longlong", "c_ulonglong", "c_longdouble", "comptime_int", "comptime_float",
}
KEYWORDS = RESERVED | PRIMITIVES

SCALAR = {"int": "i32", "float": "f32", "double": "f64", "char": "u8", "size_t": "usize", "uint64": "u64",
          "uintptr": "usize", "uint32": "u32", "uint8": "u8"}
RAW_SCALAR = {"int": "c_int", "float": "f32", "double": "f64", "char": "u8", "size_t": "usize", "uint64": "u64",
              "uintptr": "usize", "uint32": "u32", "uint8": "u8", "id": "c.Rid"}


def is_reserved(name):
    """A keyword or a primitive type of Zig (u0, i7, f16...)."""
    return name in KEYWORDS or bool(re.match(r"^[iu][0-9]+$", name))


def ident(name):
    """A name of a field or a declaration: @"error" for a reserved word (as zig fmt writes it)."""
    return '@"%s"' % name if name in RESERVED or name[:1].isdigit() else name


def raw_field(name):
    """The name of a field in zig/raven.zig (gen_zig.py): type_ for type."""
    import gen_zig
    return name + "_" if name in gen_zig.KEYWORDS else name


def pascal(snake):
    return "".join(part[:1].upper() + part[1:] for part in snake.split("_") if part)


def camel(snake):
    p = pascal(snake)
    return p[:1].lower() + p[1:]


def type_name(cname):
    """RWidgetType -> WidgetType"""
    return cname[1:] if cname.startswith("R") and cname[1:2].isupper() else cname


def snake_body(function_name):
    """Rbutton_set_text -> button_set_text"""
    return function_name[1:] if function_name.startswith("R") else function_name


def enum_member_names(enum):
    """{C name: Zig name} of the items of an enumeration, without their common prefix, in snake_case."""
    names = [item for item, _, _ in enum.items]
    words = [n.split("_") for n in names]
    common = []
    if len(names) > 1:
        for group in zip(*words):
            if len(set(group)) != 1:
                break
            common.append(group[0])
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
        short = name[len(prefix):] if prefix and name.startswith(prefix) and len(name) > len(prefix) else re.sub(r"^(RAVEN_|R_)", "", name)
        if short[:1].isdigit():
            short = (prefix.rstrip("_").split("_")[-1] if prefix else "n") + "_" + short
        result[name] = short.lower()
    if len(set(result.values())) != len(result):
        raise ValueError("%s: two items have the same name in Zig" % enum.name)
    return result


def doc(out, text, indent=""):
    for line in doc_lines(text):
        out.append("%s///%s" % (indent, (" " + line) if line else ""))


def says_bool(text):
    return bool(text) and bool(re.search(r"\bR_TRUE\b|\bR_FALSE\b", text))


# ---------------------------------------------------------------------------
# The generator
# ---------------------------------------------------------------------------

class Gen:
    def __init__(self, api):
        self.api = api
        self.names = {f.name for f in api.functions}
        self.enums = {e.name: e for e in api.enums}
        self.structs = {s.name: s for s in api.structs}

        # ---- widget kinds and handles
        widget_enum = api.enum("RWidgetType")
        self.widget_members = enum_member_names(widget_enum)
        self.widget_items = {}          # kind prefix -> [R_WIDGET_X]
        prefixes = list(WIDGET_PREFIXES)
        for item, _, _ in widget_enum.items:
            prefix = item[len("R_WIDGET_"):].lower()
            prefix = WIDGET_TYPE_ALIASES.get(prefix, prefix)
            prefix = WIDGET_TYPE_KIND.get(prefix, prefix)
            self.widget_items.setdefault(prefix, []).append(item)
            if prefix not in prefixes and any(n.startswith("R%s_" % prefix) for n in self.names):
                prefixes.append(prefix)
        self.widget_prefixes = prefixes
        self.handle_prefixes = list(HANDLE_PREFIXES)
        self.class_name = {p: pascal(p) for p in prefixes + self.handle_prefixes}
        self.class_name["widget"] = "Widget"
        self.all_prefixes = sorted(prefixes + self.handle_prefixes + ["widget", "slot"], key=len, reverse=True)

        # ---- flags
        self.flag_enums = []
        for e in api.enums:
            if e.flags:
                stem = re.sub(r"(Flags|Buttons|Button|Modifier)$", "", type_name(e.name))
                stem_snake = "_".join(w.lower() for w in re.findall(r"[A-Z][a-z0-9]*", stem))
                self.flag_enums.append((e.name, stem_snake))

        # ---- structures: given in arrays (C layout kept), with function pointers (left to raven.c)
        self.array_structs = set()
        for f in api.functions:
            for i, p in enumerate(f.params):
                kind, detail = classify(p.ctype, api)
                if kind == "cstruct_ptr" and i + 1 < len(f.params) and f.params[i + 1].ctype == "int" and "count" in f.params[i + 1].name:
                    self.array_structs.add(detail)
        for s in api.structs:
            for field in s.fields:
                if field.ctype.startswith("const R") and field.ctype.endswith("*") and api.struct(field.ctype[6:-1]):
                    self.array_structs.add(field.ctype[6:-1])
        self.raw_structs = {s.name for s in api.structs if any(f.ctype == "fnptr" for f in s.fields)}

        # what could not be made idiomatic: (C name, why), written to zig/FALLBACKS.md
        self.fallbacks = []
        self.check_names()
        stale = (FALLIBLE_BOOL | FALLIBLE_ID | BOOL_RETURNS | set(RETURNS) | set(FREE_RETURNS) | set(OVERRIDES)) - self.names
        for name in sorted(stale):
            self.fallbacks.append((name, "named in a table of gen_zig_wrapper.py, not in the headers any more"))

    # -- names ---------------------------------------------------------------

    def check_names(self):
        taken = {}
        for kind, names in (("enum", [self.enum_type(e.name) for e in self.api.enums]),
                            ("struct", [type_name(s.name) for s in self.api.structs if s.name not in self.raw_structs]),
                            ("handle", sorted(set(self.class_name.values()))),
                            ("base", ["Error", "Color", "Painter", "Pixels", "Rid"])):
            for name in names:
                if name in taken:
                    raise ValueError("the Zig type %s is both a %s and a %s" % (name, taken[name], kind))
                taken[name] = kind

    def enum_type(self, cname):
        return "ErrorCode" if cname == "RError" else type_name(cname)

    def class_of(self, function_name):
        body = function_name[1:]
        for prefix in self.all_prefixes:
            if body.startswith(prefix + "_"):
                return prefix, body[len(prefix) + 1:]
        return None

    def handle_type(self, prefix):
        return self.class_name[prefix] if prefix != "slot" else "Widget"

    def flag_type(self, name, context):
        """The flags enumeration a Ruint holds, from its name and the one of its function or structure."""
        context = re.sub(r"^R(?=[a-z])", "", context)
        context = "_".join(w.lower() for w in re.findall(r"[A-Z]?[a-z0-9]+|[A-Z]+(?![a-z])", context))
        suffix = {"flags": ("Flags",), "buttons": ("Button", "Buttons"), "modifiers": ("Modifier",)}.get(name)
        if not suffix:
            return None
        best = None
        for enum_name, stem in self.flag_enums:
            if enum_name.endswith(suffix) and (stem == "" or re.search(r"(^|_)%s(_|$)" % stem, context)):
                if best is None or len(stem) > len(best[1]):
                    best = (enum_name, stem)
        return best[0] if best else None

    # -- types ---------------------------------------------------------------

    def raw_type(self, ctype):
        """The type of zig/raven.zig for a C type (named from the module c)."""
        kind, detail = classify(ctype, self.api)
        if kind == "void":
            return "void"
        if kind == "scalar":
            return RAW_SCALAR[detail]
        if kind in ("enum", "callback", "struct"):
            return "c." + detail
        if kind == "fnptr":
            return "?*const anyopaque"
        if kind == "cstr":
            return "?[*:0]const u8"
        if kind == "owned_str":
            return "?[*:0]u8"
        if kind == "cstr_out":
            return "?*?[*:0]const u8"
        if kind == "cstr_array":
            return "?[*]const ?[*:0]const u8"
        if kind == "ptr":
            return "?*anyopaque"
        if kind == "cptr":
            return "?*const anyopaque"
        if kind == "bytes":
            return "?[*]u8"
        if kind == "cbytes":
            return "?[*]const u8"
        if kind == "out":
            return "?*%s" % (RAW_SCALAR[detail[1]] if detail[0] == "scalar" else "c." + detail[1])
        if kind == "carray":
            return "?[*]const %s" % RAW_SCALAR[detail]
        if kind == "struct_ptr":
            return "?*c.%s" % detail
        if kind == "cstruct_ptr":
            return "?*const c.%s" % detail
        if kind == "opaque_ptr":
            return "?*c.%s" % detail
        raise ValueError(ctype)

    def value(self, ctype, name, context, is_bool=False):
        """
        (Zig type, to C, from C) of a value passed by value: to C and from C are
        format strings with {} for the expression.
        """
        kind, detail = classify(ctype, self.api)
        if kind == "scalar":
            if detail == "id":
                raise ValueError("handles are typed by the caller")
            if detail == "int" and is_bool:
                return "bool", "@intFromBool({})", "({} != 0)"
            if detail == "uint32":
                flags = self.flag_type(name, context)
                if flags:
                    t = self.enum_type(flags)
                    return t, "@as(u32, @bitCast({}))", "@as(%s, @bitCast(@as(u32, {})))" % t
            return SCALAR[detail], "{}", "{}"
        if kind == "enum":
            t = self.enum_type(detail)
            if self.enums[detail].flags:
                return t, "@as(c_int, @bitCast({}))", "@as(%s, @bitCast(@as(c_int, {})))" % t
            return t, "@backingInt({})", "@as(%s, @fromBackingInt({}))" % t
        raise ValueError("no Zig value for %s %s" % (ctype, name))

    def handle_of_param(self, name, function_name):
        prefix = HANDLE_PARAMS.get(name)
        if prefix is None:
            if name in self.class_name:
                prefix = "widget" if name in self.widget_prefixes else name
            else:
                return None     # not known: a plain Rid (see HANDLE_PARAMS)
        return self.handle_type(prefix)

    def returns_bool(self, f, rest):
        if f.ret != "int":
            return False
        if f.name in BOOL_RETURNS or BOOL_RETURN_WORDS.search(rest):
            return True
        if re.match(r"get_\w+able$", rest):
            return True
        returns = re.search(r"@return([^@]*)", f.doc)
        return bool(returns and re.search(r"R_TRUE|R_FALSE", returns.group(1)))

    def is_fallible(self, f):
        if f.ret == "int":
            return f.name in FALLIBLE_BOOL
        if f.ret == "Rid" and f.name not in NOT_FALLIBLE_ID:
            if f.name in FALLIBLE_ID or FALLIBLE_ID_NAME.search(f.name):
                return True
            return bool(re.search(r"_(create|load|parse)", f.name)) and "R_INVALID_ID" in f.doc
        return False

    def returned_class(self, owner, rest, is_static):
        """The type of handle a function of `owner` returns, from its name (None: a plain Rid)."""
        names = self.class_name
        if is_static:
            for prefix in sorted(names, key=len, reverse=True):
                if rest.endswith("_" + prefix):
                    return names[prefix]
            return names[owner] if owner != "slot" else "Widget"
        for prefix in sorted(names, key=len, reverse=True):
            if prefix != "panel" and (rest == prefix or rest.endswith("_" + prefix)):
                return names[prefix]
        if re.search(r"(^|_)content$", rest):
            return "Widget"
        if re.search(r"(^|_)(child|children|parent|sibling)", rest) or rest in ("find", "hit_test"):
            return names[owner] if owner in self.handle_prefixes else "Widget"
        item_class = owner.split("_")[0] + "_item"
        if item_class in names and item_class != owner and re.search(r"(^|_)item(_|$)", rest):
            return names[item_class]
        return None

    def free_returned_class(self, f):
        if f.name in FREE_RETURNS:
            return self.class_name[FREE_RETURNS[f.name]]
        rest = snake_body(f.name)
        for prefix in sorted(self.handle_prefixes + self.widget_prefixes + ["widget"], key=len, reverse=True):
            if rest.endswith("_" + prefix) or re.search(r"(^|_)%s_create(_|$)" % prefix, rest):
                return self.class_name[prefix]
        return None

    def nullable(self, f, name):
        """Whether a text or a structure given to f may be NULL: its documentation says so."""
        for line in f.doc.split("\n"):
            if "NULL" not in line or "Never NULL" in line or line.strip().startswith("@return"):
                continue
            if re.search(r"\b%s\b" % re.escape(name), line) or "@param" not in line:
                return True
        return False

    def returns_null(self, f):
        returns = re.search(r"@return([^@]*)", f.doc)
        text = returns.group(1) if returns else f.doc
        return "NULL" in text and "Never NULL" not in text

    # -- structures ------------------------------------------------------------

    def field_info(self, s, field):
        """(Zig type, default, to C, from C) of a field: to C / from C format {} with the expression."""
        api = self.api
        kind, detail = classify(field.ctype, api)
        if field.array:
            if kind == "scalar" and detail == "char":
                return "[%d]u8" % field.array, "@splat(0)", "{}", "{}"
            return "[%d]%s" % (field.array, SCALAR[detail]), "@splat(0)", "{}", "{}"
        if kind == "scalar" and detail == "id":
            prefix = HANDLE_FIELDS.get(field.name)
            if prefix is None:
                self.fallbacks.append(("%s.%s" % (s.name, field.name), "a plain Rid: which handle it is is not known (HANDLE_FIELDS)"))
                return "Rid", "invalid_id", "{}", "{}"
            t = self.handle_type(prefix)
            return "?%s" % t, "null", "optId({})", "%s.fromId({})" % t
        if kind == "scalar" and detail == "int" and (field.name in BOOL_NAMES or says_bool(field.doc)):
            return "bool", "false", "@intFromBool({})", "({} != 0)"
        if kind == "scalar" and detail == "uint32":
            flags = self.flag_type(field.name, s.name)
            if flags:
                t = self.enum_type(flags)
                return t, ".{}", "@as(u32, @bitCast({}))", "@as(%s, @bitCast(@as(u32, {})))" % t
            return "u32", "0", "{}", "{}"
        if kind == "scalar":
            return SCALAR[detail], "0", "{}", "{}"
        if kind == "enum":
            t = self.enum_type(detail)
            if self.enums[detail].flags:
                return t, ".{}", "@as(c_int, @bitCast({}))", "@as(%s, @bitCast(@as(c_int, {})))" % t
            return t, "@fromBackingInt(0)", "@backingInt({})", "@as(%s, @fromBackingInt({}))" % t
        if kind == "cstr":
            if s.name in self.array_structs:
                return "?[*:0]const u8", "null", "{}", "{}"
            return "?[:0]const u8", "null", "rt.optPtr({})", "rt.optSpan({})"
        if kind == "ptr":
            return "?*anyopaque", "null", "{}", "{}"
        if kind == "cptr":
            return "?*const anyopaque", "null", "{}", "{}"
        self.fallbacks.append(("%s.%s" % (s.name, field.name), "keeps its type of C (%s)" % field.ctype))
        return self.raw_type(field.ctype), self.raw_default(field), "{}", "{}"

    def raw_default(self, field):
        kind, _ = classify(field.ctype, self.api)
        if field.array:
            return "@splat(0)"
        if kind in ("scalar", "enum"):
            return "0"
        if kind == "struct":
            return ".{}"
        return "null"

    def extern_field(self, s, field):
        """(type, default) of a field of a structure given in arrays: the layout of C kept."""
        kind, detail = classify(field.ctype, self.api)
        if kind == "scalar" and detail in ("id", "int") and not field.array:
            return self.raw_type(field.ctype), "0"
        try:
            t, default, _, _ = self.field_info(s, field)
        except ValueError:
            return self.raw_type(field.ctype), self.raw_default(field)
        if t.startswith("?") and kind != "cstr" and kind != "ptr":
            return self.raw_type(field.ctype), self.raw_default(field)
        return t, default

    def emit_struct(self, out, s):
        w = out.append
        name = type_name(s.name)
        doc(out, s.doc)
        if s.name in self.array_structs:
            # given to the library in arrays: the layout of C, so that a slice passes as it is
            w("pub const %s = extern struct {" % name)
            for field in s.fields:
                t, default = self.extern_field(s, field)
                doc(out, field.doc, "    ")
                w("    %s: %s = %s," % (ident(field.name), t, default))
            w("")
            w("    pub fn toC(self: %s) c.%s {" % (name, s.name))
            w("        return @as(*const c.%s, @ptrCast(&self)).*;" % s.name)
            w("    }")
            w("")
            w("    pub fn fromC(raw: c.%s) %s {" % (s.name, name))
            w("        return @as(*const %s, @ptrCast(&raw)).*;" % name)
            w("    }")
            w("};")
            w("")
            return
        fields = list(s.fields)
        counts = {}
        # const T* items + int item_count: a slice
        for i, field in enumerate(fields):
            if field.ctype in ("const char*const*",) or (field.ctype.startswith("const R") and field.ctype.endswith("*")):
                count = next((g for g in fields if g.name in (re.sub(r"s$", "", field.name) + "_count", field.name + "_count")), None)
                if count is None:
                    continue        # the pointer of C (field_info)
                counts[field.name] = count.name
        skipped = set(counts.values())
        w("pub const %s = struct {" % name)
        to_c = []
        from_c = []
        for field in fields:
            if field.name in skipped:
                continue
            doc(out, field.doc, "    ")
            fname = ident(field.name)
            rf = raw_field(field.name)
            if field.name in counts:
                count = raw_field(counts[field.name])
                if field.ctype == "const char*const*":
                    t = "[]const [*:0]const u8"
                    from_c.append("            .%s = rt.spanArray(raw.%s, raw.%s)," % (fname, rf, count))
                else:
                    t = "[]const %s" % type_name(field.ctype[6:-1])
                    from_c.append("            .%s = if (raw.%s) |items| @as([*]const %s, @ptrCast(items))[0..@intCast(raw.%s)] else &.{}," % (
                        fname, rf, type_name(field.ctype[6:-1]), count))
                w("    %s: %s = &.{}," % (fname, t))
                to_c.append("            .%s = if (self.%s.len > 0) @ptrCast(self.%s.ptr) else null," % (rf, fname, fname))
                to_c.append("            .%s = @intCast(self.%s.len)," % (count, fname))
                continue
            t, default, tc, fc = self.field_info(s, field)
            w("    %s: %s = %s," % (fname, t, default))
            to_c.append("            .%s = %s," % (rf, tc.format("self." + fname)))
            from_c.append("            .%s = %s," % (fname, fc.format("raw." + rf)))
        w("")
        w("    /// The structure of C.")
        w("    pub fn toC(self: %s) c.%s {" % (name, s.name))
        w("        return .{")
        out.extend(to_c)
        w("        };")
        w("    }")
        w("")
        w("    /// From the structure of C.")
        w("    pub fn fromC(raw: c.%s) %s {" % (s.name, name))
        w("        return .{")
        out.extend(from_c)
        w("        };")
        w("    }")
        if s.name == "RXmlError":
            w("")
            w("    /// The message, without the zeros after it.")
            w("    pub fn text(self: *const XmlError) []const u8 {")
            w("        return std.mem.sliceTo(&self.message, 0);")
            w("    }")
        for line in self.struct_methods.get(s.name, []):
            w(line)
        w("};")
        w("")

    # -- functions -------------------------------------------------------------

    def function(self, f, name, owner=None, rest=None, receiver=None, scope=()):
        """f as Zig; when a shape is not understood, f with the types of raven.c (see FALLBACKS.md)."""
        try:
            return self.idiomatic_function(f, name, owner, rest, receiver, scope)
        except ValueError as error:
            self.fallbacks.append((f.name, "written with the types of raven.c: %s" % error))
            return self.raw_function(f, name, receiver, scope)

    def raw_function(self, f, name, receiver, scope):
        """A function (or a method of a handle) with the types of the C API: the whole API is there."""
        taken = set(scope) | {"self", "c", "rt", "std"}
        params = list(f.params)
        head = []
        args = []
        if receiver is not None and receiver not in self.struct_types and params:
            params.pop(0)
            if receiver == "Painter":
                head.append("self: *Painter")
                args.append("@ptrCast(self)")
            else:
                head.append("self: %s" % receiver)
                args.append("@backingInt(self)")
        used = set()
        for p in params:
            n = p.name
            while n in taken or n in used or is_reserved(n):
                n += "_"
            used.add(n)
            head.append("%s: %s" % (n, self.raw_type(p.ctype)))
            args.append(n)
        lines = []
        doc(lines, f.doc)
        if lines:
            lines.append("///")
        lines.append("/// Not mapped to the types of Zig yet: the types of raven.c (see bindings/zig/FALLBACKS.md).")
        ret = self.raw_type(f.ret)
        lines.append("pub fn %s(%s) %s {" % (ident(name), ", ".join(head), ret))
        call = "c.%s(%s)" % (f.name, ", ".join(args))
        lines.append("    %s%s;" % ("" if ret == "void" else "return ", call))
        lines.append("}")
        return lines

    def idiomatic_function(self, f, name, owner=None, rest=None, receiver=None, scope=()):
        """
        The lines of a Zig function calling f: a method of `receiver` (a handle
        type, "Painter" or a structure) when given, else a function.
        `scope` holds the names declared around it, which a parameter cannot take.
        """
        api = self.api
        rest = rest if rest is not None else snake_body(f.name)
        is_method = receiver is not None
        params = list(f.params[1:] if is_method else f.params)
        taken = set(scope) | {"self", "c", "rt", "std"}
        used = set()

        def pname(n):
            while n in taken or n in used or is_reserved(n):
                n = n + "_"
            used.add(n)
            return n

        failure = "lastError()"     # the error of a failure
        sig = []        # "name: type"
        pre = []        # statements before the call
        args = []       # arguments of the C call
        post = []       # statements after the call
        outs = []       # (field name, zig type, local name, from C fmt)
        out_struct = None       # (local, zig struct type) of a structure the call fills
        callbacks = []          # (context, callback, type of the Zig function): a generic function
        context_name = None
        if is_method:
            if receiver == "Painter":
                args.append("@ptrCast(self)")
            elif receiver in self.struct_types:
                pre.append("var raw_self = self.toC();")
                args.append("&raw_self")
                post.append("self.* = .fromC(raw_self);")
            else:
                args.append("@backingInt(self)")

        i = 0
        while i < len(params):
            p = params[i]
            kind, detail = classify(p.ctype, api)
            nxt = params[i + 1] if i + 1 < len(params) else None
            names4 = [q.name for q in params[i:i + 4]]
            types4 = [q.ctype for q in params[i:i + 4]]
            # r, g, b, a: a Color
            if names4 == ["r", "g", "b", "a"] and types4 == ["float"] * 4:
                n = pname("color")
                sig.append("%s: Color" % n)
                args.extend(["%s.r" % n, "%s.g" % n, "%s.b" % n, "%s.a" % n])
                i += 4
                continue
            if names4 == ["r", "g", "b", "a"] and types4 == ["float*"] * 4:
                local = pname("color_")
                pre.append("var %s: Color = .{};" % local)
                args.extend(["&%s.r" % local, "&%s.g" % local, "&%s.b" % local, "&%s.a" % local])
                outs.append(("color", "Color", local, "{}"))
                i += 4
                continue
            # a text, or bytes, with their size: a slice
            if kind in ("cstr", "cptr") and nxt is not None and nxt.ctype == "size_t":
                n = pname(p.name)
                sig.append("%s: []const u8" % n)
                args.extend(["@ptrCast(%s.ptr)" % n, "%s.len" % n])
                i += 2
                continue
            # pixels: rgba, width, height
            if kind == "cbytes" and i + 2 < len(params) and params[i + 1].ctype == "int" and params[i + 2].ctype == "int":
                n = pname(p.name)
                wn, hn = pname(params[i + 1].name), pname(params[i + 2].name)
                sig.extend(["%s: []const u8" % n, "%s: i32" % wn, "%s: i32" % hn])
                pre.append("std.debug.assert(%s.len >= @as(usize, @intCast(%s)) * @as(usize, @intCast(%s)) * 4);" % (n, wn, hn))
                args.extend(["%s.ptr" % n, wn, hn])
                i += 3
                continue
            # numbers with their count (one or two arrays): slices
            if kind == "carray":
                arrays = [p]
                j = i + 1
                while j < len(params) and classify(params[j].ctype, api)[0] == "carray":
                    arrays.append(params[j])
                    j += 1
                elem = SCALAR[detail]
                local_names = [pname(q.name) for q in arrays]
                for q, n in zip(arrays, local_names):
                    sig.append("%s: []const %s" % (n, elem))
                if j < len(params) and params[j].ctype == "int" and params[j].name == "count":
                    for n in local_names[1:]:
                        pre.append("std.debug.assert(%s.len == %s.len);" % (n, local_names[0]))
                    args.extend("%s.ptr" % n for n in local_names)
                    args.append("@intCast(%s.len)" % local_names[0])
                    i = j + 1
                    continue
                # Rchart_set_grid(rows, columns, values): the size is given before
                before = [q.name for q in params[:i]]
                if before[-2:] == ["rows", "columns"] and len(arrays) == 1:
                    pre.append("std.debug.assert(%s.len >= @as(usize, @intCast(rows)) * @as(usize, @intCast(columns)));" % local_names[0])
                    args.append("%s.ptr" % local_names[0])
                    i = j
                    continue
                raise ValueError("%s: an array without its count" % f.name)
            # texts with their count
            if kind == "cstr_array" and nxt is not None and nxt.ctype == "int":
                n = pname(p.name)
                sig.append("%s: []const [*:0]const u8" % n)
                args.extend(["@ptrCast(%s.ptr)" % n, "@intCast(%s.len)" % n])
                i += 2
                continue
            # structures with their count
            if kind == "cstruct_ptr" and detail in self.array_structs and nxt is not None and nxt.ctype == "int":
                n = pname(p.name)
                sig.append("%s: []const %s" % (n, type_name(detail)))
                args.extend(["@ptrCast(%s.ptr)" % n, "@intCast(%s.len)" % n])
                i += 2
                continue
            # a callback and its user data
            if kind == "callback":
                cb = api.callback(detail)
                # the user data after the callback (or after the next ones: shared)
                j = i + 1
                while j < len(params) and classify(params[j].ctype, api)[0] == "callback":
                    j += 1
                has_data = j < len(params) and params[j].ctype == "void*"
                if has_data and context_name is None:
                    context_name = pname("context")
                    sig.append("%s: anytype" % context_name)
                cname = context_name if has_data else None
                fname_ = pname(p.name if p.name != "function" else "callback")
                tramp_name = "Trampoline" if not callbacks else "Trampoline%d" % (len(callbacks) + 1)
                zig_fn, tramp = self.trampoline(cb, cname, fname_, owner, f.name, tramp_name, first=not callbacks)
                callbacks.append((cname, fname_, zig_fn))
                sig.append("comptime %s: ?%s" % (fname_, zig_fn))
                pre.extend(tramp)
                args.append("if (%s != null) &%s.call else null" % (fname_, tramp_name))
                if has_data and j == i + 1:
                    first_cb = callbacks[0][1]
                    args.append("if (%s != null) rt.contextToC(%s) else null" % (first_cb, cname))
                    i += 2
                else:
                    i += 1
                continue
            # values written through pointers: returned
            if kind == "out":
                local = pname(p.name)
                if detail[0] == "scalar":
                    raw = RAW_SCALAR[detail[1]]
                    zt, fc = SCALAR[detail[1]], "{}"
                else:
                    raw = "c." + detail[1]
                    zt = self.enum_type(detail[1])
                    fc = "@as(%s, @fromBackingInt({}))" % zt
                pre.append("var %s: %s = 0;" % (local, raw))
                args.append("&%s" % local)
                outs.append((ident(p.name), zt, local, fc))
                i += 1
                continue
            if kind == "struct_ptr":
                st = type_name(detail)
                if detail in INOUT_STRUCTS:
                    n = pname(p.name)
                    sig.append("%s: *%s" % (n, st))
                    local = pname("raw_" + p.name)
                    pre.append("var %s = %s.toC();" % (local, n))
                    args.append("&%s" % local)
                    post.append("%s.* = .fromC(%s);" % (n, local))
                elif detail in DIAGNOSTIC_STRUCTS:
                    n = pname("diagnostics")
                    failure = "(if (%s != null) error.%s else lastError())" % (n, DIAGNOSTIC_STRUCTS[detail])
                    sig.append("%s: ?*%s" % (n, st))
                    local = pname("raw_" + p.name)
                    pre.append("var %s: c.%s = .{};" % (local, detail))
                    args.append("if (%s != null) &%s else null" % (n, local))
                    post.append("if (%s) |d| d.* = .fromC(%s);" % (n, local))
                else:
                    if out_struct is not None:
                        raise ValueError("%s: two structures filled" % f.name)
                    local = pname("raw_" + p.name)
                    pre.append("var %s: c.%s = .{};" % (local, detail))
                    args.append("&%s" % local)
                    out_struct = (local, st)
                i += 1
                continue
            if kind == "cstruct_ptr":
                n = pname(p.name)
                if detail in self.raw_structs:
                    sig.append("%s: *const c.%s" % (n, detail))
                    args.append(n)
                elif self.nullable(f, p.name):
                    sig.append("%s: ?%s" % (n, type_name(detail)))
                    local = pname("raw_" + p.name)
                    pre.append("const %s: ?c.%s = if (%s) |v| v.toC() else null;" % (local, detail, n))
                    args.append("if (%s) |*v| v else null" % local)
                else:
                    sig.append("%s: %s" % (n, type_name(detail)))
                    local = pname("raw_" + p.name)
                    pre.append("const %s = %s.toC();" % (local, n))
                    args.append("&%s" % local)
                i += 1
                continue
            if kind == "opaque_ptr":
                n = pname(p.name)
                sig.append("%s: *Painter" % n)
                args.append("@ptrCast(%s)" % n)
                i += 1
                continue
            if kind == "cstr":
                n = pname(p.name)
                if self.nullable(f, p.name):
                    sig.append("%s: ?[:0]const u8" % n)
                    args.append("rt.optPtr(%s)" % n)
                else:
                    sig.append("%s: [:0]const u8" % n)
                    args.append("%s.ptr" % n)
                i += 1
                continue
            if kind in ("ptr", "cptr", "bytes", "cbytes"):
                n = pname(p.name)
                sig.append("%s: %s" % (n, self.raw_type(p.ctype)))
                args.append(n)
                i += 1
                continue
            if kind == "scalar" and detail == "id":
                n = pname(p.name)
                t = self.handle_of_param(p.name, f.name)
                if t is None:
                    self.fallbacks.append((f.name, "the parameter `%s` is a plain Rid: which handle it is is not known (HANDLE_PARAMS)" % p.name))
                    sig.append("%s: Rid" % n)
                    args.append(n)
                elif "R_INVALID_ID" in f.doc or p.name in ("sender",):
                    sig.append("%s: ?%s" % (n, t))
                    args.append("optId(%s)" % n)
                else:
                    sig.append("%s: %s" % (n, t))
                    args.append("@backingInt(%s)" % n)
                i += 1
                continue
            if kind in ("scalar", "enum"):
                n = pname(p.name)
                is_bool = p.ctype == "int" and (p.name in BOOL_NAMES or re.search(r"@param\s+%s\b[^\n]*R_(TRUE|FALSE)" % re.escape(p.name), f.doc))
                t, tc, _ = self.value(p.ctype, p.name, f.name, bool(is_bool))
                sig.append("%s: %s" % (n, t))
                args.append(tc.format(n))
                i += 1
                continue
            raise ValueError("%s: no Zig parameter for %s %s" % (f.name, p.ctype, p.name))

        call = "c.%s(%s)" % (f.name, ", ".join(args))

        # ---- the result
        ret_kind, ret_detail = classify(f.ret, api)
        result = pname("result")
        body = []
        if outs and out_struct:
            raise ValueError("%s: values and a structure written" % f.name)
        if out_struct:
            local, st = out_struct
            if f.ret == "void":
                ret = st
                body = [call + ";"] + post + ["return .fromC(%s);" % local]
            elif f.ret == "int":
                ret = "?" + st
                body = ["if (%s == 0) return null;" % call] + post + ["return .fromC(%s);" % local]
            else:
                raise ValueError("%s: a structure written and a %s returned" % (f.name, f.ret))
        elif outs and f.ret in ("char*", "uint8_t*"):
            # memory the caller frees: copied into an allocator it gives
            free = "c.Rmemory_free" if f.ret == "char*" else "c.Rpixels_free"
            alloc = pname("allocator")
            sig.insert(0, "%s: std.mem.Allocator" % alloc)
            names = [n for n, _, _, _ in outs]
            local_of = {n: (local, fc) for n, _, local, fc in outs}
            others = [o for o in outs if o[0] not in ("size", "width", "height")]
            body = ["const %s = %s orelse return null;" % (result, call), "defer %s(%s);" % (free, result)] + post
            if "size" in names and "width" not in names:
                data = "try %s.dupe(u8, @as([*]const u8, @ptrCast(%s))[0..%s])" % (alloc, result, local_of["size"][0])
                zt = "[]u8"
            elif "width" in names and "height" in names:
                wl, hl = local_of["width"][0], local_of["height"][0]
                body.append("const pixel_bytes = @as(usize, @intCast(%s)) * @as(usize, @intCast(%s)) * 4;" % (wl, hl))
                data = ".{ .pixels = try %s.dupe(u8, %s[0..pixel_bytes]), .width = %s, .height = %s }" % (alloc, result, wl, hl)
                zt = "Pixels"
            else:
                raise ValueError("%s: memory returned without its size" % f.name)
            if others:
                ret = "std.mem.Allocator.Error!?struct { %s: %s, %s }" % (
                    "bytes" if zt == "[]u8" else "pixels", zt, ", ".join("%s: %s" % (n, t) for n, t, _, _ in others))
                body.append("return .{ .%s = %s, %s };" % ("bytes" if zt == "[]u8" else "pixels", data,
                                                            ", ".join(".%s = %s" % (n, fc.format(local)) for n, _, local, fc in others)))
            else:
                ret = "std.mem.Allocator.Error!?%s" % zt
                body.append("return %s;" % data)
        elif outs and f.ret not in ("void", "int"):
            # a result and values written through pointers: one struct
            rk, _ = classify(f.ret, api)
            if rk == "cstr":
                fields = [("text", "[:0]const u8", "rt.span(%s)" % result)]
            elif rk in ("scalar", "enum"):
                t, _, fc = self.value(f.ret, rest.split("_")[-1], f.name)
                fields = [("value", t, fc.format(result))]
            else:
                raise ValueError("%s: values written and a %s returned (an override is needed)" % (f.name, f.ret))
            fields += [(n, t, fc.format(local)) for n, t, local, fc in outs]
            ret = "struct { %s }" % ", ".join("%s: %s" % (n, t) for n, t, _ in fields)
            value = ".{ %s }" % ", ".join(".%s = %s" % (n, v) for n, _, v in fields)
            body = ["const %s = %s;" % (result, call)] + post
            if rk == "cstr" and self.returns_null(f) or rk == "cstr" and "NULL" in f.doc:
                ret = "?" + ret
                body.append("if (%s == null) return null;" % result)
            body.append("return %s;" % value)
        elif outs:
            if len(outs) == 1:
                fname0, zt, local, fc = outs[0]
                value = fc.format(local)
                ret = zt
            else:
                ret = "struct { %s }" % ", ".join("%s: %s" % (n, t) for n, t, _, _ in outs)
                value = ".{ %s }" % ", ".join(".%s = %s" % (n, fc.format(local)) for n, _, local, fc in outs)
            if f.ret == "void":
                body = [call + ";"] + post + ["return %s;" % value]
            elif f.ret == "int":
                ret = "?" + ret
                body = ["if (%s == 0) return null;" % call] + post + ["return %s;" % value]
            else:
                raise ValueError("%s: values written and a %s returned (an override is needed)" % (f.name, f.ret))
        elif self.is_fallible(f) and f.ret == "int":
            ret = "Error!void"
            body = ["if (%s == 0) return %s;" % (call, failure)] + post
        elif f.ret == "Rid":
            if f.name in RETURNS:
                cls = self.class_name[RETURNS[f.name]]
            elif owner:
                cls = self.returned_class(owner, rest, not is_method)
            elif receiver in ("Painter",) or receiver in self.struct_types:
                cls = None
            else:
                cls = self.free_returned_class(f)
            if cls is None:
                cls = "Widget" if re.search(r"(widget|content|child|focus|hover)", rest) else None
            if cls is None:
                ret, value = "c.Rid", result
                body = ["const %s = %s;" % (result, call)] + post + ["return %s;" % result]
            elif self.is_fallible(f):
                ret = "Error!" + cls
                body = ["const %s = %s;" % (result, call)] + post + ["return %s.fromId(%s) orelse %s;" % (cls, result, failure)]
            elif re.search(r"(^|_)create(_|$)", rest) or rest == "create":
                ret = cls
                body = ["const %s = %s;" % (result, call)] + post + ["return @fromBackingInt(%s);" % result]
            else:
                ret = "?" + cls
                body = ["const %s = %s;" % (result, call)] + post + ["return %s.fromId(%s);" % (cls, result)]
        elif self.returns_bool(f, rest):
            ret = "bool"
            body = ["const %s = %s;" % (result, call)] + post + ["return %s != 0;" % result]
        elif ret_kind == "void":
            ret = "void"
            body = [call + ";"] + post
        elif ret_kind == "cstr":
            if self.returns_null(f):
                ret = "?[:0]const u8"
                body = ["const %s = %s;" % (result, call)] + post + ["return rt.optSpan(%s);" % result]
            else:
                ret = "[:0]const u8"
                body = ["const %s = %s;" % (result, call)] + post + ["return rt.span(%s);" % result]
        elif ret_kind in ("scalar", "enum"):
            t, _, fc = self.value(f.ret, rest.split("_")[-1], f.name)
            ret = t
            body = ["const %s = %s;" % (result, call)] + post + ["return %s;" % fc.format(result)]
        elif ret_kind in ("ptr", "cptr", "bytes"):
            ret = self.raw_type(f.ret)
            body = ["const %s = %s;" % (result, call)] + post + ["return %s;" % result]
        elif ret_kind == "cstruct_ptr" and ret_detail in self.raw_structs:
            ret = "*const c.%s" % ret_detail
            body = ["return %s.?;" % call]
        else:
            raise ValueError("%s: no Zig result for %s (an override is needed)" % (f.name, f.ret))

        if receiver == "Painter":
            head_params = ["self: *Painter"] + sig
        elif receiver in self.struct_types:
            head_params = ["self: *%s" % receiver] + sig
        elif is_method:
            head_params = ["self: %s" % receiver] + sig
        else:
            head_params = sig
        lines = []
        doc(lines, f.doc)
        lines.append("pub fn %s(%s) %s {" % (ident(name), ", ".join(head_params), ret))
        if callbacks:
            self.generic_calls.append((self.qualifier, ident(name), head_params, callbacks))
        for line in pre + body:
            lines.append("    " + line)
        lines.append("}")
        return lines

    def trampoline(self, cb, context, callback, owner, function_name, tramp_name="Trampoline", first=True):
        """
        (the type of the Zig function, the lines of `const Trampoline = struct {...}`)
        calling `callback` (a parameter of comptime) from the C callback cb.
        """
        api = self.api
        params = list(cb.params)
        has_data = params and params[-1].ctype == "void*" and params[-1].name == "user_data"
        if has_data:
            params = params[:-1]
        raw_params = ["a%d: %s" % (k, self.raw_type(p.ctype)) for k, p in enumerate(params)]
        if has_data:
            raw_params.append("user_data: ?*anyopaque")
        zig_params = []
        call_args = []
        pre = []
        post = []
        if context:
            zig_params.append("@TypeOf(%s)" % context)
            call_args.append("rt.contextFromC(Ctx, user_data)")
        k = 0
        color_out = None
        first_id = True
        while k < len(params):
            p = params[k]
            a = "a%d" % k
            kind, detail = classify(p.ctype, api)
            names4 = [q.name for q in params[k:k + 4]]
            if names4 == ["r", "g", "b", "a"] and all(q.ctype == "float*" for q in params[k:k + 4]):
                color_out = ["a%d" % (k + j) for j in range(4)]
                k += 4
                continue
            if kind == "scalar" and detail == "id":
                prefix = CALLBACK_HANDLES.get((cb.name, p.name))
                if prefix is None and first_id and owner and p.name not in HANDLE_PARAMS:
                    prefix = owner
                if prefix is None and first_id and owner and p.name in self.class_name and p.name != "widget":
                    prefix = p.name
                if prefix is None:
                    prefix = HANDLE_PARAMS.get(p.name)
                if prefix is None and p.name in self.class_name:
                    prefix = p.name
                if prefix is None:
                    raise ValueError("%s: which handle is the parameter '%s'? (CALLBACK_HANDLES)" % (cb.name, p.name))
                t = self.handle_type(prefix if prefix != "slot" else "widget")
                if p.name == "sender":
                    zig_params.append("?Widget")
                    call_args.append("Widget.fromId(%s)" % a)
                else:
                    zig_params.append(t)
                    call_args.append("@as(%s, @fromBackingInt(%s))" % (t, a))
                first_id = False
            elif kind == "scalar" and detail == "int" and (p.name in BOOL_NAMES or says_bool(cb.doc) and re.search(r"\b%s\b[^\n]*R_(TRUE|FALSE)" % re.escape(p.name), cb.doc)):
                zig_params.append("bool")
                call_args.append("%s != 0" % a)
            elif kind in ("scalar", "enum"):
                t, _, fc = self.value(p.ctype, p.name, cb.name)
                zig_params.append(t)
                call_args.append(fc.format(a))
            elif kind == "cstr":
                zig_params.append("[:0]const u8")
                call_args.append("rt.span(%s)" % a)
            elif kind == "cstruct_ptr":
                st = type_name(detail)
                zig_params.append(st)
                call_args.append("%s.fromC(%s.?.*)" % (st, a))
            elif kind == "struct_ptr":
                st = type_name(detail)
                local = "item%d" % k
                pre.append("var %s = %s.fromC(%s.?.*);" % (local, st, a))
                zig_params.append("*" + st)
                call_args.append("&" + local)
                post.append("%s.?.* = %s.toC();" % (a, local))
            elif kind == "opaque_ptr":
                zig_params.append("*Painter")
                call_args.append("@ptrCast(%s.?)" % a)
            elif kind == "out" and detail[0] == "scalar":
                zig_params.append("*" + SCALAR[detail[1]])
                call_args.append("%s.?" % a)
            else:
                raise ValueError("%s: no Zig parameter for %s %s" % (cb.name, p.ctype, p.name))
            k += 1

        rk, rd = classify(cb.ret, api)
        invoke = "%s.?(%s)" % (callback, ", ".join(call_args))
        body = list(pre)
        if color_out:
            zret = "?Color"
            body.append("const color = %s orelse return 0;" % invoke)
            for target, comp in zip(color_out, "rgba"):
                body.append("if (%s) |out| out.* = color.%s;" % (target, comp))
            body.append("return 1;")
        elif rk == "void":
            zret = "void"
            body.append("%s;" % invoke)
            body.extend(post)
        elif cb.ret == "int":
            zret = "bool"
            body.append("const handled = %s;" % invoke)
            body.extend(post)
            body.append("return @intFromBool(handled);")
        elif rk == "cstr":
            zret = "?[:0]const u8"
            body.append("return rt.optPtr(%s);" % invoke)
        elif cb.ret == "Rid":
            zret = "?Widget"
            body.append("return optId(%s);" % invoke)
        else:
            raise ValueError("%s: no Zig result for %s" % (cb.name, cb.ret))
        zig_fn = "fn (%s) %s" % (", ".join(zig_params), zret)
        if has_data and not context:
            body.insert(0, "_ = user_data;")
        lines = (["const Ctx = @TypeOf(%s);" % context] if context and first else []) + ["const %s = struct {" % tramp_name,
                 "    fn call(%s) callconv(.c) %s {" % (", ".join(raw_params), self.raw_type(cb.ret))]
        lines += ["        " + line for line in body]
        lines += ["    }", "};"]
        return zig_fn, lines

    # -- the file --------------------------------------------------------------

    def generate(self):
        api = self.api
        out = []
        w = out.append
        version = ".".join(str(v) for n, k, v in api.defines if n in ("RAVEN_VERSION_MAJOR", "RAVEN_VERSION_MINOR", "RAVEN_VERSION_PATCH"))
        for line in HEADER.format(version=version).strip("\n").split("\n"):
            w(line)
        w("")

        # ---- base
        w("const std = @import(\"std\");")
        w("const rt = @import(\"runtime.zig\");")
        w("")
        w("/// The C API as it is (bindings/zig/raven.zig), for anything this module does not cover.")
        w("pub const c = rt.c;")
        w("/// The id of an object of the library. 0 and `invalid_id` name nothing.")
        w("pub const Rid = c.Rid;")
        w("pub const invalid_id: Rid = c.R_INVALID_ID;")
        w("/// The version of the headers this module was generated from.")
        w("pub const version: std.SemanticVersion = .{ .major = %d, .minor = %d, .patch = %d };" % tuple(
            next(v for n, k, v in api.defines if n == x) for x in ("RAVEN_VERSION_MAJOR", "RAVEN_VERSION_MINOR", "RAVEN_VERSION_PATCH")))
        w("pub const api_version = c.RAVEN_API_VERSION;")
        w("")
        w("pub const heap_allocator = rt.heap_allocator;")
        w("pub const setAllocator = rt.setAllocator;")
        w("")
        w("/// The id of an optional handle: R_INVALID_ID for null.")
        w("fn optId(handle: anytype) Rid {")
        w("    return if (handle) |h| @backingInt(h) else invalid_id;")
        w("}")
        w("")

        # ---- errors
        error_enum = api.enum("RError")
        members = enum_member_names(error_enum)
        errors = [(item, pascal(members[item])) for item, _, _ in error_enum.items if item != "R_NO_ERROR"]
        w("/// The errors of Raven (ErrorCode) as an error set, and Failed for a failure")
        w("/// the library did not describe.")
        w("pub const Error = error{")
        for _, e in errors:
            w("    %s," % e)
        w("    Failed,")
        w("};")
        w("")
        w("/// The error of an ErrorCode; Failed for no_error.")
        w("pub fn errorFromCode(code: ErrorCode) Error {")
        w("    return switch (code) {")
        for item, e in errors:
            w("        .%s => error.%s," % (ident(members[item]), e))
        w("        else => error.Failed,")
        w("    };")
        w("}")
        w("")
        w("/// The last error the library recorded (it is cleared), Failed when there is none.")
        w("pub fn lastError() Error {")
        w("    return errorFromCode(@fromBackingInt(c.Rerror_get_last(null, null)));")
        w("}")
        w("")
        w("/// The last error recorded, with its severity and detail (and clears it), or null.")
        w("pub fn errorGetLast() ?struct { code: ErrorCode, severity: Severity, detail: [:0]const u8 } {")
        w("    var detail: ?[*:0]const u8 = null;")
        w("    var severity: c.RSeverity = 0;")
        w("    const code: ErrorCode = @fromBackingInt(c.Rerror_get_last(&detail, &severity));")
        w("    if (code == .no_error) return null;")
        w("    return .{ .code = code, .severity = @fromBackingInt(severity), .detail = rt.span(detail) };")
        w("}")
        w("")
        w("/// Returns the last error recorded (and clears it), if there is one: `try raven.check();`.")
        w("pub fn check() Error!void {")
        w("    const code: ErrorCode = @fromBackingInt(c.Rerror_get_last(null, null));")
        w("    if (code != .no_error) return errorFromCode(code);")
        w("}")
        w("")

        # ---- enumerations
        for e in api.enums:
            names = enum_member_names(e)
            doc(out, e.doc)
            t = self.enum_type(e.name)
            if e.flags:
                bits = {}
                extra = []
                for item, value, idoc in e.items:
                    if value and value & (value - 1) == 0:
                        bits[value.bit_length() - 1] = (names[item], idoc)
                    else:
                        extra.append((names[item], value, idoc))
                top = max(bits) + 1
                w("pub const %s = packed struct(u32) {" % t)
                for bit in range(top):
                    if bit in bits:
                        doc(out, bits[bit][1], "    ")
                        w("    %s: bool = false," % ident(bits[bit][0]))
                    else:
                        w("    _unused%d: bool = false," % bit)
                w("    _padding: u%d = 0," % (32 - top))
                for name, value, idoc in extra:
                    w("")
                    doc(out, idoc, "    ")
                    w("    pub const %s: %s = @bitCast(@as(u32, 0x%X));" % (ident(name), t, value))
                w("};")
                w("")
                continue
            w("pub const %s = enum(c_int) {" % t)
            for item, value, idoc in e.items:
                doc(out, idoc, "    ")
                w("    %s = %s," % (ident(names[item]), "0x%04X" % value if value > 9 else str(value)))
            w("    _,")
            w("};")
            w("")

        # ---- color, image
        w(COLOR.strip("\n"))
        w("")

        # ---- structures (their methods are found below)
        self.struct_types = {type_name(s.name) for s in api.structs}
        self.generic_calls = []
        self.qualifier = None
        self.struct_methods = {}
        struct_prefixes = {re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", type_name(s.name)).lower(): s.name
                           for s in api.structs if s.name not in self.raw_structs}

        # ---- sort the functions
        by_class = {}
        painter = []
        by_struct = {}
        free = []
        overridden = set(OVERRIDES) & self.names
        for f in api.functions:
            if f.name in overridden:
                continue
            owner = self.class_of(f.name)
            body = snake_body(f.name)
            sp = next((p for p in sorted(struct_prefixes, key=len, reverse=True) if body.startswith(p + "_")), None)
            if f.params and f.params[0].ctype == "RPainter*":
                painter.append(f)
            elif sp and f.params and classify(f.params[0].ctype, api) == ("struct_ptr", struct_prefixes[sp]) and struct_prefixes[sp] in INOUT_STRUCTS:
                by_struct.setdefault(struct_prefixes[sp], []).append((f, body[len(sp) + 1:], True))
            elif sp and not f.params or (sp and f.params and classify(f.params[0].ctype, api) == ("struct_ptr", struct_prefixes[sp])):
                by_struct.setdefault(struct_prefixes[sp], []).append((f, body[len(sp) + 1:], False))
            elif owner:
                by_class.setdefault(owner[0], []).append((f, owner[1]))
            else:
                free.append(f)

        for sname, members in by_struct.items():
            st = type_name(sname)
            self.qualifier = st
            lines = []
            scope = {camel(rest) for _, rest, _ in members} | {"toC", "fromC"}
            for f, rest, inout in members:
                lines.append("")
                if inout:
                    fn = self.function(f, camel(rest), None, rest, st, scope)
                else:
                    fn = self.function(f, camel(rest), None, rest, None, scope)
                lines.extend("    " + line for line in fn)
            self.struct_methods[sname] = lines

        for s in api.structs:
            if s.name in self.raw_structs:
                continue        # function pointers: raven.c
            self.emit_struct(out, s)

        # ---- handles
        file_scope = self.file_scope(free)
        self.emit_handle(out, "widget", None, by_class, file_scope)
        for prefix in self.widget_prefixes:
            self.emit_handle(out, prefix, "widget", by_class, file_scope)
        for prefix in self.handle_prefixes:
            self.emit_handle(out, prefix, None, by_class, file_scope)

        # ---- painter
        w("/// What a paint callback draws with (RPainter).")
        w("pub const Painter = opaque {")
        scope = set()
        names = []
        for f in painter:
            name = re.sub(r"^Rdraw_", "", f.name)
            name = camel(snake_body(f.name) if name == f.name else name)
            names.append(name)
        scope = set(names)
        self.qualifier = "Painter"
        for k, (f, name) in enumerate(zip(painter, names)):
            if k:
                w("")
            for line in self.function(f, name, None, name, "Painter", scope | file_scope):
                w("    " + line)
        w("};")
        w("")

        # ---- free functions
        w("// ---- functions")
        w("")
        self.qualifier = None
        for f in free:
            out.extend(self.function(f, camel(snake_body(f.name)), None, None, None, file_scope))
            w("")
        for name in sorted(OVERRIDES):
            if name not in self.names:
                continue
            prefix, code = OVERRIDES[name]
            if prefix is None and code:
                out.extend(code.strip("\n").split("\n"))
                w("")
        self.emit_tests(out)
        while out and out[-1] == "":
            out.pop()
        text = "\n".join(out) + "\n"
        # the whole API: every function of the headers is called (Rset_allocator from runtime.zig)
        left_out = sorted(self.names - set(re.findall(r"\bc\.(R\w+)\(", text)) - {"Rset_allocator"})
        if left_out:
            raise ValueError("gen_zig_wrapper: functions left out: %s" % ", ".join(left_out))
        return text

    def emit_tests(self, out):
        """
        Zig analyses only what is used: a test that uses every declaration, and
        calls every function that takes a callback (they are generic), so that
        `zig build check` compiles the whole API.
        """
        w = out.append
        w("// ---- checks (`zig build check`): every declaration compiles")
        w("")
        w("test \"every declaration compiles\" {")
        w("    refAllDeclsRecursive(@This());")
        w("    _ = &everyCallbackSetter;")
        w("}")
        w("")
        w("fn refAllDeclsRecursive(comptime T: type) void {")
        w("    @setEvalBranchQuota(1_000_000);")
        w("    inline for (comptime std.meta.declarations(T)) |name| {")
        w("        if (T == @This() and comptime std.mem.eql(u8, name, \"c\")) continue;")
        w("        const D = @TypeOf(@field(T, name));")
        w("        if (D == type) {")
        w("            switch (@typeInfo(@field(T, name))) {")
        w("                .@\"struct\", .@\"enum\", .@\"union\", .@\"opaque\" => refAllDeclsRecursive(@field(T, name)),")
        w("                else => {},")
        w("            }")
        w("        } else if (@typeInfo(D) != .@\"fn\" or !@typeInfo(D).@\"fn\".is_generic) {")
        w("            _ = &@field(T, name);")
        w("        }")
        w("    }")
        w("}")
        w("")
        w("fn everyCallbackSetter() void {")
        for qualifier, name, head_params, callbacks in self.generic_calls:
            contexts = {cname for cname, _, _ in callbacks}
            fns = {fname: zig_fn for _, fname, zig_fn in callbacks}
            args = []
            for hp in head_params:
                pn = hp.split(":")[0].strip()
                if pn.startswith("comptime "):
                    pn = pn[len("comptime "):]
                if pn in contexts:
                    args.append("{}")
                elif pn in fns:
                    m = re.match(r"^fn \((.*)\) (.*)$", fns[pn])
                    types = [re.sub(r"@TypeOf\(\w+\)", "void", t.strip()) for t in m.group(1).split(",") if t.strip()]
                    ret = m.group(2)
                    body = None if ret == "void" else ("return false;" if ret == "bool" else "return null;")
                    head = "fn f(%s) %s" % (", ".join("_: %s" % t for t in types), ret)
                    if body is None:
                        args.append("struct {\n        %s {}\n    }.f" % head)
                    else:
                        args.append("struct {\n        %s {\n            %s\n        }\n    }.f" % (head, body))
                else:
                    args.append("undefined")
            w("    consume(%s%s(%s));" % (qualifier + "." if qualifier else "", name, ", ".join(args)))
        w("}")
        w("")
        w("fn consume(value: anytype) void {")
        w("    std.mem.doNotOptimizeAway(&value);")
        w("}")

    def file_scope(self, free):
        names = {camel(snake_body(f.name)) for f in free}
        names |= {"optId", "errorFromCode", "lastError", "errorGetLast", "check", "version", "heap_allocator", "setAllocator",
                  "invalid_id", "api_version"}
        names |= {override_name(code) for n, (prefix, code) in OVERRIDES.items() if prefix is None and code and n in self.names}
        return names

    def emit_handle(self, out, prefix, base, by_class, file_scope):
        w = out.append
        name = self.class_name[prefix]
        members = list(by_class.get(prefix, []))
        if prefix == "widget":
            members += [(f, "slot_" + rest) for f, rest in by_class.get("slot", [])]
        method_names = []
        for f, rest in members:
            method_names.append(camel(rest))
        helpers = {"fromId", "toId"}
        if base == "widget":
            helpers |= {"widget", "widget_types"}
        if prefix == "widget":
            helpers |= {"as", "asUnchecked"}
        clash = helpers & set(method_names)
        if clash or len(set(method_names)) != len(method_names):
            seen = set(helpers)
            renamed = []
            for (f, rest), mname in zip(members, method_names):
                new = mname
                while new in seen:
                    new += "C"
                if new != mname:
                    self.fallbacks.append((f.name, "named %s.%s: %s is taken" % (name, new, mname)))
                seen.add(new)
                renamed.append((f, rest, new))
            members = renamed
            method_names = [m for _, _, m in renamed]
        else:
            members = [(f, rest, m) for (f, rest), m in zip(members, method_names)]
        method_names += [override_name(code) for n, (p, code) in OVERRIDES.items() if p == prefix and n in self.names]
        scope = set(method_names) | helpers | file_scope

        if prefix in ("widget",):
            w("/// A widget of any kind. Each kind is a type of its own (Button, Label...):")
            w("/// `kind.widget()` is its Widget, `widget.as(Button)` the kind of a Widget.")
        elif base == "widget":
            items = self.widget_items.get(prefix, [])
            w("/// A widget%s." % (" (%s)" % ", ".join("WidgetType.%s" % self.widget_members[i] for i in items) if items else ""))
        else:
            w("/// A handle of the library.")
        w("pub const %s = enum(Rid) {" % name)
        w("    _,")
        w("")
        w("    /// The handle of an id; null for 0 and invalid_id.")
        w("    pub fn fromId(id: Rid) ?%s {" % name)
        w("        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);")
        w("    }")
        w("")
        w("    /// The id of the handle, for raven.c.")
        w("    pub fn toId(self: %s) Rid {" % name)
        w("        return @backingInt(self);")
        w("    }")
        if base == "widget":
            items = self.widget_items.get(prefix, [])
            w("")
            w("    /// The types of widget that are a %s." % name)
            members_ = [".%s" % ident(self.widget_members[i]) for i in items]
            w("    pub const widget_types = [_]WidgetType{%s};" % (members_[0] if len(members_) == 1 else " %s " % ", ".join(members_) if members_ else ""))
            w("")
            w("    /// The widget, for the functions of every widget.")
            w("    pub fn widget(self: %s) Widget {" % name)
            w("        return @fromBackingInt(@backingInt(self));")
            w("    }")
            has_create = any(rest == "create" for f, rest, _ in members)
            if not has_create and len(items) == 1:
                w("")
                w("    /// A new %s (Rwidget_create(R_WIDGET_%s))." % (name, items[0][len("R_WIDGET_"):]))
                w("    pub fn create() %s {" % name)
                w("        return @fromBackingInt(c.Rwidget_create(c.%s));" % items[0])
                w("    }")
                scope.add("create")
            elif not has_create:
                for item in items:
                    cname = "create" + {"vbox": "VBox", "hbox": "HBox"}.get(self.widget_members[item], pascal(self.widget_members[item]))
                    w("")
                    w("    /// A new %s (Rwidget_create(R_WIDGET_%s))." % (name, item[len("R_WIDGET_"):]))
                    w("    pub fn %s() %s {" % (cname, name))
                    w("        return @fromBackingInt(c.Rwidget_create(c.%s));" % item)
                    w("    }")
                    scope.add(cname)
        if prefix == "widget":
            w("")
            w("    /// The widget as a kind, when it is one: `widget.as(Button)`.")
            w("    pub fn as(self: Widget, comptime T: type) ?T {")
            w("        const kind: WidgetType = @fromBackingInt(c.Rwidget_get_type(@backingInt(self)));")
            w("        inline for (T.widget_types) |t| {")
            w("            if (kind == t) return @fromBackingInt(@backingInt(self));")
            w("        }")
            w("        return null;")
            w("    }")
            w("")
            w("    /// The widget as a kind, without checking that it is one.")
            w("    pub fn asUnchecked(self: Widget, comptime T: type) T {")
            w("        return @fromBackingInt(@backingInt(self));")
            w("    }")
        for oname, (owner_prefix, code) in sorted(OVERRIDES.items()):
            if owner_prefix == prefix and oname in self.names:
                w("")
                out.extend(("    " + line).rstrip() for line in code.strip("\n").split("\n"))
        self.qualifier = name
        for f, rest, mname in members:
            is_method = bool(f.params) and f.params[0].ctype == "Rid"
            w("")
            if is_method:
                lines = self.function(f, mname, prefix, rest, name, scope)
            else:
                lines = self.function(f, mname, prefix, rest, None, scope)
            out.extend("    " + line for line in lines)
        w("};")
        w("")


HEADER = """
//! Raven for Zig: the idiomatic API.
//!
//! Generated from the C headers by tools/bindgen/gen_zig_wrapper.py (Raven {version}):
//! do not edit. The hand-written part is runtime.zig.
//!
//! The C API with the types and names of Zig, over the declarations of
//! bindings/zig/raven.zig (`raven.c`, for anything this does not cover):
//!
//!   - each kind of handle is a type, `enum(Rid) {{ _ }}`, whose methods are the
//!     C functions of that object: Rbutton_set_text(button, "OK") is
//!     `button.setText("OK")`, Rbutton_create("OK") is `Button.create("OK")`.
//!     A widget of a kind gives its Widget with `.widget()`; a Widget gives its
//!     kind with `.as(Button)` (null when it is another kind);
//!   - enumerations are enums (`.vulkan`, `.left`); flags are packed structs of
//!     bools (`.{{ .no_resize = true }}`);
//!   - structures are structs with defaults, bools, enums, optional handles
//!     and slices: `raven.initEx(.{{ .backend = .null, .headless = true }})`;
//!   - texts given are `[:0]const u8` (a string literal passes as it is); texts
//!     returned are `[:0]const u8` borrowed from the library (copy them to keep
//!     them); a text with its size, or an array with its count, is a slice;
//!   - what fails returns `Error!T` with the error the library recorded; a
//!     handle that may be none is an optional (`?Widget`);
//!   - values written through pointers are returned: `window.getSize()` is
//!     `.{{ .width, .height }}`; colors are a `Color`;
//!   - memory the library hands over is copied into an allocator given by the
//!     caller: `try raven.fileRead(allocator, "notes.txt")`;
//!   - callbacks are Zig functions known at compile time, with a typed context
//!     (a pointer, or `{{}}`):
//!
//!         button.setClickedCallback(&app, struct {{
//!             fn clicked(a: *App, b: raven.Button) void {{ ... }}
//!         }}.clicked);
//!
//!     `null` for the function removes the callback.
//!
//!     const raven = @import("raven");
//!
//!     pub fn main() !void {{
//!         try raven.init(.vulkan);
//!         defer raven.shutdown();
//!         const window = try raven.Window.createFromXml(
//!             \\\\<Window Title="Hi"><Button Text="Quit" OnClicked="quit"/></Window>
//!         );
//!         _ = window;
//!         raven.actionBind("quit", {{}}, struct {{
//!             fn quit(_: void, _: ?raven.Widget, _: [:0]const u8) void {{
//!                 raven.quit(0);
//!             }}
//!         }}.quit);
//!         while (raven.waitFrame(-1.0)) {{}}
//!     }}
//!
//! Raven belongs to the thread that starts it: call it from that thread only.
"""

COLOR = """
/// A color, components from 0 to 1.
pub const Color = extern struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 1,

    pub fn rgb(r: f32, g: f32, b: f32) Color {
        return .{ .r = r, .g = g, .b = b, .a = 1 };
    }

    pub fn rgba(r: f32, g: f32, b: f32, a: f32) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// 0xRRGGBB, opaque.
    pub fn hex(value: u24) Color {
        return .{
            .r = @as(f32, @floatFromInt((value >> 16) & 0xFF)) / 255.0,
            .g = @as(f32, @floatFromInt((value >> 8) & 0xFF)) / 255.0,
            .b = @as(f32, @floatFromInt(value & 0xFF)) / 255.0,
            .a = 1,
        };
    }
};

/// Pixels, RGBA8, in memory of the allocator that was given.
pub const Pixels = struct {
    pixels: []u8,
    width: i32,
    height: i32,

    pub fn deinit(self: Pixels, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }
};
"""

# Functions written by hand, what the rules above cannot say: name -> (the
# prefix of the handle type they are a method of, or None, the Zig code).
OVERRIDES = {
    # errorGetLast, lastError and check are written with the errors
    "Rerror_get_last": (None, ""),
    # setAllocator (runtime.zig) takes a std.mem.Allocator
    "Rset_allocator": (None, ""),
    "Rtheme_get_system_dark": (None, r"""
/// Whether the system is in dark mode; null when the platform does not tell.
pub fn themeGetSystemDark() ?bool {
    const result = c.Rtheme_get_system_dark();
    return if (result < 0) null else result != 0;
}
"""),
    "Rfile_read": (None, r"""
/// The content of a file (or of a file registered in memory), copied into
/// memory of `allocator`. Fails with the error the library recorded, or
/// FileNotFound when it recorded none (the file cannot be read).
pub fn fileRead(allocator: std.mem.Allocator, path: [:0]const u8) (Error || std.mem.Allocator.Error)![]u8 {
    var size: usize = 0;
    const data = c.Rfile_read(path.ptr, &size) orelse return switch (lastError()) {
        error.Failed => error.FileNotFound,
        else => |e| e,
    };
    defer c.Rmemory_free(data);
    return allocator.dupe(u8, @as([*]const u8, @ptrCast(data))[0..size]);
}
"""),
    "Rimage_decode": (None, r"""
/// Decodes an image file held in memory (PNG, JPEG...) into RGBA pixels in
/// memory of `allocator`.
pub fn imageDecode(allocator: std.mem.Allocator, data: []const u8) (Error || std.mem.Allocator.Error)!Pixels {
    var width: c_int = 0;
    var height: c_int = 0;
    const pixels = c.Rimage_decode(data.ptr, data.len, &width, &height) orelse return lastError();
    defer c.Rpixels_free(pixels);
    const size = @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4;
    return .{ .pixels = try allocator.dupe(u8, pixels[0..size]), .width = width, .height = height };
}
"""),
    "Rwindow_capture": ("window", r"""
/// What the window shows, as RGBA pixels in memory of `allocator`.
pub fn capture(self: Window, allocator: std.mem.Allocator) (Error || std.mem.Allocator.Error)!Pixels {
    var width: c_int = 0;
    var height: c_int = 0;
    const pixels = c.Rwindow_capture(@backingInt(self), &width, &height) orelse return lastError();
    defer c.Rpixels_free(pixels);
    const size = @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4;
    return .{ .pixels = try allocator.dupe(u8, pixels[0..size]), .width = width, .height = height };
}
"""),
    "Rpdf_document_save_memory": ("pdf_document", r"""
/// The PDF file of the document, copied into memory of `allocator`.
pub fn saveMemory(self: PdfDocument, allocator: std.mem.Allocator) (Error || std.mem.Allocator.Error)![]u8 {
    var size: usize = 0;
    const data = c.Rpdf_document_save_memory(@backingInt(self), &size) orelse return lastError();
    defer c.Rmemory_free(data);
    return allocator.dupe(u8, @as([*]const u8, @ptrCast(data))[0..size]);
}
"""),
}


def override_name(code):
    return re.search(r"pub fn (\w+)", code).group(1)


def fallbacks_report(gen):
    lines = ["# What the Zig layer does not map yet", "",
             "Written by tools/bindgen/gen_zig_wrapper.py: do not edit. Each line is a",
             "function, a field or a table entry the generator could not make idiomatic.",
             "The API is still whole: these functions take and return the types of",
             "`raven.c`. To map one, add what it needs to the tables at the top of",
             "gen_zig_wrapper.py (HANDLE_PARAMS, RETURNS, OVERRIDES...) and run",
             "`python tools/bindgen/bindgen.py`.", ""]
    seen = set()
    entries = [e for e in gen.fallbacks if not (e in seen or seen.add(e))]
    if not entries:
        lines.append("Nothing: every function, structure and callback is mapped.")
    for name, why in sorted(entries):
        lines.append("- `%s`: %s" % (name, why.replace("\n", " ")))
    return "\n".join(lines) + "\n"


def generate(api):
    gen = Gen(api)
    text = gen.generate()
    if gen.fallbacks:
        import sys
        print("gen_zig_wrapper: %d things written with the types of C (bindings/zig/FALLBACKS.md)" % len(set(gen.fallbacks)), file=sys.stderr)
    return {"zig/src/raven.zig": text, "zig/FALLBACKS.md": fallbacks_report(gen)}


def main():
    """
    On its own (it is not in the list of bindgen.py, so that the branch that
    holds it only adds files to the repository):

        python tools/bindgen/gen_zig_wrapper.py           writes bindings/zig/src/raven.zig and FALLBACKS.md
        python tools/bindgen/gen_zig_wrapper.py --check   fails when they are not what would be written
    """
    import os
    import sys
    here = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, here)
    import cparse
    root = os.path.dirname(os.path.dirname(here))
    check = "--check" in sys.argv
    api = cparse.parse(os.path.join(root, "include"))
    stale = []
    for path, text in sorted(generate(api).items()):
        full = os.path.join(root, "bindings", path)
        current = open(full, encoding="utf-8").read() if os.path.exists(full) else None
        if current == text:
            continue
        stale.append(path)
        if not check:
            os.makedirs(os.path.dirname(full), exist_ok=True)
            with open(full, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(text)
    if check and stale:
        print("bindings/ is out of date (run tools/bindgen/gen_zig_wrapper.py): " + ", ".join(stale))
        return 1
    print("zig wrapper: %d functions, %d enums, %d structures, %d callbacks%s" % (
        len(api.functions), len(api.enums), len(api.structs), len(api.callbacks),
        "" if check else " (%d files written)" % len(stale)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
