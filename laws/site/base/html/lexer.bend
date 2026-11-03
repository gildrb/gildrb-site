# gildrb.com's laws: the HTML they read, the lexer
# =================================================
#
# Lx.all reads a page's bytes into tokens (tokens.bend) as a browser reads
# gildrb.com's HTML: start and end tags (names and attribute keys folded
# to lower case), the values of the attributes the laws read (Key), text,
# comments, a doctype, and the raw text of script, style, title and
# textarea (it ends only at its end tag). Entities stay as written; a "&"
# in a value the laws read (a browser decodes it) is refused. Where a
# browser could read the bytes another way it ends in LxBad: "<" before
# anything but a letter, "/" or "!"; "<![", "<?"; a comment a browser ends
# early ("<!-->", "<!--->", "--!>"); "<!--" in raw text; a quote, "<" or
# "`" where a browser reads it as part of a name; an attribute with "="
# and no value; "/>" on an element with an end tag; U+0000 in text (a
# browser drops it); a banned element
# (tokens.bend: noscript, template, base, table, select, ...); text that
# ends inside a tag, comment or raw text. tree.bend checks the tags nest.

import Base
import ./tokens.bend as H

# Lexer
# -----

# the lexer's state; names, keys, values and text are built reversed
type Lx is Data:
  LxText{buf: String}
  LxLt{buf: String}
  LxSlash{}
  LxName{shut: Bool, name: String}
  LxAttrs{shut: Bool, name: String, attrs: List<&2, H.Attr>}
  LxKey{shut: Bool, name: String, attrs: List<&2, H.Attr>, key: String}
  LxEq{shut: Bool, name: String, attrs: List<&2, H.Attr>, key: String}
  LxQuote{shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key}
  LxDq{shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key, val: String}
  LxSq{shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key, val: String}
  LxBare{shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key, val: String}
  LxSkip{shut: Bool, name: String, attrs: List<&2, H.Attr>}
  LxSelf{shut: Bool, name: String, attrs: List<&2, H.Attr>}
  LxBang{}
  LxBang1{}
  LxDecl{}
  LxComS{}
  LxComS1{}
  LxCom0{}
  LxCom1{}
  LxCom2{}
  LxRaw{name: String}
  LxRawLt{name: String}
  LxRawBang{name: String}
  LxRawBang1{name: String}
  LxRawEnd{name: String, rest: String}
  LxRawShut{name: String}
  LxBad{}

# the state and the tokens so far, reversed
type Run is Data:
  Run{st: Lx, acc: List<&2, H.Tok>}

def Lx.bad(acc: List<&2, H.Tok>) -> Run:
  Run{LxBad{}, acc}

def Lx.flush(buf: String, acc: List<&2, H.Tok>) -> List<&2, H.Tok>:
  match buf:
    case SNil{}:
      acc
    case SCon{h, t}:
      H.TText{String.reverse(SCon{h, t})} <> acc

# an attribute the laws read joins the tag; every other one is dropped
def Lx.push(key: H.Key, val: String, attrs: List<&2, H.Attr>) -> List<&2, H.Attr>:
  match key:
    case H.KOther{}:
      attrs
    case _:
      H.Attr{key, String.reverse(val)} <> attrs

def Lx.after(n: H.Name) -> Lx:
  match n:
    case H.NBanned{}:
      LxBad{}
    case _:
      LxText{SNil{}}

def Lx.next(r: Maybe<&2, String>, n: H.Name) -> Lx:
  match r:
    case Some{name}:
      LxRaw{name}
    case None{}:
      Lx.after(n)

def Lx.emit(shut: Bool, name: String, attrs: List<&2, H.Attr>, acc: List<&2, H.Tok>) -> Run:
  match shut:
    case True{}:
      Run{LxText{SNil{}}, H.TShut{H.Html.name(String.reverse(name))} <> acc}
    case False{}:
      +n = H.Html.name(String.reverse(name))
      Run{Lx.next(H.Html.raw(n), n), H.TOpen{n, List.reverse(&2, H.Attr, attrs)} <> acc}

