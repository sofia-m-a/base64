{-# LANGUAGE DataKinds #-}
{-# LANGUAGE Trustworthy #-}
-- |
-- Module       : Data.Text.Short.Encoding.Base64.URL
-- Copyright    : (c) 2019-2022 Emily Pillmore
-- License      : BSD-style
--
-- Maintainer   : Emily Pillmore <emilypi@cohomolo.gy>
-- Stability    : stable
-- Portability  : non-portable
--
-- This module contains 'Data.Text.Short.ShortText'-valued combinators
-- implementing the RFC 4648 specification for the Base64url
-- encoding format. This includes strictly padded/unpadded and lenient
-- decoding variants, and external + internal validations for canonicity.
--
module Data.Text.Short.Encoding.Base64.URL
( -- * Encoding
  encodeBase64
, encodeBase64Unpadded
  -- * Decoding
, decodeBase64
, decodeBase64With
, decodeBase64Unpadded
, decodeBase64UnpaddedWith
, decodeBase64Padded
, decodeBase64PaddedWith
, decodeBase64Lenient
  -- * Validation
, isBase64Url
, isValidBase64Url
) where

import Data.Base64.Types

import Data.Bifunctor (first)
import qualified Data.ByteString.Base64.URL as B64U
import Data.ByteString.Short (ShortByteString)
import qualified Data.ByteString.Short.Base64.URL as BS64U
import Data.Text (Text)
import qualified Data.Text.Encoding.Base64.URL as B64TU
import Data.Text.Encoding.Base64.Error
import Data.Text.Short
import Data.Text.Short.Unsafe

-- | Encode a 'ShortText' value in Base64url with padding.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-5 RFC-4648 section 5>
--
-- === __Examples__:
--
-- >>> encodeBase64 "<<?>>"
-- "PDw_Pj4="
--
encodeBase64 :: ShortText -> Base64 'UrlPadded ShortText
encodeBase64 = fmap fromByteStringUnsafe
  . B64U.encodeBase64'
  . toByteString
{-# INLINE encodeBase64 #-}

-- | Decode a padded Base64url-encoded 'ShortText' value. If its length is not a multiple
-- of 4, then padding chars will be added to fill out the input to a multiple of
-- 4 for safe decoding as base64url encodings are optionally padded.
--
-- For a decoder that fails on unpadded input, use 'decodeBase64Unpadded'.
--
-- /Note:/ This function makes sure that decoding is total by deferring to
-- 'T.decodeLatin1'. This will always round trip for any valid Base64-encoded
-- text value, but it may not round trip for bad inputs. The onus is on the
-- caller to make sure inputs are valid. If unsure, defer to `decodeBase64With`
-- and pass in a custom decode function.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Examples__:
--
-- >>> decodeBase64 "PDw_Pj4="
-- Right "<<?>>"
--
-- >>> decodeBase64 "PDw_Pj4"
-- Right "<<?>>"
--
-- >>> decodeBase64 "PDw-Pg="
-- Left "Base64-encoded bytestring has invalid padding"
--
-- >>> decodeBase64 "PDw-Pg"
-- Right "<<>>"
--
decodeBase64
  :: UrlAlphabet k
  => Base64 k ShortText
  -> Either Text ShortText
decodeBase64 = fmap fromText . B64TU.decodeBase64 . fmap toText
{-# INLINE decodeBase64 #-}

-- | Attempt to decode a 'ShortByteString' value as Base64url, converting from
-- 'ByteString' to 'ShortText' according to some encoding function. In practice,
-- This is something like 'decodeUtf8'', which may produce an error.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Examples__:
--
-- @
-- 'decodeBase64With' 'T.decodeUtf8''
--   :: 'ShortByteString' -> 'Either' ('Base64Error' 'UnicodeException') 'ShortText'
-- @
--
decodeBase64With
    :: UrlAlphabet k
    => (ShortByteString -> Either err ShortText)
      -- ^ convert a bytestring to text (e.g. 'T.decodeUtf8'')
    -> Base64 k ShortByteString
      -- ^ Input text to decode
    -> Either (Base64Error err) ShortText
decodeBase64With f t = case BS64U.decodeBase64 t of
  Left de -> Left $ DecodeError de
  Right a -> first ConversionError (f a)
{-# INLINE decodeBase64With #-}

-- | Encode a 'ShortText' value in Base64url without padding. Note that for Base64url,
-- padding is optional. If you call this function, you will simply be encoding
-- as Base64url and stripping padding chars from the output.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-3.2 RFC-4648 section 3.2>
--
-- === __Examples__:
--
-- >>> encodeBase64Unpadded "<<?>>"
-- "PDw_Pj4"
--
encodeBase64Unpadded :: ShortText -> Base64 'UrlUnpadded ShortText
encodeBase64Unpadded = fmap fromByteStringUnsafe
  . B64U.encodeBase64Unpadded'
  . toByteString
{-# INLINE encodeBase64Unpadded #-}

-- | Decode an unpadded Base64url encoded 'ShortText' value.
--
-- /Note:/ This function makes sure that decoding is total by deferring to
-- 'T.decodeLatin1'. This will always round trip for any valid Base64-encoded
-- text value, but it may not round trip for bad inputs. The onus is on the
-- caller to make sure inputs are valid. If unsure, defer to `decodeBase64UnpaddedWith`
-- and pass in a custom decode function.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Examples__:
--
-- >>> decodeBase64Unpadded "PDw_Pj4"
-- Right "<<?>>"
--
-- >>> decodeBase64Unpadded "PDw_Pj4="
-- Left "Base64-encoded bytestring has invalid padding"
--
decodeBase64Unpadded :: Base64 'UrlUnpadded ShortText -> Either Text ShortText
decodeBase64Unpadded = fmap fromText . B64TU.decodeBase64Unpadded . fmap toText
{-# INLINE decodeBase64Unpadded #-}

-- | Attempt to decode an unpadded 'ShortByteString' value as Base64url, converting from
-- 'ShortByteString' to 'ShortText' according to some encoding function. In practice,
-- This is something like 'decodeUtf8'', which may produce an error.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Examples__:
--
-- @
-- 'decodeBase64UnpaddedWith' 'T.decodeUtf8''
--   :: 'ShortByteString' -> 'Either' ('Base64Error' 'UnicodeException') 'ShortText'
-- @
--
decodeBase64UnpaddedWith
    :: (ShortByteString -> Either err ShortText)
      -- ^ convert a bytestring to text (e.g. 'T.decodeUtf8'')
    -> Base64 'UrlUnpadded ShortByteString
      -- ^ Input text to decode
    -> Either (Base64Error err) ShortText
decodeBase64UnpaddedWith f t = case BS64U.decodeBase64Unpadded t of
  Left de -> Left $ DecodeError de
  Right a -> first ConversionError (f a)
{-# INLINE decodeBase64UnpaddedWith #-}

-- | Decode an padded Base64url encoded 'ShortText' value
--
-- /Note:/ This function makes sure that decoding is total by deferring to
-- 'T.decodeLatin1'. This will always round trip for any valid Base64-encoded
-- text value, but it may not round trip for bad inputs. The onus is on the
-- caller to make sure inputs are valid. If unsure, defer to `decodeBase64PaddedWith`
-- and pass in a custom decode function.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Examples__:
--
-- >>> decodeBase64Padded "PDw_Pj4="
-- Right "<<?>>"
--
-- >>> decodeBase64Padded "PDw_Pj4"
-- Left "Base64-encoded bytestring requires padding"
--
decodeBase64Padded :: Base64 'UrlPadded ShortText -> Either Text ShortText
decodeBase64Padded = fmap fromText . B64TU.decodeBase64Padded . fmap toText
{-# INLINE decodeBase64Padded #-}

-- | Attempt to decode a padded 'ShortByteString' value as Base64url, converting from
-- 'ByteString' to 'ShortText' according to some encoding function. In practice,
-- This is something like 'decodeUtf8'', which may produce an error.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Examples__:
--
-- @
-- 'decodeBase64With' 'T.decodeUtf8''
--   :: 'ShortByteString' -> 'Either' ('Base64Error' 'UnicodeException') 'ShortText'
-- @
--
decodeBase64PaddedWith
    :: (ShortByteString -> Either err ShortText)
      -- ^ convert a bytestring to text (e.g. 'T.decodeUtf8'')
    -> Base64 'UrlPadded ShortByteString
      -- ^ Input text to decode
    -> Either (Base64Error err) ShortText
decodeBase64PaddedWith f t = case BS64U.decodeBase64Padded t of
  Left de -> Left $ DecodeError de
  Right a -> first ConversionError (f a)
{-# INLINE decodeBase64PaddedWith #-}

-- | Leniently decode an unpadded Base64url-encoded 'ShortText'. This function
-- will not generate parse errors. If input data contains padding chars,
-- then the input will be parsed up until the first pad character.
--
-- __Note:__ This is not RFC 4648-compliant.
--
-- === __Examples__:
--
-- >>> decodeBase64Lenient "PDw_Pj4="
-- "<<?>>"
--
-- >>> decodeBase64Lenient "PDw_%%%$}Pj4"
-- "<<?>>"
--
decodeBase64Lenient :: Base64 k ShortText -> ShortText
decodeBase64Lenient = fromText . B64TU.decodeBase64Lenient . fmap toText
{-# INLINE decodeBase64Lenient #-}

-- | Tell whether a 'ShortText' value is Base64url-encoded.
--
-- === __Examples__:
--
-- >>> isBase64Url "PDw_Pj4="
-- True
--
-- >>> isBase64Url "PDw_Pj4"
-- True
--
-- >>> isBase64Url "PDw_Pj"
-- False
--
isBase64Url :: ShortText -> Bool
isBase64Url = B64U.isBase64Url . toByteString
{-# INLINE isBase64Url #-}

-- | Tell whether a 'ShortText' value is a valid Base64url format.
--
-- This will not tell you whether or not this is a correct Base64url representation,
-- only that it conforms to the correct shape. To check whether it is a true
-- Base64 encoded 'ShortText' value, use 'isBase64Url'.
--
-- === __Examples__:
--
-- >>> isValidBase64Url "PDw_Pj4="
-- True
--
-- >>> isValidBase64Url "PDw_Pj"
-- True
--
-- >>> isValidBase64Url "%"
-- False
--
isValidBase64Url :: ShortText -> Bool
isValidBase64Url = B64U.isValidBase64Url . toByteString
{-# INLINE isValidBase64Url #-}
