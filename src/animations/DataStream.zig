const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const Allocator = std.mem.Allocator;
const Random = std.Random;

// inspired by cyberpunk 2077 in-game screens

pub const SPACE_BETWEEN: usize = 2;

const DataStream = @This();

pub const Dot = struct {
    value: u32,
};

pub const Block = struct {
    direction: u1,
    delay: usize,
    count: usize,
    offset: usize,
    width: usize,
};

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
blocks: []Block,
dots: []Dot,
fg: u32,
bidirectional: bool,
blocks_num: u32,
blocks_width: usize,
min_delay: usize,
max_delay: usize,
display_binary: bool,
display_symbols: bool,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
    fg: u32,
    blocks_num: u32,
    bidirectional: bool,
    min_delay: usize,
    max_delay: usize,
    display_binary: bool,
    display_symbols: bool,
) !DataStream {
    const blocks = try allocator.alloc(Block, blocks_num);
    const blocks_width = (terminal_buffer.width - SPACE_BETWEEN * (blocks_num - 1));
    const dots = try allocator.alloc(Dot, blocks_width * terminal_buffer.height);
    initArrays(dots, blocks, bidirectional, min_delay, max_delay, blocks_width, terminal_buffer);

    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .blocks = blocks,
        .dots = dots,
        .fg = fg,
        .blocks_num = blocks_num,
        .blocks_width = blocks_width,
        .bidirectional = bidirectional,
        .min_delay = min_delay,
        .max_delay = max_delay,
        .display_binary = display_binary,
        .display_symbols = display_symbols,
    };
}

pub fn animation(self: *DataStream) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(self: *DataStream) void {
    self.allocator.free(self.dots);
    self.allocator.free(self.blocks);
}

fn realloc(self: *DataStream) anyerror!void {
    const blocks_width = (self.terminal_buffer.width - SPACE_BETWEEN * (self.blocks_num - 1));
    const dots = try self.allocator.realloc(self.dots, blocks_width * self.terminal_buffer.height);
    initArrays(dots, self.blocks, self.bidirectional, self.min_delay, self.max_delay, blocks_width, self.terminal_buffer);
    self.blocks_width = blocks_width;
}

fn draw(self: *DataStream) void {
    var x_offset: usize = 0;
    var dots_offset: usize = 0;

    for (self.blocks, 0..) |block, i| {
        self.blocks[i].count += 1;
        if (block.count > block.delay) {
            self.blocks[i].count = 0;
            if (block.direction == 1) {
                self.blocks[i].offset += 1;
                if (block.offset == self.terminal_buffer.height) {
                    self.blocks[i].offset = 1;
                }
            } else {
                if (block.offset > 0) self.blocks[i].offset -= 1;
                if (block.offset == 0) {
                    self.blocks[i].offset = self.terminal_buffer.height - 1;
                }
            }
        }

        for (0..self.terminal_buffer.height) |y| {
            for (0..block.width) |x| {
                const di = @mod(y + block.offset, self.terminal_buffer.height) * self.blocks_width +
                    x + dots_offset;
                var ch: u32 = '0';
                if (self.display_binary) {
                    ch = if (self.display_symbols) bin_symbol(self.dots[di]) else bin_value(self.dots[di]);
                } else {
                    ch = if (self.display_symbols) full_symbol(self.dots[di]) else full_value(self.dots[di]);
                }

                const cell = Cell{
                    .ch = ch,
                    .fg = self.fg,
                    .bg = self.terminal_buffer.bg,
                };
                cell.put(x + x_offset, y);
            }
        }

        x_offset += block.width + SPACE_BETWEEN;
        dots_offset += block.width;
    }
}

fn rollDirection(terminal_buffer: *TerminalBuffer, bidirectional: bool) u1 {
    if (bidirectional) return terminal_buffer.random.int(u1);
    return 0;
}

fn rollDelay(min_delay: usize, max_delay: usize, terminal_buffer: *TerminalBuffer) usize {
    var mind: usize = min_delay;
    const maxd: usize = max_delay;
    if (mind > maxd) mind = maxd;
    if (mind == maxd) return mind;
    return @mod(terminal_buffer.random.int(usize), maxd - mind) + mind;
}

fn initArrays(
    dots: []Dot,
    blocks: []Block,
    bidirectional: bool,
    min_delay: usize,
    max_delay: usize,
    blocks_width: usize,
    terminal_buffer: *TerminalBuffer,
) void {
    for (0..dots.len) |i| {
        dots[i] = Dot{
            .value = terminal_buffer.random.int(u4),
        };
    }

    const avg_width = blocks_width / blocks.len;
    for (0..blocks.len) |i| {
        var block_width = avg_width;
        if (i == blocks.len / 2) {
            block_width += @mod(blocks_width, blocks.len);
        }

        blocks[i] = Block{
            .direction = rollDirection(terminal_buffer, bidirectional),
            .delay = rollDelay(min_delay, max_delay, terminal_buffer),
            .offset = 0,
            .count = 0,
            .width = block_width,
        };
    }
}

fn bin_value(dot: Dot) u32 {
    const value = @mod(dot.value, 2);
    return value + 48;
}

fn full_value(dot: Dot) u32 {
    if (dot.value < 10) return dot.value + 48;
    return dot.value + 87;
}

fn bin_symbol(dot: Dot) u32 {
    const value = @mod(dot.value, 2);
    if (value == 0) return 0x2592;
    return 0x2588;
}

fn full_symbol(dot: Dot) u32 {
    const value = @mod(dot.value, 4);
    if (value == 3) return value + 0x2585;
    return value + 0x2591;
}
