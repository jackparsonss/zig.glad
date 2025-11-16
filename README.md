# Zig Glad

Zig imports for glad loader of OpenGL 4.6 core.

This repo does not implement bindings for glad but rather provides a way to import glad code through `zig fetch` rather than manually adding and linking files

### Usage
```
zig fetch --save git+https://github.com/jackparsonss/zig.glad.git
```

### Using the package
```
# build.zig
const glad_dependency = b.dependency("zig_glad", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.linkLibrary(glad_dependency.artifact("glad"));

# main.zig
const gl = @cImport({
    @cInclude("glad/glad.h");
});
```
