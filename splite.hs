import System.IO
import System.Environment
import System.Directory
import Data.List 
import Data.Char

main = do
    fileName <- getArgs
    let fistName = head fileName
    content  <- readFile fistName
    let newContent = unlines . map (concat . map countAdd . spliteBy) $ lines content

    (tempName, tempHandle) <- openTempFile "." "txt"
    hPutStr tempHandle newContent
    hClose tempHandle
    removeFile fistName
    renameFile tempName fistName


spliteBy :: String -> [String]
spliteBy xs
    | xs == [] = [[]]
    | head xs == '#' = ('#':(g . tail $ xs)):(spliteBy . f . tail $ xs)
    | otherwise = (g xs):(spliteBy . f $ xs)

countAdd :: String -> String
countAdd xs
    | xs == [] = []
    | xs == "#" = "#"
    | head xs == '#' = case digit of "" -> xs
                                     otherwise -> concat ["#", result, left] 
    | otherwise = xs
    where result  = show ((read digit) + 1)
          left    = dropWhile isDigit.tail $ xs
          digit   = fst.span isDigit.tail $ xs

g :: String -> String
g = fst . span (/= '#')

f :: String -> String
f = snd . span (/= '#')
