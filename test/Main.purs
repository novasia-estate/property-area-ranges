module Test.Main where
import Prelude
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)
import Property.AreaRanges

assert :: String -> Boolean -> Effect Unit
assert name ok = if ok then pure unit else throw name

main :: Effect Unit
main = do
  let rounded = fromRounded SquareMetres NetInternal 50.0 0
  case rounded of
    Left _ -> throw "Valid rounded area rejected"
    Right a -> do
      assert "Independent50m2 envelope" ((bounds a).lower == 49.5 && (bounds a).upper == 50.5)
      case pricePerArea 100000.0 a of
        Left _ -> throw "Price band rejected"
        Right p -> assert "Inverse interval endpoints" (p.lower == 100000.0 / 50.5 && p.upper == 100000.0 / 49.5)
      case exactRange SquareMetres GrossInternal 49.5 50.5 of
        Left _ -> throw "Valid gross range rejected"
        Right b -> case intersect a b of
          Left BasisMismatch -> pure unit
          _ -> throw "Gross and net silently mixed"
      case exactRange SquareMetres NetInternal 60.0 61.0 of
        Left _ -> throw "Valid bounds rejected"
        Right b -> case intersect a b of
          Left Disjoint -> pure unit
          _ -> throw "Disjoint observations merged"
  case exactRange SquareFeet LandArea 100.0 100.0 of
    Left _ -> throw "Square feet rejected"
    Right a -> assert "Exact unit factor" ((bounds a).lower == 9.290304)
  case fromRounded SquareMetres NetInternal 50.0 7 of
    Left InvalidPrecision -> pure unit
    _ -> throw "Unsupported precision accepted"
  case exactRange SquareMetres NetInternal 51.0 50.0 of
    Left InvalidBounds -> pure unit
    _ -> throw "Reversed bounds accepted"
  case exactRange SquareMetres Unspecified 0.0 1.0 of
    Left _ -> throw "Unknown basis should remain representable"
    Right a -> case pricePerArea 1.0 a of
      Left BasisUnknown -> pure unit
      _ -> throw "Unknown basis used for comparison"
  case exactRange SquareMetres NetInternal 0.0 1.0 of
    Left _ -> throw "Zero bound rejected"
    Right a -> case pricePerArea 1.0 a of
      Left ZeroDenominator -> pure unit
      _ -> throw "Unbounded unit-price interval hidden"
  log "PASS area-range semantic checks"
