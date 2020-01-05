-- |
-- Module       : Data.Text.Encoding.Base64.Lens
-- Copyright 	: (c) 2019 Emily Pillmore
-- License	: BSD-style
--
-- Maintainer	: Emily Pillmore <emilypi@cohomolo.gy>
-- Stability	: Experimental
-- Portability	: portable
--
-- This module contains 'Control.Lens.Type.Prism's Base64-encoding and
-- decoding 'Text' values.
--
module Data.Text.Encoding.Base64.Lens
( -- * Prisms
  _Base64Text
, _Base64UrlText
, _Base64UnpaddedText
, _Base64UrlUnpaddedText
) where


import Control.Lens

import Data.Text (Text)
import qualified Data.Text.Encoding.Base64 as B64T
import qualified Data.Text.Encoding.Base64.URL as B64TU


-- | A 'Control.Lens.Type.Prism' into the Base64 encoding of a 'Text' value
--
_Base64Text :: Prism' Text Text
_Base64Text = prism' B64T.encodeBase64 $ \s -> case B64T.decodeBase64 s of
    Left _ -> Nothing
    Right a -> Just a
{-# INLINE _Base64Text #-}

-- | A 'Control.Lens.Type.Prism' into the Base64-url encoding of a 'Text' value
--
_Base64UrlText :: Prism' Text Text
_Base64UrlText = prism' B64TU.encodeBase64 $ \s -> case B64TU.decodeBase64 s of
    Left _ -> Nothing
    Right a -> Just a
{-# INLINE _Base64UrlText #-}

-- | A 'Control.Lens.Type.Prism' into the unpadded Base64 encoding of a
-- 'Text' value
--
_Base64UnpaddedText :: Prism' Text Text
_Base64UnpaddedText = prism' B64T.encodeBase64 $ \s -> case B64T.decodeBase64 s of
    Left _ -> Nothing
    Right a -> Just a
{-# INLINE _Base64UnpaddedText #-}

-- | A 'Control.Lens.Type.Prism' into the Base64-url encoding of a 'Text' value
--
_Base64UrlUnpaddedText :: Prism' Text Text
_Base64UrlUnpaddedText = prism' B64TU.encodeBase64 $ \s -> case B64TU.decodeBase64Unpadded s of
    Left _ -> Nothing
    Right a -> Just a
{-# INLINE _Base64UrlUnpaddedText #-}
