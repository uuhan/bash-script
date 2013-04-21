#!/usr/bin/runhaskell
import System.IO
import System.Directory
import System.Environment
import Data.List
import Control.Monad

main = do
    (deleteList:fileName) <- getArgs
    forM_ fileName (\a -> do
        content <- readFile a
        let n          = read  lineNumber - 1
        let conTent    = lines content
        let contentNew = unlines $ delete  (conTent !! n) conTent

        (tempName, tempHandle) <- openTempFile "." "txt"
        hPutStr tempHandle contentNew
        hClose tempHandle
        removeFile a
        renameFile tempName a)
