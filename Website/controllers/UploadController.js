const MaterialClassifier = require("./MaterialClassifier");
const ProjectGenerator = require("./ProjectGenerator");
const GeneratedProject = require("../models/Project");
const User = require('../models/User');

// Classify uploaded images
async function classify(files) {
  const classifier = new MaterialClassifier(files);
  await classifier.classify();
  return classifier.getResults(); // Returns materials array
}

// Generate project using classified materials
async function generate(req, res) {
  res.setHeader('Content-Type', 'application/x-ndjson');
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  const class_names = [
    'aluminum_food_can', 'aluminum_soda_can', 'cardboard', 'fabric', 'glass_bottle', 'glass_jar',
    'paper', 'plain_cup', 'plastic_bag', 'plastic_bottle', 'plastic_cup', 'plastic_cutlery',
    'plastic_detergent_bottle', 'plastic_food_container', 'plastic_straws', 'styrofoam_food_containers'
  ]

  try {
    // Step 1: classify uploaded images first
    const materials = await classify(req.files);
    const numberOfImages = req.body.numberOfImages;
    var similarity = req.body.similarity;

    if (!class_names.includes(materials[0])) {
      console.warn(`⚠️ Material "${materials[0]}" is not recognized. Setting similarity to 50.`);
      similarity = 50;
    }


    for (let i = 0; i < numberOfImages; i++) {
      const generator = new ProjectGenerator(materials);
      const project = await generator.build(similarity, req.files);

      // Ensure the materials and instructions are properly formatted as objects
      const formattedMaterials = Array.isArray(project.materials) && project.materials.length > 0
        ? project.materials.map(material => {
          return typeof material === "string"
            ? { title: material, description: "No description provided." }
            : material;
        })
        : [];

      const formattedInstructions = Array.isArray(project.instructions) && project.instructions.length > 0
        ? project.instructions.map(step => {
          return typeof step === "string"
            ? { title: step, description: "No description provided." }
            : step;
        })
        : [];

      // Save the generated project to the database
      const savedProject = new GeneratedProject({
        name: project.name,
        materials: formattedMaterials,
        mainmaterials: project.mainmaterials,
        image: project.image,
        level: project.level,
        instructions: formattedInstructions,
        user: req.user,
        shared: false,
      });

      const saved = await savedProject.save();
      const json = JSON.stringify(saved.toObject());
      res.write(json + '\n');
      res.flush?.();
    }

    res.end();

  } catch (err) {
    console.error("❌ Project generation failed:", err.message);
    res.write(`event: error\ndata: ${JSON.stringify({ error: err.message })}\n\n`);
    res.end();
  }
}

async function shareProject(req, res) {
  if (!req.user) return res.status(401).send('Unauthorized');

  try {
    const project = await GeneratedProject.findOne({ _id: req.params.projectId, user: req.user._id });
    if (!project) return res.status(404).send('Project not found');
    if (project.shared) return res.status(400).send('Project already shared');

    // Update project as shared
    project.shared = true;
    await project.save();

    // Add 2 points to user
    await User.findByIdAndUpdate(req.user._id, { $inc: { points: 2 } });

    res.status(200).json({ success: true, message: 'Project shared successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
}

async function shareHandmade(req, res) {
  if (!req.user) return res.status(401).send('Unauthorized');

  try {
    const project = await GeneratedProject.findOne({ _id: req.params.projectId, user: req.user._id });
    if (!project) return res.status(404).send('Project not found');

    // Ensure an image was uploaded
    if (!req.file) return res.status(400).json({ error: 'No image uploaded.' });

    // Add the uploaded image to the project's uploads array
    const imagePath = `/uploads/handmade/${req.file.filename}`;
    project.uploads.push({
      imagePath: imagePath,
      accepted_by_admin: false
    });

    await project.save();

    res.status(200).json({ success: true, message: 'Handmade image uploaded successfully!', imagePath });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
}

// Export the functions
module.exports = {
  classify,
  generate,
  shareProject,
  shareHandmade
};
