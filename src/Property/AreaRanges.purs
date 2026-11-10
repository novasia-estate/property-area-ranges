module Property.AreaRanges
  ( Basis(..), AreaUnit(..), AreaRange, Problem(..), bounds, exactRange, fromRounded
  , intersect, pricePerArea
  ) where

import Prelude
import Data.Either (Either(..))
import Data.Number as Number

data Basis = NetInternal | GrossInternal | LandArea | Unspecified
derive instance eqBasis :: Eq Basis
data AreaUnit = SquareMetres | SquareFeet
data Problem = InvalidBounds | InvalidPrecision | BasisUnknown | BasisMismatch | Disjoint | ZeroDenominator | InvalidPrice | ArithmeticOverflow
derive instance eqProblem :: Eq Problem
newtype AreaRange = AreaRange { lower :: Number, upper :: Number, basis :: Basis }

-- Returned bounds are in square metres. Constructor stays private.
bounds :: AreaRange -> { lower :: Number, upper :: Number, basis :: Basis }
bounds (AreaRange r) = r

factor :: AreaUnit -> Number
factor SquareMetres = 1.0
factor SquareFeet = 0.09290304

exactRange :: AreaUnit -> Basis -> Number -> Number -> Either Problem AreaRange
exactRange unit basis lower upper
  | not (Number.isFinite lower && Number.isFinite upper) || lower < 0.0 || lower > upper = Left InvalidBounds
  | otherwise = Right (AreaRange { lower: lower * factor unit, upper: upper * factor unit, basis })

-- Caller states that a nonnegative observation was rounded to nearest decimal quantum.
-- Boundaries are inclusive conservative envelopes, not a claim about tie-breaking rules.
fromRounded :: AreaUnit -> Basis -> Number -> Int -> Either Problem AreaRange
fromRounded unit basis value decimals
  | decimals < 0 || decimals > 6 = Left InvalidPrecision
  | not (Number.isFinite value) || value < 0.0 = Left InvalidBounds
  | otherwise =
      let tolerance = 0.5 * Number.pow 10.0 (negate (toNumber decimals))
      in exactRange unit basis (max 0.0 (value - tolerance)) (value + tolerance)

-- Avoid importing a conversion FFI: bounded integer exponent has7 exact integer cases.
toNumber :: Int -> Number
toNumber 0 = 0.0
toNumber 1 = 1.0
toNumber 2 = 2.0
toNumber 3 = 3.0
toNumber 4 = 4.0
toNumber 5 = 5.0
toNumber _ = 6.0

intersect :: AreaRange -> AreaRange -> Either Problem AreaRange
intersect (AreaRange a) (AreaRange b)
  | a.basis == Unspecified || b.basis == Unspecified = Left BasisUnknown
  | a.basis /= b.basis = Left BasisMismatch
  | max a.lower b.lower > min a.upper b.upper = Left Disjoint
  | otherwise = Right (AreaRange { lower: max a.lower b.lower, upper: min a.upper b.upper, basis: a.basis })

-- Price is a caller-defined single-currency amount. No FX or market comparison is inferred.
pricePerArea :: Number -> AreaRange -> Either Problem { lower :: Number, upper :: Number }
pricePerArea price (AreaRange r)
  | not (Number.isFinite price) || price < 0.0 = Left InvalidPrice
  | r.basis == Unspecified = Left BasisUnknown
  | r.lower <= 0.0 = Left ZeroDenominator
  | not (Number.isFinite (price / r.upper) && Number.isFinite (price / r.lower)) = Left ArithmeticOverflow
  | otherwise = Right { lower: price / r.upper, upper: price / r.lower }
