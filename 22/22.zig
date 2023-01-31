const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

fn readInt(reader: anytype, buf: []u8, delimiter: u8) !i64 {
    const maybe_int = try reader.readUntilDelimiterOrEof(buf, delimiter);
    if (maybe_int == null) return error.EOF;

    return try std.fmt.parseInt(i64, maybe_int.?, 0);
}

const Point3d = struct {
    const Self = @This();
    const Edge = DataEdge(void, {});

    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,

    fn rotate(self: *Self, around: Edge) void {
        var origin = self.*;

        if (around.from.x != around.to.x) {
            assert(around.from.y == around.to.y);

            origin.y -= around.from.y;
            origin.z -= around.from.z;

            self.y = -origin.z;
            self.z = origin.y;

            self.y += around.from.y;
            self.z += around.from.z;
        }
        if (around.from.y != around.to.y) {
            assert(around.from.x == around.to.x);

            origin.x -= around.from.x;
            origin.z -= around.from.z;

            self.x = origin.z;
            self.z = -origin.x;

            self.x += around.from.x;
            self.z += around.from.z;
        }
        if (around.from.z != around.to.z) {
            assert(around.from.x == around.to.x);

            origin.x -= around.from.x;
            origin.y -= around.from.y;

            self.x = -origin.y;
            self.y = origin.x;

            self.x += around.from.x;
            self.y += around.from.y;
        }
    }

    fn isEqual(self: Self, p: Point3d) bool {
        return self.x == p.x and self.y == p.y and self.z == p.z;
    }
};

fn DataEdge(comptime DataType: type, comptime default_data: DataType) type {
    return struct {
        const Self = @This();
        const Edge = DataEdge(void, {});

        from: Point3d,
        to: Point3d,
        data: DataType = default_data,
        stacked_edge: ?*DataEdge(DataType, default_data) = null,

        fn rotate(self: *Self, around: DataEdge(DataType, default_data)) void {
            const n: u4 = if (around.from.x < around.to.x or around.from.y < around.to.y or around.from.z < around.to.z) 1 else 3;
            var i: u4 = 0;
            while (i < n) : (i += 1) {
                self.from.rotate(around.toEdge());
                self.to.rotate(around.toEdge());
            }
        }

        fn isStacked(self: Self, edge: DataEdge(DataType, default_data)) bool {
            return self.from.isEqual(edge.to) and self.to.isEqual(edge.from);
        }

        fn isEqual(self: Self, edge: DataEdge(DataType, default_data)) bool {
            return self.from.isEqual(edge.from) and self.to.isEqual(edge.to);
        }

        fn copy(self: Self) DataEdge(DataType, default_data) {
            return DataEdge(DataType, default_data){ .from = self.from, .to = self.to, .data = self.data };
        }

        fn toEdge(self: Self) Edge {
            return Edge{ .from = self.from, .to = self.to };
        }
    };
}

test "rotate edges 1" {
    const Edge = DataEdge(void, {});

    const around = Edge{ .from = Point3d{ .x = 100, .y = 150 }, .to = Point3d{ .x = 100, .y = 200 } };

    var edge1 = Edge{ .from = Point3d{ .x = 100, .y = 200 }, .to = Point3d{ .x = 150, .y = 200 } };
    edge1.rotate(around);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 100, .y = 200 }, .to = Point3d{ .x = 100, .y = 200, .z = -50 } }, edge1);

    var edge2 = Edge{ .from = Point3d{ .x = 150, .y = 200 }, .to = Point3d{ .x = 150, .y = 150 } };
    edge2.rotate(around);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 100, .y = 200, .z = -50 }, .to = Point3d{ .x = 100, .y = 150, .z = -50 } }, edge2);

    var edge3 = Edge{ .from = Point3d{ .x = 150, .y = 150 }, .to = Point3d{ .x = 100, .y = 150 } };
    edge3.rotate(around);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 100, .y = 150, .z = -50 }, .to = Point3d{ .x = 100, .y = 150, .z = 0 } }, edge3);

    var edge4 = around;
    edge4.rotate(around);
    try std.testing.expectEqual(around, edge4);
}

test "rotate edges 2" {
    const Edge = DataEdge(void, {});

    const around = Edge{ .from = Point3d{ .x = 100, .y = 200 }, .to = Point3d{ .x = 100, .y = 150 } };

    var edge1 = Edge{ .from = Point3d{ .x = 50, .y = 200 }, .to = Point3d{ .x = 100, .y = 200 } };
    edge1.rotate(around);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 100, .y = 200, .z = -50 }, .to = Point3d{ .x = 100, .y = 200, .z = 0 } }, edge1);

    var edge2 = Edge{ .from = Point3d{ .x = 100, .y = 150 }, .to = Point3d{ .x = 50, .y = 150 } };
    edge2.rotate(around);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 100, .y = 150, .z = 0 }, .to = Point3d{ .x = 100, .y = 150, .z = -50 } }, edge2);

    var edge3 = Edge{ .from = Point3d{ .x = 50, .y = 150 }, .to = Point3d{ .x = 50, .y = 200 } };
    edge3.rotate(around);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 100, .y = 150, .z = -50 }, .to = Point3d{ .x = 100, .y = 200, .z = -50 } }, edge3);

    var edge4 = around;
    edge4.rotate(around);
    try std.testing.expectEqual(around, edge4);
}

