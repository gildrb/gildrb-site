# gildrb.com's laws: the homepage, its groups (R6)
# ================================================
#
# The terms shared by every section are in base/page.bend; LAWS.bend lists
# the requirements.

import Base
import ../base/html/tokens.bend as H
import ../base/page.bend as Laws

# Terms
# -----

# a group of the table: its h3's words, its rows (h4s) before the next h3
type Group is Data:
  Group{name: List<&2, String>, rows: Nat}

# outside a heading, reading a heading's text, or in a heading that holds
# an element
type GroupAt is Data:
  GroupOut{}
  GroupHead{text: String}
  GroupBad{}

# rows before any heading form a group with no name
def Group.row(gs: List<&2, Group>) -> List<&2, Group>:
  match gs:
    case Nil{}:
      [Group{[], 1n}]
    case Con{Group{name, rows}, t}:
      Group{name, 1n+rows} <> t

def Amp.has(s: String) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{Chr{38}, t}:
      True{}
    case SCon{c, t}:
      Amp.has(t)

# a heading's words, as a browser shows them (white space runs one
# space, the ends trimmed); a character reference ("&") gives no words
def Group.name(+text: String) -> List<&2, String>:
  Bool.pick(List<&2, String>, Amp.has(text), [], Laws.Spec.words(text))

# the groups, latest first; a heading that holds an element (an image, a
# span, ...) has no words
def Groups.go(ts: List<&2, H.Tok>, at: GroupAt, gs: List<&2, Group>) -> List<&2, Group>:
  match ts at:
    case Nil{} at:
      gs
    case Con{H.TOpen{H.NH3{}, a}, t} GroupOut{}:
      Groups.go(t, GroupHead{SNil{}}, gs)
    case Con{H.TOpen{H.NH4{}, a}, t} GroupOut{}:
      Groups.go(t, GroupOut{}, Group.row(gs))
    case Con{x, t} GroupOut{}:
      Groups.go(t, GroupOut{}, gs)
    case Con{H.TText{s}, t} GroupHead{text}:
      Groups.go(t, GroupHead{String.append(text, s)}, gs)
    case Con{H.TShut{H.NH3{}}, t} GroupHead{text}:
      Groups.go(t, GroupOut{}, Group{Group.name(text), 0n} <> gs)
    case Con{x, t} GroupHead{text}:
      Groups.go(t, GroupBad{}, gs)
    case Con{H.TShut{H.NH3{}}, t} GroupBad{}:
      Groups.go(t, GroupOut{}, Group{[], 0n} <> gs)
    case Con{x, t} GroupBad{}:
      Groups.go(t, GroupBad{}, gs)

# a group named exactly word, with a row
def Group.is(g: Group, +word: String) -> Bool:
  match g:
    case Group{name, +rows}:
      Laws.Spec.same(name, [word]) && Nat.is_le(1n, rows)

# a later group is Work, with a row
def Order.work(gs: List<&2, Group>) -> Bool:
  match gs:
    case Nil{}:
      False{}
    case Con{g, t}:
      Group.is(g, "Work") || Order.work(t)

# no group named Projects comes after one named Work (seen: one came)
def Order.late(gs: List<&2, Group>, +seen: Bool) -> Bool:
  match gs:
    case Nil{}:
      True{}
    case Con{Group{+name, rows}, t}:
      Bool.not(seen && Laws.Spec.same(name, ["Projects"])) && Order.late(t, seen || Laws.Spec.same(name, ["Work"]))

# every group is named exactly Projects or Work
def Order.named(gs: List<&2, Group>) -> Bool:
  match gs:
    case Nil{}:
      True{}
    case Con{Group{+name, rows}, t}:
      (Laws.Spec.same(name, ["Projects"]) || Laws.Spec.same(name, ["Work"])) && Order.named(t)

def Order.first(gs: List<&2, Group>) -> Bool:
  match gs:
    case Nil{}:
      False{}
    case Con{g, +t}:
      Group.is(g, "Projects") && Order.work(t) && Order.late(t, False{})

# the first group is Projects, with a row; Work, with a row, comes later;
# no Projects after a Work; no group has another name
def Order.of(+gs: List<&2, Group>) -> Bool:
  Order.named(gs) && Order.first(gs)

def Groups.of(m: Maybe<&2, List<&2, H.Tok>>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{ts}:
      Order.of(List.reverse(&2, Group, Groups.go(ts, GroupOut{}, [])))

# the homepage's groups: Projects first, Work later, each with a row (R6)
def Spec.groups_ok(m: Maybe<&2, List<&2, String>>) -> Bool:
  Groups.of(Laws.Spec.toks(m))

# Laws
# ----

# LAW groups: on the homepage every group heading (h3) holds only text,
# with no character reference, that reads exactly "Projects" or "Work"
# (white space as a browser shows it); the first reads "Projects" and a
# later one "Work"; each of those two has at least one row (h4) before the
# next h3; no row comes before the first h3; no "Projects" comes after a
# "Work". Which rows sit in which group is NOT pinned; a group is an h3,
# named by its text (A5) (R6).
law groups:
  {Spec.groups_ok(Laws.Spec.page("index.html")) == True{} : Bool}
