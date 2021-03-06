-- 
-- testing program for attoparsec and sax hoodle parser
-- 

import           Control.Monad
import           Data.Attoparsec 
import qualified Data.ByteString as B
import           System.Environment 
-- 
import Data.Hoodle.Simple
-- 
import Text.Hoodle.Parse.Attoparsec 
-- import Text.Hoodle.Parse.Conduit 
import Graphics.Hoodle.Render
import Graphics.Hoodle.Render.Type
import Graphics.Rendering.Cairo 

-- |  
main :: IO ()   
main = do 
  args <- getArgs 
  when (length args /= 3) $ error "parsertest mode filename (mode = atto/sax) outputfile"  
  if args !! 0 == "atto" 
    then attoparsec (args !! 1) (args !! 2)
    else return () -- sax (args !! 1)
     
     
-- | using attoparsec without any built-in xml support 
attoparsec :: FilePath -> FilePath -> IO () 
attoparsec fp ofp = do 
  bstr <- B.readFile fp
  let r = parse hoodle bstr
  case r of 
    Done _ h -> renderjob h ofp --  print (length (hoodle_pages h))
    _ -> print r 

-- | 
renderjob :: Hoodle -> FilePath -> IO () 
renderjob h ofp = do 
  let p = head (hoodle_pages h) 
  let Dim width height = page_dim p  
  withPDFSurface ofp width height $ \s -> renderWith s $  
    (sequence1_ showPage . map renderPage . hoodle_pages) h 
    
-- | interleaving a monadic action between each pair of subsequent actions
sequence1_ :: (Monad m) => m () -> [m ()] -> m () 
sequence1_ _ []  = return () 
sequence1_ _ [a] = a 
sequence1_ i (a:as) = a >> i >> sequence1_ i as 


{-
-- | using sax (from xml-conduit)
sax :: FilePath -> IO () 
sax fp = do 
  r <- parseHoodleFile fp 
  case r of 
    Left err -> print err
    Right h -> print (length (hoodle_pages h))
-}