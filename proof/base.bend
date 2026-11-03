# gildrb.com's proofs: the lemmas they share
# ==========================================

import Base

# Logic
# -----

def Bool.Is(b: Bool, G: Type) -> Type:
  match b:
    case True{}:
      G
    case False{}:
      Unit

# False is not True
def Bool.absurd(-G: Type, e: {False{} == True{} : Bool}) -> G:
  %e : Bool.Is(_, G)
  Unit{}

# Bool
# ----

def And.l(a: Bool, -b: Bool, e: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      e

def And.both(a: Bool, -b: Bool, ea: {a == True{} : Bool}, eb: {b == True{} : Bool}) -> {Bool.and(a, b) == True{} : Bool}:
  match a:
    case True{}:
      eb
    case False{}:
      Bool.absurd({Bool.and(False{}, b) == True{} : Bool}, ea)

def And.r(a: Bool, -b: Bool, e: {Bool.and(a, b) == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}:
      e
    case False{}:
      Bool.absurd({b == True{} : Bool}, e)
