const express = require('express');
const router = express.Router();
const GeneratedProject = require('../models/Project');
const badgeRules = require('../models/badgeRules'); // adjust the path if needed

router.get('/', async (req, res) => {
  if (!req.user) return res.redirect('/auth/login');

  try {
    const userId = req.user._id;
    const projects = await GeneratedProject.find({ user: userId });

    // Calculate shared material counts
    const materialCounts = {};
    projects.forEach(project => {
      if (project.shared) {
        project.mainmaterials.forEach(material => {
          materialCounts[material] = (materialCounts[material] || 0) + 1;
        });
      }
    });

    const user = req.user.toObject();
    user.materialCounts = materialCounts;

    const earnedBadgeIds = user.badges.map(b => b.badgeId);
    const badgeResults = badgeRules.map(rule => {
      const { earned, progress } = rule.criteria(user);
      return {
        ...rule,
        earned,
        progress
      };
    });

    const earnedBadges = badgeResults.filter(b => b.earned);
    const lockedBadges = badgeResults.filter(b => !b.earned);

    res.render('profile/achievements', {
      user,
      earnedBadges,
      lockedBadges,
      points: user.points
    });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

module.exports = router;
