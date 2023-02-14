# megasplit
Just another split wrapper with some sugar

1. Progressbar

2. Chunks will be named as follows:
- original_name<b>.partn-N</b>
- where **n** is chunk position and **N** is total chunks.

3. In parallel, a sha1 hash of the original file will be created.

4. Optionally, the original file can be deleted after splitting.
