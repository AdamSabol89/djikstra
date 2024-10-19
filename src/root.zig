const std = @import("std");
const testing = std.testing;

pub fn Edge(comptime T: type) type {
    return struct {
        weight: usize,
        ptr: *Node(T),

        pub fn init(weight: usize, ptr: *Node(T)) Edge(T) {
            return .{ .weight = weight, .ptr = ptr };
        }
    };
}

pub fn Node(comptime T: type) type {
    return struct {
        vertex_value: T,
        edges: std.ArrayList(Edge(T)),

        pub fn init(allocator: std.mem.Allocator, value: T, edges: ?[]const Edge(T)) !Node(T) {
            var this_edges = std.ArrayList(Edge(T)).init(allocator);
            if (edges) |some_edges| {
                try this_edges.insertSlice(0, some_edges);
            }
            return .{
                .vertex_value = value,
                .edges = this_edges,
            };
        }
        pub fn deinit(self: *Node(T)) void {
            self.edges.deinit();
        }

        pub fn add_edge(self: *Node(T), weight: usize, other_node: *Node(T)) !void {
            try self.edges.append(.{ .weight = weight, .ptr = other_node });
        }

        pub const nodeHashCtx = struct {
            pub const eql = std.hash_map.getAutoEqlFn(Node(T), @This());

            pub fn hash(self: @This(), k: Node(T)) u64 {
                _ = self;
                var hasher: *std.hash.Wyhash = @constCast(&std.hash.Wyhash.init(0));
                std.hash.autoHashStrat(hasher, k, std.hash.Strategy.Shallow);
                return @truncate(hasher.final());
            }
        };
    };
}

pub fn Graph(comptime T: type) type {
    return struct {
        const Self = @This();
        nodes: std.ArrayList(Node(T)),

        pub fn init(nodes: []Node(T), allocator: std.mem.Allocator) Graph(T) {
            return .{ .nodes = std.ArrayList(Node(T)).fromOwnedSlice(allocator, nodes) };
        }

        pub fn deinit(self: *Graph(T)) void {
            while (self.nodes.items.len > 0) {
                self.nodes.items[self.nodes.items.len - 1].deinit();
                _ = self.nodes.pop();
            }
            self.nodes.deinit();
        }

        pub fn add_node(self: *Graph(T), element: Node(T)) !void {
            try self.nodes.append(element);
        }

        pub const nodeTuple = struct {
            dist: usize,
            node: Node(T),
        };

        pub fn compare(_: void, a: Self.nodeTuple, b: Self.nodeTuple) std.math.Order {
            return std.math.order(a.dist, b.dist);
        }

        pub fn djikstra(self: Self, start: *const Node(T), allocator: std.mem.Allocator) !std.HashMap(Node(T), usize, Node(T).nodeHashCtx, 80) {
            _ = self;
            var priorityQueue = std.PriorityQueue(nodeTuple, void, compare).init(allocator, undefined);
            defer priorityQueue.deinit();

            var shortestMap = std.HashMap(Node(T), usize, Node(T).nodeHashCtx, 80).init(allocator);

            try priorityQueue.add(nodeTuple{ .dist = 0, .node = start.* });

            while (priorityQueue.peek()) |curr| {
                _ = priorityQueue.remove();

                if (shortestMap.get(curr.node)) |node| {
                    _ = node;
                    continue;
                }

                try shortestMap.put(curr.node, curr.dist);

                for (curr.node.edges.items) |edge| {
                    try priorityQueue.add(.{ .dist = edge.weight + curr.dist, .node = edge.ptr.* });
                }
            }
            return shortestMap;
        }
    };
}
