# ghūl core library

The base class library for ghūl programs on the WebAssembly target, as
ghūl source. On .NET a program's strings, collections, exceptions and
console come from the .NET base class library; on WasmGC none of that
exists, so it is supplied here and compiled into the program.

A type GHUL.md documents under a ghūl name, in `Ghul`, `Collections`,
`Text` or `IO`, carries that name, settled in
[ghul-lang/ghul#3230](https://github.com/ghul-lang/ghul/issues/3230); a .NET
type that ghūl does not rename, such as `System.Guid` or
`System.Reflection.FieldInfo`, is declared under its .NET name and namespace.
Either way these are the names a .NET program uses too, so one program
compiles for both targets unchanged. The built-in types themselves — the scalars,
`object`, `string`, the array, function and tuple shapes — are
constructed by the compiler under `--target wasm`; this library reopens
them with `partial` blocks to give them their members, and declares
everything else outright.

This is the hello-world tier: declarations whose bodies throw
`Ghul.NotImplementedException`, enough for a program that writes lines,
iterates an array and throws an exception to pass every front-end pass
under `--target wasm`. Real bodies arrive tier by tier, as the backend
gives tests something to run ([ghul-lang/ghul#3224](https://github.com/ghul-lang/ghul/issues/3224)).

## Purity

A member mirroring a .NET member the compiler trusts as store-free is declared `pure`, so a
narrowed value survives a call to it on every target as it does on .NET. Where .NET trusts only
the member's own body and holds overrides to nothing, the member is marked
`@trusted_store_free()` instead.

## Layout

- `ghul-project.json` — the library manifest (#3212 shape): name, targets,
  sources. Nothing reads it yet; the `ghul` tool that will (#3211)
  consumes the library from Git as source (#3179)
- `src/` — one file per type, plus `intrinsics.ghul`, the operators on the
  built-in types, kept in step with ghul-runtime's
  and `comparison.ghul`, the scalar types' `Equatable` and `Comparable`
- `tests/hello` — the program the library exists to compile
- `tests/type-error` — a program whose one type error must report
  against the library's declarations
- `tests/operators` — a program using the scalar operators
- `tests/comparison` — `=~` and the relational operators over each scalar
  type
- `tests/decimal` — `=~`, ordering and arithmetic on `decimal`
- `tests/ranges` — the `..` and `::` operators and the range types they
  produce
- `tests/maybe` — `MAYBE` and `KEY_VALUE_PAIR`
- `tests/math` — `Math`'s constants and functions, against .NET's values
- `tests/random` — `RANDOM`: a seed fixes the sequence, and every value is in range
- `tests/list` — `LIST` and the list traits
- `tests/map` — `MAP`, `SET` and the map and set traits, and finding
  elements of a `LIST` by `=~`
- `tests/stack-queue` — `STACK`, `Queue`, the set operations on `SET`,
  and a `KEY_VALUE_PAIR` destructured by position
- `tests/float_text` — `to_string` on `double` and `single`
- `dotnet-tests/float_text_dotnet` — the floating-point formatter compiled for .NET
  and checked against .NET's own text for boundary values and random bit
  patterns
- `tests/number_format` — the numeric types' `to_string(format)` on the wasm target,
  against the text .NET writes for the same calls
- `dotnet-tests/number_format_dotnet` — the numeric formatter compiled for .NET and
  checked against .NET's own text for fixed and random values of every
  magnitude, under every format the formatter covers
- `tests/list_sort` — `LIST.sort` with a comparer and with a comparison function
- `tests/list_members` — `LIST`'s sort, reverse and range members, and the scalar
  `Math` members, against .NET's output
- `dotnet-tests/sort_dotnet` — the sort compiled for .NET and checked against
  .NET's `List.Sort` for where it leaves elements the comparer calls equal
- `tests/self-host-members` — the members the compiler's own source uses: `string.format`,
  `replace_line_endings`, `ulong` parsing, `char.is_symbol`, `MutableList`'s `contains` and
  `remove`, `Ghul.Flags` and `LAZY`
- `tests/float-bits` — `double.to_bits` and `single.to_bits`, against the values .NET's
  `BitConverter` gives
- `tests/exception-constructors` — `Exception()` and `NotImplementedException()` with no
  message
- `tests/pure-lookups` — a field narrowed by a presence test stays narrowed across
  `contains`, `index_of` and `contains_key`
- `tests/pure-strings`, `tests/pure-paths`, `tests/pure-object`, `tests/pure-collections` and
  `tests/pure-writers` — the same, across splitting and trimming, path resolution, `get_type`, the
  collection reads and the console writes
- `tests/bigint` — bigint's operators and members, each a host operation on the
  host's BigInt, against the text .NET prints for the same program
- `tests/bigint_conversions` — `cast` between bigint and the scalars, bigint under
  numeric formats and reached as `object`, and division by zero, against
  .NET's text
- `tests/string-builder-large` — a builder and a string built from characters
  holding hundreds of thousands of code units, which must stay cheap to build and
  edit
- `tests/string_members` — the string members: search, trim, split, replace,
  padding, casing and comparison
- `tests/string_hash` — strings that are `=~` hash alike, and a union with a
  string field compared by its contents
- `tests/std_writers` — standard output and standard error written through
  `IO.Std` and through its `out` and `error` writers
- `tests/standard-input` — standard input read a line, a character and the
  rest at a time through `IO.Std` and its `in` reader
- `tests/file-system` — `Path` against .NET's answers, and `File` and
  `Directory` answering as an empty file system that cannot be changed
- `tests/tuples` — tuple elements read by position and by name, and a
  tuple destructured
- `tests/tuple-hash` — tuples hash by their elements, and a set and a map keyed
  by tuples find what was put in them
- `tests/exceptions` — the exceptions the compiler makes or catches on the
  wasm target, each with the constructor it uses
- `tests/display` — `$`, `inspect` and interpolation over records, union
  variants, tuples, sequences and a `Displayable`, as .NET writes them
- `tests/environment` — a program reading, writing and removing variables
  through its `Ghul.Environment`
- `tests/arguments` — a program reading the command-line arguments it was
  run with
- `tests/dotnet-members` — the numeric types' ranges and floating-point special
  values, ASCII and surrogate classification, `string.concat`, a builder made
  from a string, `uint.parse` and `Math.div_rem`, against .NET's output
- `tests/async-surface` — the state machine, awaiter and exception types an
  asynchronous function's lowering uses, driven by hand, and the interval clock
- `tests/tasks` — asynchronous functions returning `Tasks.TASK` and
  `Tasks.TASK[T]`, awaits on yields, delays and other tasks, a `TASK[int]`
  awaited through a `TASK`, failures through `await` and through `result`,
  and the task combinators
- `tests/disposable` — `use` over a class of the program's own, an iterator and
  a reader, disposing in reverse order and when an exception leaves the block

Each test directory is a ghul-cli project whose `ghul-project.json` takes
ghul-core from this checkout (`"path": "../.."`), so the program compiles
against the library's own sources as a user's wasm build would, with the
pinned ghul-runtime after it. Beside it are expectation files for what the
compiler should say and what the program prints. A test that builds runs
under Node. Where the wasm
target cannot yet compile what a test exercises, its expectation is the
diagnostic that says so, and a comment in the test names what it waits for.

## Tasks

`Tasks.TASK` and `Tasks.TASK[T]` are the task model of the targets with no
.NET base class library. `TASK[T]` extends `TASK`, as .NET's `Task<TResult>`
extends `Task`, and hides its awaiter so that awaiting a `TASK[T]` gives its
result. Awaiting it as a `TASK` gives nothing.

There is one thread, so nothing runs concurrently. A continuation is queued
when what it waits for completes, and the queue runs only when something
waits, through `result` or `wait`. Waiting runs queued work, and completes
`delay`s as the host's monotonic clock reaches them, until the task
completes. A wait nothing can satisfy, with no work queued and no delay
pending, throws `Ghul.InvalidOperationException` rather than hanging. A
task that threw throws `Ghul.AggregateException` holding the exception from
`result` and `wait`, and the exception itself from `await`, as on .NET.

The library declares what the compiler's lowering of an asynchronous function
and the common task members need: `completed_task`, `from_result`,
`from_exception`, `delay`, `yield`, `run`, `when_all`, `continue_with`,
`configure_await` and `TaskExtensions.unwrap`.

## Testing

```sh
dotnet tool restore
dotnet ghul-test tests                 # each project for the first target it lists
dotnet ghul-test --config llvm tests  # each project that lists llvm, as a native executable
dotnet ghul-test --config dotnet dotnet-tests  # the library's code compiled for .NET and checked against .NET's own
```

The tests in `dotnet-tests` are .NET SDK projects, because ghul-cli does not
build for .NET: each compiles part of the library's own source on .NET and
compares what it does with .NET's. `float_text_dotnet` checks the
floating-point formatter's text for boundary values and random bit patterns,
`number_format_dotnet` the numeric format strings, and `sort_dotnet` the sort.

The configurations are in `ghul-test.json`. Each project builds with the newest
installed `ghul.compiler`, which ghul-cli installs if there is none, and an
llvm build links with the ghul-llvm release ghul-cli fetches for it.

A test's manifest lists the targets it passes on. A test that does not yet
build for llvm leaves llvm out, and the gaps that keep it out are tracked on
[ghul-lang/ghul#3460](https://github.com/ghul-lang/ghul/issues/3460); it
goes back in when they close.

The type-error test passes when the error names
the member and its place.

## The loader

`host/loader.mjs` runs a compiled program: it provides the host operations this
library declares with `@intrinsic("host.*")`, loads the module beside it, and
reports its exit status. The compiler is given it with `--wasm-loader` and
writes it beside each module it builds, so the loader a program runs under is
the one from the core it was compiled with.
