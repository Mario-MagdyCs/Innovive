// routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const GeneratedProject = require('../models/Project');
const User = require('../models/User');

// Helper function to get the start of the week (Sunday)
function getStartOfWeek(date) {
  const sunday = new Date(date);
  sunday.setDate(sunday.getDate() - sunday.getDay());
  sunday.setHours(0, 0, 0, 0);
  return sunday;
}

// Helper function to get top materials with percentage
async function getTopMaterials(limit = 4) {
  const materialStats = await GeneratedProject.aggregate([
    { $unwind: "$mainmaterials" },
    { $group: { _id: "$mainmaterials", count: { $sum: 1 } } },
    { $sort: { count: -1 } }
  ]);

  const totalMaterialCount = materialStats.reduce((sum, item) => sum + item.count, 0);

  // Top X materials
  const topMaterials = materialStats.slice(0, limit).map((item, index) => {
    return {
      rank: index + 1,
      name: item._id,
      count: item.count,
      percentage: totalMaterialCount ? ((item.count / totalMaterialCount) * 100).toFixed(1) : 0
    };
  });

  // Calculating "Others" row
  
  // ✅ Sorting again to ensure "Others" is placed correctly
  topMaterials.sort((a, b) => b.count - a.count);

  // Re-calculating the ranks
  topMaterials.forEach((item, index) => {
    item.rank = index + 1;
  });

  return topMaterials;
}

router.get('/', async (req, res) => {
  try {
    // Calculating dashboard metrics
    const sharedPostsCount = await GeneratedProject.countDocuments({ shared: true });
    const totalProjectsCount = await GeneratedProject.countDocuments();
    const activeUsersCount = await User.countDocuments();
    
    const totalPointsData = await User.aggregate([{ $group: { _id: null, totalPoints: { $sum: "$points" } } }]);
    const totalPoints = totalPointsData.length > 0 ? totalPointsData[0].totalPoints : 0;

    const totalLikes = await GeneratedProject.aggregate([{ $unwind: "$likes" }, { $count: "totalLikes" }]);
    const totalDislikes = await GeneratedProject.aggregate([{ $unwind: "$dislikes" }, { $count: "totalDislikes" }]);

    // Calculating Weekly Projects Completed
    const now = new Date();
    const startOfWeek = getStartOfWeek(now);
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7);

    const projectsThisWeek = await GeneratedProject.aggregate([
      {
        $match: {
          createdAt: {
            $gte: startOfWeek,
            $lt: endOfWeek
          }
        }
      },
      {
        $group: {
          _id: { $dayOfWeek: "$createdAt" },
          count: { $sum: 1 }
        }
      }
    ]);

    const weeklyProjectsData = [0, 0, 0, 0, 0, 0, 0];
    projectsThisWeek.forEach(item => {
      weeklyProjectsData[item._id - 1] = item.count;
    });

    // ✅ Calculating Top X Recycled Materials + Sorted Others
    const topMaterials = await getTopMaterials(4); // Change this number to any limit you want

    res.render('admin', {
      sharedPostsCount,
      totalProjectsCount,
      activeUsersCount,
      totalPoints,
      totalLikes: totalLikes.length > 0 ? totalLikes[0].totalLikes : 0,
      totalDislikes: totalDislikes.length > 0 ? totalDislikes[0].totalDislikes : 0,
      weeklyProjectsData,
      topMaterials
    });
  } catch (err) {
    console.error("Error loading dashboard:", err);
    res.status(500).send("Server Error");
  }
});

module.exports = router;
