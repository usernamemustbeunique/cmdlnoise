Command line wrapper for the Zig implementation of [FastNoiseLite](https://github.com/Auburn/FastNoiseLite/)

Currently tested and working with Zig 0.13.0 and bundles Zig FastNoiseLite 1.1.1

## Usage:

cmdlnoise <args>

For example:

```
$ cmdlnoise size_x=100 size_y=100 seed=12345 fractal_type=fbm
```

will print 100 * 100 noise values as raw f32 bytes to stdout, providing a completely language agnostic interface.

Optional arguments:

- start_x=[float] start_y=[float] start_z=[float] (default = 0)
- size_x=[u64] size_y=[u64] size_z=[u64] (default = 1)
- min=[float] max=[float] (default = -1.0, 1.0)
- use_f64 (default = false). When enabled, cmdlnoise will return f64s as bytes instead of f32s.
- use_text (default = false). When enabled, cmdlnoise will print the values as ASCII formatted digits.
- separator=[string] (default = ","). Supports user defined value separators when printing ASCII. Includes \n and \t for newlines and tabs.

Implements *most* of the FastNoiseLite api, except domain warp (as we do not store multiple noise states). Internally samples 3D noise with double precision, but only returns samples in requested dimensions (with size_x/y/z=*). This means that cmdlnoise will generate samples somewhat slower, but allows for runtime flexibility.

## Building

Uses standard zig build with no external dependencies (except the bundled fastnoiselite.zig). Has no external dependencies and should support any platform Zig supports.

Compile with ```zig build -Doptimize=ReleaseFast``` or ```-Doptimize=ReleaseSmall``` for best performance/smallest binaries. ReleaseSmall binaries are <100KB.
