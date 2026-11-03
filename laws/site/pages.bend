# gildrb.com's laws: every page (R2, R3, R4)
# ==========================================
#
# The terms shared by every section are in base/page.bend; LAWS.bend lists
# the requirements.

import Base
import ../../site/site.bend as S
import ./base/html/tokens.bend as H
import ./base/html/tree.bend as T
import ./base/page.bend as Laws
import ./agents.bend as Agents

# Terms
# -----

def Spec.h1s(ts: List<&2, H.Tok>) -> Nat:
  match ts:
    case Nil{}:
      0n
    case Con{H.TOpen{H.NH1{}, attrs}, t}:
      1n+Spec.h1s(t)
    case Con{x, t}:
      Spec.h1s(t)

# a page's contents nav (a nav with the attribute data-contents): none,
# the targets of its links, or a shape the laws refuse
type Nav is Data:
  NoNav{}
  Nav{links: List<&2, String>}
  BadNav{}

type NavAt is Data:
  NavBefore{}
  NavIn{links: List<&2, String>}
  NavAfter{links: List<&2, String>}

# "~:" begins t
def Frag.dir(t: String) -> Bool:
  match t:
    case SCon{Chr{a}, SCon{Chr{b}, r}}:
      U32.is_eq(a, 126) && U32.is_eq(b, 58)
    case _:
      False{}

# printable ASCII but '"', "<", ">" and "`" (a URL parser strips, drops or
# percent-encodes any other character, and a browser looks the encoded
# form up first), and no ":~:", which begins a directive a browser strips
# (such as a text to scroll to)
def Target.char(+x: U32) -> Bool:
  U32.is_lt(32, x) && U32.is_lt(x, 127) && Bool.not(U32.is_eq(x, 34) || U32.is_eq(x, 60) || U32.is_eq(x, 62) || U32.is_eq(x, 96))

