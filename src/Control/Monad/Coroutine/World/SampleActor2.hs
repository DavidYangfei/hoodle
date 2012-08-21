{-# LANGUAGE GADTs, NoMonomorphismRestriction, ScopedTypeVariables #-}

----------------------------
-- | describe world object
----------------------------

module Control.Monad.Coroutine.World.SampleActor2 where 

import Control.Applicative
import Control.Category
import Control.Concurrent 
import Control.Monad.Error 
import Control.Monad.Reader
import Control.Monad.State
-- import Data.Lens.Common 
import Control.Lens 
-- 
import Control.Monad.Coroutine
import Control.Monad.Coroutine.Event 
import Control.Monad.Coroutine.Object
import Control.Monad.Coroutine.Queue 
-- 
import Prelude hiding ((.),id)

data JobStatus = None | Started | Ended 
               deriving (Show,Eq)

-- | 
data SubOp i o where 
  GiveEventSub :: SubOp Event ()


-- | full state of world 
data WorldState = WorldState { _jobStatus :: JobStatus
                             , _tempLog :: String -> String 
                             , _tempQueue :: Queue (Either ActionOrder Event)
                             }


-- | isDoorOpen lens
jobStatus :: Simple Lens WorldState JobStatus
jobStatus = lens _jobStatus (\a b -> a { _jobStatus = b })

-- | 
tempLog :: Simple Lens WorldState (String -> String) 
tempLog = lens _tempLog (\a b -> a { _tempLog = b } )

-- | 
tempQueue :: Simple Lens WorldState (Queue (Either ActionOrder Event))
tempQueue = lens _tempQueue (\a b -> a { _tempQueue = b} )


-- | 
emptyWorldState :: WorldState 
emptyWorldState = WorldState None id emptyQueue 


type WorldObject m r = ServerObj SubOp (StateT (WorldAttrib m) m) r 

-- | full collection of actors in world 
data WorldActor m 
    = WorldActor { _objWorker :: WorldObject m () 
                 } 


-- | objWorker lens
objWorker :: Simple Lens (WorldActor m) (ServerObj SubOp (StateT (WorldAttrib m) m) ())
objWorker = lens _objWorker (\a b -> a { _objWorker = b })


-- makeLenses [''WorldActor]

-- | 
initWorldActor :: (Monad m) => WorldActor m 
initWorldActor = WorldActor { _objWorker = worker
                            }

-- | 
data WorldAttrib m =
       WorldAttrib { _worldState :: WorldState
                   , _worldActor :: WorldActor m } 

-- makeLenses [''WorldAttrib]


-- | lens
worldState :: Simple Lens (WorldAttrib m) WorldState
worldState = lens _worldState (\a b -> a {_worldState = b})

-- | lens 
worldActor :: Simple Lens (WorldAttrib m) (WorldActor m)
worldActor = lens _worldActor (\a b -> a {_worldActor = b})



-- | initialization   
initWorld :: (Monad m) => WorldAttrib m 
initWorld = WorldAttrib emptyWorldState initWorldActor





-- |
giveEventSub :: (Monad m) => Event -> ClientObj SubOp m () 
giveEventSub ev = request (Input GiveEventSub ev) >> return ()



-- |
worker :: (Monad m) => ServerObj SubOp (StateT (WorldAttrib m) m) ()
worker = ReaderT workerW 
  where workerW (Input GiveEventSub ev) = do 
          r <- case ev of 
                 Start -> do 
                   let action = Left . ActionOrder $ 
                                  \evhandler -> do 
                                    forkIO $ do threadDelay 10000000
                                                putStrLn "BAAAAAMM"
                                                evhandler Finished
                                    return ()
                   modify (worldState.tempQueue %~ enqueue action)
                   modify (worldState.jobStatus .~ Started)
                   return True
                 Finished -> do 
                   modify (worldState.jobStatus .~ Ended)
                   return True 
                 Render -> do 
                   st <- (^. worldState.jobStatus) <$> get 
                   modify (worldState.tempLog %~ (. (++ "job status = " ++ show st ++ "\n")))
                   return True
                 _ -> return False 
          req <- if r then request (Output GiveEventSub ())
                      else request Ignore 
          workerW req 
          
                    

