const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const math = std.math;

const Allocator = std.mem.Allocator;
const Random = std.Random;

pub const PALETTE_LEN = 5;

const Interference = @This();

frames: u32,
palette: [PALETTE_LEN]Cell,
allocator: Allocator,
terminal_buffer: *TerminalBuffer,
fg: u32,
time_scale: f32,
distance_scale: f32,
corner_variant: bool,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
    fg: u32,
    time_scale: f32,
    distance_scale: f32,
    corner_variant: bool,
) !Interference {
    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .fg = fg,
        .time_scale = time_scale,
        .distance_scale = distance_scale,
        .corner_variant = corner_variant,
        .frames = 0,
        .palette = [PALETTE_LEN]Cell{
            Cell.init(' ', fg, terminal_buffer.bg),
            Cell.init(' ', fg, terminal_buffer.bg),
            Cell.init('.', fg, terminal_buffer.bg),
            Cell.init('*', fg, terminal_buffer.bg),
            Cell.init('@', fg, terminal_buffer.bg),
        },
    };
}

pub fn animation(self: *Interference) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *Interference) void {}

fn realloc(_: *Interference) anyerror!void {}

fn draw(self: *Interference) void {
    self.frames +%= 1;
    const time: f32 = @as(f32, @floatFromInt(self.frames)) * self.time_scale;

    var center_x: i32 = @intCast(self.terminal_buffer.width / 4);
    var center_y: i32 = @intCast(self.terminal_buffer.height / 2);
    var center2_x: i32 = @intCast(self.terminal_buffer.width / 4 * 3);
    var center2_y: i32 = @intCast(self.terminal_buffer.height / 2);
    if (self.corner_variant) {
        center_x = 0;
        center_y = 0;
        center2_x = @intCast(self.terminal_buffer.width);
        center2_y = @intCast(self.terminal_buffer.height);
    }

    for (0..self.terminal_buffer.width) |x| {
        for (0..self.terminal_buffer.height) |y| {
            const wave1 = @sin(distance(self.distance_scale, center_x, center_y, @intCast(x), @intCast(y)) - time);
            const wave2 = @sin(distance(self.distance_scale, center2_x, center2_y, @intCast(x), @intCast(y)) - time);
            const sum = (wave1 + wave2) / 2;

            self.palette[waveToIndex(sum)].put(x, y);
        }
    }
}

fn distance(distance_scale: f32, x1: i32, y1: i32, x2: i32, y2: i32) f32 {
    const x: f32 = @floatFromInt(@abs(x1 - x2));
    const y: f32 = @floatFromInt(@abs(y1 - y2));
    return @sqrt(x * x + y * y) * distance_scale;
}

fn waveToIndex(sin: f32) u32 {
    return @intFromFloat(@round((PALETTE_LEN - 1) * ((sin + 1) / 2)));
}
