//! Raven for Zig: the idiomatic API.
//!
//! Generated from the C headers by tools/bindgen/gen_zig_wrapper.py (Raven 0.3.0):
//! do not edit. The hand-written part is runtime.zig.
//!
//! The C API with the types and names of Zig, over the declarations of
//! bindings/zig/raven.zig (`raven.c`, for anything this does not cover):
//!
//!   - each kind of handle is a type, `enum(Rid) { _ }`, whose methods are the
//!     C functions of that object: Rbutton_set_text(button, "OK") is
//!     `button.setText("OK")`, Rbutton_create("OK") is `Button.create("OK")`.
//!     A widget of a kind gives its Widget with `.widget()`; a Widget gives its
//!     kind with `.as(Button)` (null when it is another kind);
//!   - enumerations are enums (`.vulkan`, `.left`); flags are packed structs of
//!     bools (`.{ .no_resize = true }`);
//!   - structures are structs with defaults, bools, enums, optional handles
//!     and slices: `raven.initEx(.{ .backend = .null, .headless = true })`;
//!   - texts given are `[:0]const u8` (a string literal passes as it is); texts
//!     returned are `[:0]const u8` borrowed from the library (copy them to keep
//!     them); a text with its size, or an array with its count, is a slice;
//!   - what fails returns `Error!T` with the error the library recorded; a
//!     handle that may be none is an optional (`?Widget`);
//!   - values written through pointers are returned: `window.getSize()` is
//!     `.{ .width, .height }`; colors are a `Color`;
//!   - memory the library hands over is copied into an allocator given by the
//!     caller: `try raven.fileRead(allocator, "notes.txt")`;
//!   - callbacks are Zig functions known at compile time, with a typed context
//!     (a pointer, or `{}`):
//!
//!         button.setClickedCallback(&app, struct {
//!             fn clicked(a: *App, b: raven.Button) void { ... }
//!         }.clicked);
//!
//!     `null` for the function removes the callback.
//!
//!     const raven = @import("raven");
//!
//!     pub fn main() !void {
//!         try raven.init(.vulkan);
//!         defer raven.shutdown();
//!         const window = try raven.Window.createFromXml(
//!             \\<Window Title="Hi"><Button Text="Quit" OnClicked="quit"/></Window>
//!         );
//!         _ = window;
//!         raven.actionBind("quit", {}, struct {
//!             fn quit(_: void, _: ?raven.Widget, _: [:0]const u8) void {
//!                 raven.quit(0);
//!             }
//!         }.quit);
//!         while (raven.waitFrame(-1.0)) {}
//!     }
//!
//! Raven belongs to the thread that starts it: call it from that thread only.

const std = @import("std");
const rt = @import("runtime.zig");

/// The C API as it is (bindings/zig/raven.zig), for anything this module does not cover.
pub const c = rt.c;
/// The id of an object of the library. 0 and `invalid_id` name nothing.
pub const Rid = c.Rid;
pub const invalid_id: Rid = c.R_INVALID_ID;
/// The version of the headers this module was generated from.
pub const version: std.SemanticVersion = .{ .major = 0, .minor = 3, .patch = 0 };
pub const api_version = c.RAVEN_API_VERSION;

pub const heap_allocator = rt.heap_allocator;
pub const setAllocator = rt.setAllocator;

/// The id of an optional handle: R_INVALID_ID for null.
fn optId(handle: anytype) Rid {
    return if (handle) |h| @backingInt(h) else invalid_id;
}

/// The errors of Raven (ErrorCode) as an error set, and Failed for a failure
/// the library did not describe.
pub const Error = error{
    InvalidId,
    InvalidEnum,
    InvalidValue,
    InvalidOperation,
    Backend,
    Platform,
    OutOfMemory,
    InvalidFileFormat,
    FileNotFound,
    Xml,
    WrongThread,
    Script,
    Failed,
};

/// The error of an ErrorCode; Failed for no_error.
pub fn errorFromCode(code: ErrorCode) Error {
    return switch (code) {
        .invalid_id => error.InvalidId,
        .invalid_enum => error.InvalidEnum,
        .invalid_value => error.InvalidValue,
        .invalid_operation => error.InvalidOperation,
        .backend => error.Backend,
        .platform => error.Platform,
        .out_of_memory => error.OutOfMemory,
        .invalid_file_format => error.InvalidFileFormat,
        .file_not_found => error.FileNotFound,
        .xml => error.Xml,
        .wrong_thread => error.WrongThread,
        .script => error.Script,
        else => error.Failed,
    };
}

/// The last error the library recorded (it is cleared), Failed when there is none.
pub fn lastError() Error {
    return errorFromCode(@fromBackingInt(c.Rerror_get_last(null, null)));
}

/// The last error recorded, with its severity and detail (and clears it), or null.
pub fn errorGetLast() ?struct { code: ErrorCode, severity: Severity, detail: [:0]const u8 } {
    var detail: ?[*:0]const u8 = null;
    var severity: c.RSeverity = 0;
    const code: ErrorCode = @fromBackingInt(c.Rerror_get_last(&detail, &severity));
    if (code == .no_error) return null;
    return .{ .code = code, .severity = @fromBackingInt(severity), .detail = rt.span(detail) };
}

/// Returns the last error recorded (and clears it), if there is one: `try raven.check();`.
pub fn check() Error!void {
    const code: ErrorCode = @fromBackingInt(c.Rerror_get_last(null, null));
    if (code != .no_error) return errorFromCode(code);
}

pub const Backend = enum(c_int) {
    /// The renderer of the platform: WebGL in browser builds, Metal on macOS and iOS when it is compiled, Vulkan otherwise.
    default = 0,
    /// Built-in Vulkan renderer.
    vulkan = 1,
    /// Renders nothing. Used for headless runs and unit tests.
    null = 2,
    /// Backend supplied with Rbackend_register (see raven_backend.h).
    custom = 3,
    /// Browser renderer (Emscripten, WebGL 2).
    webgl = 4,
    /// Built-in Metal renderer (macOS, iOS).
    metal = 5,
    _,
};

pub const ErrorCode = enum(c_int) {
    no_error = 0x0070,
    invalid_id = 0x0071,
    invalid_enum = 0x0072,
    invalid_value = 0x0073,
    invalid_operation = 0x0074,
    backend = 0x0075,
    platform = 0x0076,
    out_of_memory = 0x0077,
    invalid_file_format = 0x0078,
    file_not_found = 0x0079,
    xml = 0x007A,
    wrong_thread = 0x007B,
    /// A diagnostic of Raven Script (raven_script.h): the text is the whole message, "error[RS102]: ...".
    script = 0x007C,
    _,
};

pub const Severity = enum(c_int) {
    weak_warning = 0x0080,
    warning = 0x0081,
    @"error" = 0x0082,
    fatal = 0x0083,
    _,
};

/// What the system does with the application, on iOS and Android (desktop
/// systems send none of these). A pause is not always followed by
/// R_APP_DID_PAUSE: pulling down the notifications (iOS) or a dialog of the
/// system in front (Android) gives R_APP_WILL_PAUSE, then R_APP_DID_RESUME.
/// At the start, R_APP_WILL_RESUME and R_APP_DID_RESUME may come too.
///
///   leaving the front   R_APP_WILL_PAUSE    still seen: save what must not be lost
///   in the background   R_APP_DID_PAUSE     not seen, no GPU work: Raven stops drawing
///   coming back         R_APP_WILL_RESUME   Raven draws again
///   in front again      R_APP_DID_RESUME    takes input again
pub const AppEvent = enum(c_int) {
    /// The application is about to leave the front (home, app switcher, a call). Save the state now.
    will_pause = 0x0B80,
    /// The application is in the background: Raven has stopped drawing, and waited until the GPU was idle.
    did_pause = 0x0B81,
    /// The application is coming back to the front: Raven draws again.
    will_resume = 0x0B82,
    /// The application is in front and takes input again.
    did_resume = 0x0B83,
    /// The system is low on memory: free what can be made again. Raven then drops its own caches and trims its heap.
    low_memory = 0x0B84,
    /// The application is about to end (Android: the activity is finishing; its window is closed right after).
    will_terminate = 0x0B85,
    _,
};

pub const WindowFlags = packed struct(u32) {
    no_resize: bool = false,
    hidden: bool = false,
    borderless: bool = false,
    maximized: bool = false,
    /// No title bar from the OS: the content covers the whole window and
    /// draws its own header, with a R_WIDGET_HEADER_BAR (raven_shell.h) or
    /// with any widget given to Rwidget_set_window_drag. The window is still
    /// moved, resized, snapped and maximized by the OS, as it does for its own
    /// title bars.
    custom_header: bool = false,
    /// The window can be seen through: where the application draws nothing
    /// opaque, what is behind the window on the screen shows (the desktop,
    /// the other applications), not a color of the application. Glass then
    /// looks at the screen itself. What the OS does to what shows through is
    /// chosen with Rwindow_set_backdrop. See RBackdrop for what each window
    /// system can do.
    transparent: bool = false,
    /// A splash screen: shown while the application starts. No frame (it
    /// implies R_WINDOW_BORDERLESS and R_WINDOW_NO_RESIZE, and cancels
    /// R_WINDOW_MAXIMIZED and R_WINDOW_CUSTOM_HEADER), centered on the screen
    /// before it is first shown and again when its size changes, above the
    /// other windows, out of the taskbar and of Alt+Tab (Windows), of the
    /// Window menu and of Cmd+` (macOS), typed _NET_WM_WINDOW_TYPE_SPLASH on
    /// X11. Wayland gives it no place of its own: it is a window without frame
    /// there. The application destroys it once its main window is ready
    /// (creating the main window first keeps Ris_running true).
    splash_screen: bool = false,
    _padding: u25 = 0,

    pub const default: WindowFlags = @bitCast(@as(u32, 0x0));
};

/// Where a window in picture in picture goes (Rwindow_set_picture_in_picture_layout).
pub const PictureInPictureCorner = enum(c_int) {
    bottom_right = 0x0780,
    bottom_left = 0x0781,
    top_right = 0x0782,
    top_left = 0x0783,
    _,
};

/// What is seen behind a window created with R_WINDOW_TRANSPARENT.
///
///   Windows 11          every value
///   Windows 10          TRANSPARENT, BLUR, ACRYLIC (MICA gives ACRYLIC)
///   macOS               TRANSPARENT; other backdrops fall back to transparency
///   X11                 TRANSPARENT with any compositing manager; BLUR where
///                       the compositor blurs on request (KWin; picom and
///                       others with their own settings); ACRYLIC and MICA
///                       give BLUR
///   no compositor       nothing: the window stays opaque
pub const Backdrop = enum(c_int) {
    /// Opaque: the window color, or the wallpaper of the theme.
    none = 0x0400,
    /// The screen behind the window, as it is.
    transparent = 0x0401,
    /// The screen behind the window, blurred by the OS.
    blur = 0x0402,
    /// Blurred, tinted and grained by the OS (the acrylic of Windows).
    acrylic = 0x0403,
    /// A soft tint taken from the wallpaper of the desktop (the mica of Windows 11).
    mica = 0x0404,
    _,
};

pub const WindowSystem = enum(c_int) {
    none = 0x0090,
    win32 = 0x0091,
    x11 = 0x0092,
    wayland = 0x0093,
    cocoa = 0x0094,
    emscripten = 0x0095,
    android = 0x0096,
    uikit = 0x0097,
    _,
};

/// What a text input holds: on mobile it picks the on-screen keyboard (letters, @, digits...).
pub const TextInputType = enum(c_int) {
    text = 0x0B60,
    email = 0x0B61,
    number = 0x0B62,
    /// Digits and a decimal separator.
    decimal = 0x0B63,
    phone = 0x0B64,
    url = 0x0B65,
    search = 0x0B66,
    _,
};

/// The label and meaning of the return key of the on-screen keyboard. Enter does the same on every key.
pub const ReturnKey = enum(c_int) {
    default = 0x0B70,
    done = 0x0B71,
    go = 0x0B72,
    next = 0x0B73,
    search = 0x0B74,
    send = 0x0B75,
    _,
};

/// Edges and corners of a window, for Rwindow_begin_resize.
pub const WindowEdge = enum(c_int) {
    left = 0x00D0,
    right = 0x00D1,
    top = 0x00D2,
    bottom = 0x00D3,
    top_left = 0x00D4,
    top_right = 0x00D5,
    bottom_left = 0x00D6,
    bottom_right = 0x00D7,
    _,
};

pub const MouseButton = enum(c_int) {
    left = 0,
    right = 1,
    middle = 2,
    x1 = 3,
    x2 = 4,
    _,
};

pub const Modifier = packed struct(u32) {
    shift: bool = false,
    ctrl: bool = false,
    alt: bool = false,
    super: bool = false,
    _padding: u28 = 0,
};

pub const Cursor = enum(c_int) {
    arrow = 0x00B0,
    ibeam = 0x00B1,
    hand = 0x00B2,
    crosshair = 0x00B3,
    resize_h = 0x00B4,
    resize_v = 0x00B5,
    resize_nwse = 0x00B6,
    resize_nesw = 0x00B7,
    move = 0x00B8,
    not_allowed = 0x00B9,
    /// No pointer at all (a game that hides it). Windows; elsewhere the arrow.
    none = 0x00BA,
    _,
};

/// Keyboard keys. Printable keys use their upper-case ASCII code.
pub const Key = enum(c_int) {
    unknown = 0,
    space = 0x0020,
    apostrophe = 0x0027,
    comma = 0x002C,
    minus = 0x002D,
    period = 0x002E,
    slash = 0x002F,
    key_0 = 0x0030,
    key_1 = 0x0031,
    key_2 = 0x0032,
    key_3 = 0x0033,
    key_4 = 0x0034,
    key_5 = 0x0035,
    key_6 = 0x0036,
    key_7 = 0x0037,
    key_8 = 0x0038,
    key_9 = 0x0039,
    semicolon = 0x003B,
    equal = 0x003D,
    a = 0x0041,
    b = 0x0042,
    c = 0x0043,
    d = 0x0044,
    e = 0x0045,
    f = 0x0046,
    g = 0x0047,
    h = 0x0048,
    i = 0x0049,
    j = 0x004A,
    k = 0x004B,
    l = 0x004C,
    m = 0x004D,
    n = 0x004E,
    o = 0x004F,
    p = 0x0050,
    q = 0x0051,
    r = 0x0052,
    s = 0x0053,
    t = 0x0054,
    u = 0x0055,
    v = 0x0056,
    w = 0x0057,
    x = 0x0058,
    y = 0x0059,
    z = 0x005A,
    left_bracket = 0x005B,
    backslash = 0x005C,
    right_bracket = 0x005D,
    grave = 0x0060,
    escape = 0x0100,
    enter = 0x0101,
    tab = 0x0102,
    backspace = 0x0103,
    insert = 0x0104,
    delete = 0x0105,
    right = 0x0106,
    left = 0x0107,
    down = 0x0108,
    up = 0x0109,
    page_up = 0x010A,
    page_down = 0x010B,
    home = 0x010C,
    end = 0x010D,
    caps_lock = 0x010E,
    print_screen = 0x010F,
    pause = 0x0110,
    f1 = 0x0111,
    f2 = 0x0112,
    f3 = 0x0113,
    f4 = 0x0114,
    f5 = 0x0115,
    f6 = 0x0116,
    f7 = 0x0117,
    f8 = 0x0118,
    f9 = 0x0119,
    f10 = 0x011A,
    f11 = 0x011B,
    f12 = 0x011C,
    kp_0 = 0x011D,
    kp_1 = 0x011E,
    kp_2 = 0x011F,
    kp_3 = 0x0120,
    kp_4 = 0x0121,
    kp_5 = 0x0122,
    kp_6 = 0x0123,
    kp_7 = 0x0124,
    kp_8 = 0x0125,
    kp_9 = 0x0126,
    kp_decimal = 0x0127,
    kp_divide = 0x0128,
    kp_multiply = 0x0129,
    kp_subtract = 0x012A,
    kp_add = 0x012B,
    kp_enter = 0x012C,
    left_shift = 0x012D,
    left_ctrl = 0x012E,
    left_alt = 0x012F,
    left_super = 0x0130,
    right_shift = 0x0131,
    right_ctrl = 0x0132,
    right_alt = 0x0133,
    right_super = 0x0134,
    menu = 0x0135,
    count = 0x0136,
    _,
};

pub const EventType = enum(c_int) {
    none = 0x00C0,
    mouse_move = 0x00C1,
    mouse_down = 0x00C2,
    mouse_up = 0x00C3,
    mouse_wheel = 0x00C4,
    mouse_enter = 0x00C5,
    mouse_leave = 0x00C6,
    key_down = 0x00C7,
    key_up = 0x00C8,
    /// A character was typed. `codepoint` holds the Unicode scalar value.
    text = 0x00C9,
    focus_gained = 0x00CA,
    focus_lost = 0x00CB,
    _,
};

/// Moments of a drag coming from another application (files from the file manager, text...).
pub const DropPhase = enum(c_int) {
    /// The pointer came over the target.
    enter = 0x00E0,
    /// It moves over the target.
    move = 0x00E1,
    /// It left the target without dropping.
    leave = 0x00E2,
    /// The user dropped: `paths` and `text` hold what was dropped.
    dropped = 0x00E3,
    _,
};

/// What the application that takes a drag does with it (Rdrag_begin_external): a bitmask of what is allowed, or the one done.
pub const DragOperation = packed struct(u32) {
    /// The target made a copy: the source keeps its data.
    copy: bool = false,
    /// The target took the data: the source removes it (a file the file manager moved...).
    move: bool = false,
    /// The target made a link, an alias or a shortcut to it.
    link: bool = false,
    _padding: u29 = 0,

    /// Nothing was taken: dropped where nothing accepted it, or cancelled.
    pub const none: DragOperation = @bitCast(@as(u32, 0x0));
};

/// What a finger does on a widget (Rwidget_set_touch_mode).
pub const TouchMode = enum(c_int) {
    /// The finger scrolls what scrolls under it, and is a mouse elsewhere (default).
    auto = 0x0480,
    /// A finger moving on the widget always scrolls what contains it, even over a control that drags.
    scroll = 0x0481,
    /// The finger is a mouse on the widget: pressing presses at once, moving drags, nothing scrolls.
    mouse = 0x0482,
    /// Fingers are ignored on the widget (only its touch callback sees them): a surface for the pen.
    none = 0x0483,
    _,
};

pub const TouchPhase = enum(c_int) {
    /// A finger came down.
    down = 0x0490,
    move = 0x0491,
    /// The finger was lifted.
    up = 0x0492,
    /// The system took the finger away (a gesture of its own, the window lost it): nothing must happen as for a lift.
    cancel = 0x0493,
    _,
};

pub const PenPhase = enum(c_int) {
    /// The tip touched the screen.
    down = 0x04A0,
    /// The pen moves while touching.
    move = 0x04A1,
    /// The tip left the screen.
    up = 0x04A2,
    /// The pen moves near the screen without touching it.
    hover = 0x04A3,
    /// The pen went out of reach.
    leave = 0x04A4,
    _,
};

/// Buttons on the side of a pen (RPenEvent::buttons).
pub const PenButton = packed struct(u32) {
    barrel: bool = false,
    barrel2: bool = false,
    _padding: u30 = 0,
};

pub const GesturePhase = enum(c_int) {
    /// A second finger came down (a touch screen), or the system recognized a gesture (a trackpad).
    begin = 0x04B0,
    update = 0x04B1,
    /// Fewer than two fingers remain, or the fingers left the trackpad (RGestureEvent::cancelled: the system took the gesture back).
    end = 0x04B2,
    _,
};

/// What the fingers of a gesture do (RGestureEvent::kind).
pub const GestureKind = enum(c_int) {
    /// Two fingers that pinch, turn and move together: scale, rotation and pan.
    pinch = 0x04C0,
    /// Three or more fingers that move together on a trackpad: only the pan
    /// (scale stays 1). By default, a swipe across goes back or forward.
    swipe = 0x04C1,
    _,
};

/// Where the fingers of a gesture are (RGestureEvent::device).
pub const GestureDevice = enum(c_int) {
    /// On the screen: the library recognized the gesture.
    touchscreen = 0x04D0,
    /// On a trackpad: the system recognized the gesture; the fingers are not on the window (x, y is the pointer).
    trackpad = 0x04D1,
    _,
};

/// The looks. Each one comes dark and light.
///
/// Raven's looks are the default; the ones of the platforms imitate them
/// closely (their shapes, colors, sizes, states and motion), without using
/// their widgets. The looks of the platforms are opaque, except macOS Glass
/// (macOS 26), whose bars, menus and floating surfaces are glass as on the
/// system; the glass materials themselves (Rtheme_set_material) belong to
/// the glass looks of Raven.
pub const Look = enum(c_int) {
    /// Raven, flat and dense, for tools. The look at start.
    raven_dark = 0x00E0,
    raven_light = 0x00E1,
    /// Raven in glass: controls are capsules of translucent glass that refract
    /// and blur what is behind them, catch the light on their rim and react
    /// to the pointer with short animations. Windows get a soft colored
    /// background unless they have their own (Rwindow_set_background,
    /// Rwindow_set_clear_color).
    raven_glass_dark = 0x00E2,
    raven_glass_light = 0x00E3,
    /// High contrast, for low vision: pure black and white, yellow (or blue)
    /// focus and selection, thick borders, larger text (raven_accessibility.h,
    /// Raccessibility_set_high_contrast).
    raven_high_contrast_dark = 0x00E4,
    raven_high_contrast_light = 0x00E5,
    /// Windows 11 (Fluent): its controls, its colors, the accent color the
    /// user chose (on Windows), the Segoe UI font when the system has it, and
    /// motion without bounce.
    windows_dark = 0x00E6,
    windows_light = 0x00E7,
    /// macOS (Sequoia, Aqua): its controls, its colors, the accent color the
    /// user chose (on macOS), the San Francisco font when the system has it,
    /// no change under the pointer, and selections in the accent color.
    macos_dark = 0x00E8,
    macos_light = 0x00E9,
    /// GNOME (libadwaita), the desktop of most Linux distributions: flat
    /// rounded controls, the accent and the font of the desktop (on Linux).
    gnome_dark = 0x00EA,
    gnome_light = 0x00EB,
    /// The look of the platform the application runs on: Windows on Windows,
    /// macOS on macOS (macOS Glass from macOS 26 on), GNOME on Linux and the
    /// other systems.
    native_dark = 0x00EC,
    native_light = 0x00ED,
    /// macOS 26 (Tahoe, Liquid Glass): the controls of macOS, larger and
    /// rounder, and glass where the system puts it, on what floats above the
    /// content: header bars and their buttons, menus, drop-down lists,
    /// tooltips, sheets; the knobs of sliders and switches turn into a lens
    /// of clear glass while they are held. The content itself (fields, lists,
    /// text) stays opaque. The accent color and the font of the system, on
    /// macOS.
    macos_glass_dark = 0x00EE,
    macos_glass_light = 0x00EF,
    _,
};

/// @deprecated The built-in themes of Raven 0.2, now looks: R_THEME_DARK is
/// R_LOOK_RAVEN_DARK and so on, and Rtheme_apply is Rlook_set.
pub const Theme = enum(c_int) {
    /// Flat, dense themes for tools.
    dark = 0x00E0,
    light = 0x00E1,
    /// Glass themes: controls are capsules of translucent glass that refract
    /// and blur what is behind them, catch the light on their rim and react
    /// to the pointer with short animations. Windows get a soft colored
    /// background unless they have their own (Rwindow_set_background,
    /// Rwindow_set_clear_color).
    glass_dark = 0x00E2,
    glass_light = 0x00E3,
    /// High contrast, for low vision: pure black and white, yellow (or blue)
    /// focus and selection, thick borders, larger text (raven_accessibility.h,
    /// Raccessibility_set_high_contrast).
    high_contrast_dark = 0x00E4,
    high_contrast_light = 0x00E5,
    _,
};

/// What surfaces are made of, from the clearest to the most opaque. A theme
/// has one material for everything (Rtheme_set_material); any widget can be
/// given its own (Rwidget_set_material, Material="..." in XML).
///
/// The three glasses share the same anatomy (a tint over what is behind, a
/// rim that bends it and catches the light, a shadow) and differ by how much
/// they let through. Within one material, surfaces are also told apart by
/// their height above the window: bars lie flat, panels float a little,
/// controls a little more, menus and dialogs highest; each level has a
/// brighter rim and a deeper shadow than the one below.
pub const Material = enum(c_int) {
    /// Opaque: filled with the colors of the theme. The material of R_THEME_DARK and R_THEME_LIGHT.
    solid = 0x02E0,
    /// Clear glass: what is behind stays sharp enough to be recognized, strongly bent at the rim.
    glass = 0x02E1,
    /// Frosted glass: what is behind is blurred into soft colors. The material of the glass themes.
    frosted_glass = 0x02E2,
    /// Frosted glass colored by the accent color of the theme (or of the widget): for what must stand out.
    tinted_glass = 0x02E3,
    /// Not a material: "the one of the theme". Removes the material given to a widget.
    default = 0x02E4,
    _,
};

/// Color roles. The comment lists the widgets reading each role.
pub const ColorRole = enum(c_int) {
    /// Window clear color.
    window = 0x0100,
    /// Border background.
    panel = 0x0101,
    /// Border outline, list and input outlines.
    border = 0x0102,
    /// Text. Inherited by the children of the widget it is set on.
    text = 0x0103,
    text_disabled = 0x0104,
    text_placeholder = 0x0105,
    /// Primary buttons, checked boxes, slider fill, progress fill.
    accent = 0x0106,
    accent_hovered = 0x0107,
    accent_pressed = 0x0108,
    /// Text and marks drawn on top of the accent color.
    accent_text = 0x0109,
    /// Button, combo box, check box background.
    control = 0x010A,
    control_hovered = 0x010B,
    control_pressed = 0x010C,
    control_border = 0x010D,
    /// Text input, spin box, list and tree background.
    input = 0x010E,
    /// Keyboard focus outline.
    focus = 0x010F,
    /// Selected rows and selected text.
    selection = 0x0110,
    row_hovered = 0x0111,
    /// Slider track, progress background, scrollbar track.
    track = 0x0112,
    /// Scrollbar thumb, slider handle.
    handle = 0x0113,
    handle_hovered = 0x0114,
    separator = 0x0115,
    /// Menu bar, tab bar, expander header.
    header = 0x0116,
    header_hovered = 0x0117,
    /// Active tab.
    tab_active = 0x0118,
    /// Menus, combo box lists.
    popup = 0x0119,
    popup_border = 0x011A,
    shadow = 0x011B,
    tooltip = 0x011C,
    tooltip_text = 0x011D,
    /// Track of a switch that is on.
    @"switch" = 0x011E,
    /// What went well, what needs attention, what is wrong or destroys something (markers, badges, classes).
    success = 0x011F,
    warning = 0x0120,
    danger = 0x0121,
    /// Links of formatted text.
    link = 0x0122,
    /// Background of code in formatted text.
    code = 0x0123,
    /// The matches of a search in a text editor (usually see-through).
    search_match = 0x0124,
    /// The selected match of a search in a text editor.
    search_current = 0x0125,
    /// Wavy underline of the misspelled words of a TextInput or a TextEditor (spell checking).
    spelling = 0x0126,
    /// Diff view: the background of an added line and of a removed line (see-through: the background shows).
    diff_added = 0x0127,
    diff_removed = 0x0128,
    /// Diff view: the words that changed inside an added line and inside a removed line, over the color of the line.
    diff_added_word = 0x0129,
    diff_removed_word = 0x012A,
    _,
};

/// Sizes, in logical units.
pub const Metric = enum(c_int) {
    font_size = 0x0140,
    corner_radius = 0x0141,
    border_width = 0x0142,
    /// Height of buttons, inputs, combo boxes, tabs, menu bars.
    control_height = 0x0143,
    /// Horizontal / vertical padding inside controls.
    padding_x = 0x0144,
    padding_y = 0x0145,
    /// Gap between an icon or a check mark and its text.
    spacing = 0x0146,
    scrollbar_size = 0x0147,
    /// Height of list, tree and menu rows.
    row_height = 0x0148,
    /// Indentation per tree level.
    indent = 0x0149,
    splitter_size = 0x014A,
    check_size = 0x014B,
    slider_handle_size = 0x014C,
    /// Corner radius of menus, drop-down lists and tooltips.
    popup_radius = 0x014D,
    /// The glass of the theme: each one multiplies what the material gives,
    /// 1 = unchanged. Frost (how much is blurred), refraction (how far the rim
    /// bends what is behind), saturation (of what is seen through), rim (the
    /// light it catches) and shadow (the one it drops).
    glass_frost = 0x014E,
    glass_refraction = 0x014F,
    glass_saturation = 0x0150,
    glass_rim = 0x0151,
    glass_shadow = 0x0152,
    /// Radius of the blur of a BackgroundBlur that was not given one.
    blur_radius = 0x0153,
    _,
};

/// The styles of a font (Rfont_get_variant).
pub const FontStyle = enum(c_int) {
    regular = 0x0420,
    bold = 0x0421,
    italic = 0x0422,
    bold_italic = 0x0423,
    _,
};

pub const FilterType = enum(c_int) {
    linear = 0x02C0,
    /// No smoothing: keeps pixel art sharp.
    nearest = 0x02C1,
    /// Smooth, with mipmaps: an image shown much smaller than its size stays
    /// clean instead of shimmering, for a third more GPU memory. The default
    /// of the textures made from image files (Rtexture_create...). Backends
    /// without mipmaps treat it as R_FILTER_LINEAR.
    mipmap = 0x02C2,
    _,
};

pub const WidgetType = enum(c_int) {
    /// Stacks children top to bottom. Slate: SVerticalBox.
    vbox = 0x0200,
    /// Stacks children left to right. Slate: SHorizontalBox.
    hbox = 0x0201,
    /// Rows and columns with spans and fill coefficients. Slate: SGridPanel.
    grid = 0x0202,
    /// Grid whose cells all have the same size. Slate: SUniformGridPanel.
    uniform_grid = 0x0203,
    /// Draws children on top of each other. Slate: SOverlay.
    overlay = 0x0204,
    /// One child with a background, an outline and inner padding. Slate: SBorder.
    border = 0x0205,
    /// One child with size constraints or a fixed aspect ratio. Slate: SBox.
    size_box = 0x0206,
    /// Empty space. Slate: SSpacer.
    spacer = 0x0207,
    /// Scrollable stack of children. Slate: SScrollBox.
    scroll_box = 0x0208,
    /// Children separated by draggable handles. Slate: SSplitter.
    splitter = 0x0209,
    /// Flows children and wraps to the next line. Slate: SWrapBox.
    wrap_box = 0x020A,
    /// Children placed with anchors and offsets. Slate: SConstraintCanvas.
    canvas = 0x020B,
    /// Shows one child at a time. Slate: SWidgetSwitcher.
    switcher = 0x020C,
    /// Tab bar + one page per child.
    tab_view = 0x020D,
    /// Collapsible header + one child. Slate: SExpandableArea.
    expander = 0x020E,
    label = 0x020F,
    button = 0x0210,
    checkbox = 0x0211,
    slider = 0x0212,
    progressbar = 0x0213,
    image = 0x0214,
    text_input = 0x0215,
    spin_box = 0x0216,
    combo_box = 0x0217,
    separator = 0x0218,
    list_view = 0x0219,
    tree_view = 0x021A,
    menu_bar = 0x021B,
    menu = 0x021C,
    menu_item = 0x021D,
    /// Area showing content rendered by the application.
    viewport = 0x021E,
    /// Widget painted and measured by application callbacks.
    custom = 0x021F,
    /// Multi-line text editor.
    text_editor = 0x0220,
    /// Title bar of a window with a custom header, holding any widget.
    header_bar = 0x0221,
    /// Panels docked side by side or behind tabs, that the user rearranges.
    dock_area = 0x0222,
    /// A capsule that unfolds into a panel, at the top of a window.
    island = 0x0223,
    /// Explorer of the files of the computer.
    file_browser = 0x0224,
    /// One child over a blurred view of what is behind it.
    background_blur = 0x0225,
    /// Chooses a color: hue, saturation, value, opacity, by hand or by numbers.
    color_picker = 0x0226,
    /// Tracks of clips and keys along a time ruler.
    timeline = 0x0227,
    /// Nodes linked by wires, on a canvas that pans and zooms.
    node_graph = 0x0228,
    /// Grid of tiles (an icon over a name), virtualized. Slate: STileView.
    tile_view = 0x0229,
    /// Blocks that snap into each other, in the style of Scratch.
    block_editor = 0x022A,
    /// Rows of cells under columns that can be resized and sorted, virtualized.
    table = 0x022B,
    /// A date, chosen in a calendar that drops down.
    date_picker = 0x022C,
    /// A time of the day: hours, minutes, optionally seconds.
    time_picker = 0x022D,
    /// A short message that rises for a few seconds, with an optional action ("Undo").
    toast = 0x022E,
    /// The path to the current place: links separated by chevrons.
    breadcrumb = 0x022F,
    /// A score shown and chosen with stars.
    rating = 0x0230,
    /// Page numbers with previous and next.
    pagination = 0x0231,
    /// Curves of X / Y data: legend, line styles, markers, log axes, a second X and Y axis, pan and zoom.
    plot = 0x0232,
    /// The pages of a PDF document, scrolled and zoomed (drawn by PDFium, loaded at run time).
    pdf_view = 0x0233,
    /// The charts of dashboards: pie, donut, gauge, heatmap, sparkline (RChartKind).
    chart = 0x0234,
    /// A map of slippy-map tiles given by the application (or read from files): panned, zoomed, with markers.
    map_view = 0x0235,
    /// Pages shown one at a time and swiped (a page view), with dots and arrows.
    carousel = 0x0236,
    /// A web page shown by the engine of the system (WKWebView) in a view kept over the widget.
    system_web_view = 0x0237,
    /// The differences between two texts or a patch: unified or side by side, folded, virtualized (raven_tools.h).
    diff_view = 0x0238,
    _,
};

pub const HAlign = enum(c_int) {
    fill = 0x0240,
    left = 0x0241,
    center = 0x0242,
    right = 0x0243,
    _,
};

pub const VAlign = enum(c_int) {
    fill = 0x0250,
    top = 0x0251,
    center = 0x0252,
    bottom = 0x0253,
    _,
};

pub const Visibility = enum(c_int) {
    /// Drawn and laid out.
    visible = 0x0260,
    /// Not drawn, but still takes its space in the layout.
    hidden = 0x0261,
    /// Not drawn and takes no space.
    collapsed = 0x0262,
    _,
};

/// How a widget arrives. A transition animates what the widget and its
/// children draw; the layout is not affected, the widget is in place from the
/// first frame for its neighbours and for the mouse.
pub const Transition = enum(c_int) {
    none = 0x0300,
    /// Becomes opaque.
    fade = 0x0301,
    /// Grows from a smaller size and bounces a little past its own.
    pop = 0x0302,
    /// Shrinks from a larger size.
    zoom = 0x0303,
    /// Flies in from below / above / the right / the left, and settles with a bounce.
    fly_up = 0x0304,
    fly_down = 0x0305,
    fly_left = 0x0306,
    fly_right = 0x0307,
    /// Falls from above, squashes on landing and wobbles.
    drop = 0x0308,
    /// Short slide from the right / from the left, without bounce: pages that replace one another.
    slide_left = 0x0309,
    slide_right = 0x030A,
    _,
};

pub const Orientation = enum(c_int) {
    horizontal = 0x0270,
    vertical = 0x0271,
    _,
};

/// The looks of a R_WIDGET_BACKGROUND_BLUR. The first three are drawn by
/// Raven from what the window shows behind the widget; the last one is the
/// blur of the OS, which sees what is behind the window itself.
pub const BlurStyle = enum(c_int) {
    /// What is behind, out of focus, and nothing else (a Gaussian blur).
    plain = 0x0440,
    /// Frosted: blurred, its colors a little stronger, under a veil of the
    /// panel color of the theme, a fine grain and a hairline. The default.
    frosted = 0x0441,
    /// Glass: a slab that bends what is behind at its rim and catches the
    /// light, as the glass materials do (RMaterial); the radius says how
    /// frosted it is.
    glass = 0x0442,
    /// Native: the widget opens the window there, and what shows is what the
    /// OS puts behind the window (Rwindow_set_backdrop: the blurred desktop,
    /// acrylic, mica), under a light veil. It needs a window created with
    /// R_WINDOW_TRANSPARENT that the OS could make see-through; anywhere
    /// else it is drawn as R_BLUR_FROSTED. The radius is the one of the OS.
    native = 0x0443,
    _,
};

pub const Direction = enum(c_int) {
    /// A widget: the direction of its parent (the default).
    inherit = 0,
    ltr = 0x0720,
    rtl = 0x0721,
    /// The windows: the direction of the language.
    auto = 0x0722,
    _,
};

pub const TextAlign = enum(c_int) {
    left = 0x0280,
    center = 0x0281,
    right = 0x0282,
    _,
};

pub const ToastKind = enum(c_int) {
    /// A neutral message (the accent of the theme).
    info = 0x04E0,
    success = 0x04E1,
    warning = 0x04E2,
    @"error" = 0x04E3,
    _,
};

/// What a Toast does with a message that comes while another one is shown.
pub const ToastQueue = enum(c_int) {
    /// The new message takes the place of the one shown (the default).
    replace = 0x0500,
    /// The messages are shown one after the other, each for its own time.
    sequence = 0x0501,
    /// Up to Rtoast_set_max_visible messages are shown at once, one above the other; the others wait.
    stack = 0x0502,
    _,
};

pub const ButtonStyle = enum(c_int) {
    /// Filled with R_COLOR_CONTROL.
    default = 0x0290,
    /// Filled with R_COLOR_ACCENT.
    primary = 0x0291,
    /// No background until hovered (toolbars).
    flat = 0x0292,
    _,
};

pub const CheckboxStyle = enum(c_int) {
    check = 0x02A0,
    /// Round mark. Checking one unchecks the other radio boxes of the same parent.
    radio = 0x02A1,
    /// On / off switch.
    @"switch" = 0x02A2,
    _,
};

pub const Stretch = enum(c_int) {
    /// Stretches the image to the widget, ignoring its aspect ratio.
    fill = 0x02B0,
    /// Largest size that fits entirely, keeping the aspect ratio.
    fit = 0x02B1,
    /// Smallest size that covers the widget, keeping the aspect ratio (cropped).
    cover = 0x02B2,
    /// Original size, centered.
    none = 0x02B3,
    _,
};

/// The axes of a Plot.
pub const PlotAxis = enum(c_int) {
    /// The horizontal axis under the data.
    x = 0x0520,
    /// The vertical axis on the left.
    y = 0x0521,
    /// A second horizontal axis, over the data: shown when a series or a drag line uses it.
    x2 = 0x0522,
    /// A second vertical axis, on the right: shown when a series or a drag line uses it.
    y2 = 0x0523,
    _,
};

/// How a PdfView sizes its pages.
pub const PdfFit = enum(c_int) {
    /// The widest page fills the width of the view (default).
    width = 0x05C0,
    /// The largest page fits whole in the view.
    page = 0x05C1,
    /// The zoom of Rpdf_view_set_zoom; zooming with the wheel or the keys switches to it.
    none = 0x05C2,
    _,
};

/// What a PdfView holds.
pub const PdfStatus = enum(c_int) {
    /// No document.
    empty = 0x05D0,
    /// A document is shown.
    loaded = 0x05D1,
    /// The document needs a password, or the one given is wrong: load it again with one.
    needs_password = 0x05D2,
    /// The file could not be read, or is not a PDF document.
    @"error" = 0x05D3,
    /// The PDFium library was not found (see Rpdf_is_available).
    unavailable = 0x05D4,
    _,
};

/// The fonts of a PDF document (Rpdf_document_set_font): those of Raven, then the ones added (2, 3...).
pub const PdfFont = enum(c_int) {
    /// Roboto, the font of the interface of Raven.
    sans = 0,
    /// Roboto Mono.
    mono = 1,
    _,
};

/// How a shape of a PDF document is painted: a bitmask.
pub const PdfPaint = packed struct(u32) {
    /// Filled with the fill color.
    fill: bool = false,
    /// Outlined with the stroke color and the line width.
    stroke: bool = false,
    _padding: u30 = 0,
};

/// A bitmask of styles of the text of a PDF document.
pub const PdfTextStyle = packed struct(u32) {
    bold: bool = false,
    italic: bool = false,
    underline: bool = false,
    _padding: u29 = 0,
};

pub const PdfPrintFlags = enum(c_int) {
    /// No dialog: printed at once on the printer named, else the default one.
    no_dialog = 1,
    _,
};

/// Where a tile of a MapView stands (Rmap_view_get_tile_state).
pub const MapTileState = enum(c_int) {
    /// Not in the view's cache: never asked for, no longer wanted, or evicted.
    none = 0x0600,
    /// Asked for (the tile callback was called, or the file is being read): waiting for its pixels.
    pending = 0x0601,
    /// Its pixels are in the cache.
    loaded = 0x0602,
    /// The application said it has none (Rmap_view_set_tile_failed), or its file could not be read.
    failed = 0x0603,
    _,
};

/// How an axis of a Plot spreads its values.
pub const PlotScale = enum(c_int) {
    linear = 0x0530,
    /// Powers of ten at even distances; only values above zero are shown.
    log = 0x0531,
    /// Symmetric logarithm: linear between -t and t (Rplot_set_axis_linear_threshold,
    /// 1 by default), logarithmic beyond on both sides: shows zero and the
    /// negative values a logarithm cannot.
    symlog = 0x0532,
    _,
};

/// How the line of a series of a Plot is drawn.
pub const PlotLine = enum(c_int) {
    solid = 0x0540,
    dashed = 0x0541,
    dotted = 0x0542,
    dash_dot = 0x0543,
    /// No line: only the markers (a scatter plot).
    none = 0x0544,
    _,
};

/// The mark drawn on each point of a series of a Plot.
pub const PlotMarker = enum(c_int) {
    none = 0x0550,
    circle = 0x0551,
    square = 0x0552,
    diamond = 0x0553,
    triangle_up = 0x0554,
    triangle_down = 0x0555,
    cross = 0x0556,
    plus = 0x0557,
    asterisk = 0x0558,
    _,
};

/// Where the legend of a Plot is.
pub const PlotLegend = enum(c_int) {
    hidden = 0x0560,
    top_left = 0x0561,
    top = 0x0562,
    top_right = 0x0563,
    right = 0x0564,
    bottom_right = 0x0565,
    bottom = 0x0566,
    bottom_left = 0x0567,
    left = 0x0568,
    /// To the right of the data, outside it.
    outside = 0x0569,
    _,
};

/// What a Chart draws.
pub const ChartKind = enum(c_int) {
    /// Slices of a whole, as parts of a disc (the default).
    pie = 0x0590,
    /// Slices of a whole, as parts of a ring; its middle shows the total, or the slice under the pointer.
    donut = 0x0591,
    /// One value within a range, on an arc; bands color parts of the range.
    gauge = 0x0592,
    /// A grid of values, each cell colored from the low color to the high one.
    heatmap = 0x0593,
    /// A small line of values without axes, to sit in a tile or a cell of a table.
    sparkline = 0x0594,
    _,
};

/// What happens in a SystemWebView (Rsystem_web_view_set_event_callback).
pub const SystemWebViewEvent = enum(c_int) {
    /// The view shows another address (Rsystem_web_view_get_url).
    navigated = 0x0B90,
    /// The title of the page changed (Rsystem_web_view_get_title).
    title = 0x0B91,
    /// A page starts loading.
    loading = 0x0B92,
    /// The page and what it refers to are loaded.
    loaded = 0x0B93,
    /// The page could not be loaded, or the engine showing it stopped (Rsystem_web_view_get_error).
    failed = 0x0B94,
    _,
};

/// How the rows of a Table are selected (Rtable_set_selection_mode).
pub const TableSelectionMode = enum(c_int) {
    /// One row at a time (the default).
    single = 0x0BC0,
    /// Any number of rows: Ctrl/Cmd+click, Shift+click, Shift+arrows, Space, Ctrl/Cmd+A.
    multiple = 0x0BC1,
    /// The user selects nothing (the rows are only shown; cells may still be edited and checked).
    none = 0x0BC2,
    _,
};

/// What the cells of a column show (Rtable_set_column_kind).
pub const TableColumnKind = enum(c_int) {
    /// Their text (the default).
    text = 0x0BD0,
    /// A check box, checked when the text is "1", "true" or "yes". The user
    /// toggles it with a click or Space unless the column is made not
    /// editable; the cell edited callback is then called with "1" or "0".
    check = 0x0BD1,
    /// A progress bar, from a number 0..1 or a percentage ("45%"); an empty cell shows nothing.
    progress = 0x0BD2,
    _,
};

/// Shorthands of Rtext_editor_set_language for two languages.
pub const Syntax = enum(c_int) {
    none = 0x0340,
    xml = 0x0341,
    c = 0x0342,
    _,
};

pub const LanguageFlags = packed struct(u32) {
    /// Tags and attributes instead of code: XML, HTML. The words and the comments of the description are not used.
    markup: bool = false,
    /// Selectors, properties and values: CSS.
    style_sheet: bool = false,
    /// A block comment may hold another one (Rust).
    nested_comments: bool = false,
    /// Between single quotes there is one character; any other single quote is not a text (C, Java, Rust).
    char_literals: bool = false,
    /// A line that ends with ':' indents the next one (Python).
    indent_on_colon: bool = false,
    /// The words of the language are recognized whatever their case.
    ignore_case: bool = false,
    /// Markup that holds JavaScript in script elements and CSS in style elements (HTML).
    embeds: bool = false,
    /// Formatted text written in Markdown: titles, strong and emphasized
    /// text, code, links, lists. The editor shows the text as it is written,
    /// marks included, with strong text in bold, emphasized text in italic
    /// and titles in bold: what will be formatted is seen while typing.
    formatted_text: bool = false,
    _padding: u24 = 0,
};

/// What a part of the text is, for the language of the editor (Rtext_editor_get_token).
pub const Token = enum(c_int) {
    text = 0x03A0,
    comment = 0x03A1,
    string = 0x03A2,
    number = 0x03A3,
    keyword = 0x03A4,
    /// A type, or a name that is always there.
    type = 0x03A5,
    /// A name followed by an opening parenthesis.
    function = 0x03A6,
    /// The name of an element, in markup and in the selectors of a style sheet.
    tag = 0x03A7,
    /// The name of an attribute (markup), of a class or of a property (style sheets), of a key (JSON).
    attribute = 0x03A8,
    punctuation = 0x03A9,
    /// A line for the preprocessor, an annotation, a declaration of a document.
    directive = 0x03AA,
    /// Formatted text (the Markdown language): a title, strong text, emphasized text, a link.
    heading = 0x03AB,
    strong = 0x03AC,
    emphasis = 0x03AD,
    link = 0x03AE,
    _,
};

/// Options of a search (Rtext_editor_set_search), a bitmask.
pub const SearchFlags = packed struct(u32) {
    /// Upper and lower case differ. Without it the case is ignored, for the
    /// letters of ASCII, Latin-1, the Latin letters of Unicode, Greek,
    /// Cyrillic and Armenian.
    match_case: bool = false,
    /// A match is a whole word: "for" does not find the start of "format".
    whole_word: bool = false,
    _padding: u30 = 0,
};

/// What a marker says about the text it underlines.
pub const MarkerKind = enum(c_int) {
    @"error" = 0x0350,
    warning = 0x0351,
    info = 0x0352,
    _,
};

/// Buttons of a header bar.
pub const HeaderButtons = packed struct(u32) {
    close: bool = false,
    minimize: bool = false,
    maximize: bool = false,
    _padding: u29 = 0,

    pub const no_buttons: HeaderButtons = @bitCast(@as(u32, 0x0));

    pub const all_buttons: HeaderButtons = @bitCast(@as(u32, 0x7));
};

/// A progress bar on the icon of the application (Rwindow_set_taskbar_progress).
pub const TaskbarProgress = enum(c_int) {
    none = 0x07A0,
    normal = 0x07A1,
    /// Shown as paused (yellow on Windows).
    paused = 0x07A2,
    /// Shown as failed (red on Windows).
    @"error" = 0x07A3,
    /// Something goes on, without knowing how far it is.
    indeterminate = 0x07A4,
    _,
};

/// Where a panel goes in a dock area, relative to another panel or to the whole area.
pub const DockSide = enum(c_int) {
    left = 0x0360,
    right = 0x0361,
    top = 0x0362,
    bottom = 0x0363,
    /// Behind the same tabs as the other panel.
    tab = 0x0364,
    _,
};

pub const DockFloatMode = enum(c_int) {
    window = 0,
    in_window = 1,
    _,
};

pub const VisualPreset = enum(c_int) {
    /// The look of the theme of the window: its platform, dark or light.
    auto = 0x0510,
    /// Cards with soft shadows, few lines (follows dark or light).
    modern = 0x0511,
    /// Headers in gradients, a grid of lines, thick links that glow; pins of the type "exec" are arrows.
    blueprint = 0x0512,
    /// Compact nodes, flat headers in muted colors, thin links.
    blender = 0x0513,
    /// Almost black, outlines and links of light.
    neon = 0x0514,
    _,
};

/// What an item of a timeline is.
pub const TimelineItem = enum(c_int) {
    none = 0x0460,
    clip = 0x0461,
    key = 0x0462,
    marker = 0x0463,
    _,
};

pub const BlockShape = enum(c_int) {
    /// A step: snaps under another one, others snap under it.
    statement = 0x0700,
    /// Starts a script ("when the game starts"): nothing goes above it.
    hat = 0x0701,
    /// Ends a script ("stop"): nothing goes under it.
    cap = 0x0702,
    /// Wraps stacks in its mouths ("repeat", "if ... else").
    c = 0x0703,
    /// A rounded value that goes into a slot.
    reporter = 0x0704,
    /// A hexagonal condition that goes into a %b slot (or a %r one).
    boolean = 0x0705,
    _,
};

pub const BlockPlace = enum(c_int) {
    next = 0x0710,
    body = 0x0711,
    input = 0x0712,
    _,
};

pub const DiffViewMode = enum(c_int) {
    /// One column: the removed lines, then the added lines, between the lines kept.
    unified = 0x0C50,
    /// Two columns: the left text and the right text side by side, aligned.
    split = 0x0C51,
    _,
};

pub const DiffSide = enum(c_int) {
    /// The text before (the old one, "a/", the lines removed).
    left = 0x0C54,
    /// The text after (the new one, "b/", the lines added).
    right = 0x0C55,
    _,
};

pub const DiffRowKind = enum(c_int) {
    /// A line that is on both sides.
    same = 0x0C58,
    /// A line of the left text only.
    removed = 0x0C59,
    /// A line of the right text only.
    added = 0x0C5A,
    /// Split mode: a removed line facing the added line that replaces it.
    changed = 0x0C5B,
    /// Unchanged lines folded away ("12 unchanged lines"); Rdiff_view_expand shows them.
    fold = 0x0C5C,
    /// A patch: the header of a hunk ("@@ -12,7 +12,8 @@ main").
    hunk = 0x0C5D,
    /// A patch: the names of a file.
    file = 0x0C5E,
    /// A note attached to the line above it (Rdiff_view_add_annotation).
    note = 0x0C5F,
    _,
};

/// How lines are compared (Rdiff_view_set_flags, Rdiff_unified).
pub const DiffFlags = packed struct(u32) {
    /// Spaces and tabs at the end of a line (and a carriage return) do not count.
    trailing_space: bool = false,
    /// No space or tab counts, wherever it is.
    space: bool = false,
    /// Upper and lower case letters are the same (A to Z).
    case: bool = false,
    _padding: u29 = 0,
};

/// How much a notification of the system asks for attention (Rnotification_show).
pub const NotificationUrgency = enum(c_int) {
    /// No sound; may only go to the list of notifications.
    low = 0x04F0,
    normal = 0x04F1,
    /// Stays until the user dismisses it, where the system allows it.
    critical = 0x04F2,
    _,
};

/// What happened to a notification (Rnotification_set_callback).
pub const NotificationEvent = enum(c_int) {
    /// The user clicked the notification itself (not one of its buttons).
    activated = 0x0C20,
    /// The user clicked one of its buttons: `action` is the id of that button.
    action_invoked = 0x0C21,
    /// It went away without being clicked: closed by the user, or its time ran out (where the system tells).
    dismissed = 0x0C22,
    _,
};

/// What the notifications of the system can do here (Rnotification_supports).
pub const NotificationFeature = packed struct(u32) {
    /// Buttons (RNotificationDesc::actions).
    actions: bool = false,
    /// A notification shown again with the same tag replaces the first one.
    replace: bool = false,
    /// Rnotification_close takes a notification away.
    close: bool = false,
    /// An image beside the text (RNotificationDesc::icon).
    icon: bool = false,
    /// A click on the notification is reported (R_NOTIFICATION_ACTIVATED).
    activated: bool = false,
    /// Its dismissal is reported (R_NOTIFICATION_DISMISSED).
    dismissed: bool = false,
    _padding: u26 = 0,
};

pub const FileDialogFlags = packed struct(u32) {
    /// Several files can be chosen (Rfile_dialog_open): see Rfile_dialog_get_result.
    multiple: bool = false,
    /// Never the dialog of the OS: the file browser of Raven, in a dialog of the parent window.
    raven: bool = false,
    show_hidden: bool = false,
    _padding: u29 = 0,
};

pub const FileBrowserMode = enum(c_int) {
    /// Choose an existing file.
    open = 0x0380,
    /// Choose where to save: a name is typed; an existing file must be confirmed.
    save = 0x0381,
    /// Choose a folder.
    folder = 0x0382,
    _,
};

pub const MessageButtons = enum(c_int) {
    ok = 0x0390,
    ok_cancel = 0x0391,
    yes_no = 0x0392,
    yes_no_cancel = 0x0393,
    _,
};

pub const MessageResult = enum(c_int) {
    /// Dismissed (Escape), or the Cancel button.
    cancel = 0,
    ok = 1,
    yes = 2,
    no = 3,
    _,
};

/// What the application may be allowed to use (Rpermission_request).
pub const Permission = enum(c_int) {
    camera = 0x0C00,
    /// Notifications of the system (Rnotification_show).
    notifications = 0x0C01,
    /// Reading the whole photo library. Rphoto_pick needs none: the system's picker gives only what the user chose.
    photos = 0x0C02,
    microphone = 0x0C03,
    /// The location of the device while the application is in use.
    location = 0x0C04,
    _,
};

/// What the user answered, or would be asked (Rpermission_get_status).
pub const PermissionStatus = enum(c_int) {
    /// There is nothing to ask for here: the platform has no such permission,
    /// or Raven cannot ask for it on this platform. Whether the service itself
    /// exists is told by its own function (Rcamera_is_available,
    /// Rnotification_is_supported).
    unsupported = 0x0C10,
    /// Not asked yet: Rpermission_request shows the question of the system.
    not_asked = 0x0C11,
    /// Allowed (also where the system asks nothing: notifications on Windows and Linux).
    granted = 0x0C12,
    /// Allowed in part: some photos only (iOS, Android 14), quiet notifications (iOS provisional), the approximate location only.
    limited = 0x0C13,
    /// Refused, and the system may ask again (Android, after a first refusal).
    denied = 0x0C14,
    /// Refused for good, or not the user's to give (parental controls, a
    /// profile of the company): the system shows no question any more, only
    /// its Settings can change it (Rpermission_open_settings).
    blocked = 0x0C15,
    _,
};

/// How a request of a picker, the camera or a share sheet ended.
pub const DeviceResult = enum(c_int) {
    /// Done: the files were chosen, the photo taken, the file saved, the sheet shown.
    done = 0x0C20,
    /// The user closed the screen of the system without choosing.
    cancelled = 0x0C21,
    /// A permission it needs was refused (Rcamera_take_photo: the camera).
    denied = 0x0C22,
    /// The platform does not have this service.
    unsupported = 0x0C23,
    /// Another screen of the system is still open: one at a time.
    busy = 0x0C24,
    /// The system reported an error (also reported as an R_ERROR_PLATFORM warning).
    failed = 0x0C25,
    _,
};

/// A short vibration that answers a touch (Rhaptic_play).
pub const Haptic = enum(c_int) {
    /// Impacts: something touched, snapped, landed.
    light = 0x0C30,
    medium = 0x0C31,
    heavy = 0x0C32,
    /// The selection moved (a picker wheel, a switch, a segmented control).
    selection = 0x0C33,
    /// The outcome of an action.
    success = 0x0C34,
    warning = 0x0C35,
    @"error" = 0x0C36,
    _,
};

/// How a spring moves. Animations in Raven are springs, as on iOS: a value is
/// pulled toward its target and may run past it before settling, which is what
/// makes a control feel alive rather than mechanical.
pub const Motion = enum(c_int) {
    /// Fast, no bounce: hover, highlights.
    snappy = 0x0320,
    /// Slower, no bounce: scrolling, fades, sizes.
    smooth = 0x0321,
    /// Runs a little past the target and comes back: switches, popups, pressed buttons.
    bouncy = 0x0322,
    /// Swings several times around the target: things that fly in or get dropped.
    wobbly = 0x0323,
    _,
};

/// The effects that come with Raven (Reffect_get).
pub const Effect = enum(c_int) {
    /// Soft lights that drift slowly: color, color2; params: speed, scale, intensity, -. Animated.
    aurora = 0x0B40,
    /// A band of light that sweeps across (loading placeholders): color = base, color2 = light; params: speed, width, angle, -. Animated.
    shimmer = 0x0B41,
    /// A glowing edge whose colors run around the shape: color, color2; params: speed, width, glow, -. Animated.
    neon = 0x0B42,
    /// Rings that ripple what is behind, like water (reads the backdrop): color = tint; params: speed, strength, density, center x (0..1). Animated.
    ripple = 0x0B43,
    /// Bands of color that flow into each other: color, color2; params: speed, scale, contrast, -. Animated.
    plasma = 0x0B44,
    /// A gradient with the fine grain of film: color (top left) to color2 (bottom right); params: grain, angle, -, -. Animated grain.
    grain = 0x0B45,
    /// A soft light that follows a point: color = light, color2 = background; params: x, y (0..1), radius (0..1), -.
    spotlight = 0x0B46,
    /// Four colors blended across the surface, slowly moving: color, color2 and their mix; params: speed, -, -, -. Animated.
    mesh = 0x0B47,
    _,
};

/// Flags of Rshader_create.
pub const ShaderFlags = packed struct(u32) {
    /// The effect reads what is drawn behind it (raven_backdrop, raven_backdrop_blur).
    backdrop: bool = false,
    /// The effect changes with time: the window keeps drawing frames while it is shown.
    animated: bool = false,
    _padding: u30 = 0,
};

/// The kind of value an attribute takes.
pub const XmlValueType = enum(c_int) {
    text = 0x03C0,
    /// "true" or "false".
    bool = 0x03C1,
    number = 0x03C2,
    /// One of the words of `choices`.
    choice = 0x03C3,
    /// "#RGB", "#RRGGBB", "#RRGGBBAA", or a name: white, black, red, transparent...
    color = 0x03C4,
    /// The name of an action (Raction_bind).
    action = 0x03C5,
    /// The path of a file.
    file = 0x03C6,
    /// Several numbers separated by commas: "8,4", "0,0,1,1".
    numbers = 0x03C7,
    /// Texts separated by '|': "One|Two|Three".
    list = 0x03C8,
    _,
};

/// How the hours of a time are shown.
pub const Clock = enum(c_int) {
    /// As the locale does (Rlocale_uses_12_hour_clock).
    auto = 0x0C30,
    /// 1 to 12, with AM and PM.
    clock_12_hour = 0x0C31,
    /// 0 to 23.
    clock_24_hour = 0x0C32,
    _,
};

pub const ColorFilter = enum(c_int) {
    none = 0x0740,
    /// Corrections: the colors that cannot be told apart are moved to colors that can.
    protanopia = 0x0741,
    deuteranopia = 0x0742,
    tritanopia = 0x0743,
    grayscale = 0x0744,
    invert = 0x0745,
    /// Simulations, to see an interface as the color blind see it.
    simulate_protanopia = 0x0746,
    simulate_deuteranopia = 0x0747,
    simulate_tritanopia = 0x0748,
    simulate_achromatopsia = 0x0749,
    _,
};

pub const AccessibleRole = enum(c_int) {
    /// The role of the type of the widget (the default).
    auto = 0,
    /// Not exposed: its children are seen as the children of its parent.
    none = 0x0760,
    window = 0x0761,
    group = 0x0762,
    text = 0x0763,
    heading = 0x0764,
    link = 0x0765,
    button = 0x0766,
    toggle_button = 0x0767,
    checkbox = 0x0768,
    radio_button = 0x0769,
    slider = 0x076A,
    progress_bar = 0x076B,
    spin_button = 0x076C,
    text_field = 0x076D,
    document = 0x076E,
    combo_box = 0x076F,
    list = 0x0770,
    list_item = 0x0771,
    tree = 0x0772,
    tree_item = 0x0773,
    table = 0x0774,
    menu_bar = 0x0775,
    menu = 0x0776,
    menu_item = 0x0777,
    tab_list = 0x0778,
    tab = 0x0779,
    tab_panel = 0x077A,
    toolbar = 0x077B,
    status_bar = 0x077C,
    dialog = 0x077D,
    alert = 0x077E,
    image = 0x077F,
    canvas = 0x0780,
    separator = 0x0781,
    scroll_bar = 0x0782,
    pane = 0x0783,
    _,
};

/// What a request of a service of the device asks the application for (RHostServiceRequest).
pub const HostService = enum(c_int) {
    /// Files to read (Rfile_open_async): `filters`, `flags` (R_FILE_DIALOG_MULTIPLE).
    open_files = 0x0C40,
    /// Save `data` / `size`, or the file `path` when data is NULL, as `file_name` (Rfile_save_async, Rfile_export_async).
    save_file = 0x0C41,
    /// A folder (Rfile_select_folder_async).
    select_folder = 0x0C42,
    /// A photo from the camera (Rcamera_take_photo); camera permission already asked.
    take_photo = 0x0C43,
    /// Up to `max_count` photos (0: no limit) from the library (Rphoto_pick).
    pick_photos = 0x0C44,
    /// The share sheet: `text` and / or the file `path` (`mime_type`), pointing at `anchor_*` (Rshare_show).
    share = 0x0C45,
    _,
};

pub const GoldenStatus = enum(c_int) {
    /// The capture matches the golden.
    match = 0x0BA0,
    /// RAVEN_UPDATE_GOLDENS=1: the capture was written as the golden.
    updated = 0x0BA1,
    /// Too many pixels differ: NAME.actual.png and NAME.diff.png were written.
    mismatch = 0x0BA2,
    /// The capture and the golden do not have the same size: NAME.actual.png was written.
    size_mismatch = 0x0BA3,
    /// There is no golden yet: NAME.actual.png was written (run with RAVEN_UPDATE_GOLDENS=1 to keep it).
    missing = 0x0BA4,
    /// The window could not be captured, or a file could not be read or written.
    failed = 0x0BA5,
    _,
};

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

/// Optional settings for Rinit_ex. A zero-initialized structure selects the
/// default for every field, so new fields can be added without breaking code.
pub const InitDesc = struct {
    /// Rendering backend. R_BACKEND_DEFAULT (0) selects WebGL in browser builds, Metal on macOS and iOS when it is compiled, Vulkan otherwise.
    backend: Backend = @fromBackingInt(0),
    /// Application name reported to the graphics driver. May be NULL.
    app_name: ?[:0]const u8 = null,
    /// Worker threads of the job system. 0 = one per spare CPU core, negative = none.
    worker_threads: i32 = 0,
    /// R_TRUE renders on the UI thread instead of a dedicated render thread.
    disable_render_thread: bool = false,
    /// R_TRUE presents without waiting for the vertical blank.
    disable_vsync: bool = false,
    /// R_TRUE enables the backend debug layer (Vulkan validation) when installed.
    enable_validation: bool = false,
    /// R_TRUE opens no OS window (null platform). Combine with R_BACKEND_NULL for tests.
    headless: bool = false,
    /// Global UI scale multiplier applied on top of the monitor scale. 0 = 1.0.
    ui_scale: f32 = 0,

    /// The structure of C.
    pub fn toC(self: InitDesc) c.RInitDesc {
        return .{
            .backend = @backingInt(self.backend),
            .app_name = rt.optPtr(self.app_name),
            .worker_threads = self.worker_threads,
            .disable_render_thread = @intFromBool(self.disable_render_thread),
            .disable_vsync = @intFromBool(self.disable_vsync),
            .enable_validation = @intFromBool(self.enable_validation),
            .headless = @intFromBool(self.headless),
            .ui_scale = self.ui_scale,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RInitDesc) InitDesc {
        return .{
            .backend = @as(Backend, @fromBackingInt(raw.backend)),
            .app_name = rt.optSpan(raw.app_name),
            .worker_threads = raw.worker_threads,
            .disable_render_thread = (raw.disable_render_thread != 0),
            .disable_vsync = (raw.disable_vsync != 0),
            .enable_validation = (raw.enable_validation != 0),
            .headless = (raw.headless != 0),
            .ui_scale = raw.ui_scale,
        };
    }
};

/// What the library holds. See Rmemory_get_stats.
pub const MemoryStats = struct {
    /// Bytes in the blocks currently allocated. 0 with the allocator of the application.
    used_bytes: usize = 0,
    /// Highest value of used_bytes since the start.
    peak_bytes: usize = 0,
    /// Bytes taken from the OS: used_bytes, plus what is free in the heap.
    reserved_bytes: usize = 0,
    /// Blocks currently allocated. 0 after Rshutdown: anything else is a leak of the library.
    allocation_count: usize = 0,
    /// Allocations made since the start.
    total_allocations: u64 = 0,

    /// The structure of C.
    pub fn toC(self: MemoryStats) c.RMemoryStats {
        return .{
            .used_bytes = self.used_bytes,
            .peak_bytes = self.peak_bytes,
            .reserved_bytes = self.reserved_bytes,
            .allocation_count = self.allocation_count,
            .total_allocations = self.total_allocations,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RMemoryStats) MemoryStats {
        return .{
            .used_bytes = raw.used_bytes,
            .peak_bytes = raw.peak_bytes,
            .reserved_bytes = raw.reserved_bytes,
            .allocation_count = raw.allocation_count,
            .total_allocations = raw.total_allocations,
        };
    }
};

/// Timings and counters of the last frame produced for a window.
pub const FrameStats = struct {
    layout_ms: f64 = 0,
    paint_ms: f64 = 0,
    render_ms: f64 = 0,
    widget_count: u32 = 0,
    instance_count: u32 = 0,
    draw_call_count: u32 = 0,
    /// Glass: times the frame was copied and blurred to be seen through (0 without glass).
    backdrop_count: u32 = 0,
    paint_job_count: u32 = 0,
    frame_index: u64 = 0,

    /// The structure of C.
    pub fn toC(self: FrameStats) c.RFrameStats {
        return .{
            .layout_ms = self.layout_ms,
            .paint_ms = self.paint_ms,
            .render_ms = self.render_ms,
            .widget_count = self.widget_count,
            .instance_count = self.instance_count,
            .draw_call_count = self.draw_call_count,
            .backdrop_count = self.backdrop_count,
            .paint_job_count = self.paint_job_count,
            .frame_index = self.frame_index,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RFrameStats) FrameStats {
        return .{
            .layout_ms = raw.layout_ms,
            .paint_ms = raw.paint_ms,
            .render_ms = raw.render_ms,
            .widget_count = raw.widget_count,
            .instance_count = raw.instance_count,
            .draw_call_count = raw.draw_call_count,
            .backdrop_count = raw.backdrop_count,
            .paint_job_count = raw.paint_job_count,
            .frame_index = raw.frame_index,
        };
    }
};

/// One format of something given to the other applications: put on
/// the clipboard (Rclipboard_set_data) or dragged out of a window
/// (Rdrag_begin_external). The program that receives it takes the format
/// it prefers.
///
/// `mime` names the format. Raven gives these their native names on each
/// system (and converts them), so that every program understands them:
///
///   text/plain      UTF-8 text
///   text/html       HTML (UTF-8)
///   image/png       a PNG file (Rimage_encode_png); on Windows it is also
///                   given as a bitmap (CF_DIBV5), on macOS also as TIFF
///   text/uri-list   files, as file:// URLs, one per line: the file
///                   manager copies or moves them, the other programs
///                   open them
///   text/rtf, image/jpeg, image/tiff, image/gif, application/pdf,
///   application/json, text/csv, image/svg+xml
///
/// Any other name is a format of the application ("application/x-myapp-node"):
/// passed as it is, and read back by the programs that know it (other
/// instances of the application).
pub const DataItem = extern struct {
    /// The format: a MIME type.
    mime: ?[*:0]const u8 = null,
    /// The bytes (copied by the function they are given to). Text is not followed by a '\0'.
    data: ?*const anyopaque = null,
    size: usize = 0,

    pub fn toC(self: DataItem) c.RDataItem {
        return @as(*const c.RDataItem, @ptrCast(&self)).*;
    }

    pub fn fromC(raw: c.RDataItem) DataItem {
        return @as(*const DataItem, @ptrCast(&raw)).*;
    }
};

/// Distances from the edges of a window, in logical units.
pub const Insets = struct {
    top: f32 = 0,
    right: f32 = 0,
    bottom: f32 = 0,
    left: f32 = 0,

    /// The structure of C.
    pub fn toC(self: Insets) c.RInsets {
        return .{
            .top = self.top,
            .right = self.right,
            .bottom = self.bottom,
            .left = self.left,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RInsets) Insets {
        return .{
            .top = raw.top,
            .right = raw.right,
            .bottom = raw.bottom,
            .left = raw.left,
        };
    }
};

/// What the platform needs to know of the focused text input to set up the on-screen keyboard.
pub const TextInputInfo = struct {
    type: TextInputType = @fromBackingInt(0),
    return_key: ReturnKey = @fromBackingInt(0),
    /// R_TRUE: the text is hidden (no suggestions, no autocorrection, no learning).
    password: bool = false,
    read_only: bool = false,
    /// Most characters accepted; 0 for no limit.
    max_length: i32 = 0,

    /// The structure of C.
    pub fn toC(self: TextInputInfo) c.RTextInputInfo {
        return .{
            .type_ = @backingInt(self.type),
            .return_key = @backingInt(self.return_key),
            .password = @intFromBool(self.password),
            .read_only = @intFromBool(self.read_only),
            .max_length = self.max_length,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RTextInputInfo) TextInputInfo {
        return .{
            .type = @as(TextInputType, @fromBackingInt(raw.type_)),
            .return_key = @as(ReturnKey, @fromBackingInt(raw.return_key)),
            .password = (raw.password != 0),
            .read_only = (raw.read_only != 0),
            .max_length = raw.max_length,
        };
    }
};

/// Native handles of a window or of a native viewport.
///   Win32 : display = HINSTANCE, window = HWND
///   X11   : display = Display*,  window = Window (XID), visual = VisualID
///   Wayland: display = wl_display*, window = wl_surface* (Linux and BSD choose
///           Wayland or X11 when Rinit runs: check `system`)
///   Cocoa : display = NSWindow*, window = CAMetalLayer* for Vulkan presentation
///   Emscripten: window = opaque browser surface token (no OS window handle)
///   Android: window = ANativeWindow*
///   UIKit : display = UIWindow*, window = CAMetalLayer* for Vulkan presentation (iOS, iPadOS)
pub const NativeWindow = struct {
    system: WindowSystem = @fromBackingInt(0),
    display: ?*anyopaque = null,
    window: usize = 0,
    visual: usize = 0,
    /// R_TRUE when the window was created with R_WINDOW_TRANSPARENT and the
    /// window system gave it an alpha channel: what is presented in it must
    /// carry alpha (premultiplied), which a rendering backend asks for when
    /// it creates its surface.
    transparent: bool = false,

    /// The structure of C.
    pub fn toC(self: NativeWindow) c.RNativeWindow {
        return .{
            .system = @backingInt(self.system),
            .display = self.display,
            .window = self.window,
            .visual = self.visual,
            .transparent = @intFromBool(self.transparent),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RNativeWindow) NativeWindow {
        return .{
            .system = @as(WindowSystem, @fromBackingInt(raw.system)),
            .display = raw.display,
            .window = raw.window,
            .visual = raw.visual,
            .transparent = (raw.transparent != 0),
        };
    }
};

/// Input event delivered to a widget. Mouse and key events bubble from the
/// target widget to its parents until one of them handles the event.
pub const Event = struct {
    type: EventType = @fromBackingInt(0),
    window: ?Window = null,
    /// Widget the event was first sent to.
    target: ?Widget = null,
    /// Cursor position in the window, in logical units.
    x: f32 = 0,
    /// Cursor position in the window, in logical units.
    y: f32 = 0,
    /// Cursor position relative to the widget receiving the event.
    local_x: f32 = 0,
    /// Cursor position relative to the widget receiving the event.
    local_y: f32 = 0,
    /// Mouse movement since the previous event (R_EVENT_MOUSE_MOVE).
    delta_x: f32 = 0,
    /// Mouse movement since the previous event (R_EVENT_MOUSE_MOVE).
    delta_y: f32 = 0,
    /// Scroll amount in lines, positive = up / left (R_EVENT_MOUSE_WHEEL).
    wheel_x: f32 = 0,
    /// Scroll amount in lines, positive = up / left (R_EVENT_MOUSE_WHEEL).
    wheel_y: f32 = 0,
    button: MouseButton = @fromBackingInt(0),
    /// 1 = single click, 2 = double click, ... (R_EVENT_MOUSE_DOWN).
    clicks: i32 = 0,
    key: Key = @fromBackingInt(0),
    /// Bitmask of RModifier.
    modifiers: Modifier = .{},
    /// R_TRUE when the key event comes from auto-repeat.
    repeat: bool = false,
    codepoint: u32 = 0,
    /// R_EVENT_MOUSE_WHEEL: R_TRUE when the wheel comes from a trackpad (or a
    /// mouse that scrolls smoothly). wheel_x, wheel_y are then small fractions of
    /// a line, a line being 48 logical units the fingers moved: what follows the
    /// fingers moves 48 units per line, and a canvas pans rather than zooms.
    wheel_precise: bool = false,

    /// The structure of C.
    pub fn toC(self: Event) c.REvent {
        return .{
            .type_ = @backingInt(self.type),
            .window = optId(self.window),
            .target = optId(self.target),
            .x = self.x,
            .y = self.y,
            .local_x = self.local_x,
            .local_y = self.local_y,
            .delta_x = self.delta_x,
            .delta_y = self.delta_y,
            .wheel_x = self.wheel_x,
            .wheel_y = self.wheel_y,
            .button = @backingInt(self.button),
            .clicks = self.clicks,
            .key = @backingInt(self.key),
            .modifiers = @as(u32, @bitCast(self.modifiers)),
            .repeat = @intFromBool(self.repeat),
            .codepoint = self.codepoint,
            .wheel_precise = @intFromBool(self.wheel_precise),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.REvent) Event {
        return .{
            .type = @as(EventType, @fromBackingInt(raw.type_)),
            .window = Window.fromId(raw.window),
            .target = Widget.fromId(raw.target),
            .x = raw.x,
            .y = raw.y,
            .local_x = raw.local_x,
            .local_y = raw.local_y,
            .delta_x = raw.delta_x,
            .delta_y = raw.delta_y,
            .wheel_x = raw.wheel_x,
            .wheel_y = raw.wheel_y,
            .button = @as(MouseButton, @fromBackingInt(raw.button)),
            .clicks = raw.clicks,
            .key = @as(Key, @fromBackingInt(raw.key)),
            .modifiers = @as(Modifier, @bitCast(@as(u32, raw.modifiers))),
            .repeat = (raw.repeat != 0),
            .codepoint = raw.codepoint,
            .wheel_precise = (raw.wheel_precise != 0),
        };
    }
};

/// What a drop target receives. The files and the text are only known when
/// the drop happens (R_DROP_DROPPED), and are valid during the callback.
pub const DropEvent = struct {
    phase: DropPhase = @fromBackingInt(0),
    window: ?Window = null,
    /// Pointer position in the window, and relative to the target widget.
    x: f32 = 0,
    /// Pointer position in the window, and relative to the target widget.
    y: f32 = 0,
    local_x: f32 = 0,
    local_y: f32 = 0,
    /// Dropped files and folders, as UTF-8 paths.
    paths: []const [*:0]const u8 = &.{},
    /// Dropped text when it is not files, or NULL. For a drag inside the application: its data.
    text: ?[:0]const u8 = null,
    /// Drag inside the application (Rdrag_begin): its type, else NULL. Set in every phase.
    drag_type: ?[:0]const u8 = null,
    /// Widget the drag started from, or R_INVALID_ID.
    drag_source: ?Widget = null,

    /// The structure of C.
    pub fn toC(self: DropEvent) c.RDropEvent {
        return .{
            .phase = @backingInt(self.phase),
            .window = optId(self.window),
            .x = self.x,
            .y = self.y,
            .local_x = self.local_x,
            .local_y = self.local_y,
            .paths = if (self.paths.len > 0) @ptrCast(self.paths.ptr) else null,
            .path_count = @intCast(self.paths.len),
            .text = rt.optPtr(self.text),
            .drag_type = rt.optPtr(self.drag_type),
            .drag_source = optId(self.drag_source),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RDropEvent) DropEvent {
        return .{
            .phase = @as(DropPhase, @fromBackingInt(raw.phase)),
            .window = Window.fromId(raw.window),
            .x = raw.x,
            .y = raw.y,
            .local_x = raw.local_x,
            .local_y = raw.local_y,
            .paths = rt.spanArray(raw.paths, raw.path_count),
            .text = rt.optSpan(raw.text),
            .drag_type = rt.optSpan(raw.drag_type),
            .drag_source = Widget.fromId(raw.drag_source),
        };
    }
};

/// How the library treats fingers and pens (Rtouch_set_settings, Rwindow_set_touch_settings).
pub const TouchSettings = struct {
    /// R_TRUE (default): one finger drives the widgets as the mouse does: a tap clicks, a drag drags.
    mouse_emulation: bool = false,
    /// How far a finger moves (logical units) before a press becomes a drag or a scroll. Default 8.
    slop: f32 = 0,
    /// Seconds a finger rests before the press is a right click (the context menu); 0 turns it off. Default 0.5.
    long_press: f32 = 0,
    /// R_TRUE (default): flicked content keeps going and slows down.
    inertia: bool = false,
    /// How fast it slows down, in logical units per second per second. Default 2400.
    deceleration: f32 = 0,
    /// R_TRUE (default): two fingers pinch to zoom and pan.
    gestures: bool = false,
    /// R_TRUE (default): the pen drives the widgets as the mouse does (its barrel button: the right button).
    pen_mouse_emulation: bool = false,
    /// The pressure given to the application is the one of the pen to this power: 1 (default) as it is, below 1 softer, above 1 harder.
    pressure_curve: f32 = 0,
    /// Pressure (0..1, after the curve) the tip needs before it presses. Default 0.
    pressure_threshold: f32 = 0,
    /// R_TRUE (default): fingers are ignored while a pen is near the screen, and half a second after (the palm resting on it).
    palm_rejection: bool = false,
    /// R_TRUE (default): the pinch and the rotation of a trackpad zoom what zooms, as two fingers on the screen do.
    trackpad_gestures: bool = false,
    /// R_TRUE (default): three or more fingers swiped across a trackpad go back or forward (the side buttons of a mouse).
    swipe_navigation: bool = false,
    /// How far (logical units) the fingers of a swipe go across before it navigates. Default 120.
    swipe_distance: f32 = 0,
    /// Smallest height (logical units) of what a finger presses: buttons,
    /// fields, combo boxes, tabs and bars are at least this high, rows of
    /// lists, trees, tables and menus too, and so are check boxes, switches
    /// and sliders, whose box and handle grow to half of it. Whatever the
    /// theme or a widget asks for, 0 leaves the sizes as they are.
    /// Default 44 on iOS (Apple: 44 points), 48 on Android (Material: 48 dp),
    /// 0 elsewhere.
    min_touch_size: f32 = 0,

    /// The structure of C.
    pub fn toC(self: TouchSettings) c.RTouchSettings {
        return .{
            .mouse_emulation = @intFromBool(self.mouse_emulation),
            .slop = self.slop,
            .long_press = self.long_press,
            .inertia = @intFromBool(self.inertia),
            .deceleration = self.deceleration,
            .gestures = @intFromBool(self.gestures),
            .pen_mouse_emulation = @intFromBool(self.pen_mouse_emulation),
            .pressure_curve = self.pressure_curve,
            .pressure_threshold = self.pressure_threshold,
            .palm_rejection = @intFromBool(self.palm_rejection),
            .trackpad_gestures = @intFromBool(self.trackpad_gestures),
            .swipe_navigation = @intFromBool(self.swipe_navigation),
            .swipe_distance = self.swipe_distance,
            .min_touch_size = self.min_touch_size,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RTouchSettings) TouchSettings {
        return .{
            .mouse_emulation = (raw.mouse_emulation != 0),
            .slop = raw.slop,
            .long_press = raw.long_press,
            .inertia = (raw.inertia != 0),
            .deceleration = raw.deceleration,
            .gestures = (raw.gestures != 0),
            .pen_mouse_emulation = (raw.pen_mouse_emulation != 0),
            .pressure_curve = raw.pressure_curve,
            .pressure_threshold = raw.pressure_threshold,
            .palm_rejection = (raw.palm_rejection != 0),
            .trackpad_gestures = (raw.trackpad_gestures != 0),
            .swipe_navigation = (raw.swipe_navigation != 0),
            .swipe_distance = raw.swipe_distance,
            .min_touch_size = raw.min_touch_size,
        };
    }
};

pub const TouchEvent = struct {
    phase: TouchPhase = @fromBackingInt(0),
    window: ?Window = null,
    /// Widget the finger came down on.
    target: ?Widget = null,
    /// Number of the finger, the same from its down to its up.
    id: i32 = 0,
    /// Position in the window, and relative to the widget receiving the event.
    x: f32 = 0,
    /// Position in the window, and relative to the widget receiving the event.
    y: f32 = 0,
    local_x: f32 = 0,
    local_y: f32 = 0,
    /// 0..1; 1 when the screen does not tell.
    pressure: f32 = 0,
    /// Size of the contact, 0 when the screen does not tell.
    width: f32 = 0,
    /// Size of the contact, 0 when the screen does not tell.
    height: f32 = 0,
    /// Fingers on the window, this one included (0 after the last up).
    count: i32 = 0,
    /// Bitmask of RModifier.
    modifiers: Modifier = .{},

    /// The structure of C.
    pub fn toC(self: TouchEvent) c.RTouchEvent {
        return .{
            .phase = @backingInt(self.phase),
            .window = optId(self.window),
            .target = optId(self.target),
            .id = self.id,
            .x = self.x,
            .y = self.y,
            .local_x = self.local_x,
            .local_y = self.local_y,
            .pressure = self.pressure,
            .width = self.width,
            .height = self.height,
            .count = self.count,
            .modifiers = @as(u32, @bitCast(self.modifiers)),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RTouchEvent) TouchEvent {
        return .{
            .phase = @as(TouchPhase, @fromBackingInt(raw.phase)),
            .window = Window.fromId(raw.window),
            .target = Widget.fromId(raw.target),
            .id = raw.id,
            .x = raw.x,
            .y = raw.y,
            .local_x = raw.local_x,
            .local_y = raw.local_y,
            .pressure = raw.pressure,
            .width = raw.width,
            .height = raw.height,
            .count = raw.count,
            .modifiers = @as(Modifier, @bitCast(@as(u32, raw.modifiers))),
        };
    }
};

pub const PenEvent = struct {
    phase: PenPhase = @fromBackingInt(0),
    window: ?Window = null,
    /// Widget under the pen; during a stroke, the one it started on.
    target: ?Widget = null,
    x: f32 = 0,
    y: f32 = 0,
    local_x: f32 = 0,
    local_y: f32 = 0,
    /// 0..1, after the pressure curve; 0 while hovering.
    pressure: f32 = 0,
    /// As the pen gives it, 0..1.
    raw_pressure: f32 = 0,
    /// Tilt of the pen in degrees, -90..90, toward the right and toward the user; 0 when upright or unknown.
    tilt_x: f32 = 0,
    /// Tilt of the pen in degrees, -90..90, toward the right and toward the user; 0 when upright or unknown.
    tilt_y: f32 = 0,
    /// Rotation around its axis in degrees, 0..360 (when the pen tells).
    rotation: f32 = 0,
    /// R_TRUE when the eraser end touches (or the eraser button is held).
    eraser: bool = false,
    /// Bitmask of RPenButton.
    buttons: PenButton = .{},
    modifiers: Modifier = .{},

    /// The structure of C.
    pub fn toC(self: PenEvent) c.RPenEvent {
        return .{
            .phase = @backingInt(self.phase),
            .window = optId(self.window),
            .target = optId(self.target),
            .x = self.x,
            .y = self.y,
            .local_x = self.local_x,
            .local_y = self.local_y,
            .pressure = self.pressure,
            .raw_pressure = self.raw_pressure,
            .tilt_x = self.tilt_x,
            .tilt_y = self.tilt_y,
            .rotation = self.rotation,
            .eraser = @intFromBool(self.eraser),
            .buttons = @as(u32, @bitCast(self.buttons)),
            .modifiers = @as(u32, @bitCast(self.modifiers)),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RPenEvent) PenEvent {
        return .{
            .phase = @as(PenPhase, @fromBackingInt(raw.phase)),
            .window = Window.fromId(raw.window),
            .target = Widget.fromId(raw.target),
            .x = raw.x,
            .y = raw.y,
            .local_x = raw.local_x,
            .local_y = raw.local_y,
            .pressure = raw.pressure,
            .raw_pressure = raw.raw_pressure,
            .tilt_x = raw.tilt_x,
            .tilt_y = raw.tilt_y,
            .rotation = raw.rotation,
            .eraser = (raw.eraser != 0),
            .buttons = @as(PenButton, @bitCast(@as(u32, raw.buttons))),
            .modifiers = @as(Modifier, @bitCast(@as(u32, raw.modifiers))),
        };
    }
};

pub const GestureEvent = struct {
    phase: GesturePhase = @fromBackingInt(0),
    window: ?Window = null,
    /// Widget under the center of the fingers when the gesture began.
    target: ?Widget = null,
    /// Center of the fingers, in the window and relative to the widget receiving the event.
    x: f32 = 0,
    /// Center of the fingers, in the window and relative to the widget receiving the event.
    y: f32 = 0,
    local_x: f32 = 0,
    local_y: f32 = 0,
    /// Distance between the fingers relative to when the gesture began (2 = twice as far apart).
    scale: f32 = 0,
    /// The same since the previous event: what a zoom multiplies by.
    scale_delta: f32 = 0,
    /// Movement of the center since the previous event.
    pan_x: f32 = 0,
    /// Movement of the center since the previous event.
    pan_y: f32 = 0,
    /// Turn of the fingers since the gesture began, in degrees, clockwise.
    rotation: f32 = 0,
    /// R_GESTURE_PINCH or R_GESTURE_SWIPE.
    kind: GestureKind = @fromBackingInt(0),
    /// R_GESTURE_DEVICE_TOUCHSCREEN or R_GESTURE_DEVICE_TRACKPAD.
    device: GestureDevice = @fromBackingInt(0),
    /// Fingers of the gesture (2 for a pinch, 3 or more for a swipe; 0 when the system does not tell).
    fingers: i32 = 0,
    /// Movement of the center since the gesture began.
    total_x: f32 = 0,
    /// Movement of the center since the gesture began.
    total_y: f32 = 0,
    /// The same turn as `rotation`, since the previous event.
    rotation_delta: f32 = 0,
    /// R_GESTURE_END: R_TRUE when the system took the gesture back (nothing must happen as for an end).
    cancelled: bool = false,

    /// The structure of C.
    pub fn toC(self: GestureEvent) c.RGestureEvent {
        return .{
            .phase = @backingInt(self.phase),
            .window = optId(self.window),
            .target = optId(self.target),
            .x = self.x,
            .y = self.y,
            .local_x = self.local_x,
            .local_y = self.local_y,
            .scale = self.scale,
            .scale_delta = self.scale_delta,
            .pan_x = self.pan_x,
            .pan_y = self.pan_y,
            .rotation = self.rotation,
            .kind = @backingInt(self.kind),
            .device = @backingInt(self.device),
            .fingers = self.fingers,
            .total_x = self.total_x,
            .total_y = self.total_y,
            .rotation_delta = self.rotation_delta,
            .cancelled = @intFromBool(self.cancelled),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RGestureEvent) GestureEvent {
        return .{
            .phase = @as(GesturePhase, @fromBackingInt(raw.phase)),
            .window = Window.fromId(raw.window),
            .target = Widget.fromId(raw.target),
            .x = raw.x,
            .y = raw.y,
            .local_x = raw.local_x,
            .local_y = raw.local_y,
            .scale = raw.scale,
            .scale_delta = raw.scale_delta,
            .pan_x = raw.pan_x,
            .pan_y = raw.pan_y,
            .rotation = raw.rotation,
            .kind = @as(GestureKind, @fromBackingInt(raw.kind)),
            .device = @as(GestureDevice, @fromBackingInt(raw.device)),
            .fingers = raw.fingers,
            .total_x = raw.total_x,
            .total_y = raw.total_y,
            .rotation_delta = raw.rotation_delta,
            .cancelled = (raw.cancelled != 0),
        };
    }
};

/// How a PDF document is printed. Every field may be left to zero.
pub const PdfPrintDesc = struct {
    /// Window the print dialog belongs to (0 or R_INVALID_ID: none).
    window: ?Window = null,
    /// Name of the print job, shown in the queue of the printer. NULL: the title of the document or the name of the file.
    title: ?[:0]const u8 = null,
    /// Name of the printer, as the system knows it. NULL: the one chosen in the dialog, else the default printer.
    printer: ?[:0]const u8 = null,
    /// Copies to print (0: one); the dialog may change it.
    copies: i32 = 0,
    /// Bitmask of RPdfPrintFlags.
    flags: u32 = 0,
    /// Path of a file the job is written to instead of a printer. macOS: a
    /// PDF made by the print system; Windows: what the driver of the printer
    /// makes; elsewhere: the document itself.
    output: ?[:0]const u8 = null,
    /// Password of a document protected by one.
    password: ?[:0]const u8 = null,

    /// The structure of C.
    pub fn toC(self: PdfPrintDesc) c.RPdfPrintDesc {
        return .{
            .window = optId(self.window),
            .title = rt.optPtr(self.title),
            .printer = rt.optPtr(self.printer),
            .copies = self.copies,
            .flags = self.flags,
            .output = rt.optPtr(self.output),
            .password = rt.optPtr(self.password),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RPdfPrintDesc) PdfPrintDesc {
        return .{
            .window = Window.fromId(raw.window),
            .title = rt.optSpan(raw.title),
            .printer = rt.optSpan(raw.printer),
            .copies = raw.copies,
            .flags = raw.flags,
            .output = rt.optSpan(raw.output),
            .password = rt.optSpan(raw.password),
        };
    }
};

/// What a tile shows, filled by the application when the tile is drawn.
pub const TileItem = struct {
    /// Name under the icon (valid until the callback returns).
    text: ?[:0]const u8 = null,
    /// Second line, dimmer, or NULL.
    detail: ?[:0]const u8 = null,
    /// Small text at the top right of the tile, or NULL.
    badge: ?[:0]const u8 = null,
    /// Icon texture (R_INVALID_ID: none), the region of it and its tint (white by default; an SVG in currentColor is also tinted with the color of the name).
    icon: ?Texture = null,
    uv: [4]f32 = @splat(0),
    tint: [4]f32 = @splat(0),
    icon_radius: f32 = 0,
    /// Color of the name; alpha 0 = the theme.
    text_color: [4]f32 = @splat(0),
    /// Layout="Rows": a third line under the detail, dimmer, or NULL.
    note: ?[:0]const u8 = null,
    /// Color of the detail line; alpha 0 = the theme (dimmer than the name).
    detail_color: [4]f32 = @splat(0),

    /// The structure of C.
    pub fn toC(self: TileItem) c.RTileItem {
        return .{
            .text = rt.optPtr(self.text),
            .detail = rt.optPtr(self.detail),
            .badge = rt.optPtr(self.badge),
            .icon = optId(self.icon),
            .uv = self.uv,
            .tint = self.tint,
            .icon_radius = self.icon_radius,
            .text_color = self.text_color,
            .note = rt.optPtr(self.note),
            .detail_color = self.detail_color,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RTileItem) TileItem {
        return .{
            .text = rt.optSpan(raw.text),
            .detail = rt.optSpan(raw.detail),
            .badge = rt.optSpan(raw.badge),
            .icon = Texture.fromId(raw.icon),
            .uv = raw.uv,
            .tint = raw.tint,
            .icon_radius = raw.icon_radius,
            .text_color = raw.text_color,
            .note = rt.optSpan(raw.note),
            .detail_color = raw.detail_color,
        };
    }
};

/// A section of a tile view: its first tile, and what its header shows.
pub const TileSection = struct {
    /// Index of the first tile of the section (read when the sections are given).
    first: i32 = 0,
    /// Title of the header (valid until the callback returns).
    text: ?[:0]const u8 = null,
    /// Dimmer text after the title (a count...), or NULL.
    detail: ?[:0]const u8 = null,

    /// The structure of C.
    pub fn toC(self: TileSection) c.RTileSection {
        return .{
            .first = self.first,
            .text = rt.optPtr(self.text),
            .detail = rt.optPtr(self.detail),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RTileSection) TileSection {
        return .{
            .first = raw.first,
            .text = rt.optSpan(raw.text),
            .detail = rt.optSpan(raw.detail),
        };
    }
};

/// What the editor knows of a language. Every field but the name may be NULL.
/// Lists of words are separated by spaces.
pub const LanguageDesc = struct {
    /// "Rust". Compared without case.
    name: ?[:0]const u8 = null,
    /// Extensions of its files, separated by ';': "rs".
    extensions: ?[:0]const u8 = null,
    /// Words of the language itself: if, while, return...
    keywords: ?[:0]const u8 = null,
    /// Names of types and of what is always there: int, String, print...
    types: ?[:0]const u8 = null,
    /// Values with a name: true, false, null...
    constants: ?[:0]const u8 = null,
    /// What starts a comment that ends with its line: two slashes, a hash.
    line_comment: ?[:0]const u8 = null,
    /// What opens and closes a comment that may span lines.
    block_comment_start: ?[:0]const u8 = null,
    block_comment_end: ?[:0]const u8 = null,
    /// Characters that open and close a text on one line: a double quote, a single quote.
    string_quotes: ?[:0]const u8 = null,
    /// Marks of the texts that span lines, separated by spaces: three double
    /// quotes, a backquote. When what closes such a text is not what opens it,
    /// write both around three dots: R"(...)" . Nothing is escaped in those.
    multiline_strings: ?[:0]const u8 = null,
    /// What starts a line for the preprocessor: "#".
    directive: ?[:0]const u8 = null,
    /// What starts an annotation: "@" (@Override), or "#[" up to its closing bracket.
    annotation: ?[:0]const u8 = null,
    /// Bitmask of RLanguageFlags.
    flags: LanguageFlags = .{},
    /// Markup with R_LANGUAGE_EMBEDS: the language of what is between
    /// <script> and </script> (the name of a language: "C", "Rust"...).
    /// NULL: JavaScript, as in HTML.
    script_language: ?[:0]const u8 = null,

    /// The structure of C.
    pub fn toC(self: LanguageDesc) c.RLanguageDesc {
        return .{
            .name = rt.optPtr(self.name),
            .extensions = rt.optPtr(self.extensions),
            .keywords = rt.optPtr(self.keywords),
            .types = rt.optPtr(self.types),
            .constants = rt.optPtr(self.constants),
            .line_comment = rt.optPtr(self.line_comment),
            .block_comment_start = rt.optPtr(self.block_comment_start),
            .block_comment_end = rt.optPtr(self.block_comment_end),
            .string_quotes = rt.optPtr(self.string_quotes),
            .multiline_strings = rt.optPtr(self.multiline_strings),
            .directive = rt.optPtr(self.directive),
            .annotation = rt.optPtr(self.annotation),
            .flags = @as(u32, @bitCast(self.flags)),
            .script_language = rt.optPtr(self.script_language),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RLanguageDesc) LanguageDesc {
        return .{
            .name = rt.optSpan(raw.name),
            .extensions = rt.optSpan(raw.extensions),
            .keywords = rt.optSpan(raw.keywords),
            .types = rt.optSpan(raw.types),
            .constants = rt.optSpan(raw.constants),
            .line_comment = rt.optSpan(raw.line_comment),
            .block_comment_start = rt.optSpan(raw.block_comment_start),
            .block_comment_end = rt.optSpan(raw.block_comment_end),
            .string_quotes = rt.optSpan(raw.string_quotes),
            .multiline_strings = rt.optSpan(raw.multiline_strings),
            .directive = rt.optSpan(raw.directive),
            .annotation = rt.optSpan(raw.annotation),
            .flags = @as(LanguageFlags, @bitCast(@as(u32, raw.flags))),
            .script_language = rt.optSpan(raw.script_language),
        };
    }
};

/// A task of the jump list of Windows (Rtaskbar_set_jump_list).
pub const JumpTask = extern struct {
    /// What the list shows.
    title: ?[*:0]const u8 = null,
    /// The command line given to the application when it is chosen: it is started again with these arguments.
    arguments: ?[*:0]const u8 = null,
    /// The tooltip; NULL: none.
    description: ?[*:0]const u8 = null,

    pub fn toC(self: JumpTask) c.RJumpTask {
        return @as(*const c.RJumpTask, @ptrCast(&self)).*;
    }

    pub fn fromC(raw: c.RJumpTask) JumpTask {
        return @as(*const JumpTask, @ptrCast(&raw)).*;
    }
};

/// A button of a notification.
pub const NotificationAction = extern struct {
    /// Given back to the callback ("reply", "snooze"); not empty, and not "default".
    id: ?[*:0]const u8 = null,
    /// Shown to the user ("Reply").
    label: ?[*:0]const u8 = null,

    pub fn toC(self: NotificationAction) c.RNotificationAction {
        return @as(*const c.RNotificationAction, @ptrCast(&self)).*;
    }

    pub fn fromC(raw: c.RNotificationAction) NotificationAction {
        return @as(*const NotificationAction, @ptrCast(&raw)).*;
    }
};

/// A notification for Rnotification_show_desc. `size` must be
/// sizeof(RNotificationDesc): the fields that later versions of Raven add
/// come after the others, and a smaller size tells Raven they were not
/// given. The other fields may be left to zero.
pub const NotificationDesc = struct {
    /// sizeof(RNotificationDesc).
    size: u32 = 0,
    /// Names the notification: shown again with the same tag, it replaces the
    /// one still shown instead of adding another; Rnotification_close takes it
    /// away; the callback is given it. NULL or "": a tag of its own
    /// ("raven.1", "raven.2"...).
    tag: ?[:0]const u8 = null,
    title: ?[:0]const u8 = null,
    body: ?[:0]const u8 = null,
    /// 0: R_NOTIFICATION_NORMAL.
    urgency: NotificationUrgency = @fromBackingInt(0),
    /// An image file shown beside the text (PNG, JPEG, SVG...: what Raven reads), or NULL.
    icon: ?[:0]const u8 = null,
    /// Up to 3 buttons, or NULL.
    actions: []const NotificationAction = &.{},
    /// The window brought back when the notification is clicked. R_INVALID_ID: the main window (the first one opened).
    window: ?Window = null,

    /// The structure of C.
    pub fn toC(self: NotificationDesc) c.RNotificationDesc {
        return .{
            .size = self.size,
            .tag = rt.optPtr(self.tag),
            .title = rt.optPtr(self.title),
            .body = rt.optPtr(self.body),
            .urgency = @backingInt(self.urgency),
            .icon = rt.optPtr(self.icon),
            .actions = if (self.actions.len > 0) @ptrCast(self.actions.ptr) else null,
            .action_count = @intCast(self.actions.len),
            .window = optId(self.window),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RNotificationDesc) NotificationDesc {
        return .{
            .size = raw.size,
            .tag = rt.optSpan(raw.tag),
            .title = rt.optSpan(raw.title),
            .body = rt.optSpan(raw.body),
            .urgency = @as(NotificationUrgency, @fromBackingInt(raw.urgency)),
            .icon = rt.optSpan(raw.icon),
            .actions = if (raw.actions) |items| @as([*]const NotificationAction, @ptrCast(items))[0..@intCast(raw.action_count)] else &.{},
            .window = Window.fromId(raw.window),
        };
    }
};

/// A kind of file in a file dialog.
pub const FileFilter = extern struct {
    /// Shown to the user: "Images".
    name: ?[*:0]const u8 = null,
    /// Patterns separated by ';': "*.png;*.jpg". "*" matches everything.
    patterns: ?[*:0]const u8 = null,

    pub fn toC(self: FileFilter) c.RFileFilter {
        return @as(*const c.RFileFilter, @ptrCast(&self)).*;
    }

    pub fn fromC(raw: c.RFileFilter) FileFilter {
        return @as(*const FileFilter, @ptrCast(&raw)).*;
    }
};

/// Every field may be left to zero.
pub const FileDialogDesc = struct {
    /// Window the dialog belongs to. R_INVALID_ID: none (a window is opened when Raven needs one).
    parent: ?Window = null,
    /// NULL: "Open", "Save as"...
    title: ?[:0]const u8 = null,
    /// Folder shown first. NULL: the one of the previous dialog, else the home of the user.
    directory: ?[:0]const u8 = null,
    /// Name proposed to the user (save dialogs).
    file_name: ?[:0]const u8 = null,
    filters: []const FileFilter = &.{},
    /// Save dialogs: added to a name typed without extension ("xml").
    default_extension: ?[:0]const u8 = null,
    /// Bitmask of RFileDialogFlags.
    flags: FileDialogFlags = .{},

    /// The structure of C.
    pub fn toC(self: FileDialogDesc) c.RFileDialogDesc {
        return .{
            .parent = optId(self.parent),
            .title = rt.optPtr(self.title),
            .directory = rt.optPtr(self.directory),
            .file_name = rt.optPtr(self.file_name),
            .filters = if (self.filters.len > 0) @ptrCast(self.filters.ptr) else null,
            .filter_count = @intCast(self.filters.len),
            .default_extension = rt.optPtr(self.default_extension),
            .flags = @as(u32, @bitCast(self.flags)),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RFileDialogDesc) FileDialogDesc {
        return .{
            .parent = Window.fromId(raw.parent),
            .title = rt.optSpan(raw.title),
            .directory = rt.optSpan(raw.directory),
            .file_name = rt.optSpan(raw.file_name),
            .filters = if (raw.filters) |items| @as([*]const FileFilter, @ptrCast(items))[0..@intCast(raw.filter_count)] else &.{},
            .default_extension = rt.optSpan(raw.default_extension),
            .flags = @as(FileDialogFlags, @bitCast(@as(u32, raw.flags))),
        };
    }
};

/// A file given by a service of the device. Valid during the callback only: copy what you keep.
pub const PickedFile = extern struct {
    /// A path Raven and the C library can read (Rfile_read, textures, fonts,
    /// fopen). On iOS and Android a copy in the cache of the application.
    /// NULL for Rfile_save_async on iOS and Android: the file went where the
    /// user chose, which the application cannot write to again.
    path: ?[*:0]const u8 = null,
    /// The name the user saw ("IMG_0042.JPG"), to show.
    name: ?[*:0]const u8 = null,
    /// The MIME type when the system tells ("image/jpeg"), or NULL.
    mime_type: ?[*:0]const u8 = null,
    /// Bytes.
    size: u64 = 0,
    /// Pixels of a photo (Rcamera_take_photo, Rphoto_pick) when known, else 0.
    width: c_int = 0,
    /// Pixels of a photo (Rcamera_take_photo, Rphoto_pick) when known, else 0.
    height: c_int = 0,

    pub fn toC(self: PickedFile) c.RPickedFile {
        return @as(*const c.RPickedFile, @ptrCast(&self)).*;
    }

    pub fn fromC(raw: c.RPickedFile) PickedFile {
        return @as(*const PickedFile, @ptrCast(&raw)).*;
    }
};

/// What a share sheet offers to the other applications (Rshare_show). Every field may be left to zero, but not all of them.
pub const ShareDesc = struct {
    /// Text, or a link ("https://..."). May be NULL.
    text: ?[:0]const u8 = null,
    /// A file to send (a path Raven can read), or NULL.
    path: ?[:0]const u8 = null,
    /// Its MIME type ("image/png"); NULL: guessed from its extension.
    mime_type: ?[:0]const u8 = null,
    /// The title of the sheet, where the system shows one (Android's chooser). May be NULL.
    title: ?[:0]const u8 = null,
    /// The widget the sheet points at on a tablet (the button that shares). 0 or R_INVALID_ID: the middle of the window.
    anchor: ?Widget = null,

    /// The structure of C.
    pub fn toC(self: ShareDesc) c.RShareDesc {
        return .{
            .text = rt.optPtr(self.text),
            .path = rt.optPtr(self.path),
            .mime_type = rt.optPtr(self.mime_type),
            .title = rt.optPtr(self.title),
            .anchor = optId(self.anchor),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RShareDesc) ShareDesc {
        return .{
            .text = rt.optSpan(raw.text),
            .path = rt.optSpan(raw.path),
            .mime_type = rt.optSpan(raw.mime_type),
            .title = rt.optSpan(raw.title),
            .anchor = Widget.fromId(raw.anchor),
        };
    }
};

/// Passed to the draw callback of a viewport. Sizes are in pixels.
pub const ViewportDrawInfo = struct {
    backend: Backend = @fromBackingInt(0),
    viewport: ?Viewport = null,
    window: ?Window = null,
    /// Area of the viewport in the window framebuffer.
    x: i32 = 0,
    /// Area of the viewport in the window framebuffer.
    y: i32 = 0,
    /// Area of the viewport in the window framebuffer.
    width: i32 = 0,
    /// Area of the viewport in the window framebuffer.
    height: i32 = 0,
    /// Visible part of that area. Already set as the scissor rectangle.
    clip_x: i32 = 0,
    /// Visible part of that area. Already set as the scissor rectangle.
    clip_y: i32 = 0,
    /// Visible part of that area. Already set as the scissor rectangle.
    clip_width: i32 = 0,
    /// Visible part of that area. Already set as the scissor rectangle.
    clip_height: i32 = 0,
    framebuffer_width: i32 = 0,
    framebuffer_height: i32 = 0,
    frame_index: u64 = 0,
    /// Vulkan: VkCommandBuffer being recorded, inside the render pass.
    command_buffer: ?*anyopaque = null,
    /// Vulkan: VkRenderPass in use (one color attachment, no depth).
    render_pass: ?*anyopaque = null,
    /// Vulkan: VkFormat of the color attachment; Metal: MTLPixelFormat.
    color_format: u32 = 0,
    /// Metal: id<MTLRenderCommandEncoder> of the frame, inside its render pass (do not end it).
    metal_encoder: ?*anyopaque = null,
    /// Metal: id<MTLCommandBuffer> the encoder belongs to.
    metal_command_buffer: ?*anyopaque = null,
    /// Metal: id<MTLDevice> of the backend, to make pipeline states that match color_format.
    metal_device: ?*anyopaque = null,

    /// The structure of C.
    pub fn toC(self: ViewportDrawInfo) c.RViewportDrawInfo {
        return .{
            .backend = @backingInt(self.backend),
            .viewport = optId(self.viewport),
            .window = optId(self.window),
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,
            .clip_x = self.clip_x,
            .clip_y = self.clip_y,
            .clip_width = self.clip_width,
            .clip_height = self.clip_height,
            .framebuffer_width = self.framebuffer_width,
            .framebuffer_height = self.framebuffer_height,
            .frame_index = self.frame_index,
            .command_buffer = self.command_buffer,
            .render_pass = self.render_pass,
            .color_format = self.color_format,
            .metal_encoder = self.metal_encoder,
            .metal_command_buffer = self.metal_command_buffer,
            .metal_device = self.metal_device,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RViewportDrawInfo) ViewportDrawInfo {
        return .{
            .backend = @as(Backend, @fromBackingInt(raw.backend)),
            .viewport = Viewport.fromId(raw.viewport),
            .window = Window.fromId(raw.window),
            .x = raw.x,
            .y = raw.y,
            .width = raw.width,
            .height = raw.height,
            .clip_x = raw.clip_x,
            .clip_y = raw.clip_y,
            .clip_width = raw.clip_width,
            .clip_height = raw.clip_height,
            .framebuffer_width = raw.framebuffer_width,
            .framebuffer_height = raw.framebuffer_height,
            .frame_index = raw.frame_index,
            .command_buffer = raw.command_buffer,
            .render_pass = raw.render_pass,
            .color_format = raw.color_format,
            .metal_encoder = raw.metal_encoder,
            .metal_command_buffer = raw.metal_command_buffer,
            .metal_device = raw.metal_device,
        };
    }
};

/// State of one animated value. Zero-initialize it and keep it with the widget.
pub const Spring = struct {
    value: f32 = 0,
    velocity: f32 = 0,
    started: bool = false,

    /// The structure of C.
    pub fn toC(self: Spring) c.RSpring {
        return .{
            .value = self.value,
            .velocity = self.velocity,
            .started = @intFromBool(self.started),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RSpring) Spring {
        return .{
            .value = raw.value,
            .velocity = raw.velocity,
            .started = (raw.started != 0),
        };
    }

    /// Pushes a spring away from its target (units per second): it bounces back.
    pub fn kick(self: *Spring, velocity: f32) void {
        var raw_self = self.toC();
        c.Rspring_kick(&raw_self, velocity);
        self.* = .fromC(raw_self);
    }

    /// Puts a spring at rest on a value, without animation.
    pub fn set(self: *Spring, value: f32) void {
        var raw_self = self.toC();
        c.Rspring_set(&raw_self, value);
        self.* = .fromC(raw_self);
    }
};

/// How an effect is drawn. Start from Rshader_look_init.
pub const ShaderLook = struct {
    /// First and second color, 0..1, straight alpha.
    color: [4]f32 = @splat(0),
    color2: [4]f32 = @splat(0),
    /// Four numbers the effect reads as fx.params (their meaning is the effect's).
    params: [4]f32 = @splat(0),
    /// Radius of the corners, in logical units.
    radius: f32 = 0,
    /// Texture the effect reads with raven_texture(), or R_INVALID_ID.
    texture: ?Texture = null,
    /// -1: animated when the shader is (R_SHADER_ANIMATED); R_TRUE / R_FALSE forces it.
    animate: bool = false,
    /// R_TRUE (the default): the effect knows where the pointer is (fx.pointer, fx.hover, fx.press).
    pointer: bool = false,
    /// How much the pointer is over it and how much it is pressed, 0..1, as
    /// the effect reads them (fx.hover, fx.press). -1 (the default): 1 while
    /// the pointer is in the rectangle, and while the left button is down
    /// there; a Border eases them itself. The rectangle is clipped to the
    /// visible painting area; overlaid siblings do not interrupt its hover.
    hover: f32 = 0,
    press: f32 = 0,

    /// The structure of C.
    pub fn toC(self: ShaderLook) c.RShaderLook {
        return .{
            .color = self.color,
            .color2 = self.color2,
            .params = self.params,
            .radius = self.radius,
            .texture = optId(self.texture),
            .animate = @intFromBool(self.animate),
            .pointer = @intFromBool(self.pointer),
            .hover = self.hover,
            .press = self.press,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RShaderLook) ShaderLook {
        return .{
            .color = raw.color,
            .color2 = raw.color2,
            .params = raw.params,
            .radius = raw.radius,
            .texture = Texture.fromId(raw.texture),
            .animate = (raw.animate != 0),
            .pointer = (raw.pointer != 0),
            .hover = raw.hover,
            .press = raw.press,
        };
    }

    /// White to white, no parameter, no texture, square corners, animated when the shader is.
    pub fn init() ShaderLook {
        var raw_look: c.RShaderLook = .{};
        c.Rshader_look_init(&raw_look);
        return .fromC(raw_look);
    }
};

/// Where and why a text could not be read (Rxml_document_parse).
pub const XmlError = struct {
    /// Both start at 1.
    line: i32 = 0,
    column: i32 = 0,
    message: [160]u8 = @splat(0),

    /// The structure of C.
    pub fn toC(self: XmlError) c.RXmlError {
        return .{
            .line = self.line,
            .column = self.column,
            .message = self.message,
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RXmlError) XmlError {
        return .{
            .line = raw.line,
            .column = raw.column,
            .message = raw.message,
        };
    }

    /// The message, without the zeros after it.
    pub fn text(self: *const XmlError) []const u8 {
        return std.mem.sliceTo(&self.message, 0);
    }
};

/// One attribute of a tag (Rxml_get_attribute_info). The strings belong to the library.
pub const XmlAttributeInfo = struct {
    name: ?[:0]const u8 = null,
    type: XmlValueType = @fromBackingInt(0),
    /// R_XML_CHOICE: the words, separated by '|'. NULL otherwise.
    choices: ?[:0]const u8 = null,
    /// What it belongs to: the tag itself ("Button"), "Widget" for what every widget has, "Slot" for the place in the parent.
    group: ?[:0]const u8 = null,
    /// One line saying what it does.
    description: ?[:0]const u8 = null,

    /// The structure of C.
    pub fn toC(self: XmlAttributeInfo) c.RXmlAttributeInfo {
        return .{
            .name = rt.optPtr(self.name),
            .type_ = @backingInt(self.type),
            .choices = rt.optPtr(self.choices),
            .group = rt.optPtr(self.group),
            .description = rt.optPtr(self.description),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RXmlAttributeInfo) XmlAttributeInfo {
        return .{
            .name = rt.optSpan(raw.name),
            .type = @as(XmlValueType, @fromBackingInt(raw.type_)),
            .choices = rt.optSpan(raw.choices),
            .group = rt.optSpan(raw.group),
            .description = rt.optSpan(raw.description),
        };
    }
};

/// What the system asks for.
pub const AccessibilitySettings = struct {
    /// Size of the texts asked by the user (1 = normal).
    text_scale: f32 = 0,
    high_contrast: i32 = 0,
    reduce_motion: i32 = 0,
    /// R_TRUE when a screen reader is running.
    screen_reader: bool = false,

    /// The structure of C.
    pub fn toC(self: AccessibilitySettings) c.RAccessibilitySettings {
        return .{
            .text_scale = self.text_scale,
            .high_contrast = self.high_contrast,
            .reduce_motion = self.reduce_motion,
            .screen_reader = @intFromBool(self.screen_reader),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RAccessibilitySettings) AccessibilitySettings {
        return .{
            .text_scale = raw.text_scale,
            .high_contrast = raw.high_contrast,
            .reduce_motion = raw.reduce_motion,
            .screen_reader = (raw.screen_reader != 0),
        };
    }
};

/// A request of a service of the device, valid during the call only. Fields that do not concern the service are zero.
pub const HostServiceRequest = struct {
    /// Given back to Rhost_service_complete.
    id: u32 = 0,
    service: HostService = @fromBackingInt(0),
    /// The window it is for (R_INVALID_ID: none).
    window: ?Window = null,
    /// What it points at (a share sheet on a tablet), in pixels of the window; width 0: the middle of the window.
    anchor_x: f32 = 0,
    /// What it points at (a share sheet on a tablet), in pixels of the window; width 0: the middle of the window.
    anchor_y: f32 = 0,
    /// What it points at (a share sheet on a tablet), in pixels of the window; width 0: the middle of the window.
    anchor_width: f32 = 0,
    /// What it points at (a share sheet on a tablet), in pixels of the window; width 0: the middle of the window.
    anchor_height: f32 = 0,
    title: ?[:0]const u8 = null,
    filters: []const FileFilter = &.{},
    /// Bitmask of RFileDialogFlags.
    flags: u32 = 0,
    file_name: ?[:0]const u8 = null,
    default_extension: ?[:0]const u8 = null,
    data: ?*const anyopaque = null,
    size: usize = 0,
    path: ?[:0]const u8 = null,
    max_count: i32 = 0,
    text: ?[:0]const u8 = null,
    mime_type: ?[:0]const u8 = null,
    share_title: ?[:0]const u8 = null,

    /// The structure of C.
    pub fn toC(self: HostServiceRequest) c.RHostServiceRequest {
        return .{
            .id = self.id,
            .service = @backingInt(self.service),
            .window = optId(self.window),
            .anchor_x = self.anchor_x,
            .anchor_y = self.anchor_y,
            .anchor_width = self.anchor_width,
            .anchor_height = self.anchor_height,
            .title = rt.optPtr(self.title),
            .filters = if (self.filters.len > 0) @ptrCast(self.filters.ptr) else null,
            .filter_count = @intCast(self.filters.len),
            .flags = self.flags,
            .file_name = rt.optPtr(self.file_name),
            .default_extension = rt.optPtr(self.default_extension),
            .data = self.data,
            .size = self.size,
            .path = rt.optPtr(self.path),
            .max_count = self.max_count,
            .text = rt.optPtr(self.text),
            .mime_type = rt.optPtr(self.mime_type),
            .share_title = rt.optPtr(self.share_title),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RHostServiceRequest) HostServiceRequest {
        return .{
            .id = raw.id,
            .service = @as(HostService, @fromBackingInt(raw.service)),
            .window = Window.fromId(raw.window),
            .anchor_x = raw.anchor_x,
            .anchor_y = raw.anchor_y,
            .anchor_width = raw.anchor_width,
            .anchor_height = raw.anchor_height,
            .title = rt.optSpan(raw.title),
            .filters = if (raw.filters) |items| @as([*]const FileFilter, @ptrCast(items))[0..@intCast(raw.filter_count)] else &.{},
            .flags = raw.flags,
            .file_name = rt.optSpan(raw.file_name),
            .default_extension = rt.optSpan(raw.default_extension),
            .data = raw.data,
            .size = raw.size,
            .path = rt.optSpan(raw.path),
            .max_count = raw.max_count,
            .text = rt.optSpan(raw.text),
            .mime_type = rt.optSpan(raw.mime_type),
            .share_title = rt.optSpan(raw.share_title),
        };
    }
};

/// How Rtest_expect_golden compares. NULL options: a tolerance of 2 per channel and no different pixel.
pub const GoldenOptions = struct {
    /// Largest difference on one channel (0..255) for which two pixels are still the same.
    channel_tolerance: i32 = 0,
    /// Share of the pixels (0..1) that may differ while the images still match.
    max_diff_ratio: f32 = 0,
    /// R_TRUE: the golden of this OS and backend, "button.png" read as "button.macos-metal.png" (Rtest_get_platform_tag).
    per_platform: bool = false,
    /// Folder of the .actual.png and .diff.png written on a mismatch. NULL: beside the golden.
    output_directory: ?[:0]const u8 = null,

    /// The structure of C.
    pub fn toC(self: GoldenOptions) c.RGoldenOptions {
        return .{
            .channel_tolerance = self.channel_tolerance,
            .max_diff_ratio = self.max_diff_ratio,
            .per_platform = @intFromBool(self.per_platform),
            .output_directory = rt.optPtr(self.output_directory),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RGoldenOptions) GoldenOptions {
        return .{
            .channel_tolerance = raw.channel_tolerance,
            .max_diff_ratio = raw.max_diff_ratio,
            .per_platform = (raw.per_platform != 0),
            .output_directory = rt.optSpan(raw.output_directory),
        };
    }
};

/// What Rtest_expect_golden found.
pub const GoldenResult = struct {
    status: GoldenStatus = @fromBackingInt(0),
    /// Size of the capture, in pixels.
    width: i32 = 0,
    /// Size of the capture, in pixels.
    height: i32 = 0,
    /// Pixels farther from the golden than the tolerance.
    differing_pixels: i32 = 0,
    /// Largest difference found on one channel (0..255).
    max_channel_difference: i32 = 0,
    /// The golden that was read or written (with the platform tag). Valid until the next call.
    golden_path: ?[:0]const u8 = null,
    /// One line that says what happened, for the log of the test. Valid until the next call.
    message: ?[:0]const u8 = null,

    /// The structure of C.
    pub fn toC(self: GoldenResult) c.RGoldenResult {
        return .{
            .status = @backingInt(self.status),
            .width = self.width,
            .height = self.height,
            .differing_pixels = self.differing_pixels,
            .max_channel_difference = self.max_channel_difference,
            .golden_path = rt.optPtr(self.golden_path),
            .message = rt.optPtr(self.message),
        };
    }

    /// From the structure of C.
    pub fn fromC(raw: c.RGoldenResult) GoldenResult {
        return .{
            .status = @as(GoldenStatus, @fromBackingInt(raw.status)),
            .width = raw.width,
            .height = raw.height,
            .differing_pixels = raw.differing_pixels,
            .max_channel_difference = raw.max_channel_difference,
            .golden_path = rt.optSpan(raw.golden_path),
            .message = rt.optSpan(raw.message),
        };
    }
};

/// A widget of any kind. Each kind is a type of its own (Button, Label...):
/// `kind.widget()` is its Widget, `widget.as(Button)` the kind of a Widget.
pub const Widget = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Widget {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Widget) Rid {
        return @backingInt(self);
    }

    /// The widget as a kind, when it is one: `widget.as(Button)`.
    pub fn as(self: Widget, comptime T: type) ?T {
        const kind: WidgetType = @fromBackingInt(c.Rwidget_get_type(@backingInt(self)));
        inline for (T.widget_types) |t| {
            if (kind == t) return @fromBackingInt(@backingInt(self));
        }
        return null;
    }

    /// The widget as a kind, without checking that it is one.
    pub fn asUnchecked(self: Widget, comptime T: type) T {
        return @fromBackingInt(@backingInt(self));
    }

    /// What a finger does on the widget and what it contains (default R_TOUCH_MODE_AUTO: as its parent says).
    pub fn setTouchMode(self: Widget, mode: TouchMode) void {
        c.Rwidget_set_touch_mode(@backingInt(self), @backingInt(mode));
    }

    pub fn getTouchMode(self: Widget) TouchMode {
        const result = c.Rwidget_get_touch_mode(@backingInt(self));
        return @as(TouchMode, @fromBackingInt(result));
    }

    /// R_FALSE: two fingers (on the screen or a trackpad) neither zoom nor pan the widget (default R_TRUE).
    pub fn setTouchGestures(self: Widget, enabled: bool) void {
        c.Rwidget_set_touch_gestures(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getTouchGestures(self: Widget) i32 {
        const result = c.Rwidget_get_touch_gestures(@backingInt(self));
        return result;
    }

    /// R_FALSE: the pen is not a mouse on the widget and what it contains; only its pen callback sees it (default R_TRUE).
    pub fn setPenMouse(self: Widget, enabled: bool) void {
        c.Rwidget_set_pen_mouse(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getPenMouse(self: Widget) i32 {
        const result = c.Rwidget_get_pen_mouse(@backingInt(self));
        return result;
    }

    pub fn setTouchCallback(self: Widget, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, TouchEvent) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*const c.RTouchEvent, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), TouchEvent.fromC(a1.?.*));
                return @intFromBool(handled);
            }
        };
        c.Rwidget_set_touch_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setPenCallback(self: Widget, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, PenEvent) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*const c.RPenEvent, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), PenEvent.fromC(a1.?.*));
                return @intFromBool(handled);
            }
        };
        c.Rwidget_set_pen_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setGestureCallback(self: Widget, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, GestureEvent) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*const c.RGestureEvent, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), GestureEvent.fromC(a1.?.*));
                return @intFromBool(handled);
            }
        };
        c.Rwidget_set_gesture_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Creates a widget. It is not shown until it is added to a parent
    /// that belongs to a window (Rwidget_add_child, Rwindow_set_content).
    pub fn create(type_: WidgetType) Widget {
        const result = c.Rwidget_create(@backingInt(type_));
        return @fromBackingInt(result);
    }

    /// Deletes a widget and all its descendants.
    pub fn destroy(self: Widget) void {
        c.Rwidget_destroy(@backingInt(self));
    }

    pub fn isValid(self: Widget) bool {
        const result = c.Rwidget_is_valid(@backingInt(self));
        return result != 0;
    }

    pub fn getType(self: Widget) WidgetType {
        const result = c.Rwidget_get_type(@backingInt(self));
        return @as(WidgetType, @fromBackingInt(result));
    }

    /// Appends a child to a panel. The parent takes ownership.
    /// A widget that already has a parent is moved.
    /// Returns: `child`, so calls can be nested:
    ///         Rid ok = Rwidget_add_child(row, Rbutton_create("OK"));
    ///         R_INVALID_ID when the child replaced in a single-child container
    ///         had a destroy callback that destroyed the container or `child`;
    ///         `child`, when it is still there, is then not added.
    pub fn addChild(self: Widget, child: ?Widget) ?Widget {
        const result = c.Rwidget_add_child(@backingInt(self), optId(child));
        return Widget.fromId(result);
    }

    pub fn insertChild(self: Widget, child: Widget, index: i32) ?Widget {
        const result = c.Rwidget_insert_child(@backingInt(self), @backingInt(child), index);
        return Widget.fromId(result);
    }

    /// Detaches a child without deleting it. The caller owns it again.
    pub fn removeChild(self: Widget, child: Widget) void {
        c.Rwidget_remove_child(@backingInt(self), @backingInt(child));
    }

    /// Deletes every child of a panel.
    pub fn clearChildren(self: Widget) void {
        c.Rwidget_clear_children(@backingInt(self));
    }

    pub fn getParent(self: Widget) ?Widget {
        const result = c.Rwidget_get_parent(@backingInt(self));
        return Widget.fromId(result);
    }

    pub fn getChildCount(self: Widget) i32 {
        const result = c.Rwidget_get_child_count(@backingInt(self));
        return result;
    }

    pub fn getChild(self: Widget, index: i32) ?Widget {
        const result = c.Rwidget_get_child(@backingInt(self), index);
        return Widget.fromId(result);
    }

    /// Returns: The window showing the widget, or R_INVALID_ID.
    pub fn getWindow(self: Widget) ?Window {
        const result = c.Rwidget_get_window(@backingInt(self));
        return Window.fromId(result);
    }

    pub fn setName(self: Widget, name: [:0]const u8) void {
        c.Rwidget_set_name(@backingInt(self), name.ptr);
    }

    pub fn getName(self: Widget) [:0]const u8 {
        const result = c.Rwidget_get_name(@backingInt(self));
        return rt.span(result);
    }

    /// Finds a widget by name.
    /// scope A window or a widget; the search covers its whole subtree.
    /// Returns: R_INVALID_ID when no widget has that name.
    pub fn find(self: Widget, name: [:0]const u8) ?Widget {
        const result = c.Rwidget_find(@backingInt(self), name.ptr);
        return Widget.fromId(result);
    }

    pub fn setVisibility(self: Widget, visibility: Visibility) void {
        c.Rwidget_set_visibility(@backingInt(self), @backingInt(visibility));
    }

    pub fn getVisibility(self: Widget) Visibility {
        const result = c.Rwidget_get_visibility(@backingInt(self));
        return @as(Visibility, @fromBackingInt(result));
    }

    /// A disabled widget ignores input and is drawn dimmed, with its descendants.
    pub fn setEnabled(self: Widget, enabled: bool) void {
        c.Rwidget_set_enabled(@backingInt(self), @intFromBool(enabled));
    }

    pub fn isEnabled(self: Widget) bool {
        const result = c.Rwidget_is_enabled(@backingInt(self));
        return result != 0;
    }

    /// R_FALSE lets mouse events pass through the widget (not its children).
    pub fn setHitTestable(self: Widget, hit_testable: bool) void {
        c.Rwidget_set_hit_testable(@backingInt(self), @intFromBool(hit_testable));
    }

    /// Opacity multiplier applied to the widget and its descendants (0..1).
    pub fn setOpacity(self: Widget, opacity: f32) void {
        c.Rwidget_set_opacity(@backingInt(self), opacity);
    }

    /// Gives the widget a transition that plays each time it appears:
    /// when its window is first drawn, when it is added to a window that is
    /// shown, and when it becomes visible again (Rwidget_set_visibility, a
    /// tab or a switcher showing it). In XML: Appear="FlyUp" AppearDelay="0.1".
    /// delay_seconds Time before it starts. Give growing delays to the
    /// items of a group to make them arrive one after the other.
    pub fn setTransition(self: Widget, transition: Transition, delay_seconds: f32) void {
        c.Rwidget_set_transition(@backingInt(self), @backingInt(transition), delay_seconds);
    }

    /// Plays a transition once, now, whatever the widget was given with Rwidget_set_transition.
    pub fn playTransition(self: Widget, transition: Transition, delay_seconds: f32) void {
        c.Rwidget_play_transition(@backingInt(self), @backingInt(transition), delay_seconds);
    }

    /// R_TRUE clips the descendants to the bounds of the widget.
    pub fn setClipping(self: Widget, clip: bool) void {
        c.Rwidget_set_clipping(@backingInt(self), @intFromBool(clip));
    }

    /// Text shown when the cursor rests on the widget. NULL removes it. A label, which otherwise
    ///  lets the mouse through, takes the hover while it has a tooltip (events it does not use still bubble).
    pub fn setTooltip(self: Widget, text: ?[:0]const u8) void {
        c.Rwidget_set_tooltip(@backingInt(self), rt.optPtr(text));
    }

    /// Returns: The tooltip text of the widget, "" when it has none.
    pub fn getTooltip(self: Widget) [:0]const u8 {
        const result = c.Rwidget_get_tooltip(@backingInt(self));
        return rt.span(result);
    }

    pub fn setCursor(self: Widget, cursor: Cursor) void {
        c.Rwidget_set_cursor(@backingInt(self), @backingInt(cursor));
    }

    /// Size constraints, in logical units. They apply to the desired size the
    /// widget reports to its parent. A negative value removes the constraint
    /// on that axis.
    pub fn setSize(self: Widget, width: f32, height: f32) void {
        c.Rwidget_set_size(@backingInt(self), width, height);
    }

    pub fn setMinSize(self: Widget, width: f32, height: f32) void {
        c.Rwidget_set_min_size(@backingInt(self), width, height);
    }

    pub fn setMaxSize(self: Widget, width: f32, height: f32) void {
        c.Rwidget_set_max_size(@backingInt(self), width, height);
    }

    /// Bounds of the widget in its window, in logical units, after the last layout.
    pub fn getRect(self: Widget) struct { x: f32, y: f32, width: f32, height: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        var width: f32 = 0;
        var height: f32 = 0;
        c.Rwidget_get_rect(@backingInt(self), &x, &y, &width, &height);
        return .{ .x = x, .y = y, .width = width, .height = height };
    }

    pub fn getDesiredSize(self: Widget) struct { width: f32, height: f32 } {
        var width: f32 = 0;
        var height: f32 = 0;
        c.Rwidget_get_desired_size(@backingInt(self), &width, &height);
        return .{ .width = width, .height = height };
    }

    pub fn isHovered(self: Widget) bool {
        const result = c.Rwidget_is_hovered(@backingInt(self));
        return result != 0;
    }

    pub fn setFocusable(self: Widget, focusable: bool) void {
        c.Rwidget_set_focusable(@backingInt(self), @intFromBool(focusable));
    }

    /// Gives the keyboard focus to the widget, and scrolls it into view (Rwidget_scroll_into_view).
    pub fn focus(self: Widget) void {
        c.Rwidget_focus(@backingInt(self));
    }

    pub fn isFocused(self: Widget) bool {
        const result = c.Rwidget_is_focused(@backingInt(self));
        return result != 0;
    }

    pub fn setUserHandle(self: Widget, handle: ?*anyopaque) void {
        c.Rwidget_set_user_handle(@backingInt(self), handle);
    }

    pub fn getUserHandle(self: Widget) ?*anyopaque {
        const result = c.Rwidget_get_user_handle(@backingInt(self));
        return result;
    }

    pub fn setDestroyCallback(self: Widget, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)));
            }
        };
        c.Rwidget_set_destroy_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setEventCallback(self: Widget, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, Event) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*const c.REvent, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), Event.fromC(a1.?.*));
                return @intFromBool(handled);
            }
        };
        c.Rwidget_set_event_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Name of the action fired by the main event of the widget: button
    /// click, value change, text commit, item activation (see Raction_bind).
    pub fn setAction(self: Widget, action: [:0]const u8) void {
        c.Rwidget_set_action(@backingInt(self), action.ptr);
    }

    pub fn getAction(self: Widget) [:0]const u8 {
        const result = c.Rwidget_get_action(@backingInt(self));
        return rt.span(result);
    }

    /// Makes the widget a target for what is dragged from other
    /// applications: files from the file manager, text. It is highlighted
    /// while a drop on it would be accepted. NULL removes the callback.
    pub fn setDropCallback(self: Widget, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, DropEvent) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*const c.RDropEvent, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), DropEvent.fromC(a1.?.*));
                return @intFromBool(handled);
            }
        };
        c.Rwidget_set_drop_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// In a window created with R_WINDOW_CUSTOM_HEADER: dragging the
    /// widget moves the window and a double click maximizes it, as a title bar
    /// does. The buttons, fields and other controls inside it keep working.
    /// In XML: WindowDrag="true".
    pub fn setWindowDrag(self: Widget, enabled: bool) void {
        c.Rwidget_set_window_drag(@backingInt(self), @intFromBool(enabled));
    }

    /// Deepest widget of a subtree under a point of its window, or R_INVALID_ID.
    pub fn hitTest(self: Widget, x: f32, y: f32) ?Widget {
        const result = c.Rwidget_hit_test(@backingInt(self), x, y);
        return Widget.fromId(result);
    }

    /// Deepest visible widget of a subtree under a point of its window,
    /// whether it reacts to the pointer or not: a label, a panel, a disabled
    /// button. What a design tool selects with a click.
    pub fn pick(self: Widget, x: f32, y: f32) ?Widget {
        const result = c.Rwidget_pick(@backingInt(self), x, y);
        return Widget.fromId(result);
    }

    /// Menu opened by a right click on the widget. The widget does not own it.
    pub fn setContextMenu(self: Widget, menu: Widget) void {
        c.Rwidget_set_context_menu(@backingInt(self), @backingInt(menu));
    }

    /// Asks for the widget to be laid out and painted again.
    pub fn invalidate(self: Widget) void {
        c.Rwidget_invalidate(@backingInt(self));
    }

    /// Overrides a theme color for one widget. R_COLOR_TEXT is also
    /// inherited by its descendants.
    pub fn setColor(self: Widget, role: ColorRole, color: Color) void {
        c.Rwidget_set_color(@backingInt(self), @backingInt(role), color.r, color.g, color.b, color.a);
    }

    pub fn clearColor(self: Widget, role: ColorRole) void {
        c.Rwidget_clear_color(@backingInt(self), @backingInt(role));
    }

    /// The color the widget is drawn with for a role: its own, else
    /// the one of the styles of its theme that apply to it, else the one of
    /// its theme. What a custom widget should draw itself with.
    pub fn getColor(self: Widget, role: ColorRole) Color {
        var color_: Color = .{};
        c.Rwidget_get_color(@backingInt(self), @backingInt(role), &color_.r, &color_.g, &color_.b, &color_.a);
        return color_;
    }

    /// Gives one widget a material of its own, whatever the theme:
    /// a solid button in a glass window, a panel of clear glass in a flat one.
    /// A widget that draws no surface (a box, a label) gets one of this
    /// material behind it: any widget can become a panel of glass.
    /// In XML: Material="Glass | FrostedGlass | TintedGlass | Solid".
    /// material R_MATERIAL_DEFAULT follows the theme again.
    pub fn setMaterial(self: Widget, material: Material) void {
        c.Rwidget_set_material(@backingInt(self), @backingInt(material));
    }

    /// Returns: The material the widget is drawn with: its own, or the one of the theme.
    pub fn getMaterial(self: Widget) Material {
        const result = c.Rwidget_get_material(@backingInt(self));
        return @as(Material, @fromBackingInt(result));
    }

    /// Overrides a theme metric for one widget.
    pub fn setMetric(self: Widget, metric: Metric, value: f32) void {
        c.Rwidget_set_metric(@backingInt(self), @backingInt(metric), value);
    }

    pub fn clearMetric(self: Widget, metric: Metric) void {
        c.Rwidget_clear_metric(@backingInt(self), @backingInt(metric));
    }

    /// Returns: The metric the widget uses: its own, else the one of a style,
    /// else the one of its theme; grown for larger text
    /// (Raccessibility_set_text_scale) and for a finger (RTouchSettings::min_touch_size).
    pub fn getMetric(self: Widget, metric: Metric) f32 {
        const result = c.Rwidget_get_metric(@backingInt(self), @backingInt(metric));
        return result;
    }

    /// Classes of the widget, separated by spaces ("danger large"):
    /// the styles of the theme made for these classes apply to it
    /// (Rtheme_set_style_color, <Style Class="danger" .../> in a theme file).
    /// In XML: Class="...". NULL or "" removes them.
    pub fn setClass(self: Widget, classes: ?[:0]const u8) void {
        c.Rwidget_set_class(@backingInt(self), rt.optPtr(classes));
    }

    /// Returns: The classes, "" when it has none. Valid until they change.
    pub fn getClass(self: Widget) [:0]const u8 {
        const result = c.Rwidget_get_class(@backingInt(self));
        return rt.span(result);
    }

    pub fn addClass(self: Widget, style_class: [:0]const u8) void {
        c.Rwidget_add_class(@backingInt(self), style_class.ptr);
    }

    pub fn removeClass(self: Widget, style_class: [:0]const u8) void {
        c.Rwidget_remove_class(@backingInt(self), style_class.ptr);
    }

    pub fn hasClass(self: Widget, style_class: [:0]const u8) bool {
        const result = c.Rwidget_has_class(@backingInt(self), style_class.ptr);
        return result != 0;
    }

    /// Gives the widget and everything inside it a theme of their own,
    /// by name ("Dark", "GlassLight", or a theme of Rtheme_load): a dark side
    /// bar in a light window, a preview of another theme. Menus and lists
    /// opened from inside follow. In XML: Theme="...".
    /// name NULL or "" follows the parent (the application theme) again.
    /// Returns: R_FALSE, after reporting an error, when no theme has that name.
    pub fn setTheme(self: Widget, name: ?[:0]const u8) Error!void {
        if (c.Rwidget_set_theme(@backingInt(self), rt.optPtr(name)) == 0) return lastError();
    }

    /// Returns: Name of the theme the widget is drawn with.
    pub fn getTheme(self: Widget) [:0]const u8 {
        const result = c.Rwidget_get_theme(@backingInt(self));
        return rt.span(result);
    }

    /// Gives the widget and everything inside it a font, for the texts
    /// that have none of their own (a label given Rlabel_set_font keeps its
    /// own): a tool whose panels wear one font while the interface it shows
    /// keeps the font of the application. Menus and lists opened from inside
    /// follow.
    /// font R_INVALID_ID: the font of the parent (in the end, the one of the theme, Rtheme_set_font) again.
    pub fn setFont(self: Widget, font: ?Font) void {
        c.Rwidget_set_font(@backingInt(self), optId(font));
    }

    /// Returns: The font given to the widget itself, or R_INVALID_ID.
    pub fn getFont(self: Widget) ?Font {
        const result = c.Rwidget_get_font(@backingInt(self));
        return Font.fromId(result);
    }

    /// Scrolls every ScrollBox above the widget so that the widget is
    /// visible. The library does it by itself for the focused widget when the
    /// focus comes from Tab or Rwidget_focus, and for a text field above the
    /// on-screen keyboard (Rwindow_get_keyboard_area).
    pub fn scrollIntoView(self: Widget) void {
        c.Rwidget_scroll_into_view(@backingInt(self));
    }

    /// Direction of a part of a window: R_DIRECTION_INHERIT, _LTR or _RTL.
    pub fn setDirection(self: Widget, direction: Direction) void {
        c.Rwidget_set_direction(@backingInt(self), @backingInt(direction));
    }

    /// The direction the widget is laid out in: R_DIRECTION_LTR or _RTL.
    pub fn getDirection(self: Widget) Direction {
        const result = c.Rwidget_get_direction(@backingInt(self));
        return @as(Direction, @fromBackingInt(result));
    }

    /// Creates a widget tree from a document whose root element is a
    /// widget. The caller owns the returned widget until it is added to a parent.
    pub fn createFromXml(xml: []const u8) Error!Widget {
        const result = c.Rwidget_create_from_xml(@ptrCast(xml.ptr), xml.len);
        return Widget.fromId(result) orelse lastError();
    }

    pub fn createFromXmlFile(path: [:0]const u8) Error!Widget {
        const result = c.Rwidget_create_from_xml_file(path.ptr);
        return Widget.fromId(result) orelse lastError();
    }

    /// Sets a property from text, with the names and value syntax of the
    /// XML attributes. Handy for scripting and data-driven tools.
    /// Returns: R_TRUE when the attribute exists for this widget and the value is valid.
    pub fn setAttribute(self: Widget, name: [:0]const u8, value: [:0]const u8) bool {
        const result = c.Rwidget_set_attribute(@backingInt(self), name.ptr, value.ptr);
        return result != 0;
    }

    /// Returns: The node a widget was built from, or R_INVALID_ID: not built
    /// from a document, or the document is gone. The widgets inside a tag
    /// declared with <Widget> all come from the node where the tag is used.
    pub fn getXmlNode(self: Widget) ?XmlNode {
        const result = c.Rwidget_get_xml_node(@backingInt(self));
        return XmlNode.fromId(result);
    }

    /// Makes a widget show a key: an attribute ("Text", "Tooltip",
    /// "Title", "Placeholder"... any attribute that takes a text) is set to the
    /// translation now and every time the language changes. NULL or "" stops it.
    /// Same as Rwidget_set_attribute(widget, attribute, "@key").
    pub fn setTextKey(self: Widget, attribute: ?[:0]const u8, key: ?[:0]const u8) void {
        c.Rwidget_set_text_key(@backingInt(self), rt.optPtr(attribute), rt.optPtr(key));
    }

    /// What the screen reader says of the widget; NULL: what it shows (or the label before it).
    pub fn setAccessibleName(self: Widget, name: ?[:0]const u8) void {
        c.Rwidget_set_accessible_name(@backingInt(self), rt.optPtr(name));
    }

    /// The name the screen reader uses (given, or found). Valid until the next call.
    pub fn getAccessibleName(self: Widget) [:0]const u8 {
        const result = c.Rwidget_get_accessible_name(@backingInt(self));
        return rt.span(result);
    }

    /// A longer explanation, read after the name.
    pub fn setAccessibleDescription(self: Widget, description: [:0]const u8) void {
        c.Rwidget_set_accessible_description(@backingInt(self), description.ptr);
    }

    pub fn setAccessibleRole(self: Widget, role: AccessibleRole) void {
        c.Rwidget_set_accessible_role(@backingInt(self), @backingInt(role));
    }

    /// The role the screen reader sees (given, or the one of the type).
    pub fn getAccessibleRole(self: Widget) AccessibleRole {
        const result = c.Rwidget_get_accessible_role(@backingInt(self));
        return @as(AccessibleRole, @fromBackingInt(result));
    }

    /// R_TRUE: hidden from screen readers, with what it contains (decoration).
    pub fn setAccessibleHidden(self: Widget, hidden: i32) void {
        c.Rwidget_set_accessible_hidden(@backingInt(self), hidden);
    }

    /// The widget is named by another one (a label): its text is the name.
    pub fn setAccessibleLabelledBy(self: Widget, label: Widget) void {
        c.Rwidget_set_accessible_labelled_by(@backingInt(self), @backingInt(label));
    }

    /// Explicit screen-reader press action, including for custom widgets.
    /// NULL removes the override. Does not change pointer or keyboard handling.
    /// Disabled widgets (including disabled ancestors) cannot be pressed.
    pub fn setAccessibleAction(self: Widget, context: anytype, comptime press: ?fn (@TypeOf(context), Widget) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                press.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)));
            }
        };
        c.Rwidget_set_accessible_action(@backingInt(self), if (press != null) &Trampoline.call else null, if (press != null) rt.contextToC(context) else null);
    }

    /// Override the checked state: 1 checked, 0 unchecked, -1 restores the
    /// widget's default (not checkable for a custom widget). The application owns
    /// this state; a press callback updates it when appropriate.
    pub fn setAccessibleChecked(self: Widget, checked: bool) void {
        c.Rwidget_set_accessible_checked(@backingInt(self), @intFromBool(checked));
    }

    /// Space kept around the child, inside its slot. All panels.
    pub fn slotSetPadding(self: Widget, left: f32, top: f32, right: f32, bottom: f32) void {
        c.Rslot_set_padding(@backingInt(self), left, top, right, bottom);
    }

    /// Alignment of the child inside its slot. Default: fill. All panels.
    pub fn slotSetHalign(self: Widget, align_: HAlign) void {
        c.Rslot_set_halign(@backingInt(self), @backingInt(align_));
    }

    pub fn slotSetValign(self: Widget, align_: VAlign) void {
        c.Rslot_set_valign(@backingInt(self), @backingInt(align_));
    }

    /// The slot takes the desired size of the child along the panel
    /// direction (Slate AutoWidth / AutoHeight). This is the default.
    /// VBox, HBox.
    pub fn slotSetAuto(self: Widget) void {
        c.Rslot_set_auto(@backingInt(self));
    }

    /// The slot shares the space left by the auto slots, in proportion
    /// to `coefficient` (Slate FillWidth / FillHeight). VBox, HBox.
    /// In a Splitter, the coefficient is the relative size of the pane.
    pub fn slotSetFill(self: Widget, coefficient: f32) void {
        c.Rslot_set_fill(@backingInt(self), coefficient);
    }

    /// Upper bound of the slot along the panel direction. 0 = none. VBox, HBox.
    pub fn slotSetMaxSize(self: Widget, max_size: f32) void {
        c.Rslot_set_max_size(@backingInt(self), max_size);
    }

    /// Cell of the child. Grid, UniformGrid.
    pub fn slotSetGrid(self: Widget, column: i32, row: i32) void {
        c.Rslot_set_grid(@backingInt(self), column, row);
    }

    pub fn slotSetGridSpan(self: Widget, column_span: i32, row_span: i32) void {
        c.Rslot_set_grid_span(@backingInt(self), column_span, row_span);
    }

    /// Canvas placement. Anchors are fractions of the canvas size (0..1).
    ///   - anchors equal on an axis: the child is at anchor + position, with
    ///     the slot size (or its desired size when the slot size is <= 0);
    ///   - anchors different on an axis: the child stretches between them,
    ///     position and size are then the near and far margins.
    /// Alignment is the pivot of the child (0,0 = top-left, 0.5,0.5 = center).
    pub fn slotSetAnchors(self: Widget, min_x: f32, min_y: f32, max_x: f32, max_y: f32) void {
        c.Rslot_set_anchors(@backingInt(self), min_x, min_y, max_x, max_y);
    }

    pub fn slotSetPosition(self: Widget, x: f32, y: f32) void {
        c.Rslot_set_position(@backingInt(self), x, y);
    }

    pub fn slotSetSize(self: Widget, width: f32, height: f32) void {
        c.Rslot_set_size(@backingInt(self), width, height);
    }

    pub fn slotSetAlignment(self: Widget, x: f32, y: f32) void {
        c.Rslot_set_alignment(@backingInt(self), x, y);
    }

    /// Title of the tab showing the child. TabView.
    pub fn slotSetTitle(self: Widget, title: [:0]const u8) void {
        c.Rslot_set_title(@backingInt(self), title.ptr);
    }
};

/// A widget (WidgetType.label).
pub const Label = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Label {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Label) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Label.
    pub const widget_types = [_]WidgetType{.label};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Label) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// Shortcut for Rwidget_create(R_WIDGET_LABEL) + Rlabel_set_text.
    pub fn create(text: [:0]const u8) Label {
        const result = c.Rlabel_create(text.ptr);
        return @fromBackingInt(result);
    }

    /// Sets the text. '\n' starts a new line.
    pub fn setText(self: Label, text: [:0]const u8) void {
        c.Rlabel_set_text(@backingInt(self), text.ptr);
    }

    pub fn getText(self: Label) [:0]const u8 {
        const result = c.Rlabel_get_text(@backingInt(self));
        return rt.span(result);
    }

    /// R_INVALID_ID uses the theme font.
    pub fn setFont(self: Label, font: ?Font) void {
        c.Rlabel_set_font(@backingInt(self), optId(font));
    }

    /// Font size in logical units. 0 uses R_METRIC_FONT_SIZE.
    pub fn setTextSize(self: Label, size: f32) void {
        c.Rlabel_set_text_size(@backingInt(self), size);
    }

    pub fn setTextAlign(self: Label, align_: TextAlign) void {
        c.Rlabel_set_text_align(@backingInt(self), @backingInt(align_));
    }

    /// R_TRUE wraps the text on the width given by the parent.
    pub fn setWrap(self: Label, wrap: bool) void {
        c.Rlabel_set_wrap(@backingInt(self), @intFromBool(wrap));
    }

    /// Text color (R_COLOR_TEXT of this widget).
    pub fn setColor(self: Label, color: Color) void {
        c.Rlabel_set_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// R_TRUE reads the text as Markdown and shows it formatted
    /// (Markdown="true" in XML):
    ///
    ///   # titles, **strong**, *emphasis*, `code`, ~~struck~~, [links](url),
    ///   lists and lists in lists, - [x] task lists, > quotes, --- rules,
    ///   | tables |, images alone on their line, and ``` blocks of code with
    ///   the colors of their language (```c, ```python...: the languages of
    ///   the text editor, raven_text_editor.h).
    ///
    /// The text wraps on the width of the label unless Rlabel_set_wrap said
    /// otherwise; put the label in a scroll box for a long document. Strong
    /// and emphasized text use the bold and italic of the font
    /// (Rfont_set_variant), which Raven derives from the font itself when it
    /// was given none. The colors come from the theme: R_COLOR_LINK,
    /// R_COLOR_CODE, R_COLOR_SEPARATOR, R_COLOR_ACCENT.
    pub fn setMarkdown(self: Label, enabled: bool) void {
        c.Rlabel_set_markdown(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getMarkdown(self: Label) i32 {
        const result = c.Rlabel_get_markdown(@backingInt(self));
        return result;
    }

    pub fn setLinkCallback(self: Label, context: anytype, comptime callback: ?fn (@TypeOf(context), Label, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Label, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rlabel_set_link_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The text of a Markdown label without its marks, as a reader sees it. Valid until the next call.
    pub fn getPlainText(self: Label) [:0]const u8 {
        const result = c.Rlabel_get_plain_text(@backingInt(self));
        return rt.span(result);
    }

    /// R_TRUE lets the user select the text of the label with the
    /// mouse, as on a web page (Selectable="true" in XML): drag to select, a
    /// double click selects a word, a triple click a paragraph, Shift + click
    /// extends the selection; then Ctrl+C (Cmd+C) copies it and Ctrl+A selects
    /// everything. A click elsewhere takes the selection away. Plain and
    /// Markdown labels alike: a copy of a Markdown label is its text without
    /// the marks, and its links are still clicked, not selected. The label
    /// takes the mouse (what holds it no longer receives the clicks on it) and
    /// the keyboard after a click; Tab passes it by. Default R_FALSE.
    pub fn setSelectable(self: Label, selectable: bool) void {
        c.Rlabel_set_selectable(@backingInt(self), @intFromBool(selectable));
    }

    pub fn getSelectable(self: Label) bool {
        const result = c.Rlabel_get_selectable(@backingInt(self));
        return result != 0;
    }

    /// The text selected, as Ctrl+C copies it ("" when nothing is). Valid until the next call.
    pub fn getSelectedText(self: Label) [:0]const u8 {
        const result = c.Rlabel_get_selected_text(@backingInt(self));
        return rt.span(result);
    }

    /// Selects the whole text of a selectable label.
    pub fn selectAll(self: Label) void {
        c.Rlabel_select_all(@backingInt(self));
    }

    pub fn clearSelection(self: Label) void {
        c.Rlabel_clear_selection(@backingInt(self));
    }
};

/// A widget (WidgetType.button).
pub const Button = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Button {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Button) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Button.
    pub const widget_types = [_]WidgetType{.button};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Button) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// Shortcut for Rwidget_create(R_WIDGET_BUTTON) + Rbutton_set_text.
    pub fn create(text: [:0]const u8) Button {
        const result = c.Rbutton_create(text.ptr);
        return @fromBackingInt(result);
    }

    /// Sets the content of the button to a label. A button can instead
    /// hold any single child widget (Rwidget_add_child), e.g. an HBox with an icon.
    pub fn setText(self: Button, text: [:0]const u8) void {
        c.Rbutton_set_text(@backingInt(self), text.ptr);
    }

    pub fn setStyle(self: Button, style: ButtonStyle) void {
        c.Rbutton_set_style(@backingInt(self), @backingInt(style));
    }

    pub fn setClickedCallback(self: Button, context: anytype, comptime callback: ?fn (@TypeOf(context), Button) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Button, @fromBackingInt(a0)));
            }
        };
        c.Rbutton_set_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.checkbox).
pub const Checkbox = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Checkbox {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Checkbox) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Checkbox.
    pub const widget_types = [_]WidgetType{.checkbox};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Checkbox) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create(text: [:0]const u8) Checkbox {
        const result = c.Rcheckbox_create(text.ptr);
        return @fromBackingInt(result);
    }

    pub fn setText(self: Checkbox, text: [:0]const u8) void {
        c.Rcheckbox_set_text(@backingInt(self), text.ptr);
    }

    pub fn getText(self: Checkbox) [:0]const u8 {
        const result = c.Rcheckbox_get_text(@backingInt(self));
        return rt.span(result);
    }

    pub fn setChecked(self: Checkbox, checked: bool) void {
        c.Rcheckbox_set_checked(@backingInt(self), @intFromBool(checked));
    }

    pub fn isChecked(self: Checkbox) bool {
        const result = c.Rcheckbox_is_checked(@backingInt(self));
        return result != 0;
    }

    pub fn setStyle(self: Checkbox, style: CheckboxStyle) void {
        c.Rcheckbox_set_style(@backingInt(self), @backingInt(style));
    }

    pub fn setChangedCallback(self: Checkbox, context: anytype, comptime callback: ?fn (@TypeOf(context), Checkbox, bool) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Checkbox, @fromBackingInt(a0)), a1 != 0);
            }
        };
        c.Rcheckbox_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.slider).
pub const Slider = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Slider {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Slider) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Slider.
    pub const widget_types = [_]WidgetType{.slider};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Slider) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Slider (Rwidget_create(R_WIDGET_SLIDER)).
    pub fn create() Slider {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SLIDER));
    }

    pub fn setRange(self: Slider, minimum: f32, maximum: f32) void {
        c.Rslider_set_range(@backingInt(self), minimum, maximum);
    }

    pub fn setValue(self: Slider, value: f32) void {
        c.Rslider_set_value(@backingInt(self), value);
    }

    pub fn getValue(self: Slider) f32 {
        const result = c.Rslider_get_value(@backingInt(self));
        return result;
    }

    /// The range given with Rslider_set_range and the step (NULL for what is not wanted).
    pub fn getRange(self: Slider) struct { minimum: f32, maximum: f32, step: f32 } {
        var minimum: f32 = 0;
        var maximum: f32 = 0;
        var step: f32 = 0;
        c.Rslider_get_range(@backingInt(self), &minimum, &maximum, &step);
        return .{ .minimum = minimum, .maximum = maximum, .step = step };
    }

    /// Snaps the value to multiples of `step`. 0 = continuous (default).
    pub fn setStep(self: Slider, step: f32) void {
        c.Rslider_set_step(@backingInt(self), step);
    }

    pub fn setOrientation(self: Slider, orientation: Orientation) void {
        c.Rslider_set_orientation(@backingInt(self), @backingInt(orientation));
    }

    pub fn setChangedCallback(self: Slider, context: anytype, comptime callback: ?fn (@TypeOf(context), Slider, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Slider, @fromBackingInt(a0)), a1);
            }
        };
        c.Rslider_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.progressbar).
pub const ProgressBar = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?ProgressBar {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: ProgressBar) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a ProgressBar.
    pub const widget_types = [_]WidgetType{.progressbar};

    /// The widget, for the functions of every widget.
    pub fn widget(self: ProgressBar) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new ProgressBar (Rwidget_create(R_WIDGET_PROGRESSBAR)).
    pub fn create() ProgressBar {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_PROGRESSBAR));
    }

    /// Progress between 0 and 1.
    pub fn setValue(self: ProgressBar, value: f32) void {
        c.Rprogress_bar_set_value(@backingInt(self), value);
    }

    pub fn getValue(self: ProgressBar) f32 {
        const result = c.Rprogress_bar_get_value(@backingInt(self));
        return result;
    }
};

/// A widget (WidgetType.image).
pub const Image = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Image {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Image) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Image.
    pub const widget_types = [_]WidgetType{.image};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Image) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Image (Rwidget_create(R_WIDGET_IMAGE)).
    pub fn create() Image {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_IMAGE));
    }

    /// Reads what an image file in memory holds without keeping its
    /// pixels: its size, its frames (1 for a still image, more for an animated
    /// GIF or APNG) and how many times it plays (0: forever). Thread-safe.
    /// Each pointer may be NULL.
    /// Returns: R_FALSE when the data is not an image Raven can read.
    pub fn decodeInfo(data: []const u8) ?struct { width: i32, height: i32, frame_count: i32, loop_count: i32 } {
        var width: c_int = 0;
        var height: c_int = 0;
        var frame_count: c_int = 0;
        var loop_count: c_int = 0;
        if (c.Rimage_decode_info(@ptrCast(data.ptr), data.len, &width, &height, &frame_count, &loop_count) == 0) return null;
        return .{ .width = width, .height = height, .frame_count = frame_count, .loop_count = loop_count };
    }

    /// Decodes one frame of an animated GIF or APNG into tightly packed
    /// RGBA8 pixels, composed as it is shown (the frames before it drawn and
    /// disposed of). Frame 0 of a still image is the image. Thread-safe.
    /// delay Receives the seconds the frame is shown (0 for a still image); may be NULL.
    /// Returns: The pixels, to release with Rpixels_free; NULL when the frame does not exist.
    pub fn decodeFrame(allocator: std.mem.Allocator, data: []const u8, frame: i32) std.mem.Allocator.Error!?struct { pixels: Pixels, delay: f64 } {
        var width: c_int = 0;
        var height: c_int = 0;
        var delay: f64 = 0;
        const result = c.Rimage_decode_frame(@ptrCast(data.ptr), data.len, frame, &width, &height, &delay) orelse return null;
        defer c.Rpixels_free(result);
        const pixel_bytes = @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4;
        return .{ .pixels = .{ .pixels = try allocator.dupe(u8, result[0..pixel_bytes]), .width = width, .height = height }, .delay = delay };
    }

    /// Encodes tightly packed RGBA8 pixels (what Rwindow_capture
    /// returns) as a PNG file in memory. Thread-safe.
    /// size Receives the number of bytes.
    /// Returns: The bytes of the file, to release with Rpixels_free; NULL when
    /// there are no pixels.
    pub fn encodePng(allocator: std.mem.Allocator, rgba: []const u8, width: i32, height: i32) std.mem.Allocator.Error!?[]u8 {
        std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
        var size: usize = 0;
        const result = c.Rimage_encode_png(rgba.ptr, width, height, &size) orelse return null;
        defer c.Rpixels_free(result);
        return try allocator.dupe(u8, @as([*]const u8, @ptrCast(result))[0..size]);
    }

    /// Writes tightly packed RGBA8 pixels to a PNG file: a screenshot
    /// of Rwindow_capture, a picture made by the application. Thread-safe.
    /// Returns: R_FALSE when the file cannot be written.
    pub fn savePng(path: [:0]const u8, rgba: []const u8, width: i32, height: i32) bool {
        std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
        const result = c.Rimage_save_png(path.ptr, rgba.ptr, width, height);
        return result != 0;
    }

    pub fn setTexture(self: Image, texture: Texture) void {
        c.Rimage_set_texture(@backingInt(self), @backingInt(texture));
    }

    /// Color the image is multiplied by (white by default). An SVG in
    /// currentColor (Ricon_get, Rtexture_create_from_svg) is drawn in the color of
    /// the text around it until a tint is given; then in the tint. XML: Tint.
    pub fn setTintColor(self: Image, color: Color) void {
        c.Rimage_set_tint_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// R_TRUE: the image is tinted with the text color around it (white icons that follow the theme). XML: TintText.
    pub fn setTintText(self: Image, enabled: bool) void {
        c.Rimage_set_tint_text(@backingInt(self), @intFromBool(enabled));
    }

    pub fn setStretch(self: Image, stretch: Stretch) void {
        c.Rimage_set_stretch(@backingInt(self), @backingInt(stretch));
    }

    /// Part of the texture to show, in UV coordinates. Default: 0, 0, 1, 1.
    pub fn setRegion(self: Image, min_u: f32, min_v: f32, max_u: f32, max_v: f32) void {
        c.Rimage_set_region(@backingInt(self), min_u, min_v, max_u, max_v);
    }

    pub fn setCornerRadius(self: Image, radius: f32) void {
        c.Rimage_set_corner_radius(@backingInt(self), radius);
    }

    /// R_TRUE when the texture of the image is an animated GIF or APNG (two frames or more).
    pub fn isAnimated(self: Image) bool {
        const result = c.Rimage_is_animated(@backingInt(self));
        return result != 0;
    }

    /// Returns: The frames of its animation; 1 for a still image, 0 without a texture.
    pub fn getFrameCount(self: Image) i32 {
        const result = c.Rimage_get_frame_count(@backingInt(self));
        return result;
    }

    /// Returns: The seconds one play of its animation lasts (0 for a still image).
    pub fn getDuration(self: Image) f64 {
        const result = c.Rimage_get_duration(@backingInt(self));
        return result;
    }

    /// Returns: The seconds a frame of its animation is shown (0 for a frame that does not exist).
    pub fn getFrameDelay(self: Image, frame: i32) f64 {
        const result = c.Rimage_get_frame_delay(@backingInt(self), frame);
        return result;
    }

    /// Plays the animation from the frame it is on (from the first
    /// again when it had finished). An Image plays as soon as it is given an
    /// animated texture, unless XML says Animate="false".
    pub fn play(self: Image) void {
        c.Rimage_play(@backingInt(self));
    }

    /// Stops the animation on the frame it is on.
    pub fn pause(self: Image) void {
        c.Rimage_pause(@backingInt(self));
    }

    /// Stops the animation and shows its first frame.
    pub fn stop(self: Image) void {
        c.Rimage_stop(@backingInt(self));
    }

    pub fn isPlaying(self: Image) bool {
        const result = c.Rimage_is_playing(@backingInt(self));
        return result != 0;
    }

    /// Shows a frame (from 0), playing on from it if it plays.
    pub fn setFrame(self: Image, frame: i32) void {
        c.Rimage_set_frame(@backingInt(self), frame);
    }

    pub fn getFrame(self: Image) i32 {
        const result = c.Rimage_get_frame(@backingInt(self));
        return result;
    }

    /// How many times the animation plays before it stops on its last
    /// frame: 0 forever, -1 what the file says (the default). XML: Loop
    /// (a number; also Forever, Once).
    pub fn setLoopCount(self: Image, count: i32) void {
        c.Rimage_set_loop_count(@backingInt(self), count);
    }

    /// Returns: The plays of the animation (0: forever), the file's unless it was set.
    pub fn getLoopCount(self: Image) i32 {
        const result = c.Rimage_get_loop_count(@backingInt(self));
        return result;
    }

    pub fn setFinishedCallback(self: Image, context: anytype, comptime callback: ?fn (@TypeOf(context), Image) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Image, @fromBackingInt(a0)));
            }
        };
        c.Rimage_set_finished_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.text_input).
pub const TextInput = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?TextInput {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: TextInput) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a TextInput.
    pub const widget_types = [_]WidgetType{.text_input};

    /// The widget, for the functions of every widget.
    pub fn widget(self: TextInput) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new TextInput (Rwidget_create(R_WIDGET_TEXT_INPUT)).
    pub fn create() TextInput {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_TEXT_INPUT));
    }

    pub fn setText(self: TextInput, text: [:0]const u8) void {
        c.Rtext_input_set_text(@backingInt(self), text.ptr);
    }

    pub fn getText(self: TextInput) [:0]const u8 {
        const result = c.Rtext_input_get_text(@backingInt(self));
        return rt.span(result);
    }

    /// Dimmed text shown while the input is empty.
    pub fn setPlaceholder(self: TextInput, text: [:0]const u8) void {
        c.Rtext_input_set_placeholder(@backingInt(self), text.ptr);
    }

    pub fn setPassword(self: TextInput, password: bool) void {
        c.Rtext_input_set_password(@backingInt(self), @intFromBool(password));
    }

    pub fn isPassword(self: TextInput) bool {
        const result = c.Rtext_input_is_password(@backingInt(self));
        return result != 0;
    }

    pub fn isReadOnly(self: TextInput) bool {
        const result = c.Rtext_input_is_read_only(@backingInt(self));
        return result != 0;
    }

    pub fn setReadOnly(self: TextInput, read_only: bool) void {
        c.Rtext_input_set_read_only(@backingInt(self), @intFromBool(read_only));
    }

    /// Maximum number of characters. 0 = no limit (default).
    pub fn setMaxLength(self: TextInput, max_length: i32) void {
        c.Rtext_input_set_max_length(@backingInt(self), max_length);
    }

    pub fn selectAll(self: TextInput) void {
        c.Rtext_input_select_all(@backingInt(self));
    }

    /// What it holds: picks the on-screen keyboard on mobile. Default: R_TEXT_INPUT_TYPE_TEXT.
    pub fn setInputType(self: TextInput, type_: TextInputType) void {
        c.Rtext_input_set_input_type(@backingInt(self), @backingInt(type_));
    }

    pub fn getInputType(self: TextInput) TextInputType {
        const result = c.Rtext_input_get_input_type(@backingInt(self));
        return @as(TextInputType, @fromBackingInt(result));
    }

    /// The return key of the on-screen keyboard (Done, Next, Search...). Default: R_RETURN_KEY_DEFAULT.
    pub fn setReturnKey(self: TextInput, key: ReturnKey) void {
        c.Rtext_input_set_return_key(@backingInt(self), @backingInt(key));
    }

    pub fn getReturnKey(self: TextInput) ReturnKey {
        const result = c.Rtext_input_get_return_key(@backingInt(self));
        return @as(ReturnKey, @fromBackingInt(result));
    }

    /// Called on every edit.
    pub fn setChangedCallback(self: TextInput, context: anytype, comptime callback: ?fn (@TypeOf(context), TextInput, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TextInput, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rtext_input_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when Enter is pressed. This also fires the action of the widget.
    pub fn setCommittedCallback(self: TextInput, context: anytype, comptime callback: ?fn (@TypeOf(context), TextInput, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TextInput, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rtext_input_set_committed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Underlines the misspelled words with a wavy line (R_COLOR_SPELLING);
    /// a right click on one offers corrections (see SPELL CHECKING). Off by
    /// default. A password is never checked.
    pub fn setSpellCheck(self: TextInput, enabled: bool) void {
        c.Rtext_input_set_spell_check(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getSpellCheck(self: TextInput) i32 {
        const result = c.Rtext_input_get_spell_check(@backingInt(self));
        return result;
    }

    /// Language of the spell checking ("en_US", "fr"...). NULL: the default (Rspell_set_language).
    pub fn setSpellLanguage(self: TextInput, language: ?[:0]const u8) void {
        c.Rtext_input_set_spell_language(@backingInt(self), rt.optPtr(language));
    }
};

/// A widget (WidgetType.spin_box).
pub const SpinBox = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?SpinBox {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: SpinBox) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a SpinBox.
    pub const widget_types = [_]WidgetType{.spin_box};

    /// The widget, for the functions of every widget.
    pub fn widget(self: SpinBox) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new SpinBox (Rwidget_create(R_WIDGET_SPIN_BOX)).
    pub fn create() SpinBox {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SPIN_BOX));
    }

    pub fn setRange(self: SpinBox, minimum: f64, maximum: f64) void {
        c.Rspin_box_set_range(@backingInt(self), minimum, maximum);
    }

    pub fn setValue(self: SpinBox, value: f64) void {
        c.Rspin_box_set_value(@backingInt(self), value);
    }

    pub fn getValue(self: SpinBox) f64 {
        const result = c.Rspin_box_get_value(@backingInt(self));
        return result;
    }

    /// The range and the step (NULL for what is not wanted).
    pub fn getRange(self: SpinBox) struct { minimum: f64, maximum: f64, step: f64 } {
        var minimum: f64 = 0;
        var maximum: f64 = 0;
        var step: f64 = 0;
        c.Rspin_box_get_range(@backingInt(self), &minimum, &maximum, &step);
        return .{ .minimum = minimum, .maximum = maximum, .step = step };
    }

    pub fn setStep(self: SpinBox, step: f64) void {
        c.Rspin_box_set_step(@backingInt(self), step);
    }

    /// Digits shown after the decimal point. Default: 2.
    pub fn setDecimals(self: SpinBox, decimals: i32) void {
        c.Rspin_box_set_decimals(@backingInt(self), decimals);
    }

    /// Step buttons in the looks of Raven too: a down button at the left
    /// end and an up button at the right end, the value between them (XML
    /// `Buttons="True"`). A click steps once; holding a button repeats its step.
    /// The platform looks (Windows, GNOME, macOS) always draw their own buttons.
    /// Default: R_FALSE (drag to scrub, arrows / wheel to step).
    pub fn setButtons(self: SpinBox, buttons: i32) void {
        c.Rspin_box_set_buttons(@backingInt(self), buttons);
    }

    pub fn getButtons(self: SpinBox) i32 {
        const result = c.Rspin_box_get_buttons(@backingInt(self));
        return result;
    }

    pub fn setChangedCallback(self: SpinBox, context: anytype, comptime callback: ?fn (@TypeOf(context), SpinBox, f64) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: f64, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(SpinBox, @fromBackingInt(a0)), a1);
            }
        };
        c.Rspin_box_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.combo_box).
pub const ComboBox = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?ComboBox {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: ComboBox) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a ComboBox.
    pub const widget_types = [_]WidgetType{.combo_box};

    /// The widget, for the functions of every widget.
    pub fn widget(self: ComboBox) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new ComboBox (Rwidget_create(R_WIDGET_COMBO_BOX)).
    pub fn create() ComboBox {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_COMBO_BOX));
    }

    /// Returns: The index of the new item.
    pub fn addItem(self: ComboBox, text: [:0]const u8) i32 {
        const result = c.Rcombo_box_add_item(@backingInt(self), text.ptr);
        return result;
    }

    pub fn clearItems(self: ComboBox) void {
        c.Rcombo_box_clear_items(@backingInt(self));
    }

    pub fn getItemCount(self: ComboBox) i32 {
        const result = c.Rcombo_box_get_item_count(@backingInt(self));
        return result;
    }

    pub fn getItemText(self: ComboBox, index: i32) [:0]const u8 {
        const result = c.Rcombo_box_get_item_text(@backingInt(self), index);
        return rt.span(result);
    }

    /// Selects an item. -1 selects nothing.
    pub fn setSelected(self: ComboBox, index: i32) void {
        c.Rcombo_box_set_selected(@backingInt(self), index);
    }

    pub fn getSelected(self: ComboBox) i32 {
        const result = c.Rcombo_box_get_selected(@backingInt(self));
        return result;
    }

    pub fn setChangedCallback(self: ComboBox, context: anytype, comptime callback: ?fn (@TypeOf(context), ComboBox, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(ComboBox, @fromBackingInt(a0)), a1);
            }
        };
        c.Rcombo_box_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// R_TRUE: the combo box is a text field with its list: the user
    /// may type a text that is not one of the items (Editable="true"). The text
    /// is Rcombo_box_get_text; choosing an item puts its text there. A typed
    /// text equal to an item selects it, any other selects nothing (-1).
    pub fn setEditable(self: ComboBox, editable: i32) void {
        c.Rcombo_box_set_editable(@backingInt(self), editable);
    }

    pub fn isEditable(self: ComboBox) bool {
        const result = c.Rcombo_box_is_editable(@backingInt(self));
        return result != 0;
    }

    /// R_TRUE: typing in the combo box filters its list (Searchable="true"):
    /// the items that contain what was typed, without regard to case or
    /// accents ("zoe" finds "Zoë", "sao" finds "São Paulo"), or a row saying that nothing
    /// matches. Up and Down move in the list, Enter chooses, Escape closes it.
    /// A searchable combo box that is not editable comes back to the item
    /// chosen when nothing is.
    pub fn setSearchable(self: ComboBox, searchable: i32) void {
        c.Rcombo_box_set_searchable(@backingInt(self), searchable);
    }

    pub fn isSearchable(self: ComboBox) bool {
        const result = c.Rcombo_box_is_searchable(@backingInt(self));
        return result != 0;
    }

    /// The text shown: what was typed in an editable combo box, else the text of the selected item ("" for none).
    pub fn getText(self: ComboBox) [:0]const u8 {
        const result = c.Rcombo_box_get_text(@backingInt(self));
        return rt.span(result);
    }

    /// Editable combo box: sets the text of the field (the item equal to it is selected); otherwise selects the item with this text.
    pub fn setText(self: ComboBox, text: [:0]const u8) void {
        c.Rcombo_box_set_text(@backingInt(self), text.ptr);
    }

    pub fn setTextChangedCallback(self: ComboBox, context: anytype, comptime callback: ?fn (@TypeOf(context), ComboBox, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(ComboBox, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rcombo_box_set_text_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Opens (R_TRUE) or closes the list.
    pub fn setOpen(self: ComboBox, open: i32) void {
        c.Rcombo_box_set_open(@backingInt(self), open);
    }

    pub fn isOpen(self: ComboBox) bool {
        const result = c.Rcombo_box_is_open(@backingInt(self));
        return result != 0;
    }
};

/// A widget (WidgetType.separator).
pub const Separator = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Separator {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Separator) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Separator.
    pub const widget_types = [_]WidgetType{.separator};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Separator) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Separator (Rwidget_create(R_WIDGET_SEPARATOR)).
    pub fn create() Separator {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SEPARATOR));
    }

    /// R_HORIZONTAL draws a horizontal line (default).
    pub fn setOrientation(self: Separator, orientation: Orientation) void {
        c.Rseparator_set_orientation(@backingInt(self), @backingInt(orientation));
    }
};

/// A widget (WidgetType.list_view).
pub const ListView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?ListView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: ListView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a ListView.
    pub const widget_types = [_]WidgetType{.list_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: ListView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new ListView (Rwidget_create(R_WIDGET_LIST_VIEW)).
    pub fn create() ListView {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_LIST_VIEW));
    }

    /// Returns: The index of the new item.
    pub fn addItem(self: ListView, text: [:0]const u8) i32 {
        const result = c.Rlist_view_add_item(@backingInt(self), text.ptr);
        return result;
    }

    pub fn setItemText(self: ListView, index: i32, text: [:0]const u8) void {
        c.Rlist_view_set_item_text(@backingInt(self), index, text.ptr);
    }

    pub fn getItemText(self: ListView, index: i32) [:0]const u8 {
        const result = c.Rlist_view_get_item_text(@backingInt(self), index);
        return rt.span(result);
    }

    pub fn removeItem(self: ListView, index: i32) void {
        c.Rlist_view_remove_item(@backingInt(self), index);
    }

    pub fn clearItems(self: ListView) void {
        c.Rlist_view_clear_items(@backingInt(self));
    }

    pub fn getItemCount(self: ListView) i32 {
        const result = c.Rlist_view_get_item_count(@backingInt(self));
        return result;
    }

    pub fn setVirtualItems(self: ListView, count: i32, context: anytype, comptime callback: ?fn (@TypeOf(context), ListView, i32) ?[:0]const u8) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) ?[*:0]const u8 {
                return rt.optPtr(callback.?(rt.contextFromC(Ctx, user_data), @as(ListView, @fromBackingInt(a0)), a1));
            }
        };
        c.Rlist_view_set_virtual_items(@backingInt(self), count, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setItemColorCallback(self: ListView, context: anytype, comptime callback: ?fn (@TypeOf(context), ListView, i32) ?Color) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: ?*f32, a3: ?*f32, a4: ?*f32, a5: ?*f32, user_data: ?*anyopaque) callconv(.c) c_int {
                const color = callback.?(rt.contextFromC(Ctx, user_data), @as(ListView, @fromBackingInt(a0)), a1) orelse return 0;
                if (a2) |out| out.* = color.r;
                if (a3) |out| out.* = color.g;
                if (a4) |out| out.* = color.b;
                if (a5) |out| out.* = color.a;
                return 1;
            }
        };
        c.Rlist_view_set_item_color_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Selects a row. -1 selects nothing.
    pub fn setSelected(self: ListView, index: i32) void {
        c.Rlist_view_set_selected(@backingInt(self), index);
    }

    pub fn getSelected(self: ListView) i32 {
        const result = c.Rlist_view_get_selected(@backingInt(self));
        return result;
    }

    pub fn scrollToItem(self: ListView, index: i32) void {
        c.Rlist_view_scroll_to_item(@backingInt(self), index);
    }

    pub fn setSelectionChangedCallback(self: ListView, context: anytype, comptime callback: ?fn (@TypeOf(context), ListView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(ListView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rlist_view_set_selection_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called on double click or Enter. This also fires the action of the widget.
    pub fn setActivatedCallback(self: ListView, context: anytype, comptime callback: ?fn (@TypeOf(context), ListView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(ListView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rlist_view_set_activated_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.tree_view).
pub const TreeView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?TreeView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: TreeView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a TreeView.
    pub const widget_types = [_]WidgetType{.tree_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: TreeView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new TreeView (Rwidget_create(R_WIDGET_TREE_VIEW)).
    pub fn create() TreeView {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_TREE_VIEW));
    }

    /// Adds an item.
    /// parent_item Item to add under, or R_INVALID_ID for a top-level item.
    /// Returns: The handle of the new item.
    pub fn addItem(self: TreeView, parent_item: ?TreeItem, text: [:0]const u8) ?TreeItem {
        const result = c.Rtree_view_add_item(@backingInt(self), optId(parent_item), text.ptr);
        return TreeItem.fromId(result);
    }

    pub fn clearItems(self: TreeView) void {
        c.Rtree_view_clear_items(@backingInt(self));
    }

    /// Top-level items of a tree.
    pub fn getItemCount(self: TreeView) i32 {
        const result = c.Rtree_view_get_item_count(@backingInt(self));
        return result;
    }

    pub fn getItem(self: TreeView, index: i32) ?TreeItem {
        const result = c.Rtree_view_get_item(@backingInt(self), index);
        return TreeItem.fromId(result);
    }

    /// Selects an item. R_INVALID_ID selects nothing.
    pub fn setSelectedItem(self: TreeView, item: ?TreeItem) void {
        c.Rtree_view_set_selected_item(@backingInt(self), optId(item));
    }

    pub fn getSelectedItem(self: TreeView) ?TreeItem {
        const result = c.Rtree_view_get_selected_item(@backingInt(self));
        return TreeItem.fromId(result);
    }

    pub fn setSelectionChangedCallback(self: TreeView, context: anytype, comptime callback: ?fn (@TypeOf(context), TreeView, TreeItem) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TreeView, @fromBackingInt(a0)), @as(TreeItem, @fromBackingInt(a1)));
            }
        };
        c.Rtree_view_set_selection_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called on double click or Enter. This also fires the action of the widget.
    pub fn setActivatedCallback(self: TreeView, context: anytype, comptime callback: ?fn (@TypeOf(context), TreeView, TreeItem) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TreeView, @fromBackingInt(a0)), @as(TreeItem, @fromBackingInt(a1)));
            }
        };
        c.Rtree_view_set_activated_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Several items can be selected: Ctrl + click adds or removes one,
    /// Shift + click selects a range. The selection callback receives the item
    /// clicked last (the primary one, Rtree_view_get_selected_item).
    pub fn setMultiSelect(self: TreeView, enabled: bool) void {
        c.Rtree_view_set_multi_select(@backingInt(self), @intFromBool(enabled));
    }

    pub fn clearSelection(self: TreeView) void {
        c.Rtree_view_clear_selection(@backingInt(self));
    }

    /// Selected items, top to bottom.
    pub fn getSelectionCount(self: TreeView) i32 {
        const result = c.Rtree_view_get_selection_count(@backingInt(self));
        return result;
    }

    pub fn getSelection(self: TreeView, index: i32) ?TreeItem {
        const result = c.Rtree_view_get_selection(@backingInt(self), index);
        return TreeItem.fromId(result);
    }

    pub fn scrollToItem(self: TreeView, item: TreeItem) void {
        c.Rtree_view_scroll_to_item(@backingInt(self), @backingInt(item));
    }

    pub fn setContextCallback(self: TreeView, context: anytype, comptime callback: ?fn (@TypeOf(context), TreeView, TreeItem, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.Rid, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TreeView, @fromBackingInt(a0)), @as(TreeItem, @fromBackingInt(a1)), a2, a3);
            }
        };
        c.Rtree_view_set_context_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Items can be dragged: the selection is given to Rdrag_begin with
    /// this type and, as data, the handles of the items in decimal separated
    /// by spaces. NULL: no drag (default).
    pub fn setDragType(self: TreeView, type_: ?[:0]const u8) void {
        c.Rtree_view_set_drag_type(@backingInt(self), rt.optPtr(type_));
    }

    /// Item at a point relative to the tree (drop callbacks give local_x, local_y), or R_INVALID_ID.
    pub fn getItemAt(self: TreeView, local_x: f32, local_y: f32) ?TreeItem {
        const result = c.Rtree_view_get_item_at(@backingInt(self), local_x, local_y);
        return TreeItem.fromId(result);
    }

    /// Highlights where a drop would go: an item, or the whole tree (`whole_tree`). R_INVALID_ID, 0 removes it.
    pub fn setDropHighlight(self: TreeView, item: ?TreeItem, whole_tree: bool) void {
        c.Rtree_view_set_drop_highlight(@backingInt(self), optId(item), @intFromBool(whole_tree));
    }
};

/// A widget (WidgetType.menu_item).
pub const MenuItem = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?MenuItem {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: MenuItem) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a MenuItem.
    pub const widget_types = [_]WidgetType{.menu_item};

    /// The widget, for the functions of every widget.
    pub fn widget(self: MenuItem) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new MenuItem (Rwidget_create(R_WIDGET_MENU_ITEM)).
    pub fn create() MenuItem {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_MENU_ITEM));
    }

    pub fn setText(self: MenuItem, text: [:0]const u8) void {
        c.Rmenu_item_set_text(@backingInt(self), text.ptr);
    }

    pub fn getText(self: MenuItem) [:0]const u8 {
        const result = c.Rmenu_item_get_text(@backingInt(self));
        return rt.span(result);
    }

    /// Shows a shortcut next to the item and triggers the item when the
    /// keys are pressed in the window of its menu bar.
    pub fn setShortcut(self: MenuItem, key: Key, modifiers: Modifier) void {
        c.Rmenu_item_set_shortcut(@backingInt(self), @backingInt(key), @as(u32, @bitCast(modifiers)));
    }

    /// Display-only shortcut hint; copied, never binds a key. Overrides
    /// the formatted shortcut without changing its binding. NULL restores the
    /// formatted shortcut; an empty string hides it. XML: ShortcutText.
    pub fn setShortcutText(self: MenuItem, text: ?[:0]const u8) void {
        c.Rmenu_item_set_shortcut_text(@backingInt(self), rt.optPtr(text));
    }

    pub fn setCheckable(self: MenuItem, checkable: bool) void {
        c.Rmenu_item_set_checkable(@backingInt(self), @intFromBool(checkable));
    }

    pub fn setChecked(self: MenuItem, checked: bool) void {
        c.Rmenu_item_set_checked(@backingInt(self), @intFromBool(checked));
    }

    /// Icon drawn before the text of a menu item (after the check mark column).
    /// texture R_INVALID_ID removes it. u0, v0, u1, v1 : region of the texture.
    /// tint    R_TRUE: the texture is a mask drawn in the text color (monochrome icons).
    ///                An SVG in currentColor (Ricon_get) always is. XML: Icon.
    pub fn setIcon(self: MenuItem, texture: ?Texture, u0_: f32, v0: f32, u1_: f32, v1: f32, tint: bool) void {
        c.Rmenu_item_set_icon(@backingInt(self), optId(texture), u0_, v0, u1_, v1, @intFromBool(tint));
    }

    pub fn isChecked(self: MenuItem) bool {
        const result = c.Rmenu_item_is_checked(@backingInt(self));
        return result != 0;
    }

    pub fn setClickedCallback(self: MenuItem, context: anytype, comptime callback: ?fn (@TypeOf(context), TreeItem) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TreeItem, @fromBackingInt(a0)));
            }
        };
        c.Rmenu_item_set_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.menu).
pub const Menu = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Menu {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Menu) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Menu.
    pub const widget_types = [_]WidgetType{.menu};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Menu) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Menu (Rwidget_create(R_WIDGET_MENU)).
    pub fn create() Menu {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_MENU));
    }

    /// Creates a menu inside a menu bar or as a sub-menu of another menu.
    pub fn addMenu(self: Menu, title: [:0]const u8) ?Menu {
        const result = c.Rmenu_add_menu(@backingInt(self), title.ptr);
        return Menu.fromId(result);
    }

    pub fn setTitle(self: Menu, title: [:0]const u8) void {
        c.Rmenu_set_title(@backingInt(self), title.ptr);
    }

    pub fn addItem(self: Menu, text: [:0]const u8) ?MenuItem {
        const result = c.Rmenu_add_item(@backingInt(self), text.ptr);
        return MenuItem.fromId(result);
    }

    pub fn addSeparator(self: Menu) ?MenuItem {
        const result = c.Rmenu_add_separator(@backingInt(self));
        return MenuItem.fromId(result);
    }

    /// A noninteractive caption row, skipped by keyboard navigation.
    pub fn addHeader(self: Menu, text: [:0]const u8) ?MenuItem {
        const result = c.Rmenu_add_header(@backingInt(self), text.ptr);
        return MenuItem.fromId(result);
    }

    /// Title color in an in-window bar; alpha 0 restores the theme. Ignored by native macOS bars.
    pub fn setTitleColor(self: Menu, color: Color) void {
        c.Rmenu_set_title_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// Opens a menu as a popup at a position of the window (logical units).
    pub fn open(self: Menu, window: Window, x: f32, y: f32) void {
        c.Rmenu_open(@backingInt(self), @backingInt(window), x, y);
    }
};

/// A widget (WidgetType.vbox, WidgetType.hbox, WidgetType.wrap_box).
pub const Panel = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Panel {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Panel) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Panel.
    pub const widget_types = [_]WidgetType{ .vbox, .hbox, .wrap_box };

    /// The widget, for the functions of every widget.
    pub fn widget(self: Panel) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Panel (Rwidget_create(R_WIDGET_VBOX)).
    pub fn createVBox() Panel {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_VBOX));
    }

    /// A new Panel (Rwidget_create(R_WIDGET_HBOX)).
    pub fn createHBox() Panel {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_HBOX));
    }

    /// A new Panel (Rwidget_create(R_WIDGET_WRAP_BOX)).
    pub fn createWrapBox() Panel {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_WRAP_BOX));
    }

    /// Gap inserted between neighbouring children.
    pub fn setSpacing(self: Panel, spacing: f32) void {
        c.Rpanel_set_spacing(@backingInt(self), spacing);
    }

    pub fn getSpacing(self: Panel) f32 {
        const result = c.Rpanel_get_spacing(@backingInt(self));
        return result;
    }
};

/// A widget (WidgetType.uniform_grid).
pub const UniformGrid = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?UniformGrid {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: UniformGrid) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a UniformGrid.
    pub const widget_types = [_]WidgetType{.uniform_grid};

    /// The widget, for the functions of every widget.
    pub fn widget(self: UniformGrid) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new UniformGrid (Rwidget_create(R_WIDGET_UNIFORM_GRID)).
    pub fn create() UniformGrid {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_UNIFORM_GRID));
    }

    /// Places children automatically, left to right then top to bottom,
    /// in the given number of columns. 0 uses the grid cell of each slot (default).
    pub fn setColumns(self: UniformGrid, columns: i32) void {
        c.Runiform_grid_set_columns(@backingInt(self), columns);
    }

    pub fn setMinCellSize(self: UniformGrid, width: f32, height: f32) void {
        c.Runiform_grid_set_min_cell_size(@backingInt(self), width, height);
    }
};

/// A widget (WidgetType.grid).
pub const Grid = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Grid {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Grid) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Grid.
    pub const widget_types = [_]WidgetType{.grid};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Grid) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Grid (Rwidget_create(R_WIDGET_GRID)).
    pub fn create() Grid {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_GRID));
    }

    /// Lets a column / row grow to take a share of the free space
    /// (Slate FillColumn / FillRow). 0 sizes it to its content (default).
    pub fn setColumnFill(self: Grid, column: i32, coefficient: f32) void {
        c.Rgrid_set_column_fill(@backingInt(self), column, coefficient);
    }

    pub fn setRowFill(self: Grid, row: i32, coefficient: f32) void {
        c.Rgrid_set_row_fill(@backingInt(self), row, coefficient);
    }
};

/// A widget (WidgetType.border).
pub const Border = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Border {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Border) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Border.
    pub const widget_types = [_]WidgetType{.border};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Border) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Border (Rwidget_create(R_WIDGET_BORDER)).
    pub fn create() Border {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_BORDER));
    }

    /// Space between the outline and the child.
    pub fn setPadding(self: Border, left: f32, top: f32, right: f32, bottom: f32) void {
        c.Rborder_set_padding(@backingInt(self), left, top, right, bottom);
    }

    /// Background color (R_COLOR_PANEL of this widget). Alpha 0 draws no background.
    pub fn setBackground(self: Border, color: Color) void {
        c.Rborder_set_background(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// Outline width and color. Width 0 draws no outline (default).
    pub fn setOutline(self: Border, width: f32, color: Color) void {
        c.Rborder_set_outline(@backingInt(self), width, color.r, color.g, color.b, color.a);
    }

    pub fn setCornerRadius(self: Border, top_left: f32, top_right: f32, bottom_right: f32, bottom_left: f32) void {
        c.Rborder_set_corner_radius(@backingInt(self), top_left, top_right, bottom_right, bottom_left);
    }

    /// Soft drop shadow behind the border. Blur 0 disables it (default).
    pub fn setShadow(self: Border, blur: f32, offset_x: f32, offset_y: f32) void {
        c.Rborder_set_shadow(@backingInt(self), blur, offset_x, offset_y);
    }

    /// What the border is made of. R_MATERIAL_GLASS turns it into a
    /// panel of glass tinted by its background color (the alpha of the color
    /// is the strength of the tint): floating tool bars, side bars, cards.
    pub fn setMaterial(self: Border, material: Material) void {
        c.Rborder_set_material(@backingInt(self), @backingInt(material));
    }

    /// The background of a border becomes an effect (its Background,
    /// if any, is drawn under it; its child over it). R_INVALID_ID removes it.
    /// XML: Effect="aurora" or Effect="file.spv", EffectColor, EffectColor2,
    /// EffectParams="a,b,c,d", EffectAnimate, EffectBackdrop (for a file).
    pub fn setEffect(self: Border, shader: ?Shader, look: ShaderLook) void {
        const raw_look = look.toC();
        c.Rborder_set_effect(@backingInt(self), optId(shader), &raw_look);
    }

    pub fn getEffect(self: Border) ?Shader {
        const result = c.Rborder_get_effect(@backingInt(self));
        return Shader.fromId(result);
    }
};

/// A widget (WidgetType.size_box).
pub const SizeBox = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?SizeBox {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: SizeBox) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a SizeBox.
    pub const widget_types = [_]WidgetType{.size_box};

    /// The widget, for the functions of every widget.
    pub fn widget(self: SizeBox) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new SizeBox (Rwidget_create(R_WIDGET_SIZE_BOX)).
    pub fn create() SizeBox {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SIZE_BOX));
    }

    /// Keeps the child at a fixed width / height ratio, as large as fits.
    /// 0 disables it (default). The fixed, minimum and maximum sizes are set
    /// with Rwidget_set_size, Rwidget_set_min_size and Rwidget_set_max_size.
    pub fn setAspectRatio(self: SizeBox, ratio: f32) void {
        c.Rsize_box_set_aspect_ratio(@backingInt(self), ratio);
    }
};

/// A widget (WidgetType.spacer).
pub const Spacer = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Spacer {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Spacer) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Spacer.
    pub const widget_types = [_]WidgetType{.spacer};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Spacer) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Spacer (Rwidget_create(R_WIDGET_SPACER)).
    pub fn create() Spacer {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SPACER));
    }

    pub fn setSize(self: Spacer, width: f32, height: f32) void {
        c.Rspacer_set_size(@backingInt(self), width, height);
    }
};

/// A widget (WidgetType.scroll_box).
pub const ScrollBox = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?ScrollBox {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: ScrollBox) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a ScrollBox.
    pub const widget_types = [_]WidgetType{.scroll_box};

    /// The widget, for the functions of every widget.
    pub fn widget(self: ScrollBox) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new ScrollBox (Rwidget_create(R_WIDGET_SCROLL_BOX)).
    pub fn create() ScrollBox {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SCROLL_BOX));
    }

    /// Direction in which children are stacked and scrolled. Default: R_VERTICAL.
    pub fn setOrientation(self: ScrollBox, orientation: Orientation) void {
        c.Rscroll_box_set_orientation(@backingInt(self), @backingInt(orientation));
    }

    /// R_TRUE also scrolls across the stacking direction when the content is too large.
    pub fn setScrollBoth(self: ScrollBox, enabled: bool) void {
        c.Rscroll_box_set_scroll_both(@backingInt(self), @intFromBool(enabled));
    }

    pub fn setOffset(self: ScrollBox, x: f32, y: f32) void {
        c.Rscroll_box_set_offset(@backingInt(self), x, y);
    }

    pub fn getOffset(self: ScrollBox) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        c.Rscroll_box_get_offset(@backingInt(self), &x, &y);
        return .{ .x = x, .y = y };
    }

    pub fn scrollToEnd(self: ScrollBox) void {
        c.Rscroll_box_scroll_to_end(@backingInt(self));
    }
};

/// A widget (WidgetType.splitter).
pub const Splitter = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Splitter {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Splitter) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Splitter.
    pub const widget_types = [_]WidgetType{.splitter};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Splitter) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Splitter (Rwidget_create(R_WIDGET_SPLITTER)).
    pub fn create() Splitter {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SPLITTER));
    }

    /// R_HORIZONTAL puts the panes side by side (default), R_VERTICAL stacks them.
    pub fn setOrientation(self: Splitter, orientation: Orientation) void {
        c.Rsplitter_set_orientation(@backingInt(self), @backingInt(orientation));
    }

    pub fn setMinPaneSize(self: Splitter, size: f32) void {
        c.Rsplitter_set_min_pane_size(@backingInt(self), size);
    }
};

/// A widget (WidgetType.switcher).
pub const Switcher = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Switcher {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Switcher) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Switcher.
    pub const widget_types = [_]WidgetType{.switcher};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Switcher) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Switcher (Rwidget_create(R_WIDGET_SWITCHER)).
    pub fn create() Switcher {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_SWITCHER));
    }

    pub fn setIndex(self: Switcher, index: i32) void {
        c.Rswitcher_set_index(@backingInt(self), index);
    }

    pub fn getIndex(self: Switcher) i32 {
        const result = c.Rswitcher_get_index(@backingInt(self));
        return result;
    }
};

/// A widget (WidgetType.tab_view).
pub const TabView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?TabView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: TabView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a TabView.
    pub const widget_types = [_]WidgetType{.tab_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: TabView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new TabView (Rwidget_create(R_WIDGET_TAB_VIEW)).
    pub fn create() TabView {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_TAB_VIEW));
    }

    /// Adds a page. Same as Rwidget_add_child followed by Rslot_set_title.
    /// Returns: The index of the new tab, or -1.
    pub fn addTab(self: TabView, title: [:0]const u8, content: Widget) i32 {
        const result = c.Rtab_view_add_tab(@backingInt(self), title.ptr, @backingInt(content));
        return result;
    }

    pub fn setActive(self: TabView, index: i32) void {
        c.Rtab_view_set_active(@backingInt(self), index);
    }

    pub fn getActive(self: TabView) i32 {
        const result = c.Rtab_view_get_active(@backingInt(self));
        return result;
    }

    pub fn setChangedCallback(self: TabView, context: anytype, comptime callback: ?fn (@TypeOf(context), TabView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TabView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtab_view_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Documents mode: the major tabs of an application (the level,
    /// then one tab per open asset, as in Unreal): tabs on the left with an
    /// icon and a close button (a middle click closes too), shrinking when
    /// they do not fit, no slide between pages. XML: Documents="true".
    pub fn setDocuments(self: TabView, documents: i32) void {
        c.Rtab_view_set_documents(@backingInt(self), documents);
    }

    pub fn getTabCount(self: TabView) i32 {
        const result = c.Rtab_view_get_tab_count(@backingInt(self));
        return result;
    }

    /// The page of a tab, R_INVALID_ID if none.
    pub fn getTab(self: TabView, index: i32) ?Widget {
        const result = c.Rtab_view_get_tab(@backingInt(self), index);
        return Widget.fromId(result);
    }

    /// Index of the tab of a page, -1 if none.
    pub fn findTab(self: TabView, content: Widget) i32 {
        const result = c.Rtab_view_find_tab(@backingInt(self), @backingInt(content));
        return result;
    }

    pub fn setTabTitle(self: TabView, content: Widget, title: [:0]const u8) void {
        c.Rtab_view_set_tab_title(@backingInt(self), @backingInt(content), title.ptr);
    }

    /// Icon before the title (documents). R_INVALID_ID removes it; tint: a mask in the text color (always, for an SVG in currentColor). XML: Slot.Icon.
    pub fn setTabIcon(self: TabView, content: ?Widget, texture: ?Texture, u0_: f32, v0: f32, u1_: f32, v1: f32, tint: bool) void {
        c.Rtab_view_set_tab_icon(@backingInt(self), optId(content), optId(texture), u0_, v0, u1_, v1, @intFromBool(tint));
    }

    /// R_FALSE: no close button (documents ; the level tab). Tabs can be closed by default.
    pub fn setTabClosable(self: TabView, content: Widget, closable: bool) void {
        c.Rtab_view_set_tab_closable(@backingInt(self), @backingInt(content), @intFromBool(closable));
    }

    /// Shows the tab of a page (the changed callback is called).
    pub fn showTab(self: TabView, content: Widget) void {
        c.Rtab_view_show_tab(@backingInt(self), @backingInt(content));
    }

    pub fn setCloseCallback(self: TabView, context: anytype, comptime callback: ?fn (@TypeOf(context), TabView, i32, Widget) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c.Rid, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(TabView, @fromBackingInt(a0)), a1, @as(Widget, @fromBackingInt(a2)));
                return @intFromBool(handled);
            }
        };
        c.Rtab_view_set_close_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.expander).
pub const Expander = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Expander {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Expander) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Expander.
    pub const widget_types = [_]WidgetType{.expander};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Expander) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Expander (Rwidget_create(R_WIDGET_EXPANDER)).
    pub fn create() Expander {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_EXPANDER));
    }

    pub fn setTitle(self: Expander, title: [:0]const u8) void {
        c.Rexpander_set_title(@backingInt(self), title.ptr);
    }

    pub fn getTitle(self: Expander) [:0]const u8 {
        const result = c.Rexpander_get_title(@backingInt(self));
        return rt.span(result);
    }

    pub fn setExpanded(self: Expander, expanded: bool) void {
        c.Rexpander_set_expanded(@backingInt(self), @intFromBool(expanded));
    }

    pub fn isExpanded(self: Expander) bool {
        const result = c.Rexpander_is_expanded(@backingInt(self));
        return result != 0;
    }

    pub fn setChangedCallback(self: Expander, context: anytype, comptime callback: ?fn (@TypeOf(context), Expander, bool) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Expander, @fromBackingInt(a0)), a1 != 0);
            }
        };
        c.Rexpander_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.text_editor).
pub const TextEditor = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?TextEditor {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: TextEditor) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a TextEditor.
    pub const widget_types = [_]WidgetType{.text_editor};

    /// The widget, for the functions of every widget.
    pub fn widget(self: TextEditor) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// text Initial content, or NULL.
    pub fn create(text: ?[:0]const u8) TextEditor {
        const result = c.Rtext_editor_create(rt.optPtr(text));
        return @fromBackingInt(result);
    }

    /// Replaces the whole text. The history of undo is cleared; the changed callback is not called.
    pub fn setText(self: TextEditor, text: [:0]const u8) void {
        c.Rtext_editor_set_text(@backingInt(self), text.ptr);
    }

    /// Returns: The whole text, lines separated by '\n'. Valid until the next call or the next edit.
    pub fn getText(self: TextEditor) [:0]const u8 {
        const result = c.Rtext_editor_get_text(@backingInt(self));
        return rt.span(result);
    }

    /// Returns: The number of bytes of Rtext_editor_get_text.
    pub fn getLength(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_length(@backingInt(self));
        return result;
    }

    pub fn getLineCount(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_line_count(@backingInt(self));
        return result;
    }

    /// Returns: One line, without its line break. Valid until the next edit. NULL when `line` is out of range.
    pub fn getLine(self: TextEditor, line: i32) ?[:0]const u8 {
        const result = c.Rtext_editor_get_line(@backingInt(self), line);
        return rt.optSpan(result);
    }

    /// Types a text at the cursor, replacing the selection, as the user
    /// would (at every cursor when there are several): it can be undone and
    /// the changed callback is called.
    pub fn insertText(self: TextEditor, text: [:0]const u8) void {
        c.Rtext_editor_insert_text(@backingInt(self), text.ptr);
    }

    pub fn setCursor(self: TextEditor, line: i32, column: i32) void {
        c.Rtext_editor_set_cursor(@backingInt(self), line, column);
    }

    pub fn getCursor(self: TextEditor) struct { line: i32, column: i32 } {
        var line: c_int = 0;
        var column: c_int = 0;
        c.Rtext_editor_get_cursor(@backingInt(self), &line, &column);
        return .{ .line = line, .column = column };
    }

    /// Selects from one position to another; the cursor is on the second.
    pub fn select(self: TextEditor, from_line: i32, from_column: i32, to_line: i32, to_column: i32) void {
        c.Rtext_editor_select(@backingInt(self), from_line, from_column, to_line, to_column);
    }

    pub fn selectAll(self: TextEditor) void {
        c.Rtext_editor_select_all(@backingInt(self));
    }

    /// Start and end of the selection, in the order of the text. Returns R_FALSE when nothing is selected.
    pub fn getSelection(self: TextEditor) ?struct { from_line: i32, from_column: i32, to_line: i32, to_column: i32 } {
        var from_line: c_int = 0;
        var from_column: c_int = 0;
        var to_line: c_int = 0;
        var to_column: c_int = 0;
        if (c.Rtext_editor_get_selection(@backingInt(self), &from_line, &from_column, &to_line, &to_column) == 0) return null;
        return .{ .from_line = from_line, .from_column = from_column, .to_line = to_line, .to_column = to_column };
    }

    /// Returns: The selected text, "" when there is none. Valid until the next call or the next edit.
    pub fn getSelectedText(self: TextEditor) [:0]const u8 {
        const result = c.Rtext_editor_get_selected_text(@backingInt(self));
        return rt.span(result);
    }

    /// Scrolls so that a line is visible.
    pub fn scrollToLine(self: TextEditor, line: i32) void {
        c.Rtext_editor_scroll_to_line(@backingInt(self), line);
    }

    /// Adds a cursor (a caret) to the editor; the main cursor stays
    /// the main one. A cursor over another one, or at the place of another
    /// caret, becomes one with it. Rtext_editor_set_cursor,
    /// Rtext_editor_select and Rtext_editor_set_text go back to one cursor.
    pub fn addCursor(self: TextEditor, line: i32, column: i32) void {
        c.Rtext_editor_add_cursor(@backingInt(self), line, column);
    }

    /// Adds a cursor that selects from one position to another (its caret on the second).
    pub fn addSelection(self: TextEditor, from_line: i32, from_column: i32, to_line: i32, to_column: i32) void {
        c.Rtext_editor_add_selection(@backingInt(self), from_line, from_column, to_line, to_column);
    }

    /// Returns: The number of cursors, the main one included (1 at least).
    pub fn getCursorCount(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_cursor_count(@backingInt(self));
        return result;
    }

    /// A cursor by its index, in the order of the text (0 for the
    /// first): its caret and the anchor of its selection (the same position
    /// when nothing is selected). Returns R_FALSE when `index` is out of range.
    pub fn getCursorAt(self: TextEditor, index: i32) ?struct { line: i32, column: i32, anchor_line: i32, anchor_column: i32 } {
        var line: c_int = 0;
        var column: c_int = 0;
        var anchor_line: c_int = 0;
        var anchor_column: c_int = 0;
        if (c.Rtext_editor_get_cursor_at(@backingInt(self), index, &line, &column, &anchor_line, &anchor_column) == 0) return null;
        return .{ .line = line, .column = column, .anchor_line = anchor_line, .anchor_column = anchor_column };
    }

    /// Returns: The index of the main cursor, in the order of Rtext_editor_get_cursor_at.
    pub fn getMainCursor(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_main_cursor(@backingInt(self));
        return result;
    }

    /// Back to the main cursor alone, as Escape does.
    pub fn clearCursors(self: TextEditor) void {
        c.Rtext_editor_clear_cursors(@backingInt(self));
    }

    /// What Ctrl+D does: with nothing selected, selects the word at
    /// each caret; else adds a cursor on the next occurrence of the main
    /// selection (with its case, a whole word when it was selected so) that no
    /// cursor selects, going on from the start of the text. Returns R_FALSE
    /// when there is none.
    pub fn addNextOccurrence(self: TextEditor) i32 {
        const result = c.Rtext_editor_add_next_occurrence(@backingInt(self));
        return result;
    }

    /// What Ctrl+Shift+L does: a cursor on every occurrence of the main selection (or of the word at the caret). Returns their number.
    pub fn selectAllOccurrences(self: TextEditor) i32 {
        const result = c.Rtext_editor_select_all_occurrences(@backingInt(self));
        return result;
    }

    /// Folds the region that starts at a line: the lines after it, up
    /// to the one before the bracket that closes it (or to the last one more
    /// indented), are hidden. When the line starts none, or it is folded
    /// already, the nearest region around the line is folded. Cursors in it
    /// go to the end of its first line. Returns R_FALSE when there is none.
    /// Line numbers stay those of the text. Folds follow the lines when text
    /// is added or removed elsewhere; editing a hidden line (or the line break
    /// of the first line) unfolds its region, and so does a match of the
    /// search or a cursor that goes into it.
    pub fn fold(self: TextEditor, line: i32) i32 {
        const result = c.Rtext_editor_fold(@backingInt(self), line);
        return result;
    }

    /// Unfolds the region that starts at a line, or what hides it. Returns R_FALSE when nothing was folded there.
    pub fn unfold(self: TextEditor, line: i32) i32 {
        const result = c.Rtext_editor_unfold(@backingInt(self), line);
        return result;
    }

    /// Folds every region, those inside others too.
    pub fn foldAll(self: TextEditor) void {
        c.Rtext_editor_fold_all(@backingInt(self));
    }

    pub fn unfoldAll(self: TextEditor) void {
        c.Rtext_editor_unfold_all(@backingInt(self));
    }

    /// Returns: R_TRUE when a folded region starts at this line.
    pub fn isFolded(self: TextEditor, line: i32) bool {
        const result = c.Rtext_editor_is_folded(@backingInt(self), line);
        return result != 0;
    }

    /// Returns: R_TRUE when the line is hidden in a folded region.
    pub fn isLineHidden(self: TextEditor, line: i32) bool {
        const result = c.Rtext_editor_is_line_hidden(@backingInt(self), line);
        return result != 0;
    }

    /// Returns: The last line of the region that starts at a line (folded or not), -1 when it starts none.
    pub fn getFoldEnd(self: TextEditor, line: i32) i32 {
        const result = c.Rtext_editor_get_fold_end(@backingInt(self), line);
        return result;
    }

    /// R_FALSE unfolds everything and stops folding: no markers, and
    /// Ctrl+Shift+[ / ] go to the shortcuts of the window. On by default.
    /// XML: Folding="false".
    pub fn setFolding(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_folding(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getFolding(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_folding(@backingInt(self));
        return result;
    }

    pub fn undo(self: TextEditor) void {
        c.Rtext_editor_undo(@backingInt(self));
    }

    pub fn redo(self: TextEditor) void {
        c.Rtext_editor_redo(@backingInt(self));
    }

    pub fn canUndo(self: TextEditor) bool {
        const result = c.Rtext_editor_can_undo(@backingInt(self));
        return result != 0;
    }

    pub fn canRedo(self: TextEditor) bool {
        const result = c.Rtext_editor_can_redo(@backingInt(self));
        return result != 0;
    }

    /// A read-only editor can still be scrolled, selected and copied.
    pub fn setReadOnly(self: TextEditor, read_only: bool) void {
        c.Rtext_editor_set_read_only(@backingInt(self), @intFromBool(read_only));
    }

    /// Long lines continue on the next row instead of scrolling sideways. Off by default.
    pub fn setWordWrap(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_word_wrap(@backingInt(self), @intFromBool(enabled));
    }

    /// Shows the line numbers in a margin. Off by default.
    pub fn setLineNumbers(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_line_numbers(@backingInt(self), @intFromBool(enabled));
    }

    /// Width of a tab, in spaces (4 by default).
    pub fn setTabSize(self: TextEditor, spaces: i32) void {
        c.Rtext_editor_set_tab_size(@backingInt(self), spaces);
    }

    /// R_TRUE makes the Tab key insert spaces instead of a tab character. Off by default.
    pub fn setTabInsertsSpaces(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_tab_inserts_spaces(@backingInt(self), @intFromBool(enabled));
    }

    /// The same as Rtext_editor_set_language with "XML", "C" or NULL.
    pub fn setSyntax(self: TextEditor, syntax: Syntax) void {
        c.Rtext_editor_set_syntax(@backingInt(self), @backingInt(syntax));
    }

    /// font R_INVALID_ID uses the font of the theme (or the fixed-width
    /// font, with a language).
    /// size 0 uses the font size of the theme.
    pub fn setFont(self: TextEditor, font: ?Font, size: f32) void {
        c.Rtext_editor_set_font(@backingInt(self), optId(font), size);
    }

    /// Text shown, dimmed, while the editor is empty.
    pub fn setPlaceholder(self: TextEditor, text: [:0]const u8) void {
        c.Rtext_editor_set_placeholder(@backingInt(self), text.ptr);
    }

    /// Zoom of the text: a factor of its font size, 1 = 100 % (0.5 .. 4).
    /// The user zooms with Ctrl + wheel (around the pointer), Ctrl + '+',
    /// Ctrl + '-' and Ctrl + 0 (back to 100 %), keypad included. Set by the
    /// program, the top of the view stays and the zoom callback is not called.
    /// XML: Zoom="1.25".
    pub fn setZoom(self: TextEditor, zoom: f32) void {
        c.Rtext_editor_set_zoom(@backingInt(self), zoom);
    }

    pub fn getZoom(self: TextEditor) f32 {
        const result = c.Rtext_editor_get_zoom(@backingInt(self));
        return result;
    }

    /// R_FALSE: Ctrl + wheel and the keys do not zoom (the wheel scrolls). On by default. XML: Zoomable="false".
    pub fn setZoomable(self: TextEditor, zoomable: i32) void {
        c.Rtext_editor_set_zoomable(@backingInt(self), zoomable);
    }

    pub fn setZoomCallback(self: TextEditor, context: anytype, comptime callback: ?fn (@TypeOf(context), TextEditor, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TextEditor, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtext_editor_set_zoom_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Gives the editor a language, by name ("C++", "Python"...), by
    /// another usual name ("cpp", "js") or by the extension of its files
    /// ("rs"). NULL or "" removes it. An editor with a language uses the
    /// fixed-width font unless it was given a font.
    pub fn setLanguage(self: TextEditor, name: ?[:0]const u8) void {
        c.Rtext_editor_set_language(@backingInt(self), rt.optPtr(name));
    }

    /// Returns: The name of the language of the editor, or "".
    pub fn getLanguage(self: TextEditor) [:0]const u8 {
        const result = c.Rtext_editor_get_language(@backingInt(self));
        return rt.span(result);
    }

    /// R_TRUE makes the editor an editor of Markdown (the "Markdown"
    /// language; Markdown="true" in XML): the text stays as it is written,
    /// and what it formats shows while typing, strong text in bold,
    /// emphasized text in italic, titles in bold, code, links and marks in
    /// their colors. A label with Rlabel_set_markdown shows the same text
    /// formatted. R_FALSE removes the language.
    pub fn setMarkdown(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_markdown(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getMarkdown(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_markdown(@backingInt(self));
        return result;
    }

    /// Underlines the misspelled words with a wavy line (R_COLOR_SPELLING);
    /// a right click on one offers corrections (see SPELL CHECKING in
    /// raven_controls.h). Only the lines shown are checked, again when they
    /// change. Off by default: it is meant for prose, not for code.
    pub fn setSpellCheck(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_spell_check(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getSpellCheck(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_spell_check(@backingInt(self));
        return result;
    }

    /// Language of the spell checking ("en_US", "fr"...). NULL: the default (Rspell_set_language).
    pub fn setSpellLanguage(self: TextEditor, language: ?[:0]const u8) void {
        c.Rtext_editor_set_spell_language(@backingInt(self), rt.optPtr(language));
    }

    /// What the language of the editor makes of the character at a
    /// position: the colors come from it. R_TOKEN_TEXT without a language.
    pub fn getToken(self: TextEditor, line: i32, column: i32) Token {
        const result = c.Rtext_editor_get_token(@backingInt(self), line, column);
        return @as(Token, @fromBackingInt(result));
    }

    /// R_FALSE stops the editor from proposing words by itself; Ctrl+Space still does. On by default.
    pub fn setCompletion(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_completion(@backingInt(self), @intFromBool(enabled));
    }

    /// Proposes words for what is before the cursor, as Ctrl+Space does.
    pub fn showCompletions(self: TextEditor) void {
        c.Rtext_editor_show_completions(@backingInt(self));
    }

    pub fn isCompleting(self: TextEditor) bool {
        const result = c.Rtext_editor_is_completing(@backingInt(self));
        return result != 0;
    }

    pub fn setCompletionCallback(self: TextEditor, context: anytype, comptime callback: ?fn (@TypeOf(context), TextEditor, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TextEditor, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rtext_editor_set_completion_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Adds a proposal. Only from a completion callback. Proposals that
    /// do not start with the prefix are left out; the others keep the order
    /// they were added in.
    /// detail A few words shown beside it ("function", "int"), or NULL.
    pub fn addCompletion(self: TextEditor, text: [:0]const u8, detail: ?[:0]const u8) void {
        c.Rtext_editor_add_completion(@backingInt(self), text.ptr, rt.optPtr(detail));
    }

    /// Adds a proposal that writes another text than the one it shows
    /// and is matched on: "Threshold", listed and filtered as such, that
    /// writes "Threshold(" when chosen. Only from a completion callback.
    /// insert What replaces the word being typed; NULL or "" is `text`.
    pub fn addCompletionInsert(self: TextEditor, text: ?[:0]const u8, detail: [:0]const u8, insert: ?[:0]const u8) void {
        c.Rtext_editor_add_completion_insert(@backingInt(self), rt.optPtr(text), detail.ptr, rt.optPtr(insert));
    }

    /// R_FALSE leaves the words of the language and the names of the
    /// text out of the proposals: only the completion callback's are listed
    /// (a language server that knows better). On by default.
    pub fn setCompletionWords(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_completion_words(@backingInt(self), @intFromBool(enabled));
    }

    /// R_FALSE stops the editor from closing brackets and quotes and
    /// from indenting after them. On by default; it only acts with a language.
    pub fn setAutoPairs(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_auto_pairs(@backingInt(self), @intFromBool(enabled));
    }

    /// Underlines a part of a line and attaches a message to it, shown
    /// when the pointer rests there: an error of a compiler, a warning.
    /// Markers follow their line when text is added or removed above it, and
    /// go away when their own line is edited.
    /// to_column -1 for the end of the line.
    pub fn addMarker(self: TextEditor, line: i32, from_column: i32, to_column: i32, kind: MarkerKind, message: [:0]const u8) void {
        c.Rtext_editor_add_marker(@backingInt(self), line, from_column, to_column, @backingInt(kind), message.ptr);
    }

    pub fn clearMarkers(self: TextEditor) void {
        c.Rtext_editor_clear_markers(@backingInt(self));
    }

    pub fn getMarkerCount(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_marker_count(@backingInt(self));
        return result;
    }

    pub fn setHoverCallback(self: TextEditor, context: anytype, comptime callback: ?fn (@TypeOf(context), TextEditor, i32, i32) ?[:0]const u8) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) ?[*:0]const u8 {
                return rt.optPtr(callback.?(rt.contextFromC(Ctx, user_data), @as(TextEditor, @fromBackingInt(a0)), a1, a2));
            }
        };
        c.Rtext_editor_set_hover_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Sets what is searched for, with RSearchFlags, and shows every
    /// match of the visible text (theme colors R_COLOR_SEARCH_MATCH and
    /// R_COLOR_SEARCH_CURRENT). A match lies on one line: a query with a line
    /// break finds nothing. NULL or "" clears the search. The selection does
    /// not move; Rtext_editor_find_next goes to a match.
    pub fn setSearch(self: TextEditor, query: ?[:0]const u8, flags: SearchFlags) void {
        c.Rtext_editor_set_search(@backingInt(self), rt.optPtr(query), @as(u32, @bitCast(flags)));
    }

    /// Returns: The text searched for, "" when there is none.
    pub fn getSearch(self: TextEditor) [:0]const u8 {
        const result = c.Rtext_editor_get_search(@backingInt(self));
        return rt.span(result);
    }

    /// Returns: The RSearchFlags of the search.
    pub fn getSearchFlags(self: TextEditor) SearchFlags {
        const result = c.Rtext_editor_get_search_flags(@backingInt(self));
        return @as(SearchFlags, @bitCast(@as(u32, result)));
    }

    /// Selects the next match after the selection (or the cursor),
    /// going on from the start of the text after its end, and scrolls to it.
    /// Returns R_FALSE when the text has no match.
    pub fn findNext(self: TextEditor) i32 {
        const result = c.Rtext_editor_find_next(@backingInt(self));
        return result;
    }

    /// The same, toward the start: the match before the selection, from the end of the text after its start.
    pub fn findPrevious(self: TextEditor) i32 {
        const result = c.Rtext_editor_find_previous(@backingInt(self));
        return result;
    }

    /// Returns: The number of matches in the whole text. Counted once per change of the text or of the search.
    pub fn getMatchCount(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_match_count(@backingInt(self));
        return result;
    }

    /// Returns: The index of the selected match (0 for the first in the text), -1 when the selection is not a match.
    pub fn getMatchIndex(self: TextEditor) i32 {
        const result = c.Rtext_editor_get_match_index(@backingInt(self));
        return result;
    }

    /// Where a match is: its line and the columns of its first byte and
    /// of the byte after it. Returns R_FALSE when `index` is out of range.
    pub fn getMatch(self: TextEditor, index: i32) ?struct { line: i32, from_column: i32, to_column: i32 } {
        var line: c_int = 0;
        var from_column: c_int = 0;
        var to_column: c_int = 0;
        if (c.Rtext_editor_get_match(@backingInt(self), index, &line, &from_column, &to_column) == 0) return null;
        return .{ .line = line, .from_column = from_column, .to_column = to_column };
    }

    /// Selects a match by its index and scrolls to it. Returns R_FALSE when `index` is out of range.
    pub fn selectMatch(self: TextEditor, index: i32) i32 {
        const result = c.Rtext_editor_select_match(@backingInt(self), index);
        return result;
    }

    /// Replaces the selected match by `replacement`, as one step of
    /// the history, then selects the next match. When the selection is not a
    /// match, only selects the next one (the user sees what will be replaced).
    /// Returns R_TRUE when something was replaced. As with
    /// Rtext_editor_insert_text, the changed callback is called.
    pub fn replace(self: TextEditor, replacement: [:0]const u8) i32 {
        const result = c.Rtext_editor_replace(@backingInt(self), replacement.ptr);
        return result;
    }

    /// Replaces every match by `replacement`, as a single step of the
    /// history (one undo puts them all back). Returns the number of matches
    /// replaced.
    pub fn replaceAll(self: TextEditor, replacement: [:0]const u8) i32 {
        const result = c.Rtext_editor_replace_all(@backingInt(self), replacement.ptr);
        return result;
    }

    /// Opens the find bar of the editor (Ctrl+F), with the row to
    /// replace when `replace` is R_TRUE (Ctrl+H), and gives it the keyboard.
    /// Text selected on one line becomes the text searched for.
    /// Its texts are English unless the locale has the keys Raven.Find,
    /// Raven.Replace, Raven.ReplaceAll, Raven.FindNoResults, Raven.FindCount
    /// ("{0} of {1}"), Raven.FindMatchCase, Raven.FindWholeWord,
    /// Raven.FindPrevious, Raven.FindNext, Raven.FindClose and
    /// Raven.FindToggleReplace.
    pub fn showFind(self: TextEditor, replace_: i32) void {
        c.Rtext_editor_show_find(@backingInt(self), replace_);
    }

    /// Closes the find bar; the matches are no longer shown, F3 still goes to the next one.
    pub fn hideFind(self: TextEditor) void {
        c.Rtext_editor_hide_find(@backingInt(self));
    }

    pub fn isFindShown(self: TextEditor) bool {
        const result = c.Rtext_editor_is_find_shown(@backingInt(self));
        return result != 0;
    }

    /// R_FALSE removes the find bar and its keys (Ctrl+F, Ctrl+H, F3,
    /// Cmd+G), which then go to the shortcuts of the window: for an
    /// application with its own search, built on Rtext_editor_set_search. On
    /// by default. XML: FindBar="false".
    pub fn setFindBar(self: TextEditor, enabled: bool) void {
        c.Rtext_editor_set_find_bar(@backingInt(self), @intFromBool(enabled));
    }

    pub fn setChangedCallback(self: TextEditor, context: anytype, comptime callback: ?fn (@TypeOf(context), TextEditor) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TextEditor, @fromBackingInt(a0)));
            }
        };
        c.Rtext_editor_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.header_bar).
pub const HeaderBar = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?HeaderBar {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: HeaderBar) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a HeaderBar.
    pub const widget_types = [_]WidgetType{.header_bar};

    /// The widget, for the functions of every widget.
    pub fn widget(self: HeaderBar) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// title Text shown in the bar; NULL shows the title of the window.
    pub fn create(title: ?[:0]const u8) HeaderBar {
        const result = c.Rheader_bar_create(rt.optPtr(title));
        return @fromBackingInt(result);
    }

    /// title NULL shows the title of the window.
    pub fn setTitle(self: HeaderBar, title: ?[:0]const u8) void {
        c.Rheader_bar_set_title(@backingInt(self), rt.optPtr(title));
    }

    /// buttons Bitmask of RHeaderButtons. All by default; the maximize button only shows on a resizable window.
    pub fn setButtons(self: HeaderBar, buttons: HeaderButtons) void {
        c.Rheader_bar_set_buttons(@backingInt(self), @as(u32, @bitCast(buttons)));
    }

    /// side R_HALIGN_RIGHT: minimize, maximize, close, as on Windows.
    /// R_HALIGN_LEFT: three round colored buttons, as on macOS. Until it is
    /// set, the side is the one of the system the program runs on (left on
    /// macOS, right elsewhere), whatever the look.
    pub fn setButtonSide(self: HeaderBar, side: HAlign) void {
        c.Rheader_bar_set_button_side(@backingInt(self), @backingInt(side));
    }

    /// align R_HALIGN_CENTER (default) or R_HALIGN_LEFT.
    pub fn setTitleAlign(self: HeaderBar, align_: HAlign) void {
        c.Rheader_bar_set_title_align(@backingInt(self), @backingInt(align_));
    }

    /// R_TRUE: the title sits in a dark tab hanging from the top edge of
    /// the bar (slanted sides, round bottom corners). XML: TitleStyle="Notch".
    pub fn setTitleNotch(self: HeaderBar, notch: i32) void {
        c.Rheader_bar_set_title_notch(@backingInt(self), notch);
    }

    /// R_FALSE removes the background of the bar: for a header that
    /// floats above the content (in an Overlay) or sits inside a glass panel.
    pub fn setBackground(self: HeaderBar, enabled: bool) void {
        c.Rheader_bar_set_background(@backingInt(self), @intFromBool(enabled));
    }
};

/// A widget (WidgetType.dock_area).
pub const DockArea = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?DockArea {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: DockArea) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a DockArea.
    pub const widget_types = [_]WidgetType{.dock_area};

    /// The widget, for the functions of every widget.
    pub fn widget(self: DockArea) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() DockArea {
        const result = c.Rdock_area_create();
        return @fromBackingInt(result);
    }

    /// Adds a panel. The dock area takes ownership of the widget.
    /// title    Text of its tab.
    /// side     Where it goes.
    /// relative A panel of the area to split or to share tabs with, or
    ///                 R_INVALID_ID for the whole area (with R_DOCK_TAB: the
    ///                 first group of tabs).
    /// size     Part of the split space given to the new panel, 0..1
    ///                 (0 = a half, or a quarter along the whole area).
    pub fn addPanel(self: DockArea, panel: ?Widget, title: [:0]const u8, side: DockSide, relative: ?Widget, size: f32) void {
        c.Rdock_area_add_panel(@backingInt(self), optId(panel), title.ptr, @backingInt(side), optId(relative), size);
    }

    /// Moves a panel of the area somewhere else in it.
    pub fn movePanel(self: DockArea, panel: Widget, side: DockSide, relative: Widget, size: f32) void {
        c.Rdock_area_move_panel(@backingInt(self), @backingInt(panel), @backingInt(side), @backingInt(relative), size);
    }

    /// Removes a panel and deletes it.
    pub fn closePanel(self: DockArea, panel: Widget) void {
        c.Rdock_area_close_panel(@backingInt(self), @backingInt(panel));
    }

    pub fn setPanelTitle(self: DockArea, panel: Widget, title: [:0]const u8) void {
        c.Rdock_area_set_panel_title(@backingInt(self), @backingInt(panel), title.ptr);
    }

    /// Icon drawn before the title of the tab of a panel (and on the chip while it is dragged).
    /// texture Texture of the icon, R_INVALID_ID removes it.
    /// u0,v0,u1,v1 Region of the texture (0, 0, 1, 1 : all of it).
    /// tint    R_TRUE: the texture is a mask drawn in the text color of the tab (monochrome icons).
    pub fn setPanelIcon(self: DockArea, panel: ?Widget, texture: ?Texture, u0_: f32, v0: f32, u1_: f32, v1: f32, tint: bool) void {
        c.Rdock_area_set_panel_icon(@backingInt(self), optId(panel), optId(texture), u0_, v0, u1_, v1, @intFromBool(tint));
    }

    /// R_FALSE removes the close button of the tab of a panel. Panels can be closed by default.
    pub fn setPanelClosable(self: DockArea, panel: Widget, closable: bool) void {
        c.Rdock_area_set_panel_closable(@backingInt(self), @backingInt(panel), @intFromBool(closable));
    }

    /// Takes a panel out of the arrangement without deleting it (a
    /// window of an application closed from its menu). Its tab disappears
    /// and its neighbours take its place; the area remembers where it was.
    pub fn hidePanel(self: DockArea, panel: Widget) void {
        c.Rdock_area_hide_panel(@backingInt(self), @backingInt(panel));
    }

    /// Puts a hidden panel back where it was, and brings its tab to the front (also for a panel that is not hidden).
    pub fn openPanel(self: DockArea, panel: Widget) void {
        c.Rdock_area_open_panel(@backingInt(self), @backingInt(panel));
    }

    /// Returns: R_TRUE when the panel is in the arrangement (not hidden), shown or behind another tab.
    pub fn isPanelOpen(self: DockArea, panel: Widget) bool {
        const result = c.Rdock_area_is_panel_open(@backingInt(self), @backingInt(panel));
        return result != 0;
    }

    /// R_TRUE: the close button of a tab hides its panel
    /// (Rdock_area_hide_panel) instead of deleting it. XML: CloseHides="true".
    /// The close callback is asked first either way.
    pub fn setCloseHides(self: DockArea, hides: i32) void {
        c.Rdock_area_set_close_hides(@backingInt(self), hides);
    }

    /// Brings the tab of a panel to the front.
    pub fn showPanel(self: DockArea, panel: Widget) void {
        c.Rdock_area_show_panel(@backingInt(self), @backingInt(panel));
    }

    /// Returns: R_TRUE when the panel is the one shown in its group of tabs.
    pub fn isPanelShown(self: DockArea, panel: Widget) bool {
        const result = c.Rdock_area_is_panel_shown(@backingInt(self), @backingInt(panel));
        return result != 0;
    }

    /// R_FALSE stops the user from moving the panels (the borders can still be dragged).
    pub fn setMovable(self: DockArea, movable: i32) void {
        c.Rdock_area_set_movable(@backingInt(self), movable);
    }

    /// Describes how the panels are arranged, as a short text to keep
    /// in a settings file. Panels are named by their widget name
    /// (Rwidget_set_name): unnamed panels are not part of the description.
    /// Returns: A string valid until the next call.
    pub fn saveLayout(self: DockArea) [:0]const u8 {
        const result = c.Rdock_area_save_layout(@backingInt(self));
        return rt.span(result);
    }

    /// Arranges the panels as a saved description says. Panels of the
    /// area that the description does not name keep a place; names it has
    /// that match no panel are ignored in legacy descriptions. Versioned
    /// descriptions with floating cards reject unknown or duplicate names.
    /// Returns: R_FALSE when the text is not a layout (nothing is changed).
    pub fn loadLayout(self: DockArea, layout: [:0]const u8) Error!void {
        if (c.Rdock_area_load_layout(@backingInt(self), layout.ptr) == 0) return lastError();
    }

    pub fn setCloseCallback(self: DockArea, context: anytype, comptime callback: ?fn (@TypeOf(context), DockArea, Widget) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.Rid, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(DockArea, @fromBackingInt(a0)), @as(Widget, @fromBackingInt(a1)));
                return @intFromBool(handled);
            }
        };
        c.Rdock_area_set_close_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Tearing: a tab dragged out of the area takes its panel to a
    /// window of its own (a floating area of the same family), and a tab
    /// dragged from such a window over the area docks it back where it is
    /// dropped. A double click on the tab of a floating window, or closing
    /// that window, puts its panels back where they were. Dragging the only
    /// tab of a floating window moves the window. R_TRUE by default; XML:
    /// Tearable="false". The functions of this area that take a panel also
    /// work on its panels that are in floating windows.
    pub fn setTearable(self: DockArea, tearable: i32) void {
        c.Rdock_area_set_tearable(@backingInt(self), tearable);
    }

    pub fn isTearable(self: DockArea) bool {
        const result = c.Rdock_area_is_tearable(@backingInt(self));
        return result != 0;
    }

    /// Default for future floats/tears; existing floating panels keep their mode.
    pub fn setFloatMode(self: DockArea, mode: DockFloatMode) void {
        c.Rdock_area_set_float_mode(@backingInt(self), @backingInt(mode));
    }

    /// How the windows of torn-off panels are made (native windows,
    /// R_DOCK_FLOAT_WINDOW; in-window cards are not windows).
    /// flags    RWindowFlags they are created with: R_WINDOW_NO_RESIZE,
    ///                 R_WINDOW_BORDERLESS, R_WINDOW_CUSTOM_HEADER and
    ///                 R_WINDOW_TRANSPARENT (the others are ignored).
    ///                 R_WINDOW_DEFAULT by default.
    /// callback May be NULL: the floating area is the whole window.
    /// Dragging the only tab of such a window still moves it, and closing
    /// it (its header bar's close button too) docks its panels back.
    pub fn setFloatWindow(self: DockArea, flags: WindowFlags, context: anytype, comptime callback: ?fn (@TypeOf(context), DockArea, Widget, Window, DockArea) ?Widget) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.Rid, a2: c.Rid, a3: c.Rid, user_data: ?*anyopaque) callconv(.c) c.Rid {
                return optId(callback.?(rt.contextFromC(Ctx, user_data), @as(DockArea, @fromBackingInt(a0)), @as(Widget, @fromBackingInt(a1)), @as(Window, @fromBackingInt(a2)), @as(DockArea, @fromBackingInt(a3))));
            }
        };
        c.Rdock_area_set_float_window(@backingInt(self), @as(u32, @bitCast(flags)), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Floats a panel. Native mode: screen x/y; in-window mode: window-local logical x/y. Returns its containing window.
    pub fn floatPanel(self: DockArea, panel: Widget, x: i32, y: i32) ?Window {
        const result = c.Rdock_area_float_panel(@backingInt(self), @backingInt(panel), x, y);
        return Window.fromId(result);
    }

    /// A floating panel goes back where it was in the area.
    pub fn dockPanel(self: DockArea, panel: Widget) void {
        c.Rdock_area_dock_panel(@backingInt(self), @backingInt(panel));
    }

    /// The window a floating panel is in, R_INVALID_ID when it is docked in the area.
    pub fn getPanelWindow(self: DockArea, panel: ?Widget) ?Window {
        const result = c.Rdock_area_get_panel_window(@backingInt(self), optId(panel));
        return Window.fromId(result);
    }

    pub fn setChangedCallback(self: DockArea, context: anytype, comptime callback: ?fn (@TypeOf(context), DockArea) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(DockArea, @fromBackingInt(a0)));
            }
        };
        c.Rdock_area_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.island).
pub const Island = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Island {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Island) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Island.
    pub const widget_types = [_]WidgetType{.island};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Island) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() Island {
        const result = c.Risland_create();
        return @fromBackingInt(result);
    }

    /// Unfolds or folds the island. The changed callback is not called.
    pub fn setExpanded(self: Island, expanded: bool) void {
        c.Risland_set_expanded(@backingInt(self), @intFromBool(expanded));
    }

    pub fn isExpanded(self: Island) bool {
        const result = c.Risland_is_expanded(@backingInt(self));
        return result != 0;
    }

    /// Unfolds the island, and folds it back by itself after a while:
    /// to tell something to the user. It stays open while the pointer is on it.
    pub fn expandFor(self: Island, seconds: f64) void {
        c.Risland_expand_for(@backingInt(self), seconds);
    }

    /// R_TRUE (default): the island unfolds under the pointer and folds back when it leaves.
    pub fn setExpandOnHover(self: Island, enabled: bool) void {
        c.Risland_set_expand_on_hover(@backingInt(self), @intFromBool(enabled));
    }

    /// R_TRUE (default): a click on the island unfolds or folds it.
    pub fn setExpandOnClick(self: Island, enabled: bool) void {
        c.Risland_set_expand_on_click(@backingInt(self), @intFromBool(enabled));
    }

    /// R_TRUE gives the island square upper corners: a notch that hangs
    /// from the edge it touches, instead of a capsule that floats under it.
    pub fn setAttached(self: Island, attached: i32) void {
        c.Risland_set_attached(@backingInt(self), attached);
    }

    /// R_TRUE: on a screen with a camera housing at its top (the notch
    /// of a MacBook), the island of a window (Rwindow_set_island) lives in the
    /// housing itself, in a window of its own anchored to the screen: it stays
    /// there when the window is moved, and takes the mouse and the keyboard as
    /// usual. Folded, it is the housing grown into two ears: the first Spacer
    /// of its folded content becomes the room of the camera (what is before
    /// it shows on the left, what is after on the right). Unfolded, its
    /// content starts under the camera.
    ///
    /// It is in the housing while its window is the last one of the
    /// application the user worked in, is shown, and is on that screen; it
    /// goes back into its window otherwise, and on the window systems and
    /// screens without a housing (where nothing changes). XML: Notch="true".
    pub fn setNotch(self: Island, enabled: bool) void {
        c.Risland_set_notch(@backingInt(self), @intFromBool(enabled));
    }

    pub fn getNotch(self: Island) i32 {
        const result = c.Risland_get_notch(@backingInt(self));
        return result;
    }

    /// R_TRUE while the island is in the camera housing of the screen.
    pub fn isInNotch(self: Island) bool {
        const result = c.Risland_is_in_notch(@backingInt(self));
        return result != 0;
    }

    pub fn setChangedCallback(self: Island, context: anytype, comptime callback: ?fn (@TypeOf(context), Island, bool) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Island, @fromBackingInt(a0)), a1 != 0);
            }
        };
        c.Risland_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.file_browser).
pub const FileBrowser = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?FileBrowser {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: FileBrowser) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a FileBrowser.
    pub const widget_types = [_]WidgetType{.file_browser};

    /// The widget, for the functions of every widget.
    pub fn widget(self: FileBrowser) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() FileBrowser {
        const result = c.Rfile_browser_create();
        return @fromBackingInt(result);
    }

    pub fn setMode(self: FileBrowser, mode: FileBrowserMode) void {
        c.Rfile_browser_set_mode(@backingInt(self), @backingInt(mode));
    }

    /// Shows a folder. "~" is the home of the user. Returns R_FALSE when it cannot be read.
    pub fn setDirectory(self: FileBrowser, path: [:0]const u8) Error!void {
        if (c.Rfile_browser_set_directory(@backingInt(self), path.ptr) == 0) return lastError();
    }

    pub fn getDirectory(self: FileBrowser) [:0]const u8 {
        const result = c.Rfile_browser_get_directory(@backingInt(self));
        return rt.span(result);
    }

    /// Reads the folder again.
    pub fn refresh(self: FileBrowser) void {
        c.Rfile_browser_refresh(@backingInt(self));
    }

    /// Kinds of files the user chooses from; the first one is active. The strings are copied.
    pub fn setFilters(self: FileBrowser, filters: []const FileFilter) void {
        c.Rfile_browser_set_filters(@backingInt(self), @ptrCast(filters.ptr), @intCast(filters.len));
    }

    pub fn setShowHidden(self: FileBrowser, show: i32) void {
        c.Rfile_browser_set_show_hidden(@backingInt(self), show);
    }

    /// R_TRUE lets several files be selected (Ctrl and Shift with a click).
    pub fn setMultiple(self: FileBrowser, multiple: bool) void {
        c.Rfile_browser_set_multiple(@backingInt(self), @intFromBool(multiple));
    }

    /// R_FALSE hides the name field, the filter list and the buttons:
    /// what remains is an explorer to put in a side panel. Shown by default.
    pub fn setControlsVisible(self: FileBrowser, visible: bool) void {
        c.Rfile_browser_set_controls_visible(@backingInt(self), @intFromBool(visible));
    }

    /// R_FALSE hides the list of places on the left.
    pub fn setPlacesVisible(self: FileBrowser, visible: bool) void {
        c.Rfile_browser_set_places_visible(@backingInt(self), @intFromBool(visible));
    }

    /// Name typed in the name field (save mode).
    pub fn setFileName(self: FileBrowser, name: [:0]const u8) void {
        c.Rfile_browser_set_file_name(@backingInt(self), name.ptr);
    }

    /// Added to a name typed without extension, in save mode.
    pub fn setDefaultExtension(self: FileBrowser, extension: [:0]const u8) void {
        c.Rfile_browser_set_default_extension(@backingInt(self), extension.ptr);
    }

    /// Paths of the selected entries. The strings are valid until the selection or the folder changes.
    pub fn getSelectionCount(self: FileBrowser) i32 {
        const result = c.Rfile_browser_get_selection_count(@backingInt(self));
        return result;
    }

    pub fn getSelection(self: FileBrowser, index: i32) [:0]const u8 {
        const result = c.Rfile_browser_get_selection(@backingInt(self), index);
        return rt.span(result);
    }

    /// Selects an entry of the folder by its name.
    pub fn select(self: FileBrowser, name: [:0]const u8) void {
        c.Rfile_browser_select(@backingInt(self), name.ptr);
    }

    pub fn setAcceptedCallback(self: FileBrowser, context: anytype, comptime callback: ?fn (@TypeOf(context), FileBrowser, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(FileBrowser, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rfile_browser_set_accepted_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called by the Cancel button.
    pub fn setCancelledCallback(self: FileBrowser, context: anytype, comptime callback: ?fn (@TypeOf(context), FileBrowser, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(FileBrowser, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rfile_browser_set_cancelled_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when the selection changes; `path` is the entry under the cursor, or NULL.
    pub fn setSelectionChangedCallback(self: FileBrowser, context: anytype, comptime callback: ?fn (@TypeOf(context), FileBrowser, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(FileBrowser, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rfile_browser_set_selection_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.viewport).
pub const Viewport = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Viewport {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Viewport) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Viewport.
    pub const widget_types = [_]WidgetType{.viewport};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Viewport) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Viewport (Rwidget_create(R_WIDGET_VIEWPORT)).
    pub fn create() Viewport {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_VIEWPORT));
    }

    /// Shows a texture. R_INVALID_ID shows nothing.
    pub fn setTexture(self: Viewport, texture: ?Texture) void {
        c.Rviewport_set_texture(@backingInt(self), optId(texture));
    }

    /// How the texture is fitted in the widget. Default: R_STRETCH_FILL.
    pub fn setStretch(self: Viewport, stretch: Stretch) void {
        c.Rviewport_set_stretch(@backingInt(self), @backingInt(stretch));
    }

    /// R_TRUE flips the texture vertically (OpenGL framebuffers are bottom-up).
    pub fn setFlipY(self: Viewport, flip: i32) void {
        c.Rviewport_set_flip_y(@backingInt(self), flip);
    }

    pub fn setDrawCallback(self: Viewport, context: anytype, comptime callback: ?fn (@TypeOf(context), ViewportDrawInfo) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: ?*const c.RViewportDrawInfo, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), ViewportDrawInfo.fromC(a0.?.*));
            }
        };
        c.Rviewport_set_draw_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Creates (or destroys) the native child window of the viewport.
    /// The viewport must already be in a window.
    /// Returns: R_TRUE on success.
    pub fn setNative(self: Viewport, enabled: bool) Error!void {
        if (c.Rviewport_set_native(@backingInt(self), @intFromBool(enabled)) == 0) return lastError();
    }

    /// Fills `native` with the handles of the child window.
    pub fn getNativeHandle(self: Viewport) ?NativeWindow {
        var raw_native: c.RNativeWindow = .{};
        if (c.Rviewport_get_native_handle(@backingInt(self), &raw_native) == 0) return null;
        return .fromC(raw_native);
    }

    /// Size of the viewport in pixels after the last layout.
    pub fn getPixelSize(self: Viewport) struct { width: i32, height: i32 } {
        var width: c_int = 0;
        var height: c_int = 0;
        c.Rviewport_get_pixel_size(@backingInt(self), &width, &height);
        return .{ .width = width, .height = height };
    }

    pub fn setResizeCallback(self: Viewport, context: anytype, comptime callback: ?fn (@TypeOf(context), Viewport, i32, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Viewport, @fromBackingInt(a0)), a1, a2);
            }
        };
        c.Rviewport_set_resize_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// R_TRUE redraws the window every frame while the viewport is
    /// visible (game view). R_FALSE redraws only on Rwidget_invalidate (default).
    pub fn setRealtime(self: Viewport, realtime: i32) void {
        c.Rviewport_set_realtime(@backingInt(self), realtime);
    }
};

/// A widget (WidgetType.custom).
pub const Custom = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Custom {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Custom) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Custom.
    pub const widget_types = [_]WidgetType{.custom};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Custom) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Custom (Rwidget_create(R_WIDGET_CUSTOM)).
    pub fn create() Custom {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_CUSTOM));
    }

    pub fn setPaintCallback(self: Custom, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, *Painter, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*c.RPainter, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), @ptrCast(a1.?), a2, a3);
            }
        };
        c.Rcustom_set_paint_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Reports the desired size of the widget. Without it the widget asks for 0 x 0.
    pub fn setMeasureCallback(self: Custom, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, *f32, *f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*f32, a2: ?*f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), a1.?, a2.?);
            }
        };
        c.Rcustom_set_measure_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.menu_bar).
pub const MenuBar = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?MenuBar {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: MenuBar) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a MenuBar.
    pub const widget_types = [_]WidgetType{.menu_bar};

    /// The widget, for the functions of every widget.
    pub fn widget(self: MenuBar) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new MenuBar (Rwidget_create(R_WIDGET_MENU_BAR)).
    pub fn create() MenuBar {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_MENU_BAR));
    }

    /// The menu bar of the system. On macOS, the first MenuBar of a
    /// window is shown in the bar at the top of the screen while the window is
    /// the active one, after the menu of the application (About, Hide, Quit);
    /// it then takes no room in the window. Its shortcuts are those of the
    /// system: R_MOD_SUPER is Command, R_MOD_CTRL is Control. Elsewhere it is
    /// drawn in the window. On by default; R_FALSE keeps it in the window
    /// everywhere. In XML: <MenuBar Native="false">.
    pub fn setNative(self: MenuBar, native: bool) void {
        c.Rmenu_bar_set_native(@backingInt(self), @intFromBool(native));
    }

    /// Returns: R_TRUE while the menu bar is shown by the system instead of the window.
    pub fn isNative(self: MenuBar) bool {
        const result = c.Rmenu_bar_is_native(@backingInt(self));
        return result != 0;
    }

    /// A vertical divider between titles of an in-window MenuBar. Ignored by native macOS bars.
    pub fn addDivider(self: MenuBar) ?MenuItem {
        const result = c.Rmenu_bar_add_divider(@backingInt(self));
        return MenuItem.fromId(result);
    }
};

/// A widget (WidgetType.background_blur).
pub const BackgroundBlur = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?BackgroundBlur {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: BackgroundBlur) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a BackgroundBlur.
    pub const widget_types = [_]WidgetType{.background_blur};

    /// The widget, for the functions of every widget.
    pub fn widget(self: BackgroundBlur) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// Creates a panel that shows what is behind it out of focus,
    /// with one child over it. In XML:
    ///
    ///   <BackgroundBlur Style="Frosted" Radius="24" CornerRadius="18" Padding="16">
    ///       <Label>Over a blurred view of the window</Label>
    ///   </BackgroundBlur>
    ///
    /// It works in any theme and with any material: it is not the glass of
    /// the glass themes (which bends and reflects), but the looks of
    /// RBlurStyle. Unlike the opacity of a widget, it does not let what is
    /// behind show sharp.
    pub fn create() BackgroundBlur {
        const result = c.Rbackground_blur_create();
        return @fromBackingInt(result);
    }

    pub fn setStyle(self: BackgroundBlur, style: BlurStyle) void {
        c.Rbackground_blur_set_style(@backingInt(self), @backingInt(style));
    }

    pub fn getStyle(self: BackgroundBlur) BlurStyle {
        const result = c.Rbackground_blur_get_style(@backingInt(self));
        return @as(BlurStyle, @fromBackingInt(result));
    }

    /// How far what is behind goes out of focus, in logical units:
    /// 4 softens, 20 hides the details, 60 leaves only colors. A negative
    /// value (the default) uses R_METRIC_BLUR_RADIUS of the theme.
    pub fn setRadius(self: BackgroundBlur, radius: f32) void {
        c.Rbackground_blur_set_radius(@backingInt(self), radius);
    }

    pub fn getRadius(self: BackgroundBlur) f32 {
        const result = c.Rbackground_blur_get_radius(@backingInt(self));
        return result;
    }

    /// Color laid over the blur; its alpha is how much of it. Without
    /// one, R_BLUR_PLAIN has none and the other styles take theirs from the
    /// theme (R_COLOR_PANEL).
    pub fn setTint(self: BackgroundBlur, color: Color) void {
        c.Rbackground_blur_set_tint(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// Removes the tint given with Rbackground_blur_set_tint.
    pub fn clearTint(self: BackgroundBlur) void {
        c.Rbackground_blur_clear_tint(@backingInt(self));
    }

    /// Saturation of what is seen through: 1 = as it is, 0 = gray, 1.5 = vivid. Negative = the one of the style.
    pub fn setSaturation(self: BackgroundBlur, saturation: f32) void {
        c.Rbackground_blur_set_saturation(@backingInt(self), saturation);
    }

    /// Fine grain over the blur, 0 = none .. 1. Negative = the one of the style.
    pub fn setGrain(self: BackgroundBlur, grain: f32) void {
        c.Rbackground_blur_set_grain(@backingInt(self), grain);
    }

    pub fn setCornerRadius(self: BackgroundBlur, top_left: f32, top_right: f32, bottom_right: f32, bottom_left: f32) void {
        c.Rbackground_blur_set_corner_radius(@backingInt(self), top_left, top_right, bottom_right, bottom_left);
    }

    /// Space between the edge and the child.
    pub fn setPadding(self: BackgroundBlur, left: f32, top: f32, right: f32, bottom: f32) void {
        c.Rbackground_blur_set_padding(@backingInt(self), left, top, right, bottom);
    }

    /// Soft shadow under the panel; blur 0 = none (default).
    pub fn setShadow(self: BackgroundBlur, shadow_blur: f32) void {
        c.Rbackground_blur_set_shadow(@backingInt(self), shadow_blur);
    }
};

/// A widget (WidgetType.color_picker).
pub const ColorPicker = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?ColorPicker {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: ColorPicker) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a ColorPicker.
    pub const widget_types = [_]WidgetType{.color_picker};

    /// The widget, for the functions of every widget.
    pub fn widget(self: ColorPicker) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() ColorPicker {
        const result = c.Rcolor_picker_create();
        return @fromBackingInt(result);
    }

    /// Sets the color (0..1 each). The callback is not called.
    pub fn setColor(self: ColorPicker, color: Color) void {
        c.Rcolor_picker_set_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    pub fn getColor(self: ColorPicker) Color {
        var color_: Color = .{};
        c.Rcolor_picker_get_color(@backingInt(self), &color_.r, &color_.g, &color_.b, &color_.a);
        return color_;
    }

    /// The same color as hue (0..360), saturation and value (0..1).
    /// The picker remembers the hue of a gray and the saturation of black,
    /// which red, green and blue cannot tell.
    pub fn setHsv(self: ColorPicker, hue: f32, saturation: f32, value: f32) void {
        c.Rcolor_picker_set_hsv(@backingInt(self), hue, saturation, value);
    }

    pub fn getHsv(self: ColorPicker) struct { hue: f32, saturation: f32, value: f32 } {
        var hue: f32 = 0;
        var saturation: f32 = 0;
        var value: f32 = 0;
        c.Rcolor_picker_get_hsv(@backingInt(self), &hue, &saturation, &value);
        return .{ .hue = hue, .saturation = saturation, .value = value };
    }

    /// Sets the color from text: "#RGB", "#RRGGBB", "#RRGGBBAA" (the
    /// '#' may be left out) or one of the color names of the XML attributes.
    /// A code without opacity leaves the opacity as it is.
    /// Returns: R_FALSE when the text is not a color (the color is unchanged).
    pub fn setHex(self: ColorPicker, text: [:0]const u8) Error!void {
        if (c.Rcolor_picker_set_hex(@backingInt(self), text.ptr) == 0) return lastError();
    }

    /// Returns: "#RRGGBB", or "#RRGGBBAA" when the opacity is shown and not full. Valid until the color changes.
    pub fn getHex(self: ColorPicker) [:0]const u8 {
        const result = c.Rcolor_picker_get_hex(@backingInt(self));
        return rt.span(result);
    }

    /// R_TRUE (default) shows the opacity strip and the fourth number. R_FALSE: colors are opaque.
    pub fn setAlphaEnabled(self: ColorPicker, enabled: bool) void {
        c.Rcolor_picker_set_alpha_enabled(@backingInt(self), @intFromBool(enabled));
    }

    /// The color shown next to the current one, to compare with what
    /// was there before: clicking it comes back to it. Rcolor_picker_set_color
    /// does not change it; a popup picker takes it when it opens.
    pub fn setPreviousColor(self: ColorPicker, color: Color) void {
        c.Rcolor_picker_set_previous_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// Adds a color to the row of swatches: one click takes it.
    pub fn addSwatch(self: ColorPicker, color: Color) void {
        c.Rcolor_picker_add_swatch(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    pub fn clearSwatches(self: ColorPicker) void {
        c.Rcolor_picker_clear_swatches(@backingInt(self));
    }

    pub fn getSwatchCount(self: ColorPicker) i32 {
        const result = c.Rcolor_picker_get_swatch_count(@backingInt(self));
        return result;
    }

    /// R_TRUE turns the widget into a swatch that opens the picker in a popup.
    pub fn setPopup(self: ColorPicker, popup: i32) void {
        c.Rcolor_picker_set_popup(@backingInt(self), popup);
    }

    /// R_TRUE hides the code and the numbers: only the square, the strips and the swatches.
    pub fn setCompact(self: ColorPicker, compact: i32) void {
        c.Rcolor_picker_set_compact(@backingInt(self), compact);
    }

    pub fn setChangedCallback(self: ColorPicker, context: anytype, comptime callback: ?fn (@TypeOf(context), ColorPicker, f32, f32, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: f32, a2: f32, a3: f32, a4: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(ColorPicker, @fromBackingInt(a0)), a1, a2, a3, a4);
            }
        };
        c.Rcolor_picker_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.timeline).
pub const Timeline = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Timeline {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Timeline) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Timeline.
    pub const widget_types = [_]WidgetType{.timeline};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Timeline) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() Timeline {
        const result = c.Rtimeline_create();
        return @fromBackingInt(result);
    }

    /// Length of the sequence. The view and the playhead stay within 0 .. duration.
    pub fn setDuration(self: Timeline, seconds: f64) void {
        c.Rtimeline_set_duration(@backingInt(self), seconds);
    }

    pub fn getDuration(self: Timeline) f64 {
        const result = c.Rtimeline_get_duration(@backingInt(self));
        return result;
    }

    /// Moves the playhead. The time callback is not called.
    pub fn setTime(self: Timeline, seconds: f64) void {
        c.Rtimeline_set_time(@backingInt(self), seconds);
    }

    pub fn getTime(self: Timeline) f64 {
        const result = c.Rtimeline_get_time(@backingInt(self));
        return result;
    }

    /// Frames per second. With a frame rate the ruler counts in
    /// frames ("2:12" is second 2, frame 12) and everything snaps to frames;
    /// 0 (default) counts in seconds and snaps to the marks of the ruler.
    pub fn setFrameRate(self: Timeline, frames_per_second: f64) void {
        c.Rtimeline_set_frame_rate(@backingInt(self), frames_per_second);
    }

    pub fn getFrameRate(self: Timeline) f64 {
        const result = c.Rtimeline_get_frame_rate(@backingInt(self));
        return result;
    }

    /// R_FALSE lets items be placed anywhere (holding Alt while dragging does it for one move).
    pub fn setSnapping(self: Timeline, enabled: bool) void {
        c.Rtimeline_set_snapping(@backingInt(self), @intFromBool(enabled));
    }

    /// The part of the sequence that is shown. Zooming is showing less.
    pub fn setView(self: Timeline, start: f64, end: f64) void {
        c.Rtimeline_set_view(@backingInt(self), start, end);
    }

    pub fn getView(self: Timeline) struct { start: f64, end: f64 } {
        var start: f64 = 0;
        var end: f64 = 0;
        c.Rtimeline_get_view(@backingInt(self), &start, &end);
        return .{ .start = start, .end = end };
    }

    /// Makes the playhead run by itself, at the speed of the clock,
    /// calling the time callback at each frame; at the end it stops, or
    /// starts again with Rtimeline_set_loop.
    pub fn setPlaying(self: Timeline, playing: i32) void {
        c.Rtimeline_set_playing(@backingInt(self), playing);
    }

    pub fn isPlaying(self: Timeline) bool {
        const result = c.Rtimeline_is_playing(@backingInt(self));
        return result != 0;
    }

    pub fn setLoop(self: Timeline, loop: i32) void {
        c.Rtimeline_set_loop(@backingInt(self), loop);
    }

    /// Width of the column of the names of the tracks. 0 (default): fits the longest name.
    pub fn setHeaderWidth(self: Timeline, width: f32) void {
        c.Rtimeline_set_header_width(@backingInt(self), width);
    }

    /// Returns: The width of the column of the names, as laid out now.
    pub fn getHeaderWidth(self: Timeline) f32 {
        const result = c.Rtimeline_get_header_width(@backingInt(self));
        return result;
    }

    /// Height of the ruler of time (and of the markers' flags band). 0 (default): automatic.
    pub fn setRulerHeight(self: Timeline, height: f32) void {
        c.Rtimeline_set_ruler_height(@backingInt(self), height);
    }

    pub fn getRulerHeight(self: Timeline) f32 {
        const result = c.Rtimeline_get_ruler_height(@backingInt(self));
        return result;
    }

    /// Height of the tracks that have none of their own (Rtimeline_set_track_height). 0 (default): automatic.
    pub fn setDefaultTrackHeight(self: Timeline, height: f32) void {
        c.Rtimeline_set_default_track_height(@backingInt(self), height);
    }

    pub fn getDefaultTrackHeight(self: Timeline) f32 {
        const result = c.Rtimeline_get_default_track_height(@backingInt(self));
        return result;
    }

    /// Returns: The track, or 0. Tracks are shown in the order they were added.
    pub fn addTrack(self: Timeline, name: [:0]const u8) i32 {
        const result = c.Rtimeline_add_track(@backingInt(self), name.ptr);
        return result;
    }

    /// Removes a track and everything on it.
    pub fn removeTrack(self: Timeline, track: i32) void {
        c.Rtimeline_remove_track(@backingInt(self), track);
    }

    pub fn getTrackCount(self: Timeline) i32 {
        const result = c.Rtimeline_get_track_count(@backingInt(self));
        return result;
    }

    /// Returns: The index-th track from the top, or 0.
    pub fn getTrack(self: Timeline, index: i32) i32 {
        const result = c.Rtimeline_get_track(@backingInt(self), index);
        return result;
    }

    pub fn setTrackName(self: Timeline, track: i32, name: [:0]const u8) void {
        c.Rtimeline_set_track_name(@backingInt(self), track, name.ptr);
    }

    pub fn getTrackName(self: Timeline, track: i32) [:0]const u8 {
        const result = c.Rtimeline_get_track_name(@backingInt(self), track);
        return rt.span(result);
    }

    /// Color of the clips and keys of the track that have none of their own.
    pub fn setTrackColor(self: Timeline, track: i32, r: f32, g: f32, b: f32) void {
        c.Rtimeline_set_track_color(@backingInt(self), track, r, g, b);
    }

    /// Height of the track in logical units; 0 = the default.
    pub fn setTrackHeight(self: Timeline, track: i32, height: f32) void {
        c.Rtimeline_set_track_height(@backingInt(self), track, height);
    }

    /// A locked track shows its items but does not let the user change them.
    pub fn setTrackLocked(self: Timeline, track: i32, locked: i32) void {
        c.Rtimeline_set_track_locked(@backingInt(self), track, locked);
    }

    /// A muted track is drawn dimmed; what muting means is up to the application.
    pub fn setTrackMuted(self: Timeline, track: i32, muted: i32) void {
        c.Rtimeline_set_track_muted(@backingInt(self), track, muted);
    }

    /// A property of the look of a track: "ClipStyle" (Solid,
    /// Gradient, Tint, Outline), "KeyShape" (Diamond, Circle, Square...),
    /// "KeySize", "ClipRadius", "Background" (its lane), or a part and a
    /// property ("Clip.Glow", "Key.BorderColor"). "" or "Default" gives back
    /// the one of the timeline.
    /// Returns: R_FALSE when the name or the value is not one.
    pub fn setTrackStyle(self: Timeline, track: i32, property: [:0]const u8, value: [:0]const u8) Error!void {
        if (c.Rtimeline_set_track_style(@backingInt(self), track, property.ptr, value.ptr) == 0) return lastError();
    }

    pub fn isTrackMuted(self: Timeline, track: i32) bool {
        const result = c.Rtimeline_is_track_muted(@backingInt(self), track);
        return result != 0;
    }

    /// Returns: The clip, or 0 when the track does not exist.
    pub fn addClip(self: Timeline, track: i32, start: f64, length: f64, label: [:0]const u8) i32 {
        const result = c.Rtimeline_add_clip(@backingInt(self), track, start, length, label.ptr);
        return result;
    }

    /// Returns: The key, or 0.
    pub fn addKey(self: Timeline, track: i32, time: f64) i32 {
        const result = c.Rtimeline_add_key(@backingInt(self), track, time);
        return result;
    }

    /// A named moment of the whole sequence, shown on the ruler and across the tracks.
    pub fn addMarker(self: Timeline, time: f64, label: [:0]const u8) i32 {
        const result = c.Rtimeline_add_marker(@backingInt(self), time, label.ptr);
        return result;
    }

    pub fn removeItem(self: Timeline, item: i32) void {
        c.Rtimeline_remove_item(@backingInt(self), item);
    }

    /// Removes every track, clip, key and marker.
    pub fn clear(self: Timeline) void {
        c.Rtimeline_clear(@backingInt(self));
    }

    pub fn getItemType(self: Timeline, item: i32) TimelineItem {
        const result = c.Rtimeline_get_item_type(@backingInt(self), item);
        return @as(TimelineItem, @fromBackingInt(result));
    }

    /// Returns: The track of a clip or of a key; 0 for a marker.
    pub fn getItemTrack(self: Timeline, item: i32) i32 {
        const result = c.Rtimeline_get_item_track(@backingInt(self), item);
        return result;
    }

    pub fn getItemStart(self: Timeline, item: i32) f64 {
        const result = c.Rtimeline_get_item_start(@backingInt(self), item);
        return result;
    }

    /// Returns: The length of a clip; 0 for a key or a marker.
    pub fn getItemLength(self: Timeline, item: i32) f64 {
        const result = c.Rtimeline_get_item_length(@backingInt(self), item);
        return result;
    }

    /// Moves an item: to another track (0 = keep), another start, another length (clips; negative = keep).
    pub fn setItem(self: Timeline, item: i32, track: i32, start: f64, length: f64) void {
        c.Rtimeline_set_item(@backingInt(self), item, track, start, length);
    }

    pub fn setItemLabel(self: Timeline, item: i32, label: [:0]const u8) void {
        c.Rtimeline_set_item_label(@backingInt(self), item, label.ptr);
    }

    pub fn getItemLabel(self: Timeline, item: i32) [:0]const u8 {
        const result = c.Rtimeline_get_item_label(@backingInt(self), item);
        return rt.span(result);
    }

    pub fn setItemColor(self: Timeline, item: i32, r: f32, g: f32, b: f32) void {
        c.Rtimeline_set_item_color(@backingInt(self), item, r, g, b);
    }

    /// A property of the look of one clip, key or marker: "Style"
    /// (Solid, Gradient, Tint, Outline: clips), "Shape" (keys), or any
    /// property of its part ("Background", "BorderColor", "Glow",
    /// "CornerRadius", "Foreground" for its label...).
    pub fn setItemStyle(self: Timeline, item: i32, property: [:0]const u8, value: [:0]const u8) bool {
        const result = c.Rtimeline_set_item_style(@backingInt(self), item, property.ptr, value.ptr);
        return result != 0;
    }

    /// The look the timeline starts from (R_PRESET_AUTO by default; Preset="..." in XML).
    pub fn setPreset(self: Timeline, preset: VisualPreset) void {
        c.Rtimeline_set_preset(@backingInt(self), @backingInt(preset));
    }

    pub fn getPreset(self: Timeline) VisualPreset {
        const result = c.Rtimeline_get_preset(@backingInt(self));
        return @as(VisualPreset, @fromBackingInt(result));
    }

    pub fn getItemCount(self: Timeline) i32 {
        const result = c.Rtimeline_get_item_count(@backingInt(self));
        return result;
    }

    /// Returns: The index-th item, in the order they were added, or 0.
    pub fn getItem(self: Timeline, index: i32) i32 {
        const result = c.Rtimeline_get_item(@backingInt(self), index);
        return result;
    }

    /// Selects an item, alone or (add) with the ones already selected.
    pub fn select(self: Timeline, item: i32, add: i32) void {
        c.Rtimeline_select(@backingInt(self), item, add);
    }

    pub fn clearSelection(self: Timeline) void {
        c.Rtimeline_clear_selection(@backingInt(self));
    }

    pub fn isSelected(self: Timeline, item: i32) bool {
        const result = c.Rtimeline_is_selected(@backingInt(self), item);
        return result != 0;
    }

    pub fn getSelectionCount(self: Timeline) i32 {
        const result = c.Rtimeline_get_selection_count(@backingInt(self));
        return result;
    }

    pub fn getSelected(self: Timeline, index: i32) i32 {
        const result = c.Rtimeline_get_selected(@backingInt(self), index);
        return result;
    }

    pub fn setTimeCallback(self: Timeline, context: anytype, comptime callback: ?fn (@TypeOf(context), Timeline, f64) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: f64, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Timeline, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtimeline_set_time_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called for each item the user moved, stretched or retimed, as
    /// it happens. The action of the widget (OnChanged in XML) fires once
    /// per gesture, when the button is released.
    pub fn setChangedCallback(self: Timeline, context: anytype, comptime callback: ?fn (@TypeOf(context), Timeline, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Timeline, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtimeline_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when the selection changed; `item` is the item just clicked, or 0.
    pub fn setSelectionCallback(self: Timeline, context: anytype, comptime callback: ?fn (@TypeOf(context), Timeline, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Timeline, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtimeline_set_selection_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when an item is double-clicked.
    pub fn setActivatedCallback(self: Timeline, context: anytype, comptime callback: ?fn (@TypeOf(context), Timeline, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Timeline, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtimeline_set_activated_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when the user deletes an item (the Delete key), before
    /// it is removed: its values can still be read. Without this callback the
    /// Delete key does nothing: the application decides what can be deleted.
    pub fn setRemovedCallback(self: Timeline, context: anytype, comptime callback: ?fn (@TypeOf(context), Timeline, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Timeline, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtimeline_set_removed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.node_graph).
pub const NodeGraph = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?NodeGraph {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: NodeGraph) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a NodeGraph.
    pub const widget_types = [_]WidgetType{.node_graph};

    /// The widget, for the functions of every widget.
    pub fn widget(self: NodeGraph) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() NodeGraph {
        const result = c.Rnode_graph_create();
        return @fromBackingInt(result);
    }

    /// x,y Top-left corner of the node, in the units of the canvas.
    pub fn addNode(self: NodeGraph, title: [:0]const u8, x: f32, y: f32) i32 {
        const result = c.Rnode_graph_add_node(@backingInt(self), title.ptr, x, y);
        return result;
    }

    /// Removes a node, its pins, their links, and the widget it holds.
    pub fn removeNode(self: NodeGraph, node: i32) void {
        c.Rnode_graph_remove_node(@backingInt(self), node);
    }

    pub fn clear(self: NodeGraph) void {
        c.Rnode_graph_clear(@backingInt(self));
    }

    pub fn getNodeCount(self: NodeGraph) i32 {
        const result = c.Rnode_graph_get_node_count(@backingInt(self));
        return result;
    }

    pub fn getNode(self: NodeGraph, index: i32) i32 {
        const result = c.Rnode_graph_get_node(@backingInt(self), index);
        return result;
    }

    pub fn setNodeTitle(self: NodeGraph, node: i32, title: [:0]const u8) void {
        c.Rnode_graph_set_node_title(@backingInt(self), node, title.ptr);
    }

    pub fn getNodeTitle(self: NodeGraph, node: i32) [:0]const u8 {
        const result = c.Rnode_graph_get_node_title(@backingInt(self), node);
        return rt.span(result);
    }

    pub fn setNodePosition(self: NodeGraph, node: i32, x: f32, y: f32) void {
        c.Rnode_graph_set_node_position(@backingInt(self), node, x, y);
    }

    pub fn getNodePosition(self: NodeGraph, node: i32) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        c.Rnode_graph_get_node_position(@backingInt(self), node, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Size of a node on the canvas: Raven works it out from its title, its pins and its content.
    pub fn getNodeSize(self: NodeGraph, node: i32) struct { width: f32, height: f32 } {
        var width: f32 = 0;
        var height: f32 = 0;
        c.Rnode_graph_get_node_size(@backingInt(self), node, &width, &height);
        return .{ .width = width, .height = height };
    }

    /// Color of the header of the node; without one it takes the accent color of the theme.
    pub fn setNodeColor(self: NodeGraph, node: i32, r: f32, g: f32, b: f32) void {
        c.Rnode_graph_set_node_color(@backingInt(self), node, r, g, b);
    }

    /// A property of the look of one node: "HeaderStyle" (Solid,
    /// Gradient, Stripe, Tint, None), "HeaderColor", "TitleColor",
    /// "Background", "BorderColor", "BorderWidth", "CornerRadius", "Glow",
    /// "Icon" (an image file shown before its title), or a part and a property
    /// ("Header.Gradient", "Node.ShadowSize"). "" or "Default" gives back the
    /// one of the graph.
    /// Returns: R_FALSE when the name or the value is not one.
    pub fn setNodeStyle(self: NodeGraph, node: i32, property: [:0]const u8, value: [:0]const u8) Error!void {
        if (c.Rnode_graph_set_node_style(@backingInt(self), node, property.ptr, value.ptr) == 0) return lastError();
    }

    /// Puts a widget inside the node, under its pins: the graph owns
    /// it from now on. R_INVALID_ID removes (and deletes) the one it had.
    pub fn setNodeContent(self: NodeGraph, node: i32, widget_: ?Widget) void {
        c.Rnode_graph_set_node_content(@backingInt(self), node, optId(widget_));
    }

    pub fn getNodeContent(self: NodeGraph, node: i32) ?Widget {
        const result = c.Rnode_graph_get_node_content(@backingInt(self), node);
        return Widget.fromId(result);
    }

    /// Name of the node, the `Name` of its XML element: what
    /// <Link From="name.pin"> and Rnode_graph_find_node look for. Not shown.
    pub fn setNodeName(self: NodeGraph, node: i32, name: [:0]const u8) void {
        c.Rnode_graph_set_node_name(@backingInt(self), node, name.ptr);
    }

    pub fn getNodeName(self: NodeGraph, node: i32) [:0]const u8 {
        const result = c.Rnode_graph_get_node_name(@backingInt(self), node);
        return rt.span(result);
    }

    /// Returns: The node of that name, or 0.
    pub fn findNode(self: NodeGraph, name: [:0]const u8) i32 {
        const result = c.Rnode_graph_find_node(@backingInt(self), name.ptr);
        return result;
    }

    /// Value the application attaches to a node.
    pub fn setNodeUserData(self: NodeGraph, node: i32, user_data: ?*anyopaque) void {
        c.Rnode_graph_set_node_user_data(@backingInt(self), node, user_data);
    }

    pub fn getNodeUserData(self: NodeGraph, node: i32) ?*anyopaque {
        const result = c.Rnode_graph_get_node_user_data(@backingInt(self), node);
        return result;
    }

    /// type Free text, or NULL for a pin that links to any type. Returns: The pin, or 0.
    pub fn addInput(self: NodeGraph, node: i32, label: [:0]const u8, type_: ?[:0]const u8) i32 {
        const result = c.Rnode_graph_add_input(@backingInt(self), node, label.ptr, rt.optPtr(type_));
        return result;
    }

    pub fn addOutput(self: NodeGraph, node: i32, label: [:0]const u8, type_: [:0]const u8) i32 {
        const result = c.Rnode_graph_add_output(@backingInt(self), node, label.ptr, type_.ptr);
        return result;
    }

    pub fn removePin(self: NodeGraph, pin: i32) void {
        c.Rnode_graph_remove_pin(@backingInt(self), pin);
    }

    pub fn getPinNode(self: NodeGraph, pin: i32) i32 {
        const result = c.Rnode_graph_get_pin_node(@backingInt(self), pin);
        return result;
    }

    pub fn isPinOutput(self: NodeGraph, pin: i32) bool {
        const result = c.Rnode_graph_is_pin_output(@backingInt(self), pin);
        return result != 0;
    }

    pub fn getPinLabel(self: NodeGraph, pin: i32) [:0]const u8 {
        const result = c.Rnode_graph_get_pin_label(@backingInt(self), pin);
        return rt.span(result);
    }

    pub fn getPinType(self: NodeGraph, pin: i32) [:0]const u8 {
        const result = c.Rnode_graph_get_pin_type(@backingInt(self), pin);
        return rt.span(result);
    }

    /// Name of the pin for Rnode_graph_find_pin and for the links of XML; a pin without one answers to its label.
    pub fn setPinName(self: NodeGraph, pin: i32, name: [:0]const u8) void {
        c.Rnode_graph_set_pin_name(@backingInt(self), pin, name.ptr);
    }

    /// Returns: The pin of a node with that name (or label), or 0.
    pub fn findPin(self: NodeGraph, node: i32, name: [:0]const u8) i32 {
        const result = c.Rnode_graph_find_pin(@backingInt(self), node, name.ptr);
        return result;
    }

    /// Where a pin is on the canvas (the middle of its dot).
    pub fn getPinPosition(self: NodeGraph, pin: i32) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        c.Rnode_graph_get_pin_position(@backingInt(self), pin, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Returns: The index-th input (or output) of a node, or 0.
    pub fn getInput(self: NodeGraph, node: i32, index: i32) i32 {
        const result = c.Rnode_graph_get_input(@backingInt(self), node, index);
        return result;
    }

    pub fn getOutput(self: NodeGraph, node: i32, index: i32) i32 {
        const result = c.Rnode_graph_get_output(@backingInt(self), node, index);
        return result;
    }

    /// Color of the pins of a type and of the links between them.
    pub fn setTypeColor(self: NodeGraph, type_: [:0]const u8, r: f32, g: f32, b: f32) void {
        c.Rnode_graph_set_type_color(@backingInt(self), type_.ptr, r, g, b);
    }

    /// A property of the pins of a type and of their links: "Shape"
    /// (Circle, Ring, Square, Diamond, Triangle, Arrow), "Size", "Glow",
    /// "LinkShape" (Bezier, Straight, Step, Angled), "LinkWidth", "LinkGlow".
    pub fn setTypeStyle(self: NodeGraph, type_: [:0]const u8, property: [:0]const u8, value: [:0]const u8) bool {
        const result = c.Rnode_graph_set_type_style(@backingInt(self), type_.ptr, property.ptr, value.ptr);
        return result != 0;
    }

    /// The same for one pin ("Shape", "Size", "Glow", "Color").
    pub fn setPinStyle(self: NodeGraph, pin: i32, property: [:0]const u8, value: [:0]const u8) bool {
        const result = c.Rnode_graph_set_pin_style(@backingInt(self), pin, property.ptr, value.ptr);
        return result != 0;
    }

    /// Links an output to an input, as the user does by dragging.
    /// The connect callback is not asked.
    /// Returns: The link; 0 when the pins cannot be linked (two inputs, the
    /// same node, different types).
    pub fn connect(self: NodeGraph, output_pin: i32, input_pin: i32) i32 {
        const result = c.Rnode_graph_connect(@backingInt(self), output_pin, input_pin);
        return result;
    }

    pub fn disconnect(self: NodeGraph, link: i32) void {
        c.Rnode_graph_disconnect(@backingInt(self), link);
    }

    pub fn getLinkCount(self: NodeGraph) i32 {
        const result = c.Rnode_graph_get_link_count(@backingInt(self));
        return result;
    }

    pub fn getLink(self: NodeGraph, index: i32) i32 {
        const result = c.Rnode_graph_get_link(@backingInt(self), index);
        return result;
    }

    pub fn getLinkOutput(self: NodeGraph, link: i32) i32 {
        const result = c.Rnode_graph_get_link_output(@backingInt(self), link);
        return result;
    }

    pub fn getLinkInput(self: NodeGraph, link: i32) i32 {
        const result = c.Rnode_graph_get_link_input(@backingInt(self), link);
        return result;
    }

    /// Returns: The link that arrives at an input pin, or 0.
    pub fn getInputLink(self: NodeGraph, input_pin: i32) i32 {
        const result = c.Rnode_graph_get_input_link(@backingInt(self), input_pin);
        return result;
    }

    /// What the middle of the widget shows: a point of the canvas, and how large (1 = one unit per logical unit).
    pub fn setView(self: NodeGraph, center_x: f32, center_y: f32, zoom: f32) void {
        c.Rnode_graph_set_view(@backingInt(self), center_x, center_y, zoom);
    }

    pub fn getView(self: NodeGraph) struct { center_x: f32, center_y: f32, zoom: f32 } {
        var center_x: f32 = 0;
        var center_y: f32 = 0;
        var zoom: f32 = 0;
        c.Rnode_graph_get_view(@backingInt(self), &center_x, &center_y, &zoom);
        return .{ .center_x = center_x, .center_y = center_y, .zoom = zoom };
    }

    /// Converts a point of the widget (from its corner, as in the events) to the canvas, and back, with the view as it is shown now.
    pub fn toCanvas(self: NodeGraph, x: f32, y: f32) struct { canvas_x: f32, canvas_y: f32 } {
        var canvas_x: f32 = 0;
        var canvas_y: f32 = 0;
        c.Rnode_graph_to_canvas(@backingInt(self), x, y, &canvas_x, &canvas_y);
        return .{ .canvas_x = canvas_x, .canvas_y = canvas_y };
    }

    pub fn fromCanvas(self: NodeGraph, canvas_x: f32, canvas_y: f32) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        c.Rnode_graph_from_canvas(@backingInt(self), canvas_x, canvas_y, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Moves and zooms so that every node shows.
    pub fn frameAll(self: NodeGraph) void {
        c.Rnode_graph_frame_all(@backingInt(self));
    }

    /// R_FALSE hides the grid of dots (shown by default).
    pub fn setGridVisible(self: NodeGraph, visible: bool) void {
        c.Rnode_graph_set_grid_visible(@backingInt(self), @intFromBool(visible));
    }

    /// The pulses of light that run along the links, from output to
    /// input. By default they run while the pointer is over the graph, and
    /// the window rests the rest of the time. R_TRUE makes them run all the
    /// time (the window then draws without pause); R_FALSE stops them.
    pub fn setFlowVisible(self: NodeGraph, visible: bool) void {
        c.Rnode_graph_set_flow_visible(@backingInt(self), @intFromBool(visible));
    }

    /// R_TRUE: the user can look but not move, link or delete.
    pub fn setReadOnly(self: NodeGraph, read_only: bool) void {
        c.Rnode_graph_set_read_only(@backingInt(self), @intFromBool(read_only));
    }

    /// The look the graph starts from (R_PRESET_AUTO by default; Preset="..." in XML).
    pub fn setPreset(self: NodeGraph, preset: VisualPreset) void {
        c.Rnode_graph_set_preset(@backingInt(self), @backingInt(preset));
    }

    pub fn getPreset(self: NodeGraph) VisualPreset {
        const result = c.Rnode_graph_get_preset(@backingInt(self));
        return @as(VisualPreset, @fromBackingInt(result));
    }

    pub fn selectNode(self: NodeGraph, node: i32, add: i32) void {
        c.Rnode_graph_select_node(@backingInt(self), node, add);
    }

    pub fn clearSelection(self: NodeGraph) void {
        c.Rnode_graph_clear_selection(@backingInt(self));
    }

    pub fn isNodeSelected(self: NodeGraph, node: i32) bool {
        const result = c.Rnode_graph_is_node_selected(@backingInt(self), node);
        return result != 0;
    }

    pub fn getSelectionCount(self: NodeGraph) i32 {
        const result = c.Rnode_graph_get_selection_count(@backingInt(self));
        return result;
    }

    pub fn getSelectedNode(self: NodeGraph, index: i32) i32 {
        const result = c.Rnode_graph_get_selected_node(@backingInt(self), index);
        return result;
    }

    pub fn setConnectCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32, i32) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1, a2);
                return @intFromBool(handled);
            }
        };
        c.Rnode_graph_set_connect_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called after the user made a link, and before a link the user removed goes (its pins can still be read).
    pub fn setLinkedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1);
            }
        };
        c.Rnode_graph_set_linked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setUnlinkedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1);
            }
        };
        c.Rnode_graph_set_unlinked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called for each node the user moved, when the button is released.
    pub fn setMovedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1);
            }
        };
        c.Rnode_graph_set_moved_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when the selection changed; `item` is the node just clicked, or 0.
    pub fn setSelectionCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1);
            }
        };
        c.Rnode_graph_set_selection_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when the user deletes a node (the Delete key), before
    /// it is removed. Without this callback the Delete key only removes
    /// links: the application decides whether nodes can be deleted.
    pub fn setRemovedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1);
            }
        };
        c.Rnode_graph_set_removed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when the user double-clicks a node (to open what it stands for).
    pub fn setActivatedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1);
            }
        };
        c.Rnode_graph_set_activated_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setContextCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rnode_graph_set_context_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Double click on the empty canvas (`item` 0): the application acts
    /// there (a search to add a node...). Without this callback it frames all nodes.
    pub fn setCanvasActivatedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rnode_graph_set_canvas_activated_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// A wire the user pulled from a pin was released on nothing: `item` is
    /// that pin, x, y where it was dropped (to offer a node to connect it to). The
    /// wire draws back as usual.
    pub fn setWireDroppedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rnode_graph_set_wire_dropped_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// A pin was clicked, not dragged (`item` is the pin, x, y on the canvas):
    /// the application may link in two clicks (Rnode_graph_set_pin_emphasis shows where
    /// the second may go). With this callback such a click neither detaches the wire
    /// of an input nor counts as a wire dropped on nothing.
    pub fn setPinClickedCallback(self: NodeGraph, context: anytype, comptime callback: ?fn (@TypeOf(context), NodeGraph, i32, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(NodeGraph, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rnode_graph_set_pin_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The node under a point of the widget (x, y as in the events: Rnode_graph_to_canvas), or 0.
    pub fn getNodeAt(self: NodeGraph, x: f32, y: f32) i32 {
        const result = c.Rnode_graph_get_node_at(@backingInt(self), x, y);
        return result;
    }

    /// The pin near a point of the widget (or whose tag is under it: Rnode_graph_set_pin_tag), or 0 (a menu for a pin).
    pub fn getPinAt(self: NodeGraph, x: f32, y: f32) i32 {
        const result = c.Rnode_graph_get_pin_at(@backingInt(self), x, y);
        return result;
    }

    /// The link under a point of the widget, or 0 (hidden links are never under it).
    pub fn getLinkAt(self: NodeGraph, x: f32, y: f32) i32 {
        const result = c.Rnode_graph_get_link_at(@backingInt(self), x, y);
        return result;
    }

    /// R_TRUE: this input keeps every link made to it (a state that several
    /// transitions enter) instead of one. Pulling a wire from it starts a new one.
    pub fn setPinMultiple(self: NodeGraph, pin: i32, multiple: bool) void {
        c.Rnode_graph_set_pin_multiple(@backingInt(self), pin, @intFromBool(multiple));
    }

    /// R_TRUE: the node is running (live debug) : a soft ring breathes around it.
    pub fn setNodeActive(self: NodeGraph, node: i32, active: bool) void {
        c.Rnode_graph_set_node_active(@backingInt(self), node, @intFromBool(active));
    }

    /// Color of that ring (the success color of the theme by default).
    pub fn setNodeActiveColor(self: NodeGraph, node: i32, r: f32, g: f32, b: f32) void {
        c.Rnode_graph_set_node_active_color(@backingInt(self), node, r, g, b);
    }

    /// R_FALSE: the Delete key does not remove this node (the root of a tree, the output of a graph).
    pub fn setNodeDeletable(self: NodeGraph, node: i32, deletable: bool) void {
        c.Rnode_graph_set_node_deletable(@backingInt(self), node, @intFromBool(deletable));
    }

    /// Shows a node at once, without the animation a node added to a shown graph pops in with (an application that rebuilds its graph).
    pub fn setNodeShown(self: NodeGraph, node: i32) void {
        c.Rnode_graph_set_node_shown(@backingInt(self), node);
    }

    /// The same for a link made with Rnode_graph_connect: drawn whole at once instead of growing from its output.
    pub fn setLinkShown(self: NodeGraph, link: i32) void {
        c.Rnode_graph_set_link_shown(@backingInt(self), link);
    }

    /// An icon before the title: a texture of the application, shared by many nodes and not deleted with them (the "Icon" style loads one per node from a file). R_INVALID_ID removes it.
    pub fn setNodeIcon(self: NodeGraph, node: i32, texture: ?Texture) void {
        c.Rnode_graph_set_node_icon(@backingInt(self), node, optId(texture));
    }

    /// A short text in a pill on the top right corner of the node ("1", "!"...); NULL or "" removes it.
    pub fn setNodeBadge(self: NodeGraph, node: i32, text: ?[:0]const u8) void {
        c.Rnode_graph_set_node_badge(@backingInt(self), node, rt.optPtr(text));
    }

    /// A short text in a chip of the pin's color outside the node, beside the pin
    /// (left of an input, right of an output): the name of what goes out or comes in
    /// there, as a net label of a schematic. NULL or "" removes it.
    pub fn setPinTag(self: NodeGraph, pin: i32, text: ?[:0]const u8) void {
        c.Rnode_graph_set_pin_tag(@backingInt(self), pin, rt.optPtr(text));
    }

    /// R_TRUE: the link stays (its pins are linked, the application keeps
    /// it) but is not drawn and not picked: its two ends are shown otherwise (pin
    /// tags naming it, as the labels of a schematic stand for a wire).
    pub fn setLinkHidden(self: NodeGraph, link: i32, hidden: i32) void {
        c.Rnode_graph_set_link_hidden(@backingInt(self), link, hidden);
    }

    /// How much a pin stands out, as while a wire is pulled: 1 shows it as a pin
    /// to go to, -1 steps it back, 0 as usual (an application that links in two clicks).
    pub fn setPinEmphasis(self: NodeGraph, pin: i32, emphasis: i32) void {
        c.Rnode_graph_set_pin_emphasis(@backingInt(self), pin, emphasis);
    }

    /// The pin whose tag (Rnode_graph_set_pin_tag) is under a point of the widget, or 0: the chip only, not the pin.
    pub fn getTagAt(self: NodeGraph, x: f32, y: f32) i32 {
        const result = c.Rnode_graph_get_tag_at(@backingInt(self), x, y);
        return result;
    }

    /// R_TRUE: the pin's tag is drawn as under the pointer (a stronger fill, a
    /// thicker edge) — every tag of one net lit while the pointer is on one of them.
    pub fn setPinTagLit(self: NodeGraph, pin: i32, lit: i32) void {
        c.Rnode_graph_set_pin_tag_lit(@backingInt(self), pin, lit);
    }

    /// Pin labels wider than `width` (logical units) are cut short with an
    /// ellipsis and the nodes are laid out with them so (compact ports); 0, the
    /// default, shows every label whole.
    pub fn setPinLabelWidth(self: NodeGraph, width: f32) void {
        c.Rnode_graph_set_pin_label_width(@backingInt(self), width);
    }

    pub fn getPinLabelWidth(self: NodeGraph) f32 {
        const result = c.Rnode_graph_get_pin_label_width(@backingInt(self));
        return result;
    }

    /// Color of the badge pill of one node (Rnode_graph_set_node_badge); its text turns dark or light to suit it. A negative component restores the look's color.
    pub fn setNodeBadgeColor(self: NodeGraph, node: i32, r: f32, g: f32, b: f32) void {
        c.Rnode_graph_set_node_badge_color(@backingInt(self), node, r, g, b);
    }
};

/// A widget (WidgetType.tile_view).
pub const TileView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?TileView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: TileView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a TileView.
    pub const widget_types = [_]WidgetType{.tile_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: TileView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new TileView (Rwidget_create(R_WIDGET_TILE_VIEW)).
    pub fn create() TileView {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_TILE_VIEW));
    }

    /// Gives the tiles: `count` of them, described by `callback`. The selection is cleared.
    pub fn setItems(self: TileView, count: i32, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView, i32, *TileItem) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: ?*c.RTileItem, user_data: ?*anyopaque) callconv(.c) void {
                var item2 = TileItem.fromC(a2.?.*);
                callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0)), a1, &item2);
                a2.?.* = item2.toC();
            }
        };
        c.Rtile_view_set_items(@backingInt(self), count, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Draws the tiles again (their description changed, not their number).
    pub fn refresh(self: TileView) void {
        c.Rtile_view_refresh(@backingInt(self));
    }

    pub fn getCount(self: TileView) i32 {
        const result = c.Rtile_view_get_count(@backingInt(self));
        return result;
    }

    /// Size of a tile (its name included) and of its icon. Default 112 x 112, icon 64.
    pub fn setTileSize(self: TileView, width: f32, height: f32, icon_size: f32) void {
        c.Rtile_view_set_tile_size(@backingInt(self), width, height, icon_size);
    }

    pub fn setEmptyText(self: TileView, text: [:0]const u8) void {
        c.Rtile_view_set_empty_text(@backingInt(self), text.ptr);
    }

    /// Layout="Rows": width of the box the icon is drawn in (its height is the
    /// icon size), for icons that are not square; 0 = square (default). XML: IconWidth.
    pub fn setIconWidth(self: TileView, width: f32) void {
        c.Rtile_view_set_icon_width(@backingInt(self), width);
    }

    /// `count` sections, described by `callback`, all unfolded. Rtile_view_set_items removes them: give them after the tiles.
    pub fn setSections(self: TileView, count: i32, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView, i32, *TileSection) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: ?*c.RTileSection, user_data: ?*anyopaque) callconv(.c) void {
                var item2 = TileSection.fromC(a2.?.*);
                callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0)), a1, &item2);
                a2.?.* = item2.toC();
            }
        };
        c.Rtile_view_set_sections(@backingInt(self), count, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn getSectionCount(self: TileView) i32 {
        const result = c.Rtile_view_get_section_count(@backingInt(self));
        return result;
    }

    /// The section of a tile, or -1 (before the first section).
    pub fn getSectionOf(self: TileView, index: i32) i32 {
        const result = c.Rtile_view_get_section_of(@backingInt(self), index);
        return result;
    }

    /// Folds or unfolds a section (the toggled callback is not called).
    pub fn setSectionFolded(self: TileView, section: i32, folded: i32) void {
        c.Rtile_view_set_section_folded(@backingInt(self), section, folded);
    }

    pub fn isSectionFolded(self: TileView, section: i32) bool {
        const result = c.Rtile_view_is_section_folded(@backingInt(self), section);
        return result != 0;
    }

    /// The section whose header is at a point relative to the widget, or -1.
    pub fn getSectionAt(self: TileView, local_x: f32, local_y: f32) i32 {
        const result = c.Rtile_view_get_section_at(@backingInt(self), local_x, local_y);
        return result;
    }

    /// Called when the user folds or unfolds a section (`index`: the section).
    pub fn setSectionToggledCallback(self: TileView, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtile_view_set_section_toggled_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setSelected(self: TileView, index: i32, selected: bool) void {
        c.Rtile_view_set_selected(@backingInt(self), index, @intFromBool(selected));
    }

    pub fn isSelected(self: TileView, index: i32) bool {
        const result = c.Rtile_view_is_selected(@backingInt(self), index);
        return result != 0;
    }

    pub fn clearSelection(self: TileView) void {
        c.Rtile_view_clear_selection(@backingInt(self));
    }

    pub fn selectOnly(self: TileView, index: i32) void {
        c.Rtile_view_select_only(@backingInt(self), index);
    }

    /// The tile clicked last, or -1.
    pub fn getCurrent(self: TileView) i32 {
        const result = c.Rtile_view_get_current(@backingInt(self));
        return result;
    }

    pub fn getSelectionCount(self: TileView) i32 {
        const result = c.Rtile_view_get_selection_count(@backingInt(self));
        return result;
    }

    /// Index of the nth selected tile, in order.
    pub fn getSelection(self: TileView, nth: i32) i32 {
        const result = c.Rtile_view_get_selection(@backingInt(self), nth);
        return result;
    }

    pub fn scrollTo(self: TileView, index: i32) void {
        c.Rtile_view_scroll_to(@backingInt(self), index);
    }

    /// Tile at a point relative to the widget (drop callbacks give local_x, local_y), or -1.
    pub fn getItemAt(self: TileView, local_x: f32, local_y: f32) i32 {
        const result = c.Rtile_view_get_item_at(@backingInt(self), local_x, local_y);
        return result;
    }

    /// Highlights the tile a drop would go to; -1 removes it.
    pub fn setDropHighlight(self: TileView, index: i32) void {
        c.Rtile_view_set_drop_highlight(@backingInt(self), index);
    }

    /// Tiles can be dragged: the selected tiles are given to Rdrag_begin
    /// with this type and, as data, their indices separated by spaces.
    pub fn setDragType(self: TileView, type_: [:0]const u8) void {
        c.Rtile_view_set_drag_type(@backingInt(self), type_.ptr);
    }

    pub fn setDragDataCallback(self: TileView, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView) ?[:0]const u8) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) ?[*:0]const u8 {
                return rt.optPtr(callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0))));
            }
        };
        c.Rtile_view_set_drag_data_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Tiles can be dragged out of the window, to other applications:
    /// when the user starts dragging the selected tiles (`index` is the one
    /// under the pointer), the callback gives their data by calling
    /// Rdrag_begin_external (the pictures, the files they stand for...), and
    /// Rdrag_set_image. With a drag type too (Rtile_view_set_drag_type), the
    /// drag first goes to the drop targets of the window and only leaves it
    /// with the pointer. NULL: the tiles stay in the application (default).
    pub fn setDragOutCallback(self: TileView, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtile_view_set_drag_out_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setSelectionChangedCallback(self: TileView, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtile_view_set_selection_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setActivatedCallback(self: TileView, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtile_view_set_activated_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setContextCallback(self: TileView, context: anytype, comptime callback: ?fn (@TypeOf(context), TileView, i32, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TileView, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rtile_view_set_context_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.block_editor).
pub const BlockEditor = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?BlockEditor {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: BlockEditor) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a BlockEditor.
    pub const widget_types = [_]WidgetType{.block_editor};

    /// The widget, for the functions of every widget.
    pub fn widget(self: BlockEditor) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() BlockEditor {
        const result = c.Rblock_editor_create();
        return @fromBackingInt(result);
    }

    /// A kind of block, and its block in the palette. Returns its index, -1 on an error.
    pub fn addKind(self: BlockEditor, name: [:0]const u8, label: [:0]const u8, shape: BlockShape, category: [:0]const u8) i32 {
        const result = c.Rblock_editor_add_kind(@backingInt(self), name.ptr, label.ptr, @backingInt(shape), category.ptr);
        return result;
    }

    /// Color of the blocks of a category (Raven picks one from its name otherwise).
    pub fn setCategoryColor(self: BlockEditor, category: [:0]const u8, r: f32, g: f32, b: f32) void {
        c.Rblock_editor_set_category_color(@backingInt(self), category.ptr, r, g, b);
    }

    pub fn setPaletteVisible(self: BlockEditor, visible: bool) void {
        c.Rblock_editor_set_palette_visible(@backingInt(self), @intFromBool(visible));
    }

    /// A new block, the top of a script of its own at x, y (canvas units). Returns it, 0 on an error.
    pub fn addBlock(self: BlockEditor, kind: [:0]const u8, x: f32, y: f32) i32 {
        const result = c.Rblock_editor_add_block(@backingInt(self), kind.ptr, x, y);
        return result;
    }

    /// Removes a block and everything that hangs under it.
    pub fn removeBlock(self: BlockEditor, block: i32) void {
        c.Rblock_editor_remove_block(@backingInt(self), block);
    }

    pub fn clear(self: BlockEditor) void {
        c.Rblock_editor_clear(@backingInt(self));
    }

    /// Puts a block (with what is under it) at a place of another one. R_FALSE when it does not fit there.
    pub fn attach(self: BlockEditor, block: i32, target: i32, place: BlockPlace, index: i32) bool {
        const result = c.Rblock_editor_attach(@backingInt(self), block, target, @backingInt(place), index);
        return result != 0;
    }

    /// Takes a block (with what is under it) out: a script of its own at x, y.
    pub fn detach(self: BlockEditor, block: i32, x: f32, y: f32) void {
        c.Rblock_editor_detach(@backingInt(self), block, x, y);
    }

    pub fn getScriptCount(self: BlockEditor) i32 {
        const result = c.Rblock_editor_get_script_count(@backingInt(self));
        return result;
    }

    /// The top block of a script.
    pub fn getScript(self: BlockEditor, index: i32) i32 {
        const result = c.Rblock_editor_get_script(@backingInt(self), index);
        return result;
    }

    pub fn getKind(self: BlockEditor, block: i32) [:0]const u8 {
        const result = c.Rblock_editor_get_kind(@backingInt(self), block);
        return rt.span(result);
    }

    /// The block under it, 0 if none.
    pub fn getNext(self: BlockEditor, block: i32) i32 {
        const result = c.Rblock_editor_get_next(@backingInt(self), block);
        return result;
    }

    pub fn getMouthCount(self: BlockEditor, block: i32) i32 {
        const result = c.Rblock_editor_get_mouth_count(@backingInt(self), block);
        return result;
    }

    /// The first block in a mouth of a C block, 0 if empty.
    pub fn getBody(self: BlockEditor, block: i32, mouth: i32) i32 {
        const result = c.Rblock_editor_get_body(@backingInt(self), block, mouth);
        return result;
    }

    pub fn getSlotCount(self: BlockEditor, block: i32) i32 {
        const result = c.Rblock_editor_get_slot_count(@backingInt(self), block);
        return result;
    }

    /// The value block in a slot, 0 if the slot holds a typed value.
    pub fn getInput(self: BlockEditor, block: i32, slot: i32) i32 {
        const result = c.Rblock_editor_get_input(@backingInt(self), block, slot);
        return result;
    }

    /// The typed value of a slot.
    pub fn getValue(self: BlockEditor, block: i32, slot: i32) [:0]const u8 {
        const result = c.Rblock_editor_get_value(@backingInt(self), block, slot);
        return rt.span(result);
    }

    pub fn setValue(self: BlockEditor, block: i32, slot: i32, value: [:0]const u8) void {
        c.Rblock_editor_set_value(@backingInt(self), block, slot, value.ptr);
    }

    /// Where a block hangs: the block it hangs from (0: the top of a script).
    pub fn getParent(self: BlockEditor, block: i32) ?struct { place: BlockPlace, index: i32 } {
        var place: c.RBlockPlace = 0;
        var index: c_int = 0;
        if (c.Rblock_editor_get_parent(@backingInt(self), block, &place, &index) == 0) return null;
        return .{ .place = @as(BlockPlace, @fromBackingInt(place)), .index = index };
    }

    pub fn getPosition(self: BlockEditor, block: i32) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        c.Rblock_editor_get_position(@backingInt(self), block, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// R_TRUE: the block is running: a halo breathes around it.
    pub fn setBlockGlow(self: BlockEditor, block: i32, glow: i32) void {
        c.Rblock_editor_set_block_glow(@backingInt(self), block, glow);
    }

    /// Every script as text (valid until the next call).
    pub fn save(self: BlockEditor) [:0]const u8 {
        const result = c.Rblock_editor_save(@backingInt(self));
        return rt.span(result);
    }

    /// Replaces the scripts with those of a text from Rblock_editor_save.
    pub fn load(self: BlockEditor, text: [:0]const u8) Error!void {
        if (c.Rblock_editor_load(@backingInt(self), text.ptr) == 0) return lastError();
    }

    pub fn setChangedCallback(self: BlockEditor, context: anytype, comptime callback: ?fn (@TypeOf(context), BlockEditor, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(BlockEditor, @fromBackingInt(a0)), a1);
            }
        };
        c.Rblock_editor_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setClickedCallback(self: BlockEditor, context: anytype, comptime callback: ?fn (@TypeOf(context), BlockEditor, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(BlockEditor, @fromBackingInt(a0)), a1);
            }
        };
        c.Rblock_editor_set_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setContextCallback(self: BlockEditor, context: anytype, comptime callback: ?fn (@TypeOf(context), BlockEditor, i32, f32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f32, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(BlockEditor, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rblock_editor_set_context_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The choices of a %m slot of a kind, separated by '\n' ("" : the slot is typed in).
    pub fn setSlotOptions(self: BlockEditor, kind: [:0]const u8, slot: i32, options: [:0]const u8) void {
        c.Rblock_editor_set_slot_options(@backingInt(self), kind.ptr, slot, options.ptr);
    }

    /// R_FALSE: the kind is not in the palette (its blocks stay where they are).
    pub fn setKindVisible(self: BlockEditor, kind: [:0]const u8, visible: bool) void {
        c.Rblock_editor_set_kind_visible(@backingInt(self), kind.ptr, @intFromBool(visible));
    }

    /// A new label for a kind (a function that takes one more input...).
    /// The blocks of that kind keep the values of the slots that are still there.
    pub fn setKindLabel(self: BlockEditor, kind: [:0]const u8, label: [:0]const u8) bool {
        const result = c.Rblock_editor_set_kind_label(@backingInt(self), kind.ptr, label.ptr);
        return result != 0;
    }

    /// R_FALSE: the user cannot delete the block (the entry of a function). Not saved.
    pub fn setBlockDeletable(self: BlockEditor, block: i32, deletable: bool) void {
        c.Rblock_editor_set_block_deletable(@backingInt(self), block, @intFromBool(deletable));
    }

    pub fn getSelectionCount(self: BlockEditor) i32 {
        const result = c.Rblock_editor_get_selection_count(@backingInt(self));
        return result;
    }

    pub fn getSelected(self: BlockEditor, index: i32) i32 {
        const result = c.Rblock_editor_get_selected(@backingInt(self), index);
        return result;
    }

    /// Selects a block (add: R_FALSE clears the selection first ; block 0 : only clears).
    pub fn select(self: BlockEditor, block: i32, add: i32) void {
        c.Rblock_editor_select(@backingInt(self), block, add);
    }

    /// Pan (canvas units at the top left) and zoom.
    pub fn getView(self: BlockEditor) struct { x: f32, y: f32, zoom: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        var zoom: f32 = 0;
        c.Rblock_editor_get_view(@backingInt(self), &x, &y, &zoom);
        return .{ .x = x, .y = y, .zoom = zoom };
    }

    pub fn setView(self: BlockEditor, x: f32, y: f32, zoom: f32) void {
        c.Rblock_editor_set_view(@backingInt(self), x, y, zoom);
    }
};

/// A widget (WidgetType.table).
pub const Table = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Table {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Table) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Table.
    pub const widget_types = [_]WidgetType{.table};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Table) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Table (Rwidget_create(R_WIDGET_TABLE)).
    pub fn create() Table {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_TABLE));
    }

    /// Adds a column.
    /// width Width in logical units; 0 or less gives the default (120).
    /// Returns: The index of the column. The stored rows get an empty cell in it.
    pub fn addColumn(self: Table, header: [:0]const u8, width: f32) i32 {
        const result = c.Rtable_add_column(@backingInt(self), header.ptr, width);
        return result;
    }

    pub fn getColumnCount(self: Table) i32 {
        const result = c.Rtable_get_column_count(@backingInt(self));
        return result;
    }

    /// Removes the columns and the stored rows.
    pub fn clearColumns(self: Table) void {
        c.Rtable_clear_columns(@backingInt(self));
    }

    pub fn setColumnHeader(self: Table, column: i32, header: [:0]const u8) void {
        c.Rtable_set_column_header(@backingInt(self), column, header.ptr);
    }

    pub fn getColumnHeader(self: Table, column: i32) [:0]const u8 {
        const result = c.Rtable_get_column_header(@backingInt(self), column);
        return rt.span(result);
    }

    pub fn setColumnWidth(self: Table, column: i32, width: f32) void {
        c.Rtable_set_column_width(@backingInt(self), column, width);
    }

    /// The width the column has on screen (a filling column takes more than its width).
    pub fn getColumnWidth(self: Table, column: i32) f32 {
        const result = c.Rtable_get_column_width(@backingInt(self), column);
        return result;
    }

    /// > 0: the column takes this share of the room the others leave; 0: its width only.
    pub fn setColumnFill(self: Table, column: i32, fill: f32) void {
        c.Rtable_set_column_fill(@backingInt(self), column, fill);
    }

    /// R_FALSE: a click on the header does not sort (default R_TRUE).
    pub fn setColumnSortable(self: Table, column: i32, sortable: bool) void {
        c.Rtable_set_column_sortable(@backingInt(self), column, @intFromBool(sortable));
    }

    /// Where the texts sit in the cells: 0 left, 0.5 center, 1 right.
    pub fn setColumnAlign(self: Table, column: i32, align_: f32) void {
        c.Rtable_set_column_align(@backingInt(self), column, align_);
    }

    /// Adds a row.
    /// cells The texts of the cells, separated by '|' ("Ada|36|London"),
    ///              or NULL for an empty row; Rtable_set_cell gives a text holding a '|'.
    /// Returns: The index of the row.
    pub fn addRow(self: Table, cells: ?[:0]const u8) i32 {
        const result = c.Rtable_add_row(@backingInt(self), rt.optPtr(cells));
        return result;
    }

    pub fn setCell(self: Table, row: i32, column: i32, text: [:0]const u8) void {
        c.Rtable_set_cell(@backingInt(self), row, column, text.ptr);
    }

    pub fn getCell(self: Table, row: i32, column: i32) [:0]const u8 {
        const result = c.Rtable_get_cell(@backingInt(self), row, column);
        return rt.span(result);
    }

    pub fn removeRow(self: Table, row: i32) void {
        c.Rtable_remove_row(@backingInt(self), row);
    }

    pub fn clearRows(self: Table) void {
        c.Rtable_clear_rows(@backingInt(self));
    }

    pub fn getRowCount(self: Table) i32 {
        const result = c.Rtable_get_row_count(@backingInt(self));
        return result;
    }

    pub fn setVirtualRows(self: Table, count: i32, context: anytype, comptime callback: ?fn (@TypeOf(context), Table, i32, i32) ?[:0]const u8) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) ?[*:0]const u8 {
                return rt.optPtr(callback.?(rt.contextFromC(Ctx, user_data), @as(Table, @fromBackingInt(a0)), a1, a2));
            }
        };
        c.Rtable_set_virtual_rows(@backingInt(self), count, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setCellColorCallback(self: Table, context: anytype, comptime callback: ?fn (@TypeOf(context), Table, i32, i32) ?Color) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, a3: ?*f32, a4: ?*f32, a5: ?*f32, a6: ?*f32, user_data: ?*anyopaque) callconv(.c) c_int {
                const color = callback.?(rt.contextFromC(Ctx, user_data), @as(Table, @fromBackingInt(a0)), a1, a2) orelse return 0;
                if (a3) |out| out.* = color.r;
                if (a4) |out| out.* = color.g;
                if (a5) |out| out.* = color.b;
                if (a6) |out| out.* = color.a;
                return 1;
            }
        };
        c.Rtable_set_cell_color_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Stored rows: a fixed text color; column -1 colors the row; cells override it.
    /// Alpha 0 restores the inherited/theme color. A color from the cell color callback wins over it.
    pub fn setCellTextColor(self: Table, row: i32, column: i32, color: Color) void {
        c.Rtable_set_cell_text_color(@backingInt(self), row, column, color.r, color.g, color.b, color.a);
    }

    /// Opt into Ctrl/Cmd toggles and Shift ranges; single selection is the default. Same as Rtable_set_selection_mode(MULTIPLE or SINGLE).
    pub fn setMultiSelect(self: Table, enabled: bool) void {
        c.Rtable_set_multi_select(@backingInt(self), @intFromBool(enabled));
    }

    /// Single (default), multiple or no selection (SelectionMode="Multiple" in XML).
    /// Going to single keeps the selected row, going to none clears the selection.
    pub fn setSelectionMode(self: Table, mode: TableSelectionMode) void {
        c.Rtable_set_selection_mode(@backingInt(self), @backingInt(mode));
    }

    pub fn getSelectionMode(self: Table) TableSelectionMode {
        const result = c.Rtable_get_selection_mode(@backingInt(self));
        return @as(TableSelectionMode, @fromBackingInt(result));
    }

    pub fn setRowSelected(self: Table, row: i32, selected: bool) void {
        c.Rtable_set_row_selected(@backingInt(self), row, @intFromBool(selected));
    }

    pub fn isRowSelected(self: Table, row: i32) bool {
        const result = c.Rtable_is_row_selected(@backingInt(self), row);
        return result != 0;
    }

    /// Selects (`selected` R_TRUE) or deselects the rows first..last, both
    /// included, keeping the others: multiple selection only (in single
    /// selection, selecting a range selects `last`).
    pub fn selectRange(self: Table, first: i32, last: i32, selected: bool) void {
        c.Rtable_select_range(@backingInt(self), first, last, @intFromBool(selected));
    }

    /// Multiple selection: selects every row (Ctrl/Cmd+A). Nothing in the other modes.
    pub fn selectAll(self: Table) void {
        c.Rtable_select_all(@backingInt(self));
    }

    pub fn clearSelection(self: Table) void {
        c.Rtable_clear_selection(@backingInt(self));
    }

    pub fn getSelectionCount(self: Table) i32 {
        const result = c.Rtable_get_selection_count(@backingInt(self));
        return result;
    }

    /// Selected row at index, top to bottom; -1 outside the selection.
    pub fn getSelection(self: Table, index: i32) i32 {
        const result = c.Rtable_get_selection(@backingInt(self), index);
        return result;
    }

    /// The selection as runs of consecutive rows, top to bottom: the
    /// fast way to go through a large selection (select all of a million rows
    /// is one range).
    pub fn getSelectionRangeCount(self: Table) i32 {
        const result = c.Rtable_get_selection_range_count(@backingInt(self));
        return result;
    }

    /// The rows first..last (both included) of a range of the selection. Returns: R_FALSE outside the ranges.
    pub fn getSelectionRange(self: Table, index: i32) ?struct { first: i32, last: i32 } {
        var first: c_int = 0;
        var last: c_int = 0;
        if (c.Rtable_get_selection_range(@backingInt(self), index, &first, &last) == 0) return null;
        return .{ .first = first, .last = last };
    }

    /// Replaces the selection with one row. -1 selects nothing, including in multi-select mode.
    pub fn setSelected(self: Table, row: i32) void {
        c.Rtable_set_selected(@backingInt(self), row);
    }

    /// The selected row (-1: none). In multiple selection, the one
    /// selected last, or else the first one; the selection changed callback
    /// receives it.
    pub fn getSelected(self: Table) i32 {
        const result = c.Rtable_get_selected(@backingInt(self));
        return result;
    }

    /// The row the keyboard is on: the selected row in single
    /// selection; in multiple selection the row last clicked or reached with
    /// the arrows, which Space toggles (it may be unselected). -1: none.
    pub fn getCurrentRow(self: Table) i32 {
        const result = c.Rtable_get_current_row(@backingInt(self));
        return result;
    }

    pub fn scrollToRow(self: Table, row: i32) void {
        c.Rtable_scroll_to_row(@backingInt(self), row);
    }

    /// Sorts by a column (stored rows are moved); -1 shows no sorted column.
    pub fn sort(self: Table, column: i32, descending: bool) void {
        c.Rtable_sort(@backingInt(self), column, @intFromBool(descending));
    }

    pub fn getSortColumn(self: Table) i32 {
        const result = c.Rtable_get_sort_column(@backingInt(self));
        return result;
    }

    pub fn isSortDescending(self: Table) bool {
        const result = c.Rtable_is_sort_descending(@backingInt(self));
        return result != 0;
    }

    pub fn setHeaderVisible(self: Table, visible: bool) void {
        c.Rtable_set_header_visible(@backingInt(self), @intFromBool(visible));
    }

    pub fn setGridLines(self: Table, visible: bool) void {
        c.Rtable_set_grid_lines(@backingInt(self), @intFromBool(visible));
    }

    /// Every other row a little darker.
    pub fn setStriped(self: Table, striped: bool) void {
        c.Rtable_set_striped(@backingInt(self), @intFromBool(striped));
    }

    pub fn setSelectionChangedCallback(self: Table, context: anytype, comptime callback: ?fn (@TypeOf(context), Table, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Table, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtable_set_selection_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called on double click or Enter. This also fires the action of the widget.
    pub fn setActivatedCallback(self: Table, context: anytype, comptime callback: ?fn (@TypeOf(context), Table, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Table, @fromBackingInt(a0)), a1);
            }
        };
        c.Rtable_set_activated_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setSortCallback(self: Table, context: anytype, comptime callback: ?fn (@TypeOf(context), Table, i32, bool) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Table, @fromBackingInt(a0)), a1, a2 != 0);
            }
        };
        c.Rtable_set_sort_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// R_TRUE: the cells of the column are edited in place by the user (default R_FALSE).
    pub fn setColumnEditable(self: Table, column: i32, editable: i32) void {
        c.Rtable_set_column_editable(@backingInt(self), column, editable);
    }

    pub fn isColumnEditable(self: Table, column: i32) bool {
        const result = c.Rtable_is_column_editable(@backingInt(self), column);
        return result != 0;
    }

    pub fn setCellEditedCallback(self: Table, context: anytype, comptime callback: ?fn (@TypeOf(context), Table, i32, i32, [:0]const u8) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, a3: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Table, @fromBackingInt(a0)), a1, a2, rt.span(a3));
                return @intFromBool(handled);
            }
        };
        c.Rtable_set_cell_edited_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Opens the editor on a cell, its text selected, as F2 does (the
    /// row is selected and scrolled into view). Any column can be edited this
    /// way, editable or not. Returns: R_TRUE when the editor is open.
    pub fn editCell(self: Table, row: i32, column: i32) bool {
        const result = c.Rtable_edit_cell(@backingInt(self), row, column);
        return result != 0;
    }

    pub fn isEditing(self: Table) bool {
        const result = c.Rtable_is_editing(@backingInt(self));
        return result != 0;
    }

    /// Closes the editor: `commit` R_TRUE keeps the text (through the
    /// cell edited callback), R_FALSE forgets it. Returns: R_FALSE when the text
    /// was refused (the editor then stays open), R_TRUE otherwise.
    pub fn endEdit(self: Table, commit: i32) bool {
        const result = c.Rtable_end_edit(@backingInt(self), commit);
        return result != 0;
    }

    /// The first `count` columns stay in place when the table scrolls
    /// sideways; a thin shadow marks where the others pass under them. 0 (the
    /// default): every column scrolls.
    pub fn setFrozenColumns(self: Table, count: i32) void {
        c.Rtable_set_frozen_columns(@backingInt(self), count);
    }

    pub fn getFrozenColumns(self: Table) i32 {
        const result = c.Rtable_get_frozen_columns(@backingInt(self));
        return result;
    }

    /// Text (default), check box or progress bar: how the cells of the
    /// column are drawn from their texts. A check column is made editable (the
    /// user toggles it; Rtable_set_column_editable(R_FALSE) after this shows it
    /// only) and centered. For anything else, a cell color callback and the
    /// texts are what the table offers: it draws no other widget in its cells.
    pub fn setColumnKind(self: Table, column: i32, kind: TableColumnKind) void {
        c.Rtable_set_column_kind(@backingInt(self), column, @backingInt(kind));
    }

    pub fn getColumnKind(self: Table, column: i32) TableColumnKind {
        const result = c.Rtable_get_column_kind(@backingInt(self), column);
        return @as(TableColumnKind, @fromBackingInt(result));
    }

    /// A cell of a check column: R_TRUE when its text is "1", "true" or "yes". Any cell can be asked.
    pub fn isCellChecked(self: Table, row: i32, column: i32) bool {
        const result = c.Rtable_is_cell_checked(@backingInt(self), row, column);
        return result != 0;
    }

    /// Stored rows: writes "1" or "0" in the cell (no callback is called).
    pub fn setCellChecked(self: Table, row: i32, column: i32, checked: bool) void {
        c.Rtable_set_cell_checked(@backingInt(self), row, column, @intFromBool(checked));
    }
};

/// A widget (WidgetType.date_picker).
pub const DatePicker = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?DatePicker {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: DatePicker) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a DatePicker.
    pub const widget_types = [_]WidgetType{.date_picker};

    /// The widget, for the functions of every widget.
    pub fn widget(self: DatePicker) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new DatePicker (Rwidget_create(R_WIDGET_DATE_PICKER)).
    pub fn create() DatePicker {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_DATE_PICKER));
    }

    /// Sets the date (today when the picker is created). An invalid date is refused.
    pub fn setDate(self: DatePicker, year: i32, month: i32, day: i32) void {
        c.Rdate_picker_set_date(@backingInt(self), year, month, day);
    }

    pub fn getDate(self: DatePicker) struct { year: i32, month: i32, day: i32 } {
        var year: c_int = 0;
        var month: c_int = 0;
        var day: c_int = 0;
        c.Rdate_picker_get_date(@backingInt(self), &year, &month, &day);
        return .{ .year = year, .month = month, .day = day };
    }

    /// The earliest and the latest dates that can be chosen; 0 for year leaves that side open.
    pub fn setRange(self: DatePicker, min_year: i32, min_month: i32, min_day: i32, max_year: i32, max_month: i32, max_day: i32) void {
        c.Rdate_picker_set_range(@backingInt(self), min_year, min_month, min_day, max_year, max_month, max_day);
    }

    /// 0 = Sunday (default), 1 = Monday...
    pub fn setFirstDayOfWeek(self: DatePicker, day: i32) void {
        c.Rdate_picker_set_first_day_of_week(@backingInt(self), day);
    }

    /// How the field writes the date: YYYY, MM, M, DD, D, MMMM (the name
    /// of the month), MMM (its first three letters), dddd (the name of the day),
    /// ddd; anything else is kept. Default "YYYY-MM-DD"; "D MMMM YYYY" gives "3 November 2026".
    pub fn setFormat(self: DatePicker, format: [:0]const u8) void {
        c.Rdate_picker_set_format(@backingInt(self), format.ptr);
    }

    /// The date as the field shows it (valid until the next call).
    pub fn getText(self: DatePicker) [:0]const u8 {
        const result = c.Rdate_picker_get_text(@backingInt(self));
        return rt.span(result);
    }

    /// Opens or closes the calendar.
    pub fn setOpen(self: DatePicker, open: i32) void {
        c.Rdate_picker_set_open(@backingInt(self), open);
    }

    pub fn isOpen(self: DatePicker) bool {
        const result = c.Rdate_picker_is_open(@backingInt(self));
        return result != 0;
    }

    pub fn setChangedCallback(self: DatePicker, context: anytype, comptime callback: ?fn (@TypeOf(context), DatePicker, i32, i32, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, a3: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(DatePicker, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rdate_picker_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The time zone of the date, for the instants below; NULL or "" (default): the zone of the system. TimeZone="..." in XML.
    pub fn setTimeZone(self: DatePicker, zone: ?[:0]const u8) void {
        c.Rdate_picker_set_time_zone(@backingInt(self), rt.optPtr(zone));
    }

    pub fn getTimeZone(self: DatePicker) [:0]const u8 {
        const result = c.Rdate_picker_get_time_zone(@backingInt(self));
        return rt.span(result);
    }

    /// Shows the date an instant (seconds since 1970, UTC) has in the zone of the picker.
    pub fn setInstant(self: DatePicker, utc: f64) void {
        c.Rdate_picker_set_instant(@backingInt(self), utc);
    }

    /// The first instant of the date in the zone: its midnight (or, where the clocks skip midnight, the time they go to).
    pub fn getInstant(self: DatePicker) f64 {
        const result = c.Rdate_picker_get_instant(@backingInt(self));
        return result;
    }
};

/// A widget (WidgetType.time_picker).
pub const TimePicker = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?TimePicker {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: TimePicker) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a TimePicker.
    pub const widget_types = [_]WidgetType{.time_picker};

    /// The widget, for the functions of every widget.
    pub fn widget(self: TimePicker) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new TimePicker (Rwidget_create(R_WIDGET_TIME_PICKER)).
    pub fn create() TimePicker {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_TIME_PICKER));
    }

    pub fn setTime(self: TimePicker, hour: i32, minute: i32, second: i32) void {
        c.Rtime_picker_set_time(@backingInt(self), hour, minute, second);
    }

    pub fn getTime(self: TimePicker) struct { hour: i32, minute: i32, second: i32 } {
        var hour: c_int = 0;
        var minute: c_int = 0;
        var second: c_int = 0;
        c.Rtime_picker_get_time(@backingInt(self), &hour, &minute, &second);
        return .{ .hour = hour, .minute = minute, .second = second };
    }

    pub fn setSecondsVisible(self: TimePicker, visible: bool) void {
        c.Rtime_picker_set_seconds_visible(@backingInt(self), @intFromBool(visible));
    }

    /// Step of the minutes for the arrows and the wheel (default 1).
    pub fn setMinuteStep(self: TimePicker, step: i32) void {
        c.Rtime_picker_set_minute_step(@backingInt(self), step);
    }

    pub fn setChangedCallback(self: TimePicker, context: anytype, comptime callback: ?fn (@TypeOf(context), TimePicker, i32, i32, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, a3: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(TimePicker, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rtime_picker_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// 12 or 24 hours for this picker; R_CLOCK_AUTO (default): the clock of the locale. Clock="Auto|12|24" in XML.
    pub fn setClock(self: TimePicker, clock: Clock) void {
        c.Rtime_picker_set_clock(@backingInt(self), @backingInt(clock));
    }

    pub fn getClock(self: TimePicker) Clock {
        const result = c.Rtime_picker_get_clock(@backingInt(self));
        return @as(Clock, @fromBackingInt(result));
    }

    /// The time as the field shows it: "3:05 PM", "15:05", with the zone when it is shown (valid until the next call).
    pub fn getText(self: TimePicker) [:0]const u8 {
        const result = c.Rtime_picker_get_text(@backingInt(self));
        return rt.span(result);
    }

    /// The time zone of the time ("America/New_York", see
    /// Rtimezone_is_valid); NULL or "" (default): the zone of the system. An
    /// unknown zone is refused. TimeZone="..." in XML.
    pub fn setTimeZone(self: TimePicker, zone: ?[:0]const u8) void {
        c.Rtime_picker_set_time_zone(@backingInt(self), rt.optPtr(zone));
    }

    /// The zone set, "" for none.
    pub fn getTimeZone(self: TimePicker) [:0]const u8 {
        const result = c.Rtime_picker_get_time_zone(@backingInt(self));
        return rt.span(result);
    }

    /// Writes the zone after the time ("EST", "CET", "UTC+3"). ShowTimeZone="true" in XML.
    pub fn setTimeZoneVisible(self: TimePicker, visible: bool) void {
        c.Rtime_picker_set_time_zone_visible(@backingInt(self), @intFromBool(visible));
    }

    /// The day of the time, for its zone (month 1 to 12); year 0: today (default). Date="YYYY-MM-DD" in XML.
    pub fn setDate(self: TimePicker, year: i32, month: i32, day: i32) void {
        c.Rtime_picker_set_date(@backingInt(self), year, month, day);
    }

    pub fn getDate(self: TimePicker) struct { year: i32, month: i32, day: i32 } {
        var year: c_int = 0;
        var month: c_int = 0;
        var day: c_int = 0;
        c.Rtime_picker_get_date(@backingInt(self), &year, &month, &day);
        return .{ .year = year, .month = month, .day = day };
    }

    /// Shows an instant (seconds since 1970, UTC) in the zone of the picker: its day and its time.
    pub fn setInstant(self: TimePicker, utc: f64) void {
        c.Rtime_picker_set_instant(@backingInt(self), utc);
    }

    /// The instant the day and the time are in the zone. A time the
    /// clocks skipped is moved forward, a time they repeated is the first
    /// (see Rtimezone_from_local).
    pub fn getInstant(self: TimePicker) f64 {
        const result = c.Rtime_picker_get_instant(@backingInt(self));
        return result;
    }
};

/// A widget (WidgetType.toast).
pub const Toast = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Toast {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Toast) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Toast.
    pub const widget_types = [_]WidgetType{.toast};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Toast) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Toast (Rwidget_create(R_WIDGET_TOAST)).
    pub fn create() Toast {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_TOAST));
    }

    /// Shows a message for `seconds` (0 or less: until Rtoast_hide), with the kind and button set now.
    pub fn show(self: Toast, text: [:0]const u8, seconds: f64) void {
        c.Rtoast_show(@backingInt(self), text.ptr, seconds);
    }

    /// Same, with a kind of its own (the kind set by Rtoast_set_kind is left as it is).
    pub fn showKind(self: Toast, text: [:0]const u8, kind: ToastKind, seconds: f64) void {
        c.Rtoast_show_kind(@backingInt(self), text.ptr, @backingInt(kind), seconds);
    }

    /// Hides the newest message shown; the next one waiting comes.
    pub fn hide(self: Toast) void {
        c.Rtoast_hide(@backingInt(self));
    }

    /// Hides every message, and forgets those waiting.
    pub fn clear(self: Toast) void {
        c.Rtoast_clear(@backingInt(self));
    }

    pub fn isShown(self: Toast) bool {
        const result = c.Rtoast_is_shown(@backingInt(self));
        return result != 0;
    }

    /// Returns: The messages shown and waiting.
    pub fn getCount(self: Toast) i32 {
        const result = c.Rtoast_get_count(@backingInt(self));
        return result;
    }

    /// Returns: The newest message shown (the last one, once hidden; the clicked one in the action callback).
    pub fn getText(self: Toast) [:0]const u8 {
        const result = c.Rtoast_get_text(@backingInt(self));
        return rt.span(result);
    }

    pub fn setQueue(self: Toast, queue: ToastQueue) void {
        c.Rtoast_set_queue(@backingInt(self), @backingInt(queue));
    }

    pub fn getQueue(self: Toast) ToastQueue {
        const result = c.Rtoast_get_queue(@backingInt(self));
        return @as(ToastQueue, @fromBackingInt(result));
    }

    /// How many messages a R_TOAST_STACK shows at once (default 3).
    pub fn setMaxVisible(self: Toast, count: i32) void {
        c.Rtoast_set_max_visible(@backingInt(self), count);
    }

    /// The kind of the next messages (and of the message shown, with R_TOAST_REPLACE).
    pub fn setKind(self: Toast, kind: ToastKind) void {
        c.Rtoast_set_kind(@backingInt(self), @backingInt(kind));
    }

    /// A button at the end of the next messages ("Undo"); NULL or "" removes it.
    pub fn setActionText(self: Toast, text: ?[:0]const u8) void {
        c.Rtoast_set_action_text(@backingInt(self), rt.optPtr(text));
    }

    pub fn setActionCallback(self: Toast, context: anytype, comptime callback: ?fn (@TypeOf(context), Toast) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Toast, @fromBackingInt(a0)));
            }
        };
        c.Rtoast_set_action_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.breadcrumb).
pub const Breadcrumb = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Breadcrumb {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Breadcrumb) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Breadcrumb.
    pub const widget_types = [_]WidgetType{.breadcrumb};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Breadcrumb) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Breadcrumb (Rwidget_create(R_WIDGET_BREADCRUMB)).
    pub fn create() Breadcrumb {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_BREADCRUMB));
    }

    /// Replaces the items: their texts separated by '|'.
    pub fn setItems(self: Breadcrumb, items: [:0]const u8) void {
        c.Rbreadcrumb_set_items(@backingInt(self), items.ptr);
    }

    /// Returns: The index of the new item, at the end.
    pub fn addItem(self: Breadcrumb, text: [:0]const u8) i32 {
        const result = c.Rbreadcrumb_add_item(@backingInt(self), text.ptr);
        return result;
    }

    /// Keeps the first `count` items: Rbreadcrumb_truncate(b, index + 1) goes back to the item clicked.
    pub fn truncate(self: Breadcrumb, count: i32) void {
        c.Rbreadcrumb_truncate(@backingInt(self), count);
    }

    pub fn getItemCount(self: Breadcrumb) i32 {
        const result = c.Rbreadcrumb_get_item_count(@backingInt(self));
        return result;
    }

    pub fn getItemText(self: Breadcrumb, index: i32) [:0]const u8 {
        const result = c.Rbreadcrumb_get_item_text(@backingInt(self), index);
        return rt.span(result);
    }

    pub fn setClickedCallback(self: Breadcrumb, context: anytype, comptime callback: ?fn (@TypeOf(context), Breadcrumb, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Breadcrumb, @fromBackingInt(a0)), a1);
            }
        };
        c.Rbreadcrumb_set_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.rating).
pub const Rating = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Rating {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Rating) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Rating.
    pub const widget_types = [_]WidgetType{.rating};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Rating) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Rating (Rwidget_create(R_WIDGET_RATING)).
    pub fn create() Rating {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_RATING));
    }

    /// The score, from 0 to the number of stars.
    pub fn setValue(self: Rating, value: f32) void {
        c.Rrating_set_value(@backingInt(self), value);
    }

    pub fn getValue(self: Rating) f32 {
        const result = c.Rrating_get_value(@backingInt(self));
        return result;
    }

    /// Number of stars (default 5, at most 20).
    pub fn setMax(self: Rating, max: i32) void {
        c.Rrating_set_max(@backingInt(self), max);
    }

    pub fn getMax(self: Rating) i32 {
        const result = c.Rrating_get_max(@backingInt(self));
        return result;
    }

    /// Half stars can be chosen (a whole star by default).
    pub fn setAllowHalf(self: Rating, allow: i32) void {
        c.Rrating_set_allow_half(@backingInt(self), allow);
    }

    /// Shown only, the user cannot change it.
    pub fn setReadOnly(self: Rating, read_only: bool) void {
        c.Rrating_set_read_only(@backingInt(self), @intFromBool(read_only));
    }

    /// Size of a star (default 18).
    pub fn setStarSize(self: Rating, size: f32) void {
        c.Rrating_set_star_size(@backingInt(self), size);
    }

    pub fn setChangedCallback(self: Rating, context: anytype, comptime callback: ?fn (@TypeOf(context), Rating, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Rating, @fromBackingInt(a0)), a1);
            }
        };
        c.Rrating_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.pagination).
pub const Pagination = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Pagination {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Pagination) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Pagination.
    pub const widget_types = [_]WidgetType{.pagination};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Pagination) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Pagination (Rwidget_create(R_WIDGET_PAGINATION)).
    pub fn create() Pagination {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_PAGINATION));
    }

    pub fn setPageCount(self: Pagination, count: i32) void {
        c.Rpagination_set_page_count(@backingInt(self), count);
    }

    pub fn getPageCount(self: Pagination) i32 {
        const result = c.Rpagination_get_page_count(@backingInt(self));
        return result;
    }

    pub fn setPage(self: Pagination, page: i32) void {
        c.Rpagination_set_page(@backingInt(self), page);
    }

    pub fn getPage(self: Pagination) i32 {
        const result = c.Rpagination_get_page(@backingInt(self));
        return result;
    }

    /// Page numbers shown around the current one (default 1).
    pub fn setSiblings(self: Pagination, siblings: i32) void {
        c.Rpagination_set_siblings(@backingInt(self), siblings);
    }

    pub fn setChangedCallback(self: Pagination, context: anytype, comptime callback: ?fn (@TypeOf(context), Pagination, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Pagination, @fromBackingInt(a0)), a1);
            }
        };
        c.Rpagination_set_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.plot).
pub const Plot = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Plot {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Plot) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Plot.
    pub const widget_types = [_]WidgetType{.plot};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Plot) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new Plot (Rwidget_create(R_WIDGET_PLOT)).
    pub fn create() Plot {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_PLOT));
    }

    pub fn setTitle(self: Plot, title: [:0]const u8) void {
        c.Rplot_set_title(@backingInt(self), title.ptr);
    }

    pub fn getTitle(self: Plot) [:0]const u8 {
        const result = c.Rplot_get_title(@backingInt(self));
        return rt.span(result);
    }

    /// Adds a series (its name in the legend; NULL or "": not in the legend). Returns its index.
    pub fn addSeries(self: Plot, name: ?[:0]const u8) i32 {
        const result = c.Rplot_add_series(@backingInt(self), rt.optPtr(name));
        return result;
    }

    pub fn removeSeries(self: Plot, series: i32) void {
        c.Rplot_remove_series(@backingInt(self), series);
    }

    /// Removes every series and every drag line.
    pub fn clear(self: Plot) void {
        c.Rplot_clear(@backingInt(self));
    }

    pub fn getSeriesCount(self: Plot) i32 {
        const result = c.Rplot_get_series_count(@backingInt(self));
        return result;
    }

    pub fn setSeriesName(self: Plot, series: i32, name: [:0]const u8) void {
        c.Rplot_set_series_name(@backingInt(self), series, name.ptr);
    }

    pub fn getSeriesName(self: Plot, series: i32) [:0]const u8 {
        const result = c.Rplot_get_series_name(@backingInt(self), series);
        return rt.span(result);
    }

    /// Replaces the points of a series with `count` points, copied.
    /// x The X of the points, or NULL: 0, 1, 2...
    /// y The Y of the points. NaN leaves a gap in the line.
    pub fn setSeriesData(self: Plot, series: i32, x: []const f64, y: []const f64) void {
        std.debug.assert(y.len == x.len);
        c.Rplot_set_series_data(@backingInt(self), series, x.ptr, y.ptr, @intCast(x.len));
    }

    /// Adds points after those of a series (x NULL: numbered after the last one).
    pub fn appendSeriesData(self: Plot, series: i32, x: []const f64, y: []const f64) void {
        std.debug.assert(y.len == x.len);
        c.Rplot_append_series_data(@backingInt(self), series, x.ptr, y.ptr, @intCast(x.len));
    }

    /// Adds one point after those of a series.
    pub fn addPoint(self: Plot, series: i32, x: f64, y: f64) void {
        c.Rplot_add_point(@backingInt(self), series, x, y);
    }

    pub fn clearSeriesData(self: Plot, series: i32) void {
        c.Rplot_clear_series_data(@backingInt(self), series);
    }

    pub fn getPointCount(self: Plot, series: i32) i32 {
        const result = c.Rplot_get_point_count(@backingInt(self), series);
        return result;
    }

    /// One point of a series. Returns R_FALSE when there is no such point.
    pub fn getPoint(self: Plot, series: i32, index: i32) ?struct { x: f64, y: f64 } {
        var x: f64 = 0;
        var y: f64 = 0;
        if (c.Rplot_get_point(@backingInt(self), series, index, &x, &y) == 0) return null;
        return .{ .x = x, .y = y };
    }

    /// Keeps only the last `max` points of a series, for data that streams in (0: all of them, the default).
    pub fn setSeriesMaxPoints(self: Plot, series: i32, max: i32) void {
        c.Rplot_set_series_max_points(@backingInt(self), series, max);
    }

    /// The color of a series (by default the next one of a palette of ten).
    pub fn setSeriesColor(self: Plot, series: i32, color: Color) void {
        c.Rplot_set_series_color(@backingInt(self), series, color.r, color.g, color.b, color.a);
    }

    /// How the line is drawn and how wide (default solid, 1.75; width 0 keeps the width).
    pub fn setSeriesLine(self: Plot, series: i32, line: PlotLine, width: f32) void {
        c.Rplot_set_series_line(@backingInt(self), series, @backingInt(line), width);
    }

    /// The mark on each point and its radius (default none, 4; size 0 keeps the size).
    pub fn setSeriesMarker(self: Plot, series: i32, marker: PlotMarker, size: f32) void {
        c.Rplot_set_series_marker(@backingInt(self), series, @backingInt(marker), size);
    }

    /// Filled markers (the default) or only their outline.
    pub fn setSeriesMarkerFilled(self: Plot, series: i32, filled: i32) void {
        c.Rplot_set_series_marker_filled(@backingInt(self), series, filled);
    }

    /// Draws the line in steps: along at the height of a point, then up or down to the next.
    pub fn setSeriesStep(self: Plot, series: i32, step: i32) void {
        c.Rplot_set_series_step(@backingInt(self), series, step);
    }

    /// Shades the area between the line and zero, at this opacity (0: none, the default).
    pub fn setSeriesFill(self: Plot, series: i32, opacity: f32) void {
        c.Rplot_set_series_fill(@backingInt(self), series, opacity);
    }

    /// The axes a series is drawn against: R_PLOT_X or R_PLOT_X2, R_PLOT_Y or R_PLOT_Y2.
    pub fn setSeriesAxes(self: Plot, series: i32, x_axis: PlotAxis, y_axis: PlotAxis) void {
        c.Rplot_set_series_axes(@backingInt(self), series, @backingInt(x_axis), @backingInt(y_axis));
    }

    /// Shows or hides a series (the user does it with a click on its name in the legend).
    pub fn setSeriesVisible(self: Plot, series: i32, visible: bool) void {
        c.Rplot_set_series_visible(@backingInt(self), series, @intFromBool(visible));
    }

    pub fn isSeriesVisible(self: Plot, series: i32) bool {
        const result = c.Rplot_is_series_visible(@backingInt(self), series);
        return result != 0;
    }

    /// The name written along an axis.
    pub fn setAxisLabel(self: Plot, axis: PlotAxis, label: [:0]const u8) void {
        c.Rplot_set_axis_label(@backingInt(self), @backingInt(axis), label.ptr);
    }

    pub fn getAxisLabel(self: Plot, axis: PlotAxis) [:0]const u8 {
        const result = c.Rplot_get_axis_label(@backingInt(self), @backingInt(axis));
        return rt.span(result);
    }

    pub fn setAxisScale(self: Plot, axis: PlotAxis, scale: PlotScale) void {
        c.Rplot_set_axis_scale(@backingInt(self), @backingInt(axis), @backingInt(scale));
    }

    pub fn getAxisScale(self: Plot, axis: PlotAxis) PlotScale {
        const result = c.Rplot_get_axis_scale(@backingInt(self), @backingInt(axis));
        return @as(PlotScale, @fromBackingInt(result));
    }

    /// R_PLOT_SCALE_SYMLOG: the axis is linear from -threshold to threshold (default 1).
    pub fn setAxisLinearThreshold(self: Plot, axis: PlotAxis, threshold: f64) void {
        c.Rplot_set_axis_linear_threshold(@backingInt(self), @backingInt(axis), threshold);
    }

    /// Shows this range of an axis; the axis then stops following the data.
    pub fn setAxisRange(self: Plot, axis: PlotAxis, min: f64, max: f64) void {
        c.Rplot_set_axis_range(@backingInt(self), @backingInt(axis), min, max);
    }

    /// The range an axis shows now (after the user moved or zoomed it).
    pub fn getAxisRange(self: Plot, axis: PlotAxis) struct { min: f64, max: f64 } {
        var min: f64 = 0;
        var max: f64 = 0;
        c.Rplot_get_axis_range(@backingInt(self), @backingInt(axis), &min, &max);
        return .{ .min = min, .max = max };
    }

    /// The axis is fitted to the data whenever it changes (the default, until the view is moved; a double click turns it on again).
    pub fn setAxisAutoFit(self: Plot, axis: PlotAxis, auto_fit: i32) void {
        c.Rplot_set_axis_auto_fit(@backingInt(self), @backingInt(axis), auto_fit);
    }

    pub fn isAxisAutoFit(self: Plot, axis: PlotAxis) bool {
        const result = c.Rplot_is_axis_auto_fit(@backingInt(self), @backingInt(axis));
        return result != 0;
    }

    /// How the labels of an axis are written: a printf format for one double ("%.1f s", "%g"), NULL: chosen from the ticks.
    pub fn setAxisFormat(self: Plot, axis: PlotAxis, format: ?[:0]const u8) void {
        c.Rplot_set_axis_format(@backingInt(self), @backingInt(axis), rt.optPtr(format));
    }

    /// 1: shown, 0: hidden, -1: R_PLOT_X and R_PLOT_Y always, the second axes when something uses them (the default).
    pub fn setAxisVisible(self: Plot, axis: PlotAxis, visible: bool) void {
        c.Rplot_set_axis_visible(@backingInt(self), @backingInt(axis), @intFromBool(visible));
    }

    /// Lines across the data at the ticks of an axis (on for R_PLOT_X and R_PLOT_Y).
    pub fn setAxisGrid(self: Plot, axis: PlotAxis, grid: i32) void {
        c.Rplot_set_axis_grid(@backingInt(self), @backingInt(axis), grid);
    }

    /// The values grow the other way (to the left, or down).
    pub fn setAxisInverted(self: Plot, axis: PlotAxis, inverted: i32) void {
        c.Rplot_set_axis_inverted(@backingInt(self), @backingInt(axis), inverted);
    }

    /// The user cannot move or zoom this axis (the application still can).
    pub fn setAxisLocked(self: Plot, axis: PlotAxis, locked: i32) void {
        c.Rplot_set_axis_locked(@backingInt(self), @backingInt(axis), locked);
    }

    /// Fits every axis that is not locked to the data, and has them follow it again (what a double click does).
    pub fn fit(self: Plot) void {
        c.Rplot_fit(@backingInt(self));
    }

    /// Where the legend is (default R_PLOT_LEGEND_TOP_RIGHT).
    pub fn setLegend(self: Plot, legend: PlotLegend) void {
        c.Rplot_set_legend(@backingInt(self), @backingInt(legend));
    }

    /// Lines across the data through the pointer.
    pub fn setCrosshair(self: Plot, crosshair: i32) void {
        c.Rplot_set_crosshair(@backingInt(self), crosshair);
    }

    /// The coordinates of the pointer in a corner of the data (on by default).
    pub fn setMouseText(self: Plot, shown: bool) void {
        c.Rplot_set_mouse_text(@backingInt(self), @intFromBool(shown));
    }

    /// The values of the point under the pointer, written next to it (on by default).
    pub fn setTooltips(self: Plot, shown: bool) void {
        c.Rplot_set_tooltips(@backingInt(self), @intFromBool(shown));
    }

    /// Where the pointer is, in the units of R_PLOT_X and R_PLOT_Y. Returns R_TRUE when it is over the data.
    pub fn getMousePosition(self: Plot) ?struct { x: f64, y: f64 } {
        var x: f64 = 0;
        var y: f64 = 0;
        if (c.Rplot_get_mouse_position(@backingInt(self), &x, &y) == 0) return null;
        return .{ .x = x, .y = y };
    }

    /// Where a point of the data (R_PLOT_X, R_PLOT_Y) is in the widget, in logical units from its corner.
    pub fn dataToPoint(self: Plot, x: f64, y: f64) struct { point_x: f32, point_y: f32 } {
        var point_x: f32 = 0;
        var point_y: f32 = 0;
        c.Rplot_data_to_point(@backingInt(self), x, y, &point_x, &point_y);
        return .{ .point_x = point_x, .point_y = point_y };
    }

    /// The data (R_PLOT_X, R_PLOT_Y) at a point of the widget, in logical units from its corner.
    pub fn pointToData(self: Plot, point_x: f32, point_y: f32) struct { x: f64, y: f64 } {
        var x: f64 = 0;
        var y: f64 = 0;
        c.Rplot_point_to_data(@backingInt(self), point_x, point_y, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Adds a line across the data that the user drags: vertical at an X
    /// (axis R_PLOT_X or R_PLOT_X2), horizontal at a Y (R_PLOT_Y or R_PLOT_Y2).
    /// Its value is written on it, after `label` (may be NULL). Returns its index.
    pub fn addDragLine(self: Plot, axis: PlotAxis, value: f64, label: ?[:0]const u8) i32 {
        const result = c.Rplot_add_drag_line(@backingInt(self), @backingInt(axis), value, rt.optPtr(label));
        return result;
    }

    pub fn removeDragLine(self: Plot, line: i32) void {
        c.Rplot_remove_drag_line(@backingInt(self), line);
    }

    pub fn getDragLineCount(self: Plot) i32 {
        const result = c.Rplot_get_drag_line_count(@backingInt(self));
        return result;
    }

    pub fn setDragLineValue(self: Plot, line: i32, value: f64) void {
        c.Rplot_set_drag_line_value(@backingInt(self), line, value);
    }

    pub fn getDragLineValue(self: Plot, line: i32) f64 {
        const result = c.Rplot_get_drag_line_value(@backingInt(self), line);
        return result;
    }

    /// The color of a drag line (by default the accent of the theme).
    pub fn setDragLineColor(self: Plot, line: i32, color: Color) void {
        c.Rplot_set_drag_line_color(@backingInt(self), line, color.r, color.g, color.b, color.a);
    }

    pub fn setViewChangedCallback(self: Plot, context: anytype, comptime callback: ?fn (@TypeOf(context), Plot) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Plot, @fromBackingInt(a0)));
            }
        };
        c.Rplot_set_view_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setDragLineCallback(self: Plot, context: anytype, comptime callback: ?fn (@TypeOf(context), Plot, i32, f64) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f64, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Plot, @fromBackingInt(a0)), a1, a2);
            }
        };
        c.Rplot_set_drag_line_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setSeriesToggledCallback(self: Plot, context: anytype, comptime callback: ?fn (@TypeOf(context), Plot, i32, bool) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Plot, @fromBackingInt(a0)), a1, a2 != 0);
            }
        };
        c.Rplot_set_series_toggled_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.pdf_view).
pub const PdfView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?PdfView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: PdfView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a PdfView.
    pub const widget_types = [_]WidgetType{.pdf_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: PdfView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A new PdfView (Rwidget_create(R_WIDGET_PDF_VIEW)).
    pub fn create() PdfView {
        return @fromBackingInt(c.Rwidget_create(c.R_WIDGET_PDF_VIEW));
    }

    /// Shows a PDF file. `password` may be NULL. Returns R_FALSE when it
    /// cannot: Rpdf_view_get_status tells why (a password is needed, not a
    /// PDF, no PDFium). The view then shows that instead of pages.
    pub fn loadFile(self: PdfView, path: ?[:0]const u8, password: ?[:0]const u8) Error!void {
        if (c.Rpdf_view_load_file(@backingInt(self), rt.optPtr(path), rt.optPtr(password)) == 0) return lastError();
    }

    /// Same as Rpdf_view_load_file, from bytes in memory (copied).
    pub fn loadMemory(self: PdfView, data: []const u8, password: [:0]const u8) Error!void {
        if (c.Rpdf_view_load_memory(@backingInt(self), @ptrCast(data.ptr), data.len, password.ptr) == 0) return lastError();
    }

    /// Closes the document: the view is empty.
    pub fn close(self: PdfView) void {
        c.Rpdf_view_close(@backingInt(self));
    }

    pub fn getStatus(self: PdfView) PdfStatus {
        const result = c.Rpdf_view_get_status(@backingInt(self));
        return @as(PdfStatus, @fromBackingInt(result));
    }

    pub fn getPageCount(self: PdfView) i32 {
        const result = c.Rpdf_view_get_page_count(@backingInt(self));
        return result;
    }

    /// Size of a page in points (1/72 inch), as it is shown (its rotation applied).
    pub fn getPageSize(self: PdfView, page: i32) struct { width: f32, height: f32 } {
        var width: f32 = 0;
        var height: f32 = 0;
        c.Rpdf_view_get_page_size(@backingInt(self), page, &width, &height);
        return .{ .width = width, .height = height };
    }

    /// Scrolls to the top of a page; it becomes the current page.
    pub fn setPage(self: PdfView, page: i32) void {
        c.Rpdf_view_set_page(@backingInt(self), page);
    }

    /// The current page: the one a third down the view.
    pub fn getPage(self: PdfView) i32 {
        const result = c.Rpdf_view_get_page(@backingInt(self));
        return result;
    }

    /// A zoom of its own (1: the printed size): the fit becomes R_PDF_FIT_NONE.
    pub fn setZoom(self: PdfView, zoom: f32) void {
        c.Rpdf_view_set_zoom(@backingInt(self), zoom);
    }

    /// The zoom the pages show at, the one a fit gives included.
    pub fn getZoom(self: PdfView) f32 {
        const result = c.Rpdf_view_get_zoom(@backingInt(self));
        return result;
    }

    pub fn setFit(self: PdfView, fit: PdfFit) void {
        c.Rpdf_view_set_fit(@backingInt(self), @backingInt(fit));
    }

    pub fn getFit(self: PdfView) PdfFit {
        const result = c.Rpdf_view_get_fit(@backingInt(self));
        return @as(PdfFit, @fromBackingInt(result));
    }

    /// The title of the document (its information), "" when it has none.
    pub fn getTitle(self: PdfView) [:0]const u8 {
        const result = c.Rpdf_view_get_title(@backingInt(self));
        return rt.span(result);
    }

    /// The text of a page (UTF-8), to search it or copy it. Valid until
    /// the next call for this view.
    pub fn getPageText(self: PdfView, page: i32) [:0]const u8 {
        const result = c.Rpdf_view_get_page_text(@backingInt(self), page);
        return rt.span(result);
    }

    pub fn setPageChangedCallback(self: PdfView, context: anytype, comptime callback: ?fn (@TypeOf(context), PdfView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(PdfView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rpdf_view_set_page_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Prints the document shown (see Rpdf_print); the job is named after its title.
    pub fn print(self: PdfView, desc: PdfPrintDesc) bool {
        const raw_desc = desc.toC();
        const result = c.Rpdf_view_print(@backingInt(self), &raw_desc);
        return result != 0;
    }
};

/// A widget (WidgetType.chart).
pub const Chart = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Chart {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Chart) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Chart.
    pub const widget_types = [_]WidgetType{.chart};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Chart) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// A chart of a kind (Rwidget_create(R_WIDGET_CHART) makes a pie).
    pub fn create(kind: ChartKind) Chart {
        const result = c.Rchart_create(@backingInt(kind));
        return @fromBackingInt(result);
    }

    pub fn setKind(self: Chart, kind: ChartKind) void {
        c.Rchart_set_kind(@backingInt(self), @backingInt(kind));
    }

    pub fn getKind(self: Chart) ChartKind {
        const result = c.Rchart_get_kind(@backingInt(self));
        return @as(ChartKind, @fromBackingInt(result));
    }

    /// The title over a pie, a donut or a heatmap, under the value of a gauge (a sparkline only tells it to screen readers).
    pub fn setTitle(self: Chart, title: [:0]const u8) void {
        c.Rchart_set_title(@backingInt(self), title.ptr);
    }

    pub fn getTitle(self: Chart) [:0]const u8 {
        const result = c.Rchart_get_title(@backingInt(self));
        return rt.span(result);
    }

    /// How the values are written (the gauge, the middle of a donut, what
    /// the pointer shows): a printf format for one double with its unit, "%.0f%%",
    /// "$%.2f". NULL: whole numbers as they are, others with up to two decimals.
    pub fn setFormat(self: Chart, format: ?[:0]const u8) void {
        c.Rchart_set_format(@backingInt(self), rt.optPtr(format));
    }

    /// The color of the arc of a gauge outside any band, and of the line of a sparkline (default: the accent).
    pub fn setColor(self: Chart, color: Color) void {
        c.Rchart_set_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// The legend: the slices beside a pie or a donut, the scale of colors under a heatmap (shown by default).
    pub fn setLegend(self: Chart, shown: bool) void {
        c.Rchart_set_legend(@backingInt(self), @intFromBool(shown));
    }

    /// Removes the slices, the bands, the grid and the values.
    pub fn clear(self: Chart) void {
        c.Rchart_clear(@backingInt(self));
    }

    /// What is under the pointer: a slice, a point of a sparkline, or a
    /// cell of a heatmap as row * columns + column; -1 for nothing.
    pub fn getHovered(self: Chart) i32 {
        const result = c.Rchart_get_hovered(@backingInt(self));
        return result;
    }

    /// Adds a slice (a value of 0 or more). Returns its index, -1 when the value is not valid.
    pub fn addSlice(self: Chart, label: [:0]const u8, value: f64) i32 {
        const result = c.Rchart_add_slice(@backingInt(self), label.ptr, value);
        return result;
    }

    pub fn removeSlice(self: Chart, slice: i32) void {
        c.Rchart_remove_slice(@backingInt(self), slice);
    }

    pub fn getSliceCount(self: Chart) i32 {
        const result = c.Rchart_get_slice_count(@backingInt(self));
        return result;
    }

    pub fn setSliceValue(self: Chart, slice: i32, value: f64) void {
        c.Rchart_set_slice_value(@backingInt(self), slice, value);
    }

    pub fn getSliceValue(self: Chart, slice: i32) f64 {
        const result = c.Rchart_get_slice_value(@backingInt(self), slice);
        return result;
    }

    pub fn setSliceLabel(self: Chart, slice: i32, label: [:0]const u8) void {
        c.Rchart_set_slice_label(@backingInt(self), slice, label.ptr);
    }

    pub fn getSliceLabel(self: Chart, slice: i32) [:0]const u8 {
        const result = c.Rchart_get_slice_label(@backingInt(self), slice);
        return rt.span(result);
    }

    /// The color of a slice; an alpha of 0 gives it back its color of the palette.
    pub fn setSliceColor(self: Chart, slice: i32, color: Color) void {
        c.Rchart_set_slice_color(@backingInt(self), slice, color.r, color.g, color.b, color.a);
    }

    /// The sum of the values of the slices.
    pub fn getTotal(self: Chart) f64 {
        const result = c.Rchart_get_total(@backingInt(self));
        return result;
    }

    /// The slice lifted as selected, or -1 for none (the user selects one with a click).
    pub fn setSelected(self: Chart, slice: i32) void {
        c.Rchart_set_selected(@backingInt(self), slice);
    }

    pub fn getSelected(self: Chart) i32 {
        const result = c.Rchart_get_selected(@backingInt(self));
        return result;
    }

    /// The hole of a donut, as a part of its radius, from 0.2 to 0.9 (default 0.62).
    pub fn setHole(self: Chart, ratio: f32) void {
        c.Rchart_set_hole(@backingInt(self), ratio);
    }

    /// What the middle of a donut shows when the pointer is not over a
    /// slice: `text` in large (NULL or "": the total) over `caption` in small
    /// (NULL or "": none).
    pub fn setCenterText(self: Chart, text: ?[:0]const u8, caption: ?[:0]const u8) void {
        c.Rchart_set_center_text(@backingInt(self), rt.optPtr(text), rt.optPtr(caption));
    }

    pub fn setSliceClickedCallback(self: Chart, context: anytype, comptime callback: ?fn (@TypeOf(context), Chart, i32, bool) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Chart, @fromBackingInt(a0)), a1, a2 != 0);
            }
        };
        c.Rchart_set_slice_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The range of a gauge (default 0 to 100), and a fixed range for the
    /// colors of a heatmap and the height of a sparkline, which otherwise follow
    /// their values. min == max goes back to these defaults.
    pub fn setRange(self: Chart, min: f64, max: f64) void {
        c.Rchart_set_range(@backingInt(self), min, max);
    }

    /// The range in use now (a gauge's, or the one of the values of a heatmap or a sparkline).
    pub fn getRange(self: Chart) struct { min: f64, max: f64 } {
        var min: f64 = 0;
        var max: f64 = 0;
        c.Rchart_get_range(@backingInt(self), &min, &max);
        return .{ .min = min, .max = max };
    }

    /// The value of a gauge, kept within its range when drawn.
    pub fn setValue(self: Chart, value: f64) void {
        c.Rchart_set_value(@backingInt(self), value);
    }

    pub fn getValue(self: Chart) f64 {
        const result = c.Rchart_get_value(@backingInt(self));
        return result;
    }

    /// Colors a part of the range of a gauge (an alpha of 0: the success,
    /// warning and danger colors of the theme, one after the other). The arc
    /// takes the color of the band its value is in. Returns the index of the band.
    pub fn addBand(self: Chart, from: f64, to: f64, color: Color) i32 {
        const result = c.Rchart_add_band(@backingInt(self), from, to, color.r, color.g, color.b, color.a);
        return result;
    }

    pub fn clearBands(self: Chart) void {
        c.Rchart_clear_bands(@backingInt(self));
    }

    pub fn getBandCount(self: Chart) i32 {
        const result = c.Rchart_get_band_count(@backingInt(self));
        return result;
    }

    /// The cells of a heatmap: `rows` x `columns` values, row after row,
    /// copied (NULL: all 0). NaN leaves a cell empty.
    pub fn setGrid(self: Chart, rows: i32, columns: i32, values: []const f32) void {
        std.debug.assert(values.len >= @as(usize, @intCast(rows)) * @as(usize, @intCast(columns)));
        c.Rchart_set_grid(@backingInt(self), rows, columns, values.ptr);
    }

    pub fn getRowCount(self: Chart) i32 {
        const result = c.Rchart_get_row_count(@backingInt(self));
        return result;
    }

    pub fn getColumnCount(self: Chart) i32 {
        const result = c.Rchart_get_column_count(@backingInt(self));
        return result;
    }

    pub fn setCell(self: Chart, row: i32, column: i32, value: f32) void {
        c.Rchart_set_cell(@backingInt(self), row, column, value);
    }

    pub fn getCell(self: Chart, row: i32, column: i32) f32 {
        const result = c.Rchart_get_cell(@backingInt(self), row, column);
        return result;
    }

    /// The names of the rows, separated by '|': "Mon|Tue|Wed" (shown at their left).
    pub fn setRowLabels(self: Chart, labels: [:0]const u8) void {
        c.Rchart_set_row_labels(@backingInt(self), labels.ptr);
    }

    /// The names of the columns, separated by '|' (shown over them, as many as fit).
    pub fn setColumnLabels(self: Chart, labels: [:0]const u8) void {
        c.Rchart_set_column_labels(@backingInt(self), labels.ptr);
    }

    /// The name of a row or of a column, "" when it has none.
    pub fn getRowLabel(self: Chart, row: i32) [:0]const u8 {
        const result = c.Rchart_get_row_label(@backingInt(self), row);
        return rt.span(result);
    }

    pub fn getColumnLabel(self: Chart, column: i32) [:0]const u8 {
        const result = c.Rchart_get_column_label(@backingInt(self), column);
        return rt.span(result);
    }

    /// The colors of the lowest and of the highest values of a heatmap (default: a tint of the accent, the accent).
    pub fn setColorScale(self: Chart, low_r: f32, low_g: f32, low_b: f32, low_a: f32, high_r: f32, high_g: f32, high_b: f32, high_a: f32) void {
        c.Rchart_set_color_scale(@backingInt(self), low_r, low_g, low_b, low_a, high_r, high_g, high_b, high_a);
    }

    pub fn setCellClickedCallback(self: Chart, context: anytype, comptime callback: ?fn (@TypeOf(context), Chart, i32, i32, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, a3: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Chart, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rchart_set_cell_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The values of a sparkline, copied. NaN leaves a gap.
    pub fn setValues(self: Chart, values: []const f32) void {
        c.Rchart_set_values(@backingInt(self), values.ptr, @intCast(values.len));
    }

    /// Adds a value after the others, for live data; only the last `max_count` are kept (0: all of them).
    pub fn pushValue(self: Chart, value: f32, max_count: i32) void {
        c.Rchart_push_value(@backingInt(self), value, max_count);
    }

    pub fn getValueCount(self: Chart) i32 {
        const result = c.Rchart_get_value_count(@backingInt(self));
        return result;
    }

    pub fn getValueAt(self: Chart, index: i32) f32 {
        const result = c.Rchart_get_value_at(@backingInt(self), index);
        return result;
    }

    /// Shades the area under the line of a sparkline (on by default).
    pub fn setFill(self: Chart, fill: i32) void {
        c.Rchart_set_fill(@backingInt(self), fill);
    }

    /// A dot on the last value of a sparkline (on by default).
    pub fn setMarker(self: Chart, shown: bool) void {
        c.Rchart_set_marker(@backingInt(self), @intFromBool(shown));
    }
};

/// A widget (WidgetType.map_view).
pub const MapView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?MapView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: MapView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a MapView.
    pub const widget_types = [_]WidgetType{.map_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: MapView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() MapView {
        const result = c.Rmap_view_create();
        return @fromBackingInt(result);
    }

    /// Centers the map on a place. The latitude is held within +/-85.0511; the longitude wraps.
    pub fn setCenter(self: MapView, latitude: f64, longitude: f64) void {
        c.Rmap_view_set_center(@backingInt(self), latitude, longitude);
    }

    /// The place at the middle of the map (longitude from -180 to 180).
    pub fn getCenter(self: MapView) struct { latitude: f64, longitude: f64 } {
        var latitude: f64 = 0;
        var longitude: f64 = 0;
        c.Rmap_view_get_center(@backingInt(self), &latitude, &longitude);
        return .{ .latitude = latitude, .longitude = longitude };
    }

    /// The zoom: 0 shows the whole world in one tile, each step doubles the scale. Fractions are allowed.
    pub fn setZoom(self: MapView, zoom: f64) void {
        c.Rmap_view_set_zoom(@backingInt(self), zoom);
    }

    pub fn getZoom(self: MapView) f64 {
        const result = c.Rmap_view_get_zoom(@backingInt(self));
        return result;
    }

    /// The zooms the user can reach (default 0 to 19, at most 0 to 24). Tiles are asked for at whole zooms of this range.
    pub fn setZoomRange(self: MapView, min_zoom: f64, max_zoom: f64) void {
        c.Rmap_view_set_zoom_range(@backingInt(self), min_zoom, max_zoom);
    }

    pub fn getZoomRange(self: MapView) struct { min_zoom: f64, max_zoom: f64 } {
        var min_zoom: f64 = 0;
        var max_zoom: f64 = 0;
        c.Rmap_view_get_zoom_range(@backingInt(self), &min_zoom, &max_zoom);
        return .{ .min_zoom = min_zoom, .max_zoom = max_zoom };
    }

    /// Glides to a place and a zoom (at once when animations are off).
    pub fn animateTo(self: MapView, latitude: f64, longitude: f64, zoom: f64) void {
        c.Rmap_view_animate_to(@backingInt(self), latitude, longitude, zoom);
    }

    /// The place at a point of the widget.
    pub fn screenToLatlon(self: MapView, x: f32, y: f32) struct { latitude: f64, longitude: f64 } {
        var latitude: f64 = 0;
        var longitude: f64 = 0;
        c.Rmap_view_screen_to_latlon(@backingInt(self), x, y, &latitude, &longitude);
        return .{ .latitude = latitude, .longitude = longitude };
    }

    /// Where a place is in the widget (of the copies of the world side by side, the one nearest the middle).
    pub fn latlonToScreen(self: MapView, latitude: f64, longitude: f64) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        c.Rmap_view_latlon_to_screen(@backingInt(self), latitude, longitude, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Called once for each tile the map needs. Answer with
    /// Rmap_view_set_tile, Rmap_view_set_tile_data or Rmap_view_set_tile_failed,
    /// at once or later. Setting it forgets the tiles of the previous source.
    pub fn setTileCallback(self: MapView, context: anytype, comptime callback: ?fn (@TypeOf(context), MapView, i32, i32, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, a3: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(MapView, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rmap_view_set_tile_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when a tile asked for and not answered yet is no longer wanted (the user went elsewhere). Optional.
    pub fn setTileCancelCallback(self: MapView, context: anytype, comptime callback: ?fn (@TypeOf(context), MapView, i32, i32, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, a3: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(MapView, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rmap_view_set_tile_cancel_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The pixels of a tile: `width` x `height` RGBA8, tightly packed
    /// (they are copied; any size, shown at the tile size). Thread-safe: from
    /// another thread it is applied on the UI thread during the next frame.
    pub fn setTile(self: MapView, z: i32, x: i32, y: i32, rgba: []const u8, width: i32, height: i32) void {
        std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
        c.Rmap_view_set_tile(@backingInt(self), z, x, y, rgba.ptr, width, height);
    }

    /// A tile as the bytes of an image file (PNG, JPEG...), decoded on the calling thread. Thread-safe.
    pub fn setTileData(self: MapView, z: i32, x: i32, y: i32, data: []const u8) void {
        c.Rmap_view_set_tile_data(@backingInt(self), z, x, y, @ptrCast(data.ptr), data.len);
    }

    /// There is no such tile: the coarser one stays shown in its place. Thread-safe.
    pub fn setTileFailed(self: MapView, z: i32, x: i32, y: i32) void {
        c.Rmap_view_set_tile_failed(@backingInt(self), z, x, y);
    }

    /// Reads the tiles from files instead of asking for them: a path
    /// where {z}, {x} and {y} are replaced ({-y}: the row counted from the
    /// south, as in TMS and MBTiles). The files are read and decoded on a
    /// worker thread; a missing file is a tile that failed. NULL or "": the
    /// tile callback again. Local files only.
    pub fn setTilePath(self: MapView, path_template: ?[:0]const u8) void {
        c.Rmap_view_set_tile_path(@backingInt(self), rt.optPtr(path_template));
    }

    pub fn getTilePath(self: MapView) [:0]const u8 {
        const result = c.Rmap_view_get_tile_path(@backingInt(self));
        return rt.span(result);
    }

    /// Logical size of a tile at a whole zoom (default 256, from 16 to 1024): larger tiles show the map larger.
    pub fn setTileSize(self: MapView, size: i32) void {
        c.Rmap_view_set_tile_size(@backingInt(self), size);
    }

    pub fn getTileSize(self: MapView) i32 {
        const result = c.Rmap_view_get_tile_size(@backingInt(self));
        return result;
    }

    /// Memory the decoded tiles may take, in bytes (default 64 MiB). The tiles on screen are always kept.
    pub fn setCacheSize(self: MapView, bytes: usize) void {
        c.Rmap_view_set_cache_size(@backingInt(self), bytes);
    }

    /// Memory the decoded tiles take now, in bytes.
    pub fn getCacheUsage(self: MapView) usize {
        const result = c.Rmap_view_get_cache_usage(@backingInt(self));
        return result;
    }

    /// Forgets every tile (they are asked for again): the tiles of the source changed.
    pub fn clearTiles(self: MapView) void {
        c.Rmap_view_clear_tiles(@backingInt(self));
    }

    pub fn getTileState(self: MapView, z: i32, x: i32, y: i32) MapTileState {
        const result = c.Rmap_view_get_tile_state(@backingInt(self), z, x, y);
        return @as(MapTileState, @fromBackingInt(result));
    }

    /// Adds a pin at a place, with a label written next to it (may be NULL). Returns its id (from 1), or -1.
    pub fn addMarker(self: MapView, latitude: f64, longitude: f64, label: ?[:0]const u8) i32 {
        const result = c.Rmap_view_add_marker(@backingInt(self), latitude, longitude, rt.optPtr(label));
        return result;
    }

    pub fn removeMarker(self: MapView, marker: i32) void {
        c.Rmap_view_remove_marker(@backingInt(self), marker);
    }

    pub fn clearMarkers(self: MapView) void {
        c.Rmap_view_clear_markers(@backingInt(self));
    }

    pub fn getMarkerCount(self: MapView) i32 {
        const result = c.Rmap_view_get_marker_count(@backingInt(self));
        return result;
    }

    pub fn setMarkerPosition(self: MapView, marker: i32, latitude: f64, longitude: f64) void {
        c.Rmap_view_set_marker_position(@backingInt(self), marker, latitude, longitude);
    }

    pub fn setMarkerLabel(self: MapView, marker: i32, label: [:0]const u8) void {
        c.Rmap_view_set_marker_label(@backingInt(self), marker, label.ptr);
    }

    /// The color of a pin (by default the accent of the theme).
    pub fn setMarkerColor(self: MapView, marker: i32, color: Color) void {
        c.Rmap_view_set_marker_color(@backingInt(self), marker, color.r, color.g, color.b, color.a);
    }

    pub fn setMarkerClickedCallback(self: MapView, context: anytype, comptime callback: ?fn (@TypeOf(context), MapView, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(MapView, @fromBackingInt(a0)), a1);
            }
        };
        c.Rmap_view_set_marker_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setViewChangedCallback(self: MapView, context: anytype, comptime callback: ?fn (@TypeOf(context), MapView, f64, f64, f64) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: f64, a2: f64, a3: f64, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(MapView, @fromBackingInt(a0)), a1, a2, a3);
            }
        };
        c.Rmap_view_set_view_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// A line written in the bottom right corner: the credit most tile
    /// licences ask for, such as "(c) OpenStreetMap contributors". NULL or "": none.
    pub fn setAttribution(self: MapView, text: ?[:0]const u8) void {
        c.Rmap_view_set_attribution(@backingInt(self), rt.optPtr(text));
    }

    pub fn getAttribution(self: MapView) [:0]const u8 {
        const result = c.Rmap_view_get_attribution(@backingInt(self));
        return rt.span(result);
    }
};

/// A widget (WidgetType.carousel).
pub const Carousel = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Carousel {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Carousel) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a Carousel.
    pub const widget_types = [_]WidgetType{.carousel};

    /// The widget, for the functions of every widget.
    pub fn widget(self: Carousel) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() Carousel {
        const result = c.Rcarousel_create();
        return @fromBackingInt(result);
    }

    /// Shows a page, gliding to it when `animated` (and the animations
    /// are on), at once otherwise. The page changed callback is not called.
    pub fn setPage(self: Carousel, page: i32, animated: bool) void {
        c.Rcarousel_set_page(@backingInt(self), page, @intFromBool(animated));
    }

    /// The page shown, -1 when the carousel has none.
    pub fn getPage(self: Carousel) i32 {
        const result = c.Rcarousel_get_page(@backingInt(self));
        return result;
    }

    /// Its children.
    pub fn getPageCount(self: Carousel) i32 {
        const result = c.Rcarousel_get_page_count(@backingInt(self));
        return result;
    }

    /// Glides to the next / previous page; nothing at the last / first one unless it loops.
    pub fn next(self: Carousel) void {
        c.Rcarousel_next(@backingInt(self));
    }

    pub fn prev(self: Carousel) void {
        c.Rcarousel_prev(@backingInt(self));
    }

    /// R_TRUE: after the last page comes the first one, and before the first the last (default R_FALSE).
    pub fn setLoop(self: Carousel, loop: i32) void {
        c.Rcarousel_set_loop(@backingInt(self), loop);
    }

    pub fn getLoop(self: Carousel) i32 {
        const result = c.Rcarousel_get_loop(@backingInt(self));
        return result;
    }

    /// Goes to the next page by itself every `seconds` (0: never, the
    /// default); after the last page it comes back to the first. It waits
    /// while the pointer is on the carousel, while the pages are dragged and
    /// while the keyboard is in it; a page chosen by the user starts the
    /// interval again.
    pub fn setAutoplay(self: Carousel, seconds: f64) void {
        c.Rcarousel_set_autoplay(@backingInt(self), seconds);
    }

    pub fn getAutoplay(self: Carousel) f64 {
        const result = c.Rcarousel_get_autoplay(@backingInt(self));
        return result;
    }

    /// The dots along the bottom edge (the right edge when vertical), one per page (default R_TRUE).
    pub fn setIndicatorsVisible(self: Carousel, visible: bool) void {
        c.Rcarousel_set_indicators_visible(@backingInt(self), @intFromBool(visible));
    }

    pub fn getIndicatorsVisible(self: Carousel) i32 {
        const result = c.Rcarousel_get_indicators_visible(@backingInt(self));
        return result;
    }

    /// The previous / next buttons shown while the pointer is on the carousel (default R_TRUE).
    pub fn setArrowsVisible(self: Carousel, visible: bool) void {
        c.Rcarousel_set_arrows_visible(@backingInt(self), @intFromBool(visible));
    }

    pub fn getArrowsVisible(self: Carousel) i32 {
        const result = c.Rcarousel_get_arrows_visible(@backingInt(self));
        return result;
    }

    /// R_HORIZONTAL: the pages side by side (default); R_VERTICAL: one above the other.
    pub fn setOrientation(self: Carousel, orientation: Orientation) void {
        c.Rcarousel_set_orientation(@backingInt(self), @backingInt(orientation));
    }

    pub fn getOrientation(self: Carousel) Orientation {
        const result = c.Rcarousel_get_orientation(@backingInt(self));
        return @as(Orientation, @fromBackingInt(result));
    }

    pub fn setPageChangedCallback(self: Carousel, context: anytype, comptime callback: ?fn (@TypeOf(context), Carousel, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Carousel, @fromBackingInt(a0)), a1);
            }
        };
        c.Rcarousel_set_page_changed_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A widget (WidgetType.system_web_view).
pub const SystemWebView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?SystemWebView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: SystemWebView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a SystemWebView.
    pub const widget_types = [_]WidgetType{.system_web_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: SystemWebView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    /// Returns: R_TRUE when web views show pages here (the system has an engine Raven can embed, and Raven runs with a window system).
    pub fn isSupported() bool {
        const result = c.Rsystem_web_view_is_supported();
        return result != 0;
    }

    pub fn create() SystemWebView {
        const result = c.Rsystem_web_view_create();
        return @fromBackingInt(result);
    }

    /// Goes to an address ("https://...", "file:///...", "about:blank"). A file: address may read the files of its folder.
    pub fn loadUrl(self: SystemWebView, url: [:0]const u8) void {
        c.Rsystem_web_view_load_url(@backingInt(self), url.ptr);
    }

    /// Shows a file of the computer (an .html file, and what it refers to in its folder).
    pub fn loadFile(self: SystemWebView, path: [:0]const u8) void {
        c.Rsystem_web_view_load_file(@backingInt(self), path.ptr);
    }

    /// Shows HTML given as text.
    /// base_url Where the relative addresses of the text are looked
    /// for ("file:///Users/me/app/pages/", "https://example.org/"), or NULL.
    pub fn loadHtml(self: SystemWebView, html: ?[:0]const u8, base_url: ?[:0]const u8) void {
        c.Rsystem_web_view_load_html(@backingInt(self), rt.optPtr(html), rt.optPtr(base_url));
    }

    pub fn reload(self: SystemWebView) void {
        c.Rsystem_web_view_reload(@backingInt(self));
    }

    pub fn stop(self: SystemWebView) void {
        c.Rsystem_web_view_stop(@backingInt(self));
    }

    pub fn goBack(self: SystemWebView) void {
        c.Rsystem_web_view_go_back(@backingInt(self));
    }

    pub fn goForward(self: SystemWebView) void {
        c.Rsystem_web_view_go_forward(@backingInt(self));
    }

    pub fn canGoBack(self: SystemWebView) bool {
        const result = c.Rsystem_web_view_can_go_back(@backingInt(self));
        return result != 0;
    }

    pub fn canGoForward(self: SystemWebView) bool {
        const result = c.Rsystem_web_view_can_go_forward(@backingInt(self));
        return result != 0;
    }

    /// Returns: The address of the page shown (the one asked for, where unsupported). Valid until it changes.
    pub fn getUrl(self: SystemWebView) [:0]const u8 {
        const result = c.Rsystem_web_view_get_url(@backingInt(self));
        return rt.span(result);
    }

    /// Returns: The title of the page, "" when it has none. Valid until it changes.
    pub fn getTitle(self: SystemWebView) [:0]const u8 {
        const result = c.Rsystem_web_view_get_title(@backingInt(self));
        return rt.span(result);
    }

    pub fn isLoading(self: SystemWebView) bool {
        const result = c.Rsystem_web_view_is_loading(@backingInt(self));
        return result != 0;
    }

    /// Returns: Why the last page could not be shown, or "" when all is well.
    pub fn getError(self: SystemWebView) [:0]const u8 {
        const result = c.Rsystem_web_view_get_error(@backingInt(self));
        return rt.span(result);
    }

    /// Runs JavaScript in the page; the value of its last statement is
    /// the result. If it is a promise, the result is what the promise
    /// resolves to. The callback (may be NULL) always comes later, never
    /// during this call.
    pub fn runJavascript(self: SystemWebView, script: ?[:0]const u8, context: anytype, comptime callback: ?fn (@TypeOf(context), SystemWebView, [:0]const u8, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, a2: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(SystemWebView, @fromBackingInt(a0)), rt.span(a1), rt.span(a2));
            }
        };
        c.Rsystem_web_view_run_javascript(@backingInt(self), rt.optPtr(script), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setMessageCallback(self: SystemWebView, context: anytype, comptime callback: ?fn (@TypeOf(context), SystemWebView, [:0]const u8) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(SystemWebView, @fromBackingInt(a0)), rt.span(a1));
            }
        };
        c.Rsystem_web_view_set_message_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Called when something happens in the page. The action of the
    /// widget (Rwidget_set_action, OnChanged in XML) is fired as well each
    /// time the address changes.
    pub fn setEventCallback(self: SystemWebView, context: anytype, comptime callback: ?fn (@TypeOf(context), SystemWebView, SystemWebViewEvent) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.RSystemWebViewEvent, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(SystemWebView, @fromBackingInt(a0)), @as(SystemWebViewEvent, @fromBackingInt(a1)));
            }
        };
        c.Rsystem_web_view_set_event_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// The view of the system, to go further than these functions:
    /// a WKWebView* on macOS and iOS. NULL where unsupported.
    pub fn getNativeHandle(self: SystemWebView) ?*anyopaque {
        const result = c.Rsystem_web_view_get_native_handle(@backingInt(self));
        return result;
    }
};

/// A widget (WidgetType.diff_view).
pub const DiffView = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?DiffView {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: DiffView) Rid {
        return @backingInt(self);
    }

    /// The types of widget that are a DiffView.
    pub const widget_types = [_]WidgetType{.diff_view};

    /// The widget, for the functions of every widget.
    pub fn widget(self: DiffView) Widget {
        return @fromBackingInt(@backingInt(self));
    }

    pub fn create() DiffView {
        const result = c.Rdiff_view_create();
        return @fromBackingInt(result);
    }

    /// The two texts to compare (NULL: empty). Lines end with "\n" or "\r\n".
    pub fn setTexts(self: DiffView, left: ?[:0]const u8, right: ?[:0]const u8) void {
        c.Rdiff_view_set_texts(@backingInt(self), rt.optPtr(left), rt.optPtr(right));
    }

    /// Names shown over the two sides (file names, "Before" / "After"); NULL: none. Their extension chooses the colors of the code.
    pub fn setNames(self: DiffView, left_name: ?[:0]const u8, right_name: ?[:0]const u8) void {
        c.Rdiff_view_set_names(@backingInt(self), rt.optPtr(left_name), rt.optPtr(right_name));
    }

    /// Compares two files. Their paths become the names unless names
    /// were given. Returns: R_FALSE when a file cannot be read (it is compared
    /// as empty).
    pub fn loadFiles(self: DiffView, left_path: [:0]const u8, right_path: [:0]const u8) bool {
        const result = c.Rdiff_view_load_files(@backingInt(self), left_path.ptr, right_path.ptr);
        return result != 0;
    }

    /// Shows a patch (unified diff: the output of `git diff`, `diff -u`)
    /// instead of two texts: each file with its name, each hunk with its header.
    /// Returns: R_FALSE when the text holds no hunk (nothing is shown).
    pub fn setPatch(self: DiffView, patch: [:0]const u8) bool {
        const result = c.Rdiff_view_set_patch(@backingInt(self), patch.ptr);
        return result != 0;
    }

    pub fn setMode(self: DiffView, mode: DiffViewMode) void {
        c.Rdiff_view_set_mode(@backingInt(self), @backingInt(mode));
    }

    pub fn getMode(self: DiffView) DiffViewMode {
        const result = c.Rdiff_view_get_mode(@backingInt(self));
        return @as(DiffViewMode, @fromBackingInt(result));
    }

    /// Unchanged lines shown around each change (3 by default); the
    /// others are folded. A negative number shows every line.
    pub fn setContext(self: DiffView, lines: i32) void {
        c.Rdiff_view_set_context(@backingInt(self), lines);
    }

    pub fn getContext(self: DiffView) i32 {
        const result = c.Rdiff_view_get_context(@backingInt(self));
        return result;
    }

    /// How lines are compared: RDiffFlags (0 by default). Not used by a patch.
    pub fn setFlags(self: DiffView, flags: DiffFlags) void {
        c.Rdiff_view_set_flags(@backingInt(self), @as(u32, @bitCast(flags)));
    }

    pub fn getFlags(self: DiffView) DiffFlags {
        const result = c.Rdiff_view_get_flags(@backingInt(self));
        return @as(DiffFlags, @bitCast(@as(u32, result)));
    }

    /// Marks the words that changed inside a changed line (default R_TRUE).
    pub fn setWordDiff(self: DiffView, enabled: bool) void {
        c.Rdiff_view_set_word_diff(@backingInt(self), @intFromBool(enabled));
    }

    /// Shows the numbers of the lines (default R_TRUE).
    pub fn setLineNumbers(self: DiffView, visible: bool) void {
        c.Rdiff_view_set_line_numbers(@backingInt(self), @intFromBool(visible));
    }

    /// Colors the code as the text editor does: a language name of
    /// Rlanguage_register ("C", "Python", "JSON"...), "None" for plain text,
    /// NULL (default) to guess it from the extension of the names.
    pub fn setLanguage(self: DiffView, language: ?[:0]const u8) void {
        c.Rdiff_view_set_language(@backingInt(self), rt.optPtr(language));
    }

    /// The number of changes: runs of lines removed and / or added.
    pub fn getChangeCount(self: DiffView) i32 {
        const result = c.Rdiff_view_get_change_count(@backingInt(self));
        return result;
    }

    /// Where a change is: its first line and its number of lines on
    /// each side (a count of 0: nothing on that side; the line is then the one
    /// after which the other side's lines go). Returns: R_FALSE when there is
    /// no such change.
    pub fn getChange(self: DiffView, change: i32) ?struct { left_line: i32, left_count: i32, right_line: i32, right_count: i32 } {
        var left_line: c_int = 0;
        var left_count: c_int = 0;
        var right_line: c_int = 0;
        var right_count: c_int = 0;
        if (c.Rdiff_view_get_change(@backingInt(self), change, &left_line, &left_count, &right_line, &right_count) == 0) return null;
        return .{ .left_line = left_line, .left_count = left_count, .right_line = right_line, .right_count = right_count };
    }

    /// Scrolls to a change (from 0) and marks it as the current one.
    pub fn goToChange(self: DiffView, change: i32) void {
        c.Rdiff_view_go_to_change(@backingInt(self), change);
    }

    /// The current change, -1 before the first one is gone to.
    pub fn getCurrentChange(self: DiffView) i32 {
        const result = c.Rdiff_view_get_current_change(@backingInt(self));
        return result;
    }

    /// Goes to the next / previous change. Returns: Its index, -1 when there is none.
    pub fn nextChange(self: DiffView) i32 {
        const result = c.Rdiff_view_next_change(@backingInt(self));
        return result;
    }

    pub fn prevChange(self: DiffView) i32 {
        const result = c.Rdiff_view_prev_change(@backingInt(self));
        return result;
    }

    /// The rows shown, folds, hunk headers and notes included.
    pub fn getRowCount(self: DiffView) i32 {
        const result = c.Rdiff_view_get_row_count(@backingInt(self));
        return result;
    }

    /// What a row shows, and the numbers of its lines (0 for a side it
    /// has no line of). A fold gives the first line it hides on each side.
    pub fn getRow(self: DiffView, row: i32) struct { value: DiffRowKind, left_line: i32, right_line: i32 } {
        var left_line: c_int = 0;
        var right_line: c_int = 0;
        const result = c.Rdiff_view_get_row(@backingInt(self), row, &left_line, &right_line);
        return .{ .value = @as(DiffRowKind, @fromBackingInt(result)), .left_line = left_line, .right_line = right_line };
    }

    /// The text of a row on one side (in unified mode the side does not
    /// matter for a line); a fold, a hunk, a file or a note give their label.
    /// Valid until the next call. "" when there is none.
    pub fn getRowText(self: DiffView, row: i32, side: DiffSide) [:0]const u8 {
        const result = c.Rdiff_view_get_row_text(@backingInt(self), row, @backingInt(side));
        return rt.span(result);
    }

    /// Shows the lines of a fold. Returns: R_FALSE when the row is not a fold.
    pub fn expand(self: DiffView, row: i32) bool {
        const result = c.Rdiff_view_expand(@backingInt(self), row);
        return result != 0;
    }

    /// The first row at the top of the view; Rdiff_view_scroll_to_row brings one there.
    pub fn getFirstVisibleRow(self: DiffView) i32 {
        const result = c.Rdiff_view_get_first_visible_row(@backingInt(self));
        return result;
    }

    pub fn scrollToRow(self: DiffView, row: i32) void {
        c.Rdiff_view_scroll_to_row(@backingInt(self), row);
    }

    /// Attaches a short note to a line (a review comment, an error): a
    /// mark in the gutter and the text in a row under the line, which is never
    /// folded away. Several notes may go to one line.
    pub fn addAnnotation(self: DiffView, side: DiffSide, line: i32, text: [:0]const u8) void {
        c.Rdiff_view_add_annotation(@backingInt(self), @backingInt(side), line, text.ptr);
    }

    pub fn clearAnnotations(self: DiffView) void {
        c.Rdiff_view_clear_annotations(@backingInt(self));
    }

    /// The text selected by the user ("" when none), one line after another.
    pub fn getSelectedText(self: DiffView) [:0]const u8 {
        const result = c.Rdiff_view_get_selected_text(@backingInt(self));
        return rt.span(result);
    }

    /// Called when a line or its number is clicked (the action of the widget is fired too).
    pub fn setLineClickedCallback(self: DiffView, context: anytype, comptime callback: ?fn (@TypeOf(context), DiffView, DiffSide, i32, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.RDiffSide, a2: c_int, a3: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(DiffView, @fromBackingInt(a0)), @as(DiffSide, @fromBackingInt(a1)), a2, a3);
            }
        };
        c.Rdiff_view_set_line_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }
};

/// A handle of the library.
pub const Window = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Window {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Window) Rid {
        return @backingInt(self);
    }

    /// What the window shows, as RGBA pixels in memory of `allocator`.
    pub fn capture(self: Window, allocator: std.mem.Allocator) (Error || std.mem.Allocator.Error)!Pixels {
        var width: c_int = 0;
        var height: c_int = 0;
        const pixels = c.Rwindow_capture(@backingInt(self), &width, &height) orelse return lastError();
        defer c.Rpixels_free(pixels);
        const size = @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4;
        return .{ .pixels = try allocator.dupe(u8, pixels[0..size]), .width = width, .height = height };
    }

    pub fn getFrameStats(self: Window) FrameStats {
        var raw_stats: c.RFrameStats = .{};
        c.Rwindow_get_frame_stats(@backingInt(self), &raw_stats);
        return .fromC(raw_stats);
    }

    /// Opens a top-level window.
    /// width,height Client size in logical units.
    /// flags        Bitmask of RWindowFlags.
    pub fn create(title: [:0]const u8, width: i32, height: i32, flags: WindowFlags) Window {
        const result = c.Rwindow_create(title.ptr, width, height, @as(u32, @bitCast(flags)));
        return @fromBackingInt(result);
    }

    /// Closes a window and deletes its content widgets.
    pub fn destroy(self: Window) void {
        c.Rwindow_destroy(@backingInt(self));
    }

    pub fn isValid(self: Window) bool {
        const result = c.Rwindow_is_valid(@backingInt(self));
        return result != 0;
    }

    /// Sets the root widget of the window. The window takes ownership of
    /// the widget; the previous content is deleted.
    pub fn setContent(self: Window, widget: Widget) void {
        c.Rwindow_set_content(@backingInt(self), @backingInt(widget));
    }

    pub fn getContent(self: Window) ?Widget {
        const result = c.Rwindow_get_content(@backingInt(self));
        return Widget.fromId(result);
    }

    pub fn setTitle(self: Window, title: [:0]const u8) void {
        c.Rwindow_set_title(@backingInt(self), title.ptr);
    }

    pub fn getTitle(self: Window) [:0]const u8 {
        const result = c.Rwindow_get_title(@backingInt(self));
        return rt.span(result);
    }

    pub fn setSize(self: Window, width: i32, height: i32) void {
        c.Rwindow_set_size(@backingInt(self), width, height);
    }

    pub fn getSize(self: Window) struct { width: i32, height: i32 } {
        var width: c_int = 0;
        var height: c_int = 0;
        c.Rwindow_get_size(@backingInt(self), &width, &height);
        return .{ .width = width, .height = height };
    }

    /// The part of the window the system covers (status bar, notch,
    /// home indicator, navigation bar), in logical units. The content of the
    /// window is laid out inside it already. All 0 on desktop.
    pub fn getSafeArea(self: Window) Insets {
        var raw_insets: c.RInsets = .{};
        c.Rwindow_get_safe_area(@backingInt(self), &raw_insets);
        return .fromC(raw_insets);
    }

    /// The part of the window the on-screen keyboard covers (only
    /// `bottom` is set), in logical units; 0 when it is hidden or there is
    /// none (desktop). The content is laid out above it already, and the
    /// field that has the focus is scrolled into view above it, by the
    /// ScrollBoxes that hold it, when the keyboard comes or changes height,
    /// when the window turns, and when another field takes the focus.
    pub fn getKeyboardArea(self: Window) Insets {
        var raw_insets: c.RInsets = .{};
        c.Rwindow_get_keyboard_area(@backingInt(self), &raw_insets);
        return .fromC(raw_insets);
    }

    /// Called when the on-screen keyboard appears, changes height or goes away (mobile). NULL removes it.
    pub fn setKeyboardCallback(self: Window, context: anytype, comptime callback: ?fn (@TypeOf(context), Window, bool, f32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: f32, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Window, @fromBackingInt(a0)), a1 != 0, a2);
            }
        };
        c.Rwindow_set_keyboard_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// No widget of the window has the keyboard focus any more: on mobile, the on-screen keyboard goes away.
    pub fn clearFocus(self: Window) void {
        c.Rwindow_clear_focus(@backingInt(self));
    }

    pub fn setBackCallback(self: Window, context: anytype, comptime callback: ?fn (@TypeOf(context), Window) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Window, @fromBackingInt(a0)));
                return @intFromBool(handled);
            }
        };
        c.Rwindow_set_back_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// R_TRUE while the application has somewhere to go back to (a page
    /// under the one shown). Android 13 and later ask for Back only while the
    /// window wants it (predictive back): at the root page the system handles
    /// Back itself and animates back to the home screen. Default R_FALSE.
    pub fn setBackEnabled(self: Window, enabled: bool) void {
        c.Rwindow_set_back_enabled(@backingInt(self), @intFromBool(enabled));
    }

    /// Returns: R_TRUE while Back would be taken: a popup or dialog is open, or Rwindow_set_back_enabled said so.
    pub fn wantsBack(self: Window) bool {
        const result = c.Rwindow_wants_back(@backingInt(self));
        return result != 0;
    }

    pub fn setMinSize(self: Window, width: i32, height: i32) void {
        c.Rwindow_set_min_size(@backingInt(self), width, height);
    }

    pub fn setPosition(self: Window, x: i32, y: i32) void {
        c.Rwindow_set_position(@backingInt(self), x, y);
    }

    pub fn getPosition(self: Window) struct { x: i32, y: i32 } {
        var x: c_int = 0;
        var y: c_int = 0;
        c.Rwindow_get_position(@backingInt(self), &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Size of the drawable area in pixels.
    pub fn getFramebufferSize(self: Window) struct { width: i32, height: i32 } {
        var width: c_int = 0;
        var height: c_int = 0;
        c.Rwindow_get_framebuffer_size(@backingInt(self), &width, &height);
        return .{ .width = width, .height = height };
    }

    /// Returns: Pixels per logical unit (monitor scale x global UI scale).
    pub fn getScale(self: Window) f32 {
        const result = c.Rwindow_get_scale(@backingInt(self));
        return result;
    }

    pub fn show(self: Window) void {
        c.Rwindow_show(@backingInt(self));
    }

    pub fn hide(self: Window) void {
        c.Rwindow_hide(@backingInt(self));
    }

    /// Shows the window in front of the others with the keyboard, and
    /// makes the application the active one. Rwindow_show alone does not take
    /// the keyboard from another application (a prompt that appears while the
    /// user types elsewhere); this is for a window the user just asked for (a
    /// card opened from a tray icon). Where the system has no such request,
    /// the same as Rwindow_show.
    pub fn focus(self: Window) void {
        c.Rwindow_focus(@backingInt(self));
    }

    pub fn maximize(self: Window) void {
        c.Rwindow_maximize(@backingInt(self));
    }

    pub fn minimize(self: Window) void {
        c.Rwindow_minimize(@backingInt(self));
    }

    pub fn restore(self: Window) void {
        c.Rwindow_restore(@backingInt(self));
    }

    pub fn isMaximized(self: Window) bool {
        const result = c.Rwindow_is_maximized(@backingInt(self));
        return result != 0;
    }

    pub fn isMinimized(self: Window) bool {
        const result = c.Rwindow_is_minimized(@backingInt(self));
        return result != 0;
    }

    /// Returns: R_TRUE while the window is the one the user is working in.
    pub fn isActive(self: Window) bool {
        const result = c.Rwindow_is_active(@backingInt(self));
        return result != 0;
    }

    /// Asks to close the window, as the close button of its title bar
    /// does: the close callback is asked first and may refuse.
    pub fn close(self: Window) void {
        c.Rwindow_close(@backingInt(self));
    }

    /// Custom headers. Call these from a mouse-down handler, while the left
    /// button is held: the window follows the pointer until the button is
    /// released (the widget does not receive the release). A
    /// R_WIDGET_HEADER_BAR and the widgets given to Rwidget_set_window_drag do
    /// it by themselves.
    pub fn beginMove(self: Window) void {
        c.Rwindow_begin_move(@backingInt(self));
    }

    pub fn beginResize(self: Window, edge: WindowEdge) void {
        c.Rwindow_begin_resize(@backingInt(self), @backingInt(edge));
    }

    /// Icon of the window (title bar, task bar), from tightly packed
    /// RGBA8 pixels; NULL goes back to the default: on Windows the first icon
    /// of the executable, when it has one. Windows and X11.
    pub fn setIcon(self: Window, rgba: []const u8, width: i32, height: i32) void {
        std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
        c.Rwindow_set_icon(@backingInt(self), rgba.ptr, width, height);
    }

    pub fn setClearColor(self: Window, color: Color) void {
        c.Rwindow_set_clear_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// Image drawn behind the content, scaled to cover the window:
    /// what the glass of a glass theme looks through. R_INVALID_ID removes it.
    pub fn setBackground(self: Window, texture: ?Texture) void {
        c.Rwindow_set_background(@backingInt(self), optId(texture));
    }

    /// Chooses what shows behind a window created with
    /// R_WINDOW_TRANSPARENT (see RBackdrop). With anything but
    /// R_BACKDROP_NONE the window is not cleared with its color and the
    /// wallpaper of the theme is not drawn: only what the widgets draw hides
    /// the screen. In XML: <Window Backdrop="Blur">.
    /// Returns: R_TRUE when the window system does it; R_FALSE (the window
    /// then stays as it was) without R_WINDOW_TRANSPARENT, or when it cannot.
    pub fn setBackdrop(self: Window, backdrop: Backdrop) bool {
        const result = c.Rwindow_set_backdrop(@backingInt(self), @backingInt(backdrop));
        return result != 0;
    }

    pub fn getBackdrop(self: Window) Backdrop {
        const result = c.Rwindow_get_backdrop(@backingInt(self));
        return @as(Backdrop, @fromBackingInt(result));
    }

    /// Gives the window a theme of its own, by name ("Dark",
    /// "WindowsLight", or a theme of Rtheme_load): everything inside it (its
    /// content, its island, its menus, lists and dialogs, its background) is
    /// drawn with that theme, while the other windows keep the one of the
    /// application (Rtheme_use). A widget given Rwidget_set_theme keeps its own.
    /// In XML: <Window Theme="...">.
    /// name NULL or "": the theme of the application again.
    /// Returns: R_FALSE, after reporting an error, when no theme has that name.
    pub fn setTheme(self: Window, name: ?[:0]const u8) Error!void {
        if (c.Rwindow_set_theme(@backingInt(self), rt.optPtr(name)) == 0) return lastError();
    }

    /// Returns: Name of the theme the window is drawn with (the one of the application when it has none of its own).
    pub fn getTheme(self: Window) [:0]const u8 {
        const result = c.Rwindow_get_theme(@backingInt(self));
        return rt.span(result);
    }

    /// Returns: R_TRUE when the window has a theme of its own (Rwindow_set_theme).
    pub fn hasOwnTheme(self: Window) bool {
        const result = c.Rwindow_has_own_theme(@backingInt(self));
        return result != 0;
    }

    /// Opacity of the whole window, its frame included, from 0 to 1:
    /// a window that fades, a tool that lets what is under it show.
    /// Returns: R_FALSE when the window system cannot do it.
    pub fn setOpacity(self: Window, opacity: f32) bool {
        const result = c.Rwindow_set_opacity(@backingInt(self), opacity);
        return result != 0;
    }

    pub fn getOpacity(self: Window) f32 {
        const result = c.Rwindow_get_opacity(@backingInt(self));
        return result;
    }

    /// Keeps the window above the other windows (splash screens, tools).
    /// Returns: R_FALSE when the window system cannot do it.
    pub fn setTopmost(self: Window, topmost: bool) bool {
        const result = c.Rwindow_set_topmost(@backingInt(self), @intFromBool(topmost));
        return result != 0;
    }

    /// Gives the window an owner (a tool window or an inspector of the
    /// main window): it stays above its owner, has no button of its own in the
    /// taskbar, is minimized and restored with it (where the window system
    /// does it: Windows, X11), and is destroyed with it (everywhere: Raven
    /// destroys the windows a window owns before the window). R_INVALID_ID
    /// gives the window back its independence.
    /// Returns: R_FALSE when the window system cannot keep the window with its
    /// owner (it is still destroyed with it), or when the owner is not valid
    /// or is owned by the window (nothing is changed then).
    pub fn setOwner(self: Window, owner: ?Window) bool {
        const result = c.Rwindow_set_owner(@backingInt(self), optId(owner));
        return result != 0;
    }

    /// Returns: The owner of the window (Rwindow_set_owner), or R_INVALID_ID.
    pub fn getOwner(self: Window) ?Window {
        const result = c.Rwindow_get_owner(@backingInt(self));
        return Window.fromId(result);
    }

    /// Picture in picture: the window becomes a small floating window
    /// that stays above the other windows, on every desktop (every space of
    /// macOS, over the applications in full screen too), in a corner of the
    /// work area of its monitor. It loses its title bar where the system
    /// allows: the empty parts of its content move it, its edges resize it,
    /// and its size keeps the proportions it was given. Leaving it gives back
    /// the size, place, frame and state the window had.
    ///
    /// Raven does not add a button to leave it: the content shows one, with
    /// the built-in action "window.picture_in_picture" (it goes in and out).
    /// Returns: R_FALSE when the window system cannot keep a window above the
    /// others (Wayland): the window is left as it is.
    pub fn setPictureInPicture(self: Window, enabled: bool) bool {
        const result = c.Rwindow_set_picture_in_picture(@backingInt(self), @intFromBool(enabled));
        return result != 0;
    }

    pub fn isPictureInPicture(self: Window) bool {
        const result = c.Rwindow_is_picture_in_picture(@backingInt(self));
        return result != 0;
    }

    /// Size (logical units) and corner of the window in picture in
    /// picture, for the next time it goes in (now, when it is in). 0, 0 (the
    /// default): 320 wide, with the proportions the content has when it goes
    /// in. The proportions of width / height are kept while the user resizes.
    pub fn setPictureInPictureLayout(self: Window, width: i32, height: i32, corner: PictureInPictureCorner) void {
        c.Rwindow_set_picture_in_picture_layout(@backingInt(self), width, height, @backingInt(corner));
    }

    /// Centers the window on the work area of its monitor (no task bar).
    pub fn center(self: Window) void {
        c.Rwindow_center(@backingInt(self));
    }

    /// Shows (R_TRUE) or hides (R_FALSE) the inspector of the window: a
    /// window beside it that lists its widgets as a tree, says what the
    /// selected one is (type, name, classes, place and size in the window,
    /// desired size, constraints, slot, visibility, state, style, action,
    /// children) and what the last frame cost (layout, paint and render
    /// times, widgets, instances, draw calls). The selected widget is
    /// outlined in the window, with its type and size. "Pick" selects the
    /// next widget clicked in the window (that click goes to the inspector
    /// only). It follows the window as it changes; closing it hides it, and
    /// it goes with the window. Nothing opens it but this function.
    pub fn setInspector(self: Window, shown: bool) void {
        c.Rwindow_set_inspector(@backingInt(self), @intFromBool(shown));
    }

    pub fn isInspectorShown(self: Window) bool {
        const result = c.Rwindow_is_inspector_shown(@backingInt(self));
        return result != 0;
    }

    /// Returns: The window of the inspector of a window (to place it), or R_INVALID_ID when it is hidden.
    pub fn getInspector(self: Window) ?Window {
        const result = c.Rwindow_get_inspector(@backingInt(self));
        return Window.fromId(result);
    }

    /// Returns: R_TRUE for a window created with R_WINDOW_SPLASH_SCREEN (IsSplashScreen in XML).
    pub fn isSplashScreen(self: Window) bool {
        const result = c.Rwindow_is_splash_screen(@backingInt(self));
        return result != 0;
    }

    /// Asks for a new frame even if no widget changed. Thread-safe.
    pub fn requestRedraw(self: Window) void {
        c.Rwindow_request_redraw(@backingInt(self));
    }

    /// R_TRUE redraws the window every frame (games, live viewports).
    pub fn setContinuousRedraw(self: Window, enabled: bool) void {
        c.Rwindow_set_continuous_redraw(@backingInt(self), @intFromBool(enabled));
    }

    pub fn setCloseCallback(self: Window, context: anytype, comptime callback: ?fn (@TypeOf(context), Window) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Window, @fromBackingInt(a0)));
                return @intFromBool(handled);
            }
        };
        c.Rwindow_set_close_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setResizeCallback(self: Window, context: anytype, comptime callback: ?fn (@TypeOf(context), Window, i32, i32) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c_int, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Window, @fromBackingInt(a0)), a1, a2);
            }
        };
        c.Rwindow_set_resize_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// Takes what is dropped on the window from other applications,
    /// where no widget takes it (Rwidget_set_drop_callback). NULL removes it.
    pub fn setDropCallback(self: Window, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, DropEvent) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*const c.RDropEvent, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), DropEvent.fromC(a1.?.*));
                return @intFromBool(handled);
            }
        };
        c.Rwindow_set_drop_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    pub fn setUserHandle(self: Window, handle: ?*anyopaque) void {
        c.Rwindow_set_user_handle(@backingInt(self), handle);
    }

    pub fn getUserHandle(self: Window) ?*anyopaque {
        const result = c.Rwindow_get_user_handle(@backingInt(self));
        return result;
    }

    /// Fills `native` with the OS handles of the window.
    pub fn getNativeHandle(self: Window) ?NativeWindow {
        var raw_native: c.RNativeWindow = .{};
        if (c.Rwindow_get_native_handle(@backingInt(self), &raw_native) == 0) return null;
        return .fromC(raw_native);
    }

    /// Widget that has the keyboard focus in the window, or R_INVALID_ID.
    pub fn getFocusedWidget(self: Window) ?Widget {
        const result = c.Rwindow_get_focused_widget(@backingInt(self));
        return Widget.fromId(result);
    }

    /// Deepest widget under the cursor, or R_INVALID_ID.
    pub fn getHoveredWidget(self: Window) ?Widget {
        const result = c.Rwindow_get_hovered_widget(@backingInt(self));
        return Widget.fromId(result);
    }

    pub fn getMousePosition(self: Window) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        c.Rwindow_get_mouse_position(@backingInt(self), &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Inject input as if it came from the OS. Positions are in logical units.
    /// Useful for automated tests, replays and when Raven is driven by a host
    /// application.
    pub fn injectMouseMove(self: Window, x: f32, y: f32) void {
        c.Rwindow_inject_mouse_move(@backingInt(self), x, y);
    }

    pub fn injectMouseButton(self: Window, button: MouseButton, pressed: bool) void {
        c.Rwindow_inject_mouse_button(@backingInt(self), @backingInt(button), @intFromBool(pressed));
    }

    pub fn injectMouseWheel(self: Window, wheel_x: f32, wheel_y: f32) void {
        c.Rwindow_inject_mouse_wheel(@backingInt(self), wheel_x, wheel_y);
    }

    pub fn injectKey(self: Window, key: Key, pressed: bool, modifiers: Modifier) void {
        c.Rwindow_inject_key(@backingInt(self), @backingInt(key), @intFromBool(pressed), @as(u32, @bitCast(modifiers)));
    }

    pub fn injectText(self: Window, text: [:0]const u8) void {
        c.Rwindow_inject_text(@backingInt(self), text.ptr);
    }

    /// The text an input method is composing (preedit: Chinese,
    /// Japanese, Korean, dead keys), as the platforms send it. The focused
    /// TextInput, SpinBox or TextEditor shows it at its caret, underlined, in
    /// place of its selection, but it is not in its text and no changed
    /// callback runs. [selection_start, selection_end) are bytes of `text`:
    /// the part the input method works on (underlined thicker), or the caret
    /// when they are equal; -1 is the end of `text`. NULL or "" ends the
    /// composition without typing anything (cancel). The committed text comes
    /// through Rwindow_inject_text, which ends the composition too, and so
    /// does a change of focus. Ignored when the focus takes no text.
    pub fn injectComposition(self: Window, text: ?[:0]const u8, selection_start: i32, selection_end: i32) void {
        c.Rwindow_inject_composition(@backingInt(self), rt.optPtr(text), selection_start, selection_end);
    }

    /// A drag from another application moves over the window
    /// (`inside` R_TRUE) or leaves it.
    /// Returns: R_TRUE when a drop at this position would be accepted.
    pub fn injectDrag(self: Window, x: f32, y: f32, inside: bool) bool {
        const result = c.Rwindow_inject_drag(@backingInt(self), x, y, @intFromBool(inside));
        return result != 0;
    }

    /// Drops files and / or text at a position. Returns R_TRUE when a target took them.
    pub fn injectDrop(self: Window, x: f32, y: f32, paths: []const [*:0]const u8, text: [:0]const u8) bool {
        const result = c.Rwindow_inject_drop(@backingInt(self), x, y, @ptrCast(paths.ptr), @intCast(paths.len), text.ptr);
        return result != 0;
    }

    /// The end of the drag out of the window that the window system
    /// holds (Rdrag_begin_external), as it reports it: `operation` is what the
    /// target did (an RDragOperation). Returns R_FALSE when no such drag is in
    /// progress.
    pub fn injectDragEnd(self: Window, operation: DragOperation) i32 {
        const result = c.Rwindow_inject_drag_end(@backingInt(self), @as(c_int, @bitCast(operation)));
        return result;
    }

    /// Back, as the system sends it (Rwindow_set_back_callback). Returns R_TRUE when something took it.
    pub fn injectBack(self: Window) i32 {
        const result = c.Rwindow_inject_back(@backingInt(self));
        return result;
    }

    /// R_TRUE while the key is held down in the window (cleared when the window loses the keyboard).
    pub fn isKeyDown(self: Window, key: Key) bool {
        const result = c.Rwindow_is_key_down(@backingInt(self), @backingInt(key));
        return result != 0;
    }

    /// R_TRUE while the mouse button is held down over (or captured by) the window.
    pub fn isMouseButtonDown(self: Window, button: MouseButton) bool {
        const result = c.Rwindow_is_mouse_button_down(@backingInt(self), @backingInt(button));
        return result != 0;
    }

    /// Modifiers (RModifier) of the last input event.
    pub fn getModifiers(self: Window) Modifier {
        const result = c.Rwindow_get_modifiers(@backingInt(self));
        return @as(Modifier, @bitCast(@as(u32, result)));
    }

    /// R_TRUE while the pointer is over the client area.
    pub fn isMouseInside(self: Window) bool {
        const result = c.Rwindow_is_mouse_inside(@backingInt(self));
        return result != 0;
    }

    /// R_TRUE when the keyboard focus is in a text input, spin box or text editor.
    pub fn wantsTextInput(self: Window) bool {
        const result = c.Rwindow_wants_text_input(@backingInt(self));
        return result != 0;
    }

    /// The kind of the focused text input; R_FALSE when there is none.
    pub fn getTextInputInfo(self: Window) ?TextInputInfo {
        var raw_info: c.RTextInputInfo = .{};
        if (c.Rwindow_get_text_input_info(@backingInt(self), &raw_info) == 0) return null;
        return .fromC(raw_info);
    }

    /// Its text (UTF-8), valid until it changes; NULL when there is none.
    pub fn getTextInputText(self: Window) ?[:0]const u8 {
        const result = c.Rwindow_get_text_input_text(@backingInt(self));
        return rt.optSpan(result);
    }

    /// Its selection: start == end is the caret. R_FALSE when there is none.
    pub fn getTextInputSelection(self: Window) ?struct { start: i32, end: i32 } {
        var start: c_int = 0;
        var end: c_int = 0;
        if (c.Rwindow_get_text_input_selection(@backingInt(self), &start, &end) == 0) return null;
        return .{ .start = start, .end = end };
    }

    /// Selects bytes [start, end) of it (end before start puts the caret at end).
    pub fn setTextInputSelection(self: Window, start: i32, end: i32) bool {
        const result = c.Rwindow_set_text_input_selection(@backingInt(self), start, end);
        return result != 0;
    }

    /// Replaces bytes [start, end) of it with `text` and puts the caret
    /// after it, as typing would (the changed callback runs; MaxLength
    /// applies). R_FALSE when there is none or it is read-only.
    pub fn replaceTextInput(self: Window, start: i32, end: i32, text: [:0]const u8) bool {
        const result = c.Rwindow_replace_text_input(@backingInt(self), start, end, text.ptr);
        return result != 0;
    }

    /// The composition of the input method in progress (UTF-8, valid
    /// until it changes) and its selection in bytes; NULL when there is none.
    /// Any output pointer may be NULL.
    pub fn getTextComposition(self: Window) ?struct { text: [:0]const u8, selection_start: i32, selection_end: i32 } {
        var selection_start: c_int = 0;
        var selection_end: c_int = 0;
        const result = c.Rwindow_get_text_composition(@backingInt(self), &selection_start, &selection_end);
        if (result == null) return null;
        return .{ .text = rt.span(result), .selection_start = selection_start, .selection_end = selection_end };
    }

    /// R_TRUE while a menu, list or dialog is open over the window.
    pub fn hasPopup(self: Window) bool {
        const result = c.Rwindow_has_popup(@backingInt(self));
        return result != 0;
    }

    /// Last painted caret in window pixels (x, y, width, height), including scrolling and scale.
    /// Call after Rdraw_frame. Independent of the blink phase. Returns R_FALSE and zeros the
    /// outputs when there is no visible editable caret, the window is inactive, or focus changed
    /// since painting. Any output pointer may be NULL. While an input method
    /// composes, it is the caret inside the composition: where its candidate
    /// window goes.
    pub fn getTextInputRect(self: Window) ?struct { x: i32, y: i32, width: i32, height: i32 } {
        var x: c_int = 0;
        var y: c_int = 0;
        var width: c_int = 0;
        var height: c_int = 0;
        if (c.Rwindow_get_text_input_rect(@backingInt(self), &x, &y, &width, &height) == 0) return null;
        return .{ .x = x, .y = y, .width = width, .height = height };
    }

    /// Returns: Number of open in-window popups (menus, combo lists, pickers), bottom to top.
    pub fn getPopupCount(self: Window) i32 {
        const result = c.Rwindow_get_popup_count(@backingInt(self));
        return result;
    }

    /// Returns: Root widget of popup `index`, whose rect is in window coordinates; R_INVALID_ID out of range.
    pub fn getPopup(self: Window, index: i32) ?Widget {
        const result = c.Rwindow_get_popup(@backingInt(self), index);
        return Widget.fromId(result);
    }

    /// R_FALSE: Tab no longer moves the keyboard focus (the application uses it as a shortcut). Default R_TRUE.
    pub fn setTabNavigation(self: Window, enabled: bool) void {
        c.Rwindow_set_tab_navigation(@backingInt(self), @intFromBool(enabled));
    }

    pub fn setEventHook(self: Window, context: anytype, comptime hook: ?fn (@TypeOf(context), Window, Event) bool) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: ?*const c.REvent, user_data: ?*anyopaque) callconv(.c) c_int {
                const handled = hook.?(rt.contextFromC(Ctx, user_data), @as(Window, @fromBackingInt(a0)), Event.fromC(a1.?.*));
                return @intFromBool(handled);
            }
        };
        c.Rwindow_set_event_hook(@backingInt(self), if (hook != null) &Trampoline.call else null, if (hook != null) rt.contextToC(context) else null);
    }

    pub fn registerShortcut(self: Window, key: Key, modifiers: Modifier, action: [:0]const u8) void {
        c.Rwindow_register_shortcut(@backingInt(self), @backingInt(key), @as(u32, @bitCast(modifiers)), action.ptr);
    }

    pub fn unregisterShortcut(self: Window, key: Key, modifiers: Modifier) void {
        c.Rwindow_unregister_shortcut(@backingInt(self), @backingInt(key), @as(u32, @bitCast(modifiers)));
    }

    /// Settings of one window; NULL: it follows Rtouch_set_settings again.
    pub fn setTouchSettings(self: Window, settings: ?TouchSettings) void {
        const raw_settings: ?c.RTouchSettings = if (settings) |v| v.toC() else null;
        c.Rwindow_set_touch_settings(@backingInt(self), if (raw_settings) |*v| v else null);
    }

    /// The settings the window follows (its own, or those of the application).
    pub fn getTouchSettings(self: Window) TouchSettings {
        var raw_settings: c.RTouchSettings = .{};
        c.Rwindow_get_touch_settings(@backingInt(self), &raw_settings);
        return .fromC(raw_settings);
    }

    /// Fingers on the window now.
    pub fn getTouchCount(self: Window) i32 {
        const result = c.Rwindow_get_touch_count(@backingInt(self));
        return result;
    }

    /// R_TRUE while a pen is near the screen over the window.
    pub fn isPenInRange(self: Window) bool {
        const result = c.Rwindow_is_pen_in_range(@backingInt(self));
        return result != 0;
    }

    /// R_TRUE when the pointer last used in the window was a finger (the interface may then be made larger).
    pub fn isTouchActive(self: Window) bool {
        const result = c.Rwindow_is_touch_active(@backingInt(self));
        return result != 0;
    }

    /// A finger: R_TOUCH_DOWN, then R_TOUCH_MOVE..., then R_TOUCH_UP, with the same `id`.
    pub fn injectTouch(self: Window, id: i32, phase: TouchPhase, x: f32, y: f32) void {
        c.Rwindow_inject_touch(@backingInt(self), id, @backingInt(phase), x, y);
    }

    /// A pen: `pressure` 0..1 as the pen would give it, `buttons` a bitmask of RPenButton.
    pub fn injectPen(self: Window, phase: PenPhase, x: f32, y: f32, pressure: f32, tilt_x: f32, tilt_y: f32, buttons: PenButton, eraser: bool) void {
        c.Rwindow_inject_pen(@backingInt(self), @backingInt(phase), x, y, pressure, tilt_x, tilt_y, @as(u32, @bitCast(buttons)), @intFromBool(eraser));
    }

    /// A gesture of a trackpad, as the system recognizes it: R_GESTURE_BEGIN,
    /// R_GESTURE_UPDATE..., then R_GESTURE_END. (x, y) is the pointer, `scale_delta`
    /// and `rotation_delta` (degrees, clockwise) what changed since the previous
    /// event, `pan_x`, `pan_y` how far the fingers moved since then.
    pub fn injectTrackpadGesture(self: Window, kind: GestureKind, phase: GesturePhase, x: f32, y: f32, scale_delta: f32, rotation_delta: f32, pan_x: f32, pan_y: f32, fingers: i32) void {
        c.Rwindow_inject_trackpad_gesture(@backingInt(self), @backingInt(kind), @backingInt(phase), x, y, scale_delta, rotation_delta, pan_x, pan_y, fingers);
    }

    /// Two fingers scrolling on a trackpad: (dx, dy) is how far they moved
    /// (logical units), the content following them. Sent as a precise wheel
    /// (REvent::wheel_precise) at the pointer.
    pub fn injectTrackpadScroll(self: Window, dx: f32, dy: f32) void {
        c.Rwindow_inject_trackpad_scroll(@backingInt(self), dx, dy);
    }

    /// The fingers that scrolled left the trackpad, on a system that
    /// leaves the inertia to the application (Wayland): flicked content keeps
    /// going (Touch.Inertia).
    pub fn injectTrackpadScrollEnd(self: Window) void {
        c.Rwindow_inject_trackpad_scroll_end(@backingInt(self));
    }

    /// Advances the inertia of flicked content by `seconds` at once,
    /// and fires a long press that is due, without waiting (tests).
    pub fn advanceTouch(self: Window, seconds: f64) void {
        c.Rwindow_advance_touch(@backingInt(self), seconds);
    }

    /// Closes every open menu and popup of the window.
    pub fn closePopups(self: Window) void {
        c.Rwindow_close_popups(@backingInt(self));
    }

    /// Shows a widget (usually an island) floating at the top of a
    /// window, in the middle, above its content. The window takes ownership;
    /// the previous one is deleted. R_INVALID_ID removes it. The padding of
    /// its slot (Rslot_set_padding) is its distance from the top edge.
    pub fn setIsland(self: Window, widget: ?Widget) void {
        c.Rwindow_set_island(@backingInt(self), optId(widget));
    }

    pub fn getIsland(self: Window) ?Island {
        const result = c.Rwindow_get_island(@backingInt(self));
        return Island.fromId(result);
    }

    /// A progress bar on the icon of the application: on the button of
    /// the window in the taskbar (Windows), on the icon in the Dock (macOS),
    /// on the launcher (Linux). There is one icon for the whole application in
    /// the Dock and the launchers: the last window that set it is shown.
    /// value From 0 to 1 (not used by NONE and INDETERMINATE).
    /// Returns: R_FALSE where the system shows no progress.
    pub fn setTaskbarProgress(self: Window, state: TaskbarProgress, value: f32) bool {
        const result = c.Rwindow_set_taskbar_progress(@backingInt(self), @backingInt(state), value);
        return result != 0;
    }

    /// Asks the user to look at the window when it is not the active
    /// one: its taskbar button flashes (Windows), the icon bounces in the
    /// Dock (macOS), the window is marked urgent (X11, the launchers of
    /// Linux). `critical`: until the user comes to the window; otherwise a few
    /// times. Nothing happens when the window is already the active one.
    pub fn requestAttention(self: Window, critical: i32) bool {
        const result = c.Rwindow_request_attention(@backingInt(self), critical);
        return result != 0;
    }

    /// Returns: R_TRUE while a dialog is shown in the window.
    pub fn hasDialog(self: Window) bool {
        const result = c.Rwindow_has_dialog(@backingInt(self));
        return result != 0;
    }

    /// Creates a window from a document whose root element is <Window>.
    /// xml  UTF-8 text. It does not need to be null-terminated.
    /// size Size of the text in bytes.
    /// Returns: The window, or R_INVALID_ID. Parse errors are reported with
    ///         their line and column through the error callback (R_ERROR_XML).
    pub fn createFromXml(xml: []const u8) Error!Window {
        const result = c.Rwindow_create_from_xml(@ptrCast(xml.ptr), xml.len);
        return Window.fromId(result) orelse lastError();
    }

    pub fn createFromXmlFile(path: [:0]const u8) Error!Window {
        const result = c.Rwindow_create_from_xml_file(path.ptr);
        return Window.fromId(result) orelse lastError();
    }
};

/// A handle of the library.
pub const TreeItem = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?TreeItem {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: TreeItem) Rid {
        return @backingInt(self);
    }

    /// Deletes an item and its descendants.
    pub fn destroy(self: TreeItem) void {
        c.Rtree_item_destroy(@backingInt(self));
    }

    pub fn isValid(self: TreeItem) bool {
        const result = c.Rtree_item_is_valid(@backingInt(self));
        return result != 0;
    }

    pub fn setText(self: TreeItem, text: [:0]const u8) void {
        c.Rtree_item_set_text(@backingInt(self), text.ptr);
    }

    pub fn getText(self: TreeItem) [:0]const u8 {
        const result = c.Rtree_item_get_text(@backingInt(self));
        return rt.span(result);
    }

    pub fn setExpanded(self: TreeItem, expanded: bool) void {
        c.Rtree_item_set_expanded(@backingInt(self), @intFromBool(expanded));
    }

    pub fn isExpanded(self: TreeItem) bool {
        const result = c.Rtree_item_is_expanded(@backingInt(self));
        return result != 0;
    }

    pub fn setUserHandle(self: TreeItem, handle: ?*anyopaque) void {
        c.Rtree_item_set_user_handle(@backingInt(self), handle);
    }

    pub fn getUserHandle(self: TreeItem) ?*anyopaque {
        const result = c.Rtree_item_get_user_handle(@backingInt(self));
        return result;
    }

    /// Returns: The parent item, or R_INVALID_ID for a top-level item.
    pub fn getParent(self: TreeItem) ?TreeItem {
        const result = c.Rtree_item_get_parent(@backingInt(self));
        return TreeItem.fromId(result);
    }

    pub fn getChildCount(self: TreeItem) i32 {
        const result = c.Rtree_item_get_child_count(@backingInt(self));
        return result;
    }

    pub fn getChild(self: TreeItem, index: i32) ?TreeItem {
        const result = c.Rtree_item_get_child(@backingInt(self), index);
        return TreeItem.fromId(result);
    }

    /// Icon drawn before the text of the item (a region u0,v0,u1,v1 of the texture). R_INVALID_ID removes it.
    /// An SVG in currentColor (Ricon_get) takes the color of the text. XML: Icon on an Item.
    pub fn setIcon(self: TreeItem, texture: ?Texture, u0_: f32, v0: f32, u1_: f32, v1: f32) void {
        c.Rtree_item_set_icon(@backingInt(self), optId(texture), u0_, v0, u1_, v1);
    }

    /// Color of the text of the item; alpha 0 goes back to the theme.
    pub fn setTextColor(self: TreeItem, color: Color) void {
        c.Rtree_item_set_text_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    pub fn setSelected(self: TreeItem, selected: bool) void {
        c.Rtree_item_set_selected(@backingInt(self), @intFromBool(selected));
    }

    pub fn isSelected(self: TreeItem) bool {
        const result = c.Rtree_item_is_selected(@backingInt(self));
        return result != 0;
    }
};

/// A handle of the library.
pub const Font = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Font {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Font) Rid {
        return @backingInt(self);
    }

    /// Creates a font from the content of a .ttf / .otf file.
    /// The buffer is copied. Glyphs are rasterized on demand, at the exact
    /// pixel size needed by each window scale, into a shared atlas.
    /// Returns: R_INVALID_ID on failure.
    pub fn create(data: []const u8) Error!Font {
        const result = c.Rfont_create(@ptrCast(data.ptr), data.len);
        return Font.fromId(result) orelse lastError();
    }

    pub fn createFromFile(path: [:0]const u8) Error!Font {
        const result = c.Rfont_create_from_file(path.ptr);
        return Font.fromId(result) orelse lastError();
    }

    pub fn destroy(self: Font) void {
        c.Rfont_destroy(@backingInt(self));
    }

    pub fn isValid(self: Font) bool {
        const result = c.Rfont_is_valid(@backingInt(self));
        return result != 0;
    }

    /// Returns: The font embedded in the library (Roboto, Latin and Latin Extended-A).
    pub fn getDefault() ?Font {
        const result = c.Rfont_get_default();
        return Font.fromId(result);
    }

    /// Returns: The fixed-width font embedded in the library (Roboto Mono, same
    /// characters), used by default by the text editors. In XML: Font="monospace".
    pub fn getMonospace() ?Font {
        const result = c.Rfont_get_monospace();
        return Font.fromId(result);
    }

    /// Font used for the characters missing from `font` (symbols, icons,
    /// other scripts). Fallbacks can be chained.
    pub fn setFallback(self: Font, fallback: Font) void {
        c.Rfont_set_fallback(@backingInt(self), @backingInt(fallback));
    }

    /// Gives a font the font to use for one of its styles: the bold
    /// file of the same family, its italic file. Formatted text (Markdown
    /// labels, the Markdown of the text editor) uses them.
    ///
    /// A font that was given none still has the three styles: Raven draws
    /// its glyphs thicker for bold and slanted for italic, keeping their
    /// advances, so that text does not move when its style changes.
    /// variant R_INVALID_ID goes back to the style Raven derives.
    pub fn setVariant(self: Font, style: FontStyle, variant: ?Font) void {
        c.Rfont_set_variant(@backingInt(self), @backingInt(style), optId(variant));
    }

    /// Returns: The font drawn for a style of `font`: the one given with
    /// Rfont_set_variant, else the one Raven derives from it (made on first
    /// use; it lives as long as `font` and cannot be deleted by itself).
    /// Usable wherever a font is: Rlabel_set_font, Rdraw_text...
    pub fn getVariant(self: Font, style: FontStyle) ?Font {
        const result = c.Rfont_get_variant(@backingInt(self), @backingInt(style));
        return Font.fromId(result);
    }

    /// Measures a UTF-8 string, in logical units, at scale 1.
    /// font R_INVALID_ID uses the theme font.
    /// size Font size; 0 uses R_METRIC_FONT_SIZE.
    pub fn measureText(self: Font, size: f32, text: [:0]const u8) struct { width: f32, height: f32 } {
        var width: f32 = 0;
        var height: f32 = 0;
        c.Rfont_measure_text(@backingInt(self), size, text.ptr, &width, &height);
        return .{ .width = width, .height = height };
    }
};

/// A handle of the library.
pub const Texture = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Texture {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Texture) Rid {
        return @backingInt(self);
    }

    /// Creates a texture from the content of an image file (PNG, JPEG,
    /// BMP, TGA, GIF, PSD, SVG). Decoding happens on the calling thread. An
    /// animated GIF or APNG keeps its frames: an Image showing it plays them.
    /// Returns: R_INVALID_ID on failure.
    pub fn create(data: []const u8) Error!Texture {
        const result = c.Rtexture_create(@ptrCast(data.ptr), data.len);
        return Texture.fromId(result) orelse lastError();
    }

    /// Same as Rtexture_create, decoded on a worker thread. The handle
    /// is usable at once; widgets showing it draw nothing until it is ready.
    /// The buffer is copied.
    pub fn createAsync(data: []const u8) Texture {
        const result = c.Rtexture_create_async(@ptrCast(data.ptr), data.len);
        return @fromBackingInt(result);
    }

    /// Draws an SVG image (an icon) into a texture, at `scale` pixels per
    /// unit of the SVG. The widgets show it at the size the SVG gives, whatever
    /// the scale (Rtexture_get_density).
    ///
    /// 0 or less: at the size it is shown. It is first drawn at a scale of 2;
    /// once painted, it is drawn again (on a worker thread) with as many pixels
    /// as the screen shows it with: the scale of the monitor of the window, an
    /// Image that stretches it, a zoom. It follows when the window moves to a
    /// screen of another density or the image grows, and comes down when it is
    /// shown much smaller (sides of at most 4096 pixels). Its width and height
    /// in pixels (Rtexture_get_size) change then; its size in logical units
    /// does not. Rtexture_create, Rtexture_create_from_file and the asynchronous
    /// ones read SVG files this way. Paths, fills, strokes and gradients are
    /// drawn; text, filters and masks are not.
    ///
    /// currentColor: an SVG painted only in currentColor (fill="currentColor",
    /// stroke="currentColor") is drawn in white, keeping its shape and its
    /// opacity, and the widgets that show it (Image, the icons of menu items,
    /// tabs, tree items, dock panels, tiles, nodes) tint it with the color of
    /// their text at draw time: it follows the theme, hover, pressed and
    /// disabled without being drawn again. Rdraw_image draws it in its tint
    /// color. In an SVG that also uses other colors, currentColor is black.
    /// See Rtexture_uses_current_color.
    pub fn createFromSvg(svg: []const u8, scale: f32) Error!Texture {
        const result = c.Rtexture_create_from_svg(@ptrCast(svg.ptr), svg.len, scale);
        return Texture.fromId(result) orelse lastError();
    }

    /// R_TRUE when the texture is an SVG painted only in currentColor:
    /// white where it is painted, tinted with the color of the text by the
    /// widgets that show it (see Rtexture_create_from_svg).
    pub fn usesCurrentColor(self: Texture) i32 {
        const result = c.Rtexture_uses_current_color(@backingInt(self));
        return result;
    }

    /// Pixels of the texture per logical unit: the scale of an SVG, 1 otherwise.
    pub fn getDensity(self: Texture) f32 {
        const result = c.Rtexture_get_density(@backingInt(self));
        return result;
    }

    pub fn createFromFile(path: [:0]const u8) Error!Texture {
        const result = c.Rtexture_create_from_file(path.ptr);
        return Texture.fromId(result) orelse lastError();
    }

    /// Reads and decodes the file on a worker thread.
    pub fn createFromFileAsync(path: [:0]const u8) Error!Texture {
        const result = c.Rtexture_create_from_file_async(path.ptr);
        return Texture.fromId(result) orelse lastError();
    }

    /// Downloads an http:// or https:// image and decodes it on a worker
    /// thread, as an Image whose Source is a URL does. The handle is usable at
    /// once: widgets showing it draw nothing until it is ready (Rtexture_is_ready;
    /// a texture that could not be downloaded is ready with a size of 0, and the
    /// failure is reported as a warning). Desktops download with WinHTTP or
    /// `curl`; iOS and Android through their platform. Android needs the INTERNET
    /// permission in the manifest; iOS refuses http:// unless Info.plist allows
    /// it (App Transport Security). Up to 32 MiB.
    pub fn createFromUrlAsync(url: [:0]const u8) Texture {
        const result = c.Rtexture_create_from_url_async(url.ptr);
        return @fromBackingInt(result);
    }

    /// Creates a texture from tightly packed RGBA8 pixels (straight alpha). Its filter is R_FILTER_LINEAR.
    pub fn createFromPixels(rgba: []const u8, width: i32, height: i32) Error!Texture {
        std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
        const result = c.Rtexture_create_from_pixels(rgba.ptr, width, height);
        return Texture.fromId(result) orelse lastError();
    }

    /// Replaces the pixels of a texture. The size may change. Use it to
    /// show frames produced on the CPU or read back from another renderer.
    pub fn update(self: Texture, rgba: []const u8, width: i32, height: i32) void {
        std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
        c.Rtexture_update(@backingInt(self), rgba.ptr, width, height);
    }

    /// Returns: R_TRUE once an asynchronous texture is decoded (or failed).
    pub fn isReady(self: Texture) bool {
        const result = c.Rtexture_is_ready(@backingInt(self));
        return result != 0;
    }

    /// Blocks until an asynchronous texture is ready.
    pub fn wait(self: Texture) void {
        c.Rtexture_wait(@backingInt(self));
    }

    pub fn destroy(self: Texture) void {
        c.Rtexture_destroy(@backingInt(self));
    }

    pub fn isValid(self: Texture) bool {
        const result = c.Rtexture_is_valid(@backingInt(self));
        return result != 0;
    }

    pub fn getSize(self: Texture) struct { width: i32, height: i32 } {
        var width: c_int = 0;
        var height: c_int = 0;
        c.Rtexture_get_size(@backingInt(self), &width, &height);
        return .{ .width = width, .height = height };
    }

    /// How the texture is smoothed when it is scaled. The textures made
    /// from image files start with R_FILTER_MIPMAP, the others with
    /// R_FILTER_LINEAR.
    pub fn setFilter(self: Texture, filter: FilterType) void {
        c.Rtexture_set_filter(@backingInt(self), @backingInt(filter));
    }
};

/// A handle of the library.
pub const Timer = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Timer {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Timer) Rid {
        return @backingInt(self);
    }

    /// Calls a function on the UI thread after `interval_seconds`.
    /// repeat R_TRUE to fire repeatedly, R_FALSE to fire once and delete itself.
    pub fn create(interval_seconds: f64, repeat: bool, context: anytype, comptime callback: ?fn (@TypeOf(context), Timer) void) Timer {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Timer, @fromBackingInt(a0)));
            }
        };
        const result = c.Rtimer_create(interval_seconds, @intFromBool(repeat), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
        return @fromBackingInt(result);
    }

    pub fn destroy(self: Timer) void {
        c.Rtimer_destroy(@backingInt(self));
    }

    pub fn isValid(self: Timer) bool {
        const result = c.Rtimer_is_valid(@backingInt(self));
        return result != 0;
    }
};

/// A handle of the library.
pub const XmlDocument = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?XmlDocument {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: XmlDocument) Rid {
        return @backingInt(self);
    }

    /// A new document with one element.
    pub fn create(root_tag: [:0]const u8) XmlDocument {
        const result = c.Rxml_document_create(root_tag.ptr);
        return @fromBackingInt(result);
    }

    /// Reads a text into a document. Comments are kept.
    /// error When not NULL, a mistake in the text is described there
    /// and nothing is reported; when NULL it goes to the error callback.
    /// Returns: The document, or R_INVALID_ID.
    pub fn parse(xml: []const u8, diagnostics: ?*XmlError) Error!XmlDocument {
        var raw_error: c.RXmlError = .{};
        const result = c.Rxml_document_parse(@ptrCast(xml.ptr), xml.len, if (diagnostics != null) &raw_error else null);
        if (diagnostics) |d| d.* = .fromC(raw_error);
        return XmlDocument.fromId(result) orelse (if (diagnostics != null) error.Xml else lastError());
    }

    /// Reads a file. The paths written in it are relative to its folder.
    pub fn load(path: [:0]const u8) Error!XmlDocument {
        const result = c.Rxml_document_load(path.ptr);
        return XmlDocument.fromId(result) orelse lastError();
    }

    /// Releases a document and its nodes. What was built from it lives on.
    pub fn destroy(self: XmlDocument) void {
        c.Rxml_document_destroy(@backingInt(self));
    }

    pub fn isValid(self: XmlDocument) bool {
        const result = c.Rxml_document_is_valid(@backingInt(self));
        return result != 0;
    }

    pub fn getRoot(self: XmlDocument) ?XmlNode {
        const result = c.Rxml_document_get_root(@backingInt(self));
        return XmlNode.fromId(result);
    }

    /// Writes the document as text, one element per line, indented
    /// with tabs. Rxml_node_get_line then says where each node was written.
    /// Returns: The text, valid until the next call for this document or its destruction.
    pub fn toString(self: XmlDocument) [:0]const u8 {
        const result = c.Rxml_document_to_string(@backingInt(self));
        return rt.span(result);
    }

    pub fn save(self: XmlDocument, path: [:0]const u8) Error!void {
        if (c.Rxml_document_save(@backingInt(self), path.ptr) == 0) return lastError();
    }

    /// Builds the widgets the document describes, as
    /// Rwidget_create_from_xml does. When the root is a <Window>, builds what
    /// the window would show (R_INVALID_ID when it is empty).
    pub fn createWidget(self: XmlDocument) Error!Widget {
        const result = c.Rxml_document_create_widget(@backingInt(self));
        return Widget.fromId(result) orelse lastError();
    }

    /// Builds the window the document describes, as Rwindow_create_from_xml does.
    pub fn createWindow(self: XmlDocument) Window {
        const result = c.Rxml_document_create_window(@backingInt(self));
        return @fromBackingInt(result);
    }
};

/// A handle of the library.
pub const XmlNode = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?XmlNode {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: XmlNode) Rid {
        return @backingInt(self);
    }

    pub fn isValid(self: XmlNode) bool {
        const result = c.Rxml_node_is_valid(@backingInt(self));
        return result != 0;
    }

    pub fn getDocument(self: XmlNode) ?XmlDocument {
        const result = c.Rxml_node_get_document(@backingInt(self));
        return XmlDocument.fromId(result);
    }

    /// Returns: The tag of an element, "" for a comment.
    pub fn getTag(self: XmlNode) [:0]const u8 {
        const result = c.Rxml_node_get_tag(@backingInt(self));
        return rt.span(result);
    }

    pub fn setTag(self: XmlNode, tag: [:0]const u8) void {
        c.Rxml_node_set_tag(@backingInt(self), tag.ptr);
    }

    pub fn isComment(self: XmlNode) bool {
        const result = c.Rxml_node_is_comment(@backingInt(self));
        return result != 0;
    }

    /// The text inside an element (<Label>this</Label>), or the text of a comment.
    pub fn getText(self: XmlNode) [:0]const u8 {
        const result = c.Rxml_node_get_text(@backingInt(self));
        return rt.span(result);
    }

    pub fn setText(self: XmlNode, text: [:0]const u8) void {
        c.Rxml_node_set_text(@backingInt(self), text.ptr);
    }

    pub fn getParent(self: XmlNode) ?XmlNode {
        const result = c.Rxml_node_get_parent(@backingInt(self));
        return XmlNode.fromId(result);
    }

    pub fn getChildCount(self: XmlNode) i32 {
        const result = c.Rxml_node_get_child_count(@backingInt(self));
        return result;
    }

    pub fn getChild(self: XmlNode, index: i32) ?XmlNode {
        const result = c.Rxml_node_get_child(@backingInt(self), index);
        return XmlNode.fromId(result);
    }

    /// Returns: The place of a node among the children of its parent; 0 for the root.
    pub fn getIndex(self: XmlNode) i32 {
        const result = c.Rxml_node_get_index(@backingInt(self));
        return result;
    }

    /// index Where among the children; -1 for the end.
    /// Returns: The new node; R_INVALID_ID (R_ERROR_XML) when it would be nested
    ///         deeper than a document can be: 256 levels under the root, as
    ///         when a text is read. The same holds for the functions below.
    pub fn addChild(self: XmlNode, tag: [:0]const u8, index: i32) ?XmlNode {
        const result = c.Rxml_node_add_child(@backingInt(self), tag.ptr, index);
        return XmlNode.fromId(result);
    }

    pub fn addComment(self: XmlNode, text: [:0]const u8, index: i32) ?XmlNode {
        const result = c.Rxml_node_add_comment(@backingInt(self), text.ptr, index);
        return XmlNode.fromId(result);
    }

    /// Reads a piece of XML (one element and what it contains) and
    /// adds it: what a palette, a paste or a template inserts.
    pub fn addXml(self: XmlNode, xml: []const u8, index: i32) ?XmlNode {
        const result = c.Rxml_node_add_xml(@backingInt(self), @ptrCast(xml.ptr), xml.len, index);
        return XmlNode.fromId(result);
    }

    /// Removes a node and what it contains. The root stays.
    pub fn remove(self: XmlNode) void {
        c.Rxml_node_remove(@backingInt(self));
    }

    /// Moves a node, with what it contains, under another parent of
    /// the same document or elsewhere under its own.
    /// index Where among the children of the new parent, counted once the node has left its place; -1 for the end.
    /// Returns: R_FALSE when it cannot be done (the root, a parent that is inside the node, or a place too deep).
    pub fn move(self: XmlNode, new_parent: XmlNode, index: i32) Error!void {
        if (c.Rxml_node_move(@backingInt(self), @backingInt(new_parent), index) == 0) return lastError();
    }

    /// Copies a node and what it contains, right after it. Returns the copy.
    pub fn duplicate(self: XmlNode) ?XmlNode {
        const result = c.Rxml_node_duplicate(@backingInt(self));
        return XmlNode.fromId(result);
    }

    /// The node as text. Valid until the next call for this document.
    pub fn toString(self: XmlNode) [:0]const u8 {
        const result = c.Rxml_node_to_string(@backingInt(self));
        return rt.span(result);
    }

    pub fn getAttributeCount(self: XmlNode) i32 {
        const result = c.Rxml_node_get_attribute_count(@backingInt(self));
        return result;
    }

    pub fn getAttributeName(self: XmlNode, index: i32) [:0]const u8 {
        const result = c.Rxml_node_get_attribute_name(@backingInt(self), index);
        return rt.span(result);
    }

    pub fn getAttributeValue(self: XmlNode, index: i32) [:0]const u8 {
        const result = c.Rxml_node_get_attribute_value(@backingInt(self), index);
        return rt.span(result);
    }

    /// Returns: The value of an attribute (names are compared without case), or NULL when the node does not have it.
    pub fn getAttribute(self: XmlNode, name: [:0]const u8) ?[:0]const u8 {
        const result = c.Rxml_node_get_attribute(@backingInt(self), name.ptr);
        return rt.optSpan(result);
    }

    /// Sets an attribute, added after the others when it is new. A NULL value removes it.
    pub fn setAttribute(self: XmlNode, name: ?[:0]const u8, value: ?[:0]const u8) void {
        c.Rxml_node_set_attribute(@backingInt(self), rt.optPtr(name), rt.optPtr(value));
    }

    /// Returns: The line of the node, starting at 1, in the text the document
    /// was read from or last written to; 0 for a node added since.
    pub fn getLine(self: XmlNode) i32 {
        const result = c.Rxml_node_get_line(@backingInt(self));
        return result;
    }

    /// Returns: The widget (the window, for a <Window>) the node became the
    /// last time the document was built, or R_INVALID_ID: never built,
    /// destroyed since, or not a widget (an <Item>, a comment). A tag declared
    /// with <Widget> gives the widget it stands for.
    pub fn getWidget(self: XmlNode) ?Widget {
        const result = c.Rxml_node_get_widget(@backingInt(self));
        return Widget.fromId(result);
    }
};

/// A handle of the library.
pub const Tray = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Tray {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Tray) Rid {
        return @backingInt(self);
    }

    /// Returns: R_TRUE when the system shows tray icons: always on Windows and
    /// macOS; on Linux, when a host of StatusNotifierItem runs (the panel of
    /// the desktop). An icon made where none runs yet appears when one starts.
    pub fn isSupported() bool {
        const result = c.Rtray_is_supported();
        return result != 0;
    }

    /// Puts an icon of the application beside the clock. While one
    /// exists, the application goes on running when its last window closes
    /// (Ris_running): Rquit (or the action app.quit) ends it.
    /// Returns: R_INVALID_ID where the system has none.
    pub fn create() Error!Tray {
        const result = c.Rtray_create();
        return Tray.fromId(result) orelse lastError();
    }

    pub fn destroy(self: Tray) void {
        c.Rtray_destroy(@backingInt(self));
    }

    pub fn isValid(self: Tray) bool {
        const result = c.Rtray_is_valid(@backingInt(self));
        return result != 0;
    }

    /// The picture, from tightly packed RGBA8 pixels (straight alpha);
    /// the system scales it (16 to 32 pixels square fit everywhere). Copied.
    pub fn setIcon(self: Tray, rgba: []const u8, width: i32, height: i32) void {
        std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
        c.Rtray_set_icon(@backingInt(self), rgba.ptr, width, height);
    }

    /// The text shown when the pointer rests on the icon (and its title for the Linux panels).
    pub fn setTooltip(self: Tray, text: [:0]const u8) void {
        c.Rtray_set_tooltip(@backingInt(self), text.ptr);
    }

    /// The menu the system shows for the icon: on a right click
    /// (Windows, Linux), on a click (macOS). A MENU without a parent, whose
    /// MenuItems fire as when chosen in a window; what changes in it shows
    /// the next time it opens. R_INVALID_ID: none.
    pub fn setMenu(self: Tray, menu: ?Widget) void {
        c.Rtray_set_menu(@backingInt(self), optId(menu));
    }

    /// Called on a click: the left button (activate), the right one
    /// when there is no menu, the middle one. On macOS an icon with a menu
    /// opens it instead.
    pub fn setClickedCallback(self: Tray, context: anytype, comptime callback: ?fn (@TypeOf(context), Tray, MouseButton) void) void {
        const Ctx = @TypeOf(context);
        const Trampoline = struct {
            fn call(a0: c.Rid, a1: c.RMouseButton, user_data: ?*anyopaque) callconv(.c) void {
                callback.?(rt.contextFromC(Ctx, user_data), @as(Tray, @fromBackingInt(a0)), @as(MouseButton, @fromBackingInt(a1)));
            }
        };
        c.Rtray_set_clicked_callback(@backingInt(self), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    }

    /// A short text shown beside the icon (macOS menu bar), drawn by the
    /// system in its own font and colors; the item widens to fit it. NULL or
    /// "": the icon alone. Systems that show no text there ignore it (the
    /// tooltip is the place for it).
    pub fn setTitle(self: Tray, text: ?[:0]const u8) void {
        c.Rtray_set_title(@backingInt(self), rt.optPtr(text));
    }

    /// Where the icon is on the screen, in the units and coordinates of
    /// Rwindow_set_position (a window can then open just under it).
    /// Returns: R_FALSE when the system does not tell (the outputs are then 0).
    pub fn getRect(self: Tray) ?struct { x: i32, y: i32, width: i32, height: i32 } {
        var x: c_int = 0;
        var y: c_int = 0;
        var width: c_int = 0;
        var height: c_int = 0;
        if (c.Rtray_get_rect(@backingInt(self), &x, &y, &width, &height) == 0) return null;
        return .{ .x = x, .y = y, .width = width, .height = height };
    }
};

/// A handle of the library.
pub const Shader = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?Shader {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: Shader) Rid {
        return @backingInt(self);
    }

    /// A shader from SPIR-V code (a fragment shader written with
    /// raven_effect.glsl, as in a .spv file): `size` bytes, copied. R_INVALID_ID
    /// when the code is not SPIR-V; a backend that refuses it reports an error
    /// and the effect is drawn as a rectangle.
    pub fn create(spirv: []const u8, flags: ShaderFlags) Error!Shader {
        const result = c.Rshader_create(@ptrCast(spirv.ptr), spirv.len, @as(u32, @bitCast(flags)));
        return Shader.fromId(result) orelse lastError();
    }

    /// The same, from a .spv file (UTF-8 path, relative to the current folder).
    pub fn createFromFile(path: [:0]const u8, flags: ShaderFlags) Error!Shader {
        const result = c.Rshader_create_from_file(path.ptr, @as(u32, @bitCast(flags)));
        return Shader.fromId(result) orelse lastError();
    }

    pub fn destroy(self: Shader) void {
        c.Rshader_destroy(@backingInt(self));
    }

    pub fn isValid(self: Shader) bool {
        const result = c.Rshader_is_valid(@backingInt(self));
        return result != 0;
    }

    pub fn getFlags(self: Shader) ShaderFlags {
        const result = c.Rshader_get_flags(@backingInt(self));
        return @as(ShaderFlags, @bitCast(@as(u32, result)));
    }

    /// Fills a look with the defaults of the shader when it is a built-in effect (else Rshader_look_init).
    pub fn lookDefaults(self: Shader) ShaderLook {
        var raw_look: c.RShaderLook = .{};
        c.Rshader_look_defaults(@backingInt(self), &raw_look);
        return .fromC(raw_look);
    }
};

/// A handle of the library.
pub const PdfDocument = enum(Rid) {
    _,

    /// The handle of an id; null for 0 and invalid_id.
    pub fn fromId(id: Rid) ?PdfDocument {
        return if (id == 0 or id == invalid_id) null else @fromBackingInt(id);
    }

    /// The id of the handle, for raven.c.
    pub fn toId(self: PdfDocument) Rid {
        return @backingInt(self);
    }

    /// The PDF file of the document, copied into memory of `allocator`.
    pub fn saveMemory(self: PdfDocument, allocator: std.mem.Allocator) (Error || std.mem.Allocator.Error)![]u8 {
        var size: usize = 0;
        const data = c.Rpdf_document_save_memory(@backingInt(self), &size) orelse return lastError();
        defer c.Rmemory_free(data);
        return allocator.dupe(u8, @as([*]const u8, @ptrCast(data))[0..size]);
    }

    pub fn create() PdfDocument {
        const result = c.Rpdf_document_create();
        return @fromBackingInt(result);
    }

    pub fn delete(self: PdfDocument) void {
        c.Rpdf_document_delete(@backingInt(self));
    }

    /// The information of the document, shown by readers (the title in their window).
    pub fn setTitle(self: PdfDocument, title: [:0]const u8) void {
        c.Rpdf_document_set_title(@backingInt(self), title.ptr);
    }

    pub fn setAuthor(self: PdfDocument, author: [:0]const u8) void {
        c.Rpdf_document_set_author(@backingInt(self), author.ptr);
    }

    pub fn setSubject(self: PdfDocument, subject: [:0]const u8) void {
        c.Rpdf_document_set_subject(@backingInt(self), subject.ptr);
    }

    /// Adds a page of a size in points; drawing goes to it. Returns its index, -1 for an invalid size.
    pub fn addPage(self: PdfDocument, width: f32, height: f32) i32 {
        const result = c.Rpdf_document_add_page(@backingInt(self), width, height);
        return result;
    }

    pub fn getPageCount(self: PdfDocument) i32 {
        const result = c.Rpdf_document_get_page_count(@backingInt(self));
        return result;
    }

    pub fn setFillColor(self: PdfDocument, color: Color) void {
        c.Rpdf_document_set_fill_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    pub fn setStrokeColor(self: PdfDocument, color: Color) void {
        c.Rpdf_document_set_stroke_color(@backingInt(self), color.r, color.g, color.b, color.a);
    }

    /// Width of the lines and outlines, in points (default 1).
    pub fn setLineWidth(self: PdfDocument, width: f32) void {
        c.Rpdf_document_set_line_width(@backingInt(self), width);
    }

    /// A rectangle, its corners rounded by `radius`; `paint` is a bitmask of RPdfPaint.
    pub fn drawRect(self: PdfDocument, x: f32, y: f32, width: f32, height: f32, radius: f32, paint: u32) void {
        c.Rpdf_document_draw_rect(@backingInt(self), x, y, width, height, radius, paint);
    }

    /// The ellipse inside a rectangle.
    pub fn drawEllipse(self: PdfDocument, x: f32, y: f32, width: f32, height: f32, paint: u32) void {
        c.Rpdf_document_draw_ellipse(@backingInt(self), x, y, width, height, paint);
    }

    /// A line in the stroke color.
    pub fn drawLine(self: PdfDocument, x1: f32, y1: f32, x2: f32, y2: f32) void {
        c.Rpdf_document_draw_line(@backingInt(self), x1, y1, x2, y2);
    }

    /// Adds a TrueType font (.ttf) to the document (the data is
    /// copied, and embedded in the file). Returns its number for
    /// Rpdf_document_set_font, -1 when it is not a TrueType font.
    pub fn addFont(self: PdfDocument, data: []const u8) i32 {
        const result = c.Rpdf_document_add_font(@backingInt(self), @ptrCast(data.ptr), data.len);
        return result;
    }

    pub fn addFontFromFile(self: PdfDocument, path: [:0]const u8) i32 {
        const result = c.Rpdf_document_add_font_from_file(@backingInt(self), path.ptr);
        return result;
    }

    /// The font of the text drawn next: an RPdfFont or a number of Rpdf_document_add_font, a size in points, a bitmask of RPdfTextStyle.
    pub fn setFont(self: PdfDocument, font: i32, size: f32, style: u32) void {
        c.Rpdf_document_set_font(@backingInt(self), font, size, style);
    }

    /// Distance between two lines of text in the current font.
    pub fn getLineHeight(self: PdfDocument) f32 {
        const result = c.Rpdf_document_get_line_height(@backingInt(self));
        return result;
    }

    /// Width of a text in the current font, in points (of its widest line).
    pub fn measureText(self: PdfDocument, text: [:0]const u8) f32 {
        const result = c.Rpdf_document_measure_text(@backingInt(self), text.ptr);
        return result;
    }

    /// Text in the fill color, the top of its first line at y ('\n'
    /// starts a line below). Returns its width.
    pub fn drawText(self: PdfDocument, x: f32, y: f32, text: [:0]const u8) f32 {
        const result = c.Rpdf_document_draw_text(@backingInt(self), x, y, text.ptr);
        return result;
    }

    /// Text wrapped at the spaces to fit `width`, each line placed by
    /// `align` (R_HALIGN_LEFT, R_HALIGN_CENTER or R_HALIGN_RIGHT). Returns the
    /// height it took.
    pub fn drawParagraph(self: PdfDocument, x: f32, y: f32, width: f32, text: [:0]const u8, align_: HAlign) f32 {
        const result = c.Rpdf_document_draw_paragraph(@backingInt(self), x, y, width, text.ptr, @backingInt(align_));
        return result;
    }

    /// A picture of RGBA8 pixels stretched over a rectangle. A width or
    /// height of 0 keeps the proportions of the picture; both 0: 96 pixels per inch.
    pub fn drawImage(self: PdfDocument, x: f32, y: f32, width: f32, height: f32, rgba: []const u8, pixels_width: i32, pixels_height: i32) void {
        std.debug.assert(rgba.len >= @as(usize, @intCast(pixels_width)) * @as(usize, @intCast(pixels_height)) * 4);
        c.Rpdf_document_draw_image(@backingInt(self), x, y, width, height, rgba.ptr, pixels_width, pixels_height);
    }

    /// What a window shows (Rwindow_capture), as a picture: a report of
    /// the screen, a chart. A width and height of 0: the size it has on the
    /// screen. Returns R_FALSE when the window cannot be captured.
    pub fn drawWindow(self: PdfDocument, window: Window, x: f32, y: f32, width: f32, height: f32) Error!void {
        if (c.Rpdf_document_draw_window(@backingInt(self), @backingInt(window), x, y, width, height) == 0) return lastError();
    }

    /// Writes the file. Returns R_FALSE when it cannot be written.
    pub fn save(self: PdfDocument, path: [:0]const u8) Error!void {
        if (c.Rpdf_document_save(@backingInt(self), path.ptr) == 0) return lastError();
    }

    /// Prints a document written by the application.
    pub fn print(self: PdfDocument, desc: PdfPrintDesc) bool {
        const raw_desc = desc.toC();
        const result = c.Rpdf_document_print(@backingInt(self), &raw_desc);
        return result != 0;
    }
};

/// What a paint callback draws with (RPainter).
pub const Painter = opaque {
    /// Filled rectangle with rounded corners (radius 0 = sharp).
    pub fn rect(self: *Painter, x: f32, y: f32, width: f32, height: f32, radius: f32, color: Color) void {
        c.Rdraw_rect(@ptrCast(self), x, y, width, height, radius, color.r, color.g, color.b, color.a);
    }

    /// Soft shadow or glow: a rounded rectangle blurred by `blur` logical units.
    /// Offset the rectangle for a drop shadow, or draw it under a shape for a glow.
    /// Nonpositive width, height or blur draws nothing. Uses the same primitive as Border shadows.
    pub fn shadow(self: *Painter, x: f32, y: f32, width: f32, height: f32, radius: f32, blur: f32, color: Color) void {
        c.Rdraw_shadow(@ptrCast(self), x, y, width, height, radius, blur, color.r, color.g, color.b, color.a);
    }

    /// Outline of a rounded rectangle, drawn inside its bounds.
    pub fn rectOutline(self: *Painter, x: f32, y: f32, width: f32, height: f32, radius: f32, thickness: f32, color: Color) void {
        c.Rdraw_rect_outline(@ptrCast(self), x, y, width, height, radius, thickness, color.r, color.g, color.b, color.a);
    }

    pub fn circle(self: *Painter, center_x: f32, center_y: f32, radius: f32, color: Color) void {
        c.Rdraw_circle(@ptrCast(self), center_x, center_y, radius, color.r, color.g, color.b, color.a);
    }

    /// Anti-aliased line with round caps.
    pub fn line(self: *Painter, x0: f32, y0: f32, x1: f32, y1: f32, thickness: f32, color: Color) void {
        c.Rdraw_line(@ptrCast(self), x0, y0, x1, y1, thickness, color.r, color.g, color.b, color.a);
    }

    /// Anti-aliased cubic Bezier curve from (x0, y0) to (x1, y1), pulled by two control points.
    pub fn curve(self: *Painter, x0: f32, y0: f32, cx0: f32, cy0: f32, cx1: f32, cy1: f32, x1: f32, y1: f32, thickness: f32, color: Color) void {
        c.Rdraw_curve(@ptrCast(self), x0, y0, cx0, cy0, cx1, cy1, x1, y1, thickness, color.r, color.g, color.b, color.a);
    }

    pub fn triangle(self: *Painter, x0: f32, y0: f32, x1: f32, y1: f32, x2: f32, y2: f32, color: Color) void {
        c.Rdraw_triangle(@ptrCast(self), x0, y0, x1, y1, x2, y2, color.r, color.g, color.b, color.a);
    }

    /// Texture stretched to a rectangle and multiplied by a tint color.
    pub fn image(self: *Painter, texture: Texture, x: f32, y: f32, width: f32, height: f32, color: Color) void {
        c.Rdraw_image(@ptrCast(self), @backingInt(texture), x, y, width, height, color.r, color.g, color.b, color.a);
    }

    /// Draws UTF-8 text; (x, y) is the top-left corner of the first line.
    /// font R_INVALID_ID uses the theme font.
    /// size 0 uses R_METRIC_FONT_SIZE.
    pub fn text(self: *Painter, font: ?Font, size: f32, x: f32, y: f32, text_: [:0]const u8, color: Color) void {
        c.Rdraw_text(@ptrCast(self), optId(font), size, x, y, text_.ptr, color.r, color.g, color.b, color.a);
    }

    /// Rounded rectangle of glass. It shows what was drawn before it,
    /// frosted and bent along its rim, under a tint: (r, g, b) is the color of
    /// the tint and `a` its strength (0 = clear glass, 1 = opaque color).
    /// Works with any theme. Needs a backend that implements glass (the Vulkan
    /// backend does).
    pub fn glass(self: *Painter, x: f32, y: f32, width: f32, height: f32, radius: f32, color: Color) void {
        c.Rdraw_glass(@ptrCast(self), x, y, width, height, radius, color.r, color.g, color.b, color.a);
    }

    /// Animates a value from the paint callback of a custom widget.
    /// Moves the spring toward `target` by the time elapsed since the last
    /// frame and returns its value. While it moves, the window keeps drawing
    /// frames by itself. The first call puts the spring on its target.
    ///
    ///     static RSpring size;                                  (zeroed)
    ///     float s = Rdraw_spring(painter, &size, hovered ? 1.0f : 0.0f, R_MOTION_BOUNCY);
    ///     Rdraw_circle(painter, cx, cy, 20.0f + 8.0f * s, ...);
    pub fn spring(self: *Painter, spring_: *Spring, target: f32, motion: Motion) f32 {
        var raw_spring = spring_.toC();
        const result = c.Rdraw_spring(@ptrCast(self), &raw_spring, target, @backingInt(motion));
        spring_.* = .fromC(raw_spring);
        return result;
    }

    /// Restricts the following draws to a rectangle, intersected with the current one.
    pub fn pushClipRect(self: *Painter, x: f32, y: f32, width: f32, height: f32) void {
        c.Rdraw_push_clip_rect(@ptrCast(self), x, y, width, height);
    }

    pub fn popClipRect(self: *Painter) void {
        c.Rdraw_pop_clip_rect(@ptrCast(self));
    }

    /// From a paint callback: draws the effect over a rectangle of the
    /// widget (logical units, from its top left corner).
    pub fn shader(self: *Painter, shader_: Shader, x: f32, y: f32, width: f32, height: f32, look: ShaderLook) void {
        const raw_look = look.toC();
        c.Rdraw_shader(@ptrCast(self), @backingInt(shader_), x, y, width, height, &raw_look);
    }
};

// ---- functions

/// Starts the library with default settings on the given backend.
/// The calling thread becomes the UI thread.
/// Returns: R_TRUE on success. On failure, see Rerror_get_last.
pub fn init(backend: Backend) Error!void {
    if (c.Rinit(@backingInt(backend)) == 0) return lastError();
}

/// Starts the library with explicit settings.
/// desc Settings, or NULL for the defaults.
pub fn initEx(desc: ?InitDesc) Error!void {
    const raw_desc: ?c.RInitDesc = if (desc) |v| v.toC() else null;
    if (c.Rinit_ex(if (raw_desc) |*v| v else null) == 0) return lastError();
}

/// Destroys every window, widget and resource, stops the worker and
/// render threads and releases the backend.
pub fn shutdown() void {
    c.Rshutdown();
}

pub fn isInitialized() bool {
    const result = c.Ris_initialized();
    return result != 0;
}

/// Returns: The library version, e.g. "0.1.0".
pub fn getVersion() [:0]const u8 {
    const result = c.Rget_version();
    return rt.span(result);
}

/// Returns: An allocator that forwards to malloc, realloc and free of the C
/// runtime: Rset_allocator(Rallocator_get_system()) is how memory tools
/// that follow malloc (Valgrind, heap profilers) see the blocks of Raven.
/// The environment variable RAVEN_ALLOCATOR=system does the same without
/// recompiling, and it is the default in a build with AddressSanitizer.
pub fn allocatorGetSystem() *const c.RAllocator {
    return c.Rallocator_get_system().?;
}

/// Memory from the allocator of Raven (or from the one given to
/// Rset_allocator), for the application: custom widgets, pixel buffers.
/// Aligned on 16 bytes. Never returns NULL: running out of memory is a
/// fatal error. Thread-safe.
pub fn memoryAlloc(size: usize) ?*anyopaque {
    const result = c.Rmemory_alloc(size);
    return result;
}

/// Resizes a block, keeping its content. A NULL block is allocated. Thread-safe.
pub fn memoryRealloc(ptr: ?*anyopaque, size: usize) ?*anyopaque {
    const result = c.Rmemory_realloc(ptr, size);
    return result;
}

/// Frees a block. NULL is ignored. Thread-safe.
pub fn memoryFree(ptr: ?*anyopaque) void {
    c.Rmemory_free(ptr);
}

/// What the library holds right now. Thread-safe.
pub fn memoryGetStats() MemoryStats {
    var raw_stats: c.RMemoryStats = .{};
    c.Rmemory_get_stats(&raw_stats);
    return .fromC(raw_stats);
}

/// Walks the whole heap of Raven and verifies its structure.
/// Returns: R_FALSE when it is corrupted (a buffer overrun wrote over a block
/// header). Slow: for tests and for hunting a bug. Thread-safe.
pub fn memoryCheck() bool {
    const result = c.Rmemory_check();
    return result != 0;
}

/// Returns to the OS the regions of the heap that hold nothing. Thread-safe.
pub fn memoryTrim() void {
    c.Rmemory_trim();
}

/// Produces one frame: processes the pending OS events without
/// waiting, runs the posted tasks and the timers, then lays out, paints and
/// submits every window that changed. A window in which nothing changed is
/// not drawn again, so the call is cheap when the UI is idle.
/// Returns: R_FALSE once Rquit was called or the last window is closed.
pub fn drawFrame() bool {
    const result = c.Rdraw_frame();
    return result != 0;
}

/// Same as Rdraw_frame, but first sleeps until there is something to
/// do: an OS event, a posted task, a timer, an animation, a pending redraw.
/// timeout_seconds Longest sleep. Negative sleeps without limit, 0
/// does not sleep.
pub fn waitFrame(timeout_seconds: f64) bool {
    const result = c.Rwait_frame(timeout_seconds);
    return result != 0;
}

/// Makes Rdraw_frame and Rwait_frame return R_FALSE. Thread-safe.
pub fn quit(exit_code: i32) void {
    c.Rquit(exit_code);
}

/// Returns: The code given to Rquit, 0 when the last window was closed.
pub fn getExitCode() i32 {
    const result = c.Rget_exit_code();
    return result;
}

/// Returns: R_FALSE once Rquit was called or every window is closed.
pub fn isRunning() bool {
    const result = c.Ris_running();
    return result != 0;
}

/// Processes the pending OS events without producing a frame.
/// Rdraw_frame does it already: only useful to keep the windows responsive
/// during a long operation.
pub fn pollEvents() void {
    c.Rpoll_events();
}

/// Sleeps until an OS event, a posted task, a timer or a pending
/// redraw, and processes the OS events. Rwait_frame does it already.
/// timeout_seconds Maximum wait. Negative waits without limit.
pub fn waitEvents(timeout_seconds: f64) void {
    c.Rwait_events(timeout_seconds);
}

pub fn setFrameCallback(context: anytype, comptime callback: ?fn (@TypeOf(context), f64) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: f64, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), a0);
        }
    };
    c.Rset_frame_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Returns: Seconds between the last two frames.
pub fn getDeltaTime() f64 {
    const result = c.Rget_delta_time();
    return result;
}

/// Returns: Seconds elapsed since Rinit, from a monotonic clock. Thread-safe.
pub fn getTime() f64 {
    const result = c.Rget_time();
    return result;
}

pub fn setAppEventCallback(context: anytype, comptime callback: ?fn (@TypeOf(context), AppEvent) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RAppEvent, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(AppEvent, @fromBackingInt(a0)));
        }
    };
    c.Rset_app_event_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Returns: R_TRUE between R_APP_DID_PAUSE and R_APP_WILL_RESUME: the application is in the background.
pub fn isAppPaused() bool {
    const result = c.Ris_app_paused();
    return result != 0;
}

/// Handles an RAppEvent as if the system had sent it: for tests,
/// and for a host application (raven_host.h) that knows the lifecycle.
/// UI thread.
pub fn injectAppEvent(event: AppEvent) void {
    c.Rinject_app_event(@backingInt(event));
}

/// Scale of the whole interface, on top of the one of the monitor
/// (RInitDesc.ui_scale at start): every window is laid out again. 0.25 .. 4.
pub fn setUiScale(scale: f32) void {
    c.Rset_ui_scale(scale);
}

/// R_TRUE: every frame waits for the vertical synchronization of the
/// screen (no tearing, no wasted frames); R_FALSE: as fast as possible
/// (RInitDesc.disable_vsync at start). Takes effect at the next frame.
pub fn setVsync(enabled: bool) void {
    c.Rset_vsync(@intFromBool(enabled));
}

pub fn getVsync() i32 {
    const result = c.Rget_vsync();
    return result;
}

pub fn getUiScale() f32 {
    const result = c.Rget_ui_scale();
    return result;
}

/// R_FALSE makes every change immediate: for users who ask for
/// reduced motion (Raccessibility_set_reduce_motion), and for tests that
/// read the state right after an input.
pub fn setAnimationsEnabled(enabled: bool) void {
    c.Rset_animations_enabled(@intFromBool(enabled));
}

pub fn getAnimationsEnabled() i32 {
    const result = c.Rget_animations_enabled();
    return result;
}

/// Multiplies the speed of every animation. 1 is the default, 0.25 a slow motion.
pub fn setAnimationSpeed(speed: f32) void {
    c.Rset_animation_speed(speed);
}

pub fn getAnimationSpeed() f32 {
    const result = c.Rget_animation_speed();
    return result;
}

/// When positive, each frame advances the animations by exactly this
/// many seconds instead of the time really elapsed: frames rendered one by
/// one for a video or a screenshot, deterministic tests. 0 follows the clock.
pub fn setAnimationTimeStep(seconds: f64) void {
    c.Rset_animation_time_step(seconds);
}

/// Queues a function to run on the UI thread during the next frame
/// and wakes Rwait_frame. Thread-safe: this is how worker threads touch the UI.
pub fn taskPost(context: anytype, comptime task: ?fn (@TypeOf(context)) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(user_data: ?*anyopaque) callconv(.c) void {
            task.?(rt.contextFromC(Ctx, user_data));
        }
    };
    c.Rtask_post(if (task != null) &Trampoline.call else null, if (task != null) rt.contextToC(context) else null);
}

/// Runs a function on a worker thread of the job system. Thread-safe.
pub fn taskRunAsync(context: anytype, comptime task: ?fn (@TypeOf(context)) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(user_data: ?*anyopaque) callconv(.c) void {
            task.?(rt.contextFromC(Ctx, user_data));
        }
    };
    c.Rtask_run_async(if (task != null) &Trampoline.call else null, if (task != null) rt.contextToC(context) else null);
}

/// Splits [0, count) into ranges of at most `grain` items and runs them
/// on the worker threads and the calling thread. Returns when all are done.
pub fn parallelFor(count: u32, grain: u32, context: anytype, comptime callback: ?fn (@TypeOf(context), u32, u32) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: u32, a1: u32, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), a0, a1);
        }
    };
    c.Rparallel_for(count, grain, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Wakes Rwait_frame and Rwait_events from any thread.
pub fn wakeUp() void {
    c.Rwake_up();
}

pub fn getWorkerThreadCount() i32 {
    const result = c.Rget_worker_thread_count();
    return result;
}

pub fn isUiThread() bool {
    const result = c.Ris_ui_thread();
    return result != 0;
}

pub fn actionBind(name: [:0]const u8, context: anytype, comptime callback: ?fn (@TypeOf(context), ?Widget, [:0]const u8) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), Widget.fromId(a0), rt.span(a1));
        }
    };
    c.Raction_bind(name.ptr, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

pub fn actionUnbind(name: [:0]const u8) void {
    c.Raction_unbind(name.ptr);
}

/// Fires an action as a widget would: the function bound to the
/// name is called, or the default handler. What a tool bar button, a
/// script or a test uses to do what a menu item does.
/// sender Passed to the function; R_INVALID_ID when there is none.
pub fn actionFire(name: [:0]const u8, sender: ?Widget) void {
    c.Raction_fire(name.ptr, optId(sender));
}

/// Receives every action that has no bound function and is not one of the built-in actions (e.g. a script bridge).
pub fn actionSetDefaultHandler(context: anytype, comptime callback: ?fn (@TypeOf(context), ?Widget, [:0]const u8) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.Rid, a1: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), Widget.fromId(a0), rt.span(a1));
        }
    };
    c.Raction_set_default_handler(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

pub fn actionBindWithParameters(name: [:0]const u8, signature: [:0]const u8, context: anytype, comptime callback: ?fn (@TypeOf(context), *Painter) void) i32 {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: ?*c.RActionContext, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @ptrCast(a0.?));
        }
    };
    const result = c.Raction_bind_with_parameters(name.ptr, signature.ptr, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    return result;
}

/// Returns: The widget whose event fired the action, R_INVALID_ID when a script calls it.
pub fn actionGetSender(context: *Painter) c.Rid {
    const result = c.Raction_get_sender(@ptrCast(context));
    return result;
}

pub fn actionGetName(context: *Painter) [:0]const u8 {
    const result = c.Raction_get_name(@ptrCast(context));
    return rt.span(result);
}

/// Returns: The number of arguments given: the parameters of the signature, fewer when an event gives fewer... never more.
pub fn actionGetArgumentCount(context: *Painter) i32 {
    const result = c.Raction_get_argument_count(@ptrCast(context));
    return result;
}

/// The arguments, by position from 0. A wrong index or type reports an error and gives 0, "" or R_FALSE.
pub fn actionGetNumber(context: *Painter, index: i32) f64 {
    const result = c.Raction_get_number(@ptrCast(context), index);
    return result;
}

/// Returns: Valid until the function returns.
pub fn actionGetString(context: *Painter, index: i32) [:0]const u8 {
    const result = c.Raction_get_string(@ptrCast(context), index);
    return rt.span(result);
}

pub fn actionGetBool(context: *Painter, index: i32) i32 {
    const result = c.Raction_get_bool(@ptrCast(context), index);
    return result;
}

/// The value returned to the script; of the type of the signature (what is set last counts).
pub fn actionReturnNumber(context: *Painter, value: f64) void {
    c.Raction_return_number(@ptrCast(context), value);
}

pub fn actionReturnString(context: *Painter, value: [:0]const u8) void {
    c.Raction_return_string(@ptrCast(context), value.ptr);
}

pub fn actionReturnBool(context: *Painter, value: i32) void {
    c.Raction_return_bool(@ptrCast(context), value);
}

/// The function failed: the script that called it stops with error
/// RS205 and this message (the application goes on; so does the next event).
pub fn actionFail(context: *Painter, message: [:0]const u8) void {
    c.Raction_fail(@ptrCast(context), message.ptr);
}

/// The actions Raven knows by itself: an interface written in XML
/// uses them with no C at all (OnClicked="app.quit").
///
///   app.quit                          quits (Rquit(0))
///   window.close, window.minimize,    the window of the widget
///   window.maximize, window.restore   (maximize goes back when it already is)
///   window.picture_in_picture         in and out of picture in picture
///   island.expand, island.fold,       the island of that window
///   island.toggle
///   theme.dark, theme.light,          the look of Raven, dark or light
///   theme.toggle
///   theme:NAME                        Rtheme_use(NAME): a theme loaded or built in
///   language:CODE                     Rlocale_set_language(CODE)
///   open:ADDRESS                      Ropen_url (https:, mailto:, a file)
///   copy:TEXT                         the text to the clipboard
///   show:NAME, hide:NAME, toggle:NAME the widget named NAME in the window (hidden: Collapsed)
///   enable:NAME, disable:NAME
///   focus:NAME
///   page:NAME=2, page:NAME=+1         what a Switcher, a TabView, a ComboBox or a ListView
///                                     shows; +1 and -1 step, and go round
///
/// A function bound to one of these names (Raction_bind) replaces it; the
/// default handler receives the others only.
/// enabled R_FALSE turns them all off: a design tool that shows
/// interfaces without running them. On by default.
pub fn actionSetBuiltins(enabled: bool) void {
    c.Raction_set_builtins(@intFromBool(enabled));
}

/// Returns: R_TRUE when the name is one of the built-in actions (Raction_set_builtins), whether they are on or not.
pub fn actionIsBuiltin(name: [:0]const u8) bool {
    const result = c.Raction_is_builtin(name.ptr);
    return result != 0;
}

/// Opens an address with the program the user has for it: a web
/// page in the browser, a mailto: in the mail program, a file in its
/// application. Returns at once. On iOS and Android the system opens it
/// (a web page, a tel:, a mailto:; not a file: share it with Rshare_show),
/// and Raven must be initialized and this be called on the UI thread.
/// Returns: R_FALSE when the OS could not be asked (nothing tells whether
/// a program then really opened it).
pub fn openUrl(url: [:0]const u8) Error!void {
    if (c.Ropen_url(url.ptr) == 0) return lastError();
}

pub fn clipboardSetText(text: [:0]const u8) void {
    c.Rclipboard_set_text(text.ptr);
}

/// Copies one content in two formats: `html` for the programs that
/// paste formatting (word processors, chat, mail) and `text` for the
/// others (editors, terminals). Each program takes the format it prefers.
/// Where the window system has no clipboard formats, or `html` is NULL,
/// it is Rclipboard_set_text(text).
pub fn clipboardSetHtml(text: ?[:0]const u8, html: ?[:0]const u8) void {
    c.Rclipboard_set_html(rt.optPtr(text), rt.optPtr(html));
}

/// Returns: The clipboard text, or "" when empty. Valid until the next call.
/// On iOS a read that does not follow a paste of the user (the Paste of a
/// menu, a button, Command-V) shows the system's question "Allow Paste?",
/// and on Android 12+ the system says that the application pasted: read it
/// when the user pastes, not to look at it. Android lets only the
/// application in front read it.
pub fn clipboardGetText() [:0]const u8 {
    const result = c.Rclipboard_get_text();
    return rt.span(result);
}

/// Returns: R_TRUE when the clipboard holds text, without reading it (no
/// question of the system on iOS): to enable a Paste button.
pub fn clipboardHasText() bool {
    const result = c.Rclipboard_has_text();
    return result != 0;
}

/// Replaces what the clipboard holds with one content in several
/// formats (RDataItem): each program pastes the one it prefers.
/// Returns: R_TRUE when every format was put on the clipboard; R_FALSE when
/// some could not be (a window system that only takes text: X11 and
/// Wayland for now, where the text/plain item, if any, still is).
pub fn clipboardSetData(items: []const DataItem) bool {
    const result = c.Rclipboard_set_data(@ptrCast(items.ptr), @intCast(items.len));
    return result != 0;
}

/// Returns: R_TRUE when the clipboard holds this format (Rclipboard_set_data), or one Raven converts to it.
pub fn clipboardHasData(mime: [:0]const u8) bool {
    const result = c.Rclipboard_has_data(mime.ptr);
    return result != 0;
}

/// What the clipboard holds in one format, converted from the
/// native one when needed (a bitmap given as image/png...).
/// Returns: The bytes, followed by a '\0' that `size` does not count, to
/// release with Rmemory_free; NULL when the clipboard does not hold it.
pub fn clipboardGetData(allocator: std.mem.Allocator, mime: ?[:0]const u8) std.mem.Allocator.Error!?[]u8 {
    var size: usize = 0;
    const result = c.Rclipboard_get_data(rt.optPtr(mime), &size) orelse return null;
    defer c.Rmemory_free(result);
    return try allocator.dupe(u8, @as([*]const u8, @ptrCast(result))[0..size]);
}

/// Copies a picture: RGBA8 pixels, straight alpha, rows `stride`
/// bytes apart (0: width * 4). It goes on the clipboard as image/png
/// (and as the bitmaps of the system), so that image editors, documents
/// and mail paste it.
/// Returns: R_FALSE when it could not be put there.
pub fn clipboardSetImage(rgba: []const u8, width: i32, height: i32, stride: i32) bool {
    std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
    const result = c.Rclipboard_set_image(rgba.ptr, width, height, stride);
    return result != 0;
}

/// Returns: R_TRUE when the clipboard holds a picture Rclipboard_get_image can read.
pub fn clipboardHasImage() bool {
    const result = c.Rclipboard_has_image();
    return result != 0;
}

/// The picture on the clipboard (copied from any program: PNG,
/// TIFF, a bitmap...), as tightly packed RGBA8 pixels, straight alpha.
/// Returns: The pixels, to release with Rpixels_free; NULL when there is
/// none (or no decoder: RAVEN_WITH_STB_IMAGE off).
pub fn clipboardGetImage(allocator: std.mem.Allocator) std.mem.Allocator.Error!?Pixels {
    var width: c_int = 0;
    var height: c_int = 0;
    const result = c.Rclipboard_get_image(&width, &height) orelse return null;
    defer c.Rpixels_free(result);
    const pixel_bytes = @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4;
    return .{ .pixels = try allocator.dupe(u8, result[0..pixel_bytes]), .width = width, .height = height };
}

pub fn errorToString(error_: ErrorCode) [:0]const u8 {
    const result = c.Rerror_to_string(@backingInt(error_));
    return rt.span(result);
}

pub fn severityToString(severity: Severity) [:0]const u8 {
    const result = c.Rseverity_to_string(@backingInt(severity));
    return rt.span(result);
}

pub fn errorSetCallback(comptime callback: ?fn (ErrorCode, Severity, [:0]const u8) void) void {
    const Trampoline = struct {
        fn call(a0: c.RError, a1: c.RSeverity, a2: ?[*:0]const u8) callconv(.c) void {
            callback.?(@as(ErrorCode, @fromBackingInt(a0)), @as(Severity, @fromBackingInt(a1)), rt.span(a2));
        }
    };
    c.Rerror_set_callback(if (callback != null) &Trampoline.call else null);
}

pub fn setDeviceResetCallback(context: anytype, comptime callback: ?fn (@TypeOf(context)) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data));
        }
    };
    c.Rset_device_reset_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// During R_DROP_ENTER / R_DROP_MOVE only: choose Raven's highlight
/// in target-local logical units (window-local for a window callback).
/// Clipped to the target; zero width or height hides it without refusing
/// the drop. Each callback starts with the default highlight again.
/// Dimensions must be finite and nonnegative; coordinates must be finite.
pub fn dropSetHighlightRect(x: f32, y: f32, width: f32, height: f32) void {
    c.Rdrop_set_highlight_rect(x, y, width, height);
}

/// Starts dragging `data` from `source` (call it while a mouse button
/// is held, typically from a mouse-move event once the pointer has moved
/// a few units). Until the button is released, the widgets with a drop
/// callback (Rwidget_set_drop_callback) under the pointer receive
/// R_DROP_ENTER / MOVE / LEAVE and, on release, R_DROP_DROPPED, with
/// `drag_type` set and `text` = `data`. Returning R_FALSE from the callback
/// refuses the drop there. Escape cancels. `label` follows the pointer.
/// Returns: R_FALSE when the widget is not in a window.
pub fn dragBegin(source: Widget, type_: [:0]const u8, data: [:0]const u8, label: [:0]const u8) bool {
    const result = c.Rdrag_begin(@backingInt(source), type_.ptr, data.ptr, label.ptr);
    return result != 0;
}

/// R_TRUE while a drag started by Rdrag_begin is in progress in the window.
pub fn dragIsActive(window: Window) bool {
    const result = c.Rdrag_is_active(@backingInt(window));
    return result != 0;
}

/// Type of the drag in progress, or NULL.
pub fn dragGetType(window: Window) ?[:0]const u8 {
    const result = c.Rdrag_get_type(@backingInt(window));
    return rt.optSpan(result);
}

/// Data of the drag in progress, or NULL.
pub fn dragGetData(window: Window) ?[:0]const u8 {
    const result = c.Rdrag_get_data(@backingInt(window));
    return rt.optSpan(result);
}

/// Ends the drag in progress without dropping (the target receives R_DROP_LEAVE).
pub fn dragCancel(window: Window) void {
    c.Rdrag_cancel(@backingInt(window));
}

/// Lets the user drag data out of the window, to another
/// application: a picture into a document, files into the file manager,
/// text into an editor. `items` is one content in several formats
/// (RDataItem, copied): the target takes the one it prefers.
/// `operations` is a bitmask of RDragOperation the target may do (0:
/// R_DRAG_OPERATION_COPY).
///
/// Call it as Rdrag_begin, while the mouse button is held (from a mouse
/// move once the pointer has moved a few units). The window system then
/// takes the drag at the next move of the pointer: it shows the picture
/// that follows the pointer (Rdrag_set_image) and the cursor that tells
/// what a drop there does; the button released, `callback` (may be NULL)
/// is told what the target did.
///
/// Called while a drag inside the application (Rdrag_begin) is in progress
/// in the window of `source`, it gives that drag the data for outside:
/// the drag stays inside the window, to its drop targets, and becomes a
/// drag of the window system only when the pointer leaves the window.
/// Brought back over a window of the application, it still comes to the
/// drop targets with the type and data given to Rdrag_begin.
///
/// Implemented on macOS and Windows; elsewhere it returns R_FALSE
/// (Rdrag_external_supported).
/// Returns: R_FALSE when the widget is not in a window or the window
/// system cannot drag out of its windows.
pub fn dragBeginExternal(source: Widget, items: []const DataItem, operations: u32, context: anytype, comptime callback: ?fn (@TypeOf(context), Widget, DragOperation) void) bool {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.Rid, a1: c.RDragOperation, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), @as(DragOperation, @bitCast(@as(c_int, a1))));
        }
    };
    const result = c.Rdrag_begin_external(@backingInt(source), @ptrCast(items.ptr), @intCast(items.len), operations, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
    return result != 0;
}

/// The picture that follows the pointer during the drag given by
/// Rdrag_begin_external (RGBA8 pixels, straight alpha, tightly packed,
/// copied), held by the pointer at its center. Call it right after
/// Rdrag_begin_external. Without it the system chooses: the picture
/// dragged, the icons of the files, or a generic one.
pub fn dragSetImage(rgba: []const u8, width: i32, height: i32) void {
    std.debug.assert(rgba.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
    c.Rdrag_set_image(rgba.ptr, width, height);
}

/// R_TRUE when the window system lets Raven drag data out of its windows (Rdrag_begin_external).
pub fn dragExternalSupported() i32 {
    const result = c.Rdrag_external_supported();
    return result;
}

/// R_TRUE from Rdrag_begin_external until its callback was called.
pub fn dragExternalIsActive() bool {
    const result = c.Rdrag_external_is_active();
    return result != 0;
}

/// The settings every window follows, unless it has its own.
pub fn touchGetSettings() TouchSettings {
    var raw_settings: c.RTouchSettings = .{};
    c.Rtouch_get_settings(&raw_settings);
    return .fromC(raw_settings);
}

/// Changes them; NULL puts back the defaults.
pub fn touchSetSettings(settings: ?TouchSettings) void {
    const raw_settings: ?c.RTouchSettings = if (settings) |v| v.toC() else null;
    c.Rtouch_set_settings(if (raw_settings) |*v| v else null);
}

/// The defaults, to start from.
pub fn touchGetDefaultSettings() TouchSettings {
    var raw_settings: c.RTouchSettings = .{};
    c.Rtouch_get_default_settings(&raw_settings);
    return .fromC(raw_settings);
}

/// Changes the look of the application. The theme file in use, if
/// it names no look of its own, is laid again over the new one; colors
/// and metrics changed with Rtheme_set_... are lost; what was given to
/// widgets (Rwidget_set_color...) is kept.
///
///   Rlook_set(R_LOOK_NATIVE_LIGHT);   the look of the platform, light
///
/// Theme files that name no look (no Look attribute) follow it too, so a
/// part of a window given one (Theme="paper.xml") changes with it.
pub fn lookSet(look: Look) void {
    c.Rlook_set(@backingInt(look));
}

/// The look given to Rlook_set (R_LOOK_RAVEN_DARK at start).
pub fn lookGet() Look {
    const result = c.Rlook_get();
    return @as(Look, @fromBackingInt(result));
}

/// @deprecated Rlook_set: a built-in theme is a look of Raven.
pub fn themeApply(theme: Theme) void {
    c.Rtheme_apply(@backingInt(theme));
}

pub fn themeSetColor(role: ColorRole, color: Color) void {
    c.Rtheme_set_color(@backingInt(role), color.r, color.g, color.b, color.a);
}

pub fn themeGetColor(role: ColorRole) Color {
    var color_: Color = .{};
    c.Rtheme_get_color(@backingInt(role), &color_.r, &color_.g, &color_.b, &color_.a);
    return color_;
}

/// Changes a size of the theme in use. It lasts until the look or
/// the theme is chosen again (Rlook_set, Rtheme_use), but not through a
/// switch between light and dark made by Rtheme_follow_system.
pub fn themeSetMetric(metric: Metric, value: f32) void {
    c.Rtheme_set_metric(@backingInt(metric), value);
}

pub fn themeGetMetric(metric: Metric) f32 {
    const result = c.Rtheme_get_metric(@backingInt(metric));
    return result;
}

/// Material of every widget that was not given one with
/// Rwidget_set_material. Rtheme_apply sets it: solid for the flat
/// themes, frosted glass for the glass themes.
pub fn themeSetMaterial(material: Material) void {
    c.Rtheme_set_material(@backingInt(material));
}

pub fn themeGetMaterial() Material {
    const result = c.Rtheme_get_material();
    return @as(Material, @fromBackingInt(result));
}

/// Font used by widgets that have no font of their own.
pub fn themeSetFont(font: Font) void {
    c.Rtheme_set_font(@backingInt(font));
}

pub fn themeGetFont() ?Font {
    const result = c.Rtheme_get_font();
    return Font.fromId(result);
}

/// Sets the accent color and everything that follows from it: its
/// hovered and pressed shades, the focus outline, the selection, the links.
pub fn themeSetAccent(r: f32, g: f32, b: f32) void {
    c.Rtheme_set_accent(r, g, b);
}

/// Tells whether the theme is a dark one. It decides the tint of
/// the glass, the colors of the code and which wallpaper the glass themes
/// use. Rtheme_apply and the theme files set it.
pub fn themeSetDark(dark: bool) void {
    c.Rtheme_set_dark(@intFromBool(dark));
}

/// Follows the dark or light mode of the system with the Raven look
/// (R_LOOK_RAVEN_DARK / R_LOOK_RAVEN_LIGHT), now and when it changes.
/// Off by default. Does nothing where the platform does not tell (desktop today).
///
/// A switch is Rlook_set, except that the sizes given with
/// Rtheme_set_metric stay. Colors and styles set with Rtheme_set_... are
/// those of one mode and are lost; to keep colors, sizes and styles of
/// the application through the switch, put them in a theme that names no
/// look (Rtheme_load_from_memory, then Rtheme_use): it is laid over the
/// new look.
pub fn themeFollowSystem(enabled: bool) void {
    c.Rtheme_follow_system(@intFromBool(enabled));
}

pub fn themeIsDark() bool {
    const result = c.Rtheme_is_dark();
    return result != 0;
}

/// Image drawn behind the content of the windows that have no
/// background of their own, or R_INVALID_ID for none (the window color).
pub fn themeSetWallpaper(texture: ?Texture) void {
    c.Rtheme_set_wallpaper(optId(texture));
}

pub fn themeGetWallpaper() ?Texture {
    const result = c.Rtheme_get_wallpaper();
    return Texture.fromId(result);
}

/// Gives a color to the widgets of a type and / or of a class,
/// instead of the color of the theme.
/// widget      Tag of a type of widget ("Button"), or NULL for every type.
/// style_class A class (Rwidget_set_class, Class="..."), or NULL
///                    for the widgets of the type whatever their classes.
///
/// When several styles give the same value to a widget, the one with a
/// type and a class wins over the one with a class, which wins over the
/// one with a type; between equals, the last one set wins.
pub fn themeSetStyleColor(widget: ?[:0]const u8, style_class: ?[:0]const u8, role: ColorRole, color: Color) void {
    c.Rtheme_set_style_color(rt.optPtr(widget), rt.optPtr(style_class), @backingInt(role), color.r, color.g, color.b, color.a);
}

pub fn themeSetStyleMetric(widget: [:0]const u8, style_class: [:0]const u8, metric: Metric, value: f32) void {
    c.Rtheme_set_style_metric(widget.ptr, style_class.ptr, @backingInt(metric), value);
}

/// R_MATERIAL_DEFAULT removes the material of the style.
pub fn themeSetStyleMaterial(widget: [:0]const u8, style_class: [:0]const u8, material: Material) void {
    c.Rtheme_set_style_material(widget.ptr, style_class.ptr, @backingInt(material));
}

/// Removes every style of the theme. Rtheme_apply and Rtheme_use do it too.
pub fn themeClearStyles() void {
    c.Rtheme_clear_styles();
}

/// Reads a theme file and keeps the theme under its name (the Name
/// attribute, else the name of the file). It does not change the theme in
/// use unless a theme of that name is the one in use.
///
/// The file is watched like the interface files (Rxml_set_live_reload):
/// saving it updates every widget that uses the theme.
/// Returns: The name of the theme, valid until Rshutdown, or NULL after
/// reporting an error.
pub fn themeLoad(path: [:0]const u8) ?[:0]const u8 {
    const result = c.Rtheme_load(path.ptr);
    return rt.optSpan(result);
}

/// Same, from a text. `size` may be 0 for a null-terminated text.
pub fn themeLoadFromMemory(xml: []const u8) [:0]const u8 {
    const result = c.Rtheme_load_from_memory(@ptrCast(xml.ptr), xml.len);
    return rt.span(result);
}

/// Makes a named theme the theme of the application: a theme
/// given by Rtheme_load (laid over the look in use when it names no
/// look), or the name of a look ("WindowsLight", "RavenDark"; the old
/// "Dark", "Light", "GlassDark"... too), which is then Rlook_set.
/// Values changed with Rtheme_set_... are lost.
/// Returns: R_FALSE, after reporting an error, when no theme has that name.
pub fn themeUse(name: [:0]const u8) Error!void {
    if (c.Rtheme_use(name.ptr) == 0) return lastError();
}

/// Name of the theme in use ("Dark" at start).
pub fn themeGetName() [:0]const u8 {
    const result = c.Rtheme_get_name();
    return rt.span(result);
}

/// Number of named themes, the four built-in ones included.
pub fn themeGetCount() i32 {
    const result = c.Rtheme_get_count();
    return result;
}

/// Name of the index-th one, or NULL.
pub fn themeGetNameAt(index: i32) ?[:0]const u8 {
    const result = c.Rtheme_get_name_at(index);
    return rt.optSpan(result);
}

/// Writes the theme in use, with every change made since it was
/// applied, as a theme file.
/// name Name given to the theme in the file; NULL keeps the current one.
pub fn themeSave(path: [:0]const u8, name: ?[:0]const u8) Error!void {
    if (c.Rtheme_save(path.ptr, rt.optPtr(name)) == 0) return lastError();
}

/// Releases pixels returned by Raven (Rimage_decode, Rwindow_capture). Thread-safe.
pub fn pixelsFree(pixels: ?[*]u8) void {
    c.Rpixels_free(pixels);
}

/// An icon shipped with Raven, by its name: "search", "settings",
/// "close"... (Ricon_get_name lists them; "raven:search" works too, as in
/// XML: Source="raven:search"). The icons are the ones of Lucide (ISC
/// License), 24 x 24 logical units, drawn with lines in currentColor: the
/// widgets that show them tint them with the color of their text, so they
/// follow the theme and the states (Rtexture_create_from_svg). Drawn at
/// the density they are shown with, sharp on every screen.
/// Returns: A texture owned by Raven, made on first use and then shared
/// (do not destroy it; if it was, the next call makes it again);
/// R_INVALID_ID, with an error, when there is no icon of that name.
pub fn iconGet(name: [:0]const u8) c.Rid {
    const result = c.Ricon_get(name.ptr);
    return result;
}

/// Returns: The number of icons shipped with Raven.
pub fn iconGetCount() i32 {
    const result = c.Ricon_get_count();
    return result;
}

/// Returns: The name of an icon, from 0 to Ricon_get_count() - 1, in alphabetical order; NULL out of range.
pub fn iconGetName(index: i32) ?[:0]const u8 {
    const result = c.Ricon_get_name(index);
    return rt.optSpan(result);
}

/// Direction of every window: R_DIRECTION_AUTO (the default), _LTR or _RTL.
pub fn setLayoutDirection(direction: Direction) void {
    c.Rset_layout_direction(@backingInt(direction));
}

/// The direction the windows use now: R_DIRECTION_LTR or _RTL.
pub fn getLayoutDirection() Direction {
    const result = c.Rget_layout_direction();
    return @as(Direction, @fromBackingInt(result));
}

/// R_TRUE when the system has a spell checker that Raven can use.
pub fn spellIsSupported() bool {
    const result = c.Rspell_is_supported();
    return result != 0;
}

/// The languages the checker has dictionaries for.
pub fn spellGetLanguageCount() i32 {
    const result = c.Rspell_get_language_count();
    return result;
}

pub fn spellGetLanguageAt(index: i32) [:0]const u8 {
    const result = c.Rspell_get_language_at(index);
    return rt.span(result);
}

/// The language used when a widget or a call gives none. NULL
/// follows the locale again.
/// Returns: R_FALSE when the checker has no dictionary for it (the default
/// of the system is then used).
pub fn spellSetLanguage(language: ?[:0]const u8) bool {
    const result = c.Rspell_set_language(rt.optPtr(language));
    return result != 0;
}

/// The code of the language used by default, as the checker names it; "" when there is no checker.
pub fn spellGetLanguage() [:0]const u8 {
    const result = c.Rspell_get_language();
    return rt.span(result);
}

/// Checks a text. `language` NULL: the default.
/// Returns: The number of misspelled words, read with Rspell_get_misspelling.
pub fn spellCheck(text: ?[:0]const u8, language: ?[:0]const u8) i32 {
    const result = c.Rspell_check(rt.optPtr(text), rt.optPtr(language));
    return result;
}

/// A misspelled word found by the last Rspell_check: bytes [start, end) of its text.
pub fn spellGetMisspelling(index: i32) ?struct { start: i32, end: i32 } {
    var start: c_int = 0;
    var end: c_int = 0;
    if (c.Rspell_get_misspelling(index, &start, &end) == 0) return null;
    return .{ .start = start, .end = end };
}

/// Returns: The number of corrections for a word (best first), read with Rspell_get_suggestion.
pub fn spellSuggest(word: [:0]const u8, language: [:0]const u8) i32 {
    const result = c.Rspell_suggest(word.ptr, language.ptr);
    return result;
}

/// A correction found by the last Rspell_suggest; valid until the next call.
pub fn spellGetSuggestion(index: i32) [:0]const u8 {
    const result = c.Rspell_get_suggestion(index);
    return rt.span(result);
}

/// Adds a word to the dictionary of the user, which the system keeps (with Hunspell alone: for the session).
pub fn spellLearn(word: [:0]const u8, language: [:0]const u8) void {
    c.Rspell_learn(word.ptr, language.ptr);
}

/// The word is no longer a misspelling, in every language, until the application quits.
pub fn spellIgnore(word: [:0]const u8) void {
    c.Rspell_ignore(word.ptr);
}

/// R_TRUE when PDFium can be loaded (it is, the first time this is asked).
pub fn pdfIsAvailable() bool {
    const result = c.Rpdf_is_available();
    return result != 0;
}

/// Prints a PDF document with the print system: on macOS the print
/// panel, on Windows the print dialog (the pages are drawn by PDFium, see
/// PDF VIEW), on Linux and the other systems CUPS (lp or lpr) after a
/// dialog of Raven that chooses the printer. It waits until the job is
/// sent. `desc` may be NULL. Returns R_FALSE when cancelled or when it
/// cannot print. Not in the browser.
pub fn pdfPrint(desc: ?PdfPrintDesc, data: []const u8) bool {
    const raw_desc: ?c.RPdfPrintDesc = if (desc) |v| v.toC() else null;
    const result = c.Rpdf_print(if (raw_desc) |*v| v else null, @ptrCast(data.ptr), data.len);
    return result != 0;
}

pub fn pdfPrintFile(desc: PdfPrintDesc, path: [:0]const u8) bool {
    const raw_desc = desc.toC();
    const result = c.Rpdf_print_file(&raw_desc, path.ptr);
    return result != 0;
}

/// Declares a language, or replaces the one that has this name: to
/// add words to a built-in language, read it with Rlanguage_get, change
/// what you want and register it again. The strings are copied.
pub fn languageRegister(desc: LanguageDesc) Error!void {
    const raw_desc = desc.toC();
    if (c.Rlanguage_register(&raw_desc) == 0) return lastError();
}

/// Reads the description of a language. The strings belong to the library. Returns R_FALSE when it is unknown.
pub fn languageGet(name: [:0]const u8) ?LanguageDesc {
    var raw_desc: c.RLanguageDesc = .{};
    if (c.Rlanguage_get(name.ptr, &raw_desc) == 0) return null;
    return .fromC(raw_desc);
}

pub fn languageGetCount() i32 {
    const result = c.Rlanguage_get_count();
    return result;
}

pub fn languageGetName(index: i32) [:0]const u8 {
    const result = c.Rlanguage_get_name(index);
    return rt.span(result);
}

/// Returns: The name of the language of a file, from its extension, or NULL.
pub fn languageForFile(path: [:0]const u8) ?[:0]const u8 {
    const result = c.Rlanguage_for_file(path.ptr);
    return rt.optSpan(result);
}

/// Color of a kind of token in the theme in use, instead of the
/// one Raven picks for dark and for light themes. Theme files set them
/// with <Syntax Keyword="#FF7AB2" String="..."/>.
pub fn themeSetTokenColor(token: Token, color: Color) void {
    c.Rtheme_set_token_color(@backingInt(token), color.r, color.g, color.b, color.a);
}

pub fn themeGetTokenColor(token: Token) Color {
    var color_: Color = .{};
    c.Rtheme_get_token_color(@backingInt(token), &color_.r, &color_.g, &color_.b, &color_.a);
    return color_;
}

/// Back to the colors Raven picks.
pub fn themeClearTokenColors() void {
    c.Rtheme_clear_token_colors();
}

/// A short text on the icon of the application: a number of unread
/// messages, "!". macOS: the badge of the Dock. Windows: a small round
/// icon on the taskbar buttons of the windows, drawn from the text (one
/// to three characters fit). Linux: a number only (the text is read as
/// one; anything else shows nothing). NULL or "": no badge.
pub fn taskbarSetBadge(text: ?[:0]const u8) bool {
    const result = c.Rtaskbar_set_badge(rt.optPtr(text));
    return result != 0;
}

/// The menu of the icon of the application in the Dock (macOS),
/// above the entries of the system. A MENU without a parent: its
/// MenuItems fire as when chosen in a window (clicked callback, action),
/// and what changes in it shows the next time the menu opens.
/// R_INVALID_ID: none. R_FALSE where the system has no such menu.
pub fn taskbarSetMenu(menu: ?Widget) bool {
    const result = c.Rtaskbar_set_menu(optId(menu));
    return result != 0;
}

/// The tasks of the jump list of Windows (right click on the button
/// of the application in the taskbar, or on its tile in the Start menu).
/// Choosing one starts the application again with its arguments: the
/// application reads them as any other command line. count 0: none.
/// R_FALSE where there is no jump list.
pub fn taskbarSetJumpList(tasks: []const JumpTask) bool {
    const result = c.Rtaskbar_set_jump_list(@ptrCast(tasks.ptr), @intCast(tasks.len));
    return result != 0;
}

/// Red, green, blue (0..1) to hue (0..360), saturation, value (0..1).
pub fn colorRgbToHsv(r: f32, g: f32, b: f32) struct { hue: f32, saturation: f32, value: f32 } {
    var hue: f32 = 0;
    var saturation: f32 = 0;
    var value: f32 = 0;
    c.Rcolor_rgb_to_hsv(r, g, b, &hue, &saturation, &value);
    return .{ .hue = hue, .saturation = saturation, .value = value };
}

pub fn colorHsvToRgb(hue: f32, saturation: f32, value: f32) struct { r: f32, g: f32, b: f32 } {
    var r: f32 = 0;
    var g: f32 = 0;
    var b: f32 = 0;
    c.Rcolor_hsv_to_rgb(hue, saturation, value, &r, &g, &b);
    return .{ .r = r, .g = g, .b = b };
}

/// The differences between two texts as a unified diff (the format
/// of `diff -u` and `git diff`), with `context` unchanged lines around each
/// change (3 is usual). `left_name` and `right_name` follow `---` and `+++`
/// (NULL: "a" and "b"). `flags`: RDiffFlags. It touches nothing else of
/// the library: it may be called from any thread.
/// Returns: The patch followed by a '\0' (an empty text when the texts are
/// the same), to release with Rmemory_free; NULL when a text is NULL.
/// `size` receives its length in bytes, and may be NULL.
pub fn diffUnified(allocator: std.mem.Allocator, left: ?[:0]const u8, right: ?[:0]const u8, left_name: ?[:0]const u8, right_name: ?[:0]const u8, context: i32, flags: DiffFlags) std.mem.Allocator.Error!?[]u8 {
    var size: usize = 0;
    const result = c.Rdiff_unified(rt.optPtr(left), rt.optPtr(right), rt.optPtr(left_name), rt.optPtr(right_name), context, @as(u32, @bitCast(flags)), &size) orelse return null;
    defer c.Rmemory_free(result);
    return try allocator.dupe(u8, @as([*]const u8, @ptrCast(result))[0..size]);
}

/// The number of changes (runs of lines removed and / or added) between two texts. Any thread.
pub fn diffCountChanges(left: [:0]const u8, right: [:0]const u8, flags: DiffFlags) i32 {
    const result = c.Rdiff_count_changes(left.ptr, right.ptr, @as(u32, @bitCast(flags)));
    return result;
}

/// Shows a widget as a dialog of a window. The window takes
/// ownership of `content`: it is deleted when the dialog closes, so read
/// what you need from it before, or in `closed`.
/// The Escape key dismisses the dialog (result 0).
pub fn dialogOpen(window: Window, content: Widget, context: anytype, comptime closed: ?fn (@TypeOf(context), Widget, i32) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
            closed.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), a1);
        }
    };
    c.Rdialog_open(@backingInt(window), @backingInt(content), if (closed != null) &Trampoline.call else null, if (closed != null) rt.contextToC(context) else null);
}

/// Closes the dialog that contains a widget (the content itself or
/// anything inside it: the button that was clicked).
/// result Passed to the closed callback and returned by Rdialog_run.
pub fn dialogClose(widget: Widget, result: i32) void {
    c.Rdialog_close(@backingInt(widget), result);
}

/// Shows a dialog and waits until it closes. Returns its result.
pub fn dialogRun(window: Window, content: Widget) i32 {
    const result = c.Rdialog_run(@backingInt(window), @backingInt(content));
    return result;
}

/// Shows a widget as a popup over the window, its top-left corner at
/// x, y (window coordinates; moved to stay inside the window): a search box,
/// a palette, a picker. Unlike a dialog it does not block the window: a click
/// outside it, or Escape, closes it. The application keeps the content (it is
/// not deleted on close) and can open it again. `closed` (may be NULL) is
/// called when it closes, with the result given to Rpopup_close (0 when dismissed).
/// The content draws its own background (a Border with a Background...).
pub fn popupOpen(window: Window, content: Widget, x: f32, y: f32, context: anytype, comptime closed: ?fn (@TypeOf(context), Widget, i32) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.Rid, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
            closed.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), a1);
        }
    };
    c.Rpopup_open(@backingInt(window), @backingInt(content), x, y, if (closed != null) &Trampoline.call else null, if (closed != null) rt.contextToC(context) else null);
}

/// Closes the popup that contains a widget (the content or anything inside it).
pub fn popupClose(widget: Widget, result: i32) void {
    c.Rpopup_close(@backingInt(widget), result);
}

/// Returns: R_TRUE while the widget is shown as a popup.
pub fn popupIsOpen(content: Widget) bool {
    const result = c.Rpopup_is_open(@backingInt(content));
    return result != 0;
}

/// Shows a message with buttons and waits for the answer.
/// window R_INVALID_ID: the first window of the application.
/// title  May be NULL.
pub fn messageBox(window: ?Window, title: ?[:0]const u8, text: [:0]const u8, buttons: MessageButtons) MessageResult {
    const result = c.Rmessage_box(optId(window), rt.optPtr(title), text.ptr, @backingInt(buttons));
    return @as(MessageResult, @fromBackingInt(result));
}

/// Asks for a file to open.
/// desc May be NULL.
/// Returns: The path (UTF-8), valid until the next file dialog, or NULL when the user cancelled.
pub fn fileDialogOpen(desc: ?FileDialogDesc) ?[:0]const u8 {
    const raw_desc: ?c.RFileDialogDesc = if (desc) |v| v.toC() else null;
    const result = c.Rfile_dialog_open(if (raw_desc) |*v| v else null);
    return rt.optSpan(result);
}

/// Asks where to save a file. An existing file was confirmed by the user.
pub fn fileDialogSave(desc: FileDialogDesc) [:0]const u8 {
    const raw_desc = desc.toC();
    const result = c.Rfile_dialog_save(&raw_desc);
    return rt.span(result);
}

/// Asks for a folder.
pub fn fileDialogSelectFolder(desc: FileDialogDesc) [:0]const u8 {
    const raw_desc = desc.toC();
    const result = c.Rfile_dialog_select_folder(&raw_desc);
    return rt.span(result);
}

/// What the last file dialog returned: several paths with R_FILE_DIALOG_MULTIPLE.
pub fn fileDialogGetResultCount() i32 {
    const result = c.Rfile_dialog_get_result_count();
    return result;
}

pub fn fileDialogGetResult(index: i32) [:0]const u8 {
    const result = c.Rfile_dialog_get_result(index);
    return rt.span(result);
}

/// Registers a file held in memory under a path: every file Raven
/// reads (XML documents and their Include, Source and Font attributes,
/// themes, textures, fonts, Rfile_read) is looked up here first, so that
/// resources embedded in the executable need no file beside it. A relative
/// path names the file as it is written in the XML once joined to the
/// folder of the document that names it (Rxml_set_base_path for a
/// document given as text), e.g. "ui/editor.xml". Paths compare with '/'
/// and '\\' alike. Memory files are not watched for live reload. Call it
/// after Rinit; Rshutdown forgets every file.
/// copy R_TRUE: Raven keeps a copy; R_FALSE: `data` must outlive Raven (static data).
pub fn fileRegisterMemory(path: [:0]const u8, data: []const u8, copy: bool) Error!void {
    if (c.Rfile_register_memory(path.ptr, @ptrCast(data.ptr), data.len, @intFromBool(copy)) == 0) return lastError();
}

pub fn fileUnregisterMemory(path: [:0]const u8) void {
    c.Rfile_unregister_memory(path.ptr);
}

/// R_TRUE when `path` is a file registered with Rfile_register_memory.
pub fn fileIsMemory(path: [:0]const u8) bool {
    const result = c.Rfile_is_memory(path.ptr);
    return result != 0;
}

pub fn fileWrite(path: [:0]const u8, data: []const u8) Error!void {
    if (c.Rfile_write(path.ptr, @ptrCast(data.ptr), data.len) == 0) return lastError();
}

/// Returns: R_TRUE when the system took the notification.
pub fn notificationShow(title: [:0]const u8, body: [:0]const u8, urgency: NotificationUrgency) bool {
    const result = c.Rnotification_show(title.ptr, body.ptr, @backingInt(urgency));
    return result != 0;
}

/// R_FALSE when the system shows no notifications here (Rnotification_show then always uses
/// the fallback): the null platform, no notification server on Linux, an executable outside of a
/// bundle on macOS.
pub fn notificationIsSupported() bool {
    const result = c.Rnotification_is_supported();
    return result != 0;
}

/// Called with the notifications the system could not show; NULL: none.
pub fn notificationSetFallback(context: anytype, comptime callback: ?fn (@TypeOf(context), [:0]const u8, [:0]const u8, NotificationUrgency) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: ?[*:0]const u8, a1: ?[*:0]const u8, a2: c.RNotificationUrgency, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), rt.span(a0), rt.span(a1), @as(NotificationUrgency, @fromBackingInt(a2)));
        }
    };
    c.Rnotification_set_fallback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Called when the user clicks a notification of Rnotification_show
/// (on the UI thread), as R_NOTIFICATION_ACTIVATED of
/// Rnotification_set_callback, which also tells which one. NULL: none.
pub fn notificationSetClickedCallback(context: anytype, comptime callback: ?fn (@TypeOf(context)) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data));
        }
    };
    c.Rnotification_set_clicked_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Shows a notification described by `desc` (see RNotificationDesc).
/// Returns: R_TRUE when the system took it; R_FALSE when it went to the fallback (or nowhere).
pub fn notificationShowDesc(desc: NotificationDesc) bool {
    const raw_desc = desc.toC();
    const result = c.Rnotification_show_desc(&raw_desc);
    return result != 0;
}

/// Takes away the notification of that tag, shown by the system or by the fallback toast. The callback is not called.
pub fn notificationClose(tag: [:0]const u8) void {
    c.Rnotification_close(tag.ptr);
}

pub fn notificationSetCallback(context: anytype, comptime callback: ?fn (@TypeOf(context), [:0]const u8, NotificationEvent, [:0]const u8) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: ?[*:0]const u8, a1: c.RNotificationEvent, a2: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), rt.span(a0), @as(NotificationEvent, @fromBackingInt(a1)), rt.span(a2));
        }
    };
    c.Rnotification_set_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// R_TRUE (the default): a click on a notification (not on one of
/// its buttons) brings its window back before the callback is called:
/// shown again if it was hidden or minimized, in front, with the keyboard.
/// R_FALSE: the application does what it wants in the callback.
pub fn notificationSetBringToFront(enabled: bool) void {
    c.Rnotification_set_bring_to_front(@intFromBool(enabled));
}

/// A Toast that shows the notifications the system could not show,
/// with their title, icon and buttons; a click on one, or on a button, is
/// reported to Rnotification_set_callback as for the system's. Put it in
/// an Overlay (Queue="Stack" shows several at once). It takes the place
/// of the fallback callback (Rnotification_set_fallback). R_INVALID_ID: none.
pub fn notificationSetFallbackToast(toast: ?Widget) void {
    c.Rnotification_set_fallback_toast(optId(toast));
}

/// Whether the notifications of the system have that feature here (R_FALSE where there are none).
pub fn notificationSupports(feature: NotificationFeature) i32 {
    const result = c.Rnotification_supports(@as(c_int, @bitCast(feature)));
    return result;
}

/// What the user answered, without asking. Cheap: the platform
/// remembers it. On iOS the status of notifications is known shortly after
/// the start (R_PERMISSION_NOT_ASKED until then).
pub fn permissionGetStatus(permission: Permission) PermissionStatus {
    const result = c.Rpermission_get_status(@backingInt(permission));
    return @as(PermissionStatus, @fromBackingInt(result));
}

/// Asks the user, with the question of the system, when the status
/// is R_PERMISSION_NOT_ASKED or R_PERMISSION_DENIED; otherwise only answers
/// with the status. Several requests for the same permission share one
/// question. `callback` may be NULL.
pub fn permissionRequest(permission: Permission, context: anytype, comptime callback: ?fn (@TypeOf(context), Permission, PermissionStatus) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RPermission, a1: c.RPermissionStatus, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(Permission, @fromBackingInt(a0)), @as(PermissionStatus, @fromBackingInt(a1)));
        }
    };
    c.Rpermission_request(@backingInt(permission), if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Opens the page of the application in the Settings of the system,
/// where the user changes what was refused for good (R_PERMISSION_BLOCKED).
/// Returns: R_FALSE when the platform has no such page.
pub fn permissionOpenSettings() bool {
    const result = c.Rpermission_open_settings();
    return result != 0;
}

/// Returns: The name of a permission or a status ("camera", "granted"...), for logs.
pub fn permissionToString(permission: Permission) [:0]const u8 {
    const result = c.Rpermission_to_string(@backingInt(permission));
    return rt.span(result);
}

pub fn permissionStatusToString(status: PermissionStatus) [:0]const u8 {
    const result = c.Rpermission_status_to_string(@backingInt(status));
    return rt.span(result);
}

/// Asks for one file to read (several with R_FILE_DIALOG_MULTIPLE). `desc` may be NULL.
pub fn fileOpenAsync(desc: ?FileDialogDesc, context: anytype, comptime callback: ?fn (@TypeOf(context), DeviceResult, PickedFile, i32) void) void {
    const raw_desc: ?c.RFileDialogDesc = if (desc) |v| v.toC() else null;
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RDeviceResult, a1: ?*const c.RPickedFile, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(DeviceResult, @fromBackingInt(a0)), PickedFile.fromC(a1.?.*), a2);
        }
    };
    c.Rfile_open_async(if (raw_desc) |*v| v else null, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Saves `size` bytes (copied: `data` may be freed at once) as a
/// file where the user chooses, proposed under `desc->file_name`. The
/// callback gives the file as saved: its name, and its path on desktops.
pub fn fileSaveAsync(desc: FileDialogDesc, data: []const u8, context: anytype, comptime callback: ?fn (@TypeOf(context), DeviceResult, PickedFile, i32) void) void {
    const raw_desc = desc.toC();
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RDeviceResult, a1: ?*const c.RPickedFile, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(DeviceResult, @fromBackingInt(a0)), PickedFile.fromC(a1.?.*), a2);
        }
    };
    c.Rfile_save_async(&raw_desc, @ptrCast(data.ptr), data.len, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Same as Rfile_save_async, for a file that already exists (a path Raven can read), copied where the user chooses.
pub fn fileExportAsync(desc: FileDialogDesc, path: [:0]const u8, context: anytype, comptime callback: ?fn (@TypeOf(context), DeviceResult, PickedFile, i32) void) void {
    const raw_desc = desc.toC();
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RDeviceResult, a1: ?*const c.RPickedFile, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(DeviceResult, @fromBackingInt(a0)), PickedFile.fromC(a1.?.*), a2);
        }
    };
    c.Rfile_export_async(&raw_desc, path.ptr, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Asks for a folder: desktops only for now (R_DEVICE_UNSUPPORTED on iOS and Android).
pub fn fileSelectFolderAsync(desc: FileDialogDesc, context: anytype, comptime callback: ?fn (@TypeOf(context), DeviceResult, PickedFile, i32) void) void {
    const raw_desc = desc.toC();
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RDeviceResult, a1: ?*const c.RPickedFile, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(DeviceResult, @fromBackingInt(a0)), PickedFile.fromC(a1.?.*), a2);
        }
    };
    c.Rfile_select_folder_async(&raw_desc, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Returns: R_TRUE when Rcamera_take_photo can show a camera (none on desktops, nor in the iOS Simulator).
pub fn cameraIsAvailable() bool {
    const result = c.Rcamera_is_available();
    return result != 0;
}

/// Shows the camera of the system to take one photo. It asks for
/// R_PERMISSION_CAMERA first when needed (R_DEVICE_DENIED when refused).
/// The photo is a JPEG file in the cache of the application, with its
/// size in pixels, upright.
pub fn cameraTakePhoto(context: anytype, comptime callback: ?fn (@TypeOf(context), DeviceResult, PickedFile, i32) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RDeviceResult, a1: ?*const c.RPickedFile, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(DeviceResult, @fromBackingInt(a0)), PickedFile.fromC(a1.?.*), a2);
        }
    };
    c.Rcamera_take_photo(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Shows the photo picker of the system (desktops: a file dialog for
/// images). No permission is needed: the application only sees what the
/// user picks. Each photo is a file Raven can load (iOS: converted to JPEG
/// when it is HEIC).
/// max_count How many photos may be picked; 0: no limit.
pub fn photoPick(max_count: i32, context: anytype, comptime callback: ?fn (@TypeOf(context), DeviceResult, PickedFile, i32) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RDeviceResult, a1: ?*const c.RPickedFile, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(DeviceResult, @fromBackingInt(a0)), PickedFile.fromC(a1.?.*), a2);
        }
    };
    c.Rphoto_pick(max_count, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Returns: R_TRUE when the device can play haptics (a phone; never a desktop).
pub fn hapticIsSupported() bool {
    const result = c.Rhaptic_is_supported();
    return result != 0;
}

/// A short vibration, as the controls of the system play when
/// touched. Nothing happens where there are none, or when the user turned
/// them off. Returns: R_TRUE when it was handed to the system.
pub fn hapticPlay(haptic: Haptic) bool {
    const result = c.Rhaptic_play(@backingInt(haptic));
    return result != 0;
}

/// Shows the share sheet of the system with a text and / or a file,
/// to send them to another application (mail, chat, Files...). The
/// callback says R_DEVICE_DONE once something was chosen (Android: once the
/// sheet was shown; it does not tell more), R_DEVICE_CANCELLED when it was
/// closed. R_DEVICE_UNSUPPORTED on desktops.
pub fn shareShow(desc: ShareDesc, context: anytype, comptime callback: ?fn (@TypeOf(context), DeviceResult, PickedFile, i32) void) void {
    const raw_desc = desc.toC();
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RDeviceResult, a1: ?*const c.RPickedFile, a2: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(DeviceResult, @fromBackingInt(a0)), PickedFile.fromC(a1.?.*), a2);
        }
    };
    c.Rshare_show(&raw_desc, if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// A built-in effect, created the first time it is asked for.
pub fn effectGet(effect: Effect) ?Shader {
    const result = c.Reffect_get(@backingInt(effect));
    return Shader.fromId(result);
}

/// A built-in effect by its name ("aurora", "shimmer", "neon", "ripple", "plasma", "grain", "spotlight", "mesh"), or R_INVALID_ID.
pub fn effectFind(name: [:0]const u8) ?Shader {
    const result = c.Reffect_find(name.ptr);
    return Shader.fromId(result);
}

pub fn effectGetName(effect: Effect) [:0]const u8 {
    const result = c.Reffect_get_name(@backingInt(effect));
    return rt.span(result);
}

/// Its colors and parameters when nothing else is given (Rshader_look_init uses them).
pub fn effectGetDefaults(effect: Effect) ShaderLook {
    var raw_look: c.RShaderLook = .{};
    c.Reffect_get_defaults(@backingInt(effect), &raw_look);
    return .fromC(raw_look);
}

/// A folder looked into after the one of the document (see above),
/// and the first one for the documents given from memory. NULL or "": none.
pub fn xmlSetBasePath(path: ?[:0]const u8) void {
    c.Rxml_set_base_path(rt.optPtr(path));
}

/// Turns auto-loading on or off (see above). It is on by default;
/// the environment variable RAVEN_AUTO_LOAD=0 turns it off without
/// rebuilding. Turned off, the register functions are the only way in;
/// the places where paths are looked for stay the same.
pub fn xmlSetAutoLoad(enabled: bool) void {
    c.Rxml_set_auto_load(@intFromBool(enabled));
}

pub fn xmlGetAutoLoad() i32 {
    const result = c.Rxml_get_auto_load();
    return result;
}

/// Turns live reload on or off. It is on by default, except in
/// the browser (Emscripten), where watching files would keep the page
/// drawing; the environment variable RAVEN_LIVE_RELOAD=0 or 1 changes the
/// default without rebuilding. When off, files are never looked at again.
pub fn xmlSetLiveReload(enabled: bool) void {
    c.Rxml_set_live_reload(@intFromBool(enabled));
}

pub fn xmlGetLiveReload() i32 {
    const result = c.Rxml_get_live_reload();
    return result;
}

pub fn xmlSetReloadCallback(context: anytype, comptime callback: ?fn (@TypeOf(context), [:0]const u8, bool) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: ?[*:0]const u8, a1: c_int, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), rt.span(a0), a1 != 0);
        }
    };
    c.Rxml_set_reload_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Looks at the files now, without waiting for the next look
/// (there are five per second), even when live reload is off.
/// Returns: The number of files found changed.
pub fn xmlCheckFiles() i32 {
    const result = c.Rxml_check_files();
    return result;
}

/// Reads the <Widget Name="..."> declarations of a document (its
/// root, or the children of a <Widgets> root) so that the tags they
/// declare can be used in the documents loaded afterwards.
/// Returns: The number of tags declared.
pub fn xmlRegisterWidgets(xml: []const u8) i32 {
    const result = c.Rxml_register_widgets(@ptrCast(xml.ptr), xml.len);
    return result;
}

pub fn xmlRegisterWidgetsFromFile(path: [:0]const u8) i32 {
    const result = c.Rxml_register_widgets_from_file(path.ptr);
    return result;
}

pub fn xmlUnregisterWidget(name: [:0]const u8) void {
    c.Rxml_unregister_widget(name.ptr);
}

pub fn xmlIsWidgetRegistered(name: [:0]const u8) bool {
    const result = c.Rxml_is_widget_registered(name.ptr);
    return result != 0;
}

/// The declared tags, for tools that list them.
pub fn xmlGetRegisteredWidgetCount() i32 {
    const result = c.Rxml_get_registered_widget_count();
    return result;
}

pub fn xmlGetRegisteredWidgetName(index: i32) [:0]const u8 {
    const result = c.Rxml_get_registered_widget_name(index);
    return rt.span(result);
}

/// Registers a tag (or replaces what it was registered with).
/// Returns: R_FALSE when the name is the one of a widget of Raven, or when too many tags are registered (64).
pub fn xmlRegisterTag(tag: [:0]const u8, context: anytype, comptime create: ?fn (@TypeOf(context), [:0]const u8) ?Widget, comptime set_attribute: ?fn (@TypeOf(context), Widget, [:0]const u8, [:0]const u8) bool) Error!void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) c.Rid {
            return optId(create.?(rt.contextFromC(Ctx, user_data), rt.span(a0)));
        }
    };
    const Trampoline2 = struct {
        fn call(a0: c.Rid, a1: ?[*:0]const u8, a2: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) c_int {
            const handled = set_attribute.?(rt.contextFromC(Ctx, user_data), @as(Widget, @fromBackingInt(a0)), rt.span(a1), rt.span(a2));
            return @intFromBool(handled);
        }
    };
    if (c.Rxml_register_tag(tag.ptr, if (create != null) &Trampoline.call else null, if (set_attribute != null) &Trampoline2.call else null, if (create != null) rt.contextToC(context) else null) == 0) return lastError();
}

pub fn xmlUnregisterTag(tag: [:0]const u8) void {
    c.Rxml_unregister_tag(tag.ptr);
}

pub fn xmlIsTagRegistered(tag: [:0]const u8) bool {
    const result = c.Rxml_is_tag_registered(tag.ptr);
    return result != 0;
}

/// The path of a file named in a document: as the attributes
/// Source of Raven read it, looked for where files are looked for (see
/// Rxml_set_base_path): the folder of the document being loaded (while it
/// loads) and its subfolders, the base path, the current folder, PATH.
/// When no place holds it, the path it would have next to the document
/// (else in the base path). For the attributes of the tags made by code
/// that name files.
/// Returns: The path; valid until the next call.
pub fn xmlResolvePath(path: [:0]const u8) [:0]const u8 {
    const result = c.Rxml_resolve_path(path.ptr);
    return rt.span(result);
}

/// The tags of the library, <Window> included. Those declared with <Widget> are listed by Rxml_get_registered_widget_name.
pub fn xmlGetTagCount() i32 {
    const result = c.Rxml_get_tag_count();
    return result;
}

pub fn xmlGetTagName(index: i32) [:0]const u8 {
    const result = c.Rxml_get_tag_name(index);
    return rt.span(result);
}

/// Returns: One line about a tag, "" when there is nothing to say.
pub fn xmlGetTagDescription(tag: [:0]const u8) [:0]const u8 {
    const result = c.Rxml_get_tag_description(tag.ptr);
    return rt.span(result);
}

/// Returns: 0: no child widget; 1: a single one; 2: any number. Declared and unknown tags give 2.
pub fn xmlGetTagChildren(tag: [:0]const u8) i32 {
    const result = c.Rxml_get_tag_children(tag.ptr);
    return result;
}

/// The attributes of a tag: its own first, then those every widget
/// has, then those of its place in its parent. For a tag declared with
/// <Widget>, its own are its parameters.
pub fn xmlGetAttributeCount(tag: [:0]const u8) i32 {
    const result = c.Rxml_get_attribute_count(tag.ptr);
    return result;
}

pub fn xmlGetAttributeInfo(tag: [:0]const u8, index: i32) ?XmlAttributeInfo {
    var raw_info: c.RXmlAttributeInfo = .{};
    if (c.Rxml_get_attribute_info(tag.ptr, index, &raw_info) == 0) return null;
    return .fromC(raw_info);
}

/// Loads a script given as text (not an XML document): its
/// functions become actions, its globals are initialized.
/// name Names it in the diagnostics (a file name); may be NULL.
/// Returns: R_FALSE when it has an error (nothing of it is installed).
pub fn scriptLoad(source: []const u8, name: ?[:0]const u8) bool {
    const result = c.Rscript_load(@ptrCast(source.ptr), source.len, rt.optPtr(name));
    return result != 0;
}

/// The same from a file (.rvs).
pub fn scriptLoadFile(path: [:0]const u8) i32 {
    const result = c.Rscript_load_file(path.ptr);
    return result;
}

/// Checks a script, or the scripts of an XML document and the
/// functions its widgets name, without running anything nor building a
/// widget. The diagnostics are reported as usual.
/// source A script, or an XML document (text that starts with '<').
/// Returns: The number of errors.
pub fn scriptCheck(source: []const u8, name: [:0]const u8) i32 {
    const result = c.Rscript_check(@ptrCast(source.ptr), source.len, name.ptr);
    return result;
}

/// Returns: The number of errors in the file (a .rvs or an .xml), -1 when it cannot be read.
pub fn scriptCheckFile(path: [:0]const u8) i32 {
    const result = c.Rscript_check_file(path.ptr);
    return result;
}

/// Formats a script: one statement per line, blocks indented,
/// spaces around operators; comments are kept.
/// indent One level of indentation; NULL for four spaces.
/// Returns: The text, valid until the next call; NULL when the script has a
/// syntax error (it is not changed).
pub fn scriptFormat(source: []const u8, indent: ?[:0]const u8) ?[:0]const u8 {
    const result = c.Rscript_format(@ptrCast(source.ptr), source.len, rt.optPtr(indent));
    return rt.optSpan(result);
}

/// Removes every script function (their actions are unbound) and every global. Not while a script runs.
pub fn scriptReset() void {
    c.Rscript_reset();
}

/// Returns: R_TRUE when a script function has that name.
pub fn scriptHasFunction(name: [:0]const u8) bool {
    const result = c.Rscript_has_function(name.ptr);
    return result != 0;
}

/// R_FALSE: the <Script> elements of the documents are read but not
/// compiled nor run (a design tool that shows interfaces without running
/// them). On by default.
pub fn scriptSetEnabled(enabled: bool) void {
    c.Rscript_set_enabled(@intFromBool(enabled));
}

pub fn scriptIsEnabled() bool {
    const result = c.Rscript_is_enabled();
    return result != 0;
}

/// The limits of the scripts. 0 keeps a value.
/// max_instructions Instructions one invocation (an event) may run (10 000 000).
/// max_depth Calls nested (200).
/// max_memory Bytes of strings and arrays alive (64 MB).
pub fn scriptSetLimits(max_instructions: u32, max_depth: i32, max_memory: usize) void {
    c.Rscript_set_limits(max_instructions, max_depth, max_memory);
}

pub fn scriptSetLogCallback(context: anytype, comptime callback: ?fn (@TypeOf(context), [:0]const u8) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), rt.span(a0));
        }
    };
    c.Rscript_set_log_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

pub fn scriptSetDiagnosticCallback(context: anytype, comptime callback: ?fn (@TypeOf(context), Severity, [:0]const u8, [:0]const u8, i32, i32, [:0]const u8) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: c.RSeverity, a1: ?[*:0]const u8, a2: ?[*:0]const u8, a3: c_int, a4: c_int, a5: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), @as(Severity, @fromBackingInt(a0)), rt.span(a1), rt.span(a2), a3, a4, rt.span(a5));
        }
    };
    c.Rscript_set_diagnostic_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// Loads a CSV table of translations from a file. Returns the number of keys read, -1 on an error.
pub fn localeLoadCsv(path: [:0]const u8) i32 {
    const result = c.Rlocale_load_csv(path.ptr);
    return result;
}

/// Same, from text in memory (UTF-8).
pub fn localeLoadCsvFromMemory(csv: []const u8) i32 {
    const result = c.Rlocale_load_csv_from_memory(@ptrCast(csv.ptr), csv.len);
    return result;
}

/// Forgets every table.
pub fn localeClear() void {
    c.Rlocale_clear();
}

/// Adds or replaces one text of one language.
pub fn localeSetText(language: [:0]const u8, key: [:0]const u8, text: [:0]const u8) void {
    c.Rlocale_set_text(language.ptr, key.ptr, text.ptr);
}

/// Number of languages in the tables, and their codes, in the order of the columns.
pub fn localeGetLanguageCount() i32 {
    const result = c.Rlocale_get_language_count();
    return result;
}

pub fn localeGetLanguageAt(index: i32) [:0]const u8 {
    const result = c.Rlocale_get_language_at(index);
    return rt.span(result);
}

/// Chooses the language: an exact code ("pt-BR"), or its first part
/// ("pt") when the tables have no such column. Every widget that shows a key
/// is updated, and the layout of the windows follows its direction (an
/// Arabic, Hebrew, Persian or Urdu language is laid out from right to left,
/// see Rset_layout_direction). Returns R_FALSE when no column matches (the
/// language is set all the same: the texts fall back).
pub fn localeSetLanguage(code: [:0]const u8) bool {
    const result = c.Rlocale_set_language(code.ptr);
    return result != 0;
}

pub fn localeGetLanguage() [:0]const u8 {
    const result = c.Rlocale_get_language();
    return rt.span(result);
}

/// The language of the user, from the system ("fr-FR", "en-US"...).
pub fn localeGetSystemLanguage() [:0]const u8 {
    const result = c.Rlocale_get_system_language();
    return rt.span(result);
}

/// The language whose texts are shown when the current one has none (default: the first column).
pub fn localeSetFallbackLanguage(code: [:0]const u8) void {
    c.Rlocale_set_fallback_language(code.ptr);
}

/// R_TRUE when the language is written from right to left.
pub fn localeIsRtl() bool {
    const result = c.Rlocale_is_rtl();
    return result != 0;
}

/// Called after the language or the tables changed (the widgets are already updated).
pub fn localeSetChangedCallback(context: anytype, comptime callback: ?fn (@TypeOf(context), [:0]const u8) void) void {
    const Ctx = @TypeOf(context);
    const Trampoline = struct {
        fn call(a0: ?[*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
            callback.?(rt.contextFromC(Ctx, user_data), rt.span(a0));
        }
    };
    c.Rlocale_set_changed_callback(if (callback != null) &Trampoline.call else null, if (callback != null) rt.contextToC(context) else null);
}

/// The text of a key in the current language (see the fallbacks above). Never NULL.
pub fn tr(key: [:0]const u8) [:0]const u8 {
    const result = c.Rtr(key.ptr);
    return rt.span(result);
}

/// R_TRUE when the key has a text in the current language or the fallback one.
pub fn trExists(key: [:0]const u8) bool {
    const result = c.Rtr_exists(key.ptr);
    return result != 0;
}

/// The text of a key with its {0} {1} ... replaced by the arguments
/// (translators may put them in any order). "{{" is a brace.
pub fn trFormat(key: [:0]const u8, args: []const [*:0]const u8) [:0]const u8 {
    const result = c.Rtr_format(key.ptr, @ptrCast(args.ptr), @intCast(args.len));
    return rt.span(result);
}

/// The plural form of a key for a count: the key followed by the CLDR
/// category of the count in the current language (".zero", ".one", ".two",
/// ".few", ".many", ".other"), else ".other", else the key itself. {n} is
/// replaced by the count, written in the conventions of the language.
pub fn trPlural(key: [:0]const u8, count: i32) [:0]const u8 {
    const result = c.Rtr_plural(key.ptr, count);
    return rt.span(result);
}

/// A number written in the conventions of the language: decimal separator and digit grouping ("1 234,5" in French).
pub fn localeFormatNumber(value: f64, decimals: i32) [:0]const u8 {
    const result = c.Rlocale_format_number(value, decimals);
    return rt.span(result);
}

/// Forces the clock of every time shown (a setting of the
/// application): R_CLOCK_12_HOUR, R_CLOCK_24_HOUR, or R_CLOCK_AUTO (default)
/// to follow the locale. A TimePicker can still choose its own (Clock="24").
pub fn localeSetClock(clock: Clock) void {
    c.Rlocale_set_clock(@backingInt(clock));
}

pub fn localeGetClock() Clock {
    const result = c.Rlocale_get_clock();
    return @as(Clock, @fromBackingInt(result));
}

/// R_TRUE when times are shown on 12 hours with AM and PM. With
/// Rlocale_set_clock, what it forces; else, when the application chose a
/// language (Rlocale_set_language), the usage of that language (from CLDR:
/// en-US, en-CA, en-AU, en-IN, hi, ar, ko, zh-TW, fil... use 12 hours, most
/// others 24); else the setting of the user on the system (Windows, macOS,
/// the LC_TIME of Linux), or the usage of the language of the system.
pub fn localeUses12HourClock() i32 {
    const result = c.Rlocale_uses_12_hour_clock();
    return result;
}

/// "AM" (pm = R_FALSE) or "PM" in the language: the keys Raven.AM / Raven.PM when the tables have them. Never NULL.
pub fn localeGetDayPeriod(pm: i32) [:0]const u8 {
    const result = c.Rlocale_get_day_period(pm);
    return rt.span(result);
}

/// A time of the day (hour 0 to 23) as the locale writes it: "3:05 PM", "15:05", "오후 3:05".
pub fn localeFormatTime(hour: i32, minute: i32, second: i32, show_seconds: i32) [:0]const u8 {
    const result = c.Rlocale_format_time(hour, minute, second, show_seconds);
    return rt.span(result);
}

/// The zone of the system ("Europe/Paris"): the TZ variable, the
/// link /etc/localtime, else what the system says; "UTC" when it says
/// nothing. Valid until the next call.
pub fn timezoneGetSystem() [:0]const u8 {
    const result = c.Rtimezone_get_system();
    return rt.span(result);
}

/// The folder of the tz database (the files "Europe/Paris"...), or
/// the packed tzdata file of Android, to read instead of the system's: for
/// a database shipped with the application, or tests. It is then the only
/// one read. NULL: the system's (or the TZDIR variable). Forgets the zones
/// read so far.
pub fn timezoneSetDirectory(path: ?[:0]const u8) void {
    c.Rtimezone_set_directory(rt.optPtr(path));
}

/// R_TRUE when the zone is known. Every function takes a name of
/// the tz database, "UTC", a POSIX TZ rule ("EST5EDT,M3.2.0,M11.1.0"), or
/// NULL / "" for the zone of the system.
pub fn timezoneIsValid(zone: ?[:0]const u8) bool {
    const result = c.Rtimezone_is_valid(rt.optPtr(zone));
    return result != 0;
}

/// The date and time an instant shows in a zone (month 1 to 12). R_FALSE for an unknown zone.
pub fn timezoneToLocal(zone: [:0]const u8, utc: f64) ?struct { year: i32, month: i32, day: i32, hour: i32, minute: i32, second: i32 } {
    var year: c_int = 0;
    var month: c_int = 0;
    var day: c_int = 0;
    var hour: c_int = 0;
    var minute: c_int = 0;
    var second: c_int = 0;
    if (c.Rtimezone_to_local(zone.ptr, utc, &year, &month, &day, &hour, &minute, &second) == 0) return null;
    return .{ .year = year, .month = month, .day = day, .hour = hour, .minute = minute, .second = second };
}

/// The instant a date and time of a zone is. When the clocks go
/// forward, the times they skip do not exist: such a time is moved forward
/// by the length of the gap (02:30 becomes 03:30). When they go back, the
/// times of the hour repeated happen twice: the first is taken (still in
/// summer time). Rtimezone_count_local tells these cases apart.
pub fn timezoneFromLocal(zone: [:0]const u8, year: i32, month: i32, day: i32, hour: i32, minute: i32, second: i32) f64 {
    const result = c.Rtimezone_from_local(zone.ptr, year, month, day, hour, minute, second);
    return result;
}

/// How many instants show this date and time in the zone: 1, 0 (skipped when the clocks went forward) or 2 (repeated when they went back).
pub fn timezoneCountLocal(zone: [:0]const u8, year: i32, month: i32, day: i32, hour: i32, minute: i32, second: i32) i32 {
    const result = c.Rtimezone_count_local(zone.ptr, year, month, day, hour, minute, second);
    return result;
}

/// Seconds the zone is ahead of UTC at an instant (3600 in Paris in winter, -14400 in New York in summer).
pub fn timezoneGetOffset(zone: [:0]const u8, utc: f64) i32 {
    const result = c.Rtimezone_get_offset(zone.ptr, utc);
    return result;
}

/// R_TRUE when the zone is on summer (daylight saving) time at the instant.
pub fn timezoneIsDaylightSaving(zone: [:0]const u8, utc: f64) bool {
    const result = c.Rtimezone_is_daylight_saving(zone.ptr, utc);
    return result != 0;
}

/// The abbreviation of the zone at an instant ("CET", "EDT"; "+03" where the database has no name).
pub fn timezoneGetAbbreviation(zone: [:0]const u8, utc: f64) [:0]const u8 {
    const result = c.Rtimezone_get_abbreviation(zone.ptr, utc);
    return rt.span(result);
}

/// The zone at an instant, to show: "CET, UTC+1", "EDT, UTC-4", "IST, UTC+5:30", "UTC+3" when it has no name.
pub fn timezoneGetLabel(zone: [:0]const u8, utc: f64) [:0]const u8 {
    const result = c.Rtimezone_get_label(zone.ptr, utc);
    return rt.span(result);
}

/// Size of every text, 1 = as designed (0.5 to 4). Controls grow with their text.
pub fn accessibilitySetTextScale(scale: f32) void {
    c.Raccessibility_set_text_scale(scale);
}

pub fn accessibilityGetTextScale() f32 {
    const result = c.Raccessibility_get_text_scale();
    return result;
}

/// Themes of high contrast: black and white, yellow focus, thick
/// borders (the dark one, or the light one when the theme in use is light).
/// R_FALSE goes back to the theme used before.
pub fn accessibilitySetHighContrast(enabled: bool) void {
    c.Raccessibility_set_high_contrast(@intFromBool(enabled));
}

pub fn accessibilityGetHighContrast() i32 {
    const result = c.Raccessibility_get_high_contrast();
    return result;
}

/// R_TRUE: the focus ring is always shown (not only after the keyboard was used), and thicker.
pub fn accessibilitySetFocusAlwaysVisible(enabled: bool) void {
    c.Raccessibility_set_focus_always_visible(@intFromBool(enabled));
}

pub fn accessibilityGetFocusAlwaysVisible() i32 {
    const result = c.Raccessibility_get_focus_always_visible();
    return result;
}

/// Reduced motion, for the whole application: R_TRUE and nothing
/// moves by itself. Changes are immediate (no spring, no slide, no bounce,
/// no transition), and the effects (raven_shader.h) stand still; they still
/// follow the pointer. Same as Rset_animations_enabled(R_FALSE).
pub fn accessibilitySetReduceMotion(enabled: bool) void {
    c.Raccessibility_set_reduce_motion(@intFromBool(enabled));
}

pub fn accessibilityGetReduceMotion() i32 {
    const result = c.Raccessibility_get_reduce_motion();
    return result;
}

/// A filter on the colors of the interface (pictures and viewports keep theirs).
pub fn accessibilitySetColorFilter(filter: ColorFilter) void {
    c.Raccessibility_set_color_filter(@backingInt(filter));
}

pub fn accessibilityGetColorFilter() ColorFilter {
    const result = c.Raccessibility_get_color_filter();
    return @as(ColorFilter, @fromBackingInt(result));
}

pub fn accessibilityGetSystemSettings() AccessibilitySettings {
    var raw_settings: c.RAccessibilitySettings = .{};
    c.Raccessibility_get_system_settings(&raw_settings);
    return .fromC(raw_settings);
}

/// Applies the settings of the system (text size, contrast, motion).
pub fn accessibilityFollowSystem() void {
    c.Raccessibility_follow_system();
}

/// Has a message read (a save that ended, an error). `assertive`: interrupts what is being read.
pub fn accessibilityAnnounce(text: [:0]const u8, assertive: i32) void {
    c.Raccessibility_announce(text.ptr, assertive);
}

/// R_TRUE when a screen reader is reading the windows of the application.
pub fn accessibilityIsScreenReaderActive() bool {
    const result = c.Raccessibility_is_screen_reader_active();
    return result != 0;
}

/// Makes the next Rinit use the host platform. The structure is copied; NULL restores the default.
pub fn hostPlatformRegister(desc: *const c.RHostPlatformDesc) void {
    c.Rhost_platform_register(desc);
}

/// Returns: R_TRUE while the running library uses the host platform.
pub fn hostPlatformIsActive() bool {
    const result = c.Rhost_platform_is_active();
    return result != 0;
}

/// Size of a host window in pixels, and pixels per logical unit.
pub fn hostWindowSetSize(window: Window, width: i32, height: i32, scale: f32) void {
    c.Rhost_window_set_size(@backingInt(window), width, height, scale);
}

/// What covers a host window on a phone or a tablet, in pixels: the
/// safe area (status bar, notch, home indicator; NULL: none) and the height
/// of the on-screen keyboard over its bottom (0: hidden). The content is laid
/// out inside them (Rwindow_get_safe_area, Rwindow_get_keyboard_area).
pub fn hostWindowSetInsets(window: Window, safe_area: ?Insets, keyboard_height: i32) void {
    const raw_safe_area: ?c.RInsets = if (safe_area) |v| v.toC() else null;
    c.Rhost_window_set_insets(@backingInt(window), if (raw_safe_area) |*v| v else null, keyboard_height);
}

/// The application's system is in dark (R_TRUE) or light (R_FALSE)
/// mode, -1 when it does not tell (the default): Rtheme_get_system_dark,
/// and Rtheme_follow_system follows it.
pub fn hostSetSystemDark(dark: bool) void {
    c.Rhost_set_system_dark(@intFromBool(dark));
}

pub fn hostInjectMouseMove(window: Window, x: i32, y: i32, modifiers: Modifier) void {
    c.Rhost_inject_mouse_move(@backingInt(window), x, y, @as(u32, @bitCast(modifiers)));
}

pub fn hostInjectMouseButton(window: Window, x: i32, y: i32, button: MouseButton, pressed: bool, modifiers: Modifier) void {
    c.Rhost_inject_mouse_button(@backingInt(window), x, y, @backingInt(button), @intFromBool(pressed), @as(u32, @bitCast(modifiers)));
}

pub fn hostInjectMouseWheel(window: Window, wheel_x: f32, wheel_y: f32, modifiers: Modifier) void {
    c.Rhost_inject_mouse_wheel(@backingInt(window), wheel_x, wheel_y, @as(u32, @bitCast(modifiers)));
}

/// The pointer left the window: hover states end.
pub fn hostInjectMouseLeave(window: Window) void {
    c.Rhost_inject_mouse_leave(@backingInt(window));
}

/// repeat R_TRUE for a key held down (auto-repeat).
pub fn hostInjectKey(window: Window, key: Key, pressed: bool, modifiers: Modifier, repeat: bool) void {
    c.Rhost_inject_key(@backingInt(window), @backingInt(key), @intFromBool(pressed), @as(u32, @bitCast(modifiers)), @intFromBool(repeat));
}

/// One typed Unicode code point.
pub fn hostInjectText(window: Window, codepoint: u32) void {
    c.Rhost_inject_text(@backingInt(window), codepoint);
}

/// The input method of the application's system composes `text`
/// (preedit), with its selection in bytes (see Rwindow_inject_composition).
/// NULL or "" cancels it; the committed text then comes through
/// Rhost_inject_text. Rwindow_get_text_input_rect tells where to put the
/// candidate window.
pub fn hostInjectComposition(window: Window, text: ?[:0]const u8, selection_start: i32, selection_end: i32) void {
    c.Rhost_inject_composition(@backingInt(window), rt.optPtr(text), selection_start, selection_end);
}

/// The window gained or lost the keyboard. Losing it closes popups and drops captures.
pub fn hostInjectFocus(window: Window, focused: i32) void {
    c.Rhost_inject_focus(@backingInt(window), focused);
}

/// The user asked to close the window (its close callback decides).
pub fn hostInjectClose(window: Window) void {
    c.Rhost_inject_close(@backingInt(window));
}

/// The user answered a permission_request (or the status changed
/// by itself). The waiting Rpermission_request callbacks get it at the
/// next frame. Any thread.
pub fn hostPermissionAnswer(permission: Permission, status: PermissionStatus) void {
    c.Rhost_permission_answer(@backingInt(permission), @backingInt(status));
}

/// The end of a service_request: the files it gave (copied; paths
/// Raven can read; size 0 is read from the file), at the next frame. Once
/// per request. Any thread.
pub fn hostServiceComplete(request: u32, result: DeviceResult, files: []const PickedFile) void {
    c.Rhost_service_complete(request, @backingInt(result), @ptrCast(files.ptr), @intCast(files.len));
}

/// R_TRUE makes what is drawn depend only on what the test does:
/// every frame advances the animations by 1/60 s (Rset_animation_time_step),
/// and the carets of the text fields stay lit instead of blinking. R_FALSE
/// gives the clock back (time step 0).
pub fn testSetDeterministic(enabled: bool) void {
    c.Rtest_set_deterministic(@intFromBool(enabled));
}

pub fn testIsDeterministic() bool {
    const result = c.Rtest_is_deterministic();
    return result != 0;
}

/// Returns: What the goldens of this run are made with, "OS-backend":
/// "macos-metal", "linux-vulkan", "windows-vulkan", "web-webgl"... and
/// "null" with the null backend.
pub fn testGetPlatformTag() [:0]const u8 {
    const result = c.Rtest_get_platform_tag();
    return rt.span(result);
}

/// Finds a widget by name (Rwidget_set_name, Name="" in XML). The
/// path may have several names separated by '/': "settings/ok" is the
/// widget named "ok" inside the one named "settings". In a window, the
/// open popups (menus, dialogs) are searched first, top first, then the
/// content.
/// scope A window or a widget.
/// Returns: R_INVALID_ID when nothing has that name (no error is reported).
pub fn testFind(scope: ?Widget, path: [:0]const u8) c.Rid {
    const result = c.Rtest_find(optId(scope), path.ptr);
    return result;
}

/// Moves the mouse to the middle of the widget, presses and releases the left button.
pub fn testClick(widget: Widget) i32 {
    const result = c.Rtest_click(@backingInt(widget));
    return result;
}

/// Two clicks in a row on the middle of the widget, seen as a double click.
pub fn testDoubleClick(widget: Widget) i32 {
    const result = c.Rtest_double_click(@backingInt(widget));
    return result;
}

/// A click of the right button on the middle of the widget (a context menu).
pub fn testRightClick(widget: Widget) i32 {
    const result = c.Rtest_right_click(@backingInt(widget));
    return result;
}

/// Clicks at a position of a widget or a window.
/// clicks 1 for a click, 2 for a double click, 3 for a triple click.
/// modifiers RModifier held during the clicks (R_MOD_SHIFT...).
pub fn testClickAt(target: Widget, x: f32, y: f32, button: MouseButton, clicks: i32, modifiers: Modifier) i32 {
    const result = c.Rtest_click_at(@backingInt(target), x, y, @backingInt(button), clicks, @as(u32, @bitCast(modifiers)));
    return result;
}

/// Moves the mouse over the middle of the widget, without clicking.
pub fn testHover(widget: Widget) i32 {
    const result = c.Rtest_hover(@backingInt(widget));
    return result;
}

/// Moves the mouse to a position of a widget or a window.
pub fn testHoverAt(target: Widget, x: f32, y: f32) i32 {
    const result = c.Rtest_hover_at(@backingInt(target), x, y);
    return result;
}

/// Presses the left button on the middle of the widget, moves by
/// (dx, dy) in several steps, and releases: a slider, a splitter, a
/// window dragged by a widget.
pub fn testDrag(widget: Widget, dx: f32, dy: f32) i32 {
    const result = c.Rtest_drag(@backingInt(widget), dx, dy);
    return result;
}

/// Drags from the middle of one widget to the middle of another (drag and drop).
pub fn testDragTo(from: Widget, to: Widget) i32 {
    const result = c.Rtest_drag_to(@backingInt(from), @backingInt(to));
    return result;
}

/// Turns the mouse wheel over the middle of the widget: `wheel_y`
/// notches (positive: toward the top, as a wheel turned away from the
/// user), `wheel_x` notches sideways.
pub fn testScroll(widget: Widget, wheel_x: f32, wheel_y: f32) i32 {
    const result = c.Rtest_scroll(@backingInt(widget), wheel_x, wheel_y);
    return result;
}

/// Presses and releases a key, with RModifier held. A widget
/// target gets the keyboard focus first; a window sends the key to what
/// has the focus.
pub fn testKey(target: Widget, key: Key, modifiers: Modifier) i32 {
    const result = c.Rtest_key(@backingInt(target), @backingInt(key), @as(u32, @bitCast(modifiers)));
    return result;
}

/// Types UTF-8 text as a keyboard would. A widget target gets the
/// keyboard focus first. '\n', '\t' and '\b' are sent as the keys Enter,
/// Tab and Backspace.
pub fn testTypeText(target: Widget, text: [:0]const u8) i32 {
    const result = c.Rtest_type_text(@backingInt(target), text.ptr);
    return result;
}

/// A finger touches the middle of the widget and leaves at once.
pub fn testTap(widget: Widget) i32 {
    const result = c.Rtest_tap(@backingInt(widget));
    return result;
}

/// A finger put on the middle of the widget moves by (dx, dy) in
/// `seconds`, and leaves: a fast swipe flicks a list, which then coasts
/// (Rtest_settle lets it stop).
pub fn testSwipe(widget: Widget, dx: f32, dy: f32, seconds: f64) i32 {
    const result = c.Rtest_swipe(@backingInt(widget), dx, dy, seconds);
    return result;
}

/// Produces `frames` frames (Rdraw_frame). Returns: R_FALSE once the application quits.
pub fn testPump(frames: i32) bool {
    const result = c.Rtest_pump(frames);
    return result != 0;
}

/// Returns: R_TRUE when nothing waits for a frame: no posted task, no layout
/// to do, nothing to paint, no animation, no layout spring, no inertia.
/// Windows that redraw all the time (Rwindow_set_continuous_redraw, a
/// realtime viewport) and the timers are not counted.
pub fn testIsIdle() bool {
    const result = c.Rtest_is_idle();
    return result != 0;
}

/// Produces frames until Rtest_is_idle, each advancing the
/// animations by the time step (1/60 s unless Rset_animation_time_step
/// gives another), for at most `max_seconds` of that time.
/// Returns: R_FALSE when it was still moving at the end.
pub fn testSettle(max_seconds: f64) bool {
    const result = c.Rtest_settle(max_seconds);
    return result != 0;
}

/// Returns: What the user reads in the widget: the text of a field, else
/// its label (as screen readers say it: the text of a Label, a Button, a
/// Checkbox...). "" when it has none. Valid until the next call.
pub fn testGetText(widget: Widget) [:0]const u8 {
    const result = c.Rtest_get_text(@backingInt(widget));
    return rt.span(result);
}

/// Returns: R_TRUE when the widget can be seen: in a window, Visible with
/// all that holds it, on the page a Switcher or a TabView shows, and laid
/// out with a size.
pub fn testIsShown(widget: Widget) bool {
    const result = c.Rtest_is_shown(@backingInt(widget));
    return result != 0;
}

/// Returns: R_TRUE for a checked Checkbox, Switch, RadioButton, toggle Button or menu item.
pub fn testIsChecked(widget: Widget) bool {
    const result = c.Rtest_is_checked(@backingInt(widget));
    return result != 0;
}

/// Captures a window, or the rectangle of one widget, and compares
/// it with the PNG file `golden_path` (see the top of this file).
/// target A window or a widget.
/// options NULL for the defaults.
/// result Receives the details; may be NULL.
/// Returns: R_TRUE when the capture matches (or the golden was written
/// because RAVEN_UPDATE_GOLDENS=1).
pub fn testExpectGolden(target: Widget, golden_path: [:0]const u8, options: ?GoldenOptions) ?GoldenResult {
    const raw_options: ?c.RGoldenOptions = if (options) |v| v.toC() else null;
    var raw_result: c.RGoldenResult = .{};
    if (c.Rtest_expect_golden(@backingInt(target), golden_path.ptr, if (raw_options) |*v| v else null, &raw_result) == 0) return null;
    return .fromC(raw_result);
}

/// Compares two RGBA8 images of the same size as Rtest_expect_golden
/// does, without files.
/// diff_rgba When not NULL, receives width * height * 4 bytes: the
/// expected image faded, with the different pixels in red.
/// Returns: The number of pixels farther apart than `channel_tolerance`;
/// -1 when an image is missing.
pub fn testComparePixels(actual: ?[*]const u8, expected: []const u8, width: i32, height: i32, channel_tolerance: i32, diff_rgba: ?[*]u8) ?i32 {
    std.debug.assert(expected.len >= @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
    var max_channel_difference: c_int = 0;
    if (c.Rtest_compare_pixels(actual, expected.ptr, width, height, channel_tolerance, &max_channel_difference, diff_rgba) == 0) return null;
    return max_channel_difference;
}

/// The widgets as JSON, what a test, a script or an agent reads of
/// the interface. Each widget gives its "type" (its XML tag), "name" and
/// "path" (for Rtest_find) when it has a name, its accessibility "role",
/// its "text" (Rtest_get_text), "label" and "value" when they differ,
/// "bounds" [x, y, width, height] in logical units of its window,
/// "shown", "enabled", and when they apply "focused", "checked",
/// "selected", "expanded", "number"/"minimum"/"maximum", the rows of a
/// list ("items") and its "children", in the order of the layout.
/// target A window or a widget; R_INVALID_ID for every window of
/// the application: {"raven": version, "backend": tag, "windows": [...]},
/// each with its "title", "size", "scale", "content", "popups".
/// Returns: The JSON text, valid until the next call. "" on error.
pub fn testDumpTree(target: ?Widget) [:0]const u8 {
    const result = c.Rtest_dump_tree(optId(target));
    return rt.span(result);
}

/// Rtest_dump_tree written to a file ("-": the standard output).
pub fn testSaveTree(target: Widget, path: [:0]const u8) i32 {
    const result = c.Rtest_save_tree(@backingInt(target), path.ptr);
    return result;
}

/// Captures a window, or the rectangle of a widget, into a PNG
/// file. The null backend draws nothing: its picture is the clear color.
pub fn testSavePng(target: Widget, path: [:0]const u8) i32 {
    const result = c.Rtest_save_png(@backingInt(target), path.ptr);
    return result;
}

/// Runs a script of steps, one per line, as RAVEN_SCRIPT does (see
/// "Driving any application headlessly" in README.md):
///
///     click form/user
///     type "ada"
///     key Enter
///     expect status text "Welcome, ada"
///     snap after-login
///
/// The frames are produced by the function (Rdraw_frame) until the script
/// ends. A widget is named by its name or path, by "text:Sign in" (the
/// first one shown that reads it), or a point of the window by "@x,y".
/// script The text of the script.
/// source_name The name its messages give it ("login.script"); may be NULL.
/// Returns: R_TRUE when every step was done and every check was true;
/// R_FALSE otherwise, with the reason in Rtest_get_script_error.
pub fn testRunScript(script: ?[:0]const u8, source_name: ?[:0]const u8) bool {
    const result = c.Rtest_run_script(rt.optPtr(script), rt.optPtr(source_name));
    return result != 0;
}

/// Returns: Why the last Rtest_run_script failed ("login.script:4: expect: ..."), "" when it passed.
pub fn testGetScriptError() [:0]const u8 {
    const result = c.Rtest_get_script_error();
    return rt.span(result);
}

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

/// Whether the system is in dark mode; null when the platform does not tell.
pub fn themeGetSystemDark() ?bool {
    const result = c.Rtheme_get_system_dark();
    return if (result < 0) null else result != 0;
}

// ---- checks (`zig build check`): every declaration compiles

test "every declaration compiles" {
    refAllDeclsRecursive(@This());
    _ = &everyCallbackSetter;
}

fn refAllDeclsRecursive(comptime T: type) void {
    @setEvalBranchQuota(1_000_000);
    inline for (comptime std.meta.declarations(T)) |name| {
        if (T == @This() and comptime std.mem.eql(u8, name, "c")) continue;
        const D = @TypeOf(@field(T, name));
        if (D == type) {
            switch (@typeInfo(@field(T, name))) {
                .@"struct", .@"enum", .@"union", .@"opaque" => refAllDeclsRecursive(@field(T, name)),
                else => {},
            }
        } else if (@typeInfo(D) != .@"fn" or !@typeInfo(D).@"fn".is_generic) {
            _ = &@field(T, name);
        }
    }
}

fn everyCallbackSetter() void {
    consume(Widget.setTouchCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: TouchEvent) bool {
            return false;
        }
    }.f));
    consume(Widget.setPenCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: PenEvent) bool {
            return false;
        }
    }.f));
    consume(Widget.setGestureCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: GestureEvent) bool {
            return false;
        }
    }.f));
    consume(Widget.setDestroyCallback(undefined, {}, struct {
        fn f(_: void, _: Widget) void {}
    }.f));
    consume(Widget.setEventCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: Event) bool {
            return false;
        }
    }.f));
    consume(Widget.setDropCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: DropEvent) bool {
            return false;
        }
    }.f));
    consume(Widget.setAccessibleAction(undefined, {}, struct {
        fn f(_: void, _: Widget) void {}
    }.f));
    consume(Label.setLinkCallback(undefined, {}, struct {
        fn f(_: void, _: Label, _: [:0]const u8) void {}
    }.f));
    consume(Button.setClickedCallback(undefined, {}, struct {
        fn f(_: void, _: Button) void {}
    }.f));
    consume(Checkbox.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Checkbox, _: bool) void {}
    }.f));
    consume(Slider.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Slider, _: f32) void {}
    }.f));
    consume(Image.setFinishedCallback(undefined, {}, struct {
        fn f(_: void, _: Image) void {}
    }.f));
    consume(TextInput.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: TextInput, _: [:0]const u8) void {}
    }.f));
    consume(TextInput.setCommittedCallback(undefined, {}, struct {
        fn f(_: void, _: TextInput, _: [:0]const u8) void {}
    }.f));
    consume(SpinBox.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: SpinBox, _: f64) void {}
    }.f));
    consume(ComboBox.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: ComboBox, _: i32) void {}
    }.f));
    consume(ComboBox.setTextChangedCallback(undefined, {}, struct {
        fn f(_: void, _: ComboBox, _: [:0]const u8) void {}
    }.f));
    consume(ListView.setVirtualItems(undefined, undefined, {}, struct {
        fn f(_: void, _: ListView, _: i32) ?[:0]const u8 {
            return null;
        }
    }.f));
    consume(ListView.setItemColorCallback(undefined, {}, struct {
        fn f(_: void, _: ListView, _: i32) ?Color {
            return null;
        }
    }.f));
    consume(ListView.setSelectionChangedCallback(undefined, {}, struct {
        fn f(_: void, _: ListView, _: i32) void {}
    }.f));
    consume(ListView.setActivatedCallback(undefined, {}, struct {
        fn f(_: void, _: ListView, _: i32) void {}
    }.f));
    consume(TreeView.setSelectionChangedCallback(undefined, {}, struct {
        fn f(_: void, _: TreeView, _: TreeItem) void {}
    }.f));
    consume(TreeView.setActivatedCallback(undefined, {}, struct {
        fn f(_: void, _: TreeView, _: TreeItem) void {}
    }.f));
    consume(TreeView.setContextCallback(undefined, {}, struct {
        fn f(_: void, _: TreeView, _: TreeItem, _: f32, _: f32) void {}
    }.f));
    consume(MenuItem.setClickedCallback(undefined, {}, struct {
        fn f(_: void, _: TreeItem) void {}
    }.f));
    consume(TabView.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: TabView, _: i32) void {}
    }.f));
    consume(TabView.setCloseCallback(undefined, {}, struct {
        fn f(_: void, _: TabView, _: i32, _: Widget) bool {
            return false;
        }
    }.f));
    consume(Expander.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Expander, _: bool) void {}
    }.f));
    consume(TextEditor.setZoomCallback(undefined, {}, struct {
        fn f(_: void, _: TextEditor, _: f32) void {}
    }.f));
    consume(TextEditor.setCompletionCallback(undefined, {}, struct {
        fn f(_: void, _: TextEditor, _: [:0]const u8) void {}
    }.f));
    consume(TextEditor.setHoverCallback(undefined, {}, struct {
        fn f(_: void, _: TextEditor, _: i32, _: i32) ?[:0]const u8 {
            return null;
        }
    }.f));
    consume(TextEditor.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: TextEditor) void {}
    }.f));
    consume(DockArea.setCloseCallback(undefined, {}, struct {
        fn f(_: void, _: DockArea, _: Widget) bool {
            return false;
        }
    }.f));
    consume(DockArea.setFloatWindow(undefined, undefined, {}, struct {
        fn f(_: void, _: DockArea, _: Widget, _: Window, _: DockArea) ?Widget {
            return null;
        }
    }.f));
    consume(DockArea.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: DockArea) void {}
    }.f));
    consume(Island.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Island, _: bool) void {}
    }.f));
    consume(FileBrowser.setAcceptedCallback(undefined, {}, struct {
        fn f(_: void, _: FileBrowser, _: [:0]const u8) void {}
    }.f));
    consume(FileBrowser.setCancelledCallback(undefined, {}, struct {
        fn f(_: void, _: FileBrowser, _: [:0]const u8) void {}
    }.f));
    consume(FileBrowser.setSelectionChangedCallback(undefined, {}, struct {
        fn f(_: void, _: FileBrowser, _: [:0]const u8) void {}
    }.f));
    consume(Viewport.setDrawCallback(undefined, {}, struct {
        fn f(_: void, _: ViewportDrawInfo) void {}
    }.f));
    consume(Viewport.setResizeCallback(undefined, {}, struct {
        fn f(_: void, _: Viewport, _: i32, _: i32) void {}
    }.f));
    consume(Custom.setPaintCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: *Painter, _: f32, _: f32) void {}
    }.f));
    consume(Custom.setMeasureCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: *f32, _: *f32) void {}
    }.f));
    consume(ColorPicker.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: ColorPicker, _: f32, _: f32, _: f32, _: f32) void {}
    }.f));
    consume(Timeline.setTimeCallback(undefined, {}, struct {
        fn f(_: void, _: Timeline, _: f64) void {}
    }.f));
    consume(Timeline.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Timeline, _: i32) void {}
    }.f));
    consume(Timeline.setSelectionCallback(undefined, {}, struct {
        fn f(_: void, _: Timeline, _: i32) void {}
    }.f));
    consume(Timeline.setActivatedCallback(undefined, {}, struct {
        fn f(_: void, _: Timeline, _: i32) void {}
    }.f));
    consume(Timeline.setRemovedCallback(undefined, {}, struct {
        fn f(_: void, _: Timeline, _: i32) void {}
    }.f));
    consume(NodeGraph.setConnectCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32, _: i32) bool {
            return false;
        }
    }.f));
    consume(NodeGraph.setLinkedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32) void {}
    }.f));
    consume(NodeGraph.setUnlinkedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32) void {}
    }.f));
    consume(NodeGraph.setMovedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32) void {}
    }.f));
    consume(NodeGraph.setSelectionCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32) void {}
    }.f));
    consume(NodeGraph.setRemovedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32) void {}
    }.f));
    consume(NodeGraph.setActivatedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32) void {}
    }.f));
    consume(NodeGraph.setContextCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32, _: f32, _: f32) void {}
    }.f));
    consume(NodeGraph.setCanvasActivatedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32, _: f32, _: f32) void {}
    }.f));
    consume(NodeGraph.setWireDroppedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32, _: f32, _: f32) void {}
    }.f));
    consume(NodeGraph.setPinClickedCallback(undefined, {}, struct {
        fn f(_: void, _: NodeGraph, _: i32, _: f32, _: f32) void {}
    }.f));
    consume(TileView.setItems(undefined, undefined, {}, struct {
        fn f(_: void, _: TileView, _: i32, _: *TileItem) void {}
    }.f));
    consume(TileView.setSections(undefined, undefined, {}, struct {
        fn f(_: void, _: TileView, _: i32, _: *TileSection) void {}
    }.f));
    consume(TileView.setSectionToggledCallback(undefined, {}, struct {
        fn f(_: void, _: TileView, _: i32) void {}
    }.f));
    consume(TileView.setDragDataCallback(undefined, {}, struct {
        fn f(_: void, _: TileView) ?[:0]const u8 {
            return null;
        }
    }.f));
    consume(TileView.setDragOutCallback(undefined, {}, struct {
        fn f(_: void, _: TileView, _: i32) void {}
    }.f));
    consume(TileView.setSelectionChangedCallback(undefined, {}, struct {
        fn f(_: void, _: TileView, _: i32) void {}
    }.f));
    consume(TileView.setActivatedCallback(undefined, {}, struct {
        fn f(_: void, _: TileView, _: i32) void {}
    }.f));
    consume(TileView.setContextCallback(undefined, {}, struct {
        fn f(_: void, _: TileView, _: i32, _: f32, _: f32) void {}
    }.f));
    consume(BlockEditor.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: BlockEditor, _: i32) void {}
    }.f));
    consume(BlockEditor.setClickedCallback(undefined, {}, struct {
        fn f(_: void, _: BlockEditor, _: i32) void {}
    }.f));
    consume(BlockEditor.setContextCallback(undefined, {}, struct {
        fn f(_: void, _: BlockEditor, _: i32, _: f32, _: f32) void {}
    }.f));
    consume(Table.setVirtualRows(undefined, undefined, {}, struct {
        fn f(_: void, _: Table, _: i32, _: i32) ?[:0]const u8 {
            return null;
        }
    }.f));
    consume(Table.setCellColorCallback(undefined, {}, struct {
        fn f(_: void, _: Table, _: i32, _: i32) ?Color {
            return null;
        }
    }.f));
    consume(Table.setSelectionChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Table, _: i32) void {}
    }.f));
    consume(Table.setActivatedCallback(undefined, {}, struct {
        fn f(_: void, _: Table, _: i32) void {}
    }.f));
    consume(Table.setSortCallback(undefined, {}, struct {
        fn f(_: void, _: Table, _: i32, _: bool) void {}
    }.f));
    consume(Table.setCellEditedCallback(undefined, {}, struct {
        fn f(_: void, _: Table, _: i32, _: i32, _: [:0]const u8) bool {
            return false;
        }
    }.f));
    consume(DatePicker.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: DatePicker, _: i32, _: i32, _: i32) void {}
    }.f));
    consume(TimePicker.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: TimePicker, _: i32, _: i32, _: i32) void {}
    }.f));
    consume(Toast.setActionCallback(undefined, {}, struct {
        fn f(_: void, _: Toast) void {}
    }.f));
    consume(Breadcrumb.setClickedCallback(undefined, {}, struct {
        fn f(_: void, _: Breadcrumb, _: i32) void {}
    }.f));
    consume(Rating.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Rating, _: f32) void {}
    }.f));
    consume(Pagination.setChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Pagination, _: i32) void {}
    }.f));
    consume(Plot.setViewChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Plot) void {}
    }.f));
    consume(Plot.setDragLineCallback(undefined, {}, struct {
        fn f(_: void, _: Plot, _: i32, _: f64) void {}
    }.f));
    consume(Plot.setSeriesToggledCallback(undefined, {}, struct {
        fn f(_: void, _: Plot, _: i32, _: bool) void {}
    }.f));
    consume(PdfView.setPageChangedCallback(undefined, {}, struct {
        fn f(_: void, _: PdfView, _: i32) void {}
    }.f));
    consume(Chart.setSliceClickedCallback(undefined, {}, struct {
        fn f(_: void, _: Chart, _: i32, _: bool) void {}
    }.f));
    consume(Chart.setCellClickedCallback(undefined, {}, struct {
        fn f(_: void, _: Chart, _: i32, _: i32, _: f32) void {}
    }.f));
    consume(MapView.setTileCallback(undefined, {}, struct {
        fn f(_: void, _: MapView, _: i32, _: i32, _: i32) void {}
    }.f));
    consume(MapView.setTileCancelCallback(undefined, {}, struct {
        fn f(_: void, _: MapView, _: i32, _: i32, _: i32) void {}
    }.f));
    consume(MapView.setMarkerClickedCallback(undefined, {}, struct {
        fn f(_: void, _: MapView, _: i32) void {}
    }.f));
    consume(MapView.setViewChangedCallback(undefined, {}, struct {
        fn f(_: void, _: MapView, _: f64, _: f64, _: f64) void {}
    }.f));
    consume(Carousel.setPageChangedCallback(undefined, {}, struct {
        fn f(_: void, _: Carousel, _: i32) void {}
    }.f));
    consume(SystemWebView.runJavascript(undefined, undefined, {}, struct {
        fn f(_: void, _: SystemWebView, _: [:0]const u8, _: [:0]const u8) void {}
    }.f));
    consume(SystemWebView.setMessageCallback(undefined, {}, struct {
        fn f(_: void, _: SystemWebView, _: [:0]const u8) void {}
    }.f));
    consume(SystemWebView.setEventCallback(undefined, {}, struct {
        fn f(_: void, _: SystemWebView, _: SystemWebViewEvent) void {}
    }.f));
    consume(DiffView.setLineClickedCallback(undefined, {}, struct {
        fn f(_: void, _: DiffView, _: DiffSide, _: i32, _: i32) void {}
    }.f));
    consume(Window.setKeyboardCallback(undefined, {}, struct {
        fn f(_: void, _: Window, _: bool, _: f32) void {}
    }.f));
    consume(Window.setBackCallback(undefined, {}, struct {
        fn f(_: void, _: Window) bool {
            return false;
        }
    }.f));
    consume(Window.setCloseCallback(undefined, {}, struct {
        fn f(_: void, _: Window) bool {
            return false;
        }
    }.f));
    consume(Window.setResizeCallback(undefined, {}, struct {
        fn f(_: void, _: Window, _: i32, _: i32) void {}
    }.f));
    consume(Window.setDropCallback(undefined, {}, struct {
        fn f(_: void, _: Widget, _: DropEvent) bool {
            return false;
        }
    }.f));
    consume(Window.setEventHook(undefined, {}, struct {
        fn f(_: void, _: Window, _: Event) bool {
            return false;
        }
    }.f));
    consume(Timer.create(undefined, undefined, {}, struct {
        fn f(_: void, _: Timer) void {}
    }.f));
    consume(Tray.setClickedCallback(undefined, {}, struct {
        fn f(_: void, _: Tray, _: MouseButton) void {}
    }.f));
    consume(setFrameCallback({}, struct {
        fn f(_: void, _: f64) void {}
    }.f));
    consume(setAppEventCallback({}, struct {
        fn f(_: void, _: AppEvent) void {}
    }.f));
    consume(taskPost({}, struct {
        fn f(_: void) void {}
    }.f));
    consume(taskRunAsync({}, struct {
        fn f(_: void) void {}
    }.f));
    consume(parallelFor(undefined, undefined, {}, struct {
        fn f(_: void, _: u32, _: u32) void {}
    }.f));
    consume(actionBind(undefined, {}, struct {
        fn f(_: void, _: ?Widget, _: [:0]const u8) void {}
    }.f));
    consume(actionSetDefaultHandler({}, struct {
        fn f(_: void, _: ?Widget, _: [:0]const u8) void {}
    }.f));
    consume(actionBindWithParameters(undefined, undefined, {}, struct {
        fn f(_: void, _: *Painter) void {}
    }.f));
    consume(errorSetCallback(struct {
        fn f(_: ErrorCode, _: Severity, _: [:0]const u8) void {}
    }.f));
    consume(setDeviceResetCallback({}, struct {
        fn f(_: void) void {}
    }.f));
    consume(dragBeginExternal(undefined, undefined, undefined, {}, struct {
        fn f(_: void, _: Widget, _: DragOperation) void {}
    }.f));
    consume(dialogOpen(undefined, undefined, {}, struct {
        fn f(_: void, _: Widget, _: i32) void {}
    }.f));
    consume(popupOpen(undefined, undefined, undefined, undefined, {}, struct {
        fn f(_: void, _: Widget, _: i32) void {}
    }.f));
    consume(notificationSetFallback({}, struct {
        fn f(_: void, _: [:0]const u8, _: [:0]const u8, _: NotificationUrgency) void {}
    }.f));
    consume(notificationSetClickedCallback({}, struct {
        fn f(_: void) void {}
    }.f));
    consume(notificationSetCallback({}, struct {
        fn f(_: void, _: [:0]const u8, _: NotificationEvent, _: [:0]const u8) void {}
    }.f));
    consume(permissionRequest(undefined, {}, struct {
        fn f(_: void, _: Permission, _: PermissionStatus) void {}
    }.f));
    consume(fileOpenAsync(undefined, {}, struct {
        fn f(_: void, _: DeviceResult, _: PickedFile, _: i32) void {}
    }.f));
    consume(fileSaveAsync(undefined, undefined, {}, struct {
        fn f(_: void, _: DeviceResult, _: PickedFile, _: i32) void {}
    }.f));
    consume(fileExportAsync(undefined, undefined, {}, struct {
        fn f(_: void, _: DeviceResult, _: PickedFile, _: i32) void {}
    }.f));
    consume(fileSelectFolderAsync(undefined, {}, struct {
        fn f(_: void, _: DeviceResult, _: PickedFile, _: i32) void {}
    }.f));
    consume(cameraTakePhoto({}, struct {
        fn f(_: void, _: DeviceResult, _: PickedFile, _: i32) void {}
    }.f));
    consume(photoPick(undefined, {}, struct {
        fn f(_: void, _: DeviceResult, _: PickedFile, _: i32) void {}
    }.f));
    consume(shareShow(undefined, {}, struct {
        fn f(_: void, _: DeviceResult, _: PickedFile, _: i32) void {}
    }.f));
    consume(xmlSetReloadCallback({}, struct {
        fn f(_: void, _: [:0]const u8, _: bool) void {}
    }.f));
    consume(xmlRegisterTag(undefined, {}, struct {
        fn f(_: void, _: [:0]const u8) ?Widget {
            return null;
        }
    }.f, struct {
        fn f(_: void, _: Widget, _: [:0]const u8, _: [:0]const u8) bool {
            return false;
        }
    }.f));
    consume(scriptSetLogCallback({}, struct {
        fn f(_: void, _: [:0]const u8) void {}
    }.f));
    consume(scriptSetDiagnosticCallback({}, struct {
        fn f(_: void, _: Severity, _: [:0]const u8, _: [:0]const u8, _: i32, _: i32, _: [:0]const u8) void {}
    }.f));
    consume(localeSetChangedCallback({}, struct {
        fn f(_: void, _: [:0]const u8) void {}
    }.f));
}

fn consume(value: anytype) void {
    std.mem.doNotOptimizeAway(&value);
}
