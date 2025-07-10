const express = require('express');
const router = express.Router();
const multer = require('multer');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const MaterialClassifier = require("../controllers/MaterialClassifier");
const ProjectGenerator = require("../controllers/ProjectGenerator");
const uploadController=require("../controllers/UploadController.js")
const GeneratedProject = require("../models/Project")
const {isLoggedIn}=require("../middleware.js")
const multer2 = require('../controllers/multerConfig'); 


router.get("/", async(req, res) => {
  try {
    let userProjects = [];

    if (req.user) {
      userProjects = await GeneratedProject.find({ user: req.user._id })
        .sort({ createdAt: -1 }) // sort by newest
        .limit(3)                // only get 3
        .lean();                 // improve read performance
    }
    res.render("upload", {
      currentUser: req.user,
      userProjects
    });

  } catch (err) {
    console.error("Error fetching user projects:", err);
    res.status(500).send("Server error");
  }
});

 
const upload = multer({ dest: "uploads/" });
 

router.post("/generate",isLoggedIn,upload.array("images"),uploadController.generate );

// POST Route - Share Project
router.post('/share/:projectId',uploadController.shareProject);

// POST Route - Upload Handmade Image
router.post('/handmade/:projectId', multer2.single('handmadeImage'),uploadController.shareHandmade);

router.delete("/delete/:id", async (req, res) => {
  try {
    const projectId = req.params.id;
    await GeneratedProject.findByIdAndDelete(projectId);
    res.status(200).json({ message: "Project deleted successfully" });
  } catch (error) {
    console.error("Error deleting project:", error);
    res.status(500).json({ message: "Failed to delete project" });
  }
});



module.exports = router;
