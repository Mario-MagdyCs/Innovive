const express = require('express');
const router = express.Router();
const multer = require('multer');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const User = require('../models/User'); // Path to your Mongoose User model


// Render the upload page
// routes/profile.js or wherever you define your route
router.get('/', (req, res) => {
  if (!req.user) {
    return res.redirect('/auth/login'); // or handle unauthenticated access
  }
  res.render('profile/profile_info', {
    user: req.user,
    currentUser: req.user
  });
});



router.post('/', async (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  
  console.log('User ID:', req.user._id);


  const { fullName, email, age, gender } = req.body;

  try {
    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { fullName, email, age, gender },
      { new: true } // return the updated document
    );

    console.log('Updated user:', updatedUser); // <— Confirm it’s updated
    res.json({ success: true, message: 'Profile updated successfully' });
  } catch (err) {
    console.error('Error updating user:', err);
    res.status(500).json({ success: false, message: 'Update failed' });
  }
});


module.exports=router;