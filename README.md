Command line wrapper for [FastNoiseLite](https://github.com/Auburn/FastNoiseLite/)

For when you want some noise dumped as unformatted bytes to stdout

## Usage:

cmdlnoise [width] [height] <args>

For example:

```
$ cmdlnoise 100 100 seed=12345
```

will print 100 * 100 noise values as raw f32 bytes to stdout, providing a completely language agnostic interface.

Optional arguments:

- startx=[float] starty=[float] (default = 0)
- increment=[float] (default = 1)
- seed=[int] (default = 1337)
- frequency=[float] (default = 0.1)
- type=[noise type] (default = OPENSIMPLEX2)

Other config values not yet implemented

## Building

```zig build -Doptimize=ReleaseFast``` or ```-Doptimize=ReleaseSmall```. The underlying FastNoiseLite C99 header cannot be compiled with Zig's safety checks on.