def Lx.text(c: Char, buf: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{60}:
      Run{LxLt{buf}, acc}
    case Chr{0}:
      Lx.bad(acc)
    case c:
      Run{LxText{SCon{c, buf}}, acc}

def Lx.lt(k: H.Ck, buf: String, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CLetter{l}:
      Run{LxName{False{}, SCon{l, SNil{}}}, Lx.flush(buf, acc)}
    case H.CSl{}:
      Run{LxSlash{}, Lx.flush(buf, acc)}
    case H.CBang{}:
      Run{LxBang{}, Lx.flush(buf, acc)}
    case _:
      Lx.bad(acc)

def Lx.slash(k: H.Ck, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CLetter{l}:
      Run{LxName{True{}, SCon{l, SNil{}}}, acc}
    case _:
      Lx.bad(acc)

def Lx.name(k: H.Ck, shut: Bool, name: String, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CLetter{l}:
      Run{LxName{shut, SCon{l, name}}, acc}
    case H.CName{d}:
      Run{LxName{shut, SCon{d, name}}, acc}
    case H.CDash{}:
      Run{LxName{shut, SCon{Chr{45}, name}}, acc}
    case H.CSp{}:
      Run{LxAttrs{shut, name, []}, acc}
    case H.CSl{}:
      Run{LxSelf{shut, name, []}, acc}
    case H.CGt{}:
      Lx.emit(shut, name, [], acc)
    case _:
      Lx.bad(acc)

def Lx.attrs(k: H.Ck, shut: Bool, name: String, attrs: List<&2, H.Attr>, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CSp{}:
      Run{LxAttrs{shut, name, attrs}, acc}
    case H.CGt{}:
      Lx.emit(shut, name, attrs, acc)
    case H.CSl{}:
      Run{LxSelf{shut, name, attrs}, acc}
    case H.CLetter{l}:
      Run{LxKey{shut, name, attrs, SCon{l, SNil{}}}, acc}
    case H.CName{d}:
      Run{LxKey{shut, name, attrs, SCon{d, SNil{}}}, acc}
    case H.CDash{}:
      Run{LxKey{shut, name, attrs, SCon{Chr{45}, SNil{}}}, acc}
    case H.COther{o}:
      Run{LxKey{shut, name, attrs, SCon{o, SNil{}}}, acc}
    case _:
      Lx.bad(acc)

def Lx.key(k: H.Ck, shut: Bool, name: String, attrs: List<&2, H.Attr>, key: String, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CEq{}:
      Run{LxQuote{shut, name, attrs, H.Html.key(String.reverse(key))}, acc}
    case H.CSp{}:
      Run{LxEq{shut, name, attrs, key}, acc}
    case H.CGt{}:
      Lx.emit(shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs), acc)
    case H.CSl{}:
      Run{LxSelf{shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs)}, acc}
    case H.CLetter{l}:
      Run{LxKey{shut, name, attrs, SCon{l, key}}, acc}
    case H.CName{d}:
      Run{LxKey{shut, name, attrs, SCon{d, key}}, acc}
    case H.CDash{}:
      Run{LxKey{shut, name, attrs, SCon{Chr{45}, key}}, acc}
    case H.COther{o}:
      Run{LxKey{shut, name, attrs, SCon{o, key}}, acc}
    case _:
      Lx.bad(acc)

def Lx.eq(k: H.Ck, shut: Bool, name: String, attrs: List<&2, H.Attr>, key: String, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CSp{}:
      Run{LxEq{shut, name, attrs, key}, acc}
    case H.CEq{}:
      Run{LxQuote{shut, name, attrs, H.Html.key(String.reverse(key))}, acc}
    case H.CGt{}:
      Lx.emit(shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs), acc)
    case H.CSl{}:
      Run{LxSelf{shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs)}, acc}
    case H.CLetter{l}:
      Run{LxKey{shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs), SCon{l, SNil{}}}, acc}
    case H.CName{d}:
      Run{LxKey{shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs), SCon{d, SNil{}}}, acc}
    case H.CDash{}:
      Run{LxKey{shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs), SCon{Chr{45}, SNil{}}}, acc}
    case H.COther{o}:
      Run{LxKey{shut, name, Lx.push(H.Html.key(String.reverse(key)), SNil{}, attrs), SCon{o, SNil{}}}, acc}
    case _:
      Lx.bad(acc)

