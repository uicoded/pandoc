{-# LANGUAGE LambdaCase           #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
{- |
   Module      : Text.Pandoc.Lua.Marshaling.WriterOptions
   Copyright   : © 2021-2022 Albert Krewinkel, John MacFarlane
   License     : GNU GPL, version 2 or above

   Maintainer  : Albert Krewinkel <tarleb+pandoc@moltkeplatz.de>
   Stability   : alpha

Marshaling instance for WriterOptions and its components.
-}
module Text.Pandoc.Lua.Marshal.WriterOptions
  ( peekWriterOptions
  , pushWriterOptions
  ) where

import Control.Applicative (optional)
import Data.Aeson as Aeson
import Data.Default (def)
import HsLua as Lua
import HsLua.Aeson (peekValue, pushValue)
import Text.Pandoc.Lua.Marshal.List (pushPandocList)
import Text.Pandoc.Options (WriterOptions (..))
import Text.Pandoc.UTF8 (fromString)

--
-- Writer Options
--

-- | Retrieve a WriterOptions value, either from a normal WriterOptions
-- value, from a read-only object, or from a table with the same
-- keys as a WriterOptions object.
peekWriterOptions :: LuaError e => Peeker e WriterOptions
peekWriterOptions = retrieving "WriterOptions" . \idx ->
  liftLua (ltype idx) >>= \case
    TypeUserdata -> peekUD typeWriterOptions idx
    TypeTable    -> peekWriterOptionsTable idx
    _            -> failPeek =<<
                    typeMismatchMessage "WriterOptions userdata or table" idx

-- | Pushes a WriterOptions value as userdata object.
pushWriterOptions :: LuaError e => Pusher e WriterOptions
pushWriterOptions = pushUD typeWriterOptions

-- | 'WriterOptions' object type.
typeWriterOptions :: LuaError e => DocumentedType e WriterOptions
typeWriterOptions = deftype "WriterOptions"
  [ operation Tostring $ lambda
    ### liftPure show
    <#> udparam typeWriterOptions "opts" "options to print in native format"
    =#> functionResult pushString "string" "Haskell representation"
  ]
  [ property "cite_method"
    "How to print cites"
    (pushViaJSON, writerCiteMethod)
    (peekViaJSON, \opts x -> opts{ writerCiteMethod = x })

  , property "columns"
    "Characters in a line (for text wrapping)"
    (pushIntegral, writerColumns)
    (peekIntegral, \opts x -> opts{ writerColumns = x })

  , property "dpi"
    "DPI for pixel to/from inch/cm conversions"
    (pushIntegral, writerDpi)
    (peekIntegral, \opts x -> opts{ writerDpi = x })

  , property "email_obfuscation"
    "How to obfuscate emails"
    (pushViaJSON, writerEmailObfuscation)
    (peekViaJSON, \opts x -> opts{ writerEmailObfuscation = x })

  , property "epub_chapter_level"
    "Header level for chapters (separate files)"
    (pushIntegral, writerEpubChapterLevel)
    (peekIntegral, \opts x -> opts{ writerEpubChapterLevel = x })

  , property "epub_fonts"
    "Paths to fonts to embed"
    (pushPandocList pushString, writerEpubFonts)
    (peekList peekString, \opts x -> opts{ writerEpubFonts = x })

  , property "epub_metadata"
    "Metadata to include in EPUB"
    (maybe pushnil pushText, writerEpubMetadata)
    (optional . peekText, \opts x -> opts{ writerEpubMetadata = x })

  , property "epub_subdirectory"
    "Subdir for epub in OCF"
    (pushText, writerEpubSubdirectory)
    (peekText, \opts x -> opts{ writerEpubSubdirectory = x })

  , property "extensions"
    "Markdown extensions that can be used"
    (pushViaJSON, writerExtensions)
    (peekViaJSON, \opts x -> opts{ writerExtensions = x })

  , property "highlight_style"
    "Style to use for highlighting (nil = no highlighting)"
    (maybe pushnil pushViaJSON, writerHighlightStyle)
    (optional . peekViaJSON, \opts x -> opts{ writerHighlightStyle = x })

  , property "html_math_method"
    "How to print math in HTML"
    (pushViaJSON, writerHTMLMathMethod)
    (peekViaJSON, \opts x -> opts{ writerHTMLMathMethod = x })

  , property "html_q_tags"
    "Use @<q>@ tags for quotes in HTML"
    (pushBool, writerHtmlQTags)
    (peekBool, \opts x -> opts{ writerHtmlQTags = x })

  , property "identifier_prefix"
    "Prefix for section & note ids in HTML and for footnote marks in markdown"
    (pushText, writerIdentifierPrefix)
    (peekText, \opts x -> opts{ writerIdentifierPrefix = x })

  , property "incremental"
    "True if lists should be incremental"
    (pushBool, writerIncremental)
    (peekBool, \opts x -> opts{ writerIncremental = x })

  , property "listings"
    "Use listings package for code"
    (pushBool, writerListings)
    (peekBool, \opts x -> opts{ writerListings = x })

  , property "number_offset"
    "Starting number for section, subsection, ..."
    (pushPandocList pushIntegral, writerNumberOffset)
    (peekList peekIntegral, \opts x -> opts{ writerNumberOffset = x })

  , property "number_sections"
    "Number sections in LaTeX"
    (pushBool, writerNumberSections)
    (peekBool, \opts x -> opts{ writerNumberSections = x })

  , property "prefer_ascii"
    "Prefer ASCII representations of characters when possible"
    (pushBool, writerPreferAscii)
    (peekBool, \opts x -> opts{ writerPreferAscii = x })

  , property "reference_doc"
    "Path to reference document if specified"
    (maybe pushnil pushString, writerReferenceDoc)
    (optional . peekString, \opts x -> opts{ writerReferenceDoc = x })

  , property "reference_links"
    "Use reference links in writing markdown, rst"
    (pushBool, writerReferenceLinks)
    (peekBool, \opts x -> opts{ writerReferenceLinks = x })

  , property "reference_location"
    "Location of footnotes and references for writing markdown"
    (pushViaJSON, writerReferenceLocation)
    (peekViaJSON, \opts x -> opts{ writerReferenceLocation = x })

  , property "section_divs"
    "Put sections in div tags in HTML"
    (pushBool, writerSectionDivs)
    (peekBool, \opts x -> opts{ writerSectionDivs = x })

  , property "setext_headers"
    "Use setext headers for levels 1-2 in markdown"
    (pushBool, writerSetextHeaders)
    (peekBool, \opts x -> opts{ writerSetextHeaders = x })

  , property "slide_level"
    "Force header level of slides"
    (maybe pushnil pushIntegral, writerSlideLevel)
    (optional . peekIntegral, \opts x -> opts{ writerSlideLevel = x })

  -- , property "syntax_map" "Syntax highlighting definition"
  --   (pushViaJSON, writerSyntaxMap)
  --   (peekViaJSON, \opts x -> opts{ writerSyntaxMap = x })
    -- :: SyntaxMap

  , property "tab_stop"
    "Tabstop for conversion btw spaces and tabs"
    (pushIntegral, writerTabStop)
    (peekIntegral, \opts x -> opts{ writerTabStop = x })

  , property "table_of_contents"
    "Include table of contents"
    (pushBool, writerTableOfContents)
    (peekBool, \opts x -> opts{ writerTableOfContents = x })

  -- , property "template" "Template to use"
  --   (maybe pushnil pushViaJSON, writerTemplate)
  --   (optional . peekViaJSON, \opts x -> opts{ writerTemplate = x })
    -- :: Maybe (Template Text)

  , property "toc_depth"
    "Number of levels to include in TOC"
    (pushIntegral, writerTOCDepth)
    (peekIntegral, \opts x -> opts{ writerTOCDepth = x })

  , property "top_level_division"
    "Type of top-level divisions"
    (pushViaJSON, writerTopLevelDivision)
    (peekViaJSON, \opts x -> opts{ writerTopLevelDivision = x })

  , property "variables"
    "Variables to set in template"
    (pushViaJSON, writerVariables)
    (peekViaJSON, \opts x -> opts{ writerVariables = x })

  , property "wrap_text"
    "Option for wrapping text"
    (pushViaJSON, writerWrapText)
    (peekViaJSON, \opts x -> opts{ writerWrapText = x })
  ]

-- | Retrieves a 'WriterOptions' object from a table on the stack, using
-- the default values for all missing fields.
--
-- Internally, this pushes the default writer options, sets each
-- key/value pair of the table in the userdata value, then retrieves the
-- object again. This will update all fields and complain about unknown
-- keys.
peekWriterOptionsTable :: LuaError e => Peeker e WriterOptions
peekWriterOptionsTable idx = retrieving "WriterOptions (table)" $ do
  liftLua $ do
    absidx <- absindex idx
    pushUD typeWriterOptions def
    let setFields = do
          next absidx >>= \case
            False -> return () -- all fields were copied
            True -> do
              pushvalue (nth 2) *> insert (nth 2)
              settable (nth 4) -- set in userdata object
              setFields
    pushnil -- first key
    setFields
  peekUD typeWriterOptions top `lastly` pop 1

instance Pushable WriterOptions where
  push = pushWriterOptions

-- These will become part of hslua-aeson in future versions.

-- | Retrieves a value from the Lua stack via JSON.
peekViaJSON :: (Aeson.FromJSON a, LuaError e) => Peeker e a
peekViaJSON idx = do
  value <- peekValue idx
  case fromJSON value of
    Aeson.Success x -> pure x
    Aeson.Error msg -> failPeek $ "failed to decode: " <>
                       fromString msg

-- | Pushes a value to the Lua stack as a JSON-like value.
pushViaJSON :: (Aeson.ToJSON a, LuaError e) => Pusher e a
pushViaJSON = pushValue . toJSON