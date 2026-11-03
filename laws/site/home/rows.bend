# gildrb.com's laws: the homepage, its rows (R5)
# ==============================================
#
# The terms shared by every section are in base/page.bend; LAWS.bend lists
# the requirements.

import Base
import ../base/html/tokens.bend as H
import ../base/page.bend as Laws

# Terms
# -----

# k from "<k>-title"
def Row.key(r: String) -> Maybe<&2, String>:
  match r:
    case SCon{Chr{101}, SCon{Chr{108}, SCon{Chr{116}, SCon{Chr{105}, SCon{Chr{116}, SCon{Chr{45}, k}}}}}}:
      Some{String.reverse(k)}
    case _:
      None{}

# "<k>-title <k>-descriptor <k>-end"
def Row.label(+k: String) -> String:
  k ++ "-title " ++ k ++ "-descriptor " ++ k ++ "-end"

# every word is exactly once in ids
def Once.all(ws: List<&2, String>, +ids: List<&2, String>) -> Bool:
  match ws:
    case Nil{}:
      True{}
    case Con{w, t}:
      Nat.is_eq(Laws.Spec.count(ids, w), 1n) && Once.all(t, ids)

# the three ids, each one word (an IDREF list splits at white space)
def Row.ids(+k: String) -> List<&2, String>:
  [k ++ "-title", k ++ "-descriptor", k ++ "-end"]

def Row.match(k: Maybe<&2, String>, +label: String) -> Bool:
  match k:
    case None{}:
      False{}
    case Some{+k}:
      String.eq(label, Row.label(k)) && Laws.Spec.same(Laws.Spec.words(label), Row.ids(k))

# a link labelled by its h4's id, descriptor and end
def Row.ok(label: Maybe<&2, String>, id: Maybe<&2, String>) -> Bool:
  match label id:
    case Some{label} Some{id}:
      Row.match(Row.key(String.reverse(id)), label)
    case _ _:
      False{}

# one tag after another: an h4 opens right after a link labelled as its
# row; a link with aria-labelledby opens right before an h4
def Rows.pair(prev: H.Tok, x: H.Tok) -> Bool:
  match prev x:
    case H.TOpen{H.NA{}, a} H.TOpen{H.NH4{}, h}:
      Row.ok(Laws.Spec.attr(H.KLabelled{}, a), Laws.Spec.attr(H.KId{}, h))
    case H.TOpen{H.NA{}, a} y:
      Bool.not(Laws.Spec.has(H.KLabelled{}, a))
    case p H.TOpen{H.NH4{}, h}:
      False{}
    case p y:
      True{}

def Rows.go(ts: List<&2, H.Tok>, +prev: H.Tok) -> Bool:
  match ts:
    case Nil{}:
      True{}
    case Con{+x, t}:
      Rows.pair(prev, x) && Rows.go(t, x)

# outside a link with aria-labelledby, or inside one: the ids it names,
# and the ids of the elements in it so far (links do not nest:
# base/html/tree.bend)
type Inside is Data:
  InOut{}
  InRow{want: List<&2, String>, ids: List<&2, String>}

def Inside.open(m: Maybe<&2, String>) -> Inside:
  match m:
    case None{}:
      InOut{}
    case Some{v}:
      InRow{Laws.Spec.words(v), []}

def Inside.shut(b: Bool) -> Maybe<&2, Inside>:
  match b:
    case True{}:
      Some{InOut{}}
    case False{}:
      None{}

# one tag on; None: a link's end tag before each id its aria-labelledby
# names is the id of exactly one element in it
def Inside.step(x: H.Tok, st: Inside) -> Maybe<&2, Inside>:
  match x st:
    case H.TOpen{H.NA{}, a} InOut{}:
      Some{Inside.open(Laws.Spec.attr(H.KLabelled{}, a))}
    case H.TOpen{n, attrs} InRow{want, ids}:
      Some{InRow{want, Laws.Spec.ids.at(Laws.Spec.attr(H.KId{}, attrs), ids)}}
    case H.TShut{H.NA{}} InRow{want, ids}:
      Inside.shut(Once.all(want, ids))
    case x st:
      Some{st}

def Inside.go(ts: List<&2, H.Tok>, m: Maybe<&2, Inside>) -> Bool:
  match ts m:
    case ts None{}:
      False{}
    case Nil{} Some{InOut{}}:
      True{}
    case Nil{} Some{InRow{want, ids}}:
      False{}
    case Con{x, t} Some{st}:
      Inside.go(t, Inside.step(x, st))

def Spec.h4s(ts: List<&2, H.Tok>) -> Nat:
  match ts:
    case Nil{}:
      0n
    case Con{H.TOpen{H.NH4{}, attrs}, t}:
      1n+Spec.h4s(t)
    case Con{x, t}:
      Spec.h4s(t)

def Once.at(m: Maybe<&2, String>, +ids: List<&2, String>) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{v}:
      Once.all(Laws.Spec.words(v), ids)

# every id an aria-labelledby names is on the page exactly once
def Once.go(ts: List<&2, H.Tok>, +ids: List<&2, String>) -> Bool:
  match ts:
    case Nil{}:
      True{}
    case Con{H.TOpen{n, attrs}, t}:
      Once.at(Laws.Spec.attr(H.KLabelled{}, attrs), ids) && Once.go(t, ids)
    case Con{x, t}:
      Once.go(t, ids)

def Rows.of(m: Maybe<&2, List<&2, H.Tok>>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{+ts}:
      Rows.go(ts, H.TText{SNil{}}) && Nat.is_le(1n, Spec.h4s(ts)) && Once.go(ts, Laws.Spec.ids(ts)) && Inside.go(ts, Some{InOut{}})

# the homepage's rows are labelled by their title, descriptor and end (R5)
def Spec.rows_ok(m: Maybe<&2, List<&2, String>>) -> Bool:
  Rows.of(Laws.Spec.toks(m))

# Laws
# ----

# LAW rows: on the homepage every h4 (a row's title) opens right after a
# link (its row) whose aria-labelledby is exactly "<k>-title
# <k>-descriptor <k>-end", where "<k>-title" is the h4's id and k holds no
# white space (the attribute splits into those three ids); each id a
# link's aria-labelledby names is the id of exactly one element inside
# that link (after its start tag, before its end tag); every link with
# aria-labelledby is such a row; there is at least one row; every id any
# aria-labelledby names is on the page exactly once (R5).
law rows:
  {Spec.rows_ok(Laws.Spec.page("index.html")) == True{} : Bool}
