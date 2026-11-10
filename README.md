# Property Area Ranges

Keep rounded floor-area observations as intervals instead of pretending that a brochure's rounded50m² is an exact survey. PureScript types keep the area basis explicit: net internal, gross internal, land or unspecified. Intersections refuse incompatible or unknown bases and report disjoint observations rather than averaging away a disagreement.

`fromRounded SquareMetres NetInternal 50.0 0` creates the conservative interval49.5–50.5m². `pricePerArea 100000.0 area` returns100000/50.5 through100000/49.5, not a falsely exact2000/m². `bounds` always returns square metres. One square foot is0.09290304m².

## Usage and verification

`spago install property-area-ranges` after registry publication. Import `Property.AreaRanges`. Run `spago test` from this directory to verify the independent examples, unit conversion, basis mismatch, disjoint ranges, zero denominator and precision limits. The constructor is private so callers cannot bypass range validation.

Arithmetic uses ordinary floating-point Numbers, not exact rational arithmetic. Inputs must be finite and nonnegative. The rounded interval assumes nearest-decimal rounding, supplied by the caller; it is an inclusive envelope, not a claim about half-way tie conventions or instrument accuracy. Decimal precision is bounded0–6. Unknown bases can be recorded but cannot be compared or used for unit prices. Prices must already share an explicitly chosen currency. No survey certification, valuation, local area standard or FX conversion is inferred.

Maintained by [NovAsia Estate](https://novasia.estate/). [Source and issues](https://github.com/novasia-estate/open-property-lab/tree/main/property-area-ranges). MIT. Examples are invented arithmetic cases.
