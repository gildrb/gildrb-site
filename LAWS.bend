# gildrb.com: the laws
# ====================
#
# Each law is a claim about the site as `vp build` ships it: the bytes of
# every HTML page of dist/ and of dist/.well-known/poppy.json, which
# scripts/site.py writes into site/site.bend (S.Site.pages, S.Site.files).
# A page is read as a browser reads it (laws/site/base/html/).
# PROOF.bend proves every law; `bend PROOF.bend --verdict` checks them.
#
# Requirements
#
# R1 The homepage carries its text in its raw HTML, for a reader without JavaScript: at least 500 characters, and at least 5% of the body markup (scripts left out).
# R2 The homepage has exactly one h1.
# R3 A page with a contents nav links every part from it: each link targets an h2 of the page by id, and there is more than one link.
# R4 A page that fits a screen or two lists no contents: archetypon and porthmeus.
# R5 Each row of the homepage's project table is named by what it shows: its aria-labelledby is exactly its title, descriptor and end ids, and each id is on the page.
# R6 The homepage lists maintained projects (Projects) before design work (Work), whatever their dates.
# R7 /.well-known/poppy.json declares the public website of this domain and nothing it does not serve: {protocol_version: "0.1", organization: {name: "Gil Rodrigues", domain: <the site's host>}, web: {}}.
# A1 The site's host is the host of the homepage's one canonical URL (a link whose rel names "canonical", any letter case).
# A3 Text hidden by CSS counts as shown: the laws read HTML, not CSS; the hidden attribute they read (home_shown).
# A4 Scripts are not read: what a page's scripts, event handlers or javascript: URLs do when they run is not checked.
# A5 A group of the project table is an h3 element, named by its text: an element given a heading role, an accessible name or a heading's look by ARIA or CSS is not read as one.
# A6 The host sends every page as text/html; charset=utf-8 (gildrb.com does), which a browser follows over any charset a page declares: the laws read each page's bytes as UTF-8.
# A2 HTML the lexer cannot read as a browser does, or whose tags a browser would build into another tree (moving, cloning or dropping an element; laws/site/base/html/), is a bug: every law that reads that page fails.

import Base
import ./laws/site/home/text.bend as HomeText
import ./laws/site/home/rows.bend as HomeRows
import ./laws/site/home/groups.bend as HomeGroups
import ./laws/site/pages.bend as PagesLaws
import ./laws/site/agents.bend as AgentsLaws
