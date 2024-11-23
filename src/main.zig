const std = @import("std");
const fnl = @import("fastnoise.zig");
const eql = std.mem.eql;

pub fn main() !void {
    var noise = fnl.Noise(f64){};
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    errdefer printHelp();

    // Check for version, help commands
    var args1 = try std.process.argsWithAllocator(alloc);
    _ = args1.next();
    while (args1.next()) |arg| {
        if (eql(u8, arg, "help")) {
            printHelp();
            return;
        } else if (eql(u8, arg, "version")) {
            try stdout.print("cmdlnoise version 0.0.2-dev\n", .{});
            try bw.flush();
            return;
        }
    }
    args1.deinit();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = args.next();

    // Default values
    var size_x: usize = 1;
    var size_y: usize = 1;
    var size_z: usize = 1;
    var start_x: f64 = 0;
    var start_y: f64 = 0;
    var start_z: f64 = 0;
    var min: f64 = -1.0;
    var max: f64 = 1.0;
    var use_f64 = false;

    // Iterate over keyword arguments, if any
    while (args.next()) |arg| {
        var terms = std.mem.splitAny(u8, arg, ":=");
        const k = terms.next().?;
        const v = terms.next().?;
        if (terms.next()) |_| return error.SyntaxError;

        // FastNoiseLite config settings
        if (eql(u8, k, "seed")) {
            noise.seed = try std.fmt.parseInt(i32, v, 0);
        } else if (eql(u8, k, "frequency")) {
            noise.frequency = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "noise_type")) {
            var valid = false;
            inline for (@typeInfo(fnl.NoiseType).Enum.fields) |field| {
                if (eql(u8, field.name, v)) {
                    noise.noise_type = @enumFromInt(field.value);
                    valid = true;
                }
            }
            if (!valid) return error.InvalidNoiseType;
        } else if (eql(u8, k, "rotation_type")) {
            var valid = false;
            inline for (@typeInfo(fnl.RotationType).Enum.fields) |field| {
                if (eql(u8, field.name, v)) {
                    noise.rotation_type = @enumFromInt(field.value);
                    valid = true;
                }
            }
            if (!valid) return error.InvalidRotationType;
        } else if (eql(u8, k, "fractal_type")) {
            var valid = false;
            inline for (@typeInfo(fnl.FractalType).Enum.fields) |field| {
                if (eql(u8, field.name, v)) {
                    noise.fractal_type = @enumFromInt(field.value);
                    valid = true;
                }
            }
            if (!valid) return error.InvalidFractalType;
        } else if (eql(u8, k, "octaves")) {
            noise.octaves = try std.fmt.parseInt(u32, v, 0);
        } else if (eql(u8, k, "lacunarity")) {
            noise.lacunarity = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "gain")) {
            noise.gain = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "weighted_strength")) {
            noise.weighted_strength = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "ping_pong_strength")) {
            noise.ping_pong_strength = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "cellular_distance")) {
            var valid = false;
            inline for (@typeInfo(fnl.CellularDistanceFunc).Enum.fields) |field| {
                if (eql(u8, field.name, v)) {
                    noise.cellular_distance = @enumFromInt(field.value);
                    valid = true;
                }
            }
            if (!valid) return error.InvalidCellularDistanceFunc;
        } else if (eql(u8, k, "cellular_return")) {
            var valid = false;
            inline for (@typeInfo(fnl.CellularReturnType).Enum.fields) |field| {
                if (eql(u8, field.name, v)) {
                    noise.cellular_return = @enumFromInt(field.value);
                    valid = true;
                }
            }
            if (!valid) return error.InvalidCellularReturnType;
        } else if (eql(u8, k, "cellular_jitter_mod")) {
            noise.cellular_jitter_mod = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "domain_warp_type")) {
            var valid = false;
            inline for (@typeInfo(fnl.DomainWarpType).Enum.fields) |field| {
                if (eql(u8, field.name, v)) {
                    noise.domain_warp_type = @enumFromInt(field.value);
                    valid = true;
                }
            }
            if (!valid) return error.InvalidDomainWarpType;
        } else if (eql(u8, k, "domain_warp_amp")) {
            noise.domain_warp_amp = try std.fmt.parseFloat(f64, v);
        }

        // cmdlnoise-specific options
        else if (eql(u8, k, "start_x")) {
            start_x = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "start_y")) {
            start_y = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "start_z")) {
            start_z = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "size_x")) {
            size_x = try std.fmt.parseInt(usize, v, 0);
        } else if (eql(u8, k, "size_y")) {
            size_y = try std.fmt.parseInt(usize, v, 0);
        } else if (eql(u8, k, "size_z")) {
            size_z = try std.fmt.parseInt(usize, v, 0);
        } else if (eql(u8, k, "min")) {
            min = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "max")) {
            max = try std.fmt.parseFloat(f64, v);
        } else if (eql(u8, k, "use_f64")) {
            use_f64 = true;
        }

        //
        else {
            return error.InvalidArgument;
        }
    }

    for (0..size_x) |x| {
        for (0..size_y) |y| {
            for (0..size_z) |z| {
                if (use_f64) {
                    _ = try stdout.write(&@as([8]u8, @bitCast(noise.genNoise3DRange(
                        start_x + @as(f64, @floatFromInt(x)),
                        start_y + @as(f64, @floatFromInt(y)),
                        start_z + @as(f64, @floatFromInt(z)),
                        f64,
                        min,
                        max,
                    ))));
                } else {
                    _ = try stdout.write(&@as([4]u8, @bitCast(noise.genNoise3DRange(
                        start_x + @as(f64, @floatFromInt(x)),
                        start_y + @as(f64, @floatFromInt(y)),
                        start_z + @as(f64, @floatFromInt(z)),
                        f32,
                        @floatCast(min),
                        @floatCast(max),
                    ))));
                }
            }
        }
    }
    try bw.flush();
}

fn printHelp() void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    stdout.print(
        \\cmdlnoise - fastnoiselite on the command line
        \\
        \\version - print version info
        \\help - print this message
        \\
        \\usage: cmdlnoise [width] [height] <args>
        \\prints width*height noise values to stdout
        \\
        \\cmdlnoise optional arguments:
        \\start_x=[float] start_y=[float] start_z=[float] (default = 0)
        \\size_x=[u64] size_y=[u64] size_z=[u64] (default = 1)
        \\min=[float] max=[float] (default = -1.0, 1.0)
        \\use_f64 (default = false, returns f32s)
        \\
        \\FNL configuration options:
        \\seed=[i32] (default = 1337)
        \\frequency=[float] (default = 0.1)
        \\noise_type=[type] (default = simplex)
        \\
        \\See FastNoiseLite documentation for the full list of options.
        \\
        \\
    , .{}) catch return;
    bw.flush() catch return;
}
