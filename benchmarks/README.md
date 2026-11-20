# Benchmarks: the core library on llvm against .NET

One ghūl program, built twice from the same sources. On .NET its strings,
collections and text come from the .NET base class library. On llvm they come
from `ghul-core`, compiled into the program at `--optimise 2`. Comparing the
two times shows where the core library is slower than the BCL it stands in
for.

```sh
benchmarks/run.sh --check                # build both, compare every checksum, no timing
benchmarks/run.sh                        # build both and time every benchmark
benchmarks/run.sh list_sort map_iterate  # time only these
benchmarks/run.sh --no-build --scale 0.1 --repeats 3
```

Timings are only worth anything on a quiet machine.

## How a benchmark is timed

`run.sh` starts a separate process for each benchmark on each target, so a
benchmark run earlier can't change what a later one measures, for example by
leaving a .NET call site polymorphic. Within that process, the benchmark runs
once untimed as a warm-up, then `--repeats` times on the clock, all at the same
size. The default of 15 repeats is enough for .NET's tiered compilation to
settle, so the median is a steady-state time; with fewer repeats .NET medians
can include runs from before the JIT optimised the code. The table gives the fastest and the median time on each target, the
ratio of llvm's median to .NET's (below 1 means llvm is faster), and whether
both targets computed the same checksum.

Each benchmark returns a checksum of what it computed. The checksum makes sure
the work is actually done, and it also checks correctness: two targets that
disagree on a checksum are not running the same program. A benchmark whose
answer can legitimately differ between targets uses a coarse checksum. These
are `math_functions` (the last bit of `sin` and `log`) and `string_hash` (the
hash function itself).

A checksum alone doesn't stop the llvm optimiser removing an allocation it can
prove unused and reducing the loop around it to arithmetic. A benchmark that
measures allocation hands each object it allocates to `Sink.keep`
(`src/harness.ghul`), which keeps it reachable.

## Families

| family | file | covers |
|---|---|---|
| collections | `src/collections.ghul` | `LIST` (add, index, iterate, sort, `index_of`, insert and remove), `MAP` with int and string keys (insert, lookup, iterate, remove), `SET`, `STACK` and `QUEUE` |
| strings | `src/strings.ghul` | `index_of` (string and char), `substring`, `=~`, ordinal compare, hashing, interpolation, `concat`, `split` and `join`, `replace`, case conversion, character reads, `StringBuilder`, and int and double to and from text |
| pipes | `src/pipes.ghul` | `filter`, `map`, `sum` and `reduce` over ranges and lists, building a list, `take` and `skip`, `zip`, `sort`, `join`, short chains (the cost of setting up a chain), comprehensions, generators |
| numeric | `src/numeric.ghul` | int, long and double loops, `sqrt`, `sin` and `log`, a sieve, matrix multiplication over a `LIST`, `bigint` |
| objects | `src/objects.ghul` | allocation (small objects, linked lists, binary trees), a list of structs, virtual, trait, generic and closure calls, closure creation, `case` over a union, optional chains, exceptions, type tests |

A benchmark's size is the size one run uses at `--scale 1`. `--scale`
multiplies every size. Most benchmarks scale linearly with their size.
`matrix_multiply` (n × n) grows as the cube of its size and `list_index_of` as
the square, so keep the scale near 1 when timing those.

## Adding a benchmark

Write a function `(n: int) -> long` in the right family's file and register it
in that file's `register_` function. Its checksum has to be the same on both
targets. For pseudo-random input, use `Lcg` rather than `Random`, which isn't
the same sequence on every target. Then run `run.sh --check`.

`decimal` is not covered. It doesn't compile on llvm yet: the lowering does
not produce `decimal` values.
