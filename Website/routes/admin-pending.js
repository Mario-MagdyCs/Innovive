// routes/admin-pending.js
const express = require('express');
const router = express.Router();
const GeneratedProject = require('../models/Project');
const User = require('../models/User');

// Route to Render Admin Page
router.get('/', (req, res) => {
  res.render('admin-pending'); // Renders the clean HTML page
});

// Route to Provide JSON Data for Pending Posts
router.get('/data', async (req, res) => {
  try {
    const projects = await GeneratedProject.find({
      "uploads.accepted_by_admin": false,
      "uploads.0": { $exists: true }
    }).populate('user', 'fullName');

    res.json({ projects });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

// POST - Accept Handmade Image
router.post('/handmade/accept/:projectId/:imageIndex', async (req, res) => {
  console.log("Accept route hit:", req.params);

  try {
    const { projectId, imageIndex } = req.params;
    const project = await GeneratedProject.findById(projectId);
    console.log("Fetched Project:", project); // Debug line

    if (!project) {
      console.log("Project not found");
      return res.status(404).send('Project not found');
    }

    console.log("Uploads Array:", project.uploads); // Debug line
    if (!project.uploads || !project.uploads[imageIndex]) {
      console.log("Image not found at index:", imageIndex);
      return res.status(404).send('Image not found');
    }

    const upload = project.uploads[imageIndex];
    console.log("Selected Upload:", upload); // Debug line

    if (upload.accepted_by_admin) {
      return res.status(400).send('Image already accepted');
    }

    // Mark as accepted, set shared to true, and give user 5 points
    upload.accepted_by_admin = true;
    project.shared = true;
    await project.save();
    await User.findByIdAndUpdate(project.user, { $inc: { points: 5 } });

    res.status(200).json({ success: true, message: 'Image accepted. User awarded 5 points!' });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});



// POST - Reject Handmade Image
router.post('/handmade/reject/:projectId/:imageIndex', async (req, res) => {
  try {
    const { projectId, imageIndex } = req.params;
    const project = await GeneratedProject.findById(projectId);
    if (!project) return res.status(404).send('Project not found');
    if (!project.uploads || !project.uploads[imageIndex]) {
      return res.status(404).send('Image not found');
    }

    // Remove the specific image from uploads
    project.uploads.splice(imageIndex, 1);
    await project.save();

    res.status(200).json({ success: true, message: 'Image rejected and removed.' });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

module.exports = router;
