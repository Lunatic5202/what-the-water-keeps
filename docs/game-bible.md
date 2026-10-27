# What the Water Keeps: Game Bible

Complete design reference in 5 parts. The prototype implements only a small slice of it; see the README for current status.

# Part 1: Full Script and World


A dreamy 2D Souls-like platformer. Cute on the surface, with a much deeper meaning underneath.

---

## 0. AT A GLANCE

**Premise:** Lumi, a small lantern-carrying wanderer, wakes beside a still pond with no memory. Seven doors stand in a ring around it, each leading to a land built from one of humanity's seven sins. At the center of the ring is the Mirror Gate. Behind it waits the last boss: Lumi's own reflection.

**Core rule:** There are no buffs. If you ignore a region's mechanic, the world punishes you with a debuff. Every mechanic is also a moral lesson.

**Hidden truth:** Every boss was once something kind. Each sin is a good thing that went too far. The final boss is everything Lumi refused to look at.

### Regions, artifacts, gadgets

| # | Region | Sin | Debuff | Boss | Artifact (new fighting style) | Gadget (traversal) |
|---|--------|-----|--------|------|-------------------------------|--------------------|
| 0 | The Wake | none | none | none | none | Wind Ribbon (Dash) |
| 1 | The Gilded Garden | Greed | Weight | The Collector | The Open Hand (Offering Style) | Featherweight Charm (Double Jump) |
| 2 | Slumber Hollow | Sloth | Drowse | The Dreamer | Hourglass Shard (Tempo Style) | Snail Grips (Wall Climb) |
| 3 | The Endless Table | Gluttony | Stuffed | The Host | The Hollow Spoon (Devour Style) | Hungry Wind Scarf (Super Dash) |
| 4 | The Gallery of Glass | Envy | Comparison | The Understudy | Green Mirror Shard (Mimic Style) | Mirror Hairpin (Glass Step) |
| 5 | The Ribbon Orchard | Lust (longing and obsession) | Fixation | The Devoted | Red Thread Spool (Tether Style) | Thread Needle (Grapple) |
| 6 | The Ashen Kettle | Wrath | Rage | The Boiling One | The Cooled Ember (Ember Style) | Ember Boots (Ground Pound) |
| 7 | The Tower of Applause | Pride | Hubris | The Champion | The Bowed Crown (Humble Style) | Halo Cloak (Glide) |
| 8 | The Mirror Gate | the eighth sin | none | Your Reflection | none | all gadgets required |

### Gating chain (each region needs the gadget before it)

Dash (The Wake) leads to Greed. Double Jump (Greed) leads to Sloth. Wall Climb (Sloth) leads to Gluttony. Super Dash (Gluttony) leads to Envy. Glass Step (Envy) leads to Lust. Grapple (Lust) leads to Wrath. Ground Pound (Wrath) leads to Pride. Glide (Pride) leads to the Memory Path and the Mirror Gate. Every region has hidden areas that can only be reached with later gadgets, so the player comes back.

### Fighting styles (set a loadout of 3 at the hub altar; cycle in the field. Full movesets in Part 4)

| Style | Feel | Gimmick |
|-------|------|---------|
| Default (Lantern Swing) | balanced | none |
| Offering Style | wide, slow palm waves | spending carried gold powers hits and clears weight |
| Tempo Style | precise, counter-focused | a perfect-timed block slows time for 1 second |
| Devour Style | close range, hungry | absorbs projectiles and converts them to charge |
| Mimic Style | tricky | copies the last enemy attack you took, once |
| Tether Style | mid range ribbon whip | pulls enemies in or pulls you to them |
| Ember Style | heavy, charged | holding still builds a stronger strike (patience as power) |
| Humble Style | low, evasive, counter-slashes | summons spirits of defeated bosses as brief helpers |

---

## 1. THE CAST

- **LUMI:** the player. Silent except for small sounds. Carries a paper lantern. Rounded, soft, big eyes.
- **NIM:** a tiny moth-spirit who lives in the lantern. Gentle, curious, a little scared. Guides Lumi. Nim is the only one who speaks to Lumi kindly in every region.
- **THE REFLECTION:** Lumi's mirror-self. Speaks only through water and glass. At first its voice is a whisper, later warm, later heavy. It always lags one beat behind Lumi's movements in the hub pond, and always smiles a little too long.
- **THE SEVEN BOSSES:** each cute, each sad.

---

## 2. THE HUB: THE STILL POND (Lantern Landing)

A circular lakeside shrine under a pastel sky. A glass-calm pond in the center. Seven arched doors in a ring, each sealed, each marked with a sleeping symbol. In the middle, past the pond, the Mirror Gate: tall, silent, sealed by seven keyholes.

**Hub features:**
- **The Pond:** the Reflection appears here between regions. Its mood changes over time.
- **The Altar of Hands:** choose your loadout of 3 fighting styles here (cycle between them in the field).
- **The Bench of Rest:** heal and save.
- **Nim's Lantern Post:** talk to Nim for hints.
- **The Memory Tree:** collectible Memory Petals (hidden in every region) add short lore lines to its branches.
- **Visual change:** with each region cleared, the hub gets brighter and prettier, but the music detunes slightly and the pond reflection starts to look at Lumi a little too long.

### Hub dialogue: arrival (game start)

*(Lumi wakes beside the pond. A tiny glow flutters out of the lantern.)*

NIM: Oh! You're awake. Hello. I'm Nim. I live in your lantern. I think. I've been in it a very long time.

NIM: Do you remember anything? No? ...That's okay. Neither do I. Isn't that funny?

*(Lumi looks into the pond. The reflection waves a moment late.)*

NIM: That's you. Though... it waved after you did. Hmm. Probably nothing.

REFLECTION (whisper, from the water): You came back.

NIM: Did you hear that?

*(Lumi nods.)*

NIM: It's coming from the Gate. See the seven keyholes? I think we need seven keys. And there are seven doors. I think the doors are the way.

NIM: Let's start small. Come on, I'll teach you to move.

### The Wake (tutorial)
A short meadow of soft grass and floating petals. Tutorial signs are written by Nim in crayon.

Teaches: move, jump, light attack, heal (limited charges), and **Dash**.

