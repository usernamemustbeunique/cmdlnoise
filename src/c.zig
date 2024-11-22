pub const fnl = @cImport({
    @setRuntimeSafety(false);
    @cDefine("FNL_IMPL", {});
    @cInclude("FastNoiseLite.h");
});
