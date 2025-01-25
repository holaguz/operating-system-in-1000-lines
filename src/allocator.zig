const std = @import("std");
const Self = @This();

pub const BuddyAllocator = struct {
    size: usize,
    page_size: usize,
    num_pages: usize,
    memory: []align(8) u8,
    used: []u8 align(8),
    sum_tree: []usize,

    /// Initialize the BuddyAllocator
    /// `base`: the base address of the backing memory
    /// `size`: the size in bytes of the backing memory
    /// `page_size`: the size in bytes of each memory page. A page is the minimum number of bytes that can be
    /// allocated at a single time. A lower value is more efficient when doing single, small allocations, but requires
    /// more static memory to hold the metadata. A higher value means the metadata is smaller, but a lot of memory is
    /// wasted when performing small allocations.
    pub fn init(buffer: []align(8) u8, comptime size: usize, comptime page_size: usize) BuddyAllocator {
        if ((size == 0) or (page_size == 0)) {
            @compileError("Invalid size or page_size");
        }

        if (page_size % 8 != 0) {
            @compileError("Page size is not 8-byte aligned");
        }

        if (size % 8 != 0) {
            @compileError("Memory size is not 8-byte aligned");
        }

        if (buffer.len < size) {
            @panic("Buffer too small for the given size");
        }

        const num_pages = std.math.divCeil(usize, size, page_size) catch unreachable;

        // The number of nodes in a full tree is 2*L - 1, where L is the number of leaves
        // In this case, the number of leaves is the number of pages.
        // The leaves are not stored the sum tree, so we substract L.
        const nodes_in_full_tree = 2 * num_pages - 1;
        const nodes_not_leaves = nodes_in_full_tree - num_pages;

        // The number of bytes required to store the sum tree. For ease of use, each node
        // is stored as an `usize`.
        const sum_tree_size_bytes = nodes_not_leaves * @sizeOf(usize);

        // The number of u8 buckets required to store the state of each memory page. Each
        // byte can store the state of 8 pages.
        const num_buckets = std.math.divCeil(usize, num_pages, 8) catch unreachable;

        // Calculate the number of pages required to store the metadata in memory.
        const total_meta_bytes = num_buckets + sum_tree_size_bytes;
        const pages_needed = std.math.divCeil(usize, total_meta_bytes, page_size) catch unreachable;

        // Store the sum tree as a slice at the start of the provided buffer.
        const sum_tree: []usize = @as([*]usize, @ptrCast(buffer.ptr))[0..nodes_not_leaves];

        // Store the buckets just after the sum tree.
        const used: []u8 = @as([*]u8, @ptrCast(buffer.ptr + sum_tree_size_bytes))[0..num_buckets];

        // Zero-initialize the metadata
        @memset(sum_tree, 0);
        @memset(used, 0);

        std.debug.print("{?}\n", .{.{
            size,
            page_size,
            num_pages,
            sum_tree,
            used,
        }});

        var self = BuddyAllocator{
            .size = size,
            .page_size = page_size,
            .num_pages = num_pages,
            .used = used,
            .sum_tree = sum_tree,
            .memory = buffer[0..size],
        };

        for (0..pages_needed) |i| {
            self.usePage(i);

            const tree_index = self.pageIndexToTreeIndex(i);
            // const parent = tree_index / 2;
            self.propagateNode(tree_index);
        }

        return self;
    }

    fn usePage(self: *BuddyAllocator, i: usize) void {
        const bucket_idx, const pos = pageIndexToBucketAndPos(i);
        const mask = std.math.shl(u8, 1, pos);

        const bucket = &self.used[bucket_idx];
        if (bucket.* & mask != 0) {
            @panic("Page already used");
        }

        bucket.* |= mask;
    }

    fn freePage(self: *BuddyAllocator, i: usize) void {
        const bucket_idx, const pos = pageIndexToBucketAndPos(i);
        const mask = std.math.shl(u8, 1, pos);

        const bucket = &self.used[bucket_idx];
        if (bucket.* & mask != 1) {
            @panic("Page not in use");
        }

        bucket.* &= ~mask;
    }

    fn propagateNode(self: *BuddyAllocator, i: usize) void {
        // We have two cases: i is a page or not

        // If i is a page, do nothing and call update on the parent
        if (self.indexIsPage(i)) {
            // Do nothing
        } else {
            // i is a node, fetch the children

            const left = 2 * i + 1;
            const right = 2 * i + 2;

            const sum_left = if (self.indexIsPage(left)) blk: {
                // The left children is a page
                const page_index = self.treeIndexToPageIndex(left);
                const bucket, const pos = pageIndexToBucketAndPos(page_index);
                const mask = std.math.shl(u8, 1, pos);
                const in_use: usize = if (self.used[bucket] & mask != 0) 1 else 0;
                break :blk in_use;
            } else self.sum_tree[left];

            const sum_right = if (self.indexIsPage(right)) blk: {
                // The children is a page
                const page_index = self.treeIndexToPageIndex(right);
                const bucket, const pos = pageIndexToBucketAndPos(page_index);
                const mask = std.math.shl(u8, 1, pos);
                const in_use: usize = if (self.used[bucket] & mask != 0) 1 else 0;
                break :blk in_use;
            } else self.sum_tree[right];

            self.sum_tree[i] = sum_left + sum_right;
        }

        const isRoot = i == 0;

        if (!isRoot) {
            const parent = (i - 1) / 2;
            self.propagateNode(parent);
        }
    }

    inline fn pageIndexToTreeIndex(self: *BuddyAllocator, i: usize) usize {
        if (i >= self.num_pages) {
            @panic("Invalid page index");
        }
        return i + self.num_pages - 1;
    }

    inline fn treeIndexToPageIndex(self: *BuddyAllocator, i: usize) usize {
        if (i < self.num_pages - 1) {
            @panic("Index is not a page index");
        }

        return i - (self.num_pages - 1);
    }

    inline fn indexIsPage(self: *BuddyAllocator, i: usize) bool {
        return i >= self.num_pages - 1;
    }

    inline fn pageIndexToBucketAndPos(i: usize) struct { usize, usize } {
        return .{
            i / 8,
            i % 8,
        };
    }
};

test "BuddyAllocator init" {
    const heap_size = 128; // 128 bytes
    const page_size = 32; // 32 bytes
    const num_pages = heap_size / page_size;

    var buffer: [heap_size]u8 align(8) = undefined;
    var meta: [(num_pages + 7) / 8]u8 align(8) = undefined;

    @memset(&buffer, 0xaa);
    @memset(&meta, 0xaa);

    // const base = @intFromPtr(&buffer);
    const b = BuddyAllocator.init(&buffer, heap_size, page_size);
    _ = b;
    // try std.testing.expectEqual(1, meta[0]);

    // std.debug.print("{}, {any}", .{ b, buffer });
}
