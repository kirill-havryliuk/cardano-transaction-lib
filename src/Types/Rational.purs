module Types.Rational
  ( Rational
  , class RationalComponent
  , reduce
  , (%)
  , recip
  , numerator
  , denominator
  , denominatorAsNat
  ) where

import Prelude

import Data.BigInt (BigInt)
import Data.BigInt (fromInt) as BigInt
import Data.Maybe (Maybe(Just, Nothing), fromJust)
import Data.Ratio (Ratio)
import Data.Ratio ((%), numerator, denominator) as Ratio
import FromData (class FromData)
import ToData (class ToData)
import Types.Natural (Natural)
import Types.Natural (fromBigInt', toBigInt) as Nat
import Types.PlutusData (PlutusData(Constr, Integer))

-- | `Rational` is a newtype over `Ratio` with a smart constructor `reduce`
-- | that allows to create a `Rational` safely. The constructor is not exposed.
-- | `Rational` also enforces the denominator to always be positive.
newtype Rational = Rational (Ratio BigInt)

derive newtype instance Show Rational
derive newtype instance Eq Rational
derive newtype instance Ord Rational
derive newtype instance Semiring Rational
derive newtype instance Ring Rational
derive newtype instance CommutativeRing Rational

instance EuclideanRing Rational where
  degree _ = one
  mod _ _ = zero
  div a b
    | numerator b == zero = zero
    | otherwise = Rational $
        (numerator a * denominator b) Ratio.% (denominator a * numerator b)

-- | Gives the reciprocal of a `Rational`.
-- | Returns `Nothing` if applied to `zero` since the reciprocal of zero
-- | is mathematically undefined.
recip :: Rational -> Maybe Rational
recip r
  | numerator r == zero = Nothing
  | otherwise = reduce (denominator r) (numerator r)

-- | Get the numerator of a `Rational` as `BigInt`.
numerator :: Rational -> BigInt
numerator (Rational r) = Ratio.numerator r

-- | Get the denominator of a `Rational` as `BigInt`.
denominator :: Rational -> BigInt
denominator (Rational r) = Ratio.denominator r

-- This is safe because the denominator is guaranteed to be positive.
-- | Get the denominator of a `Rational` as `Natural`.
denominatorAsNat :: Rational -> Natural
denominatorAsNat = Nat.fromBigInt' <<< denominator

--------------------------------------------------------------------------------
-- FromData / ToData
--------------------------------------------------------------------------------

instance ToData Rational where
  toData r = Constr zero [ Integer (numerator r), Integer (denominator r) ]

instance FromData Rational where
  fromData (Constr c [ Integer n, Integer d ])
    | c == zero = reduce n d
  fromData _ = Nothing

--------------------------------------------------------------------------------
-- RationalComponent
--------------------------------------------------------------------------------

class RationalComponent t where
  reduce :: t -> t -> Maybe Rational

infixl 7 reduce as %

instance RationalComponent BigInt where
  reduce n d
    | d == zero = Nothing
    | otherwise = Just $ Rational (n Ratio.% d)

instance RationalComponent Int where
  reduce n d = reduce (BigInt.fromInt n) (BigInt.fromInt d)

instance RationalComponent Natural where
  reduce n d = reduce (Nat.toBigInt n) (Nat.toBigInt d)
