const express = require("express");
const ProjectGenerator = require("../controllers/ProjectGenerator");
const GeneratedProject = require("../models/Project");

const router = express.Router();
let lastProject = null; // You can improve this later with session or DB

router.get("/", (req, res) => {
  if (!lastProject) return res.send("No project generated yet.");
  res.render("generated-project", {lastProject, currentUser:req.user});
})

router.post("/generate-another", async (req, res) => {
  try {
    const materials = req.body.materials;
    console.log(materials);
    const generator = new ProjectGenerator(materials);
    const project = await generator.build();

    const newProject = new GeneratedProject({
      name: project.name,
      image: project.image,
      level: project.level,
      materials: project.materials,
      mainmaterials: project.mainmaterials,
      instructions: project.instructions,
      generatedBy: project.generatedBy,
    });

    console.log("PROJECT DETAILS RECEIVED. SAVING TO DATABASE....");

    try{
      const saved = await newProject.save();
      res.redirect(`/generate-project/${saved._id}`);
    }
    catch(err){
      console.log("Error saving in database:",err);
    }

  } catch (err) {
    console.error("Generation failed:", err);
    res.status(500).json({ error: "Project generation failed" });
  }
});

router.get("/:id", async (req, res) => { 
  try {
    const project = await GeneratedProject.findById(req.params.id);

    if (!project) {
      return res.status(404).send("Project not found.");
    }

    res.render("generated-project", {
      currentUser:req.user,
      name: project.name,
      image: project.image,
      level: project.level,
      materials: project.materials,
      mainmaterials:project.mainmaterials,
      instructions: project.instructions,
      createdAt:project.createdAt,
      shared:project.shared,
      likes:project.likes,
      dislikes:project.dislikes,
      uploads: project.uploads,
    });

  } catch (err) {
    console.error("Error fetching project:", err);
    res.status(500).send("Internal Server Error");
  }
});

  

module.exports=router;