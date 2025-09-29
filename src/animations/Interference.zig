const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const math = std.math;

const Allocator = std.mem.Allocator;
const Random = std.Random;

pub const PALETTE_LEN = 4;
pub const DELAY = 4;
pub const FG = 0x00FFFFFF;
pub const DISTANCE_SCALE = 1.5;

// WIP

const Interference = @This();

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
count: u64,
offset: u64,
palette: [PALETTE_LEN]Cell,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
) !Interference {
    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .count = 0,
        .offset = 0,
        .palette = [PALETTE_LEN]Cell{
            Cell.init(0x2588, FG, terminal_buffer.bg),
            Cell.init(0x2592, FG, terminal_buffer.bg),
            Cell.init(0x2591, FG, terminal_buffer.bg),
            Cell.init(0x20, FG, terminal_buffer.bg),
        },
    };
}

pub fn animation(self: *Interference) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *Interference) void {}

fn realloc(_: *Interference) anyerror!void {}

fn draw(self: *Interference) void {
    self.count += 1;
    if (self.count >= DELAY) {
        self.offset +%= 1;
        self.count = 0;
    }

    const center_x: i32 = 0;
    const center_y: i32 = 0;
    const center2_x: i32 = @intCast(self.terminal_buffer.width);
    const center2_y: i32 = @intCast(self.terminal_buffer.height);

    for (0..self.terminal_buffer.width) |x| {
        for (0..self.terminal_buffer.height) |y| {
            const sin1 = @sin(distance(center_x, center_y, @intCast(x), @intCast(y)) - @as(f32, @floatFromInt(self.offset)));
            const sin2 = @sin(distance(center2_x, center2_y, @intCast(x), @intCast(y)) - @as(f32, @floatFromInt(self.offset)));
            const sum = (sin1 + sin2) / 2;

            self.palette[sinToIndex(sum)].put(x, y);
        }
    }
}

fn distance(x1: i32, y1: i32, x2: i32, y2: i32) f32 {
    const x: f32 = @floatFromInt(@abs(x1 - x2));
    const y: f32 = @floatFromInt(@abs(y1 - y2));
    return @sqrt(x * x + y * y) * DISTANCE_SCALE;
}

fn sinToIndex(sin: f32) u32 {
    return @intFromFloat(@round((PALETTE_LEN - 1) * ((sin + 1) / 2)));
}

fn sinToColor(sin: f32) u32 {
    const shade: u32 = @intFromFloat(255 * ((sin + 1) / 2));
    return shade << 16 | shade << 8 | shade;
}
