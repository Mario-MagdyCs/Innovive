// routes/admin-users.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');


// Route to Render Users Management EJS Page
router.get('/', (req, res) => {
    res.render('adminUser'); // Make sure the EJS file is named adminUser.ejs
  });
// Route to Fetch All Users (GET /admin-users/data)
router.get('/data', async (req, res) => {
  try {
    const users = await User.find({}, 'fullName email age gender points').exec();
    res.json(users);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server Error' });
  }
});



router.delete('/delete/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const deletedUser = await User.findByIdAndDelete(userId);
  
      if (!deletedUser) {
        return res.status(404).json({ error: 'User not found' });
      }
  
      res.status(200).json({ success: true, message: 'User deleted successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server Error' });
    }
  });


  // Edit User (PUT /adminUser/edit/:userId)
router.put('/edit/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const { fullName, age, gender, points } = req.body;
  
      const updatedUser = await User.findByIdAndUpdate(userId, {
        fullName,
        age: age || null,
        gender,
        points: points || 0
      }, { new: true });
  
      if (!updatedUser) {
        return res.status(404).json({ error: 'User not found' });
      }
  
      res.status(200).json({ success: true, message: 'User updated successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server Error' });
    }
  });
module.exports = router;
