const fs = require('fs');
const path = require('path');

// Load JSON
const dataPath = path.join(__dirname, 'expanded_materials_dataset.json');
const materialsData = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

/**
 * Shuffle helper
 */
function shuffle(array) {
  return array.sort(() => Math.random() - 0.5);
}

/**
 * Generates a short, clear, and high-quality DIY prompt
 */
function generateRandomPrompt(materials = []) {
  let promptParts = [];

  for (let material of materials) {
    const key = material.toLowerCase().trim();
    const entry = materialsData[key];

    if (!entry || !entry.projects || entry.projects.length === 0) {
      console.warn(`⚠️ Material not found or has no projects: "${material}"`);
      continue; // skip to next
    }

    // Select a random project from the list of projects for this material
    const randomProject = entry.projects[Math.floor(Math.random() * entry.projects.length)];
    
    // Short, clear, high-quality prompt
    //const prompt = `Creative DIY ${randomProject} using ${material}. High-quality, realistic, eco-friendly, and visually appealing.`;
    const prompt = `Creative DIY ${randomProject} crafted from ${material}. Decorative, realistic, detailed 9K.`;
    promptParts.push(prompt);
  }

  if (promptParts.length === 0) {
    return "⚠️ No valid materials were provided.";
  }

  return `${promptParts.join(" ")}.`;
}

module.exports = generateRandomPrompt;
