# tests/negative/

Twelve expected-failure fixtures, run by `lake test`, in two classes.

Six must fail to elaborate: `SorryFixture`, `PrivateSorryFixture`,
`NativeDecideFixture`, `OmittedTokenFixture`, `CoverageFixture` (an
unconsumed, unledgered theorem the coverage gate must reject), and
`SilencingMarkersFixture` (one declaration per gate-silencing marker —
`unsafe`, `partial`, `implemented_by`, `extern`, `nolint` — that the
`silencingMarkers` environment linter must flag; its in-file `#lint` run
is what fails elaboration).

Six compile with at most a warning, and the source-level proof-token
scan must reject them instead: `ExampleSorryFixture`,
`StringSorryFixture`, `CharLiteralSorryFixture`, `SorryAxFixture`,
`StopFixture`, and `NativePlusFixture`. Lean adds no `example` to the
environment, so elaboration-time gates cannot see these. The scanner is
what rejects them, and these fixtures are what keep the scanner honest.

`CharLiteralSorryFixture` is a regression rather than a shape anyone
would write on purpose. A char literal holding a double quote
desynchronized the scanner's string tracking, so everything after it
read as string content and the live `sorry` at the end of the line went
unseen.

These two lists are the ones `TemplateTest/Main.lean` runs, as
`negativeFixtures` and `scannerFixtures`. A fixture added to this
directory must be registered in one of them, or it never runs.
