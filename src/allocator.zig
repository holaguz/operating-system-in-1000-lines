const std = @import("std");
const Allocator = std.mem.Allocator;
const Self = @This();

const WordSize = @alignOf(usize);

pub const BuddyAllocator = struct {
    const AllocatorError = Allocator.Error;

    const TreeNode = struct {
        total_pages: usize = 0,
        contiguous_left: usize = 0,
        contiguous_right: usize = 0,
        is_full: bool = false,
        is_empty: bool = false,

        const Direction = enum { Left, Right };

        fn merge(self: *@This(), left: *const TreeNode, right: *const TreeNode) void {
            const merged_interval = left.contiguous_right + right.contiguous_left;
            const left_sum = std.mem.max(usize, &[_]usize{ left.contiguous_left, left.contiguous_right, merged_interval });
            const right_sum = std.mem.max(usize, &[_]usize{ right.contiguous_left, right.contiguous_right, merged_interval });

            self.contiguous_left = left_sum;
            self.contiguous_right = right_sum;
            self.total_pages = left.total_pages + right.total_pages;
            self.is_empty = left.is_empty and right.is_empty;
            self.is_full = left.is_full and right.is_full;
        }

        fn fromInt(bucket: anytype) TreeNode {
            const T = @TypeOf(bucket);
            const Ti = @typeInfo(T);

            comptime switch (Ti) {
                .Int => {},
                else => @compileError("bucket must be an integral type"),
            };

            return .{
                .total_pages = Ti.Int.bits,
                .contiguous_left = @clz(bucket),
                .contiguous_right = @ctz(bucket),
                .is_full = bucket == std.math.maxInt(T),
                .is_empty = bucket == 0,
            };
        }
    };

    size: usize,
    page_size: usize,
    num_pages: usize,
    memory: []align(WordSize) u8,
    // sum_tree: []TreeNode, // TODO: Try using a MultiArrayList
    sum_tree: std.MultiArrayList(TreeNode),
    pages: []align(WordSize) u8,

    const vtable: Allocator.VTable = .{
        .alloc = alloc,
        .free = free,
        .resize = resize,
    };

    /// Initialize the BuddyAllocator
    /// `base`: the base address of the backing memory
    /// `size`: the size in bytes of the backing memory
    /// `page_size`: the size in bytes of each memory page. A page is the minimum number of bytes that can be
    /// allocated at a single time. A lower value is more efficient when doing single, small allocations, but requires
    /// more static memory to hold the metadata. A higher value means the metadata is smaller, but a lot of memory is
    /// wasted when performing small allocations.
    pub fn init(buffer: []align(WordSize) u8, comptime size: usize, comptime page_size: usize) BuddyAllocator {
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
        const num_buckets = (num_pages + 7) / 8;

        // The number of nodes in a full tree is 2*L - 1, where L is the number of leaves
        // In this case, the number of leaves is the number of pages.
        // The leaves are not stored the sum tree, so we substract L.
        // const nodes_in_full_tree = 2 * num_pages - 1;
        // const nodes_not_leaves = nodes_in_full_tree - num_pages;

        // The number of bytes required to store the sum tree. For ease of use, each node
        // is stored as an `usize`.
        // const sum_tree_size_bytes = nodes_not_leaves * @sizeOf(usize);

        // The number of u8 buckets required to store the state of each memory page. Each
        // byte can store the state of 8 pages.
        // const num_buckets = std.math.divCeil(usize, num_pages, 8) catch unreachable;

        // Calculate the number of pages required to store the metadata in memory.
        // const total_meta_bytes = num_buckets + sum_tree_size_bytes;
        // const pages_needed = std.math.divCeil(usize, total_meta_bytes, page_size) catch unreachable;

        // Store the sum tree as a slice at the start of the provided buffer.
        // The sum tree stores the number of contiguous free pages.
        // const sum_tree: []TreeNode = @as([*]TreeNode, @ptrCast(buffer.ptr))[0..nodes_not_leaves];
        // const branches = &[nodes_not_leaves]TreeNode{};
        // const leaves = [num_pages / 8]TreeNode{};
        // const sum_tree = branches ++ leaves;

        var fba = std.heap.FixedBufferAllocator.init(buffer);
        const fba_alloc = fba.allocator();

        // const sum_tree = fba_alloc.alloc(TreeNode, num_pages - 1) catch @panic("No memory");
        var sum_tree = std.MultiArrayList(TreeNode){};
        sum_tree.setCapacity(fba_alloc, num_buckets - 1) catch unreachable;

        // FIXME: Find a better way to append many items to a MultiArrayList
        for (0..num_buckets - 1) |_| {
            _ = sum_tree.addOneAssumeCapacity();
        }

        const page_array = fba_alloc.alignedAlloc(u8, WordSize, num_buckets) catch @panic("No memory");

        std.debug.print("allocator usage: {}\n\n", .{fba.end_index});

        const used_pages = std.math.divCeil(usize, fba.end_index, page_size) catch @panic("Div Error");

        @memset(page_array, 0);

        var self = BuddyAllocator{
            .size = size,
            .page_size = page_size,
            .num_pages = num_pages,
            .sum_tree = sum_tree,
            .pages = page_array,
            .memory = buffer[0..size],
        };

        std.debug.print("num nodes in tree: {}\n", .{sum_tree.len});
        std.debug.print("num_pages: {}\nused by metadata: {}\nnum buckets: {}\n", .{ num_pages, used_pages, num_buckets });

        for (0..used_pages) |i| {
            self.usePage(i);
        }

        self.bubbleDown(0);

        return self;
    }

    pub fn allocator(self: *BuddyAllocator) Allocator {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }

    // Returns the index of the first page which spans at least num_pages contiguous free.
    // fn findFirstBucket(self: *const BuddyAllocator, start_ix: usize, num_pages: usize) AllocatorError!usize {
    //     // var current: usize = 0;
    //
    //     std.debug.print("{} {}\n", .{ start_ix, num_pages });
    //
    //     if (self.indexIsPage(start_ix)) {
    //         @panic("TODO");
    //     }
    //
    //     // Always go left
    //     while (true) {
    //         const free_pages = self.sum_tree[start_ix];
    //         std.debug.print("free pages: {}\n", .{free_pages});
    //         if (free_pages < num_pages) {
    //             return AllocatorError.OutOfMemory;
    //         }
    //
    //         const left_ix = 2 * start_ix + 1;
    //         const right_ix = 2 * start_ix + 2;
    //
    //         return self.findFirstBucket(left_ix, num_pages) catch self.findFirstBucket(right_ix, num_pages);
    //     }
    //
    //     return 0;
    // }

    fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        _ = ctx;
        _ = len;
        _ = ptr_align;
        _ = ret_addr;
        @panic("Lol");
        // _ = ret_addr;
        // const self: *BuddyAllocator = @ptrCast(@alignCast(ctx));
        //
        // if (ptr_align > self.page_size) {
        //     @panic("Not implemented");
        // }
        //
        // const pages_required = std.mem.alignForward(usize, len, self.page_size) / self.page_size;
        // const first_page_index = self.findFirstBucket(0, pages_required) catch return null;
        //
        // const memory = self.memory[first_page_index * self.page_size ..];
        // return @ptrCast(memory);
    }

    fn resize(_: *anyopaque, _: []u8, _: u8, _: usize, _: usize) bool {
        return false;
    }

    fn free(_: *anyopaque, _: []u8, _: u8, _: usize) void {}

    fn usePage(self: *BuddyAllocator, i: usize) void {
        const bucket_idx, const pos = pageIndexToBucketAndPos(i);
        const mask = std.math.shl(u8, 1, 7 - pos);

        const bucket = &self.pages[bucket_idx];
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

    fn bubbleUp(self: *BuddyAllocator, i: usize) void {
        // We have two cases: i is a page or not

        // If i is a page, do nothing and call update on the parent
        if (self.indexIsPage(i)) {
            // Do nothing
        } else {
            // i is a node, fetch the children

            // const left = 2 * i + 1;
            // const right = 2 * i + 2;
            //
            // const left_sum = if (self.indexIsPage(left)) blk: {
            //     const page_index = self.treeIndexToPageIndex(left);
            //     const bucket_idx, _ = pageIndexToBucketAndPos(page_index);
            //     const bucket = self.used[bucket_idx];
            //     break :blk @ctz(bucket); // For the left tree, count the trailing zeroes
            // } else self.sum_tree[left].suffix;
            //
            // const right_sum = if (self.indexIsPage(right)) blk: {
            //     const page_index = self.treeIndexToPageIndex(right);
            //     const bucket_idx, _ = pageIndexToBucketAndPos(page_index);
            //     const bucket = self.used[bucket_idx];
            //     break :blk @clz(bucket); // For the right tree, count the leading zeroes
            // } else self.sum_tree[right].prefix;
            //
            // self.sum_tree[i] = left_sum + right_sum;
        }

        const isRoot = i == 0;

        if (!isRoot) {
            const parent = (i - 1) / 2;
            self.bubbleUp(parent);
        }
    }

    fn bubbleDown(self: *BuddyAllocator, i: usize) void {
        const left_ix = 2 * i + 1;
        const right_ix = 2 * i + 2;

        std.debug.print("ix: {}, l: {}, r: {}\n", .{ i, left_ix, right_ix });

        const left_node, const right_node = blk: {
            switch (self.indexIsPage(left_ix) and self.indexIsPage(right_ix)) {
                true => {
                    const left_page_ix = self.treeIndexToBucketIndex(left_ix);
                    const right_page_ix = self.treeIndexToBucketIndex(right_ix);

                    const left_page = self.pages[left_page_ix];
                    const right_page = self.pages[right_page_ix];

                    const left_node = TreeNode.fromInt(left_page);
                    const right_node = TreeNode.fromInt(right_page);
                    break :blk .{ left_node, right_node };
                },
                false => {
                    self.bubbleDown(left_ix);
                    self.bubbleDown(right_ix);

                    const left_node = self.sum_tree.slice().get(left_ix);
                    const right_node = self.sum_tree.slice().get(right_ix);

                    break :blk .{ left_node, right_node };
                },
            }
        };

        var this_node = self.sum_tree.slice().get(i);
        this_node.merge(&left_node, &right_node);
        self.sum_tree.set(i, this_node);
    }

    inline fn pageIndexToTreeIndex(self: *const BuddyAllocator, i: usize) usize {
        if (i >= self.num_pages) {
            @panic("Invalid page index");
        }
        return i + self.num_pages - 1;
    }

    inline fn treeIndexToPageIndex(self: *const BuddyAllocator, i: usize) usize {
        if (!self.indexIsPage(i)) {
            @panic("Index is not a page index");
        }

        return i - (self.num_pages - 1);
    }

    inline fn treeIndexToBucketIndex(self: *const BuddyAllocator, i: usize) usize {
        if (!self.indexIsPage(i)) {
            @panic("Index is not a page index");
        }

        return i - (self.num_pages - 1) / 8;
    }

    inline fn indexIsPage(self: *const BuddyAllocator, i: usize) bool {
        return i >= (self.num_pages - 1) / 8;
    }

    inline fn pageIndexToBucketAndPos(i: usize) struct { usize, usize } {
        return .{
            i / 8,
            i % 8,
        };
    }

    pub fn graphviz(self: *const BuddyAllocator) void {
        // Header
        std.debug.print("digraph BuddyAllocator {{\n", .{});

        for (0..self.sum_tree.len) |i| {
            const el = self.sum_tree.get(i);
            std.debug.print("\t{} [label=\"ix={} cnt={}\"];\n", .{ i, i, el });
            std.debug.print("\t{} -> {};\n", .{ i, 2 * i + 1 });
            std.debug.print("\t{} -> {};\n", .{ i, 2 * i + 2 });
        }
        std.debug.print("\n", .{});

        for (0..self.num_pages / 8) |i| {
            const value = self.pages[i];
            // const mask = std.math.shl(u8, 1, bit);
            // const value: usize = if (self.pages[bucket] & mask > 0) 1 else 0;
            std.debug.print("\t{} [label=\"{}: v={b:0>8}\"];\n", .{ i + self.sum_tree.len, i, value });
        }

        std.debug.print("}}\n", .{});
    }
};

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}

test "BuddyAllocator init" {
    const heap_size = 4096; // 128 bytes
    const page_size = 128; // 32 bytes

    var buffer: [heap_size]u8 align(WordSize) = undefined;

    @memset(&buffer, 0xaa);

    var b = BuddyAllocator.init(&buffer, heap_size, page_size);

    // b.usePage(1);
    // b.usePage(2);
    // b.usePage(3);
    b.usePage(20);
    b.usePage(31);

    b.bubbleDown(0);
    b.graphviz();

    std.debug.print("{?}\n", .{b.sum_tree});

    for (0..b.sum_tree.len) |i| {
        std.debug.print("node {}: {?}\n", .{ i, b.sum_tree.get(i) });
    }

    for (0..b.pages.len) |i| {
        std.debug.print("page {}: {b:0>8}\n", .{ i, b.pages[i] });
    }

    // const alloc = b.allocator();
    // _ = alloc.alloc(u8, 16) catch unreachable;

    // var al = std.ArrayList(u8).init(alloc);
    // defer al.deinit();
    //
    // for (0..8) |i| {
    //     const j: u8 = @intCast(i % 256);
    //     al.append(j) catch @panic("Whoops");
    // }

    // std.debug.print("{}, {any}", .{ b, buffer });
}
