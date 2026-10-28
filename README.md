# ghūl compiler runtime library

[![CI/CD](https://img.shields.io/github/actions/workflow/status/ghul-lang/ghul-runtime/cicd.yml?branch=main)](https://github.com/ghul-lang/ghul-runtime/actions/workflows/cicd.yml?query=branch%3Amain)
[![NuGet version (ghul.runtime)](https://img.shields.io/nuget/v/ghul.runtime.svg)](https://www.nuget.org/packages/ghul.runtime/)
[![Release](https://img.shields.io/github/v/release/ghul-lang/ghul-runtime?label=release)](https://github.com/ghul-lang/ghul-runtime/releases)
[![Release Date](https://img.shields.io/github/release-date/ghul-lang/ghul-runtime)](https://github.com/ghul-lang/ghul-runtime/releases) 
[![Issues](https://img.shields.io/github/issues-search/ghul-lang/ghul?query=is%3Aopen%20is%3Aissue%20label%3Aghul-runtime&label=issues)](https://github.com/ghul-lang/ghul/issues?q=is%3Aopen+is%3Aissue+label%3Aghul-runtime) 
[![License](https://img.shields.io/github/license/ghul-lang/ghul-runtime)](https://github.com/ghul-lang/ghul-runtime/blob/main/LICENSE)
[![ghūl](https://img.shields.io/badge/gh%C5%ABl-100%25!-information)](https://ghul.dev)

This package provides: 
- internal types required by all [ghūl](https://ghul.dev) applications
- support for the ghūl pipe operator and fluent methods on pipes, such as `filter`, `map` and `reduce`
- `slice`, which takes part of an array, list or string: `xs |> slice(1..4)`. An array or a list is sliced without copying, so a later change to the source shows through
- function combinators, in `Ghul` (reached with `use Ghul`): `f >> g` composes left to right and `f << g` right to left, keeping the multi-argument stage's own arity - `add >> tag` composes a two-argument `add` with a unary `tag` and calls it as `tagged(4, 5)`; `curry` and `uncurry` reshape a two-argument function in either direction; `memo(f)` answers from a cache of the results `f` has already computed, keyed on the whole argument tuple; `memo_rec(f)` does the same for a recursive function, handing `f` the memoised function to make its recursive calls through, so every level is cached - `memo_rec((fib, n: int) => if n < 2 then bigint(n) else fib(n - 1) + fib(n - 2) fi)`; and `apply(f, x, y)` calls a function of any arity with the arguments of the call itself
- number theory, in `Ghul.Numerics` over `int`, `long` and `bigint` alike: `is_prime`, an unbounded `primes()` stream (or `primes(from)`), `prime_factors` and `factorize`, `divisors`, `divisor_count`, `divisor_sum`, `totient`, `gcd`, `lcm`, `factorial`, `binomial`, `mod_pow`, `isqrt`, `is_square` and `digit_sum`. Primality is exact for `int` and `long`, and the Baillie-PSW test, which has no known counterexample, above that; results that don't fit the type throw `System.OverflowException`
- `retry(f, attempts)` calls f, retrying the whole call up to the given number of times when it throws and throwing the last failure when every attempt does; the wrapped function keeps f's own arity
- `Ghul.Coroutines`, cooperative coroutines: asynchronous functions returning `COROUTINE[T]` or `COROUTINE`, which one coroutine awaits as it would call a function. `pause()` gives up the turn, `sleep(milliseconds)` gives it up until a deadline, `run()` resumes parked coroutines one at a time, `CHANNEL[T]` hands values between them, and `MUTEX` and `SEMAPHORE` guard what they share. All of it runs on one thread, on a default `SCHEDULER` unless one is named. A coroutine can also await a task or any other awaitable: `run()` waits for it and resumes the coroutine on its own thread. Where that thread cannot block, such an await is reported as an error
- MSBuild targets needed to build ghūl projects

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
`ghul-core/` is the source core library, which supplies on the wasm and llvm
targets the types .NET supplies on the other; it is not compiled on .NET, and
was brought here from [ghul-core](https://github.com/ghul-lang/ghul-core), which
this repository supersedes. Each tree carries its own `ghul-project.json`, so a
ghul-cli project can depend on either by path, and the manifest at the
repository's root covers both trees' sources: the single `ghul-runtime`
library a version or tag dependency resolves carries the whole compilation
unit. The .NET package is unaffected - `ghul-runtime.ghulproj` globs only the
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