fn Face(comptime DataType: type, comptime default_data: DataType) type {
    return struct {
        const Self = @This();

        left_face: ?*Face(DataType, default_data) = null,
        right_face: ?*Face(DataType, default_data) = null,
        top_face: ?*Face(DataType, default_data) = null,
        bottom_face: ?*Face(DataType, default_data) = null,

        left_edge: DataEdge(DataType, default_data),
        right_edge: DataEdge(DataType, default_data),
        top_edge: DataEdge(DataType, default_data),
        bottom_edge: DataEdge(DataType, default_data),

        fn rotate(self: *Self, around: DataEdge(DataType, default_data), parent: ?*const Face(DataType, default_data)) void {
            if (!self.left_edge.isEqual(around) and !self.left_edge.isStacked(around)) self.left_edge.rotate(around);
            if (!self.right_edge.isEqual(around) and !self.right_edge.isStacked(around)) self.right_edge.rotate(around);
            if (!self.top_edge.isEqual(around) and !self.top_edge.isStacked(around)) self.top_edge.rotate(around);
            if (!self.bottom_edge.isEqual(around) and !self.bottom_edge.isStacked(around)) self.bottom_edge.rotate(around);

            if (self.left_face) |face| if (parent == null or face != parent.?) face.rotate(around, self);
            if (self.right_face) |face| if (parent == null or face != parent.?) face.rotate(around, self);
            if (self.top_face) |face| if (parent == null or face != parent.?) face.rotate(around, self);
            if (self.bottom_face) |face| if (parent == null or face != parent.?) face.rotate(around, self);
        }

        fn connectIfEdgesStacked(self: *Self, face: *Face(DataType, default_data)) void {
            const FaceAndEdge = struct {
                face: *?*Face(DataType, default_data),
                edge: *DataEdge(DataType, default_data),
            };

            var faes1 = [4]FaceAndEdge{ FaceAndEdge{ .face = &self.left_face, .edge = &self.left_edge }, FaceAndEdge{ .face = &self.right_face, .edge = &self.right_edge }, FaceAndEdge{ .face = &self.top_face, .edge = &self.top_edge }, FaceAndEdge{ .face = &self.bottom_face, .edge = &self.bottom_edge } };
            var faes2 = [4]FaceAndEdge{ FaceAndEdge{ .face = &face.left_face, .edge = &face.left_edge }, FaceAndEdge{ .face = &face.right_face, .edge = &face.right_edge }, FaceAndEdge{ .face = &face.top_face, .edge = &face.top_edge }, FaceAndEdge{ .face = &face.bottom_face, .edge = &face.bottom_edge } };

            for (faes1) |*fae1| {
                for (faes2) |*fae2| {
                    if (fae1.edge.isStacked(fae2.edge.*)) {
                        fae1.face.* = face;
                        fae2.face.* = self;

                        fae1.edge.stacked_edge = fae2.edge;
                        fae2.edge.stacked_edge = fae1.edge;
                    }
                }
            }
        }
    };
}

test "rotate faces 1" {
    const Edge = DataEdge(void, {});

    var face1 = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = -1, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = -1, .y = -1 } },
    };
    var face2 = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -2 }, .to = Point3d{ .x = -1, .y = -1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = 1, .y = -2 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -2 }, .to = Point3d{ .x = -1, .y = -2 } },
    };

    try std.testing.expectEqual(true, face1.bottom_edge.isStacked(face2.top_edge));
    try std.testing.expectEqual(true, face2.top_edge.isStacked(face1.bottom_edge));

    face1.connectIfEdgesStacked(&face2);

    try std.testing.expectEqual(face1, face2.top_face.?.*);
    try std.testing.expectEqual(face2, face1.bottom_face.?.*);
    try std.testing.expectEqual(face1.bottom_edge.stacked_edge.?.*, face2.top_edge);

    face1.rotate(face1.top_edge.copy(), null);

    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = -1, .y = 1, .z = -2 }, .to = Point3d{ .x = -1, .y = 1 } }, face1.left_edge);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = -1, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } }, face1.top_edge);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = 1, .z = -2 } }, face1.right_edge);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 1, .y = 1, .z = -2 }, .to = Point3d{ .x = -1, .y = 1, .z = -2 } }, face1.bottom_edge.copy());

    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = -1, .y = 1, .z = -3 }, .to = Point3d{ .x = -1, .y = 1, .z = -2 } }, face2.left_edge);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = -1, .y = 1, .z = -2 }, .to = Point3d{ .x = 1, .y = 1, .z = -2 } }, face2.top_edge.copy());
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 1, .y = 1, .z = -2 }, .to = Point3d{ .x = 1, .y = 1, .z = -3 } }, face2.right_edge);
    try std.testing.expectEqual(Edge{ .from = Point3d{ .x = 1, .y = 1, .z = -3 }, .to = Point3d{ .x = -1, .y = 1, .z = -3 } }, face2.bottom_edge);
}