*(Signs and Nim's lines)*
- Sign 1: "Walk! (it's easy, I believe in you)"
- Sign 2: "Jump over the tiny puddle."
- Sign 3: "Swing your lantern. Hit the little jelly. He is very forgiving."
- Sign 4: "Healing takes a moment. Be brave, but not silly."

At the end, Lumi passes Old Moss, a gentle tutorial boss (see Part 5), and finds the **Wind Ribbon**.

NIM: A ribbon! It's humming. Try dashing. Pretend you're a leaf in a breeze.

*(Dash unlocks. Lumi dashes across a gap to reach the first door: GREED.)*

NIM: Door one. The little gold flowers on it look so pretty. I don't know why that makes me nervous.

---

## 3. REGION 1: THE GILDED GARDEN (GREED)

**Look:** a golden garden of glittering flowers, coin fountains, honey-colored sunlight. It looks like a dream of being rich and safe.

**Mechanic (Weight):** every coin you carry adds weight. The heavier you are, the slower you move, the lower you jump, the weaker your dash. Gold is optional but tempting. Offer it at shrines to lift the debuff. Passing a shrine with a full purse applies **Burden** until you give gold away.

**Debuff text:** *"BURDEN: You held on too tightly."*

**Monsters:**
- **Penny Pips:** coin-bodied bunnies that hop in swarms. A hit sticks a coin to you; dash to shake it off.
- **Magpie Thieves:** swoop in, steal your gold, flee. Killing one gives it back.
- **Chest Mimics:** glowing treasure chests with big eyes. Walk up to loot and they bite.
- **Gilded Blossoms:** stationary golden flowers that spit sticky sap (heavy weight). Placed next to gold piles.

**Lore tablets (Greed):**
1. "I only wanted enough. Then enough was a little more."
2. "The flowers grew from the coins we dropped. Nobody remembered who dropped them."
3. "I counted it every night so I wouldn't have to count what I'd lost."

### Dialogue

NIM (entering): It's so pretty! Careful. Things that shine are usually watching.

*(First shrine)*
NIM: A little bowl. It says "give what you carry." Odd. I thought we were supposed to collect things.

*(First time Lumi is slowed by weight)*
NIM: You're slower. It's the coins. Maybe... put some down?

*(Magpie steals gold)*
NIM: Hey! He took it! Well... maybe that's fine. You didn't need all of it.

*(Chest Mimic bites)*
NIM: That's the thing about free treasure. Someone made sure it was free.

*(Pre-boss: The Collector's mountain)*

THE COLLECTOR: Oh. A visitor. Come, come, sit. Isn't it all lovely? I've kept it all safe.

THE COLLECTOR: Nobody takes what's mine anymore. Not like before. I had a family once. A cozy house. Then the winter came and it all slipped away. So I held on. Tighter. Tighter.

NIM: He sounds sad.

THE COLLECTOR: Sad? I'm not sad. I'm *full*. I have so much.

*(Boss fight: see boss design below.)*

**BOSS: THE COLLECTOR**
A giant, round, golden plush bear in a tiny crown, sitting on a mountain of coins.
- **Phase 1, Coin Rain:** throws coins, belly slam. Missed coins become pickups to tempt you.
- **Phase 2, Feast:** swallows the coin mountain and grows. The arena shrinks. Growth speed scales with your carried gold.
- **Phase 3, Hunger:** lunges for your purse. A grab steals all gold and heals him. If you carry nothing, the grab whiffs and he staggers.
- **Offering bowls** let you drop gold to shrink him and lighten yourself.

*(Mid-fight)*
THE COLLECTOR: Give it back! It's mine! It's all I have!
THE COLLECTOR: If I let go of one thing, I'll let go of everything!

*(If Lumi offers gold to a bowl during the fight)*
THE COLLECTOR: Why would you... why would you just *give* it?

*(Defeat: he shrinks into a tiny crying bear holding one coin.)*

THE COLLECTOR: I only wanted to keep them. I only wanted to keep everyone.

NIM: ...You can let go. It's okay.

*(He puts the coin in the offering bowl. He fades.)*

THE COLLECTOR (last words): It's so light.

**Rewards:**
- **The Open Hand** (Offering Style), a small glowing palm-shaped charm.
- **Featherweight Charm** (Double Jump), floating in the empty vault.
- **Key 1: Gold Key.**

*(Return to hub.)*

### Hub dialogue after Greed

NIM: He wasn't a monster, was he. He was just... holding on.

*(The pond ripples.)*

REFLECTION: You put it down. That's strange. Most people don't.

NIM: Who said that?

REFLECTION: Come back when you're ready, little light.

*(The first door glows green-white. The second door opens: SLOTH. The hub's music loses a note.)*

---

## 4. REGION 2: SLUMBER HOLLOW (SLOTH)

**Look:** a hazy dusk valley of hammocks, floating pillows, lazy rivers, and warm fog. Everything is soft, yawning, and gently dim.

**Mechanic (Drowse):** Lanterns are scattered across the region. Lighting them is an optional chore, but each lit lantern keeps the fog away. If you skip or delay chores, **Drowse** builds: your screen vignettes, your inputs get delayed by a fraction of a second, and eventually you fall asleep for a few seconds mid-fight. Standing idle builds Drowse faster. Keep moving, keep lighting.

**Debuff text:** *"DROWSE: You put it off again."*

**Monsters:**
- **Napping Nimbus:** puffy clouds that drift and release sleep spores.
- **Snoozle Snails:** slow, harmless-looking, leave drowsy trails.
- **Hammock Spiders:** wait until you stop moving, then drop on you.

**Lore tablets (Sloth):**
1. "I'll start tomorrow."
2. "It's not that I didn't want to. It's that it was so far from where I was."
3. "I was tired. Nobody asked me why I was tired."

### Dialogue

NIM: It's so peaceful. I could just... rest a bit. Just a moment.

*(Lumi idles. Drowse builds.)*
NIM (slower, yawning): Maybe we could wait here. Until it feels better.

*(After Lumi keeps moving and lights lanterns)*
NIM: Better. Every little light helps. Funny. Doing something is easier than I remembered.

*(Pre-boss: the hammock between two moons)*

THE DREAMER: ...Oh. Hello. Sorry. I'm so... tired.

THE DREAMER: I used to run, you know. I carried everything. Everyone else's work. Then one day I put one thing down. Then another. Then I couldn't pick any of it up.

NIM: You're not lazy. You're exhausted.

THE DREAMER: Is there a difference? Everyone called me lazy.

*(Boss fight.)*

**BOSS: THE DREAMER**
A gigantic fluffy sloth in a hammock between two glowing moons.
- **Phase 1, Lullaby:** sends slow waves of notes. Touching them builds Drowse. Lumi must keep moving.
- **Phase 2, Pillow Fall:** huge pillows drop, creating soft platforms and crush zones. Lantern posts spawn; light them to stay awake.
- **Phase 3, Covers Over:** the Dreamer pulls a blanket over the arena; the screen goes dim. Lumi must climb the new walls (Snail Grips tutorial walls appear) and strike the lantern-heart on her back.

*(Mid-fight)*
THE DREAMER: Just a little longer... just rest...
THE DREAMER: I'll get up tomorrow. I promise. I promise.

*(Defeat: she smiles and curls up small.)*

THE DREAMER: I was so tired for so long. Thank you for staying awake with me.

*(Her hammock lifts, and light spills in.)*

**Rewards:**
- **Hourglass Shard** (Tempo Style).
- **Snail Grips** (Wall Climb).
- **Key 2: Dusk Key.**

### Hub dialogue after Sloth

NIM: She wasn't lazy. She was drowning. Quietly.

*(Lumi stands still by the pond. Nim hovers.)*

NIM: Funny. In there, standing still was dangerous. Here, it feels like the only thing I can do.

REFLECTION: Stillness isn't the sin. Hiding in it is. Remember that.

NIM: Who... what does that mean?

REFLECTION: You'll know.

*(The third door opens: GLUTTONY.)*

---

## 5. REGION 3: THE ENDLESS TABLE (GLUTTONY)

**Look:** a candy-colored banquet hall stretching forever. Cakes the size of hills, chandeliers made of jelly, soft golden light. Smells of cinnamon you can almost see.

**Mechanic (Stuffed):** food pickups heal you. Eat too much and your **Fullness** meter climbs. At full, you gain **Stuffed**: your dash is disabled, your attacks slow, and your healing is cut by half. Work it off by moving and fighting. Skipping all food leaves you hungry but light, which is safe. Eating mindfully (only when low) is rewarded with an extra heal.

**Debuff text:** *"STUFFED: There was still room. There was never room."*

**Monsters:**
- **Crumb Swarm:** tiny crumbs that scatter, then re-form.
- **Jelly Gulpers:** gelatin blobs that swallow you briefly and spit you back with weight.
- **Cutlery Sprites:** forks and spoons that flit around and poke.

**Lore tablets (Gluttony):**
1. "It was never about the food."
2. "Every plate filled a little of the quiet."
3. "I kept saying one more. I kept saying it kindly."

### Dialogue

NIM: Everything smells like home. Which is strange, because I don't remember a home.

*(Lumi eats beyond full)*
NIM: You look... heavy. Maybe stop? One more won't hurt. Then maybe one more... Oh no. I'm doing it too.

*(Pre-boss: the long table)*

THE HOST: Welcome, welcome! Sit! You must be hungry. Nobody ever leaves my table hungry.

THE HOST: I've kept the feast going for a very long time. As long as there's food, nobody is lonely.

NIM: Are you lonely?

THE HOST: ...Eat something, dear.

*(Boss fight.)*

**BOSS: THE HOST**
A giant, round, cake-bodied cat in a tiny chef's hat, hosting a banquet that never ends.
- **Phase 1, Appetizers:** serves projectiles disguised as snacks. Eating them heals but builds Fullness.
- **Phase 2, Main Course:** the table fills the arena; platforms are cakes and pies that sag when you stand on them.
- **Phase 3, Dessert:** the Host swallows the room and grows. Lumi must dash through the gaps, but only when not Stuffed.
- Defeat: starve the fight by refusing food and hit weak spots.

*(Mid-fight)*
THE HOST: One more bite! Just one more!
THE HOST: Please, don't leave. If the plates are empty, I'll have to hear the silence.

*(Defeat: the Host deflates to a small cat with a single spoon.)*

THE HOST: I'm so full. Why am I still so empty?

NIM: Sometimes you're not hungry. You're just... sad.

**Rewards:**
- **The Hollow Spoon** (Devour Style).
- **Hungry Wind Scarf** (Super Dash).
- **Key 3: Honey Key.**

### Hub dialogue after Gluttony

NIM: He kept feeding everyone so no one would leave. That's a kind of love, isn't it?

REFLECTION: It's a kind of hiding too.

*(The pond ripples. For a moment, the reflection's eyes are wet.)*

*(The fourth door opens: ENVY.)*

---

## 6. REGION 4: THE GALLERY OF GLASS (ENVY)

**Look:** a long museum of tall windows, glass floors, and mirror-polished sculptures, tinted soft green. Every surface shows a better version of something. Paintings hang of glittering lives.

**Mechanic (Comparison):** the gallery has spotlit stages where gleaming "better" copies (Echo Sprites) stand. Standing near them or looking at them (staying in their light) drains your stamina regen and dims your own lantern. The fix is to step out of the spotlight and keep to your own path. Sealed rooms of shining treasure are bait: they look better than yours, but give nothing.

**Debuff text:** *"COMPARISON: Someone always has more."*

**Monsters:**
- **Echo Sprites:** glittering copies of enemies you've already defeated, slightly better.
- **Glass Peacocks:** fan out reflective feathers to bounce your lantern light back at you.
- **Window Watchers:** wall-mounted eyes that make you feel watched; their stare builds Comparison.

**Lore tablets (Envy):**
1. "She's smiling in every photo. I checked."
2. "I didn't want what they had. I wanted to be someone who had it."
3. "I stopped looking at my own hands."

### Dialogue

NIM: Everything here looks like it's better than us. The windows. The paintings. The floors.

*(Lumi stands in a spotlight. Comparison builds.)*
NIM: I feel... smaller. That's silly. You haven't changed.

*(Pre-boss: the stage curtain)*

THE UNDERSTUDY: Oh. It's you. The lead. Of course it's you.

THE UNDERSTUDY: I know every line. I practiced. I'm better at it than you. Why do you get the light?

NIM: Maybe the light isn't a prize.

THE UNDERSTUDY: Easy to say when you're holding it.

*(Boss fight.)*

**BOSS: THE UNDERSTUDY**
A graceful puppet dressed like Lumi but in glittering clothes, with a green porcelain smile.
- **Phase 1, Rehearsal:** copies Lumi's last-used fighting style, but cleaner.
- **Phase 2, Spotlight:** the stage lights track Lumi; staying lit builds Comparison. Lumi must break line of sight and fight from the shadows.
- **Phase 3, Curtain Call:** the Understudy tries to steal Lumi's equipped style mid-fight. Defeat requires switching to a style the Understudy has not copied yet, since it only steals the style you are holding.

*(Mid-fight)*
THE UNDERSTUDY: I'd have been better. I'd have been *so* much better.
THE UNDERSTUDY: Why did they choose you?

*(Defeat: the porcelain face cracks. Under it is a plain, tired, human-shaped puppet.)*

THE UNDERSTUDY: I never wanted your life. I just wanted anyone to want mine.

NIM: Someone does. I do. You were wonderful.

*(The Understudy bows, and for the first time, no one is clapping, and it is okay.)*

**Rewards:**
- **Green Mirror Shard** (Mimic Style).
- **Mirror Hairpin** (Glass Step: pass through marked glass walls).
- **Key 4: Verdigris Key.**

### Hub dialogue after Envy

NIM: She was good. She was really good. She just couldn't see it.

REFLECTION: Everyone's good at seeing what they lack.

*(The pond reflection now smiles gently. The hub music loses another note.)*

*(The fifth door opens: LUST.)*

---

## 7. REGION 5: THE RIBBON ORCHARD (LUST: longing and obsession)

*All-ages treatment: this sin is portrayed as obsessive longing, clinging devotion, and the fear of being left. Nothing sexual.*

**Look:** a twilight orchard of heart-shaped fruit trees, red ribbons tied in every branch, lanterns shaped like hearts, and drifting petals.

**Mechanic (Fixation):** Heart Lanterns glow throughout the region. Approaching one draws your attention: your camera drifts toward it, your controls pull you gently toward it, and you take extra damage while fixated. Dash away to break the pull. Ignoring them keeps you safe; collecting them gives nothing but a lingering "ache" debuff.

**Debuff text:** *"FIXATION: You couldn't look away."*

**Monsters:**
- **Heartmoths:** beautiful moths that lure you off safe paths.
- **Ribbon Wraiths:** tangle you in red ribbon until you break free.
- **Love-Lock Flowers:** bloom padlocks that bind your ankles.

**Lore tablets (Lust):**
1. "I'd have done anything to keep them close."
2. "I told myself it was devotion."
3. "I loved them so tightly they couldn't breathe."

### Dialogue

NIM: This place is gentle. Why does it feel like it's holding on to me?

*(Lumi approaches a Heart Lantern. The camera drifts.)*
NIM: I can't... look away. It's so pretty. Maybe a little closer?

*(Lumi dashes away.)*
NIM: Whew. That was close. I don't know what I was thinking.

*(Pre-boss: the giant sewing room)*

THE DEVOTED: You came! You came back! I knew you would. I always knew.

NIM: We've never met.

THE DEVOTED: Oh, you always say that. You always leave and come back. Just stay this time. Please. I'll sew us together. Then you can't go.

*(Boss fight.)*

**BOSS: THE DEVOTED**
A giant, soft, patchwork plush doll with button eyes, trailing red thread.
- **Phase 1, Stitch:** throws needles trailing thread. Thread tethers Lumi to the doll, shortening movement.
- **Phase 2, Hold Tight:** the doll hugs the arena; the walls close in. Lumi must break free by dashing against the pull.
- **Phase 3, Sewn Together:** she tries to sew Lumi to her chest. Cutting the thread (Tether Style teaches you to pull away) staggers her.

*(Mid-fight)*
THE DEVOTED: Don't go! Please, I'll be good!
THE DEVOTED: If I let you go, you won't come back.

*(Defeat: she goes limp and unravels gently.)*

THE DEVOTED: If I let go... will you still be there?

NIM: Maybe. Maybe not. But holding on so hard wasn't keeping you together either.

*(The thread falls away. She is just a small doll with a loose button.)*

**Rewards:**
- **Red Thread Spool** (Tether Style).
- **Thread Needle** (Grapple).
- **Key 5: Scarlet Key.**

### Hub dialogue after Lust

NIM: She just didn't want to be alone.

REFLECTION: That's what all of it is. Wanting not to be alone, bent out of shape.

NIM: Then... what are *you*?

*(The pond is silent. The sixth door opens: WRATH.)*

---

## 8. REGION 6: THE ASHEN KETTLE (WRATH)

**Look:** a land of warm brown clay, cracked earth, steaming vents, tiny cinder puffs. Cute kettle-shaped hills, round boiling ponds. It looks like a kitchen on fire.

**Mechanic (Rage):** the **Rage** meter builds when you take damage and when you attack recklessly. At full Rage, you enter **Berserk**: you can't block, your dash is replaced by a lunge, and you take self-damage when you swing. Calm it by pausing for a breath (standing still near a steam vent, or perfect-blocking). Patience is rewarded with stronger counters.

**Debuff text:** *"RAGE: It felt good until it didn't."*

**Monsters:**
- **Cinder Cubs:** little coals that explode when angered.
- **Thunder Kettles:** whistle-shrieking kettles that fire steam bursts.
- **Grudge Stones:** rock creatures that remember every hit; they grow harder each time you strike them in anger.

**Lore tablets (Wrath):**
1. "I wasn't angry at them. I was angry at what happened to me."
2. "It burned out the cold. For a minute it felt like warmth."
3. "I yelled at the sky until the sky became me."

### Dialogue

NIM: It's warm. Too warm. Everything here is whistling.

*(Lumi enters Berserk.)*
NIM: Lumi, stop! You're hurting yourself! Breathe!

*(Lumi pauses near a vent. Rage cools.)*
NIM: There. Better. It's okay to be angry. It's just... hard to hold the flame without burning.

*(Pre-boss)*

THE BOILING ONE: HEY! WHO'S THERE?!

NIM: We're travelers.

THE BOILING ONE: NOBODY LISTENS! I TOLD THEM! I TOLD THEM A HUNDRED TIMES!

NIM: What did you tell them?

THE BOILING ONE: ...That it hurt.

*(Boss fight.)*

**BOSS: THE BOILING ONE**
A giant kettle-spirit with a tiny face, steam pouring from its spout.
- **Phase 1, Whistle:** sprays steam waves; shrieks that build Rage.
- **Phase 2, Overflow:** the arena floods with scalding water; platforms are floating lids. Rage builds fast.
- **Phase 3, Boil Over:** the boss's temper erupts. If Lumi lashes out, damage reflects. The only opening is when the Boiling One exhausts itself; Ember Style's patient strike shines here.

*(Mid-fight)*
THE BOILING ONE: LISTEN TO ME! LISTEN!
THE BOILING ONE: IF I STOP SCREAMING, NOBODY WILL HEAR ME.

*(Defeat: the steam fades. It sits, smaller, cooling.)*

THE BOILING ONE: ...I was just so hurt. I didn't know what else to do with it.

NIM: We hear you now.

*(A single quiet whistle. Then silence.)*

**Rewards:**
- **The Cooled Ember** (Ember Style).
- **Ember Boots** (Ground Pound: breaks cracked floors and walls).
- **Key 6: Cinder Key.**

### Hub dialogue after Wrath

NIM: Every one of them was hurt first, wasn't he.

REFLECTION: The sins aren't what we are. They're what we do with the hurt.

NIM: ...You sound sad.

REFLECTION: I have been sad for a very long time.

*(The seventh door opens: PRIDE. The hub's colors are very bright now. The music is slightly out of tune.)*

---

## 9. REGION 7: THE TOWER OF APPLAUSE (PRIDE)

**Look:** a tall pearl-white tower of marble and gold, banners, fanfare trumpets, confetti that never lands. It is beautiful and spotless. A path of golden stairs winds upward through clouds.

**Mechanic (Hubris):** as long as you take no damage, the **Hubris** meter climbs. At full Hubris, your next hit is doubled, healing is disabled, and some enemies become immune to your attacks. To lower it, you must **bow at a shrine** or **accept help from a Helper Spirit**: use the Humble Style, accept a heal from a shrine, or let a spirit cover you. Perfection is punished.

**Debuff text:** *"HUBRIS: You didn't ask for help."*

**Monsters:**
- **Trophy Knights:** gleaming armor that parry and mock.
- **Polished Pedestals:** statues that turn to face you; if you ignore them, they fall on you.
- **Applause Doves:** doves that clap their wings; the louder the applause, the faster Hubris builds.

**Lore tablets (Pride):**
1. "I never needed anyone."
2. "If I asked for help, they'd see."
3. "I was so good at being fine."

### Dialogue

NIM: It's beautiful. It's so clean. It feels like nothing here has ever gone wrong.

*(Hubris builds.)*
NIM: You haven't been hit once. That's amazing! ...Isn't it?

*(Hubris peaks, the next hit hurts doubly.)*
NIM: Maybe... it's okay to be hit sometimes. Maybe that's how we know we're alive.

*(Pre-boss: the golden summit)*

THE CHAMPION: At last. Someone worthy to witness me.

THE CHAMPION: I've never lost. Never faltered. I never needed anyone's hand. That is what makes me great.

NIM: Isn't that lonely?

THE CHAMPION: Lonely is for those who are not enough.

*(Boss fight.)*

**BOSS: THE CHAMPION**
A flawless porcelain knight in white-gold armor, wearing a perfect crown.
- **Phase 1, Duel:** precise, elegant attacks. Perfect play builds Hubris fast.
- **Phase 2, Applause:** the Champion calls the crowd; cheers fill the screen. The more you play perfectly, the more the Champion grows untouchable.
- **Phase 3, Humble Strike:** the Champion becomes invincible while Lumi has high Hubris. Lumi must **bow**: use Humble Style and call the spirits of all six defeated bosses to help, each providing a brief assist. The Collector drops coins as shields, the Dreamer slows time, the Host heals, the Understudy distracts, the Devoted pulls the Champion into reach, and the Boiling One cracks the armor.

*(When Lumi calls for help)*
THE CHAMPION: What are you doing? You don't need them! You're strong enough!
THE CHAMPION: If you can't do it alone, then what are you?

*(Defeat: the crown slips off. The porcelain cracks.)*

THE CHAMPION: I never asked anyone for anything. I thought that meant I was strong.

NIM: It meant you were alone.

*(The Champion takes off the crown and bows. For the first time, someone helps them up.)*

**Rewards:**
- **The Bowed Crown** (Humble Style).
- **Halo Cloak** (Glide).
- **Key 7: Pearl Key.**

### Hub dialogue after Pride

*(All seven doors are open and quiet. The hub is gorgeous. The music is slightly broken.)*

NIM: That's all of them. All seven. We did it.

NIM: ...Why do I feel like it's not over?

REFLECTION: Because it isn't.

*(The pond ripples. The reflection stands up inside the water.)*

REFLECTION: There was always one more. The one nobody counts.

NIM: Who are you?

REFLECTION: Come to the Gate. I'll show you.

*(The Mirror Gate begins to glow. A long, narrow path unfolds behind it: the Memory Path.)*

---

## 10. THE MEMORY PATH (gauntlet)

A final traversal sequence stitched from every region's visual style. It requires every gadget: Dash, Double Jump, Wall Climb, Super Dash, Glass Step, Grapple, Ground Pound, and Glide. No enemies. Each segment replays a quiet scene in silhouette.

Lore moments along the path:
- Greed segment: a small figure hugging a box of old things.
- Sloth segment: a small figure lying on a floor, not moving.
- Gluttony segment: a small figure eating alone at midnight.
- Envy segment: a small figure looking through a window at a party.
- Lust segment: a small figure holding a phone that never lights up.
- Wrath segment: a small figure screaming into a pillow.
- Pride segment: a small figure saying "I'm fine" to no one.

NIM (quietly): These aren't someone else's memories, are they.

*(At the end, the Mirror Gate. Seven keyholes. Lumi places the seven keys.)*

---

## 11. THE MIRROR GATE: THE FINAL ARENA

**Arena:** a calm lake of mirrored sky. A single reed. Perfect stillness. The Reflection waits on the water, looking exactly like Lumi, smiling slightly too long.

### Pre-fight dialogue

REFLECTION: Hello, Lumi.

NIM: You... you're...

REFLECTION: I'm everything you didn't want to look at. Every time you put something down and walked away. Every time you said "I'm fine." That was me. I was behind you the whole time.

REFLECTION: Seven sins. Seven doors. You thought you were beating monsters. You were meeting people. People who were just you, with different faces.

REFLECTION: The eighth sin is the one nobody lists. It's the one where you refuse to look at yourself.

*(The Reflection draws its own lantern.)*

REFLECTION: If you must fight me, fight me.

### The Fight

**BOSS: YOUR REFLECTION**
- Copies Lumi's moves, attacks, and dashes in real time with a slight delay, always one step better.
- Uses every fighting style and gadget Lumi has unlocked.
- Fighting is unwinnable: its health refills and it adapts to your patterns.
- Pre-defeat lines (looped when the player dies, escalating gently):

1. REFLECTION: You can't win like this. But try, if it helps.
2. REFLECTION: I know every move you'll make. I made them with you.
3. REFLECTION: Every time you swing, you only prove you can't stop.
4. REFLECTION (softer): You're so tired. I know. I'm tired too.
5. REFLECTION (quietly): Put it down, Lumi.

- If the player stays completely still (no input) for about 8 seconds, the Reflection halts, lowers its lantern, and slowly walks toward Lumi.

NIM (whisper): Don't move. Don't fight. Just... look at it.

### The Cutscene

*(The Reflection stops in front of Lumi. A single ripple spreads.)*

REFLECTION: I didn't come to hurt you. I came because you left me behind.

REFLECTION: I carried everything you couldn't. The greed, the tiredness, the hunger, the jealousy, the wanting, the anger, the pride. I held it all so you could keep walking. I'm not your enemy, Lumi. I'm the part of you that didn't get to rest.

*(An "Accept" prompt appears in soft gold. Beside it, in the same moment, a message appears drawn in dripping blood across the screen: STRIKE.)*

*(The player has about 5 to 6 seconds.)*

### ENDING A: GOOD ENDING, "ACCEPT"

*(If the player presses Accept, or does nothing and the timer ends.)*

*(Lumi reaches out. The Reflection takes Lumi's hand. They merge into one light.)*

REFLECTION (and Lumi's voice together, for the first time): I forgive you. I forgive me.

*(Colors brighten. The hub blooms. The music resolves into a full, warm chord. The seven bosses appear one by one, smaller, lighter, smiling.)*

THE COLLECTOR: It's so light.
THE DREAMER: I'm awake.
THE HOST: I'm not hungry.
THE UNDERSTUDY: I'm enough.
THE DEVOTED: I can let go.
THE BOILING ONE: I'm heard.
THE CHAMPION: Thank you.

NIM: You did it. You didn't beat anything. You just... stayed.

*(Epilogue: Lumi sits by the pond. The reflection waves back at the same time. No lag. No extra smile. Nim curls up in the lantern. Text on screen:)*

> *"You were never meant to defeat yourself. You were meant to come home."*

*(Credits roll over a soft, resolved melody. A final hidden Memory Petal at the end of the credits reveals the very first memory: a small child in a field, laughing, with no sins at all.)*

### ENDING B: BAD ENDING, "STRIKE" (hidden twist)

*(If the player lands a hit on the Reflection within the 5 to 6 second window.)*

*(The Reflection looks surprised, then tired.)*

REFLECTION: ...Oh. Of course.

*(It falls. The mirror cracks across the entire sky. The cracks spread.)*

NIM (screaming): LUMI, NO!

*(The lake turns black, then red. The sky burns. Every region's colors twist: golden flowers burn, hammocks rot, banquet tables collapse, glass shatters, ribbons turn to chains, the kettle boils over, the tower falls. The music distorts into reversed, warped chimes.)*

*(Lumi stands alone. Nim is gone. The Reflection is gone. The world is hell.)*

*(The player can still walk. Everything that moves is a burning silhouette of a former boss. None attack. They only look.)*

*(Text appears in dripping red:)*

> *"You killed the only one who could have saved you."*

*(The screen fades to black. A single line in white:)*

> *"Some strength is just the fear of being seen."*

*(Return to title. The title screen is now cracked, with a faint red tint, until the player completes the Good Ending once.)*

---

## 12. OPTIONAL EXTRAS

**Memory Petals:** 5 hidden in each region (35 total). Each adds a short line to the Memory Tree in the hub. Collecting all of them reveals a hidden epilogue in the Good Ending.

**New Game+:** the Reflection speaks differently. On revisit, Lumi can see the Reflection in every region's mirrors, always a little more at peace.

**Soundtrack direction:** a soft lo-fi base of music box, felt piano, and warm pads. Each region adds one instrument that gently detunes as the region's sin takes hold, then resolves after the boss is defeated. The final arena has no music until the Accept prompt, when the first soft chord arrives.

**Art direction:** pastel storybook, rounded shapes, glowing particles, gentle parallax. As the game progresses: small cracks, slightly wrong smiles, flowers that weep. Cute on the surface, deeper underneath.

# Part 2: Side Quests


**Design rules**
- Every NPC is a small soul whose story echoes the region's sin. Gently, they are all pieces of Lumi.
- No quest rewards a stat buff, since the game has no buffs. Rewards are **Keepsakes** (cosmetic charms with a short memory), **Memory Petals** (hub lore), and **hub changes** (a new light, a new sound, a new visitor).
- Each region has 2 quests. One is available on first visit. One needs a later gadget, so the player returns.
- Quests are optional and never explained with markers. NPCs just look like they're waiting.
- Several quests end with a choice. Neither choice is wrong, and both hurt a little.

**Total: 3 hub quests, 14 region quests, 1 capstone.**

---

## HUB QUESTS (The Still Pond)

### H1. The Paper Boats
**Giver:** Marl, a tiny paper-boat spirit folding boats by the pond.
**Setup:** Marl sends a paper boat across the pond every night with a letter inside. No letter has ever been answered. The boats sink at the far shore.
**Quest:** In each region Lumi finds a **soaked, unread letter** hidden in a quiet corner (7 total). Bring each back; Marl dries it, and the writing reappears.
**The dialogue:**

MARL: I write to someone every night. I don't know who. I just know they're on the other side.

*(After the 7th letter, Marl reads them aloud. They are all addressed "Dear Lumi," and all written in Lumi's own handwriting.)*

MARL: ...These aren't replies. These are what *you* wrote. To them. And never sent.

*(Marl folds one last boat and sets it in Lumi's hands.)*

MARL: Maybe they were waiting for you to send it.

**Reward:** Keepsake: **Paper Boat Charm.** In the Good Ending credits, a boat finally crosses the pond and lands.

### H2. The Bench Keeper
**Giver:** Orrin, an old stone frog on the Bench of Rest.
**Setup:** Orrin says he's waiting for someone who said, "I'll be right back." That was a very long time ago.
**Quest:** None to complete. Every time Lumi returns to the hub, Orrin has one new line. The player only needs to sit with him. Skipping the bench means missing the story.

Lines, in order:
1. ORRIN: They said they'd come back before the lamps were lit.
2. ORRIN: I kept the bench warm. Not the best at it. Stone's cold.
3. ORRIN: Sometimes I think they're just late.
4. ORRIN: Sometimes I think they forgot.
5. ORRIN: Sometimes I think I'm the one who forgot where to look.
6. ORRIN: You come by a lot. Thank you for that.
7. ORRIN: I think I can stop waiting now. I think... they would have wanted me to rest.

*(After the 7th, Orrin shrinks to a small gray pebble. He drops into the lantern.)*

NIM: He's... in here now. It's warm.

**Reward:** Keepsake: **Orrin's Pebble.** (The lantern glows a little warmer whenever Lumi sits at a bench.)

### H3. The Table of Remembering
**Giver:** none. A small wooden table beside the Memory Tree.
**Setup:** After each boss, a tiny chair appears at the table with the boss's Keepsake on it.
**Quest:** Sit in each chair to see the boss's real name and a short memory scene.

| Boss | Real name | Memory scene |
|------|-----------|--------------|
| The Collector | Barnaby | A small bear packing his family's belongings into a cart in the snow. |
| The Dreamer | Willow | A sloth carrying a pile of everyone's baskets up a hill, alone. |
| The Host | Mabel | A cat setting a table for six; five chairs stay empty. |
| The Understudy | Pip | A puppet standing at the wings, mouthing someone else's lines. |
| The Devoted | Clementine | A rag doll holding a button that fell off a friend's coat. |
| The Boiling One | Ember | A kettle whistling in an empty kitchen. |
| The Champion | Sir Alden | A knight bowing to an empty hall. |

*(After the 7th chair is filled, an eighth chair appears. It is empty. It's for the Reflection.)*

**Reward:** Keepsake: **Seven Chairs Charm.** The hub gets one more candle on the table.

---

## REGION 1: THE GILDED GARDEN (GREED)

### G1. The Last Coin
**Giver:** Tuppence, a tiny mouse sitting beside a mound of coins she won't spend.
**Setup:** She's saving every coin for a warm blanket for her grandmother. She says it's almost enough.
**Quest:** Bring her 7 coins found in safe corners (not guarded by monsters). Each time, she counts the pile again.

TUPPENCE: Almost. Just a few more. Then I'll buy it and take it home.

*(On the last coin, Lumi notices a small grave marker half-buried under the pile.)*

NIM: Tuppence... how long ago was that?

TUPPENCE: ...Long ago. But if I spend them, then it's over. Then it's real.

**The choice:**
- **Offer the pile** at a shrine. The coins become golden flowers across the grave. Tuppence says goodbye. Her last line: "She would have loved the warmth."
- **Leave her alone.** She keeps counting forever. The pile grows with a quiet, endless chime. Later, when the Collector is defeated, her coins quietly stop growing.

**Reward:** Keepsake: **Tuppence's Penny.** (Cosmetic: a tiny chime when Lumi gives gold at shrines.)

### G2. The Egg That Never Hatched *(needs Double Jump)*
**Giver:** None. A Magpie Thief's nest on a high ledge.
**Setup:** A Magpie keeps stealing gold. At the top of a tall tree, her nest is lined with gold, and in the center sits a single pale glass-like egg.
**Quest:** Reach the nest. The Magpie hovers near it, not attacking.

MAGPIE: I thought if the nest was shiny enough... it would want to come out.

*(Lumi can place a Memory Petal in the nest.)*

MAGPIE: ...It's okay. I'll keep warm anyway. Thank you for not taking it.

**Reward:** Keepsake: **Magpie Feather.** Magpie Thieves no longer steal from Lumi in later visits. They watch from a distance, quietly.

---

## REGION 2: SLUMBER HOLLOW (SLOTH)

### S1. The Unwound Clock
**Giver:** Dorrin, an old mole clockmaker.
**Setup:** Seven clocks stand in his shop. Six are stopped. He says winding them hurts his hands.
**Quest:** Wind each clock (they're scattered across the region, not in his shop). Each clock, when wound, plays a short scene of a day he skipped.

Clock scenes: a birthday cake going stale, a letter on a doorstep, a missed dance, a door left unlocked, an empty chair, a half-finished carving, a phone ringing.

DORRIN: I stopped winding them the day she left. It felt like if time stopped, it couldn't move forward without her.

*(The seventh clock, the largest, has a small note inside the case.)*

NOTE: "Dorrin, don't stop. Wind them. I'll be listening. Love, Rosa."

DORRIN: ...She knew. Of course she knew.

**Reward:** Keepsake: **Dorrin's Winding Key.** (Cosmetic: the lantern ticks softly.) The hub gets a small clock that always shows the same time as the player's clock.

### S2. The Boy Who Wouldn't Wake *(needs Wall Climb)*
**Giver:** Pim, a hedgehog child asleep in a hammock at the top of a cliff.
**Setup:** He sleeps all day. In his dreams he plays with a friend who isn't around anymore.
**Quest:** Climb to the cliff. Find his friend's last drawing in a hidden alcove, then wake Pim gently.

PIM: Five more minutes. They said they'd be here five more minutes.

*(Lumi shows him the drawing. It's of two small figures under a wide sky. At the bottom: "To Pim. See you tomorrow." The date is long ago.)*

PIM: That's... oh.

PIM: They never came tomorrow.

*(Pim cries quietly. Nim stays beside him.)*

PIM: Okay. I'll... I'll wake up. I think they'd want me to eat something.

**Reward:** Keepsake: **Pim's Drawing.** The hub gets a small drawing pinned beside the pond.

---

## REGION 3: THE ENDLESS TABLE (GLUTTONY)

### GL1. Grandmother's Soup
**Giver:** Biscuit, a bear cub in a too-big apron.
**Setup:** He's been trying to make his grandmother's soup. It never tastes right.
**Quest:** Gather 5 ingredients scattered across the banquet hall (carrot, thyme, salt, a bay leaf, a slow-warmed bowl). Each is hidden behind a small hazard.

BISCUIT: It's the right ingredients. It's the right pot. It's *not* right.

*(Lumi brings the last ingredient. Biscuit tastes the soup and stops.)*

BISCUIT: It tastes like... nothing.

NIM: Maybe it needs company.

*(Lumi sits and eats with him. Biscuit takes a long breath.)*

BISCUIT: ...There it is. That's it. It always tasted like somebody sitting across from me.

**Reward:** Keepsake: **Biscuit's Ladle.** The hub gets a small steaming pot that never empties.

### GL2. The Empty Plate *(needs Super Dash)*
**Giver:** A quiet ghost child sitting at the end of the longest table.
**Setup:** A plate is set for someone who never arrives. The ghost waits every night.
**Quest:** Reach the end of the table (it's across a wide gap). Sit in the empty chair next to the ghost. Do nothing for 30 seconds.

GHOST CHILD: They said they'd come when dinner was ready.

*(A single extra plate appears, steaming.)*

GHOST CHILD: ...Can you stay a bit? Just until I finish?

*(The child eats slowly. When the plate is empty, the child's outline fades.)*

GHOST CHILD (whisper): Thank you for staying.

**Reward:** Keepsake: **The Empty Plate.** (Cosmetic: a faint warm glow around Lumi when sitting at a bench.)

---

## REGION 4: THE GALLERY OF GLASS (ENVY)

### E1. The Painter's Hidden Wing
**Giver:** Fenn, a small bird painter who only copies masterpieces.
**Setup:** She paints perfect imitations of famous works, then sells them as "inspired." She never shows her own.
**Quest:** Find 3 of her own paintings, hidden behind her copies (Glass Step helps find them, but the first can be found without).

FENN: They're not good. Nobody wants to see them.

*(The paintings: a crooked little house, a lopsided tree, a small bird in a big sky.)*

NIM: They're beautiful.

FENN: ...They're *mine.* That's what makes them scary.

**The choice:**
- **Hang them in the main hall.** The Gallery's mood softens a little. Fenn cries and smiles.
- **Leave them hidden.** She keeps copying. The Gallery stays a bit colder.

**Reward:** Keepsake: **Fenn's Brush.** (Cosmetic: Lumi's footsteps leave a faint watercolor trail.)

### E2. The Window Seat *(needs Glass Step)*
**Giver:** A small ghost girl behind a window, watching a party in a bright hall across the glass.
**Setup:** She's watched the same party for years. She wants to be inside.
**Quest:** Use Glass Step to cross through the window and speak to the party.

*(Inside, the party-goers all stand awkwardly. One by one they confess:)*

PARTYGOER 1: I'm not happy here. I just look it.
PARTYGOER 2: I keep looking at her window. She looks so peaceful.
PARTYGOER 3: I wish someone would just ask me how I am.

*(Lumi carries these words back. The girl listens, then smiles faintly.)*

GIRL: ...They want what I have. And I want what they have. Isn't that silly?

NIM: It's the most human thing I've ever heard.

*(The girl draws the curtain, and for the first time, rests.)*

**Reward:** Keepsake: **Window Seat Cushion.** The hub bench gets a soft cushion.

---

## REGION 5: THE RIBBON ORCHARD (LUST: longing and obsession)

### L1. The Postman Who Waits
**Giver:** Hector, a snail postman with a worn satchel.
**Setup:** He delivers letters to a house that has been empty for years. The recipient moved on. He keeps delivering.
**Quest:** Read the last letter he never delivered (hidden in the satchel). It's addressed to someone named "Hector."

LETTER: "Dear Hector. Thank you for every letter. I'm sorry I never wrote back. I was afraid of how much I'd miss you. I have moved on. Please do, too."

HECTOR: ...They knew. All this time.

*(He puts the satchel down.)*

HECTOR: I think I'd like to rest now. I think I'd like to be someone's recipient, for once.

**Reward:** Keepsake: **Hector's Satchel.** The hub gets a mailbox that, once a day, contains a short note from a defeated boss.

### L2. Two Lanterns *(needs Grapple)*
**Giver:** None. Two heart-shaped lanterns tied together by a red thread on a high branch. One is dark. One burns bright.
**Setup:** The lit one never lets go, even though its partner burned out long ago.
**Quest:** Reach the branch with the Grapple.

NIM: The bright one is burning itself down trying to keep the other warm.

**The choice:**
- **Cut the thread.** The bright lantern flickers, then settles into a calm, steady glow. The dark lantern drifts down and fades into petals.
- **Leave it tied.** The bright lantern burns itself out within the hour. Both go dark together. Nim says nothing.

**Reward:** Keepsake: **Red Thread Fragment.** (If cut: the lantern burns a soft gold. If left: the lantern flickers a lonely white.)

---

## REGION 6: THE ASHEN KETTLE (WRATH)

### W1. The Cup That Was Thrown
**Giver:** A small clay cup with a crack across its side.
**Setup:** It was thrown against a wall in an argument long ago. It hasn't spoken since.
**Quest:** Find 5 shards scattered across the region. Bring them to the kiln. The cup is patched with gold seams.

CUP (quietly): I didn't do anything wrong. I was just there.

*(When mended:)*

CUP: ...I look different. I look... like I've been through something.

NIM: You have. And you're still holding together.

CUP: I didn't know I could still hold anything.

**Reward:** Keepsake: **The Gold-Seam Cup.** (Cosmetic: Lumi's healing animation pours tea from the cup.)

### W2. Echo Canyon *(needs Ground Pound)*
**Giver:** None. A deep canyon reached only after breaking a cracked floor.
**Setup:** Shouting into the canyon produces an echo.
**Quest:** Shout (a button prompt, any input). The echo returns, softer each time.

ECHO (1st): ...are you mad at me?
ECHO (2nd): ...did I do something wrong?
ECHO (3rd): ...I'm sorry. I'm sorry. I'm sorry.

*(Lumi stands quietly. The echo goes silent.)*

NIM: That wasn't an echo.

*(A small, translucent child-figure appears at the canyon floor, then fades. A Memory Petal drifts up.)*

**Reward:** Keepsake: **The Soft Echo.** (Cosmetic: Lumi's lantern hums faintly when near cliff edges.)

---

## REGION 7: THE TOWER OF APPLAUSE (PRIDE)

### P1. The Medal Collector
**Giver:** An old knight statue named Sir Alden's Squire, polishing medals.
**Setup:** He polishes 100 medals a day. He has no one to show them to.
**Quest:** Sit with him until he's done polishing (about 2 minutes of real time). He takes off one medal at a time.

SQUIRE: These are all I have to prove I mattered.

*(Underneath, there's nothing but a small toy soldier.)*

SQUIRE: ...I think I was supposed to ask someone to come with me. I never knew how.

NIM: We're here.

*(He sets down the polishing cloth.)*

**Reward:** Keepsake: **Polishing Cloth.** (Cosmetic: Lumi's lantern shines slightly brighter, but only when no enemies are nearby.)

### P2. The Tower's Servant *(needs Glide)*
**Giver:** A tiny mouse who sweeps the highest stairs of the tower.
**Setup:** She's been sweeping for a hundred years. No one has ever thanked her.
**Quest:** Glide to the highest hidden landing. Give her a Memory Petal as a thank-you.

MOUSE: ...Oh. Nobody's ever... Oh.

*(She puts down her broom. For the first time, she looks at the sky.)*

MOUSE: It's very tall up here. I never noticed.

**Reward:** Keepsake: **The Tiny Broom.** The tower's floor is a little cleaner on later visits.

---

## CAPSTONE: NIM'S WISH
**Unlocks:** after all 17 other quests are complete.
**Giver:** Nim.
**Setup:** Nim asks Lumi to sit by the pond at night in the hub. The Reflection stays quiet.

NIM: I've been wondering something for a while. I don't know if I'm real.

NIM: I remember being in your lantern. Before that... I remember being small. And you were small. And you were alone. And I think... I think you made me up. To keep from being lonely.

NIM: I don't mind. I just wanted to say it out loud.

NIM: If I'm not real, would you still... would you still keep me?

**The choice:**
- **Hold the lantern close.** Nim glows warm. In the Good Ending, Nim remains in the lantern after the credits, whispering "Goodnight."
- **Stay silent.** Nim understands. In the Good Ending, Nim still remains, but quieter.

*(No choice here is "wrong." Either way, Nim is not lost in the Good Ending. In the Bad Ending, Nim is lost either way.)*

**Reward:** Keepsake: **Nim's Real Name.** A hidden line is added to the Good Ending epilogue: Nim says his true name aloud for the first time.

---

## TONE REFERENCE
- Quiet over loud. Let the pause do the work.
- No quest should resolve with a fight.
- Every NPC speaks in short, simple sentences.
- The music for side quests is a single soft instrument with no accompaniment.
- Reward text always ends on an ordinary, gentle image, never a big reveal.

# Part 3: Lore Tablets and Memory Petals


**How it works**
- Each region already has 3 lore tablets in the main script. Here are tablets 4 and 5 for every region, so each has 5.
- Each region hides **5 Memory Petals**. A petal shows one tiny memory when collected and adds a line to the Memory Tree in the hub.
- Petals are in the voice of Lumi, as a small child, then older. Read in order across regions, they tell one quiet life story.
- The Memory Tree blooms a little more with each petal. At 35 petals, a hidden epilogue unlocks in the Good Ending.

---

## REGION 1: THE GILDED GARDEN (GREED)

### Lore tablets 4 and 5
4. "I kept the first coin I ever earned. I never spent it. I don't remember what it was for."
5. "A garden can't grow if you never let the water go."

### Memory Petals
1. "I hid my favorite toy under the bed so my sister couldn't have it. She cried. I let her."
2. "I counted my birthday money three times that night. It felt safe."
3. "I said 'it's mine' so loudly the whole room went quiet."
4. "I kept the last cookie for later. Later, it went stale."
5. "I wanted so badly to be sure there'd be enough that I forgot who I was saving it for."

---

## REGION 2: SLUMBER HOLLOW (SLOTH)

### Lore tablets 4 and 5
4. "I looked at the mountain and thought: not today. Then every day was not today."
5. "The hardest part was never the work. It was the first step. And the second. And the third."

### Memory Petals
1. "I stayed in bed instead of going to the recital. I told them I was sick. I wasn't."
2. "The homework sat on the desk for a week. It watched me."
3. "I said I'd call back. I never did. The silence got heavier every day."
4. "I was so tired I forgot what I was tired of."
5. "I wanted to rest, but resting didn't help. It only made the day longer."

---

## REGION 3: THE ENDLESS TABLE (GLUTTONY)

### Lore tablets 4 and 5
4. "I ate until the feeling went away. Then I ate because the feeling was coming back."
5. "A table set for many is the loudest kind of quiet."

### Memory Petals
1. "I ate dinner alone in front of the TV. The sound filled the room. It helped."
2. "Mom's kitchen smelled like home. When she stopped cooking, I tried to cook it myself. It never smelled the same."
3. "I took a second helping so no one could see my plate was the only one empty."
4. "I told myself I deserved it. After everything. I did. I think."
5. "I wasn't hungry. I was just lonely, and food was the only thing that always showed up."

---

## REGION 4: THE GALLERY OF GLASS (ENVY)

### Lore tablets 4 and 5
4. "She won because she was lucky. No. She won because she worked. No. She won because she deserved it. That one hurt the most."
5. "A mirror shows you everything you aren't. A window shows you everything you want."

### Memory Petals
1. "My friend got picked first for the team. I clapped. My hands didn't feel like mine."
2. "I scrolled through her photos until my eyes hurt. She looked happy. I didn't ask."
3. "I told everyone I was proud of them. I meant it. I also wished it were me."
4. "I threw out my drawing because it wasn't as good as theirs."
5. "I didn't hate them. I hated how small I felt standing next to them."

---

## REGION 5: THE RIBBON ORCHARD (LUST: longing and obsession)

*All-ages: this region is about longing, clinging, and fear of being left.*

### Lore tablets 4 and 5
4. "I read their messages again. Then once more. Then I stopped reading and just held the screen."
5. "Holding on and holding tight aren't the same. I learned that too late."

### Memory Petals
1. "I waited by the door long after they said they wouldn't come."
2. "I wrote their name in the margins of every notebook. I didn't know how to stop."
3. "I told them I'd be fine if they left. I wasn't. I never told them."
4. "I kept their scarf. It stopped smelling like them. I kept it anyway."
5. "I loved them so much I forgot they were allowed to leave."

---

## REGION 6: THE ASHEN KETTLE (WRATH)

### Lore tablets 4 and 5
4. "Anger is a fire that burns whatever's closest. Usually that's the people who love you."
5. "I threw the cup. It broke. I stood there. It was just a cup. It wasn't just a cup."

### Memory Petals
1. "I slammed my door so hard the picture fell. No one came. I wished someone had."
2. "I said something I couldn't take back. The room changed shape."
3. "I yelled because I was scared. Yelling felt like the opposite of scared. It wasn't."
4. "I was so angry I didn't notice I was crying."
5. "I wasn't angry at them. I was angry that I couldn't say what hurt."

---

## REGION 7: THE TOWER OF APPLAUSE (PRIDE)

### Lore tablets 4 and 5
4. "I said I was fine so many times that I forgot there was anything else to say."
5. "A crown is just a weight you've decided is a gift."

### Memory Petals
1. "I didn't ask for help with the project. I stayed up all night. It was good. No one knew it cost me."
2. "I corrected them in front of everyone. I was right. It didn't feel like winning."
3. "I told them I didn't need anything. I really wanted someone to notice I did."
4. "I got the trophy. I looked around for someone to show. There wasn't anyone."
5. "I was so good at being strong that no one thought to ask if I was okay."

---

## THE MEMORY TREE: FINAL BLOOM

When all 35 petals are collected, the Memory Tree blooms fully. A final line appears on the highest branch, in soft gold:

> *"None of this was ever a flaw. It was just a child, trying to be safe."*

In the Good Ending credits, after the last name, a final petal falls and shows the very first memory:

> *"I was small. I was laughing. I didn't know yet that I had anything to hide."*

# Part 4: Combat, Controls and Movesets


**Design pillar:** every artifact is the *virtue* that answers its sin. The movesets are not power-ups. They are seven different ways of playing, and each one only works if you play it the way its lesson says.

| Sin | Virtue | Artifact | Style |
|-----|--------|----------|-------|
| Greed | Giving | The Open Hand | Offering Style |
| Sloth | Showing up on time | Hourglass Shard | Tempo Style |
| Gluttony | Taking only what you need | The Hollow Spoon | Devour Style |
| Envy | Admiring without comparing | Green Mirror Shard | Mimic Style |
| Lust (longing) | Connection without clinging | Red Thread Spool | Tether Style |
| Wrath | Patience | The Cooled Ember | Ember Style |
| Pride | Asking for help | The Bowed Crown | Humble Style |

---

## 4.1 CORE RULES

- **Health:** 100 HP. Shown as the flame in Lumi's lantern.
- **Heal (Lantern Oil):** 3 charges. Each restores 35 HP over 1.2 seconds. A hit interrupts the heal and wastes the charge. Charges refill at benches.
- **Glow:** 0 to 100. Fuels style skills and the Overture. Gains: +5 per hit landed, +15 per perfect guard or perfect dodge. Glow never decays on its own.
- **Loadout:** the Altar of Hands in the hub holds 3 equipped styles (Lantern Swing is always one of them, so 2 free slots). Cycle between equipped styles in the field. A swap takes 0.4 seconds and cannot be interrupted by your own inputs.
- **Overture:** each style has a finisher that costs a full 100 Glow.
- **Death:** Lumi drops all Glow (and, in Greed, all carried gold) as an **Echo** where they fell. Reach the Echo to get it back. Dying again before then loses it for good. There is no other death penalty.
- **Checkpoints:** Benches of Rest. Resting refills health and heal charges, and respawns normal enemies. Bosses never respawn.
- **Gadget moves:** Double Jump (jump again in air), Wall Climb (hold toward a wall, then up or down), Super Dash (hold Dash, release to launch), Glass Step (walk into marked glass), Grapple (aim at a hook, press Gadget), Ground Pound (Down plus Jump in air), Glide (hold Jump while falling).

---

## 4.2 CONTROLS

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | A / D or arrows | Left stick |
| Jump (hold = higher) | Space | A |
| Dash | Shift | B |
| Attack (light) | J | X |
| Heavy (hold = charge) | K | Y |
| Style Skill | L | RB |
| Guard / Style special | I | LB |
| Heal (hold) | H | LT |
| Overture (100 Glow) | O | RT |
| Gadget (Grapple) | G | Right stick click |
| Cycle style | Q | D-pad left / right |
| Interact, bench, shrine | E | D-pad up |
| Pause | Esc | Start |
| Map | M | Select |

---

## 4.3 DEFAULT KIT: LANTERN SWING

A balanced, readable style. Everything else is a variation on it.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Light combo | J, J, J | 8 / 8 / 12 | third hit has a tiny lunge |
| Heavy | K | 22 | slight pause before the swing, short knockback |
| Air attack | J in air | 9 | can be used to bounce (pogo) with Down |
| Dash attack | Dash then J | 10 | goes through small enemies |
| Skill: Lantern Flash | L (30 Glow) | 6 plus stun | brief light burst, stuns small enemies 1.5 s |
| Guard | I | none | 0.25 s guard, perfect guard window of 0.12 s, grants Glow |
| Overture: Warm Light | O | 40 area | a wide ring of light, pushes everything away |

---

## 4.4 THE SEVEN MOVESETS

### 1. OFFERING STYLE (The Open Hand)
**Virtue:** Giving. **Feel:** wide, slow palm waves. **Shines against:** swarms, Penny Pips, The Collector, anything that sticks to you.

**Signature: Offer.** Any gold Lumi is carrying becomes ammo. Every coin spent from the purse adds +1 damage to the next hit (up to +10) and removes its weight instantly. Fighting with an empty purse makes your attacks faster by 15 percent.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Palm Push | J, J, J | 7 / 7 / 10 | the third hit sends a short shockwave (6 dmg, 3 tiles) |
| Wide Offering | K (hold 0.6 s) | 24 | huge frontal arc, strong knockback |
| Falling Petals | J in air | 14 | on landing, a ring wave pushes enemies out |
| Gentle Rush | Dash then J | 8 | pushes enemies back and cleans sticky coins and sap off Lumi |
| Skill: Coin Toss | L (20 Glow) | 3 per coin | spends up to 5 carried coins in a fan; with 0 coins, fires one soft orb (3 dmg) |
| Guard: Open Palm | I | none | perfect guard returns projectiles at 150 percent damage |
| **Overture: Everything Given** | O | 12 plus 1 per coin | flowers bloom across the screen, hit everything in view, spend all gold, remove all weight |

**Weakness:** low single-target damage and slow recovery. Does not heal.

### 2. TEMPO STYLE (Hourglass Shard)
**Virtue:** showing up on time. **Feel:** precise, rhythmic, counter-focused. **Shines against:** The Dreamer, patterned bosses, anything with readable timing.

**Signature: Beat.** A faint metronome pulse follows Lumi's lantern. Attacks pressed on the pulse deal +30 percent damage and give +3 extra Glow. Perfect guards slow time for 1 second.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Tick-Tock | J, J, J, J | 6 / 6 / 8 / 14 | fast four-hit combo; fourth hit launches |
| Hour Strike | K | 28 | delayed overhead; lands exactly 1 second after pressing, and can be held up to 2 s to place the hit |
| Pendulum Drop | J in air | 12 | swing arc downward, hits twice |
| Skip | Dash | none | short time-hop with full invincibility, can chain into attacks |
| Skill: Stopwatch | L (30 Glow) | none | freezes non-boss enemies 1.5 s; slows bosses 40 percent for 2 s |
| Guard: Tick | I | none | a perfect guard slows time 1 s and opens a counter slash (20 dmg) |
| **Overture: Last Hour** | O | stored | time stops for 4 s; every hit lands unseen and all damage hits at once when time resumes |

**Weakness:** unforgiving. Mistimed guards leave a long recovery.

### 3. DEVOUR STYLE (The Hollow Spoon)
**Virtue:** taking only what you need. **Feel:** close range and hungry. **Shines against:** The Host, projectile spam, spitters like Gilded Blossoms.

**Signature: Taste.** Lumi can absorb enemy projectiles into up to 3 **Pips**. Absorbing a fourth makes Lumi **Stuffed** for 1.5 seconds (can't act). Pips are ammo for the Skill. Taking only what you need keeps you fast.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Scoop | J, J, J | 9 / 9 / 13 | short range; the third hit pulls enemies in 1 tile |
| Gulp | K (hold 0.4 s) | 26 | ghost-mouth bite; swallows any enemy under 20 HP and turns it into a Pip |
| Slurp Drop | J in air | 11 | vacuum pull downward, brings small enemies to the ground |
| Chomp Dash | Dash | none | dash with mouth open; absorbs one projectile it passes through |
| Skill: Spit | L (1 Pip: 15 Glow) | 12 per Pip | fires stored Pips; 3 Pips fire a single large beam (45 dmg) |
| Guard: Open Wide | I | none | absorbs one projectile of any size as a Pip (no melee) |
| **Overture: The Table Clears** | O | 50 area | a giant spoon crashes down; refills Pips to full |

**Weakness:** no ranged options without stored Pips, and useless against purely melee enemies at long range.

### 4. MIMIC STYLE (Green Mirror Shard)
**Virtue:** admiring without comparing. **Feel:** tricky and improvised. **Shines against:** The Understudy (neutral), packs with varied attacks, bosses with many moves.

**Signature: Echo.** When Lumi is hit by (or perfectly guards) an enemy attack, the attack is stored as an **Echo** (holds 1). Lumi can then use it once as their own attack. Borrowing is allowed. Hoarding is not: Echoes fade after 20 seconds.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Reflection Cut | J, J, J | 9 / 9 / 12 | glassy slashes that flash a prismatic light |
| Copy Heavy | K | 20, or the copied attack's damage | with an Echo stored: performs the copied attack (visually an echo of the enemy's move). Without: plain glass slash |
| Glass Fall | J in air | 10 | a shard drops and sticks, then bursts |
| Glass Lunge | Dash | none | phases through projectiles during the dash |
| Skill: Replay | L (30 Glow) | 150 percent | uses the stored Echo at 150 percent size and damage |
| Guard: Mirror Parry | I | none | perfect guard stores the attack and returns 100 percent damage to the attacker |
| **Overture: Gallery of Faces** | O | varies | summons echoes of the last 3 stored attacks and plays them in sequence |

**Weakness:** no consistent kit. Gets worse when enemies have few attacks.

### 5. TETHER STYLE (Red Thread Spool)
**Virtue:** connection without clinging. **Feel:** mid-range ribbon whip, mobile. **Shines against:** The Devoted, flyers, enemies on platforms.

**Signature: Slack.** A thread attaches to whatever it hits for 3 seconds. Keeping a thread attached too long (all 3 seconds without releasing) pulls Lumi toward the target. **Releasing** a thread on purpose (tap Guard) deals burst damage. Letting go is the strongest move.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Ribbon Lash | J, J, J | 8 / 8 / 11 | reaches 3 tiles; hits attach a thread |
| Thread Wrap | K | 18 | wraps and pulls the enemy to Lumi, staggers; or pulls Lumi to a hook |
| Swing Drop | J in air | 13 | tethers to a ceiling hook or enemy and swings in an arc |
| Reel | Dash | none | grapple-dash up to 5 tiles toward an enemy or anchor |
| Skill: Tie Together | L (30 Glow) | 6 | ties two enemies; damage to one is split 50 percent to the other |
| Guard: Slip the Knot | I | none | on a perfect dodge, snaps a thread for 30 burst damage and reels Lumi behind the enemy |
| **Overture: Let Go** | O | 15 per thread | snaps all active threads at once; Lumi pulls in every enemy in view first |

**Weakness:** low damage if you cling. Rewards ending the connection at the right time.

### 6. EMBER STYLE (The Cooled Ember)
**Virtue:** patience. **Feel:** heavy, slow, enormous payoff. **Shines against:** The Boiling One, big slow targets, bosses with long openings.

**Signature: Banking.** Standing completely still builds **Heat** over 3 seconds (stages 1, 2, 3). The next attack spends all Heat for a damage multiplier of x1.5, x2, or x3. Moving slowly bleeds Heat. Getting hit clears it.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Ember Flick | J, J | 10 / 14 | slow two-hit combo, leaves tiny sparks |
| Cinder Hammer | K | 30 base | scaled by Heat: 45 / 60 / 90 |
| Falling Spark | J in air | 12 | on landing, an ember ring |
| Smoldering Step | Dash | none | short step; leaves a trail of embers that burn for 5 dmg |
| Skill: Banked Burst | L (30 Glow) | 25 x stage | spends all Heat in a radial burst |
| Guard: Breathe | I | none | holds Heat steady while Lumi is hit; blocks Rage buildup but not damage |
| **Overture: Kettle's Last Whistle** | O | 100 plus 30 per stage | a 2-second channel followed by one huge strike |

**Weakness:** punishes impatience and aggression. Useless in a frantic fight.

### 7. HUMBLE STYLE (The Bowed Crown)
**Virtue:** asking for help. **Feel:** low, evasive, with spirit allies. **Shines against:** The Champion (required for the final phase), crowds, long fights.

**Signature: Bow.** Pressing Guard makes Lumi bow low, ducking under high attacks. A perfect bow (0.2 seconds before impact) dodges and counters for 22 damage. Humble Style also lowers Hubris: every bow reduces it by 15.

| Move | Input | Damage | Notes |
|------|-------|--------|-------|
| Low Slash | J, J, J | 7 / 7 / 12 | crouched, short range; each slash keeps Lumi low |
| Rising Bow | K | 20 | rising uppercut that launches |
| Falling Petal | J in air | 10 | a soft drop from above |
| Duck Roll | Dash | none | low slide under projectiles and ground attacks |
| Skill: Call a Friend | L (25 Glow) | varies | summons one of seven spirit helpers (choose with Up / Down) |
| Guard: Bow Counter | I | 22 | perfect bow dodges and counters |
| **Overture: Seven Hands** | O | all at once | all seven spirits appear and each does their move together |

**The seven spirit helpers** (each defeated boss, plus Sir Alden):
- **Barnaby (Collector):** a ring of coins that blocks the next 2 hits.
- **Willow (Dreamer):** slows time in a small area.
- **Mabel (Host):** restores 15 HP.
- **Pip (Understudy):** a decoy that draws enemy attacks for 4 seconds.
- **Clementine (Devoted):** pulls the target into melee range.
- **Ember (Boiling One):** cracks armor, adding +25 percent damage for 5 seconds.
- **Sir Alden (Champion):** a shield of light that blocks all damage for 2 seconds.

**Weakness:** low base damage. Needs Glow. Helpers have a cooldown (8 seconds each).

---

## 4.5 DEBUFF REFERENCE

| Region | Debuff | Trigger | Effect | Cure |
|--------|--------|---------|--------|------|
| Greed | Weight / Burden | +1 weight per 10 gold; 60+ gold at a shrine applies Burden | 30 gold: -15 percent speed and jump. 60 gold: -30 percent speed and jump, dash halved. Burden holds until gold falls under 20 | offer gold at bowls |
| Sloth | Drowse | +1 per second idle, +0.5 per second when moving with unlit lanterns in the room | 50: vignette and 0.1 s input delay. 100: sleep for 3 s, then reset to 60 | light lanterns (-20 each) |
| Gluttony | Stuffed | +25 Fullness per food eaten; mindful eating (under 60 percent HP) gains none and heals +10 | at 100: Stuffed for 20 s: no dash, -25 percent attack speed, healing halved | move and fight (-1 per second) |
| Envy | Comparison | standing in a spotlight cone for over 1 s | Glow gain stops, lantern dims, +10 percent damage taken, lingers 5 s | leave the light |
| Lust | Fixation / Ache | within 5 tiles of a Heart Lantern | pulled toward it at 40 percent speed, +25 percent damage taken. Collecting one gives Ache: Glow gain -50 percent for 90 s | dash away |
| Wrath | Rage | +10 per hit taken, +3 per whiffed swing | at 100: Berserk for 8 s: no guard, dash becomes a short lunge, each swing costs 2 HP | stand still near a vent, perfect guard (-30) |
| Pride | Hubris | +1 per second while no damage is taken | at 100: next hit taken is doubled, healing disabled, polished enemies become immune | bow at a shrine, use Bow, accept help (Humble Style) |

Debuff flavor text shows once on first trigger in each region.

---

## 4.6 BALANCE TARGETS

| Region | Normal enemy HP | Contact damage | Boss | Boss HP | Boss damage |
|--------|-----------------|----------------|------|---------|-------------|
| The Wake | 10 to 15 | 4 to 5 | Old Moss (tutorial) | 120 | 8 to 10 |
| Greed | 20 to 40 | 8 to 12 | The Collector | 700 | 12 to 22 |
| Sloth | 25 to 45 | 8 to 12 | The Dreamer | 800 | 12 to 24 |
| Gluttony | 35 to 55 | 10 to 14 | The Host | 900 | 14 to 26 |
| Envy | 40 to 60 | 10 to 16 | The Understudy | 900 | 14 to 26 |
| Lust | 40 to 65 | 12 to 16 | The Devoted | 1000 | 16 to 28 |
| Wrath | 50 to 75 | 14 to 20 | The Boiling One | 1000 | 16 to 30 |
| Pride | 60 to 90 | 16 to 24 | The Champion | 1200 | 18 to 32 |
| Mirror Gate | n/a | n/a | Your Reflection | infinite until Accept | 12 to 20 |

Target clear times: tutorial 10 minutes, each region 40 to 60 minutes, each boss 5 to 10 minutes of attempts, the final fight is meant to be tried a few times and then abandoned.

---

## 4.7 BEST STYLE PER BOSS (suggestions, not requirements)

| Boss | Strong choice | Why |
|------|---------------|-----|
| The Collector | Offering | spending gold shrinks him; palm waves handle his coins |
| The Dreamer | Tempo | her lullaby notes have strict timing |
| The Host | Devour | absorbs snacks as Pips instead of building Fullness |
| The Understudy | any style it has not copied | it only steals the style you are holding; Mimic is neutral |
| The Devoted | Tether | thread cutting breaks her hold |
| The Boiling One | Ember | stillness cools Rage and fuels Banking |
| The Champion | Humble (required for phase 3) | helper spirits are the only way through |
| Your Reflection | none | it uses all seven styles; stillness is the only way |

# Part 5: Art, Sound, UI and the Tutorial


---

## 5.1 CHARACTER DESIGN

- **Lumi:** small and round, about 1.5 heads tall. A soft pale-peach face with large dark eyes, a lavender hooded cloak, and a paper lantern on a short pole. Mouth is a tiny line. Walk is a hop. The lantern flame shrinks as health drops.
- **Nim:** a palm-sized moth made of warm light. Large wings that pulse with emotion. Flits near the lantern. Brightens when happy, dims when scared.
- **The Reflection:** identical to Lumi, but in silver-blue and pale, drawn in cleaner lines. Always a half-second behind. Smiles slightly too long.

### Game-wide look
Pastel storybook. Soft outlines, no pure black (darkest value is a deep indigo). Gentle gradients. Layered paper-cut backgrounds. Glowing particles float everywhere.

---

## 5.2 PALETTES

| Area | Core colors | Hex |
|------|-------------|-----|
| The Still Pond (hub) | lavender, peach, mint, deep indigo | #C9B8F0, #FFD9C0, #CFF1E0, #4A3A7A |
| The Wake | meadow green, cream, sky | #BFE3B4, #FFF6DC, #CFE8F7 |
| Greed | honey gold, cream, bronze | #F2C14E, #FFF4D6, #A97C2F |
| Sloth | dusk lilac, indigo, fog, moon yellow | #A99BD6, #5B5C9E, #E8E3F5, #F7E7A1 |
| Gluttony | candy pink, cream, mint, chocolate | #F6A6C1, #FFF0E0, #BDEBD3, #6B4034 |
| Envy | verdigris, glass white, deep green, silver | #7FB8A4, #EAF6F2, #2F5D50, #C9D6D3 |
| Lust (longing) | rose, ribbon red, twilight purple, blush | #E8798B, #C23B56, #6A4C93, #F8D5DC |
| Wrath | clay, ember, ash, steam | #C0714A, #F26B3A, #5A4A45, #EFE4DC |
| Pride | pearl, gold, sky, shadow | #F4F1EC, #E3C16F, #BFD7EA, #8A8FA3 |
| Mirror Gate | silver-blue, mirror white | #B9CBE6, #F5F9FF |
| Bad ending (hell) | blood red, fire, near-black | #7A0F1A, #FF3B1F, #1A0508 |

### The "wrongness" tell in each region
The cute surface slowly gets uncanny. Each region has one small detail that gets worse the deeper you go:
- **Greed:** the coins in the ground slowly grow tiny faces.
- **Sloth:** background characters in hammocks stop breathing.
- **Gluttony:** crumbs arrange themselves into eyes.
- **Envy:** reflections lag behind and smile.
- **Lust:** the ribbons all point toward Lumi.
- **Wrath:** clouds show steam faces mid-scream.
- **Pride:** confetti freezes in the air and the applause loops.

---

## 5.3 ASSET CHECKLIST (per region)

- **Backgrounds:** 4 parallax layers (far sky, mid scenery, near scenery, foreground particles).
- **Tilesets:** ground, platforms, walls, hazards, decor. Each region has a "safe" and a "wrong" variant.
- **Props:** 25 to 30 per region (shrines, lanterns, signs, hidden alcoves).
- **Enemies:** 3 to 4 per region, each with idle, move, attack, hurt, death (about 20 frames each).
- **Boss:** 1 per region with 3 phases, each with its own attack animations, plus a defeat animation and a sad "true form" sprite.
- **NPCs:** 2 side quest NPCs per region.
- **Cutscene art:** one illustrated storybook panel per boss intro and defeat (14 panels), plus 2 for each ending.
- **Memory Petal collectibles:** 5 per region, each with a short petal-shaped light.

### Lumi animation list
Idle, walk, run, jump, fall, land, double jump, dash, super dash charge and release, wall cling, wall climb, glide, ground pound, grapple, glass step, attack (each style's combo), heavy, guard, perfect guard, heal, hurt, death, bench rest, bow, spirit call, accept.

---

## 5.4 MUSIC

**Core leitmotif: "Lumi's Lullaby."** A four-note phrase that rises, then falls. It appears in every track, always in a different instrument. As the player progresses, it detunes slightly more. After the Good Ending, it plays perfectly in tune for the first time.

| Area | Track | Instruments | Notes |
|------|-------|-------------|-------|
| Title | "What the Water Keeps" | music box, soft piano | cracks and detunes if the bad ending was seen |
| Hub | "Still Water" | music box, felt piano, pad | loses one note per region cleared |
| The Wake | "First Steps" | glockenspiel, ukulele | bouncy and light |
| Greed | "Honeycomb" | celesta, harp | sweet and glittering |
| Collector boss | "The Collector's Waltz" | waltz strings, coins as percussion | 3/4 time that stutters in phase 3 |
| Sloth | "Slumber Hollow" | slow cello, warm pad | tempo slows over time |
| Dreamer boss | "Lullaby for the Weary" | harp, humming choir | gentle, then heavy |
| Gluttony | "The Endless Table" | marimba, tuba | party feel that wears thin |
| Host boss | "Second Helping" | jazzy waltz, clinking cutlery | tempo increases |
| Envy | "Gallery of Glass" | glass harmonica, vibraphone | reverb-heavy |
| Understudy boss | "Understudy's Overture" | theatrical strings | mimics the player's style cues |
| Lust (longing) | "Ribbon Orchard" | pizzicato strings, accordion | warm, a little too close |
| Devoted boss | "Don't Go" | solo violin, soft music box | clingy, never resolves |
| Wrath | "The Ashen Kettle" | bass clarinet, kettle percussion | rhythm rises with Rage |
| Boiling One boss | "Boiling Point" | brass stabs, steam hiss | dissolves into a single whistle on defeat |
| Pride | "The Tower of Applause" | muted brass, strings, applause | the applause loops unnaturally |
| Champion boss | "Perfect Form" | flawless strings | cracks into a human melody |
| Memory Path | "Silhouettes" | solo piano | each segment adds one old theme |
| Final arena | silence, then "Come Home" | the lullaby, resolved | first chord plays only on Accept |
| Good ending | "You Were Home" | full ensemble | all seven region themes in tune |
| Bad ending | "Hell, Softly" | reversed music box | the lullaby, backwards |
| Side quests | per quest | one soft instrument | no accompaniment |

---

## 5.5 SOUND EFFECTS

- **Lumi:** soft footsteps (change by surface), lantern creak, hop, land, dash whoosh, hurt "oof", small relief sigh on heal.
- **Combat:** soft impact thuds (no harsh metal), glassy chimes on perfect guard, a warm bell on Glow full.
- **Per-style signature:** Offering (soft wind chime), Tempo (clock tick), Devour (gentle gulp), Mimic (glass echo), Tether (silk hiss), Ember (crackle), Humble (small bow sound, then bell).
- **Debuffs:** each has its own sound (Weight: low coin clink; Drowse: yawn; Stuffed: soft burp; Comparison: faint whisper; Fixation: heartbeat; Rage: kettle whistle; Hubris: applause swell).
- **World:** pond ripple, shrine chime, bench lullaby, petal collect, door open, Mirror Gate hum.
- **Reflection:** voice has a slight echo delay and water ripple under every line.

---

## 5.6 UI AND HUD

- **Health:** top-left. A paper lantern icon whose flame shrinks as health drops, with a thin bar underneath for clarity.
- **Glow:** a ring of 5 petals around the lantern base. Each fills at 20 Glow.
- **Heal charges:** 3 small oil drops under the lantern.
- **Debuff tray:** below the health. Icons appear with a short flavor line the first time each debuff triggers, then icons only.
- **Style indicator:** bottom-left. Three slots in an arc; the active one is bright.
- **Gold counter:** only appears in Greed.
- **Boss bar:** bottom center, a thin ribbon with the boss's name. The Reflection has no bar, only a mirror frame.
- **Minimal on-screen text.** No pop-up tutorial boxes. Everything is taught with crayon signs in The Wake.

### Menus
- **Title screen:** the lantern and a pond. Cracked and tinted after the bad ending until the Good Ending is seen once.
- **Pause menu:** resume, map, loadout, keepsakes, settings, quit.
- **Map:** hand-drawn on parchment, hub at the center, regions radiating outward.
- **Altar of Hands screen:** three style slots, each style shown as a small diorama.
- **Memory Tree screen:** branches with unlocked petal lines.
- **Keepsake gallery:** every Keepsake with its memory line.
- **Save:** autosave at benches. One slot.

### Accessibility options
- Reduce screen shake and flashes.
- Colorblind palettes (deuteranopia, protanopia, tritanopia).
- Hold-to-toggle for Heal and Heavy.
- **Gentle Mode:** debuff buildup is halved and damage taken is reduced by 25 percent. Explained to the player as "a softer way to walk."
- Remappable keys and buttons.
- Subtitle size and background.
- Audio sliders for music, effects, and voice.

---

## 5.7 THE WAKE (TUTORIAL AREA)

### Room by room
1. **Waking Meadow:** Lumi wakes. Nim appears. Walk and jump signs.
2. **Puddle Path:** jump over puddles; the first Puddle Sprite.
3. **Jelly Glen:** the first Pale Jelly teaches the light attack.
4. **Resting Stone:** a small bench teaches Heal and saving.
5. **Dust Hollow:** Dust Bunnies teach dash and dodging.
6. **Old Moss Clearing:** a gentle tutorial boss.
7. **Wind Ribbon Shrine:** Lumi collects the Wind Ribbon.
8. **First Door:** a gap crossing that requires the dash, leading to the Greed door.

### Tutorial enemies
- **Pale Jelly:** HP 10. Does not attack unless hit. Contact damage 4. Teaches attacking safely.
- **Puddle Sprite:** HP 15. Leaps out of puddles in a predictable arc. Damage 5. Teaches timing and jumping.
- **Dust Bunny:** HP 12. Fast, charges in a straight line. Damage 5. Teaches dash and dodge.

### Tutorial boss: Old Moss
A slow, ancient, mossy turtle. HP 120, damage 8 to 10. Attacks: a slow, telegraphed head bump that lunges forward; a rolling shell (jump over); and a fan of spores (dash through or weave between). Below half health, he quickens his recovery and adds a short aimed spore burst. Each attack has a visible wind-up so the tutorial teaches reading tells, jumping, dashing, and healing under pressure. He is protecting the Wind Ribbon, which is all that's left of the wind he used to ride.

*(Pre-fight)*
OLD MOSS: Little light... that ribbon is all I have left of the wind.

NIM: We just need to borrow it.

OLD MOSS: Everyone says borrow.

*(Defeat: he lowers his head and smiles.)*

OLD MOSS: Be gentle with it. It remembers being free.

*(Reward: the Wind Ribbon. The first lesson of the game: you can take something without hoarding it.)*

---

## 5.8 THE STILL POND (HUB LAYOUT)

A circular lakeside shrine. From left to right:
- **Far left:** the Bench of Rest and Orrin the stone frog.
- **Left-center:** the Altar of Hands.
- **Center:** the Pond, with Marl folding paper boats at the shore.
- **Behind the pond:** the Mirror Gate, tall and silent.
- **Right-center:** the Memory Tree and the Table of Remembering.
- **Far right:** Nim's Lantern Post.
- **Around the ring:** seven doors, each with a sleeping symbol: a coin (Greed), a hammock (Sloth), a spoon (Gluttony), a window (Envy), a ribbon (Lust), a kettle (Wrath), a crown (Pride).

### Hub changes over time
Each region cleared lights one lantern around the ring. The sky grows brighter, the flowers bloom, the pond calmer, but the music is slightly more out of tune each time. The Reflection in the pond lingers a little longer before it waves back.


---

# PART 6: PROTOTYPE IMPLEMENTATION NOTES

This part is not new lore. It records which bible story beats are in the playable prototype, where they live in code, and where the prototype differs from the bible. All story text is in `scripts/story.gd` (plus the boss lines in `sloth.gd` and `greed.gd`). If the bible changes, update those files.

## 6.1 Story beats in the game

Rule: the Reflection is never spoken about in the prototype's text. No Nim line, narration or whisper points at it. The player only sees a figure in the pond and slowly works it out.

| Beat | Bible source | Where it plays |
|------|--------------|----------------|
| Waking by the pond, meeting Nim, seven keyholes and seven doors | Hub arrival | Plays once at the start (`Story.ARRIVAL`, `main.gd` `_ready`). The bible's Reflection beats (late wave, whisper) are left out on purpose. Interaction prompts are hidden while it plays |
| Nim's lines on entering Greed, at the shrine, and when Lumi gets heavy | Greed region | `Story.GREED_ENTER`, `GREED_SHRINE` (first shrine use), `GREED_WEIGHT` (first time weight passes 30%) |
| The Collector's defeat lines | Greed boss | `greed.gd` |
| Nim's line after Greed, first door glows, Sloth opens, the music loses a note | Hub changes | `Story.AFTER_GREED`, plays when Lumi is back in the hub |
| Sloth entry, tablets and Dreamer fight lines | Sloth region | `sloth.gd` |
| Nim's lines after Sloth, Gluttony door opens | Hub changes | `Story.AFTER_SLOTH` |
| The pond figure changes | Hub changes over time | `reflection.gd`: a mirrored Lumi whose eyes follow Lumi, brighter and larger with each region cleared, smiling from three clears. Silent and unexplained |

Beats for regions that are not built yet (Gluttony onward, the Mirror Gate, the endings, side quests) are not in the game.

## 6.2 Differences from the bible

These are prototype adaptations, not decisions. Say if the bible should win.

- Boss health is scaled down for testing: The Collector 360, The Dreamer 420 (bible: Dreamer 800).
- Sloth's input delay (0.1s) is approximated by making Lumi 15% slower at 50 Drowse.
- Sloth only opens after Greed is cleared (the bible does not gate door order).
- Fighting styles are swapped with Tab. K heavy, L skill, I guard, O overture are new key bindings.
- The Hourglass Shard and Dusk Key are flags only. Tempo Style is not built.
- Debuffs are harsher than the bible's first description: Drowse and Weight add +1 damage per hit at their upper tiers, Drowse blocks healing at 80 and Weight blocks dash and double jump. The bible's Drowse still approximated by slowing, not the 0.1s input delay.
- Difficulty (Gentle / Normal / Hard), bench-only saves with Continue, and a secret No-Hit Challenge (one hit ends the run, unlocked by beating the game) are user-requested prototype features, not in the bible.
- W and S are new aim keys. W + J swings up, S + J in the air pogos, W + J with the Open Hand is Rising Palm, and Coin Toss throws in 8 directions (straight shots; the bible only says it throws coins). User-requested, not from the bible.
- The Wake is split into four rooms with a locked camera.
- Nim's Lantern Post gives short gameplay hints (what each region teaches). They are hints, not lore. After seven regions it shows its normal text.
- The hub is built from stepped platforms so every step is jumpable, and has a killbox.

### Prototype additions (not canon yet)

- Greedy Mites, the Coin Guard (Greed Vault mini-boss) and the Dozy Warden (Sloth sky-route mini-boss) are prototype content. Names and rewards are not decided.
- Defeating a region boss does not return the player to the hub; they climb out via the Vault Exit or Dream Exit on purpose.
