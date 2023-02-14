# megasplit
Just another split wrapper with some sugar

Chunks will be named as follows:

original_name.partn-N

where n is chunk position and N is total chunks.

In parallel, a sha1 hash of the original file is created.

Optionally, the original file can be deleted after splitting.