test "fold faces 2" {
    const Edge = DataEdge(void, {});

    var face1 = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = -1, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = -1, .y = -1 } },
    };
    var face2 = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -3 }, .to = Point3d{ .x = -1, .y = -1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = 1, .y = -3 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -3 }, .to = Point3d{ .x = -1, .y = -3 } },
    };
    var face3 = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -5 }, .to = Point3d{ .x = -1, .y = -3 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -3 }, .to = Point3d{ .x = 1, .y = -3 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -3 }, .to = Point3d{ .x = 1, .y = -5 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -5 }, .to = Point3d{ .x = -1, .y = -5 } },
    };
    var face4 = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -7 }, .to = Point3d{ .x = -1, .y = -5 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -5 }, .to = Point3d{ .x = 1, .y = -5 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -5 }, .to = Point3d{ .x = 1, .y = -7 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -7 }, .to = Point3d{ .x = -1, .y = -7 } },
    };

    try std.testing.expectEqual(true, face1.bottom_edge.isStacked(face2.top_edge));
    try std.testing.expectEqual(true, face2.bottom_edge.isStacked(face3.top_edge));
    try std.testing.expectEqual(true, face3.bottom_edge.isStacked(face4.top_edge));

    face1.connectIfEdgesStacked(&face2);
    face2.connectIfEdgesStacked(&face3);
    face3.connectIfEdgesStacked(&face4);

    face2.rotate(face2.top_edge.copy(), &face1);
    try std.testing.expectEqual(false, face1.top_edge.isStacked(face4.bottom_edge));

    face3.rotate(face3.top_edge.copy(), &face2);
    try std.testing.expectEqual(false, face1.top_edge.isStacked(face4.bottom_edge));

    face4.rotate(face4.top_edge.copy(), &face3);

    try std.testing.expectEqual(true, face1.bottom_edge.isStacked(face2.top_edge));
    try std.testing.expectEqual(face1.bottom_edge.stacked_edge.?.*, face2.top_edge);
    try std.testing.expectEqual(face2.top_edge.stacked_edge.?.*, face1.bottom_edge);

    try std.testing.expectEqual(true, face2.bottom_edge.isStacked(face3.top_edge));
    try std.testing.expectEqual(true, face3.bottom_edge.isStacked(face4.top_edge));

    try std.testing.expectEqual(true, face1.top_edge.isStacked(face4.bottom_edge));

    face1.connectIfEdgesStacked(&face4);
}

fn Cube(comptime DataType: type, comptime default_data: DataType) type {
    return struct {
        const Self = @This();

        faces: [6]Face(DataType, default_data) = undefined,

        fn connectStackedEdges(self: *Self) void {
            for (self.faces) |*face1| {
                for (self.faces) |*face2| {
                    face1.connectIfEdgesStacked(face2);
                }
            }
        }

        fn fold(self: *Self) void {
            self.connectStackedEdges();
            foldFrom(&self.faces[0], null);
            self.connectStackedEdges();
        }

        fn foldFrom(face: *Face(DataType, default_data), parent: ?*Face(DataType, default_data)) void {
            if (face.left_face) |left_face| {
                if (parent == null or parent.? != left_face) {
                    left_face.rotate(face.left_edge.copy(), face);
                    foldFrom(left_face, face);
                }
            }
            if (face.top_face) |top_face| {
                if (parent == null or parent.? != top_face) {
                    top_face.rotate(face.top_edge.copy(), face);
                    foldFrom(top_face, face);
                }
            }
            if (face.right_face) |right_face| {
                if (parent == null or parent.? != right_face) {
                    right_face.rotate(face.right_edge.copy(), face);
                    foldFrom(right_face, face);
                }
            }
            if (face.bottom_face) |bottom_face| {
                if (parent == null or parent.? != bottom_face) {
                    bottom_face.rotate(face.bottom_edge.copy(), face);
                    foldFrom(bottom_face, face);
                }
            }
        }
    };
}

