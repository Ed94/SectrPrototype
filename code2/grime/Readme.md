# Grime

This is a top-level package to adjust odin to my personalized usage.

I curate all usage of odin's provided package definitons through here. The client and host packages should never directly import them.

There are no implicit static allocations in Grime. Ideally there are also none from the base/core packages but some probably leak.
