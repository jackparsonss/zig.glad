const std = @import("std");
const toolbox_pkg = @import("toolbox");
const Toolbox = toolbox_pkg.Toolbox;

fn update(toolbox: *Toolbox) !void {
    const glad_path = try toolbox.buildRootJoin(&.{
        "glad",
    });

    std.fs.deleteTreeAbsolute(glad_path) catch |err| {
        switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
    };

    try toolbox.clone(.glad, glad_path);

    var glad_dir = try std.fs.openDirAbsolute(glad_path, .{
        .iterate = true,
    });
    defer glad_dir.close();

    var it = glad_dir.iterate();
    while (try it.next()) |*entry| {
        if (!std.mem.eql(u8, entry.name, "src") and !std.mem.eql(u8, entry.name, "include")) {
            try std.fs.deleteTreeAbsolute(toolbox.pathJoin(&.{
                glad_path, entry.name,
            }));
        }
    }

    try toolbox.clean(&.{
        "glad",
    }, &.{
        ".m",
    });
}

const FromZon = toolbox_pkg.Repositories(.{.toolbox});

const DuringExec = toolbox_pkg.Repositories(.{
    .glad,
});

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var toolbox = try Toolbox.init(FromZon, DuringExec, b, optimize, .glad_zig, "0x382b3ea69eabe8e8", &.{
        "glad",
    }, .{
        .toolbox = .{
            .name = "tiawl/toolbox",
            .host = .github,
            .ref = .tag,
        },
    }, .{
        .glad = .{
            .name = "glad/glad",
            .host = .github,
            .ref = .tag,
        },
    });
    defer toolbox.deinit();

    if (toolbox.getUpdate()) try update(&toolbox);

    const lib = b.addLibrary(.{
        .name = "glad",
        .root_module = std.Build.Module.create(b, .{
            .root_source_file = b.addWriteFiles().add("empty.zig", ""),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    var root_dir = try b.build_root.handle.openDir(".", .{
        .iterate = true,
    });
    defer root_dir.close();

    var walk = try root_dir.walk(b.allocator);
    while (try walk.next()) |*entry| {
        if (std.mem.startsWith(u8, entry.path, "glad") and entry.kind == .directory) {
            toolbox.addInclude(lib, entry.path);
        }
    }

    toolbox.addHeader(lib, try b.build_root.join(b.allocator, &.{
        "glad", "include", "KHR",
    }), "KHR", &.{
        ".h",
    });

    toolbox.addHeader(lib, try b.build_root.join(b.allocator, &.{
        "glad", "include", "glad",
    }), "glad", &.{
        ".h",
    });

    const src_path = try b.build_root.join(b.allocator, &.{
        "glad", "src",
    });

    var src_dir = try std.fs.openDirAbsolute(src_path, .{
        .iterate = true,
    });
    defer src_dir.close();

    const flags = [_][]const u8{"-Isrc"};
    var it = src_dir.iterate();
    while (try it.next()) |*entry| {
        try toolbox.addSource(lib, src_path, entry.name, &flags);
    }

    b.installArtifact(lib);
}