test "fold cube1" {
    const Edge = DataEdge(void, {});

    var cube = Cube(void, {}){};

    cube.faces[0] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = -1, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = -1, .y = -1 } },
    };
    cube.faces[1] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -3 }, .to = Point3d{ .x = -1, .y = -1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = 1, .y = -3 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -3 }, .to = Point3d{ .x = -1, .y = -3 } },
    };
    cube.faces[2] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -5 }, .to = Point3d{ .x = -1, .y = -3 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -3 }, .to = Point3d{ .x = 1, .y = -3 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -3 }, .to = Point3d{ .x = 1, .y = -5 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -5 }, .to = Point3d{ .x = -1, .y = -5 } },
    };
    cube.faces[3] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -7 }, .to = Point3d{ .x = -1, .y = -5 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -5 }, .to = Point3d{ .x = 1, .y = -5 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -5 }, .to = Point3d{ .x = 1, .y = -7 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -7 }, .to = Point3d{ .x = -1, .y = -7 } },
    };
    cube.faces[4] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -3, .y = -1 }, .to = Point3d{ .x = -3, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -3, .y = 1 }, .to = Point3d{ .x = -1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = -1, .y = 1 }, .to = Point3d{ .x = -1, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = -3, .y = -1 } },
    };
    cube.faces[5] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 3, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 3, .y = 1 }, .to = Point3d{ .x = 3, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 3, .y = -1 }, .to = Point3d{ .x = 1, .y = -1 } },
    };

    cube.connectStackedEdges();

    try std.testing.expectEqual(cube.faces[0].left_face.?, &cube.faces[4]);
    try std.testing.expectEqual(cube.faces[0].right_face.?, &cube.faces[5]);
    try std.testing.expectEqual(cube.faces[0].bottom_face.?, &cube.faces[1]);
    try std.testing.expectEqual(cube.faces[1].bottom_face.?, &cube.faces[2]);
    try std.testing.expectEqual(cube.faces[2].bottom_face.?, &cube.faces[3]);

    cube.faces[4].rotate(cube.faces[0].left_edge.copy(), &cube.faces[0]);
    cube.faces[5].rotate(cube.faces[0].right_edge.copy(), &cube.faces[0]);
    cube.faces[1].rotate(cube.faces[0].bottom_edge.copy(), &cube.faces[0]);
    cube.faces[2].rotate(cube.faces[1].bottom_edge.copy(), &cube.faces[1]);
    cube.faces[3].rotate(cube.faces[2].bottom_edge.copy(), &cube.faces[2]);
    cube.connectStackedEdges();

    for (cube.faces) |face| {
        try std.testing.expect(face.left_face != null);
        try std.testing.expect(face.top_face != null);
        try std.testing.expect(face.right_face != null);
        try std.testing.expect(face.bottom_face != null);
    }
}

test "fold cube2" {
    const Edge = DataEdge(void, {});

    var cube = Cube(void, {}){};

    cube.faces[0] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = -1, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = -1, .y = -1 } },
    };
    cube.faces[1] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -3 }, .to = Point3d{ .x = -1, .y = -1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = 1, .y = -1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = 1, .y = -3 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -3 }, .to = Point3d{ .x = -1, .y = -3 } },
    };
    cube.faces[2] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -5 }, .to = Point3d{ .x = -1, .y = -3 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -3 }, .to = Point3d{ .x = 1, .y = -3 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -3 }, .to = Point3d{ .x = 1, .y = -5 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -5 }, .to = Point3d{ .x = -1, .y = -5 } },
    };
    cube.faces[3] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -1, .y = -7 }, .to = Point3d{ .x = -1, .y = -5 } },
        .top_edge = Edge{ .from = Point3d{ .x = -1, .y = -5 }, .to = Point3d{ .x = 1, .y = -5 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = -5 }, .to = Point3d{ .x = 1, .y = -7 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = -7 }, .to = Point3d{ .x = -1, .y = -7 } },
    };
    cube.faces[4] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = -3, .y = -1 }, .to = Point3d{ .x = -3, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = -3, .y = 1 }, .to = Point3d{ .x = -1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = -1, .y = 1 }, .to = Point3d{ .x = -1, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = -1, .y = -1 }, .to = Point3d{ .x = -3, .y = -1 } },
    };
    cube.faces[5] = Face(void, {}){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = -1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 3, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 3, .y = 1 }, .to = Point3d{ .x = 3, .y = -1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 3, .y = -1 }, .to = Point3d{ .x = 1, .y = -1 } },
    };

    cube.fold();

    for (cube.faces) |face| {
        try std.testing.expect(face.left_face != null);
        try std.testing.expect(face.top_face != null);
        try std.testing.expect(face.right_face != null);
        try std.testing.expect(face.bottom_face != null);
    }
}

