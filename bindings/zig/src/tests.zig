//! The idiomatic API against the library, headless: the null backend, no
//! window system, no GPU. `zig build test`.
//!
//! Raven starts once per process and belongs to the thread that starts it, so
//! the checks are the steps of one test, in the order a program would do them.

const std = @import("std");
const raven = @import("raven");
const testing = std.testing;

/// The errors the library reported through the callback.
var reported: struct {
    count: usize = 0,
    code: raven.ErrorCode = .no_error,
    detail: [256]u8 = undefined,
    detail_len: usize = 0,
} = .{};

fn onError(code: raven.ErrorCode, severity: raven.Severity, detail: [:0]const u8) void {
    _ = severity;
    reported.count += 1;
    reported.code = code;
    reported.detail_len = @min(detail.len, reported.detail.len);
    @memcpy(reported.detail[0..reported.detail_len], detail[0..reported.detail_len]);
}

fn lastReported() []const u8 {
    return reported.detail[0..reported.detail_len];
}

const Rows = struct {
    prefix: []const u8,
    buffer: [64]u8 = undefined,

    fn text(rows: *Rows, view: raven.ListView, index: i32) ?[:0]const u8 {
        _ = view;
        return std.fmt.bufPrintSentinel(&rows.buffer, "{s} {d}", .{ rows.prefix, index }, 0) catch null;
    }
};

test "raven, headless" {
    // all the memory of the library from a Zig allocator, checked for leaks
    var debug_allocator: std.heap.DebugAllocator(.{ .thread_safe = true }) = .init;
    raven.setAllocator(debug_allocator.allocator());

    try raven.initEx(.{ .backend = .null, .headless = true, .app_name = "raven-zig-tests" });
    {
        defer raven.shutdown();
        raven.errorSetCallback(onError);
        try versionAndErrors();
        try windowsAndWidgets();
        try xmlDocuments();
        try callbacks();
        try structuresAndColors();
        try memoryAndFiles();
        try translations();
    }
    // Raven gave back every block it took from the Zig allocator
    raven.setAllocator(null);
    try testing.expectEqual(std.heap.Check.ok, debug_allocator.deinit());
}

fn versionAndErrors() !void {
    try testing.expect(raven.getVersion().len > 0);
    try testing.expectEqual(@as(u32, 0), raven.version.major);

    // an error of the caller: reported to the callback, and recorded
    const not_a_widget: raven.Widget = @fromBackingInt(0x12345);
    not_a_widget.setTooltip("x");
    try testing.expectEqual(raven.ErrorCode.invalid_id, reported.code);
    try testing.expect(std.mem.indexOf(u8, lastReported(), "Rwidget_set_tooltip") != null);
    try testing.expectError(error.InvalidId, raven.check());
    try raven.check(); // cleared
    try testing.expectEqual(@as(?raven.Widget, null), raven.Widget.fromId(raven.invalid_id));
}

fn windowsAndWidgets() !void {
    // a document that is not XML: an error union, not an invalid id
    try testing.expectError(error.Xml, raven.Window.createFromXml("<Window><VBox></Window>"));
    _ = raven.errorGetLast();

    const window = raven.Window.create("Zig", 320, 240, .{ .hidden = true });
    defer window.destroy();
    try testing.expectEqualStrings("Zig", window.getTitle());
    window.setTitle("Zig, again");
    try testing.expectEqualStrings("Zig, again", window.getTitle());

    // kinds of widgets are types; a Widget gives its kind back
    const panel = raven.Panel.createVBox();
    const button = raven.Button.create("OK");
    const label = raven.Label.create("Text");
    _ = panel.widget().addChild(button.widget());
    _ = panel.widget().addChild(label.widget());
    window.setContent(panel.widget());

    try testing.expectEqual(raven.WidgetType.button, button.widget().getType());
    const as_widget = button.widget();
    try testing.expect(as_widget.as(raven.Button) != null);
    try testing.expect(as_widget.as(raven.Label) == null);
    try testing.expect(panel.widget().as(raven.Panel) != null);
    try testing.expectEqual(@as(?raven.Widget, panel.widget()), window.getContent());

    // names, optionals
    label.widget().setName("caption");
    const found = panel.widget().find("caption") orelse return error.NotFound;
    try testing.expectEqual(label.widget(), found);
    try testing.expectEqual(@as(?raven.Widget, null), panel.widget().find("nothing"));

    // texts in and out, a NULL text given as null
    button.setText("Apply");
    label.setText("Caption");
    try testing.expectEqualStrings("Caption", label.getText());
    label.widget().setTooltip("A caption");
    label.widget().setTooltip(null);

    // values written through pointers come back as a struct
    window.setSize(400, 300);
    const size = window.getSize();
    try testing.expectEqual(@as(i32, 400), size.width);
    try testing.expectEqual(@as(i32, 300), size.height);
}

