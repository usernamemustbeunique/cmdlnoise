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
            try stdout.print("0.0.4\n", .{});
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
    var use_text = false;
    var separator: []const u8 = ",";

    // Iterate over keyword arguments, if any
    while (args.next()) |arg| {
        var terms = std.mem.splitAny(u8, arg, ":=");
        const k = terms.next().?;
        const v = terms.next().?;
        if (terms.next()) |_| return error.SyntaxError;

        // Fastnoiselite config settings, comptime
        var valid = false;
        inline for (@typeInfo(fnl.Noise(f64)).Struct.fields) |field| {
            if (eql(u8, field.name, k)) {
                switch (@typeInfo(field.type)) {
                    .Enum => {
                        inline for (@typeInfo(field.type).Enum.fields) |inner| {
                            if (eql(u8, inner.name, v)) {
                                @field(noise, field.name) = @enumFromInt(inner.value);
                                valid = true;
                            }
                        }
                    },
                    .Int => {
                        @field(noise, field.name) = try std.fmt.parseInt(field.type, v, 0);
                        valid = true;
                    },
                    .Float => {
                        @field(noise, field.name) = try std.fmt.parseFloat(field.type, v);
                        valid = true;
                    },
                    else => {},
                }
            }
        }

        // cmdlnoise-specific options
        if (valid) {
            continue;
        } else if (eql(u8, k, "start_x")) {
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
        } else if (eql(u8, k, "use_text")) {
            use_text = true;
        } else if (eql(u8, k, "separator")) {
            if (eql(u8, v, "\\n")) {
                separator = "\n";
            } else if (eql(u8, v, "\\t")) {
                separator = "\t";
            } else {
                separator = v;
            }
        }

        //
        else {
            return error.InvalidArgument;
        }
    }

    for (0..size_x) |x| {
        for (0..size_y) |y| {
            for (0..size_z) |z| {
                const value = noise.genNoise3DRange(
                    start_x + @as(f64, @floatFromInt(x)),
                    start_y + @as(f64, @floatFromInt(y)),
                    start_z + @as(f64, @floatFromInt(z)),
                    f64,
                    min,
                    max,
                );
                if (use_text and use_f64) {
                    try stdout.print("{d}", .{value});
                } else if (use_text) {
                    try stdout.print("{d}", .{@as(f32, @floatCast(value))});
                } else if (use_f64) {
                    _ = try stdout.write(&@as([8]u8, @bitCast(value)));
                } else {
                    _ = try stdout.write(&@as([4]u8, @bitCast(@as(f32, @floatCast(value)))));
                }
                if (x < size_x - 1 or y < size_y - 1 or z < size_z - 1) {
                    _ = try stdout.write(separator);
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
        \\
        \\  start_x=[float] start_y=[float] start_z=[float] (default = 0)
        \\  size_x=[u64] size_y=[u64] size_z=[u64] (default = 1)
        \\  min=[float] max=[float] (default = -1.0, 1.0)
        \\  use_f64 (default = false, returns single instead of double precision floats)
        \\  use_text (default = false, returns raw bytes instead of ASCII digits)
        \\  separator (default = ",") 
        \\
        \\FNL configuration options:
        \\
        \\  seed=[i32] (default = 1337)
        \\  frequency=[float] (default = 0.1)
        \\  noise_type=[type] (default = simplex)
        \\
        \\See FastNoiseLite documentation for the full list of options.
        \\
        \\
    , .{}) catch return;
    bw.flush() catch return;
}
