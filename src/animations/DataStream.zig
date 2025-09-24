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

pub const Line = struct {
    dots: []Dot,
};

pub const Block = struct {
    lines: []Line,
    direction: u1,
    delay: usize,
    count: usize,
    offset: usize,
};

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
blocks: []Block,
fg: u32,
bidirectional: bool,
blocks_num: u32,
min_delay: usize,
max_delay: usize,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
    fg: u32,
    blocks_num: u32,
    bidirectional: bool,
    min_delay: usize,
    max_delay: usize,
) !DataStream {
    const blocks = try allocator.alloc(Block, blocks_num);
    const blocks_width = (terminal_buffer.width - SPACE_BETWEEN * (blocks_num - 1));
    const avg_width = blocks_width / blocks_num;
    for (0..blocks.len) |i| {
        var block_width = avg_width;
        if (i == blocks.len / 2) {
            block_width += @mod(blocks_width, blocks_num);
        }
        blocks[i] = try newBlock(
            allocator,
            terminal_buffer,
            bidirectional,
            min_delay,
            max_delay,
            block_width,
        );
    }

    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .blocks = blocks,
        .fg = fg,
        .blocks_num = blocks_num,
        .bidirectional = bidirectional,
        .min_delay = min_delay,
        .max_delay = max_delay,
    };
}

fn newBlock(allocator: Allocator, terminal_buffer: *TerminalBuffer, bidirectional: bool, min_delay: usize, max_delay: usize, width: usize) !Block {
    var direction: u1 = 1;
    if (bidirectional) {
        direction = terminal_buffer.random.int(u1);
    }
    const block = Block{
        .lines = try allocator.alloc(Line, terminal_buffer.height),
        .direction = direction,
        .delay = @mod(terminal_buffer.random.int(u16), max_delay - min_delay) + min_delay,
        .offset = 0,
        .count = 0,
    };
    for (block.lines, 0..) |_, i| {
        block.lines[i].dots = try allocator.alloc(Dot, width);
    }
    initBlock(block, terminal_buffer);
    return block;
}

fn initBlock(block: Block, terminal_buffer: *TerminalBuffer) void {
    for (block.lines) |line| {
        for (0..line.dots.len) |i| {
            line.dots[i] = Dot{ .value = (terminal_buffer.random.int(u4)) };
        }
    }
}

fn hex_value(dot: Dot) u32 {
    if (dot.value < 10) return dot.value + 48;
    return dot.value + 87;
}

pub fn animation(self: *DataStream) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(self: *DataStream) void {
    for (self.blocks) |block| {
        for (block.lines) |line| {
            self.allocator.free(line.dots);
        }
        self.allocator.free(block.lines);
    }
    self.allocator.free(self.blocks);
}

fn realloc(_: *DataStream) anyerror!void {
    // for (self.blocks, 0..) |block, i| {
    //     if (self.terminal_buffer.height < block.lines.len) {
    //         for (block.lines, self.terminal_buffer.height..) |line, j| {
    //             _ = j;
    //             self.allocator.free(line.dots);
    //         }
    //     }
    // }
}

fn draw(self: *DataStream) void {
    var x_offset: usize = 0;
    for (self.blocks, 0..) |block, i| {
        self.blocks[i].count += 1;
        if (block.count > block.delay) {
            self.blocks[i].count = 0;
            if (block.direction == 1) {
                self.blocks[i].offset += 1;
                if (block.offset == block.lines.len) {
                    self.blocks[i].offset = 1;
                }
            } else {
                if (block.offset > 0) self.blocks[i].offset -= 1;
                if (block.offset == 0) {
                    self.blocks[i].offset = block.lines.len - 1;
                }
            }
        }

        for (block.lines, 0..) |line, y| {
            for (line.dots, 0..) |dot, x| {
                const cell = Cell{
                    .ch = hex_value(dot),
                    .fg = self.fg,
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x + x_offset, @mod(y + block.offset, self.terminal_buffer.height));
            }
        }

        x_offset += block.lines[0].dots.len + SPACE_BETWEEN;
    }
}
