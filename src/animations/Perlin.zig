const std = @import("std");
const znoise = @import("znoise");
const Animation = @import("../tui/Animation.zig");
const Cell = @import("../tui/Cell.zig");
const TerminalBuffer = @import("../tui/TerminalBuffer.zig");

const Allocator = std.mem.Allocator;

const Perlin = @This();

allocator: Allocator,
terminal_buffer: *TerminalBuffer,
frames: u16,
fg: u32,
time_scale: f32,
distance_scale: f32,
direction_diagonal: bool,
gen: znoise.FnlGenerator,

pub fn init(
    allocator: Allocator,
    terminal_buffer: *TerminalBuffer,
    fg: u32,
    time_scale: f32,
    distance_scale: f32,
    direction_diagonal: bool,
) !Perlin {
    return .{
        .allocator = allocator,
        .terminal_buffer = terminal_buffer,
        .frames = 0,
        .fg = fg,
        .time_scale = time_scale,
        .distance_scale = distance_scale,
        .direction_diagonal = direction_diagonal,
        .gen = znoise.FnlGenerator{
            .noise_type = .perlin,
            .seed = terminal_buffer.random.int(i32),
        },
    };
}

pub fn animation(self: *Perlin) Animation {
    return Animation.init(self, deinit, realloc, draw);
}

fn deinit(_: *Perlin) void {}

fn realloc(_: *Perlin) anyerror!void {}

fn draw(self: *Perlin) void {
    self.frames +%= 1;

    const width = self.terminal_buffer.width;
    const height = self.terminal_buffer.height;

    for (0..width) |x_u| {
        var x: f32 = @as(f32, @floatFromInt(x_u)) * self.distance_scale;
        if (self.direction_diagonal) {
            x = @as(f32, @floatFromInt(x_u)) * self.distance_scale + @as(f32, @floatFromInt(self.frames)) * self.time_scale;
        }
        for (0..height) |y_u| {
            const y: f32 = @as(f32, @floatFromInt(y_u)) * self.distance_scale + @as(f32, @floatFromInt(self.frames)) * self.time_scale;

            const cell = Cell{
                .ch = '*',
                .fg = self.fg,
                .bg = self.terminal_buffer.bg,
            };

            if ((x_u + y_u) % (1 + @as(usize, @intFromFloat(@abs(10 * self.gen.noise2(x, y))))) == 0) cell.put(x_u, y_u);
        }
    }
}
