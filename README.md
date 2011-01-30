Hatt
====

[Hatt] is a command-line program which prints truth tables for expressions in
classical propositional logic, and a library allowing its parser, evaluator and
truth table generator to be used in other programs.


Installation
------------

Hatt is available from [Hackage]. To install it with `cabal-install`, update
your list of known packages and then install Hatt.

    $ cabal update
    $ cabal install hatt

To build it from source, `cd` into the directory containing the Hatt source
files, including `hatt.cabal`, and run `cabal install`.


Valid Hatt expressions
----------------------

The following are all valid expression forms which can be parsed by Hatt, where
ϕ and ψ are metalinguistic variables standing in for any valid expression. The
parser isn't as smart about parentheses as it could be, so you have to follow
these rules quite literally. This shouldn't be a great hardship, but it does
mean that, for example, while `(A -> B)` is a valid expression, `A -> B` isn't.

* Variables: `P`, `Q`, `R` etc.---basically anything in the character class
  `[A-Z]`
* Negation: `~ϕ`
* Conjunction: `(ϕ & ψ)`
* Disjunction: `(ϕ | ψ)`
* Conditional: `(ϕ -> ψ)`
* Biconditional: `(ϕ <-> ψ)`


Using the `hatt` command-line program
-------------------------------------

The `--evaluate` flag lets you pass an expression to be evaluated directly.
Here's an example session doing just that.

    $ hatt --evaluate="(P -> (Q | ~R))"
    P Q R | (P → (Q ∨ ¬R))
    ----------------------
    T T T | F
    T T F | F
    T F T | F
    T F F | F
    F T T | F
    F T F | F
    F F T | T
    F F F | F

Note that while you need to use ASCII symbols to interact with `hatt`, it
pretty-prints expressions using the more common logical symbols. The Hatt
library exposes the `showAscii` function which will print expressions in the
format in which they're entered.


Using Hatt in other programs
----------------------------

Hatt exposes the `Logic.Propositional` module, which provides a simple API for
parsing, evaluating, and printing truth tables.


[Hatt]:          http://extralogical.net/projects/hatt
[Hackage]:       http://hackage.haskell.org/
