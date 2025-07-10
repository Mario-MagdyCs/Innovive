
import random

VALID_CRAFTS = {
    frozenset(["plastic bottle"]): ["self-watering planter", "vertical garden pot", "hanging bird feeder"],
    frozenset(["tin can"]): ["herb planter", "candle holder", "wind chime", "painted utensil holder", "DIY lantern"],
    frozenset(["glass bottle"]): ["bottle lamp", "painted flower vase", "colorful hanging vase", "wine bottle candle holder"],
    frozenset(["glass jar"]): ["terrarium", "jar lantern", "kitchen spice jar", "mini succulent terrarium"],
    frozenset(["paper"]): ["origami mobile", "recycled wall art", "paper wreath", "recycled greeting card"],
    frozenset(["plastic container"]): ["storage box", "desk organizer", "multi-purpose drawer divider", "recycled storage cube"],
    frozenset(["paper", "plastic bottle"]): ["bird feeder with paper roof", "decorative garden birdhouse"],
    frozenset(["paper", "glass jar"]): ["mason jar lantern with paper cutouts", "labelled herb jar", "labelled DIY spice jar"],
    frozenset(["paper", "plastic container"]): ["labeled drawer organizer", "recycled makeup drawer", "recycled craft supply bin"],
    frozenset(["paper", "tin can"]): ["wind chime with paper streamers", "desk pencil holder"],
    frozenset(["paper", "glass bottle"]): ["message bottle with paper tag", "paper-wrapped message bottle", "paper-labeled decorative bottle"],
    frozenset(["plastic bottle", "tin can"]): ["tiered plant stand"],
    frozenset(["glass bottle", "glass jar"]): ["candle duo decor", "matched glass storage set", "candlelight centerpiece"],
    frozenset(["glass bottle", "plastic bottle"]): ["recycled hanging flower vases", "dual-material light fixture"],
    frozenset(["plastic container", "tin can"]): ["stackable supply drawers", "multi-purpose desktop organizer"],
    frozenset(["plastic container", "glass jar"]): ["compact kitchen container set"],
    frozenset(["glass jar", "tin can"]): ["rustic tool holder set"],
    frozenset(["plastic container", "plastic bottle"]): ["DIY hydroponic grow box"],
    frozenset(["plastic container", "glass bottle"]): ["modular ambient bottle lamp", "upcycled display set"],
    frozenset(["glass jar", "plastic bottle"]): ["hanging herb planter with bottle base", "recycled container planter with jar top"],
    frozenset(["glass bottle", "tin can"]): ["rustic light fixture with tin base", "ambient glass and metal lantern"],
}

STYLE_BY_CRAFT = {
    "planter": [
        "eco-friendly upcycled aesthetics",
        "rustic DIY style"
    ],
    "feeder": [
        "eco-friendly upcycled aesthetics",
        "rustic DIY style"
    ],
    "vase": [
        "modern minimalist design",
        "boho-chic crafting style"
    ],
    "lantern": [
        "vintage touch",
        "boho-chic crafting style"
    ],
    "terrarium": [
        "modern minimalist design",
        "boho-chic crafting style"
    ],
    "mobile": [
        "handmade aesthetic",
        "boho-chic crafting style"
    ],
    "art": [
        "handmade aesthetic",
        "eco-friendly upcycled aesthetics"
    ],
    "lamp": [
        "ambient decor style",
        "modern minimalist design"
    ],
    "box": [
        "modern minimalist design",
        "eco-friendly upcycled aesthetics"
    ],
    "organizer": [
        "modern minimalist design",
        "for home decor"
    ],
    "chime": [
        "rustic DIY style",
        "boho-chic crafting style"
    ],
    "holder": [
        "rustic DIY style",
        "vintage touch"
    ]
}

# --- Extract Keyword ---
def extract_keywords(craft_name):
    craft_name = craft_name.lower()
    for keyword in STYLE_BY_CRAFT:
        if keyword in craft_name:
            return keyword
    return None

# --- Generate Prompt ---
def generate_diy_prompt(materials):
    materials_set = frozenset(materials)

    if len(materials) > 2:
        return generate_static_prompt(materials)

    if materials_set not in VALID_CRAFTS:
        return generate_static_prompt(materials)

    valid_crafts = VALID_CRAFTS[materials_set]
    selected_craft = random.choice(valid_crafts)
    keyword = extract_keywords(selected_craft)

    if keyword and keyword in STYLE_BY_CRAFT:
        style = random.choice(STYLE_BY_CRAFT[keyword])
    else:
        style = "DIY aesthetic"

    context = random.choice([
        "placed on a wooden table",
        "photographed in soft natural light",
        "styled on a clean workspace",
        "displayed with minimal props",
        "surrounded by upcycled decor"
    ])

    return (
        f"a diy {' and '.join(materials)} {selected_craft}"
    )

# --- Static Prompt Fallback ---
def generate_static_prompt(materials):
    return (
        f"Generate a realistic DIY project made from recycled {', '.join(materials)}. "
    )

# --- Test Function ---
def test_diy_prompt(material_combos):
    for materials in material_combos:
        prompt = generate_diy_prompt(materials)
        print(f"Input: {materials}\n→ Prompt: {prompt}\n")

# test_diy_prompt([
#     ["Plastic bottles"]
# ])