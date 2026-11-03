# gildrb.com: the proofs
# ======================
#
# Each law of laws/site/ is proven in its own file in proof/site/, from the
# lemmas in proof/base.bend. `bend PROOF.bend --verdict` checks them all.

import Base
import ./LAWS.bend as Laws
import ./proof/site/home/home_text.bend as HomeText
import ./proof/site/home/home_shown.bend as HomeShown
import ./proof/site/home/rows.bend as Rows
import ./proof/site/home/groups.bend as Groups
import ./proof/site/pages/outline.bend as Outline
import ./proof/site/pages/no_contents.bend as NoContents
import ./proof/site/agents/poppy.bend as Poppy
