# gildrb.com's laws: the terms they share
# =======================================
#
# The site's files (site/site.bend) by path, a page's tags (html/),
# attributes, strings. LAWS.bend lists the requirements. Each section of
# laws/site/ imports this file as Laws.

import Base
import ../../../site/site.bend as S
import ./html/tokens.bend as H
import ./html/tree.bend as T

# Terms
# -----

# the text of the file at path in fs, None when fs has no such file
def Spec.find(fs: List<&2, S.Out>, +path: String) -> Maybe<&2, List<&2, String>>:
  match fs:
    case Nil{}:
      None{}
    case Con{S.Out{p, text}, t}:
      Bool.pick(Maybe<&2, List<&2, String>>, String.eq(p, path), Some{text}, Spec.find(t, path))

# the HTML page at path in dist/
def Spec.page(path: String) -> Maybe<&2, List<&2, String>>:
  Spec.find(S.Site.pages(), path)

# any other file the laws read
def Spec.file(path: String) -> Maybe<&2, List<&2, String>>:
  Spec.find(S.Site.files(), path)

# a page's tags and text; None when it is missing or a browser could read
# it another way
def Spec.toks(m: Maybe<&2, List<&2, String>>) -> Maybe<&2, List<&2, H.Tok>>:
  match m:
    case None{}:
      None{}
    case Some{text}:
      T.Html.toks(text)

# the pieces of a file, joined
def Spec.cat(cs: List<&2, String>) -> String:
  match cs:
    case Nil{}:
      ""
    case Con{s, t}:
      String.append(s, Spec.cat(t))

def Key.num(k: H.Key) -> Nat:
  match k:
    case H.KId{}:
      0n
    case H.KHref{}:
      1n
    case H.KRel{}:
      2n
    case H.KLabelled{}:
      3n
    case H.KContents{}:
      4n
    case H.KHidden{}:
      5n
    case H.KOther{}:
      6n

# the value of a tag's first attribute named key (a browser keeps the
# first of two)
def Spec.attr(+key: H.Key, attrs: List<&2, H.Attr>) -> Maybe<&2, String>:
  match attrs:
    case Nil{}:
      None{}
    case Con{H.Attr{k, v}, t}:
      Bool.pick(Maybe<&2, String>, Nat.is_eq(Key.num(k), Key.num(key)), Some{v}, Spec.attr(key, t))

def Spec.has(+key: H.Key, attrs: List<&2, H.Attr>) -> Bool:
  Maybe.is_some(&2, String, Spec.attr(key, attrs))

# s in lower case (ASCII letters)
def Low.go(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{65}, t}:
      SCon{Chr{97}, Low.go(t)}
    case SCon{Chr{66}, t}:
      SCon{Chr{98}, Low.go(t)}
    case SCon{Chr{67}, t}:
      SCon{Chr{99}, Low.go(t)}
    case SCon{Chr{68}, t}:
      SCon{Chr{100}, Low.go(t)}
    case SCon{Chr{69}, t}:
      SCon{Chr{101}, Low.go(t)}
    case SCon{Chr{70}, t}:
      SCon{Chr{102}, Low.go(t)}
    case SCon{Chr{71}, t}:
      SCon{Chr{103}, Low.go(t)}
    case SCon{Chr{72}, t}:
      SCon{Chr{104}, Low.go(t)}
    case SCon{Chr{73}, t}:
      SCon{Chr{105}, Low.go(t)}
    case SCon{Chr{74}, t}:
      SCon{Chr{106}, Low.go(t)}
    case SCon{Chr{75}, t}:
      SCon{Chr{107}, Low.go(t)}
    case SCon{Chr{76}, t}:
      SCon{Chr{108}, Low.go(t)}
    case SCon{Chr{77}, t}:
      SCon{Chr{109}, Low.go(t)}
    case SCon{Chr{78}, t}:
      SCon{Chr{110}, Low.go(t)}
    case SCon{Chr{79}, t}:
      SCon{Chr{111}, Low.go(t)}
    case SCon{Chr{80}, t}:
      SCon{Chr{112}, Low.go(t)}
    case SCon{Chr{81}, t}:
      SCon{Chr{113}, Low.go(t)}
    case SCon{Chr{82}, t}:
      SCon{Chr{114}, Low.go(t)}
    case SCon{Chr{83}, t}:
      SCon{Chr{115}, Low.go(t)}
    case SCon{Chr{84}, t}:
      SCon{Chr{116}, Low.go(t)}
    case SCon{Chr{85}, t}:
      SCon{Chr{117}, Low.go(t)}
    case SCon{Chr{86}, t}:
      SCon{Chr{118}, Low.go(t)}
    case SCon{Chr{87}, t}:
      SCon{Chr{119}, Low.go(t)}
    case SCon{Chr{88}, t}:
      SCon{Chr{120}, Low.go(t)}
    case SCon{Chr{89}, t}:
      SCon{Chr{121}, Low.go(t)}
    case SCon{Chr{90}, t}:
      SCon{Chr{122}, Low.go(t)}
    case SCon{c, t}:
      SCon{c, Low.go(t)}

# s split at ASCII white space, empty words dropped
def Words.end(w: String, acc: List<&2, String>) -> List<&2, String>:
  match w:
    case SNil{}:
      acc
    case SCon{h, t}:
      String.reverse(SCon{h, t}) <> acc

def Words.go(s: String, w: String, acc: List<&2, String>) -> List<&2, String>:
  match s:
    case SNil{}:
      List.reverse(&2, String, Words.end(w, acc))
    case SCon{Chr{9}, t}:
      Words.go(t, SNil{}, Words.end(w, acc))
    case SCon{Chr{10}, t}:
      Words.go(t, SNil{}, Words.end(w, acc))
    case SCon{Chr{12}, t}:
      Words.go(t, SNil{}, Words.end(w, acc))
    case SCon{Chr{13}, t}:
      Words.go(t, SNil{}, Words.end(w, acc))
    case SCon{Chr{32}, t}:
      Words.go(t, SNil{}, Words.end(w, acc))
    case SCon{c, t}:
      Words.go(t, SCon{c, w}, acc)

def Spec.words(s: String) -> List<&2, String>:
  Words.go(s, SNil{}, [])

def Spec.same(xs: List<&2, String>, ys: List<&2, String>) -> Bool:
  match xs ys:
    case Nil{} Nil{}:
      True{}
    case Con{x, xt} Con{y, yt}:
      String.eq(x, y) && Spec.same(xt, yt)
    case _ _:
      False{}

# how many times s is in xs
def Spec.count(xs: List<&2, String>, +s: String) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{x, t}:
      Nat.add(Bool.pick(Nat, String.eq(x, s), 1n, 0n), Spec.count(t, s))

def Spec.ids.at(m: Maybe<&2, String>, rest: List<&2, String>) -> List<&2, String>:
  match m:
    case None{}:
      rest
    case Some{v}:
      v <> rest

# the value of every id attribute of a page, in order
def Spec.ids(ts: List<&2, H.Tok>) -> List<&2, String>:
  match ts:
    case Nil{}:
      []
    case Con{H.TOpen{n, attrs}, t}:
      Spec.ids.at(Spec.attr(H.KId{}, attrs), Spec.ids(t))
    case Con{H.TShut{n}, t}:
      Spec.ids(t)
    case Con{H.TText{x}, t}:
      Spec.ids(t)
