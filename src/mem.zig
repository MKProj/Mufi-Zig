// Controls memory allocation
const allocator = @import("std").mem.Allocator;
pub fn growCapacity(cap: usize) usize {
    if (cap < 8) {
        return 8;
    } else {
        return cap * 2;
    }
}

