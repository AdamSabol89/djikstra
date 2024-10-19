const std = @import("std");
const root = @import("root.zig");

pub fn gen_grap(GenericType: type, allocator: std.mem.Allocator) !root.Graph(GenericType) {
    const NodeType = root.Node(GenericType);
    const GraphType = root.Graph(GenericType);

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    var rand = prng.random();

    const num_nodes = rand.uintAtMost(usize, 1000);
    const nodes = try allocator.alloc(NodeType, num_nodes);

    for (0..num_nodes) |j| {
        nodes[j] = try NodeType.init(allocator, undefined, null);
    }

    for (nodes) |*node| {
        const edges = rand.uintAtMost(usize, 25);

        var i: usize = 0;
        while (i < edges) : (i += 1) {
            const other_node_index = rand.uintLessThan(usize, num_nodes);
            const other_node = &nodes[other_node_index];
            try node.add_edge(rand.uintAtMost(usize, 1000), @constCast(other_node));
        }
    }
    return GraphType.init(nodes, allocator);
}

test "djikstra" {
    const allocator = std.testing.allocator;
    var graph = try gen_grap(usize, allocator);
    defer graph.deinit();
    const graph_size = graph.nodes.items.len;

    std.debug.print("{d}", .{graph_size});
    std.debug.print("\n : random weight {d}", .{graph.nodes.getLast().edges.getLast().weight});
    var shortest_map = try graph.djikstra(&graph.nodes.getLast(), allocator);

    defer shortest_map.deinit();

    const first = graph.nodes.items[0];
    const nearest = shortest_map.get(first).?;
    std.debug.print("\n {?}", .{nearest});
}
