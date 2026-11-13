<span style="display: flex; justify-content: center;">
	<img src="https://raw.githubusercontent.com/oscar-soirey/Raven/refs/heads/main/docs/images/logo-com.png" alt="Raven Logo" width=128/>
	<img src="https://c3-lang.org/assets/logo.svg" alt="c3-logo" width=215>
</span>
<span style="display: flex; justify-content: center;"><h1> Raven GUI - C3 Bindings </h1></span>



## Description
These are the C3 bindings for Raven GUI library [Raven Github](https://github.com/oscar-soirey/Raven). 

There is two APIs in this library the C3 idiom wrapped API `import raven;`, and the fallback C api under `import raven::c;` for the C api specifically the functions are slightly changed due to C3s naming rules, so `Rinit()` becomes `raven::c::r_init()` in c3s C API

## Installing the library
Installing the library into a c3 binary project is straight forward. Copy the `raven.c3l` folder into your projects `lib` folder and add the following to your projects `project.json`

```json 
"dependencies": [ "raven" ]
```

you do need the shared libs for your platform to be included into `linked-libs\platform` folder

## Generating the bindings (if they're outdated)
The bindings are written by `tools/bindgen/gen_c3.py`, one of the generators of Raven's `tools/bindgen`, and are regenerated with the others (`python tools/bindgen/bindgen.py`). It only needs Python 3: it uses the header reader of the other generators (`tools/bindgen/cparse.py`), so no libclang is required. From a checkout of Raven:

```bash
python tools/bindgen/bindgen.py c3              # writes bindings/c3/raven.c3l/src
python tools/bindgen/bindgen.py --check         # fails when any binding is out of date
```

It can also run on its own:

```bash
python tools/bindgen/gen_c3.py .                # uses this checkout
python tools/bindgen/gen_c3.py                  # clones Raven (latest)
python tools/bindgen/gen_c3.py --ref v0.2.3     # clones a tag or branch
python tools/bindgen/gen_c3.py -o some/dir      # writes somewhere else
```

It writes two files into `src/`:

- `raven_c.c3` (`raven::c`) - the whole C API as it is in the headers, 1:1, a fallback for anything `raven` does not cover. It stands on its own (it does not import `raven`) and has the types and constants of C: `Rid`, `RWidgetType`, `RRect`, `R_INVALID_ID`, `R_WIDGET_BUTTON`, `R_COLOR_COUNT`, the end marks (`R_WIDGET_LAST_`)... An enumeration is a `CInt` and texts are `char*`. Every function is an `extern fn` bound to the C function by `@cname`, under its C name in snake_case, since a C3 function cannot start with a capital: `Rinit` is `raven::c::r_init` and `Rbutton_set_text` is `raven::c::r_button_set_text`. The macros are C3 macros (`R_ID_INDEX` is `r_id_index`, `Rerror_check()` is `r_error_check()`), and the function pointers of structures (`RBackendVTable`, `RAllocator`, `RHostPlatformDesc`) have their own types. It covers every header of `Raven.h`, `raven_vulkan.h` and `raven_backend.h` included, and `raven_web.h` (web views are part of the same library). It leaves out only `raven_emscripten.h`, which exists only in the WebAssembly build.
- `raven.c3` (`raven`) - the C3 API described below, written over `raven::c`.

Both files carry the documentation comments of the C headers as `<* ... *>`. Only the description is kept, with no `@param` lines and nothing C3 would read as a contract.

`../tests/` has the first program of the guide written with each module, both in code and loaded from XML. See `../tests/README.md`.

The only additional thing you need to do is update the dynamic libraries for linking under the `linked-libs/platform` folders.

## The C3 API
- **Naming:** types and constsets are PascalCase without the `R` (`RWidgetType` is `WidgetType`). Their values drop the common prefix (`R_WIDGET_BUTTON` is `WidgetType.BUTTON`). Constants are MACRO_CASE (`R_INVALID_ID` is `INVALID_ID`), and everything else is snake_case.
- **Handles are typed:** `Window`, `Widget`, `Button`, `TextEditor`, `XmlNode`... are `typedef`s of `Id`, chained with `inline` (a `Button` is a `Widget`, which is an `Id`). The C functions of an object are its methods: `Rbutton_set_text(button, "OK")` is `button.set_text("OK")`. Going the other way takes a cast: `(Button)widget`.
- **Constructors are functions:** `raven::button_create("OK")` returns a `Button`, and `raven::vbox_create()` returns a `Panel`.
- **Errors are faults:** `RError` maps to `ERROR_INVALID_ID`, `ERROR_XML`, ... What can fail returns an Optional carrying the fault from `Rerror_get_last` (`ERROR_FAILED` when nothing was recorded): `raven::init(...)`, `window.set_theme(...)`, `raven::font_create_from_file(...)`, `raven::window_create_from_xml(...)`, and others. `raven::check()!;` raises any pending error.
- **Yes/no values are `bool`:** functions that answer yes or no return `bool`, and parameters like `enabled` or `visible` take one.
- **Slices:** a pointer and its count are one slice: `plot.set_series_data(0, xs, ys)`, `raven::tr_format("key", args)`, `browser.set_filters(filters)`, `raven::shader_create(spirv_bytes, flags)`. XML given as text is a `String`: `raven::window_create_from_xml(xml)`.
- **Results instead of out-pointers:** what C fills through pointers is returned. Several numbers are a vector: `window.get_size()` is a `CInt[<2>]`, `widget.get_rect()` a `float[<4>]` (`{ x, y, width, height }`), `color_picker.get_color()` a `float[<4>]`. A structure is returned by value: `raven::memory_get_stats()`, `window.get_frame_stats()`, or as an Optional when C can fail: `window.get_native_handle()!`.
- **Struct methods:** the functions of a structure are its methods: `spring.kick(2.0)`, `look.init()`. Handles also have `.is_valid()` and `.index()`.
- **Memory:** memory Raven gives to the application is released the C3 way. `raven::file_read(path)` returns a `char[]` copied with an `Allocator` (`mem` by default, or `tmem`, or any other) and frees Raven's buffer. `window.capture()` and `raven::image_decode(bytes)` return `Pixels`, released with `pixels.free()` (`defer pixels.free();`).
- **Enums are `constset`s** with the C values. Flag sets combine with `|` and have `.has(flag)`.
- **Strings:** every `char*` / `const char*` is a `ZString`. A string literal passes as it is; a `String` goes through `.zstr_tcopy()`.
- **Names:** `RAllocator` is `MemoryAllocator`, so that `Allocator` stays the one of C3.
- **Callbacks:** C3 lambdas don't capture, so callbacks keep their `void* user_data`.
- **Painter:** paint callbacks receive a `Painter*`; draw with `painter.rect(...)`.

# Examples

## Hello Window in C3 with the C api
```c++
// Hello window in c3 example using the C3 raven::c fallback API
module hello_window;
import std::io;
import raven;

fn void on_quit(raven::c::Rid button, void* user_data) {
    (void)button;
    (void)user_data;
    raven::c::r_quit(0);
}

fn int main(String[] args)
{
    if(!raven::c::r_init(raven::c::R_BACKEND_VULKAN)) return 1;
    defer raven::c::r_shutdown();

    raven::c::Rid window = raven::c::r_window_create("Hello", 420, 220, raven::c::R_WINDOW_DEFAULT);
    raven::c::Rid box = raven::c::r_widget_create(raven::c::R_WIDGET_VBOX);
    raven::c::r_panel_set_spacing(box, 12);
    raven::c::r_slot_set_halign(box, raven::c::R_HALIGN_CENTER);
    raven::c::r_slot_set_valign(box, raven::c::R_VALIGN_CENTER);
    raven::c::r_window_set_content(window, box);

    raven::c::r_widget_add_child(box, raven::c::r_label_create("Hello from raven, in C3"));
    raven::c::Rid quit = raven::c::r_widget_add_child(box, raven::c::r_button_create("Quit"));
    raven::c::r_button_set_clicked_callback(quit, &on_quit, null);

    while(raven::c::r_wait_frame(-1.0)) {}
    return raven::c::r_get_exit_code();
}
```
## Hello window in C3 with the C3 wrapper API
```c++
// Hello window in c3 example using the C3 raven module API
module hello_window;
import std::io;
import raven;

fn void on_quit(Id button, void* user_data) {
    raven::quit(0);
}

fn int main(String[] args)
{
    if(catch err = raven::init(raven::Backend.VULKAN)) {
        io::printfn("Failed to initialize raven: %s", err);
        return 1;
    }
    defer raven::shutdown();

    Window window = raven::window_create("Hello", 420, 220, raven::WindowFlags.DEFAULT);

    Panel box = raven::vbox_create();
    box.set_spacing(12);
    box.slot_set_valign(raven::VAlign.CENTER);
    box.slot_set_halign(raven::HAlign.CENTER);
    
    window.set_content(box);

    box.add_child(raven::label_create("Hello from raven, in C3"));
    Button quit = (Button)box.add_child(raven::button_create("Quit"));
    quit.set_clicked_callback(&on_quit, null);

    while(raven::wait_frame(-1.0)) {}
    return raven::get_exit_code();
}
```
## Hello Window with xml and C API
```c++
// Hello window in c3 example but using the raven::c fallback API and xml file

module hello_window;
import raven;

fn void on_quit(raven::c::Rid sender, char* action, void* user_data)
{
    (void)sender;
    (void)action;
    (void)user_data;
    raven::c::r_quit(0);
}


fn int main(String[] args)
{
    if (!raven::c::r_init(raven::c::R_BACKEND_VULKAN)) return 1;
    defer raven::c::r_shutdown();
    
    raven::c::r_action_bind("app.quit", &on_quit, null);
    if(raven::c::r_window_create_from_xml_file("./src/hello.xml") == raven::c::R_INVALID_ID) return 1;

    while(raven::c::r_wait_frame(-1.0)){}
    return raven::c::r_get_exit_code();
}
```

## Hello window with xml and C3 wrapped API
```c++
// Hello window in c3 example using the C3 raven module API and xml files

module hello_window;
import std::io;
import raven;

fn void on_quit(Id sender, ZString action, void* user_data)
{
    raven::quit(0);
}


fn int main(String[] args)
{
    if (catch err = raven::init(raven::Backend.VULKAN)) {
        io::printfn("Failed to initialize Raven: %s", err);
        return 1;
    }
    defer raven::shutdown();
    
    raven::action_bind("app.quit", &on_quit, null);
    if (catch err = raven::window_create_from_xml_file("./src/hello.xml")) {
        io::printfn("Failed to create window: %s", err);
        return 1;
    }

    while(raven::wait_frame(-1.0)){}
    return raven::get_exit_code();
}

```