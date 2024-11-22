const std = @import("std");
const fnl = @import("c.zig").fnl;
const eql = std.mem.eql;

// TODO: Support all FNL config options
// TODO: Use doubles internally, return f32s by default, optionally return f64s

pub fn main() !void {
    var noise: fnl.fnl_state = fnl.fnlCreateState();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    errdefer printHelp();

    var args = try std.process.argsWithAllocator(alloc);

    // Extract positional arguments
    _ = args.next();
    const width = try std.fmt.parseInt(usize, args.next().?, 0);
    const height = try std.fmt.parseInt(usize, args.next().?, 0);

    var startx: f32 = 0;
    var starty: f32 = 0;
    var increment: f32 = 1.0;

    // Iterate over keyword arguments, if any
    while (args.next()) |arg| {
        var terms = std.mem.splitAny(u8, arg, ":=");
        const k = terms.next().?;
        const v = terms.next().?;
        if (terms.next()) |_| return error.SyntaxError;

        if (eql(u8, k, "seed")) {
            noise.seed = try std.fmt.parseInt(c_int, v, 0);
        } else if (eql(u8, k, "frequency")) {
            noise.frequency = try std.fmt.parseFloat(f32, v);
        } else if (eql(u8, k, "type")) {
            if (eql(u8, v, "OPENSIMPLEX2")) {
                noise.noise_type = fnl.FNL_NOISE_OPENSIMPLEX2;
            } else if (eql(u8, v, "OPENSIMPLEX2S")) {
                noise.noise_type = fnl.FNL_NOISE_OPENSIMPLEX2S;
            } else if (eql(u8, v, "CELLULAR")) {
                noise.noise_type = fnl.FNL_NOISE_CELLULAR;
            } else if (eql(u8, v, "PERLIN")) {
                noise.noise_type = fnl.FNL_NOISE_PERLIN;
            } else if (eql(u8, v, "VALUE_CUBIC")) {
                noise.noise_type = fnl.FNL_NOISE_VALUE_CUBIC;
            } else if (eql(u8, v, "VALUE")) {
                noise.noise_type = fnl.FNL_NOISE_VALUE;
            } else {
                return error.InvalidNoiseType;
            }
        } else if (eql(u8, k, "startx")) {
            startx = try std.fmt.parseFloat(f32, v);
        } else if (eql(u8, k, "starty")) {
            starty = try std.fmt.parseFloat(f32, v);
        } else if (eql(u8, k, "increment")) {
            increment = try std.fmt.parseFloat(f32, v);
        } else {
            return error.InvalidArgument;
        }
    }

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    for (0..width) |x| {
        for (0..height) |y| {
            _ = try stdout.write(&@as([4]u8, @bitCast(fnl.fnlGetNoise2D(
                &noise,
                startx + @as(f32, @floatFromInt(x)) * increment,
                starty + @as(f32, @floatFromInt(y)) * increment,
            ))));
        }
    }
    try bw.flush();
}

fn printHelp() void {
    std.debug.print(
        \\cmdlnoise - fastnoiselite on the command line
        \\usage: cmdlnoise [width] [height] <args>
        \\prints width*height noise values to stdout
        \\Optional arguments:
        \\startx=[float] starty=[float] (default = 0)
        \\increment=[float] (default = 1)
        \\seed=[int] (default = 1337)
        \\frequency=[float] (default = 0.1)
        \\type=[noise type] (default = OPENSIMPLEX2)
        \\Valid noise types: 
        \\  OPENSIMPLEX2
        \\  OPENSIMPLEX2S
        \\  CELLULAR
        \\  PERLIN
        \\  VALUE_CUBIC
        \\  VALUE
        \\Other config values not yet implemented
        \\
    , .{});
}
