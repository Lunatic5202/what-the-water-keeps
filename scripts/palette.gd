extends RefCounted
# Shared colours. Rule: every solid thing must be clearly darker or lighter
# than what sits behind it. Ground is the darkest thing in a scene, and
# characters get an INK or RIM outline so they never melt into it.

const INK := Color(0.12, 0.10, 0.24)      # outlines, text outlines
const RIM := Color(0.95, 0.92, 1.0)       # light rim on dark characters

# Wake (sky is pale blue, so the ground is a deep meadow green)
const WAKE_GROUND := Color(0.36, 0.55, 0.41)
const WAKE_GROUND_TOP := Color(0.74, 0.90, 0.66)
const WAKE_ARENA := Color(0.31, 0.48, 0.37)
const WAKE_CLEARING := Color(0.68, 0.84, 0.72)

# Greed (sky is cream gold, so the ground is dark amber)
const GREED_SKY := Color(0.98, 0.93, 0.74)
const GREED_GROUND := Color(0.42, 0.28, 0.13)
const GREED_GROUND_TOP := Color(1.0, 0.86, 0.45)
# Sloth (sky is dusk lilac, so ground and platforms are deep indigo)
const SLOTH_SKY := Color(0.66, 0.61, 0.84)
const SLOTH_FAR := Color(0.55, 0.52, 0.80)
const SLOTH_GROUND := Color(0.17, 0.15, 0.38)
const SLOTH_GROUND_TOP := Color(0.93, 0.90, 1.0)
const FOG := Color(0.91, 0.89, 0.96)
const MOON := Color(0.97, 0.91, 0.63)
const GOLD_OUTLINE := Color(0.30, 0.18, 0.08)
