{-# LANGUAGE QuasiQuotes #-}

-----------------------------------------------------------------------------
-- |
-- Module      : Hoodle.GUI.Menu 
-- Copyright   : (c) 2011, 2012 Ian-Woo Kim
--
-- License     : BSD3
-- Maintainer  : Ian-Woo Kim <ianwookim@gmail.com>
-- Stability   : experimental
-- Portability : GHC
--
-- Construct hoodle menus 
--
-----------------------------------------------------------------------------

module Hoodle.GUI.Menu where

-- from other packages
import           Control.Category
import           Data.Maybe
import           Graphics.UI.Gtk hiding (set,get)
import qualified Graphics.UI.Gtk as Gtk (set)
import           System.FilePath
import           System.IO 
-- from hoodle-platform 
-- import           Control.Monad.Trans.Crtn.EventHandler
import           Data.Hoodle.Predefined 
-- from this package
import           Hoodle.Coroutine.Callback
import           Hoodle.Type
import           Hoodle.Type.Clipboard
-- import           Hoodle.Util.Verbatim
--
import Prelude hiding ((.),id)
import Paths_hoodle_core

-- | 

justMenu :: MenuEvent -> Maybe MyEvent
justMenu = Just . Menu 

-- | 
-- uiDecl :: String 
-- uiDecl = [verbatim|
-- |]

iconList :: [ (String,String) ]
iconList = [ ("fullscreen.png" , "myfullscreen")
           , ("pencil.png"     , "mypen")
           , ("eraser.png"     , "myeraser")
           , ("highlighter.png", "myhighlighter") 
           , ("text-tool.png"  , "mytext")
           , ("shapes.png"     , "myshapes")
           , ("ruler.png"      , "myruler")
           , ("lasso.png"      , "mylasso")
           , ("rect-select.png", "myrectselect")
           , ("stretch.png"    , "mystretch")
           , ("hand.png"       , "myhand")
           , ("recycled.png"   , "mydefault")
           , ("default-pen.png", "mydefaultpen")
           , ("thin.png"       , "mythin")
           , ("medium.png"     , "mymedium")
           , ("thick.png"      , "mythick")
           , ("black.png"      , "myblack") 
           , ("blue.png"       , "myblue")
           , ("red.png"        , "myred")
           , ("green.png"      , "mygreen")
           , ("gray.png"       , "mygray")
           , ("lightblue.png"  , "mylightblue")
           , ("lightgreen.png" , "mylightgreen")
           , ("magenta.png"    , "mymagenta")
           , ("orange.png"     , "myorange")
           , ("yellow.png"     , "myyellow")
           , ("white.png"      , "mywhite")
           ]

-- | 
viewmods :: [RadioActionEntry] 
viewmods = [ RadioActionEntry "CONTA" "Continuous" Nothing Nothing Nothing 0
           , RadioActionEntry "ONEPAGEA" "One Page" Nothing Nothing Nothing 1
           ]
           
-- | 
pointmods :: [RadioActionEntry] 
pointmods = [ RadioActionEntry "PENVERYFINEA" "Very fine" Nothing Nothing Nothing 0
            , RadioActionEntry "PENFINEA" "Fine" (Just "mythin") Nothing Nothing 1
            
            , RadioActionEntry "PENTHICKA" "Thick" (Just "mythick") Nothing Nothing 3 
            , RadioActionEntry "PENVERYTHICKA" "Very Thick" Nothing Nothing Nothing 4 
            , RadioActionEntry "PENULTRATHICKA" "Ultra Thick" Nothing Nothing Nothing 5   
            , RadioActionEntry "PENMEDIUMA" "Medium" (Just "mymedium") Nothing Nothing 2              
            ]            

-- | 

penmods :: [RadioActionEntry] 
penmods = [ RadioActionEntry "PENA"    "Pen"         (Just "mypen")         Nothing Nothing 0 
          , RadioActionEntry "ERASERA" "Eraser"      (Just "myeraser")      Nothing Nothing 1
          , RadioActionEntry "HIGHLTA" "Highlighter" (Just "myhighlighter") Nothing Nothing 2
--           , RadioActionEntry "TEXTA"   "Text"        (Just "mytext")        Nothing Nothing 3 
          , RadioActionEntry "SELREGNA" "Select Region"     (Just "mylasso")        Nothing Nothing 4
          , RadioActionEntry "SELRECTA" "Select Rectangle" (Just "myrectselect")        Nothing Nothing 5
          , RadioActionEntry "VERTSPA" "Vertical Space"    (Just "mystretch")        Nothing Nothing 6
          , RadioActionEntry "HANDA"   "Hand Tool"         (Just "myhand")        Nothing Nothing 7
          ]            

-- | 

colormods :: [RadioActionEntry]
colormods = [ RadioActionEntry "BLUEA"       "Blue"       (Just "myblue")       Nothing Nothing 1
            , RadioActionEntry "REDA"        "Red"        (Just "myred")        Nothing Nothing 2
            , RadioActionEntry "GREENA"      "Green"      (Just "mygreen")      Nothing Nothing 3
            , RadioActionEntry "GRAYA"       "Gray"       (Just "mygray")       Nothing Nothing 4
            , RadioActionEntry "LIGHTBLUEA"  "Lightblue"  (Just "mylightblue")  Nothing Nothing 5     
            , RadioActionEntry "LIGHTGREENA" "Lightgreen" (Just "mylightgreen") Nothing Nothing 6
            , RadioActionEntry "MAGENTAA"    "Magenta"    (Just "mymagenta")    Nothing Nothing 7
            , RadioActionEntry "ORANGEA"     "Orange"     (Just "myorange")     Nothing Nothing 8
            , RadioActionEntry "YELLOWA"     "Yellow"     (Just "myyellow")     Nothing Nothing 9
            , RadioActionEntry "WHITEA"      "White"      (Just "mywhite")      Nothing Nothing 10
            , RadioActionEntry "BLACKA"      "Black"      (Just "myblack")      Nothing Nothing 0              
            ]

-- |

iconResourceAdd :: IconFactory -> FilePath -> (FilePath, StockId) 
                   -> IO ()
iconResourceAdd iconfac resdir (fp,stid) = do 
  myIconSource <- iconSourceNew 
  iconSourceSetFilename myIconSource (resdir </> fp)
  iconSourceSetSize myIconSource IconSizeLargeToolbar
  myIconSourceSmall <- iconSourceNew 
  iconSourceSetFilename myIconSourceSmall (resdir </> fp)
  iconSourceSetSize myIconSource IconSizeMenu
  myIconSet <- iconSetNew 
  iconSetAddSource myIconSet myIconSource 
  iconSetAddSource myIconSet myIconSourceSmall
  iconFactoryAdd iconfac stid myIconSet

-- | 

actionNewAndRegisterRef :: EventVar                            
                           -> String -> String 
                           -> Maybe String -> Maybe StockId
                           -> Maybe MyEvent 
                           -> IO Action
actionNewAndRegisterRef evar name label tooltip stockId myevent = do 
    a <- actionNew name label tooltip stockId 
    case myevent of 
      Nothing -> return a 
      Just ev -> do 
        a `on` actionActivated $ do 
          eventHandler evar ev
        return a

-- | 

getMenuUI :: EventVar -> IO UIManager
getMenuUI evar = do 
  let actionNewAndRegister = actionNewAndRegisterRef evar  
  -- icons   
  myiconfac <- iconFactoryNew 
  iconFactoryAddDefault myiconfac 
  resDir <- getDataDir >>= return . (</> "resource") 
  mapM_ (iconResourceAdd myiconfac resDir) iconList 
  fma     <- actionNewAndRegister "FMA"   "File" Nothing Nothing Nothing
  ema     <- actionNewAndRegister "EMA"   "Edit" Nothing Nothing Nothing
  vma     <- actionNewAndRegister "VMA"   "View" Nothing Nothing Nothing
  jma     <- actionNewAndRegister "JMA"   "Page" Nothing Nothing Nothing
  tma     <- actionNewAndRegister "TMA"   "Tools" Nothing Nothing Nothing
  oma     <- actionNewAndRegister "OMA"   "Options" Nothing Nothing Nothing
  hma     <- actionNewAndRegister "HMA"   "Help" Nothing Nothing Nothing

  -- file menu
  newa    <- actionNewAndRegister "NEWA"  "New" (Just "Just a Stub") (Just stockNew) (justMenu MenuNew)
  opena   <- actionNewAndRegister "OPENA" "Open" (Just "Just a Stub") (Just stockOpen) (justMenu MenuOpen)
  savea   <- actionNewAndRegister "SAVEA" "Save" (Just "Just a Stub") (Just stockSave) (justMenu MenuSave)
  saveasa <- actionNewAndRegister "SAVEASA" "Save As" (Just "Just a Stub") (Just stockSaveAs) (justMenu MenuSaveAs)
  reloada <- actionNewAndRegister "RELOADA" "Reload File" (Just "Just a Stub") Nothing (justMenu MenuReload)
  recenta <- actionNewAndRegister "RECENTA" "Recent Document" (Just "Just a Stub") Nothing (justMenu MenuRecentDocument)
  annpdfa <- actionNewAndRegister "ANNPDFA" "Annotate PDF" (Just "Just a Stub") Nothing (justMenu MenuAnnotatePDF)
  ldpnga <- actionNewAndRegister "LDIMGA" "Load PNG or JPG Image" (Just "Just a Stub") Nothing (justMenu MenuLoadPNGorJPG)
  ldsvga <- actionNewAndRegister "LDSVGA" "Load SVG Image" (Just "Just a Stub") Nothing (justMenu MenuLoadSVG)
  latexa <- actionNewAndRegister "LATEXA" "LaTeX" (Just "Just a Stub") Nothing (justMenu MenuLaTeX)
  ldpreimga <- actionNewAndRegister "LDPREIMGA" "Embed Predefined Image File" (Just "Just a Stub") Nothing (justMenu MenuEmbedPredefinedImage)


  printa  <- actionNewAndRegister "PRINTA" "Print" (Just "Just a Stub") Nothing (justMenu MenuPrint)
  exporta <- actionNewAndRegister "EXPORTA" "Export" (Just "Just a Stub") Nothing (justMenu MenuExport)
  quita   <- actionNewAndRegister "QUITA" "Quit" (Just "Just a Stub") (Just stockQuit) (justMenu MenuQuit)
  
  -- edit menu
  undoa   <- actionNewAndRegister "UNDOA"   "Undo" (Just "Just a Stub") (Just stockUndo) (justMenu MenuUndo)
  redoa   <- actionNewAndRegister "REDOA"   "Redo" (Just "Just a Stub") (Just stockRedo) (justMenu MenuRedo)
  cuta    <- actionNewAndRegister "CUTA"    "Cut" (Just "Just a Stub")  (Just stockCut) (justMenu MenuCut)
  copya   <- actionNewAndRegister "COPYA"   "Copy" (Just "Just a Stub") (Just stockCopy) (justMenu MenuCopy)
  pastea  <- actionNewAndRegister "PASTEA"  "Paste" (Just "Just a Stub") (Just stockPaste) (justMenu MenuPaste)
  deletea <- actionNewAndRegister "DELETEA" "Delete" (Just "Just a Stub") (Just stockDelete) (justMenu MenuDelete)
  -- netcopya <- actionNewAndRegister "NETCOPYA" "Copy to NetworkClipboard" (Just "Just a Stub") Nothing (justMenu MenuNetCopy)
  -- netpastea <- actionNewAndRegister "NETPASTEA" "Paste from NetworkClipboard" (Just "Just a Stub") Nothing (justMenu MenuNetPaste)

  -- view menu
  fscra     <- actionNewAndRegister "FSCRA"     "Full Screen" (Just "Just a Stub") (Just "myfullscreen") (justMenu MenuFullScreen)
  zooma     <- actionNewAndRegister "ZOOMA"     "Zoom" (Just "Just a Stub") Nothing Nothing -- (justMenu MenuZoom)
  zmina     <- actionNewAndRegister "ZMINA"     "Zoom In" (Just "Zoom In") (Just stockZoomIn) (justMenu MenuZoomIn)
  zmouta    <- actionNewAndRegister "ZMOUTA"    "Zoom Out" (Just "Zoom Out") (Just stockZoomOut) (justMenu MenuZoomOut)
  nrmsizea  <- actionNewAndRegister "NRMSIZEA"  "Normal Size" (Just "Normal Size") (Just stockZoom100) (justMenu MenuNormalSize)
  pgwdtha   <- actionNewAndRegister "PGWDTHA" "Page Width" (Just "Page Width") (Just stockZoomFit) (justMenu MenuPageWidth)
  pgheighta <- actionNewAndRegister "PGHEIGHTA" "Page Height" (Just "Page Height") Nothing (justMenu MenuPageHeight)
  setzma    <- actionNewAndRegister "SETZMA"  "Set Zoom" (Just "Set Zoom") (Just stockFind) (justMenu MenuSetZoom)
  fstpagea  <- actionNewAndRegister "FSTPAGEA"  "First Page" (Just "Just a Stub") (Just stockGotoFirst) (justMenu MenuFirstPage)
  prvpagea  <- actionNewAndRegister "PRVPAGEA"  "Previous Page" (Just "Just a Stub") (Just stockGoBack) (justMenu MenuPreviousPage)
  nxtpagea  <- actionNewAndRegister "NXTPAGEA"  "Next Page" (Just "Just a Stub") (Just stockGoForward) (justMenu MenuNextPage)
  lstpagea  <- actionNewAndRegister "LSTPAGEA"  "Last Page" (Just "Just a Stub") (Just stockGotoLast) (justMenu MenuLastPage)
  shwlayera <- actionNewAndRegister "SHWLAYERA" "Show Layer" (Just "Just a Stub") Nothing (justMenu MenuShowLayer)
  hidlayera <- actionNewAndRegister "HIDLAYERA" "Hide Layer" (Just "Just a Stub") Nothing (justMenu MenuHideLayer)
  hsplita <- actionNewAndRegister "HSPLITA" "Horizontal Split" (Just "horizontal split") Nothing (justMenu MenuHSplit)
  vsplita <- actionNewAndRegister "VSPLITA" "Vertical Split" (Just "vertical split") Nothing (justMenu MenuVSplit)
  delcvsa <- actionNewAndRegister "DELCVSA" "Delete Current Canvas" (Just "delete current canvas") Nothing (justMenu MenuDelCanvas)

  -- page menu 
  newpgba <- actionNewAndRegister "NEWPGBA" "New Page Before" (Just "Just a Stub") Nothing (justMenu MenuNewPageBefore)
  newpgaa <- actionNewAndRegister "NEWPGAA" "New Page After"  (Just "Just a Stub") Nothing (justMenu MenuNewPageAfter)
  newpgea <- actionNewAndRegister "NEWPGEA" "New Page At End" (Just "Just a Stub") Nothing (justMenu MenuNewPageAtEnd)
  delpga  <- actionNewAndRegister "DELPGA"  "Delete Page"     (Just "Just a Stub") Nothing (justMenu MenuDeletePage)
  expsvga <- actionNewAndRegister "EXPSVGA" "Export Current Page to SVG" (Just "Just a Stub") Nothing (justMenu MenuExportPageSVG) 
  newlyra <- actionNewAndRegister "NEWLYRA" "New Layer"       (Just "Just a Stub") Nothing (justMenu MenuNewLayer)
  nextlayera <- actionNewAndRegister "NEXTLAYERA" "Next Layer" (Just "Just a Stub") Nothing (justMenu MenuNextLayer)
  prevlayera <- actionNewAndRegister "PREVLAYERA" "Prev Layer" (Just "Just a Stub") Nothing (justMenu MenuPrevLayer)
  gotolayera <- actionNewAndRegister "GOTOLAYERA" "Goto Layer" (Just "Just a Stub") Nothing (justMenu MenuGotoLayer)
  dellyra <- actionNewAndRegister "DELLYRA" "Delete Layer"    (Just "Just a Stub") Nothing (justMenu MenuDeleteLayer)
  ppsizea <- actionNewAndRegister "PPSIZEA" "Paper Size"      (Just "Just a Stub") Nothing (justMenu MenuPaperSize)
  ppclra  <- actionNewAndRegister "PPCLRA"  "Paper Color"     (Just "Just a Stub") Nothing (justMenu MenuPaperColor)
  ppstya  <- actionNewAndRegister "PPSTYA"  "Paper Style"     (Just "Just a Stub") Nothing (justMenu MenuPaperStyle)
  apallpga<- actionNewAndRegister "APALLPGA" "Apply To All Pages" (Just "Just a Stub") Nothing (justMenu MenuApplyToAllPages)
  ldbkga  <- actionNewAndRegister "LDBKGA"  "Load Background" (Just "Just a Stub") Nothing (justMenu MenuLoadBackground)
  bkgscrshta <- actionNewAndRegister "BKGSCRSHTA" "Background Screenshot" (Just "Just a Stub") Nothing (justMenu MenuBackgroundScreenshot)
  defppa  <- actionNewAndRegister "DEFPPA"  "Default Paper" (Just "Just a Stub") Nothing (justMenu MenuDefaultPaper)
  setdefppa <- actionNewAndRegister "SETDEFPPA" "Set As Default" (Just "Just a Stub") Nothing (justMenu MenuSetAsDefaultPaper)
  
  -- tools menu
  texta <- actionNewAndRegister "TEXTA" "Text" (Just "Text") (Just "mytext") (justMenu MenuText)
  shpreca   <- actionNewAndRegister "SHPRECA" "Shape Recognizer" (Just "Just a Stub") (Just "myshapes") (justMenu MenuShapeRecognizer)
  rulera    <- actionNewAndRegister "RULERA" "Ruler" (Just "Just a Stub") (Just "myruler") (justMenu MenuRuler)
  -- selregna  <- actionNewAndRegister "SELREGNA" "Select Region" (Just "Just a Stub") (Just "mylasso") (justMenu MenuSelectRegion)
  -- selrecta  <- actionNewAndRegister "SELRECTA" "Select Rectangle" (Just "Just a Stub") (Just "myrectselect") (justMenu MenuSelectRectangle)
  -- vertspa   <- actionNewAndRegister "VERTSPA" "Vertical Space" (Just "Just a Stub") (Just "mystretch") (justMenu MenuVerticalSpace)
  -- handa     <- actionNewAndRegister "HANDA" "Hand Tool" (Just "Just a Stub") (Just "myhand") (justMenu MenuHandTool) 
  clra      <- actionNewAndRegister "CLRA" "Color" (Just "Just a Stub") Nothing Nothing
  clrpcka   <- actionNewAndRegister "CLRPCKA" "Color Picker.." (Just "Just a Stub") (Just stockSelectColor) (justMenu MenuColorPicker ) 
  penopta   <- actionNewAndRegister "PENOPTA" "Pen Options" (Just "Just a Stub") Nothing (justMenu MenuPenOptions)
  erasropta <- actionNewAndRegister "ERASROPTA" "Eraser Options" (Just "Just a Stub") Nothing (justMenu MenuEraserOptions)
  hiltropta <- actionNewAndRegister "HILTROPTA" "Highlighter Options" (Just "Just a Stub") Nothing (justMenu MenuHighlighterOptions)
  txtfnta   <- actionNewAndRegister "TXTFNTA" "Text Font" (Just "Just a Stub") Nothing (justMenu MenuTextFont)
  defpena   <- actionNewAndRegister "DEFPENA" "Default Pen" (Just "Just a Stub") (Just "mydefaultpen") (justMenu MenuDefaultPen)
  defersra  <- actionNewAndRegister "DEFERSRA" "Default Eraser" (Just "Just a Stub") Nothing (justMenu MenuDefaultEraser)
  defhiltra <- actionNewAndRegister "DEFHILTRA" "Default Highlighter" (Just "Just a Stub") Nothing (justMenu MenuDefaultHighlighter)
  deftxta   <- actionNewAndRegister "DEFTXTA" "Default Text" (Just "Just a Stub") Nothing (justMenu MenuDefaultText)
  setdefopta <- actionNewAndRegister "SETDEFOPTA" "Set As Default" (Just "Just a Stub") Nothing (justMenu MenuSetAsDefaultOption)
  relauncha <- actionNewAndRegister "RELAUNCHA" "Relaunch Application" (Just "Just a Stub") Nothing (justMenu MenuRelaunch)
    
  -- options menu 
  uxinputa <- toggleActionNew "UXINPUTA" "Use XInput" (Just "Just a Stub") Nothing 
  uxinputa `on` actionToggled $ do 
    eventHandler evar (Menu MenuUseXInput)
  smthscra <- toggleActionNew "SMTHSCRA" "Smooth Scrolling" (Just "Just a stub") Nothing
  smthscra `on` actionToggled $ do 
    eventHandler evar (Menu MenuSmoothScroll)

  ebdimga <- toggleActionNew "EBDIMGA" "Embed PNG/JPG Image" (Just "Just a stub") Nothing
  ebdimga `on` actionToggled $ do 
    eventHandler evar (Menu MenuEmbedImage)
  dcrdcorea <- actionNewAndRegister "DCRDCOREA" "Discard Core Events" (Just "Just a Stub") Nothing (justMenu MenuDiscardCoreEvents)
  ersrtipa <- actionNewAndRegister "ERSRTIPA" "Eraser Tip" (Just "Just a Stub") Nothing (justMenu MenuEraserTip)
  pressrsensa <- toggleActionNew "PRESSRSENSA" "Pressure Sensitivity" (Just "Just a Stub") Nothing 
  pressrsensa `on` actionToggled $ do 
    eventHandler evar (Menu MenuPressureSensitivity)


  
  
  
  pghilta <- actionNewAndRegister "PGHILTA" "Page Highlight" (Just "Just a Stub") Nothing (justMenu MenuPageHighlight)
  mltpgvwa <- actionNewAndRegister "MLTPGVWA" "Multiple Page View" (Just "Just a Stub") Nothing (justMenu MenuMultiplePageView) 
  mltpga <- actionNewAndRegister "MLTPGA" "Multiple Pages" (Just "Just a Stub") Nothing (justMenu MenuMultiplePages)
  btn2mapa <- actionNewAndRegister "BTN2MAPA" "Button 2 Mapping" (Just "Just a Stub") Nothing (justMenu MenuButton2Mapping)
  btn3mapa <- actionNewAndRegister "BTN3MAPA" "Button 3 Mapping" (Just "Just a Stub") Nothing (justMenu MenuButton3Mapping)
  antialiasbmpa <- actionNewAndRegister "ANTIALIASBMPA" "Antialiased Bitmaps" (Just "Just a Stub") Nothing (justMenu MenuAntialiasedBitmaps)
  prgrsbkga <- actionNewAndRegister "PRGRSBKGA" "Progressive Backgrounds" (Just "Just a Stub") Nothing (justMenu MenuProgressiveBackgrounds)
  prntpprulea <- actionNewAndRegister "PRNTPPRULEA" "Print Paper Ruling" (Just "Just a Stub") Nothing (justMenu MenuPrintPaperRuling)
  lfthndscrbra <- actionNewAndRegister "LFTHNDSCRBRA" "Left-Handed Scrollbar" (Just "Just a Stub") Nothing (justMenu MenuLeftHandedScrollbar)
  shrtnmenua <- actionNewAndRegister "SHRTNMENUA" "Shorten Menus" (Just "Just a Stub") Nothing (justMenu MenuShortenMenus)
  autosaveprefa <- actionNewAndRegister "AUTOSAVEPREFA" "Auto-Save Preferences" (Just "Just a Stub") Nothing (justMenu MenuAutoSavePreferences)
  saveprefa <- actionNewAndRegister "SAVEPREFA" "Save Preferences" (Just "Just a Stub") Nothing (justMenu MenuSavePreferences)
  
  -- help menu 
  abouta <- actionNewAndRegister "ABOUTA" "About" (Just "Just a Stub") Nothing (justMenu MenuAbout)

  -- others
  defaulta <- actionNewAndRegister "DEFAULTA" "Default" (Just "Default") (Just "mydefault") (justMenu MenuDefault)
  
  agr <- actionGroupNew "AGR"
  mapM_ (actionGroupAddAction agr) 
        [fma,ema,vma,jma,tma,oma,hma]
  mapM_ (actionGroupAddAction agr)   
        [ undoa, redoa, cuta, copya, pastea, deletea ] 
  mapM_ (\act -> actionGroupAddActionWithAccel agr act Nothing)   
        [ newa, annpdfa, ldpnga, ldsvga, latexa, ldpreimga, opena, savea, saveasa, reloada, recenta, printa, exporta, quita
        , fscra, zooma, zmina, zmouta, nrmsizea, pgwdtha, pgheighta, setzma
        , fstpagea, prvpagea, nxtpagea, lstpagea, shwlayera, hidlayera
        , hsplita, vsplita, delcvsa
        , newpgba, newpgaa, newpgea, delpga, expsvga, newlyra, nextlayera, prevlayera, gotolayera, dellyra, ppsizea, ppclra
        , ppstya, apallpga, ldbkga, bkgscrshta, defppa, setdefppa
        , texta, shpreca, rulera, clra, clrpcka, penopta 
        , erasropta, hiltropta, txtfnta, defpena, defersra, defhiltra, deftxta
        , setdefopta, relauncha
        , dcrdcorea, ersrtipa, pghilta, mltpgvwa
        , mltpga, btn2mapa, btn3mapa, antialiasbmpa, prgrsbkga, prntpprulea 
        , lfthndscrbra, shrtnmenua, autosaveprefa, saveprefa 
        , abouta 
        , defaulta         
        ] 
    
  actionGroupAddAction agr uxinputa 
  actionGroupAddAction agr smthscra
  actionGroupAddAction agr ebdimga
  actionGroupAddAction agr pressrsensa
  -- actionGroupAddRadioActions agr viewmods 0 (assignViewMode evar)
  actionGroupAddRadioActions agr viewmods 0 (const (return ()))
  
  
  actionGroupAddRadioActions agr pointmods 0 (assignPoint evar)
  actionGroupAddRadioActions agr penmods   0 (assignPenMode evar)
  actionGroupAddRadioActions agr colormods 0 (assignColor evar) 
 
  let disabledActions = 
        [ recenta, printa {- , exporta-}
        , cuta, copya, {- pastea, -} deletea
        {- , fscra -}
        ,  setzma
        , shwlayera, hidlayera
        , newpgea, {- delpga, -} ppsizea, ppclra
        , ppstya, apallpga, ldbkga, bkgscrshta, defppa, setdefppa
        , shpreca, rulera 
        , erasropta, hiltropta, txtfnta, defpena, defersra, defhiltra, deftxta
        , setdefopta
        , dcrdcorea, ersrtipa, pghilta, mltpgvwa
        , mltpga, btn2mapa, btn3mapa, antialiasbmpa, prgrsbkga, prntpprulea 
        , lfthndscrbra, shrtnmenua, autosaveprefa, saveprefa 
        , abouta 
        , defaulta         
        ] 
      enabledActions = 
        [ opena, savea, saveasa, reloada, quita, pastea, fstpagea, prvpagea, nxtpagea, lstpagea
        , clra, penopta, zooma, nrmsizea, pgwdtha, texta  
        ]
  --
  mapM_ (\x->actionSetSensitive x True) enabledActions  
  mapM_ (\x->actionSetSensitive x False) disabledActions
  --
  -- 
  -- radio actions
  --
  ui <- uiManagerNew
  
  uiDecl <- readFile (resDir </> "menu.xml")   
  uiManagerAddUiFromString ui uiDecl
  uiManagerInsertActionGroup ui agr 0 
  -- Just ra1 <- actionGroupGetAction agr "ONEPAGEA"
  -- Gtk.set (castToRadioAction ra1) [radioActionCurrentValue := 1]  
  Just ra2 <- actionGroupGetAction agr "PENFINEA"
  Gtk.set (castToRadioAction ra2) [radioActionCurrentValue := 2]
  Just ra3 <- actionGroupGetAction agr "SELREGNA"
  actionSetSensitive ra3 True 
  Just ra4 <- actionGroupGetAction agr "VERTSPA"
  actionSetSensitive ra4 False
  Just ra5 <- actionGroupGetAction agr "HANDA"
  actionSetSensitive ra5 False
  Just ra6 <- actionGroupGetAction agr "CONTA"
  actionSetSensitive ra6 True
  Just toolbar1 <- uiManagerGetWidget ui "/ui/toolbar1"
  toolbarSetStyle (castToToolbar toolbar1) ToolbarIcons 
  toolbarSetIconSize (castToToolbar toolbar1) IconSizeSmallToolbar
  Just toolbar2 <- uiManagerGetWidget ui "/ui/toolbar2"
  toolbarSetStyle (castToToolbar toolbar2) ToolbarIcons 
  toolbarSetIconSize (castToToolbar toolbar2) IconSizeSmallToolbar  
  return ui   

-- | 
assignViewMode :: EventVar -> RadioAction -> IO ()
assignViewMode evar a = viewModeToMyEvent a >>= eventHandler evar
    
-- | 
assignPenMode :: EventVar -> RadioAction -> IO ()
assignPenMode evar a = do 
    v <- radioActionGetCurrentValue a
    eventHandler evar (AssignPenMode (int2PenType v))

      
-- | 
assignColor :: EventVar -> RadioAction -> IO () 
assignColor evar a = do 
    v <- radioActionGetCurrentValue a
    let c = int2Color v
    eventHandler evar (PenColorChanged c)

-- | 
assignPoint :: EventVar -> RadioAction -> IO ()  
assignPoint evar a = do 
    v <- radioActionGetCurrentValue a
    eventHandler evar (PenWidthChanged v)

-- | 
int2PenType :: Int -> Either PenType SelectType 
int2PenType 0 = Left PenWork
int2PenType 1 = Left EraserWork
int2PenType 2 = Left HighlighterWork
-- int2PenType 3 = Left TextWork 
int2PenType 4 = Right SelectRegionWork
int2PenType 5 = Right SelectRectangleWork
int2PenType 6 = Right SelectVerticalSpaceWork
int2PenType 7 = Right SelectHandToolWork
int2PenType _ = error "No such pentype"

-- | 
int2Point :: PenType -> Int -> Double 
int2Point PenWork 0 = predefined_veryfine 
int2Point PenWork 1 = predefined_fine
int2Point PenWork 2 = predefined_medium
int2Point PenWork 3 = predefined_thick
int2Point PenWork 4 = predefined_verythick
int2Point PenWork 5 = predefined_ultrathick
int2Point HighlighterWork 0 = predefined_highlighter_veryfine
int2Point HighlighterWork 1 = predefined_highlighter_fine
int2Point HighlighterWork 2 = predefined_highlighter_medium
int2Point HighlighterWork 3 = predefined_highlighter_thick
int2Point HighlighterWork 4 = predefined_highlighter_verythick
int2Point HighlighterWork 5 = predefined_highlighter_ultrathick
int2Point EraserWork 0 = predefined_eraser_veryfine
int2Point EraserWork 1 = predefined_eraser_fine
int2Point EraserWork 2 = predefined_eraser_medium
int2Point EraserWork 3 = predefined_eraser_thick
int2Point EraserWork 4 = predefined_eraser_verythick
int2Point EraserWork 5 = predefined_eraser_ultrathick
-- int2Point TextWork 0 = predefined_veryfine
-- int2Point TextWork 1 = predefined_fine
-- int2Point TextWork 2 = predefined_medium
-- int2Point TextWork 3 = predefined_thick
-- int2Point TextWork 4 = predefined_verythick
-- int2Point TextWork 5 = predefined_ultrathick
int2Point _ _ = error "No such point"

-- | 
int2Color :: Int -> PenColor
int2Color 0  = ColorBlack 
int2Color 1  = ColorBlue
int2Color 2  = ColorRed
int2Color 3  = ColorGreen
int2Color 4  = ColorGray
int2Color 5  = ColorLightBlue
int2Color 6  = ColorLightGreen
int2Color 7  = ColorMagenta
int2Color 8  = ColorOrange
int2Color 9  = ColorYellow
int2Color 10 = ColorWhite
int2Color _ = error "No such color"
