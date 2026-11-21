# Raven for Zig

A Zig package with two modules over the shared library of Raven:

| Module | File | What it is |
|---|---|---|
| `raven` | `src/raven.zig` (generated) + `src/runtime.zig` | The idiomatic API: typed handles with methods, error unions, optionals, slices, allocators, Zig callbacks. |
| `raven_c` | `raven.zig` (generated) | The C API as it is: `extern` declarations and `extern struct`s. Also reachable as `raven.c`. |

Both are written by `tools/bindgen` from the headers (`gen_zig_wrapper.py` and
`gen_zig.py`, the generator of Raven), so they always have the whole API: every function, enumeration,
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

`ctest` runs `binding_zig_wrapper_up_to_date`, `binding_zig_wrapper` (`zig build check`) and, with
`RAVEN_BUILD_SHARED`, `binding_zig_wrapper_test` (`zig build test`), from `tests.cmake`.

## Staying up to date with Raven

The Zig layer lives on the branch `zig-wrapper` of this fork, which follows
`main`. It only adds files to Raven (`bindings/zig/`, `tools/bindgen/gen_zig_wrapper.py`,
`tools/bindgen/update_zig_wrapper.py`) and one `include()` at the end of
`bindings/CMakeLists.txt`, so that merging the updates of Raven never conflicts.

**By itself**: the workflow `ci/zig-wrapper.yml` runs whenever
`main` changes (a "Sync fork", a push of the updates of Raven), every day, and
by hand (Actions > Zig wrapper > Run workflow). It merges `main` into
`zig-wrapper`, writes the Zig API again from the new headers, checks that it
compiles (`zig build check`), commits and pushes. When the merge conflicts or
the new API does not compile, the run fails and the branch stays as it was.
GitHub starts a workflow on a push to `main` or on a schedule only from the
default branch, so it is installed once on `main` (a file of its own there;
"Sync fork" keeps it):

    git switch main
    git checkout zig-wrapper -- bindings/zig/ci/zig-wrapper.yml
    git mv bindings/zig/ci/zig-wrapper.yml .github/workflows/zig-wrapper.yml
    git commit -m "CI: keep the Zig wrapper up to date" && git push

(Pushing a workflow needs a token with the `workflow` scope; the file can also
be added on github.com: Add file > Create new file. Actions must be enabled
for the fork: the Actions tab of the repository.) When an update of Raven
changes Raven's own workflows, GitHub refuses that merge from the token of the
run: add a secret `ZIG_WRAPPER_TOKEN` (a personal access token with Contents
and Workflows read and write on the fork), which the workflow then uses.

**From a clone**, the same in one command:

    git switch zig-wrapper
    python tools/bindgen/update_zig_wrapper.py           # merge origin/main, regenerate, check, commit, push
    python tools/bindgen/update_zig_wrapper.py --test    # also the headless tests (rebuild the library first)
    python tools/bindgen/update_zig_wrapper.py --no-push

New functions, enumerations, structures and callbacks are mapped by the same
rules as the others. What the generator cannot make idiomatic (a parameter
whose handle it cannot tell, a shape it has not seen) is not left out: it is
written with the types of `raven.c`, and listed in `FALLBACKS.md` (empty when
everything is mapped). To map one, add what it needs to the tables at the top
of `tools/bindgen/gen_zig_wrapper.py` (`HANDLE_PARAMS`, `RETURNS`,
`BOOL_RETURNS`, `FALLIBLE_BOOL`, `OVERRIDES`...).

## Regenerating by hand

    python tools/bindgen/gen_zig_wrapper.py            # writes src/raven.zig and FALLBACKS.md
    python tools/bindgen/gen_zig_wrapper.py --check    # fails when they are out of date (ctest: binding_zig_wrapper_up_to_date)

`raven.zig` (the C API) is written by Raven's own `tools/bindgen/bindgen.py`.