test "fold map prototype" {
    const RowToRow = struct { from: i32 = 0, to: i32 = 0, column: i32 = 0, offset: i4 = 0 };
    const ColumnToColumn = struct { from: i32 = 0, to: i32 = 0, row: i32 = 0, offset: i4 = 0 };

    const Data = union(enum) { rtr: RowToRow, ctc: ColumnToColumn, none: void };
    const Edge = DataEdge(Data, Data{ .none = {} });

    var cube = Cube(Data, Data{ .none = {} }){};

    cube.faces[0] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 0, .y = 0 }, .to = Point3d{ .x = 0, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = 0, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = 0 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = 0 }, .to = Point3d{ .x = 0, .y = 0 } },
    };
    cube.faces[1] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 0, .y = 1 }, .to = Point3d{ .x = 0, .y = 2 } },
        .top_edge = Edge{ .from = Point3d{ .x = 0, .y = 2 }, .to = Point3d{ .x = 1, .y = 2 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 2 }, .to = Point3d{ .x = 1, .y = 1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 0, .y = 1 } },
    };
    cube.faces[2] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = 2 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 2 }, .to = Point3d{ .x = 2, .y = 2 } },
        .right_edge = Edge{ .from = Point3d{ .x = 2, .y = 2 }, .to = Point3d{ .x = 2, .y = 1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 2, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
    };
    cube.faces[3] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = 2 }, .to = Point3d{ .x = 1, .y = 3 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 3 }, .to = Point3d{ .x = 2, .y = 3 } },
        .right_edge = Edge{ .from = Point3d{ .x = 2, .y = 3 }, .to = Point3d{ .x = 2, .y = 2 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 2, .y = 2 }, .to = Point3d{ .x = 1, .y = 2 } },
    };
    cube.faces[4] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = 3 }, .to = Point3d{ .x = 1, .y = 4 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 4 }, .to = Point3d{ .x = 2, .y = 4 } },
        .right_edge = Edge{ .from = Point3d{ .x = 2, .y = 4 }, .to = Point3d{ .x = 2, .y = 3 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 2, .y = 3 }, .to = Point3d{ .x = 1, .y = 3 } },
    };
    cube.faces[5] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 2, .y = 3 }, .to = Point3d{ .x = 2, .y = 4 } },
        .top_edge = Edge{ .from = Point3d{ .x = 2, .y = 4 }, .to = Point3d{ .x = 3, .y = 4 } },
        .right_edge = Edge{ .from = Point3d{ .x = 3, .y = 4 }, .to = Point3d{ .x = 3, .y = 3 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 3, .y = 3 }, .to = Point3d{ .x = 2, .y = 3 } },
    };

    // const edge_size: usize = 52;
    // const max_height = edge_size * 4;
    for (cube.faces) |*face| {
        // .from = Point3d{ .x = 0, .y = 0 }
        // .to = Point3d{ .x = 0, .y = 1 }
        // face.left_edge.data = Data{.rtr = RowToRow{.from = 200, .to = 151, .column = 0}};
        var left_edge = &face.left_edge;
        left_edge.data = Data{ .rtr = RowToRow{ .from = 200 - left_edge.from.y * 50, .to = 200 - left_edge.to.y * 50 + 1, .column = left_edge.from.x * 50, .offset = 1 } };

        // .from = Point3d{ .x = 1, .y = 1 }
        // .to = Point3d{ .x = 1, .y = 0 }
        // face.right_edge.data = Data{.rtr = RowToRow{.from = 151, .to = 200, .column = 51}};
        var right_edge = &face.right_edge;
        right_edge.data = Data{ .rtr = RowToRow{ .from = 200 - right_edge.from.y * 50 + 1, .to = 200 - right_edge.to.y * 50, .column = right_edge.from.x * 50 + 1, .offset = -1 } };

        // .from = Point3d{ .x = 0, .y = 2 }
        // .to = Point3d{ .x = 1, .y = 2 }
        // face.top_edge.data = Data{.ctc = ColumnToColumn{.from = 1, .to = 50, .row = 100}};
        var top_edge = &face.top_edge;
        top_edge.data = Data{ .ctc = ColumnToColumn{ .from = top_edge.from.x * 50 + 1, .to = top_edge.to.x * 50, .row = 200 - top_edge.from.y * 50, .offset = 1 } };

        // .from = Point3d{ .x = 3, .y = 3 }
        // .to = Point3d{ .x = 2, .y = 3 }
        // face.bottom_edge.data = Data{.ctc = ColumnToColumn{.from = 150, .to = 101, .row = 51}};
        var bottom_edge = &face.bottom_edge;
        bottom_edge.data = Data{ .ctc = ColumnToColumn{ .from = bottom_edge.from.x * 50, .to = bottom_edge.to.x * 50 + 1, .row = 200 - bottom_edge.from.y * 50 + 1, .offset = -1 } };
    }

    cube.fold();

    print("{any}\n{any}\n", .{ cube.faces[3].right_edge.data, cube.faces[5].bottom_edge.data });

    try std.testing.expectEqual(cube.faces[3].right_face, &cube.faces[5]);
    try std.testing.expectEqual(cube.faces[5].bottom_face, &cube.faces[3]);

    for (cube.faces) |face| {
        try std.testing.expect(face.left_face != null);
        try std.testing.expect(face.top_face != null);
        try std.testing.expect(face.right_face != null);
        try std.testing.expect(face.bottom_face != null);
    }
}

const ROWS_NUM = 200;
const COLUMNS_NUM = 150;
const INPUT_FILE = "input.txt";
const STARTING_POS = Pos{ .row = 1, .column = 51 };
var MAP: [ROWS_NUM + 2][COLUMNS_NUM + 2]u8 = undefined;

const H = 0;
const V = 1;

const Teleport = struct {
    pos: Pos,
    dir: Dir,
};
var TELEPORTS: [ROWS_NUM + 2][COLUMNS_NUM + 2][2]?Teleport = undefined;

fn generateTeleportsRowToRow(r1: usize, r2: usize, from_c: usize, to_c: usize) void {
    assert(r1 < r2);
    assert(from_c <= to_c);
    var c = from_c;
    while (c <= to_c) : (c += 1) {
        assert(TELEPORTS[r1][c][V] == null);
        assert(TELEPORTS[r2][c][V] == null);
        TELEPORTS[r1][c][V] = Teleport{ .pos = Pos{ .row = r2 - 1, .column = c }, .dir = Dir{ .dx = 0, .dy = -1 } };
        TELEPORTS[r2][c][V] = Teleport{ .pos = Pos{ .row = r1 + 1, .column = c }, .dir = Dir{ .dx = 0, .dy = 1 } };
    }
}

