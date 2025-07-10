// routes/profile.js
const express = require('express');
const router = express.Router();
const GeneratedProject = require('../models/Project');
const User = require('../models/User');

// GET Route - Display Favorite Projects
router.get('/', async (req, res) => {
  if (!req.user) return res.redirect('/auth/login');

  try {
    // Populate the favorites field with full project details
    const user = await User.findById(req.user._id).populate('favorites').exec();

    res.render('profile/favourite', {
      user: req.user,
      projects: user.favorites // Send favorite projects to the page
    });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

module.exports = router;
