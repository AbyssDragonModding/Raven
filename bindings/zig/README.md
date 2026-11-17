# Raven for Zig

A Zig package with two modules over the shared library of Raven:

| Module | File | What it is |
|---|---|---|
| `raven` | `src/raven.zig` (generated) + `src/runtime.zig` | The idiomatic API: typed handles with methods, error unions, optionals, slices, allocators, Zig callbacks. |
| `raven_c` | `raven.zig` (generated) | The C API as it is: `extern` declarations and `extern struct`s. Also reachable as `raven.c`. |

Both are written by `tools/bindgen` from the headers (`gen_zig_wrapper.py` and
`gen_zig.py`), so they always have the whole API: every function, enumeration,
structure and callback. Needs **Zig 0.17**.

```zig
const std = @import("std");
const raven = @import("raven");

const App = struct {
    title: raven.Label,
    clicks: u32 = 0,

    fn greet(app: *App, sender: ?raven.Widget, action: [:0]const u8) void {
        _ = sender;
        _ = action;
        app.clicks += 1;
        app.title.setText("Hello!");
    }
};

pub fn main() !void {
    try raven.init(.vulkan);
    defer raven.shutdown();

    const window = try raven.Window.createFromXml(
        \\<Window Title="Hello" Width="320" Height="160">
        \\    <VBox Spacing="10" Slot.Padding="16">
        \\        <Label Name="title" Text="Hi"/>
        \\        <Button Text="Greet" Style="Primary" OnClicked="greet"/>
        \\    </VBox>
        \\</Window>
    );
    const root = window.getContent().?;
    var app: App = .{ .title = root.find("title").?.as(raven.Label).? };
    raven.actionBind("greet", &app, App.greet);

    while (raven.waitFrame(-1.0)) {}
}
```

## The API

| C | Zig |
|---|---|
| `Rid` of a window, a button, a font... | A type per kind of handle, `enum(Rid) { _ }`: `Window`, `Button`, `Font`, `XmlNode`... The C functions of an object are its methods: `Rbutton_set_text(b, "OK")` is `b.setText("OK")`; those that make one are in its namespace: `Button.create("OK")`, `Window.createFromXml(xml)`. |
| A widget of a kind is a widget | `button.widget()` is its `Widget` (for `Rwidget_*`: `button.widget().setTooltip("...")`); `widget.as(Button)` is its kind, or null. |
| `R_INVALID_ID` | `null`: a handle that may be none is an optional (`root.find("x")` is `?Widget`). `T.fromId(id)` and `handle.toId()` go to and from `Rid`. |
| `int` R_TRUE / R_FALSE | `bool` |
| `int` R_FALSE on failure, `R_INVALID_ID` on failure | `Error!void`, `Error!T`: the error recorded by the library (`error.FileNotFound`, `error.Xml`...), `error.Failed` when it recorded none. `raven.check()` returns the last one; `raven.errorGetLast()` gives its severity and detail. |
| Enumerations | Zig enums: `.vulkan`, `.left`, `WidgetType.button`. |
| Flags | Packed structs of bools: `Window.create("Hi", 640, 480, .{ .no_resize = true })`. |
| Structures | Structs with defaults, bools, enums and slices: `raven.initEx(.{ .backend = .null, .headless = true })`. Each has `toC()` and `fromC()`. |
| `const char*` given | `[:0]const u8` (a string literal passes as it is); `?[:0]const u8` where NULL means something. |
| `const char*` returned | `[:0]const u8`, borrowed from the library: copy it to keep it (`allocator.dupe`). `?[:0]const u8` where NULL is an answer. |
| A text and its size, numbers and their count | Slices: `Window.createFromXml(xml)`, `chart.setValues(&.{ 1, 2, 3 })`, `raven.trFormat("key", &.{"a"})`. |
| Values written through pointers | Returned: `window.getSize()` is `.{ .width, .height }`; `widget.getColor(.panel)` is a `Color`. A structure the library fills is returned (`raven.memoryGetStats()`), one it may not fill is an optional. |
| Memory the caller frees | Copied into an allocator given by the caller: `try raven.fileRead(allocator, path)`, `try window.capture(allocator)` (a `Pixels`, `deinit(allocator)`). |
| `r, g, b, a` | `Color` (`.rgb(...)`, `.rgba(...)`, `.hex(0x3366FF)`). |
| `RPainter*` | `*Painter` with methods: `painter.rect(x, y, w, h, radius, color)`. |
| Callbacks and `void* user_data` | A Zig function known at compile time and a context: a pointer, or `{}`. `button.setClickedCallback(&app, App.onClicked)` with `fn onClicked(app: *App, button: Button) void`. `null` for the function removes it. |

Memory:

- `raven.heap_allocator` is the heap of Raven as a `std.mem.Allocator`.
- `raven.setAllocator(allocator)`, before `init`, gives all the memory of the
  library to a Zig allocator (it must be thread-safe):

  ```zig
  var debug: std.heap.DebugAllocator(.{ .thread_safe = true }) = .init;
  raven.setAllocator(debug.allocator());
  ```

Raven belongs to the thread that starts it: call it from that thread only.
Whatever this layer does not cover is in `raven.c`, the C API, in the same
program.

## Using it

Build Raven as a shared library first:

    cmake -B build -DRAVEN_BUILD_SHARED=ON
    cmake --build build --config Release

In your `build.zig.zon`:

```zig
.dependencies = .{
    .raven = .{ .path = "<Raven>/bindings/zig" },
},
```

In your `build.zig`:

```zig
const raven = b.dependency("raven", .{
    .target = target,
    .optimize = optimize,
    .@"lib-dir" = "<Raven>/build/Release", // raven.lib / libraven.so / libraven.dylib
});
exe.root_module.addImport("raven", raven.module("raven"));
```

The module links `raven` (and libc) and adds `lib-dir` to the library path
(and to the rpath on Linux and macOS). On Windows, put `raven.dll` beside the
program or on the `PATH`.

## In this folder

    zig build check     compiles every declaration of both modules; links nothing, needs no library
    zig build test      the headless tests (src/tests.zig) and the example with --test
    zig build run       the example (example/main.zig) in a window

Inside the repository the library of a CMake build in `../../build` is found
by itself (`build/Release`, `build/bin/Release` for the DLL...); elsewhere give
`-Dlib-dir=<folder>` and, on Windows, `-Dbin-dir=<folder of raven.dll>`.

`ctest` runs `binding_zig_wrapper` (`zig build check`) and, with
`RAVEN_BUILD_SHARED`, `binding_zig_wrapper_test` (`zig build test`).

## Regenerating

After a change to a public header:

    python tools/bindgen/bindgen.py

What the headers cannot say (which `int` is a bool, which function fails,
which handle a `Rid` is) is decided by the tables at the top of
`tools/bindgen/gen_zig_wrapper.py`; the generator stops with a message when it
meets something it cannot place, so that a new function is not left out.
