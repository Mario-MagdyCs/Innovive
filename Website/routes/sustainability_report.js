const express = require('express');
const router = express.Router();
const GeneratedProject = require('../models/Project');

router.get('/', async (req, res) => {
  if (!req.user) return res.redirect('/auth/login');

  try {
    const projects = await GeneratedProject.find({ user: req.user._id });

    const totalProjects = projects.length;
    const co2Saved = totalProjects * 0.5;
    const waterSaved = totalProjects * 1.5;

    const dates = projects.map(p => p.createdAt.toISOString().split('T')[0]).sort();
    const uniqueDates = [...new Set(dates)];
    let streak = 0;
    for (let i = uniqueDates.length - 1; i >= 0; i--) {
      const currentDate = new Date(uniqueDates[i]);
      const expectedDate = new Date();
      expectedDate.setDate(expectedDate.getDate() - (uniqueDates.length - 1 - i));
      if (currentDate.toDateString() === expectedDate.toDateString()) {
        streak++;
      } else break;
    }

    const materialCount = {};
    projects.forEach(p => {
      p.mainmaterials.forEach(m => {
        materialCount[m] = (materialCount[m] || 0) + 1;
      });
    });

    const sortedMaterials = Object.entries(materialCount).sort((a, b) => b[1] - a[1]);
    const topMaterials = sortedMaterials.slice(0, 3).map(([material, count]) => ({
      material,
      percentage: ((count / totalProjects) * 100).toFixed(1)
    }));

    const monthlyCounts = {};

projects.forEach(p => {
  const date = new Date(p.createdAt);
  const month = date.toLocaleString('default', { month: 'short' }); // "Jan", "Feb", etc.
  monthlyCounts[month] = (monthlyCounts[month] || 0) + 1;
});

// Sort months in order (optional step for proper display)
const monthOrder = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const sortedData = monthOrder
  .filter(m => monthlyCounts[m])
  .map(m => ({ label: m, count: monthlyCounts[m] }));

const chartLabels = sortedData.map(d => d.label);
const chartData = sortedData.map(d => d.count);


res.render('profile/sustainability_report', {
    user: req.user,
    totalProjects,
    co2Saved,
    waterSaved,
    streak,
    topMaterials,
    chartLabels,
    chartData
  });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

module.exports = router;
