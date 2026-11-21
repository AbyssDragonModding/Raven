# What the Zig layer does not map yet

Written by tools/bindgen/gen_zig_wrapper.py: do not edit. Each line is a
function, a field or a table entry the generator could not make idiomatic.
The API is still whole: these functions take and return the types of
`raven.c`. To map one, add what it needs to the tables at the top of
gen_zig_wrapper.py (HANDLE_PARAMS, RETURNS, OVERRIDES...) and run
`python tools/bindgen/bindgen.py`.

Nothing: every function, structure and callback is mapped.
