-- One technical bound for monetary numbers and cash products, not a design cap.
-- IEEE doubles deliberately lose integer precision above 2^53. See docs/research/coin-bounds.md.
return { MaxAmount = 1e300 }
