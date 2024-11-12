#import "/src/lib.typ": shorthands

// Test interaction of shorthands with other elements.

#set page(width: 4cm, height: auto, margin: 1em)
#show: shorthands.with(
  ($@**$, $times.circle.big$),
  ($@*$, $times.circle$),
  ($t t t$, $1/x$),
  ($k_B$, $k_upright(B)$)
)

// Attachments
$
  a @* b \
  a @*_C b \
  a @*^C b \
  a @*^C_2 b
$

// Fractions
$
  a b / @* c \
  a @* / b c \
  t t t / t t t t
$

// Both
$
  a @*^2 / b c \
  a b / @**^2 c \
  @**_(x = 1)^(t t t) t t t / t @* t
$