# a double-quoted value the laws do not read
def Lx.dq_skip(key: H.Key, shut: Bool, name: String, attrs: List<&2, H.Attr>, acc: List<&2, H.Tok>) -> Run:
  match key:
    case H.KOther{}:
      Run{LxSkip{shut, name, attrs}, acc}
    case _:
      Run{LxDq{shut, name, attrs, key, SNil{}}, acc}

def Lx.quote(c: Char, shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{32}:
      Run{LxQuote{shut, name, attrs, key}, acc}
    case Chr{9}:
      Run{LxQuote{shut, name, attrs, key}, acc}
    case Chr{10}:
      Run{LxQuote{shut, name, attrs, key}, acc}
    case Chr{12}:
      Run{LxQuote{shut, name, attrs, key}, acc}
    case Chr{13}:
      Run{LxQuote{shut, name, attrs, key}, acc}
    case Chr{34}:
      Lx.dq_skip(key, shut, name, attrs, acc)
    case Chr{39}:
      Run{LxSq{shut, name, attrs, key, SNil{}}, acc}
    case Chr{62}:
      Lx.bad(acc)
    case Chr{60}:
      Lx.bad(acc)
    case Chr{61}:
      Lx.bad(acc)
    case Chr{96}:
      Lx.bad(acc)
    case Chr{38}:
      Lx.bad(acc)
    case c:
      Run{LxBare{shut, name, attrs, key, SCon{c, SNil{}}}, acc}

def Lx.dq(c: Char, shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key, val: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{34}:
      Run{LxAttrs{shut, name, Lx.push(key, val, attrs)}, acc}
    case Chr{38}:
      Lx.bad(acc)
    case c:
      Run{LxDq{shut, name, attrs, key, SCon{c, val}}, acc}

def Lx.skip(c: Char, shut: Bool, name: String, attrs: List<&2, H.Attr>, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{34}:
      Run{LxAttrs{shut, name, attrs}, acc}
    case _:
      Run{LxSkip{shut, name, attrs}, acc}

def Lx.sq(c: Char, shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key, val: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{39}:
      Run{LxAttrs{shut, name, Lx.push(key, val, attrs)}, acc}
    case Chr{38}:
      Lx.bad(acc)
    case c:
      Run{LxSq{shut, name, attrs, key, SCon{c, val}}, acc}

def Lx.bare(c: Char, shut: Bool, name: String, attrs: List<&2, H.Attr>, key: H.Key, val: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{32}:
      Run{LxAttrs{shut, name, Lx.push(key, val, attrs)}, acc}
    case Chr{9}:
      Run{LxAttrs{shut, name, Lx.push(key, val, attrs)}, acc}
    case Chr{10}:
      Run{LxAttrs{shut, name, Lx.push(key, val, attrs)}, acc}
    case Chr{12}:
      Run{LxAttrs{shut, name, Lx.push(key, val, attrs)}, acc}
    case Chr{13}:
      Run{LxAttrs{shut, name, Lx.push(key, val, attrs)}, acc}
    case Chr{62}:
      Lx.emit(shut, name, Lx.push(key, val, attrs), acc)
    case Chr{34}:
      Lx.bad(acc)
    case Chr{39}:
      Lx.bad(acc)
    case Chr{60}:
      Lx.bad(acc)
    case Chr{61}:
      Lx.bad(acc)
    case Chr{96}:
      Lx.bad(acc)
    case Chr{38}:
      Lx.bad(acc)
    case c:
      Run{LxBare{shut, name, attrs, key, SCon{c, val}}, acc}

def Lx.closed(b: Bool, shut: Bool, name: String, attrs: List<&2, H.Attr>, acc: List<&2, H.Tok>) -> Run:
  match b:
    case True{}:
      Lx.emit(shut, name, attrs, acc)
    case False{}:
      Lx.bad(acc)

# "/>" ends only an element with no end tag (a browser holds any other one
# open, but closes it inside svg or math)
def Lx.self(k: H.Ck, shut: Bool, +name: String, attrs: List<&2, H.Attr>, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CGt{}:
      Lx.closed(H.Html.void(H.Html.name(String.reverse(name))), shut, name, attrs, acc)
    case _:
      Lx.bad(acc)

def Lx.bang(k: H.Ck, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CDash{}:
      Run{LxBang1{}, acc}
    case H.CLetter{l}:
      Run{LxDecl{}, acc}
    case _:
      Lx.bad(acc)

def Lx.bang1(k: H.Ck, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CDash{}:
      Run{LxComS{}, acc}
    case _:
      Lx.bad(acc)

def Lx.decl(c: Char, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{62}:
      Run{LxText{SNil{}}, acc}
    case Chr{60}:
      Lx.bad(acc)
    case _:
      Run{LxDecl{}, acc}

def Lx.com_s(c: Char, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{62}:
      Lx.bad(acc)
    case Chr{45}:
      Run{LxComS1{}, acc}
    case _:
      Run{LxCom0{}, acc}

def Lx.com_s1(c: Char, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{62}:
      Lx.bad(acc)
    case Chr{45}:
      Run{LxCom2{}, acc}
    case _:
      Run{LxCom0{}, acc}

def Lx.com0(c: Char, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{45}:
      Run{LxCom1{}, acc}
    case _:
      Run{LxCom0{}, acc}

def Lx.com1(c: Char, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{45}:
      Run{LxCom2{}, acc}
    case _:
      Run{LxCom0{}, acc}

def Lx.com2(c: Char, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{62}:
      Run{LxText{SNil{}}, acc}
    case Chr{45}:
      Run{LxCom2{}, acc}
    case Chr{33}:
      Lx.bad(acc)
    case _:
      Run{LxCom0{}, acc}

def Lx.raw(c: Char, name: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{60}:
      Run{LxRawLt{name}, acc}
    case _:
      Run{LxRaw{name}, acc}

def Lx.raw_lt(c: Char, +name: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{47}:
      Run{LxRawEnd{name, name}, acc}
    case Chr{33}:
      Run{LxRawBang{name}, acc}
    case Chr{60}:
      Run{LxRawLt{name}, acc}
    case _:
      Run{LxRaw{name}, acc}

def Lx.raw_bang(c: Char, name: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{45}:
      Run{LxRawBang1{name}, acc}
    case Chr{60}:
      Run{LxRawLt{name}, acc}
    case _:
      Run{LxRaw{name}, acc}

def Lx.raw_bang1(c: Char, name: String, acc: List<&2, H.Tok>) -> Run:
  match c:
    case Chr{45}:
      Lx.bad(acc)
    case Chr{60}:
      Run{LxRawLt{name}, acc}
    case _:
      Run{LxRaw{name}, acc}

# raw text after "</" and part of its name: rest is the part left
def Lx.raw_miss(k: H.Ck, name: String, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CLt{}:
      Run{LxRawLt{name}, acc}
    case _:
      Run{LxRaw{name}, acc}

def Lx.raw_next(rest: String, name: String, acc: List<&2, H.Tok>) -> Run:
  match rest:
    case SNil{}:
      Run{LxRawShut{name}, acc}
    case SCon{h, t}:
      Run{LxRawEnd{name, SCon{h, t}}, acc}

def Lx.raw_hit(b: Bool, rest: String, name: String, acc: List<&2, H.Tok>) -> Run:
  match b:
    case True{}:
      Lx.raw_next(rest, name, acc)
    case False{}:
      Run{LxRaw{name}, acc}

def Lx.raw_cmp(k: H.Ck, h: Char, rest: String, name: String, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CLetter{l}:
      Lx.raw_hit(Char.is_eq(l, h), rest, name, acc)
    case _:
      Lx.raw_miss(k, name, acc)

def Lx.raw_end(k: H.Ck, name: String, rest: String, acc: List<&2, H.Tok>) -> Run:
  match rest:
    case SNil{}:
      Lx.bad(acc)
    case SCon{h, t}:
      Lx.raw_cmp(k, h, t, name, acc)

def Lx.raw_shut(k: H.Ck, +name: String, acc: List<&2, H.Tok>) -> Run:
  match k:
    case H.CGt{}:
      Run{LxText{SNil{}}, H.TShut{H.Html.name(name)} <> acc}
    case H.CSp{}:
      Run{LxAttrs{True{}, String.reverse(name), []}, acc}
    case H.CSl{}:
      Run{LxSelf{True{}, String.reverse(name), []}, acc}
    case _:
      Lx.raw_miss(k, name, acc)

def Lx.step(st: Lx, c: Char, acc: List<&2, H.Tok>) -> Run:
  match st:
    case LxText{buf}:
      Lx.text(c, buf, acc)
    case LxSkip{shut, name, attrs}:
      Lx.skip(c, shut, name, attrs, acc)
    case LxRaw{name}:
      Lx.raw(c, name, acc)
    case LxDq{shut, name, attrs, key, val}:
      Lx.dq(c, shut, name, attrs, key, val, acc)
    case LxAttrs{shut, name, attrs}:
      Lx.attrs(H.Ck.of(c), shut, name, attrs, acc)
    case LxKey{shut, name, attrs, key}:
      Lx.key(H.Ck.of(c), shut, name, attrs, key, acc)
    case LxQuote{shut, name, attrs, key}:
      Lx.quote(c, shut, name, attrs, key, acc)
    case LxName{shut, name}:
      Lx.name(H.Ck.of(c), shut, name, acc)
    case LxLt{buf}:
      Lx.lt(H.Ck.of(c), buf, acc)
    case LxSlash{}:
      Lx.slash(H.Ck.of(c), acc)
    case LxEq{shut, name, attrs, key}:
      Lx.eq(H.Ck.of(c), shut, name, attrs, key, acc)
    case LxSq{shut, name, attrs, key, val}:
      Lx.sq(c, shut, name, attrs, key, val, acc)
    case LxBare{shut, name, attrs, key, val}:
      Lx.bare(c, shut, name, attrs, key, val, acc)
    case LxSelf{shut, name, attrs}:
      Lx.self(H.Ck.of(c), shut, name, attrs, acc)
    case LxBang{}:
      Lx.bang(H.Ck.of(c), acc)
    case LxBang1{}:
      Lx.bang1(H.Ck.of(c), acc)
    case LxDecl{}:
      Lx.decl(c, acc)
    case LxComS{}:
      Lx.com_s(c, acc)
    case LxComS1{}:
      Lx.com_s1(c, acc)
    case LxCom0{}:
      Lx.com0(c, acc)
    case LxCom1{}:
      Lx.com1(c, acc)
    case LxCom2{}:
      Lx.com2(c, acc)
    case LxRawLt{name}:
      Lx.raw_lt(c, name, acc)
    case LxRawBang{name}:
      Lx.raw_bang(c, name, acc)
    case LxRawBang1{name}:
      Lx.raw_bang1(c, name, acc)
    case LxRawEnd{name, rest}:
      Lx.raw_end(H.Ck.of(c), name, rest, acc)
    case LxRawShut{name}:
      Lx.raw_shut(H.Ck.of(c), name, acc)
    case LxBad{}:
      Lx.bad(acc)

def Lx.str(s: String, r: Run) -> Run:
  match s r:
    case SNil{} r:
      r
    case SCon{c, t} Run{st, acc}:
      Lx.str(t, Lx.step(st, c, acc))

def Lx.all(cs: List<&2, String>, r: Run) -> Run:
  match cs:
    case Nil{}:
      r
    case Con{s, t}:
      Lx.all(t, Lx.str(s, r))

def Lx.done(st: Lx, acc: List<&2, H.Tok>) -> Maybe<&2, List<&2, H.Tok>>:
  match st:
    case LxText{buf}:
      Some{List.reverse(&2, H.Tok, Lx.flush(buf, acc))}
    case _:
      None{}

def Lx.fin(r: Run) -> Maybe<&2, List<&2, H.Tok>>:
  match r:
    case Run{st, acc}:
      Lx.done(st, acc)
