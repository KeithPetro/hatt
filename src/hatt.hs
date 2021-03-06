{-# LANGUAGE DeriveDataTypeable #-}

module Main (main) where

import Data.Logic.Propositional
import Data.Logic.Propositional.Tables
import Data.Logic.Propositional.NormalForms

import Control.Monad (when, unless)
import Data.Char (toLower)
import System.Console.CmdArgs
import System.Console.Haskeline
    ( InputT
    , runInputT
    , defaultSettings
    , getInputLine
    , outputStr
    , outputStrLn
    )

data Command = Exit
             | Help
             | Pretty
             | Coloured
             | Eval Expr
             | Convert NormalForm Expr
             | Error String

data ProgramMode = ProgramMode
  { evaluate    :: String
  , interactive :: Bool
  , pretty      :: Bool
  , coloured    :: Bool
  } deriving (Show, Data, Typeable)

data NormalForm = NNF | CNF | DNF

programMode :: ProgramMode
programMode = ProgramMode
  { evaluate    = "" &= typ  "EXPRESSION"
                     &= help "Print the truth table for the given expression"
  , interactive = False &= help "Enter interactive mode"
  , pretty      = False &= help "Use Unicode logic symbols"
  , coloured    = False &= help "Use colour-coded symbols"
  } &= summary "Hatt 1.6.0.0, (c) Benedict Eastaugh 2012"
    &= program "hatt"

main :: IO ()
main = do opts <- cmdArgs programMode
          let expStr    = evaluate opts
              interMode = interactive opts
              evalMode  = (not . null) expStr
              printer   = selectPrinter opts
          
          -- If the --evaluate flag is passed with an expression, print the
          -- truth table for that expression.
          when evalMode $ putStr (eval printer expStr)
          
          -- Unless the --evaluate flag is passed with an expression and
          -- interactive mode is NOT explicitly requested, terminate the
          -- program; otherwise, enter interactive mode.
          unless (evalMode && not interMode) $
              putStrLn replIntroText
              >> runInputT defaultSettings (repl opts)

repl :: ProgramMode -> InputT IO ()
repl mode = do
    minput <- getInputLine "> "
    case minput of
      Nothing  -> return ()
      Just cmd -> case parseCommand cmd of
        Exit              -> return ()
        Help              -> outputStr (replHelpText printer)
                             >> repl mode
        Pretty            -> outputStrLn ppMessage
                             >> repl (mode {pretty = not isPretty})
        Coloured          -> outputStrLn cpMessage
                             >> repl (mode {coloured = not isColoured})
        (Eval expr)       -> outputStr (truthTableP printer expr)
                             >> repl mode
        (Convert nf expr) -> outputStrLn (toNFStr nf (fst printer) expr)
                             >> repl mode
        (Error err)       -> outputStrLn ("Error: " ++ err)
                             >> repl mode
  where
    printer    = selectPrinter mode
    isPretty   = pretty mode
    isColoured = coloured mode
    ppMessage  = (if isPretty then "Dis" else "En") ++ "abling pretty-printing."
    cpMessage  = (if isColoured then "Dis" else "En") ++ "abling colour-coding."

eval :: Printer -> String -> String
eval p str = case parseExpr "" str of
               Left  err  -> "Parse error at " ++ show err ++ "\n"
               Right expr -> truthTableP p expr

parseCommand :: String -> Command
parseCommand input = case cmd . words $ input of
                       ""       -> Error "you must enter an expression or a command."
                       "exit"   -> Exit
                       "help"   -> Help
                       "pretty" -> Pretty
                       "colour" -> Coloured
                       "nnf"    -> eval_ (Convert NNF) (getExpr input)
                       "cnf"    -> eval_ (Convert CNF) (getExpr input)
                       "dnf"    -> eval_ (Convert DNF) (getExpr input)
                       _        -> eval_ Eval input
  where
    cmd []       = ""
    cmd ws       = map toLower . head $ ws
    eval_ dt str = case parseExpr "hatt" str of
                     Left  err  -> Error $ "parse error at " ++ show err
                     Right expr -> dt expr
    getExpr      = unwords . tail . words

toNFStr :: NormalForm -> (Expr -> String) -> Expr -> String
toNFStr NNF p = p . toNNF
toNFStr CNF p = p . toCNF
toNFStr DNF p = p . toDNF

replIntroText :: String
replIntroText = unwords
  [ "Entering interactive mode."
  , "Type `help` if you don't know what to do!"
  ]

replHelpText :: Printer -> String
replHelpText printer = unlines
  [ "Hatt's interactive mode has several commands."
  , ""
  , "help"
  , "  Print this help text."
  , ""
  , "pretty"
  , "  Pretty-print expressions using Unicode logic symbols. Only employ this"
  , "  option if your console is Unicode-aware. If pretty-printing is already"
  , "  enabled, using this command will disable it."
  , ""
  , "colour"
  , "  Colour truth values: green for true, red for false. This feature needs"
  , "  your console to support ANSI colour codes. If coloured mode is already"
  , "  enabled, this command will disable it."
  , ""
  , "exit"
  , "  Quit the program."
  , ""
  , "If you don't type in a command, the program will assume you're writing a"
  , "logical expression to be evaluated and attempt to parse it."
  , ""
  , "For example, if you enter \"p -> q\" at the prompt, Hatt will print the"
  , "truth table for that expression. Here's an example console session."
  , ""
  , "    > " ++ showAscii exp1
  , indentBy 4 $ truthTableP printer exp1
 ++ "> " ++ showAscii exp2 ++ "\n"
 ++ truthTableP printer exp2
  , "You can also convert expressions to different normal forms: negation"
  , "normal form, conjunctive normal form and disjunctive normal form. To do"
  , "this just prepend the expression you want to convert with \"nnf\", \"cnf\""
  , "or \"dnf\". For example,"
  , ""
  , "    > nnf " ++ showAscii exp3
  , "    " ++ (fst printer . toNNF) exp3
  , ""
  , "If none of this makes any sense, try reading the README file."
  ]
  where
      exp1 = Disjunction (Variable $ Var 'a') (Variable $ Var 'b')
      exp2 = Conditional (Variable $ Var 'p') exp4
      exp3 = Negation exp2
      exp4 = Conjunction (Variable $ Var 'q') (Variable $ Var 'r')

selectPrinter :: ProgramMode -> Printer
selectPrinter m = let expPrinter   = if pretty m then show else showAscii
                      tablePrinter = if coloured m then colourBool else showBool
                  in (expPrinter, tablePrinter)

indentBy :: Int -> String -> String
indentBy n = unlines . map (replicate n ' ' ++) . lines
