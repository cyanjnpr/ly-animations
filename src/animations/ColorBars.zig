const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const math = std.math;

pub const PALETTE_LEN: usize = 8;

const ColorBars = @This();

terminal_buffer: *TerminalBuffer,
frames: u64,
glitch_amplitude: usize,
glitch_scale: f32,
palette: [PALETTE_LEN]Cell,

pub fn init(terminal_buffer: *TerminalBuffer, brightness: f32, glitch_amplitude: usize, glitch_scale: f32) ColorBars {
    var cell_code: u32 = 0x2588;
    if (brightness < 0.25) {
        cell_code = 0x2591;
    } else if (brightness < 0.5) {
        cell_code = 0x2592;
    } else if (brightness < 0.75) {
        cell_code = 0x2593;
    }
    return .{
        .terminal_buffer = terminal_buffer,
        .frames = 0,
        .glitch_amplitude = glitch_amplitude,
        .glitch_scale = glitch_scale,
        .palette = [PALETTE_LEN]Cell{
            Cell.init(cell_code, 0x00FFFFFF, terminal_buffer.bg),
            Cell.init(cell_code, 0x00FFFF00, terminal_buffer.bg),
            Cell.init(cell_code, 0x0000FFFF, terminal_buffer.bg),
            Cell.init(cell_code, 0x0000FF00, terminal_buffer.bg),
            Cell.init(cell_code, 0x00FF00FF, terminal_buffer.bg),
            Cell.init(cell_code, 0x00FF0000, terminal_buffer.bg),
            Cell.init(cell_code, 0x000000FF, terminal_buffer.bg),
            Cell.init(cell_code, 0x00000000, terminal_buffer.bg),
        },
    };
}

pub fn animation(self: *ColorBars) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *ColorBars) void {}

fn realloc(_: *ColorBars) anyerror!void {}

fn draw(self: *ColorBars) void {
    self.frames +%= 1;

    for (0..self.terminal_buffer.width) |x| {
        for (0..self.terminal_buffer.height) |y| {
            const normalized_x: f32 = @mod(@as(f32, @floatFromInt(y + self.frames)) * self.glitch_scale, 2 * math.pi);
            const s: usize = @intFromFloat(@as(f32, @floatFromInt(self.glitch_amplitude)) * (@sin(normalized_x) + 1) / 2);

            const cell_x = if (x >= s) x - s else x;

            const index: usize = @intFromFloat(@as(f32, @floatFromInt(x)) /
                @as(f32, @floatFromInt(self.terminal_buffer.width)) * @as(f32, @floatFromInt(PALETTE_LEN)));

            self.palette[index].put(cell_x, y);
        }
    }
}
