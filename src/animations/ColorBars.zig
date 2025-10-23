const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const math = std.math;

pub const PALETTE_LEN: usize = 8;
pub const GLITCH_SCALE = 0.1;

const ColorBars = @This();

terminal_buffer: *TerminalBuffer,
frames: u64,
delay: usize,
palette: [PALETTE_LEN]Cell,

pub fn init(terminal_buffer: *TerminalBuffer, delay: usize) ColorBars {
    return .{
        .terminal_buffer = terminal_buffer,
        .frames = 0,
        .delay = delay + 1,
        .palette = [PALETTE_LEN]Cell{
            Cell.init(0x2591, 0x00FFFFFF, terminal_buffer.bg),
            Cell.init(0x2591, 0x00FFFF00, terminal_buffer.bg),
            Cell.init(0x2591, 0x0000FFFF, terminal_buffer.bg),
            Cell.init(0x2591, 0x0000FF00, terminal_buffer.bg),
            Cell.init(0x2591, 0x00FF00FF, terminal_buffer.bg),
            Cell.init(0x2591, 0x00FF0000, terminal_buffer.bg),
            Cell.init(0x2591, 0x000000FF, terminal_buffer.bg),
            Cell.init(0x2591, 0x00000000, terminal_buffer.bg),
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
            const normalized_x: f32 = @mod(@as(f32, @floatFromInt(y + (self.frames / self.delay))) * GLITCH_SCALE, 2 * math.pi);
            const s: usize = @intFromFloat((@sin(normalized_x) + 1) * 2);

            const cell_x = if (x >= s) x - s else x;

            const index: usize = @intFromFloat(@as(f32, @floatFromInt(x)) /
                @as(f32, @floatFromInt(self.terminal_buffer.width)) * @as(f32, @floatFromInt(PALETTE_LEN)));

            self.palette[index].put(cell_x, y);
        }
    }
}
