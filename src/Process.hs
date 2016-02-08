{-# LANGUAGE OverloadedStrings #-}
module Process
( process
, htmlPipeline
, mdPipeline
, codePipeline ) where
import Prelude hiding (readFile, writeFile)
import Data.Text.IO (writeFile, readFile)
import System.FilePath.Posix (takeFileName, dropExtension, takeExtension)
import System.Directory
import System.FilePath.Posix
import Data.List (intercalate)
import qualified Data.Text as T

import Parse (encode)
import Code
import Html
import Markdown
import Types
process pipes file = do 
    stream <- readFile file
    encoded <- return $ encode stream file
    mapM_ (\f -> f fileName encoded) pipes >> return ()
    where
        fileName = dropExtension $ takeFileName file
htmlPipeline dir mCss name enc = do
    maybeCss <- cssRelativeToOutput dir mCss
    let path = (addTrailingPathSeparator dir) ++ name ++ ".html"
        output = Html.generate maybeCss name enc
    writeFile path output
mdPipeline dir css name enc = writeFile path output
    where
        path = (addTrailingPathSeparator dir) ++ name ++ ".md"
        output = Markdown.generate name enc
codePipeline dir css showLines name enc = writeFile path output
    where
        path = (addTrailingPathSeparator dir) ++ name
        ext = takeExtension name
        output = 
            if showLines 
            then Code.generateWithAnnotation ext enc 
            else Code.generate enc 
cssRelativeToOutput :: String -> Maybe String -> IO (Maybe String)
cssRelativeToOutput output mCss =
    case mCss of
    Nothing -> return Nothing
    Just css -> do
    getCurrentDirectory >>= canonicalizePath >>= \path -> return $ Just $ (join' . helper' . trim' . split') path
    where 
        moves = filter (\str -> str /= ".") $ splitDirectories output
        split' = splitDirectories
        trim'   = trimToMatchLength moves
        helper' = reversePath moves []
        join' path = (intercalate "/" path) </> css

trimToMatchLength list listToTrim = 
    let len1 = length list
        len2 = length listToTrim
    in 
        drop (len2 - len1) listToTrim

reversePath [] solution curPathParts = solution
reversePath (fst:rest) solution curPathParts =
    if fst == ".."
    then reversePath rest ((last curPathParts) : solution) (init curPathParts)
    else reversePath rest (".." : solution) (curPathParts ++ [fst])
