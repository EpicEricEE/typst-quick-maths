#import "/src/lib.typ": shorthands

// Test single-element shorthands on non-sequence elements.

#set page(width: 4cm, height: auto, margin: 1em)
#show: shorthands.with(
  ($+$, $plus.minus$),
  ($k_B$, $k_upright(B)$)
)

$ k_B $
$ k_B^2 $
$ k_B^+ $
$ a + sqrt(k_B^k_B / T) $
