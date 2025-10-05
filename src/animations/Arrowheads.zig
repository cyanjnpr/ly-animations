const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const Random = std.Random;
const Allocator = std.mem.Allocator;

pub const PALETTE_LEN = 9;

// there's nothing here that resembles arrowheads
// inspired by visualizations from have a nice life concert

const Arrowheads = @This();

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
box_length: usize,
box_height: usize,
delay: usize,
count: usize,
offset: i32,
line_gap_period: usize,
char_gpa_period: usize,
expand_size: i32,
palette: [PALETTE_LEN]Cell,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
    box_length: usize,
    box_height: usize,
    col1: u32,
    col2: u32,
    col3: u32,
    delay: usize,
    expand_size: usize,
) !Arrowheads {
    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .box_length = box_length,
        .box_height = box_height,
        .delay = delay,
        .count = 0,
        .offset = 0,
        .line_gap_period = 2,
        .char_gpa_period = 2,
        .expand_size = @intCast(expand_size),
        .palette = [PALETTE_LEN]Cell{
            Cell.init('.', col1, terminal_buffer.bg),
            Cell.init(',', col1, terminal_buffer.bg),
            Cell.init('*', col1, terminal_buffer.bg),
            Cell.init('#', col2, terminal_buffer.bg),
            Cell.init('@', col2, terminal_buffer.bg),
            Cell.init('#', col2, terminal_buffer.bg),
            Cell.init('*', col3, terminal_buffer.bg),
            Cell.init(',', col3, terminal_buffer.bg),
            Cell.init('.', col3, terminal_buffer.bg),
        },
    };
}

pub fn animation(self: *Arrowheads) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *Arrowheads) void {}

fn realloc(_: *Arrowheads) anyerror!void {}

fn draw(self: *Arrowheads) void {
    const width = self.terminal_buffer.width;
    const height = self.terminal_buffer.height;

    const x_start: i32 = @intCast((width - self.box_length) / 2);
    const y_start: i32 = @intCast((height - self.box_height) / 2);

    self.count += 1;
    if (self.count >= self.delay) {
        self.offset += 1;
        self.count = 0;
    }
    const ratio = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    var x_offset = @as(i32, @intFromFloat(@as(f32, @floatFromInt(self.offset)) * ratio));
    if (x_start + self.expand_size - x_offset < 0 and y_start + self.expand_size - self.offset < 0) {
        self.line_gap_period = @as(usize, @intCast(self.terminal_buffer.random.int(u4))) + 2;
        self.char_gpa_period = @as(usize, @intCast(self.terminal_buffer.random.int(u4))) + 2;
        self.offset = 0;
        x_offset = 0;
    }

    for (0..width) |x_u| {
        const x: i32 = @intCast(x_u);
        for (0..height) |y_u| {
            const y: i32 = @intCast(y_u);
            const left: i32 = x - x_start + x_offset;
            const right: i32 = x - x_start - x_offset - @as(i32, @intCast(self.box_length));
            const top: i32 = y - y_start + self.offset;
            const bottom: i32 = y - y_start - self.offset - @as(i32, @intCast(self.box_height));
            const distance: u32 = @min(@abs(left), @abs(right), @abs(top), @abs(bottom));

            if (((left >= 0 and left <= @min(self.expand_size, x_offset) or right <= 0 and right >= -@min(self.expand_size, x_offset)) and
                (top >= 0 and bottom <= 0)) or
                ((top >= 0 and top <= @min(self.expand_size, self.offset) or bottom <= 0 and bottom >= -@min(self.expand_size, self.offset)) and
                    (left >= 0 and right <= 0)))
            {
                if (@mod(@as(usize, @intCast(distance)), self.line_gap_period) == self.line_gap_period - 1) continue;
                if (@mod(x_u + y_u * y_u, self.char_gpa_period) == self.char_gpa_period - 1) continue;

                self.palette[
                    @as(usize, @intFromFloat(@round(@as(f32, @floatFromInt(PALETTE_LEN - 1)) *
                        (@as(f32, @floatFromInt(distance)) / @as(f32, @floatFromInt(self.expand_size))))))
                ].put(x_u, y_u);
            }
        }
    }
}