fn generateTeleportsColumnToColumn(c1: usize, c2: usize, from_r: usize, to_r: usize) void {
    assert(c1 < c2);
    assert(from_r <= to_r);
    var r = from_r;
    while (r <= to_r) : (r += 1) {
        assert(TELEPORTS[r][c1][H] == null);
        assert(TELEPORTS[r][c2][H] == null);
        TELEPORTS[r][c1][H] = Teleport{ .pos = Pos{ .row = r, .column = c2 - 1 }, .dir = Dir{ .dx = -1, .dy = 0 } };
        TELEPORTS[r][c2][H] = Teleport{ .pos = Pos{ .row = r, .column = c1 + 1 }, .dir = Dir{ .dx = 1, .dy = 0 } };
    }
}

fn generateTeleportsPart1() void {
    for (TELEPORTS) |*t| std.mem.set([2]?Teleport, t, .{ null, null });

    // r1 = 0, c1 = 51 .. 100
    // r2 = 151, c2 = 51 .. 100
    generateTeleportsRowToRow(0, 151, 51, 100);

    // r1 = 0, c1 = 101 .. 150
    // r2 = 51, c2 = 101 .. 150
    generateTeleportsRowToRow(0, 51, 101, 150);

    // c1 = 50 r1 = 1 .. 50
    // c2 = 151 r2 = 1 .. 50
    generateTeleportsColumnToColumn(50, 151, 1, 50);

    // c1 = 50 r1 = 51 .. 100
    // c2 = 101 r2 = 51 .. 100
    generateTeleportsColumnToColumn(50, 101, 51, 100);

    // c1 = 0 r1 = 101 .. 150
    // c2 = 101 r2 = 101 .. 150
    generateTeleportsColumnToColumn(0, 101, 101, 150);

    // c1 = 0 r1 = 151 .. 200
    // c2 = 51 r2 = 151 .. 200
    generateTeleportsColumnToColumn(0, 51, 151, 200);

    // r1 = 100, c1 = 1 .. 50
    // r2 = 201, c2 = 1 .. 50
    generateTeleportsRowToRow(100, 201, 1, 50);
}

