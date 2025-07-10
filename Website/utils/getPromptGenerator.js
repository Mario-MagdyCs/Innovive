async function getPromptGenerator(similarity) {
    switch (Number(similarity)) {
      case 25:
        return require('./promptGenerators/stable_diff');
      case 50:
        return require('./promptGenerators/prompt_flux');
      case 75:
        return require('./promptGenerators/preserve_prompt');
      default:
        throw new Error(`Unsupported similarity value: ${similarity}`);
    }
  }
  
  module.exports = getPromptGenerator;
  