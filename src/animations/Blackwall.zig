const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const math = std.math;

const Allocator = std.mem.Allocator;
const Random = std.Random;

// WIP

pub const DELAY = 16;

const Blackwall = @This();

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
frames: u64,
offset: u64,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
) !Blackwall {
    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .frames = 0,
        .offset = 0,
    };
}

pub fn animation(self: *Blackwall) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *Blackwall) void {}

fn realloc(_: *Blackwall) anyerror!void {}

fn draw(self: *Blackwall) void {
    self.frames +%= 1;
    if (self.frames % DELAY == 0) {
        self.offset += 1;
    }

    for (0..self.terminal_buffer.width) |x| {
        if (self.offset % 3 == x % 3) {
            for (0..self.terminal_buffer.height) |y| {
                const cell = Cell{
                    .ch = 0x2591,
                    .fg = 0x00FF, //subColor(0x00FF0000, 255 / DELAY),
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x, y);
            }
        } else if ((self.offset + 1) % 3 == x % 3) {
            for (0..self.terminal_buffer.height) |y| {
                const cell = Cell{
                    .ch = '|',
                    .fg = 0x00FF0000,
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x, y);
            }
        }
    }
}

fn subColor(color: u32, sub: u32) u32 {
    const r = (color & 0x00FF0000) >> 8;
    const g = (color & 0x0000FF) >> 16;
    const b = (color & 0x000000FF) >> 24;
    std.log.debug("{d} {d} {d}", .{ r, g, b });
    _ = sub;
    unreachable;
    // return ((r - sub) << 16) | ((g - sub) << 8) | (b - sub);
}
