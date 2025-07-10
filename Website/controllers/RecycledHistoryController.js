const GeneratedProject = require('../models/Project');
const User = require('../models/User');

async function getProjects(req, res) {
  if (!req.user) return res.redirect('/auth/login');

  try {
    const projects = await GeneratedProject.find({ user: req.user._id });
    res.render('profile/recycled_history', {
      user: req.user,
      projects
    });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
}


async function shareProject(req, res){
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


async function shareHandmade (req, res) {
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

module.exports={
    getProjects,
    shareProject,
    shareHandmade
}