fn xmlDocuments() !void {
    // a mistake, described in a structure given as an optional pointer
    var mistake: raven.XmlError = .{};
    try testing.expectError(error.Xml, raven.XmlDocument.parse("<A><B></A>", &mistake));
    try testing.expectEqual(@as(i32, 1), mistake.line);
    try testing.expect(std.mem.indexOf(u8, mistake.text(), "does not match") != null);
    _ = raven.errorGetLast();

    const document = try raven.XmlDocument.parse("<VBox><Label Text='x'/></VBox>", null);
    defer document.destroy();
    const root = document.getRoot() orelse return error.NoRoot;
    try testing.expectEqualStrings("VBox", root.getTag());
    try testing.expectEqual(@as(i32, 1), root.getChildCount());
    try testing.expectEqual(@as(?[:0]const u8, null), root.getAttribute("Nope"));
    const child = root.getChild(0) orelse return error.NoChild;
    child.setAttribute("Text", "é & <");
    try testing.expect(std.mem.indexOf(u8, document.toString(), "Text=\"é &amp; &lt;\"") != null);
}

fn callbacks() !void {
    // a callback that returns a text, with a typed context
    var rows: Rows = .{ .prefix = "row" };
    const list = raven.ListView.create();
    defer list.widget().destroy();
    list.setVirtualItems(3, &rows, Rows.text);
    try testing.expectEqualStrings("row 2", list.getItemText(2));
    list.setVirtualItems(0, {}, null);

    // actions, a context that is a counter
    var fired: u32 = 0;
    raven.actionBind("count", &fired, struct {
        fn count(counter: *u32, sender: ?raven.Widget, action: [:0]const u8) void {
            std.debug.assert(sender == null);
            std.debug.assert(std.mem.eql(u8, action, "count"));
            counter.* += 1;
        }
    }.count);
    raven.actionFire("count", null);
    raven.actionFire("count", null);
    try testing.expectEqual(@as(u32, 2), fired);
    raven.actionUnbind("count");

    // a click, through a window, reaches a Zig function with its Button
    const window = try raven.Window.createFromXml(
        \\<Window Title="Click" Width="200" Height="100">
        \\    <Button Name="b" Text="Click"/>
        \\</Window>
    );
    defer window.destroy();
    const content = window.getContent() orelse return error.NoContent;
    const button = (content.find("b") orelse return error.NoButton).as(raven.Button) orelse return error.NotAButton;
    var clicked: ?raven.Button = null;
    button.setClickedCallback(&clicked, struct {
        fn onClicked(out: *?raven.Button, b: raven.Button) void {
            out.* = b;
        }
    }.onClicked);
    _ = raven.drawFrame();
    const rect = button.widget().getRect();
    window.injectMouseMove(rect.x + rect.width / 2, rect.y + rect.height / 2);
    window.injectMouseButton(.left, true);
    window.injectMouseButton(.left, false);
    try testing.expectEqual(@as(?raven.Button, button), clicked);
}

fn structuresAndColors() !void {
    // a Color in and out
    const label = raven.Label.create("Colored");
    defer label.widget().destroy();
    label.widget().setColor(.panel, .rgba(0.25, 0.5, 0.75, 1));
    const color = label.widget().getColor(.panel);
    try testing.expectApproxEqAbs(@as(f32, 0.5), color.g, 0.01);

    // a structure the library reads and writes, with methods
    var spring: raven.Spring = .{};
    spring.set(2);
    try testing.expectEqual(@as(f32, 2), spring.value);
    spring.kick(10);
    try testing.expectEqual(@as(f32, 10), spring.velocity);

    // a structure returned, in Zig types
    const stats = raven.memoryGetStats();
    try testing.expect(stats.total_allocations > 0);
    const settings = raven.touchGetDefaultSettings();
    try testing.expect(settings.mouse_emulation);
}

fn memoryAndFiles() !void {
    // the heap of Raven as a std.mem.Allocator
    var list: std.ArrayList(u32) = .empty;
    defer list.deinit(raven.heap_allocator);
    for (0..1000) |i| try list.append(raven.heap_allocator, @intCast(i));
    try testing.expectEqual(@as(u32, 999), list.items[999]);

    // files: bytes in, bytes out, into the allocator of the caller
    const path = "raven_zig_test.bin";
    try raven.fileWrite(path, "a\x00b");
    const data = try raven.fileRead(testing.allocator, path);
    defer testing.allocator.free(data);
    try testing.expectEqualSlices(u8, "a\x00b", data);
    std.Io.Dir.cwd().deleteFile(testing.io, path) catch {};

    try testing.expectError(error.FileNotFound, raven.fileRead(testing.allocator, "no/such/file.bin"));
    _ = raven.errorGetLast();
}

fn translations() !void {
    try testing.expect(raven.localeLoadCsvFromMemory("key,en,fr\nhello,Hello {0},Bonjour {0}\n") > 0);
    _ = raven.localeSetLanguage("fr");
    try testing.expectEqualStrings("Bonjour Zoé", raven.trFormat("hello", &.{"Zoé"}));
    try testing.expect(raven.trExists("hello"));
}
