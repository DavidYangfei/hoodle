{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Hoodle.Manage where

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Logger (MonadLogger(..))
import Control.Monad.Trans.Control (MonadBaseControl(..))
import Control.Monad.Trans.Resource (MonadResource(..))
import Data.Conduit (($$))
import Data.Conduit.List as CL
import Data.Text (Text)
-- import Data.Text.Encoding (decodeUtf8, encodeUtf8)
-- import Data.UUID
-- import Data.UUID.V4 
import Database.Esqueleto
import Database.Persist.Sqlite (runSqlite, runMigrationSilent)
import Database.Persist.TH (mkPersist, mkMigrate, persistLowerCase, share, sqlSettings)
import Database.Persist.Sql (rawQuery)
-- 
import Hoodle.Manage.Type.UUID

share [mkPersist sqlSettings, mkMigrate "migrateTables"] [persistLowerCase|
  HoodleFile 
    uuid     UUID
    md5hash  Text    
    location Text
    deriving Show
|]

-- sqlite

maintest :: IO () 
maintest = 
  runSqlite ":memory:" $ do 
         buildDB
         liftIO (putStrLn "dump hoodle")
         dumphdl
      {-   liftIO (putStrLn "dump author")
         dumpAuthor
         liftIO (putStrLn "test esqueleto")
         tuts <- select $ from $ \(a,t) -> do
                   where_ ( a ^. AuthorEmail ==. val "ann@example.com" &&. t ^. TutorialAuthor ==. a ^. AuthorId)
                   return t
         liftIO $ print tuts -}
                 
buildDB :: (Monad m, MonadLogger m, MonadIO m, MonadResource m, MonadBaseControl IO m) => 
           SqlPersistT m (Key (HoodleFileGeneric SqlBackend))
buildDB = do
    runMigration migrateTables
    uuid <- liftIO $ nextRandom
    insert $ HoodleFile uuid "testtttt" "file://url.com/file.hdl"

dumphdl :: (MonadResource m, MonadLogger m) => SqlPersistT m ()
dumphdl = rawQuery "select * from Hoodle_File" [] $$ CL.mapM_ (liftIO . print)

