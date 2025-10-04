const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const Allocator = std.mem.Allocator;
const Random = std.Random;

// WIP
// inspired by cyberpunk 2077 kiroshi scan pattern

pub const FLICKER_LENGTH = 3;

const Kiroshi = @This();

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
frames: u64,
density: usize,
delay: usize,
count: usize,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
) !Kiroshi {
    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .frames = 0,
        .density = 10,
        .delay = 5,
        .count = 0,
    };
}

pub fn animation(self: *Kiroshi) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *Kiroshi) void {}

fn realloc(_: *Kiroshi) anyerror!void {}

fn draw(self: *Kiroshi) void {
    self.count += 1;
    if (self.count >= self.delay) {
        self.frames +%= 1;
        self.count = 0;
    }

    for (0..self.terminal_buffer.width) |x| {
        var prng = Random.DefaultPrng.init(x);
        const rand = prng.random();
        const bold_rand = rand.int(u32);
        const slim_rand = rand.int(u32);
        const slim_offset = rand.int(u32) % (100 / self.density);

        for (0..self.terminal_buffer.height) |y| {
            if (self.density == 0 or x % (100 / self.density) == 0 and
                (bold_rand + y + self.frames) % (FLICKER_LENGTH * 3) < FLICKER_LENGTH)
            {
                const cell = Cell{
                    .ch = 0x2591,
                    .fg = 0x0000FF00,
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x, y);
            }

            if (self.density == 0 or x % (100 / self.density) == slim_offset and
                (slim_rand + y + self.frames) % (FLICKER_LENGTH * 3) < FLICKER_LENGTH)
            {
                const cell = Cell{
                    .ch = '|', //0x2591,
                    .fg = 0x0000FF00,
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x, y);
            }
        }
    }
}