fn generateTeleportsPart2() void {
    for (TELEPORTS) |*t| std.mem.set([2]?Teleport, t, .{ null, null });

    const RowToRow = struct { from: i32 = 0, to: i32 = 0, column: i32 = 0, offset: i4 = 0 };
    const ColumnToColumn = struct { from: i32 = 0, to: i32 = 0, row: i32 = 0, offset: i4 = 0 };

    const Data = union(enum) { rtr: RowToRow, ctc: ColumnToColumn, none: void };
    const Edge = DataEdge(Data, Data{ .none = {} });

    var cube = Cube(Data, Data{ .none = {} }){};

    cube.faces[0] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 0, .y = 0 }, .to = Point3d{ .x = 0, .y = 1 } },
        .top_edge = Edge{ .from = Point3d{ .x = 0, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = 0 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = 0 }, .to = Point3d{ .x = 0, .y = 0 } },
    };
    cube.faces[1] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 0, .y = 1 }, .to = Point3d{ .x = 0, .y = 2 } },
        .top_edge = Edge{ .from = Point3d{ .x = 0, .y = 2 }, .to = Point3d{ .x = 1, .y = 2 } },
        .right_edge = Edge{ .from = Point3d{ .x = 1, .y = 2 }, .to = Point3d{ .x = 1, .y = 1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 0, .y = 1 } },
    };
    cube.faces[2] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = 1 }, .to = Point3d{ .x = 1, .y = 2 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 2 }, .to = Point3d{ .x = 2, .y = 2 } },
        .right_edge = Edge{ .from = Point3d{ .x = 2, .y = 2 }, .to = Point3d{ .x = 2, .y = 1 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 2, .y = 1 }, .to = Point3d{ .x = 1, .y = 1 } },
    };
    cube.faces[3] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = 2 }, .to = Point3d{ .x = 1, .y = 3 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 3 }, .to = Point3d{ .x = 2, .y = 3 } },
        .right_edge = Edge{ .from = Point3d{ .x = 2, .y = 3 }, .to = Point3d{ .x = 2, .y = 2 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 2, .y = 2 }, .to = Point3d{ .x = 1, .y = 2 } },
    };
    cube.faces[4] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 1, .y = 3 }, .to = Point3d{ .x = 1, .y = 4 } },
        .top_edge = Edge{ .from = Point3d{ .x = 1, .y = 4 }, .to = Point3d{ .x = 2, .y = 4 } },
        .right_edge = Edge{ .from = Point3d{ .x = 2, .y = 4 }, .to = Point3d{ .x = 2, .y = 3 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 2, .y = 3 }, .to = Point3d{ .x = 1, .y = 3 } },
    };
    cube.faces[5] = Face(Data, Data{ .none = {} }){
        .left_edge = Edge{ .from = Point3d{ .x = 2, .y = 3 }, .to = Point3d{ .x = 2, .y = 4 } },
        .top_edge = Edge{ .from = Point3d{ .x = 2, .y = 4 }, .to = Point3d{ .x = 3, .y = 4 } },
        .right_edge = Edge{ .from = Point3d{ .x = 3, .y = 4 }, .to = Point3d{ .x = 3, .y = 3 } },
        .bottom_edge = Edge{ .from = Point3d{ .x = 3, .y = 3 }, .to = Point3d{ .x = 2, .y = 3 } },
    };

    for (cube.faces) |*face| {
        var left_edge = &face.left_edge;
        left_edge.data = Data{ .rtr = RowToRow{ .from = 200 - left_edge.from.y * 50, .to = 200 - left_edge.to.y * 50 + 1, .column = left_edge.from.x * 50, .offset = 1 } };

        var right_edge = &face.right_edge;
        right_edge.data = Data{ .rtr = RowToRow{ .from = 200 - right_edge.from.y * 50 + 1, .to = 200 - right_edge.to.y * 50, .column = right_edge.from.x * 50 + 1, .offset = -1 } };

        var top_edge = &face.top_edge;
        top_edge.data = Data{ .ctc = ColumnToColumn{ .from = top_edge.from.x * 50 + 1, .to = top_edge.to.x * 50, .row = 200 - top_edge.from.y * 50, .offset = 1 } };

        var bottom_edge = &face.bottom_edge;
        bottom_edge.data = Data{ .ctc = ColumnToColumn{ .from = bottom_edge.from.x * 50, .to = bottom_edge.to.x * 50 + 1, .row = 200 - bottom_edge.from.y * 50 + 1, .offset = -1 } };
    }

    cube.fold();

    for (cube.faces) |face| {
        const edges = [4]*const Edge{ &face.left_edge, &face.top_edge, &face.right_edge, &face.bottom_edge };
        for (edges) |edge| {
            const from_data = edge.data;
            const to_data = edge.stacked_edge.?.data;

            var idx: i32 = 0;
            while (idx < 50) : (idx += 1) {
                switch (from_data) {
                    Data.rtr => |from_rtr| {
                        switch (to_data) {
                            Data.rtr => |to_rtr| {
                                const from_row = @intCast(usize, if (from_rtr.from < from_rtr.to) from_rtr.from + idx else from_rtr.from - idx);
                                const from_column = @intCast(usize, from_rtr.column);
                                const to_row = @intCast(usize, if (to_rtr.from < to_rtr.to) to_rtr.to - idx else to_rtr.to + idx);
                                const to_column = @intCast(usize, to_rtr.column + to_rtr.offset);

                                if (from_row == to_row) break;

                                TELEPORTS[from_row][from_column][H] = Teleport{ .pos = Pos{ .row = to_row, .column = to_column }, .dir = Dir{ .dx = to_rtr.offset, .dy = 0 } };
                            },
                            Data.ctc => |to_ctc| {
                                const from_row = @intCast(usize, if (from_rtr.from < from_rtr.to) from_rtr.from + idx else from_rtr.from - idx);
                                const from_column = @intCast(usize, from_rtr.column);
                                const to_row = @intCast(usize, to_ctc.row + to_ctc.offset);
                                const to_column = @intCast(usize, if (to_ctc.from < to_ctc.to) to_ctc.to - idx else to_ctc.to + idx);
                                TELEPORTS[from_row][from_column][H] = Teleport{ .pos = Pos{ .row = to_row, .column = to_column }, .dir = Dir{ .dy = to_ctc.offset, .dx = 0 } };
                            },

                            else => unreachable,
                        }
                    },
                    Data.ctc => |from_ctc| {
                        switch (to_data) {
                            Data.rtr => |to_rtr| {
                                const from_row = @intCast(usize, from_ctc.row);
                                const from_column = @intCast(usize, if (from_ctc.from < from_ctc.to) from_ctc.from + idx else from_ctc.from - idx);
                                const to_row = @intCast(usize, if (to_rtr.from < to_rtr.to) to_rtr.to - idx else to_rtr.to + idx);
                                const to_column = @intCast(usize, to_rtr.column + to_rtr.offset);
                                TELEPORTS[from_row][from_column][V] = Teleport{ .pos = Pos{ .row = to_row, .column = to_column }, .dir = Dir{ .dx = to_rtr.offset, .dy = 0 } };
                            },
                            Data.ctc => |to_ctc| {
                                const from_row = @intCast(usize, from_ctc.row);
                                const from_column = @intCast(usize, if (from_ctc.from < from_ctc.to) from_ctc.from + idx else from_ctc.from - idx);
                                const to_row = @intCast(usize, to_ctc.row + to_ctc.offset);
                                const to_column = @intCast(usize, if (to_ctc.from < to_ctc.to) to_ctc.to - idx else to_ctc.to + idx);

                                if (from_column == to_column) break;

                                TELEPORTS[from_row][from_column][V] = Teleport{ .pos = Pos{ .row = to_row, .column = to_column }, .dir = Dir{ .dy = to_ctc.offset, .dx = 0 } };
                            },
                            else => unreachable,
                        }
                    },
                    else => unreachable,
                }
            }
        }
    }
}

