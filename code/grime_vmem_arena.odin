/*
Odin's virtual arena allocator doesn't do what I ideally want for allocation resizing or growing from a large vmem reserve.

So this is a simple virtual memory backed arena allocator designed
to take advantage of one large contigous reserve of memory.
With the expectation that resizes with its interface will only occur using the last allocated block.
*/
package sectr


