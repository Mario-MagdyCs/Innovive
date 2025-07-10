// utils/getRandomPrompt.js
const fs = require('fs');
const path = require('path');

function getRandomPromptForCategory(categoryFolder) {
  try {
    const captionsPath = path.join(__dirname, '..', 'industrial_captions', `${categoryFolder}.txt`);
    const content = fs.readFileSync(captionsPath, 'utf-8');
    const lines = content.split('\n').map(line => line.trim()).filter(line => line.includes(':'));

    if (lines.length === 0) return null;

    const randomLine = lines[Math.floor(Math.random() * lines.length)];
    const prompt = randomLine.split(':').slice(1).join(':').trim();

    return prompt;
  } catch (err) {
    console.error(`Error reading captions for ${categoryFolder}:`, err.message);
    return null;
  }
}

module.exports = getRandomPromptForCategory;



