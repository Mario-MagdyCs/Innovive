class_names = [
    'aluminum_food_can', 'aluminum_soda_can', 'cardboard', 'fabric', 'glass_bottle', 'glass_jar',
    'paper', 'plain_cup', 'plastic_bag', 'plastic_bottle', 'plastic_cup', 'plastic_cutlery',
    'plastic_detergent_bottle', 'plastic_food_container', 'plastic_straws', 'styrofoam_food_containers'
]


const VALID_CRAFTS = new Map([
  [JSON.stringify(["plastic_bottle"]), ["self-watering planter", "vertical garden pot", "hanging bird feeder"]],
  [JSON.stringify(["aluminum_food_can"]), ["herb planter", "candle holder", "wind chime", "painted utensil holder", "lantern"]],
  [JSON.stringify(["glass_bottle"]), ["bottle lamp", "painted flower vase", "colorful hanging vase", "wine bottle candle holder"]],
  [JSON.stringify(["glass_jar"]), ["terrarium", "jar lantern", "kitchen spice jar", "mini succulent terrarium"]],
  [JSON.stringify(["paper"]), ["origami mobile", "recycled wall art", "paper wreath", "recycled greeting card"]],
  [JSON.stringify(["cardboard"]), ["DIY cat house", "desktop organizer", "recycled storage box", "photo frame", "gift box"]],
  [JSON.stringify(["plastic_food_container"]), ["storage box", "desk organizer", "multi-purpose drawer divider", "recycled storage cube"]],
  [JSON.stringify(["plastic_cup"]), ["stackable cup planter", "mini seed starter", "hanging bird feeder", "table organizer"]],
  [JSON.stringify(["plain_cup"]), ["decorative candle holder", "mini storage container", "recycled pen holder", "mini vase"]],
  [JSON.stringify(["paper", "plastic_bottle"]), ["bird feeder with paper roof", "decorative garden birdhouse"]],
  [JSON.stringify(["paper", "glass_jar"]), ["mason jar lantern with paper cutouts", "labelled herb jar", "labelled DIY spice jar"]],
  [JSON.stringify(["paper", "plastic_food_container"]), ["labeled drawer organizer", "recycled makeup drawer", "recycled craft supply bin"]],
  [JSON.stringify(["paper", "aluminum_food_can"]), ["wind chime with paper streamers", "desk pencil holder"]],
  [JSON.stringify(["paper", "glass_bottle"]), ["message bottle with paper tag", "paper-wrapped message bottle", "paper-labeled decorative bottle"]],
  [JSON.stringify(["plastic_bottle", "aluminum_food_can"]), ["tiered plant stand"]],
  [JSON.stringify(["glass_bottle", "glass_jar"]), ["candle duo decor", "matched glass storage set", "candlelight centerpiece"]],
  [JSON.stringify(["glass_bottle", "plastic_bottle"]), ["recycled hanging flower vases", "dual-material light fixture"]],
  [JSON.stringify(["plastic_food_container", "aluminum_food_can"]), ["stackable supply drawers", "multi-purpose desktop organizer"]],
  [JSON.stringify(["plastic_food_container", "glass_jar"]), ["compact kitchen container set"]],
  [JSON.stringify(["glass_jar", "aluminum_food_can"]), ["rustic tool holder set"]],
  [JSON.stringify(["plastic_food_container", "plastic_bottle"]), ["DIY hydroponic grow box"]],
  [JSON.stringify(["plastic_food_container", "glass_bottle"]), ["modular ambient bottle lamp", "upcycled display set"]],
  [JSON.stringify(["glass_jar", "plastic_bottle"]), ["hanging herb planter with bottle base", "recycled container planter with jar top"]],
  [JSON.stringify(["glass_bottle", "aluminum_food_can"]), ["rustic light fixture with tin base", "ambient glass and metal lantern"]],
]);

const STYLE_BY_CRAFT = {
  "planter": ["eco-friendly upcycled aesthetics", "rustic DIY style"],
  "feeder": ["eco-friendly upcycled aesthetics", "rustic DIY style"],
  "vase": ["modern minimalist design", "boho-chic crafting style"],
  "lantern": ["vintage touch", "boho-chic crafting style"],
  "terrarium": ["modern minimalist design", "boho-chic crafting style"],
  "mobile": ["handmade aesthetic", "boho-chic crafting style"],
  "art": ["handmade aesthetic", "eco-friendly upcycled aesthetics"],
  "lamp": ["ambient decor style", "modern minimalist design"],
  "box": ["modern minimalist design", "eco-friendly upcycled aesthetics"],
  "organizer": ["modern minimalist design", "for home decor"],
  "chime": ["rustic DIY style", "boho-chic crafting style"],
  "holder": ["rustic DIY style", "vintage touch"],
  "house": ["pet-friendly DIY style", "eco-friendly upcycled aesthetics"],
  "frame": ["vintage touch", "modern minimalist design"],
  "cup": ["modern minimalist design", "eco-friendly upcycled aesthetics"],
};

// --- Extract Keyword ---
function extractKeyword(craftName) {
  const lowerCraftName = craftName.toLowerCase();
  for (const keyword of Object.keys(STYLE_BY_CRAFT)) {
    if (lowerCraftName.includes(keyword)) {
      return keyword;
    }
  }
  return null;
}

// --- Generate DIY Prompt ---
function generateDiyPrompt(materials) {
  const materialsKey = JSON.stringify(materials.sort());

  if (materials.length > 2) {
    return generateStaticPrompt(materials);
  }

  if (!VALID_CRAFTS.has(materialsKey)) {
    return generateStaticPrompt(materials);
  }

  const validCrafts = VALID_CRAFTS.get(materialsKey);
  const selectedCraft = validCrafts[Math.floor(Math.random() * validCrafts.length)];
  const keyword = extractKeyword(selectedCraft);

  const style = keyword && STYLE_BY_CRAFT[keyword]
    ? STYLE_BY_CRAFT[keyword][Math.floor(Math.random() * STYLE_BY_CRAFT[keyword].length)]
    : "DIY aesthetic";

//   const context = [
//     "placed on a wooden table",
//     "photographed in soft natural light",
//     "styled on a clean workspace",
//     "displayed with minimal props",
//     "surrounded by upcycled decor"
//   ][Math.floor(Math.random() * 5)];

  return `a diy ${materials.join(" and ")} ${selectedCraft} in ${style}.`;
}

// --- Static Prompt Fallback ---
function generateStaticPrompt(materials) {
  return `Generate a realistic DIY project made from recycled ${materials.join(", ")}.`;
}

// // --- Test Function ---
// function testDiyPrompt(materialCombos) {
//   for (const materials of materialCombos) {
//     const prompt = generateDiyPrompt(materials);
//     console.log(`Input: ${materials}\n→ Prompt: ${prompt}\n`);
//   }
// }

// // --- Test Usage ---
// testDiyPrompt([
//   ["plastic bottle"],
//   ["tin can"],
//   ["glass bottle", "glass jar"],
//   ["paper", "glass jar"],
//   ["paper", "tin can"],
//   ["plastic bottle", "glass bottle"],
//   ["paper", "plastic container"],
// ]);


module.exports=generateDiyPrompt