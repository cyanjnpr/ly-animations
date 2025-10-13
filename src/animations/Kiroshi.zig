const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const Allocator = std.mem.Allocator;
const Random = std.Random;

// WIP
// WIP
// WIP
// inspired by cyberpunk 2077 kiroshi scan pattern

pub const FLICKER_LENGTH = 3;
pub const MAX_SPACING_MULTIPLIER = 2;
pub const BACKGROUND_SPACING = 4;

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
        .density = 12,
        .delay = 7,
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
        const space_between = rand.int(u32) % MAX_SPACING_MULTIPLIER;

        for (0..self.terminal_buffer.height) |y| {
            if (self.density == 0 or x % (100 / self.density) == (50 / self.density) and
                (bold_rand + y + self.frames) % (FLICKER_LENGTH * (2 + space_between)) < FLICKER_LENGTH)
            {
                const cell = Cell{
                    .ch = 0x2588,
                    .fg = 0x0000FF00,
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x, y);
            } else if (x % BACKGROUND_SPACING == 0 and y % BACKGROUND_SPACING == 0) {
                const cell = Cell{
                    .ch = '.',
                    .fg = 0x0000FF00,
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x, y);
            }
        }
    }
}
