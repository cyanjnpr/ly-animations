const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const Allocator = std.mem.Allocator;
const math = std.math;

pub const WAVE_WIDTH = 15;
pub const SCALE = 0.1;

const Waveforms = @This();

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
frames: u16,
direction_pos: bool,
current_waveform: u2,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
) !Waveforms {
    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .frames = 0,
        .direction_pos = true,
        .current_waveform = 0,
    };
}

pub fn animation(self: *Waveforms) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *Waveforms) void {}

fn realloc(_: *Waveforms) anyerror!void {}

fn draw(self: *Waveforms) void {
    self.frames +%= 1;

    const width = self.terminal_buffer.width;
    const height = self.terminal_buffer.height;

    for (0..width) |x| {
        for (0..height) |y| {
            const cell = Cell{
                .ch = '*',
                .fg = self.terminal_buffer.fg,
                .bg = self.terminal_buffer.bg,
            };

            if ((y / WAVE_WIDTH) % 2 == 0) {
                const sign = @as(f32, @floatFromInt(@intFromBool(self.direction_pos))) * 2 - 1;
                const cell_y = @as(i32, @intCast(y)) +
                    @as(i32, @intFromFloat(sign * waveform(self, x) *
                        0.01 * (@as(f32, @floatFromInt(self.frames % 500))) *
                        0.01 * (@as(f32, @floatFromInt(500 - self.frames % 500)))));
                if (cell_y > 0 and cell_y < height) {
                    cell.put(x, @as(u32, @intCast(cell_y)));
                }
            }
        }
    }
    if (self.frames % 500 == 0) {
        self.direction_pos = !self.direction_pos;
        if (self.direction_pos) {
            self.current_waveform +%= 1;
            if (self.current_waveform == 3) self.current_waveform +%= 1;
        }
    }
}

fn waveform(self: *Waveforms, x: usize) f32 {
    switch (self.current_waveform) {
        0 => return sine(x),
        1 => return triangle(x),
        2 => return square(x),
        else => return 0,
    }
}

fn sine(x: usize) f32 {
    return @sin(@as(f32, @floatFromInt(x)) * SCALE);
}

fn triangle(x: usize) f32 {
    var normalized_x: f32 = @mod(@as(f32, @floatFromInt(x)) * SCALE, 2 * math.pi);
    if (normalized_x > math.pi) normalized_x = 2 * math.pi - normalized_x;
    normalized_x /= math.pi;
    normalized_x -= 1;
    return normalized_x;
}

fn square(x: usize) f32 {
    const normalized_x: f32 = @mod(@as(f32, @floatFromInt(x)) * SCALE, 2 * math.pi);
    if (normalized_x < math.pi) {
        return 1;
    } else if (normalized_x > math.pi) {
        return -1;
    }
    return 0;
}
