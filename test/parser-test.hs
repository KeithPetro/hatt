module Main (main) where

import Data.Logic.Propositional

import Test.Framework as TF (defaultMain, testGroup, Test)
import Test.Framework.Providers.HUnit (testCase)
import Test.HUnit.Base

main :: IO ()
main = defaultMain tests

assertParsed :: String -> Expr -> TF.Test
assertParsed toParse expected = testCase ("parse: " ++ toParse) $ either
    (assertFailure . show)
    (assertEqual "parser failed" expected)
    (parseExpr "" toParse)

tests :: [TF.Test]
tests = [ testGroup "Parser tests"
            [ assertParsed "p" p
            , assertParsed "(p)" p
            , assertParsed "((p))" p
            , assertParsed "~p" (neg p)
            , assertParsed "(~p)" (neg p)
            , assertParsed "((~p))" (neg p)
            , assertParsed "p & q" (p `conj` q)
            , assertParsed "(p & q)" (p `conj` q)
            , assertParsed "p & ~q" (p `conj` neg q)
            , assertParsed "p & (~q)" (p `conj` neg q)
            , assertParsed "(p & (~q & ~r))" (p `conj` (neg q `conj` neg r))
            , assertParsed "(p <-> q)" (p `iff` q)
            , assertParsed "p -> (q & ~r)" (p `cond` (q `conj` neg r))
            ]
        ]
  where
    neg  = Negation
    conj = Conjunction
    iff  = Biconditional
    cond = Conditional
    var  = Variable . Var
    p    = var 'p'
    q    = var 'q'
    r    = var 'r'