const Pos = struct {
    const Self = @This();

    row: usize = 0,
    column: usize = 0,

    fn move(self: *Self, dir: *const Dir) ?Dir {
        if (dir.dx > 0) self.column += 1 else if (dir.dx < 0) self.column -= 1;
        if (dir.dy > 0) self.row += 1 else if (dir.dy < 0) self.row -= 1;

        if (dir.dx != 0) {
            if (TELEPORTS[self.row][self.column][H]) |t| {
                self.* = t.pos;
                return t.dir;
            }
        }
        if (dir.dy != 0) {
            if (TELEPORTS[self.row][self.column][V]) |t| {
                self.* = t.pos;
                return t.dir;
            }
        }

        return null;
    }
};

const Dir = struct {
    const Self = @This();

    dx: i32 = 0,
    dy: i32 = -1,

    fn left(self: *Self) void {
        assert((self.dx == 0 and self.dy != 0) or (self.dx != 0 and self.dy == 0));

        if (self.dx == 1) {
            self.dx = 0;
            self.dy = -1;
        } else if (self.dx == -1) {
            self.dx = 0;
            self.dy = 1;
        } else if (self.dy == 1) {
            self.dy = 0;
            self.dx = 1;
        } else if (self.dy == -1) {
            self.dy = 0;
            self.dx = -1;
        } else {
            unreachable;
        }

        assert((self.dx == 0 and self.dy != 0) or (self.dx != 0 and self.dy == 0));
    }

    fn right(self: *Self) void {
        assert((self.dx == 0 and self.dy != 0) or (self.dx != 0 and self.dy == 0));

        if (self.dx == 1) {
            self.dx = 0;
            self.dy = 1;
        } else if (self.dx == -1) {
            self.dx = 0;
            self.dy = -1;
        } else if (self.dy == 1) {
            self.dy = 0;
            self.dx = -1;
        } else if (self.dy == -1) {
            self.dy = 0;
            self.dx = 1;
        } else {
            unreachable;
        }

        assert((self.dx == 0 and self.dy != 0) or (self.dx != 0 and self.dy == 0));
    }
};

pub fn main() !void {
    generateTeleportsPart2();

    const file = try std.fs.cwd().openFile(
        INPUT_FILE,
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [1024 * 6]u8 = undefined;

    var route: [1024 * 6]u8 = undefined;

    var n: usize = 0;
    std.mem.set(u8, &MAP[0], ' ');
    std.mem.set(u8, &MAP[MAP.len - 1], ' ');
    while (true) {
        if (n < ROWS_NUM) {
            std.mem.set(u8, &MAP[n + 1], ' ');
            std.mem.copy(u8, MAP[n + 1][1..], (try in.readUntilDelimiterOrEof(&buf, '\n')).?);
            n += 1;
        } else {
            try in.skipUntilDelimiterOrEof('\n');
            const r = (try in.readUntilDelimiterOrEof(&buf, '\n')).?;
            std.mem.copy(u8, &route, r);
            route[r.len] = '!';
            break;
        }
    }
    var map_display: [MAP.len][MAP[0].len]u8 = undefined;
    n = 0;
    for (MAP) |row| {
        std.mem.copy(u8, &map_display[n], &row);
        n += 1;
    }
    for (TELEPORTS) |row, ri| {
        for (row) |pos, ci| {
            if (pos[H]) |_| map_display[ri][ci] = 'T';
            if (pos[V]) |_| map_display[ri][ci] = 'T';
        }
    }
    for (map_display) |row| {
        print("{s}\n", .{row});
    }

    n = 0;

    var pos = STARTING_POS;
    var dir = Dir{};
    while (route[n] != '!') {
        var i = n;
        const rotate = route[i];
        i += 1;
        while (route[i] >= '0' and route[i] <= '9') : (i += 1) {}
        var steps = try std.fmt.parseInt(u32, route[n + 1 .. i], 10);
        n = i;

        var next_pos = pos;

        switch (rotate) {
            'R' => dir.right(),
            'L' => dir.left(),
            else => unreachable,
        }

        while (steps != 0) {
            const maybe_new_dir = next_pos.move(&dir);
            switch (MAP[next_pos.row][next_pos.column]) {
                '.' => {
                    pos = next_pos;
                    const dir_sign: u8 = if (dir.dx > 0) '>' else if (dir.dx < 0) '<' else if (dir.dy > 0) 'v' else if (dir.dy < 0) '^' else unreachable;
                    map_display[pos.row][pos.column] = dir_sign;
                    steps -= 1;
                    if (maybe_new_dir) |new_dir| dir = new_dir;
                },
                '#' => break,
                else => unreachable,
            }
        }
    }

    for (map_display) |row| {
        print("{s}\n", .{row});
    }

    print("row = {!}, column = {!}, dir = {any}\n", .{ pos.row, pos.column, dir });
}