def Target.clean(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{Chr{+x}, +t}:
      Target.char(x) && Bool.not(U32.is_eq(x, 58) && Frag.dir(t)) && Target.clean(t)

def Target.of(+id: String) -> Maybe<&2, String>:
  Bool.pick(Maybe<&2, String>, Bool.not(String.is_empty(id)) && Target.clean(id), Some{id}, None{})

# an in-page link's target: the href after "#", not empty, of printable
# ASCII but '"', "<", ">" and "`", without ":~:"
def Spec.target(m: Maybe<&2, String>) -> Maybe<&2, String>:
  match m:
    case Some{SCon{Chr{35}, id}}:
      Target.of(id)
    case _:
      None{}

def Nav.open(b: Bool) -> NavAt:
  match b:
    case True{}:
      NavIn{[]}
    case False{}:
      NavBefore{}

def Nav.link(m: Maybe<&2, String>, links: List<&2, String>) -> Maybe<&2, NavAt>:
  match m:
    case None{}:
      None{}
    case Some{id}:
      Some{NavIn{id <> links}}

def Nav.second(b: Bool, links: List<&2, String>) -> Maybe<&2, NavAt>:
  match b:
    case True{}:
      None{}
    case False{}:
      Some{NavAfter{links}}

# another element with href (area, link) in the contents nav: refused
def Nav.other(b: Bool, links: List<&2, String>) -> Maybe<&2, NavAt>:
  match b:
    case True{}:
      None{}
    case False{}:
      Some{NavIn{links}}

# one tag moves the walk on; None: a link without "#", another element
# with href or a nav inside the contents nav, a second contents nav
def Nav.step(at: NavAt, x: H.Tok) -> Maybe<&2, NavAt>:
  match at x:
    case NavBefore{} H.TOpen{H.NNav{}, attrs}:
      Some{Nav.open(Laws.Spec.has(H.KContents{}, attrs))}
    case NavBefore{} x:
      Some{NavBefore{}}
    case NavIn{links} H.TOpen{H.NA{}, attrs}:
      Nav.link(Spec.target(Laws.Spec.attr(H.KHref{}, attrs)), links)
    case NavIn{links} H.TOpen{H.NNav{}, attrs}:
      None{}
    case NavIn{links} H.TOpen{n, attrs}:
      Nav.other(Laws.Spec.has(H.KHref{}, attrs), links)
    case NavIn{links} H.TShut{H.NNav{}}:
      Some{NavAfter{links}}
    case NavIn{links} x:
      Some{NavIn{links}}
    case NavAfter{links} H.TOpen{H.NNav{}, attrs}:
      Nav.second(Laws.Spec.has(H.KContents{}, attrs), links)
    case NavAfter{links} x:
      Some{NavAfter{links}}

def Nav.end(at: NavAt) -> Nav:
  match at:
    case NavBefore{}:
      NoNav{}
    case NavIn{links}:
      BadNav{}
    case NavAfter{links}:
      Nav{List.reverse(&2, String, links)}

def Nav.go(ts: List<&2, H.Tok>, m: Maybe<&2, NavAt>) -> Nav:
  match ts m:
    case ts None{}:
      BadNav{}
    case Nil{} Some{at}:
      Nav.end(at)
    case Con{x, t} Some{at}:
      Nav.go(t, Nav.step(at, x))

def Spec.nav(ts: List<&2, H.Tok>) -> Nav:
  Nav.go(ts, Some{NavBefore{}})

def H2.at(m: Maybe<&2, String>, rest: Maybe<&2, List<&2, String>>) -> Maybe<&2, List<&2, String>>:
  match m rest:
    case Some{id} Some{ids}:
      Some{id <> ids}
    case _ _:
      None{}

# the id of every h2, in order; None when one has no id
def Spec.h2s(ts: List<&2, H.Tok>) -> Maybe<&2, List<&2, String>>:
  match ts:
    case Nil{}:
      Some{[]}
    case Con{H.TOpen{H.NH2{}, attrs}, t}:
      H2.at(Laws.Spec.attr(H.KId{}, attrs), Spec.h2s(t))
    case Con{x, t}:
      Spec.h2s(t)

def Contents.same(links: List<&2, String>, m: Maybe<&2, List<&2, String>>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{ids}:
      Laws.Spec.same(links, ids)

# every link's target is an id exactly once on the page (a browser goes to
# the first element with the id)
def Contents.once(links: List<&2, String>, +ids: List<&2, String>) -> Bool:
  match links:
    case Nil{}:
      True{}
    case Con{l, t}:
      Nat.is_eq(Laws.Spec.count(ids, l), 1n) && Contents.once(t, ids)

def Contents.ok(nav: Nav, m: Maybe<&2, List<&2, String>>, ids: List<&2, String>) -> Bool:
  match nav:
    case NoNav{}:
      True{}
    case Nav{+links}:
      Nat.is_le(2n, List.length(&2, String, links)) && Contents.same(links, m) && Contents.once(links, ids)
    case BadNav{}:
      False{}

def Outline.of(m: Maybe<&2, List<&2, H.Tok>>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{+ts}:
      Nat.is_eq(Spec.h1s(ts), 1n) && Contents.ok(Spec.nav(ts), Spec.h2s(ts), Laws.Spec.ids(ts))

# a page's outline holds: one h1; a contents nav, if any, links its h2s
def Spec.outline(text: List<&2, String>) -> Bool:
  Outline.of(T.Html.toks(text))

# s holds "data-contents"
def Dc.go(s: String) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{Chr{100}, SCon{Chr{97}, SCon{Chr{116}, SCon{Chr{97}, SCon{Chr{45}, SCon{Chr{99}, SCon{Chr{111}, SCon{Chr{110}, SCon{Chr{116}, SCon{Chr{101}, SCon{Chr{110}, SCon{Chr{116}, SCon{Chr{115}, t}}}}}}}}}}}}}:
      True{}
    case SCon{c, t}:
      Dc.go(t)

# the page exists and holds no "data-contents", in any letter case
def Spec.lacks(m: Maybe<&2, List<&2, String>>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{text}:
      Bool.not(Dc.go(Laws.Low.go(Laws.Spec.cat(text))))

# the part of an href after its first "#", if any
def Frag.of(s: String) -> Maybe<&2, String>:
  match s:
    case SNil{}:
      None{}
    case SCon{Chr{35}, t}:
      Some{t}
    case SCon{c, t}:
      Frag.of(t)

# a fragment a browser looks up as written: no space or control character
# (a URL parser trims or drops it), no "%" (decoded first), no ":~:" (a
# directive, such as a text to scroll to)
def Frag.ok(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{Chr{+x}, +t}:
      U32.is_lt(32, x) && Bool.not(U32.is_eq(x, 37)) && Bool.not(U32.is_eq(x, 58) && Frag.dir(t)) && Frag.ok(t)

# the id of every element before the page's first h2
def Early.go(ts: List<&2, H.Tok>) -> List<&2, String>:
  match ts:
    case Nil{}:
      []
    case Con{H.TOpen{H.NH2{}, attrs}, t}:
      []
    case Con{H.TOpen{n, attrs}, t}:
      Laws.Spec.ids.at(Laws.Spec.attr(H.KId{}, attrs), Early.go(t))
    case Con{x, t}:
      Early.go(t)

# a fragment a browser looks up as written that is empty (the top) or the
# id of an element in early
def Toc.frag(m: Maybe<&2, String>, +early: List<&2, String>) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{+f}:
      Frag.ok(f) && (String.is_empty(f) || Nat.is_le(1n, Laws.Spec.count(early, f)))

# the host of an absolute http or https URL, when it is a host name a URL
# parser reads as written (Agents.Labels.ok) followed by "/", "?", "#" or
# the end; None for any other href
def Abs.end(acc: String) -> Maybe<&2, String>:
  +h = String.reverse(acc)
  Bool.pick(Maybe<&2, String>, Agents.Labels.ok(Agents.Dots.go(h, SNil{}, [])), Some{h}, None{})

def Abs.go(s: String, acc: String) -> Maybe<&2, String>:
  match s:
    case SNil{}:
      Abs.end(acc)
    case SCon{Chr{47}, t}:
      Abs.end(acc)
    case SCon{Chr{63}, t}:
      Abs.end(acc)
    case SCon{Chr{35}, t}:
      Abs.end(acc)
    case SCon{+c, t}:
      Bool.pick(Maybe<&2, String>, Agents.Host.char(c), Abs.go(t, SCon{c, acc}), None{})

def Abs.host(s: String) -> Maybe<&2, String>:
  match s:
    case SCon{Chr{104}, SCon{Chr{116}, SCon{Chr{116}, SCon{Chr{112}, SCon{Chr{115}, SCon{Chr{58}, SCon{Chr{47}, SCon{Chr{47}, rest}}}}}}}}:
      Abs.go(rest, SNil{})
    case SCon{Chr{104}, SCon{Chr{116}, SCon{Chr{116}, SCon{Chr{112}, SCon{Chr{58}, SCon{Chr{47}, SCon{Chr{47}, rest}}}}}}}:
      Abs.go(rest, SNil{})
    case _:
      None{}

# the href goes to another site: an absolute URL whose host is not the
# site's (site: the homepage's canonical host, A1)
def Off.site(m: Maybe<&2, String>, site: Maybe<&2, String>) -> Bool:
  match m site:
    case Some{h} Some{s}:
      Bool.not(String.eq(h, s))
    case _ _:
      False{}

def Toc.link(m: Maybe<&2, String>, +early: List<&2, String>, +site: Maybe<&2, String>) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{+h}:
      Off.site(Abs.host(h), site) || Toc.frag(Frag.of(h), early)

# every href a reader can follow (any element's but a link element's)
# goes to another site, or, if it has a "#", before the page's parts
def Toc.go(ts: List<&2, H.Tok>, +early: List<&2, String>, +site: Maybe<&2, String>) -> Bool:
  match ts:
    case Nil{}:
      True{}
    case Con{H.TOpen{H.NLink{}, attrs}, t}:
      Toc.go(t, early, site)
    case Con{H.TOpen{n, attrs}, t}:
      Toc.link(Laws.Spec.attr(H.KHref{}, attrs), early, site) && Toc.go(t, early, site)
    case Con{x, t}:
      Toc.go(t, early, site)

def Toc.none(m: Maybe<&2, List<&2, H.Tok>>, site: Maybe<&2, String>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{+ts}:
      Toc.go(ts, Early.go(ts), site)

# the site's host: the homepage's canonical host (A1)
def Spec.site() -> Maybe<&2, String>:
  Agents.Poppy.host(Laws.Spec.toks(Laws.Spec.page("index.html")))

# the page lists no contents: no "data-contents", in any letter case, and
# no in-page link into its parts
def Spec.no_toc(+m: Maybe<&2, List<&2, String>>, site: Maybe<&2, String>) -> Bool:
  Spec.lacks(m) && Toc.none(Laws.Spec.toks(m), site)

# Laws
# ----

# LAW outline: every HTML page of the site has exactly one h1; a page
# with a contents nav (a nav with data-contents; inside it no other nav
# and no element with href but links) links every h2 of the page by id
# ("#<id>", the id not empty, of printable ASCII but '"', "<", ">" and
# "`", without ":~:", on the page exactly once), in page order, and at
# least two; a page has at most one contents nav. A page a browser could
# read another way, or build another tree, fails (base/html/). (R2, R3)
law outline:
  for +path: String
  for +text: List<&2, String>
  for at: {Laws.Spec.page(path) == Some{text} : Maybe<&2, List<&2, String>>}
  {Spec.outline(text) == True{} : Bool}

# LAW no_contents: archetypon.html and porthmeus.html exist, hold no
# "data-contents" in any letter case anywhere in their bytes, and on any
# element but a link element every href with a "#" either goes to another
# site (an absolute http or https URL whose host, a well-formed host name,
# is not the homepage's canonical host) or has a fragment (after its first
# "#") with no space, control character, "%" or ":~:" that is empty or the
# id of an element before the page's first h2: an in-page link goes only
# to what comes before the page's parts. What scripts do is NOT checked
# (A4). A page a browser could read another way, or build another tree,
# fails (R4).
law no_contents:
  {Spec.no_toc(Laws.Spec.page("archetypon.html"), Spec.site()) && Spec.no_toc(Laws.Spec.page("porthmeus.html"), Spec.site()) == True{} : Bool}
