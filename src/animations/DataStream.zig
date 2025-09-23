const std = @import("std");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const Allocator = std.mem.Allocator;
const Random = std.Random;

// inspired by cyberpunk 2077 in-game screens

pub const BIDIRECTIONAL = false;
pub const FG_COLOR = 0x0000FFFF;
pub const DELAY_MIN: usize = 8;
pub const DELAY_MAX: usize = 12;
pub const BLOCKS_NUM: usize = 9;
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

pub fn init(allocator: Allocator, terminal_buffer: *TerminalBuffer) !DataStream {
    const blocks = try allocator.alloc(Block, BLOCKS_NUM);
    const blocks_width = (terminal_buffer.width - SPACE_BETWEEN * (BLOCKS_NUM - 1));
    const avg_width = blocks_width / BLOCKS_NUM;
    for (0..blocks.len) |i| {
        var block_width = avg_width;
        if (i == blocks.len / 2) {
            block_width += @mod(blocks_width, BLOCKS_NUM);
        }
        blocks[i] = try newBlock(
            allocator,
            terminal_buffer,
            block_width,
        );
    }

    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .blocks = blocks,
    };
}

fn newBlock(allocator: Allocator, terminal_buffer: *TerminalBuffer, width: usize) !Block {
    var direction: u1 = 1;
    if (BIDIRECTIONAL) {
        direction = terminal_buffer.random.int(u1);
    }
    const block = Block{
        .lines = try allocator.alloc(Line, terminal_buffer.height),
        .direction = direction,
        .delay = @mod(terminal_buffer.random.int(u16), DELAY_MAX - DELAY_MIN) + DELAY_MIN,
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
    // const blocks = try self.allocator.realloc(self.blocks, BLOCKS_NUM);
    // for (self.blocks, 0..) |block, i| {
    //     self.blocks[i].lines = try self.allocator.realloc(block.lines, )
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
                    .fg = FG_COLOR,
                    .bg = self.terminal_buffer.bg,
                };

                cell.put(x + x_offset, @mod(y + block.offset, self.terminal_buffer.height));
            }
        }

        x_offset += block.lines[0].dots.len + SPACE_BETWEEN;
    }
}
