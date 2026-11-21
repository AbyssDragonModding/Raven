//! A window described in XML, driven from Zig through the idiomatic API.
//!
//!     zig build run
//!
//! `zig build run -- --test` (part of `zig build test`) runs without a window
//! system and without a GPU, clicks its own button and checks what happened:
//! the example of each binding of Raven does the same.

const std = @import("std");
const raven = @import("raven");

const xml =
    \\<Window Title="Raven from Zig" Width="360" Height="200">
    \\    <VBox Spacing="10" Slot.Padding="16">
    \\        <Label Name="title" Text="Hello from Zig" TextSize="20"/>
    \\        <TextInput Name="name" Placeholder="Your name"/>
    \\        <HBox Spacing="8">
    \\            <Button Name="greet" Text="Greet" Style="Primary" OnClicked="greet" Slot.Fill="1"/>
    \\            <Button Text="Quit" OnClicked="quit"/>
    \\        </HBox>
    \\    </VBox>
    \\</Window>
;

/// What the callbacks share: given to them as their context.
const App = struct {
    title: raven.Label,
    name: raven.TextInput,
    clicks: u32 = 0,
    buffer: [128]u8 = undefined,

    fn greet(app: *App, sender: ?raven.Widget, action: [:0]const u8) void {
        _ = sender;
        std.debug.assert(std.mem.eql(u8, action, "greet"));
        app.clicks += 1;
        const who = app.name.getText();
        const text = std.fmt.bufPrintSentinel(&app.buffer, "Hello, {s}!", .{if (who.len > 0) who else "you"}, 0) catch "Hello!";
        app.title.setText(text);
    }

    fn quit(_: *App, _: ?raven.Widget, _: [:0]const u8) void {
        raven.quit(0);
    }
};

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var test_mode = false;
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--test")) test_mode = true;
    }

    if (test_mode) {
        try raven.initEx(.{ .backend = .null, .headless = true });
    } else {
        try raven.init(.vulkan);
    }
    defer raven.shutdown();

    const window = try raven.Window.createFromXml(xml);
    const root = window.getContent() orelse return error.NoContent;
    var app: App = .{
        .title = (root.find("title") orelse return error.NoTitle).as(raven.Label) orelse return error.NotALabel,
        .name = (root.find("name") orelse return error.NoName).as(raven.TextInput) orelse return error.NotATextInput,
    };
    raven.actionBind("greet", &app, App.greet);
    raven.actionBind("quit", &app, App.quit);

    if (!test_mode) {
        while (raven.waitFrame(-1.0)) {}
        return;
    }

    // ---- the binding, checked
    _ = raven.drawFrame();
    try std.testing.expectEqualStrings("Raven from Zig", window.getTitle());
    try std.testing.expectEqual(raven.WidgetType.label, app.title.widget().getType());
    app.name.setText("Zoé");

    const greet = root.find("greet") orelse return error.NoButton;
    const rect = greet.getRect();
    try std.testing.expect(rect.width > 0 and rect.height > 0);
    window.injectMouseMove(rect.x + rect.width / 2, rect.y + rect.height / 2);
    window.injectMouseButton(.left, true);
    window.injectMouseButton(.left, false);
    try std.testing.expectEqual(@as(u32, 1), app.clicks);
    try std.testing.expectEqualStrings("Hello, Zoé!", app.title.getText());

    const size = window.getSize();
    try std.testing.expectEqual(@as(i32, 360), size.width);
    try std.testing.expectEqual(@as(i32, 200), size.height);

    raven.actionFire("quit", null);
    try std.testing.expect(!raven.isRunning());
    std.debug.print("zig binding: ok\n", .{});
}
