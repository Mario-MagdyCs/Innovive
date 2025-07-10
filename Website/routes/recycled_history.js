// routes/recycled_history.js
const express = require('express');
const router = express.Router();
const GeneratedProject = require('../models/Project');
const User = require('../models/User');
const multer = require('../controllers/multerConfig'); 
const historyController=require("../controllers/RecycledHistoryController")

// GET Route - Display Projects
router.get('/', historyController.getProjects);

// POST Route - Share Project
router.post('/share/:projectId', historyController.shareProject);

// POST Route - Upload Handmade Image
router.post('/handmade/:projectId', multer.single('handmadeImage'), historyController.shareHandmade);

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
