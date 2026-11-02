# ghūl compiler runtime library

[![CI/CD](https://img.shields.io/github/actions/workflow/status/ghul-lang/ghul-runtime/cicd.yml?branch=main)](https://github.com/ghul-lang/ghul-runtime/actions/workflows/cicd.yml?query=branch%3Amain)
[![NuGet version (ghul.runtime)](https://img.shields.io/nuget/v/ghul.runtime.svg)](https://www.nuget.org/packages/ghul.runtime/)
[![Release](https://img.shields.io/github/v/release/ghul-lang/ghul-runtime?label=release)](https://github.com/ghul-lang/ghul-runtime/releases)
[![Release Date](https://img.shields.io/github/release-date/ghul-lang/ghul-runtime)](https://github.com/ghul-lang/ghul-runtime/releases) 
[![Issues](https://img.shields.io/github/issues-search/ghul-lang/ghul?query=is%3Aopen%20is%3Aissue%20label%3Aghul-runtime&label=issues)](https://github.com/ghul-lang/ghul/issues?q=is%3Aopen+is%3Aissue+label%3Aghul-runtime) 
[![License](https://img.shields.io/github/license/ghul-lang/ghul-runtime)](https://github.com/ghul-lang/ghul-runtime/blob/main/LICENSE)
[![ghūl](https://img.shields.io/badge/gh%C5%ABl-100%25!-information)](https://ghul.dev)

## What the library provides

This package is the ghūl runtime library: the types every ghūl program needs, and a set of namespaces of general-purpose functions. `use default` imports `Ghul.Pipes`, `Collections`, `Ghul.Math`, `Ghul.NumberTheory` and `Ghul.Functional`, along with `IO.Std.write_line`; the rest are imported by name. This section is a map of what each area is for. Every public member has a doc comment, which the editor shows on hover, and that is where the detail of each function lives.

### Pipes - `Ghul.Pipes`

Functions over any sequence, joined with `|>`. A stage (`filter`, `map`, `take`, `skip`, `zip`, `sort`, ...) returns a new lazy sequence; a terminal (`sum`, `count`, `first`, `find`, `reduce`, `join`, ...) reads it and produces a value. Sources such as `from`, `repeat` and `stream` make sequences out of values.

```ghul
let total = [1, 2, 3, 4, 5] |> filter(x => x % 2 == 0) |> map(x => x * x) |> sum()
let squares = from(1) |> map(n => n * n) |> take(5) |> list()
```

### Collections - `Collections`

`LIST`, `MAP`, `SET` and `ARRAY`, each built from any sequence, and `list()`, which gives a sequence as a read-only list filled as it is read.

```ghul
let lengths = ["one", "three"] |> map(w => (w, w.length)) |> MAP()
let seen = [3, 1, 3] |> SET()
```

### Text by character - `runes`, `graphemes`, `slice`

`runes` reads a string by Unicode code point and `graphemes` by what a reader sees as one character, so a letter with its accents, an emoji sequence or a flag is one element. `slice` takes part of an array, a list or a string; an array or a list is sliced without copying.

```ghul
let middle = graphemes("héllo") |> list() |> slice(1..4) |> string()
```

### Maths - `Ghul.Math`

The maths functions and constants, the same on .NET, wasm and llvm: rounding, powers and roots, logarithms, trigonometry, the floating-point predicates, and `abs`, `min`, `max` and `clamp` over the numeric types.

```ghul
let distance = sqrt(3.0 * 3.0 + 4.0 * 4.0)
let quarter = pi / 2.0
```

### Number theory - `Ghul.NumberTheory`

Primes, factorization and the integer functions built on them, over `int`, `long` and `bigint` alike. The prime functions share one sieve that grows on demand, so they are not safe to call from more than one thread at a time.

```ghul
let first_primes = primes() |> take(10) |> list()
let factors = factorize(360)
```

### Function combinators - `Ghul.Functional`

Functions that build functions: composition with `>>` and `<<`, `curry` and `uncurry`, memoization with `memo` and `memo_rec`, and `retry`.

```ghul
let fib = memo_rec((fib, n: int) => if n < 2 then bigint(n) else fib(n - 1) + fib(n - 2) fi)
let shout = ((s: string) => s.to_upper()) >> (s => "{s}!")
```

### Coroutines - `Ghul.Coroutines`

Cooperative coroutines on one thread. A function that returns `COROUTINE[T]` or `COROUTINE` is a coroutine; one coroutine `await`s another as it would call a function, `pause()` and `sleep(ms)` give up the turn, and `run()` resumes parked coroutines until none remain. `CHANNEL[T]` hands values between coroutines, and `MUTEX` and `SEMAPHORE` guard what they share.

```ghul
use Ghul.Coroutines

square_later(n: int) -> COROUTINE[int] is
    await pause()
    return n * n
si

report() -> COROUTINE is
    write_line("{await square_later(4)}")
si

report()
run()
```

### Results and optional values - `Result`, `MAYBE`

Both are in `Ghul`, imported with `use Ghul`. `Result[T, E]` is the outcome of an operation that produces a `T` or fails with an `E`: `OK` is its default variant, so `result?` asks whether it succeeded and `if let value: Result.OK = result` reads the value. `MAYBE[T]` is a value that may be absent, which `min`, `max` and other terminals return for an empty sequence.

```ghul
use Ghul

let parsed: Result[int, string] = Result.OK(42)
let succeeded = parsed?
let smallest = [3, 1, 2] |> min()
```

### Displaying values - `$`, `inspect`

How a value becomes text. `$(value)` writes it as string interpolation does: a sequence in brackets, a tuple in parentheses, a record as its type and members. `inspect`, in `Ghul`, does the same, with strings and characters inside the value quoted. A type that implements `Displayable` controls its own rendering.

```ghul
use Ghul

write_line("{$((1, "one"))} {inspect([1, 2])}")
```

### JSON - `Json`

A JSON value tree (`Json.Value`), `Json.parse` and `Json.write` to read and write text, and `Json.to_json` and `Json.from_json` to convert between a value tree and the public members of an ordinary object.

```ghul
let doc = Json.parse("[1, 2, 3]")
let text = Json.write(doc)
```

### Processes and the environment - `IO.PROCESS`, `Ghul.Environment`

`IO.PROCESS.run` runs a program and returns its exit code and everything it wrote. `Ghul.Environment`, the type of an `entry` function's `env` parameter, is a live view of the process environment that can also end the process with `exit`.

```ghul
let result = IO.PROCESS.run("git", ["--version"])
write_line("{result.exit_code} {result.output}")
```

### MSBuild targets

The targets a `.ghulproj` needs to build a ghūl library or executable, described under [building a library or an executable](#building-a-library-or-an-executable) below.

## Building a library or an executable

The targets follow the standard `OutputType` property:

- `Library` (the .NET SDK's default when the project does not set one) builds a
  library. It needs no `entry()` function.
- `Exe` or `WinExe` builds an executable, which needs an `entry()` function.

Other values are rejected. To choose directly, regardless of `OutputType`, set
`GhulLibrary` to `true` or `false`.

```xml
<PropertyGroup>
  <OutputType>Library</OutputType>
</PropertyGroup>
```

## Repository layout

This repository holds two source trees. `ghul-runtime/` is the runtime library
itself, built on .NET as the `ghul.runtime` package by `ghul-runtime.ghulproj`.
`ghul-core/` is the core tree, which supplies on the wasm and llvm targets
the types .NET supplies on the other; it is not compiled on .NET. The two
trees are one library: the manifest at the repository's root, the only one,
names both trees' sources as `ghul-runtime`, which a version, tag or path
dependency resolves to. The .NET package is unaffected - `ghul-runtime.ghulproj` globs only the
runtime tree's sources.

## The WebAssembly target

Under `--target wasm` the runtime is compiled from source together with
ghul-core: both trees' `src/**/*.ghul` are compiled whole. A file whose
declarations belong to one target only carries `@@IF.dotnet()` or
`@@IF.source_core()` on its first line — the former compiles only into the
.NET assembly, the latter only on a target whose core library is compiled
from source, WebAssembly and LLVM. Within a file compiled everywhere,
`@IF.dotnet()` and `@IF.source_core()` mark the individual declarations that
belong to one target only. `ghul-runtime/src`'s files that declare types
ghul-core also declares carry the file-level form. What is not yet
available on the wasm target is tracked on
[ghul-lang/ghul#3319](https://github.com/ghul-lang/ghul/issues/3319).

`wasm-tests/` holds programs that build for the wasm target from this
checkout's sources and run under Node, each a ghul-cli project whose
`run.expected` is what the same program prints on .NET. Run them with
`dotnet ghul-test wasm-tests`, and the ones that also build as native
executables with `dotnet ghul-test --config llvm wasm-tests`. A test's manifest
lists the targets it passes on; the gaps that keep the rest off llvm are
tracked on [ghul-lang/ghul#3460](https://github.com/ghul-lang/ghul/issues/3460).

`native-aot-tests/` renders values with `$` under the JIT and published with
Native AOT, where rendering cannot rely on reflection, and checks that both
print its `run.expected`. See its README for how to run it.

## Issues

[View open issues](https://github.com/ghul-lang/ghul/issues?q=is%3Aopen+is%3Aissue+label%3Aghul-runtime) or [raise a new one](https://github.com/ghul-lang/ghul/issues/new?labels=ghul-runtime).
