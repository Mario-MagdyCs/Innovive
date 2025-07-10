// Express Route Optimization
const express = require('express');
const router = express.Router();
const GeneratedProject = require('../models/Project');
const User = require('../models/User');
const axios = require('axios');
const UserPreferredMaterials = require('../models/EnthRegistration/UserPreferredMaterials');
require('dotenv').config();

// =============================================
// RECOMMENDATION LOGIC (WITH DEBUG LOGGING)
// =============================================
const materialNameMapping = {
  'Plastic Bottles': 'plastic_bottle',
  'Glass Bottles': 'glass_bottle',
  'Cardboard': 'cardboard',
  'Paper': 'paper',
  'Metal Cans': 'aluminum_soda_can',
  'Glass Jars': 'glass_jar'
};

function shuffleArray(array, seed) {
  console.log(`[Shuffle] Starting shuffle with seed: ${seed}`);
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = (seed % (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    seed = Math.floor(seed / (i + 1));
  }
  console.log(`[Shuffle] Input: ${array.join(', ')}, Output: ${shuffled.join(', ')}`);
  return shuffled;
}

async function getDailyRecommendations(userId, limit = 3) {
  console.log(`[Recommendation] Starting for user: ${userId}`);
  
  try {
    // 1. Date and Seed Setup
    const today = new Date();
    const dateSeed = Number(today.toISOString().split('T')[0].replace(/-/g, ''));
    console.log(`[Recommendation] Date: ${today.toISOString()}, Seed: ${dateSeed}`);

    // 2. Get User Preferences
    console.log(`[Recommendation] Fetching preferences for user: ${userId}`);
    const userPrefs = await UserPreferredMaterials.findOne({ userId });
    console.log(`[Recommendation] Raw preferences:`, userPrefs?.materials);

    const materials = userPrefs?.materials?.length 
      ? userPrefs.materials 
      : ['Plastic Bottles', 'Glass Bottles', 'Paper'];
    console.log(`[Recommendation] Using materials:`, materials);

    // 3. Normalize Material Names
    const normalizedMaterials = materials.map(material => {
      const normalized = materialNameMapping[material] || material.toLowerCase().replace(/\s+/g, '_');
      console.log(`[Normalize] ${material} → ${normalized}`);
      return normalized;
    });

    // 4. Get Unique Materials and Shuffle
    const uniqueMaterials = [...new Set(normalizedMaterials)];
    console.log(`[Recommendation] Unique materials:`, uniqueMaterials);
    
    const shuffledMaterials = shuffleArray(uniqueMaterials, dateSeed);
    console.log(`[Recommendation] Shuffled materials:`, shuffledMaterials);

    // 5. Find Matching Projects
    const recommendations = [];
    const materialsToQuery = shuffledMaterials.slice(0, limit);
    console.log(`[Recommendation] Querying for materials:`, materialsToQuery);

    for (const material of materialsToQuery) {
      console.log(`[Recommendation] Searching for material: ${material}`);
      const project = await GeneratedProject.aggregate([
        { $match: { mainmaterials: material } },
        { $sample: { size: 1 } },
        { $project: { name: 1, image: 1, mainmaterials: 1, createdAt: 1 } }
      ]);
      
      if (project.length) {
        console.log(`[Recommendation] Found project:`, {
          name: project[0].name,
          materials: project[0].mainmaterials
        });
        recommendations.push(project[0]);
      } else {
        console.log(`[Recommendation] No projects found for material: ${material}`);
      }
    }

    // 6. Fallback to Popular Projects if Needed
    if (recommendations.length < limit) {
      const needed = limit - recommendations.length;
      console.log(`[Recommendation] Only found ${recommendations.length} projects. Getting ${needed} popular fallbacks`);
      
      const fallback = await GeneratedProject.aggregate([
        { $match: {} },
        { $sort: { likesCount: -1 } },
        { $limit: needed },
        { $project: { name: 1, image: 1, mainmaterials: 1, createdAt: 1 } }
      ]);
      
      console.log(`[Recommendation] Found ${fallback.length} fallback projects`);
      recommendations.push(...fallback);
    }

    // 7. Final Check
    if (recommendations.length === 0) {
      console.warn(`[Recommendation] WARNING: No recommendations found after all fallbacks`);
    } else {
      console.log(`[Recommendation] Final recommendations:`, recommendations.map(p => p.name));
    }

    return recommendations;

  } catch (error) {
    console.error('[Recommendation] ERROR:', error);
    console.log('[Recommendation] Attempting ultimate fallback to random projects');
    
    const fallback = await GeneratedProject.aggregate([
      { $match: {} },
      { $sample: { size: limit } },
      { $project: { name: 1, image: 1, mainmaterials: 1, createdAt: 1 } }
    ]);
    
    console.log(`[Recommendation] Ultimate fallback returned ${fallback.length} projects`);
    return fallback;
  }
}
// Optimized sorting function with aggregation
function getSortOption(sortOption) {
  if (sortOption === "most-liked") {
    return [
      { 
        $addFields: { 
          likesCount: { $size: { $ifNull: ["$likes", []] } },
          dislikesCount: { $size: { $ifNull: ["$dislikes", []] } }
        } 
      },
      { 
        $sort: { likesCount: -1, createdAt: -1 } 
      }
    ];
  }
  if (sortOption === "oldest") return [{ $sort: { createdAt: 1 } }];
  return [{ $sort: { createdAt: -1 } }];
}

// Projects main page (optimized version)
router.get('/', async (req, res) => {
  if (!req.user) return res.redirect('/auth/login');

  const page = parseInt(req.query.page) || 1;
  const limit = 6;
  const skip = (page - 1) * limit;
  const sortOption = req.query.sort || 'newest';

  try {
    const [recommendedProjects, totalPosts] = await Promise.all([
      getDailyRecommendations(req.user._id, 3),
      GeneratedProject.countDocuments({ shared: true })
    ]);

    const sortPipeline = getSortOption(sortOption);

    const posts = await GeneratedProject.aggregate([
      { $match: { shared: true } },
      ...sortPipeline,
      { $skip: skip },
      { $limit: limit },
      {
        $project: {
          name: 1,
          image: 1,
          mainmaterials: 1,
          createdAt: 1,
          likesCount: { $size: { $ifNull: ["$likes", []] } },
          dislikesCount: { $size: { $ifNull: ["$dislikes", []] } },
          isFavorite: {
            $in: [req.user._id, { $ifNull: ["$favorites", []] }]
          },
          isLiked: {
            $in: [req.user._id, { $ifNull: ["$likes", []] }]
          },
          isDisliked: {
            $in: [req.user._id, { $ifNull: ["$dislikes", []] }]
          }
        }
      }
    ]);

    const totalPages = Math.ceil(totalPosts / limit);

    res.render('projects', {
      posts,
      recommendedProjects,
      currentPage: page,
      totalPages,
      currentUser: req.user,
      currentSort: sortOption,
      layout: req.xhr ? false : undefined
    });
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
});

// Projects main page (optimized version)
//  router.get('/', async (req, res) => {
//   if (!req.user) return res.redirect('/auth/login');

//   const page = parseInt(req.query.page) || 1;
//   const limit = 6;
//   const skip = (page - 1) * limit;
//   const sortOption = req.query.sort || 'newest';

//   try {
//       const [recommendedProjects, posts, totalPosts] = await Promise.all([
//         getDailyRecommendations(req.user._id, 3),
//         GeneratedProject.find({ shared: true })
//           .populate('likes')
//           .populate('dislikes')
//           .select('name image mainmaterials createdAt')
//           .sort(getSortOption(sortOption))
//           .skip(skip)
//           .limit(limit)
//           .lean(),
//         GeneratedProject.countDocuments({ shared: true })
//       ]);

//     const totalPages = Math.ceil(totalPosts / limit);

//     res.render('projects', {
//       posts,
//       recommendedProjects,
//       currentPage: page,
//       totalPages,
//       currentUser: req.user,
//       currentSort: sortOption,
//       layout: req.xhr ? false : undefined
//     });
//   } catch (err) {
//     console.error(err);
//     res.status(500).send("Server Error");
//   }
// });

// // Optimized sorting function
// function getSortOption(sortOption) {
//   if (sortOption === "most-liked") return { likesCount: -1, createdAt: -1 };
//   if (sortOption === "oldest") return { createdAt: 1 };
//   return { createdAt: -1 };
// }


 // Optimized search route
router.get('/search', async (req, res) => {
  const queryText = req.query.query?.trim();
  const page = parseInt(req.query.page) || 1;
  const limit = 6;
  const skip = (page - 1) * limit;

  if (!queryText) {
    return res.status(400).send("Search query is required.");
  }

  try {
    const regex = new RegExp(queryText, 'i');
    const searchQuery = { 
      shared: true, 
      $or: [ 
        { name: regex }, 
        { level: regex }, 
        { generatedBy: regex }, 
        { mainmaterials: regex } 
      ] 
    };

    // First get the recommendations from the main route
    const recommendedProjects = await getDailyRecommendations(req.user._id, 3);
    
    // Then get the search results
    const [totalPosts, posts] = await Promise.all([
      GeneratedProject.countDocuments(searchQuery),
      GeneratedProject.find(searchQuery)
        .select('name image mainmaterials likes dislikes createdAt generatedBy')
        .lean()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
    ]);

    const enhancedPosts = posts.map(post => ({
      ...post,
      isFavorite: req.user?.favorites?.includes(post._id.toString()),
      isLiked: req.user?.likes?.includes(post._id.toString()),
      isDisliked: req.user?.dislikes?.includes(post._id.toString()),
      likesCount: post.likes ? post.likes.length : 0,
      dislikesCount: post.dislikes ? post.dislikes.length : 0
    }));

    res.render('projects', {
      posts: enhancedPosts,
      recommendedProjects, // Same recommendations as main route
      currentPage: page,
      totalPages: Math.ceil(totalPosts / limit),
      currentUser: req.user,
      currentSort: 'newest',
      layout: req.xhr ? false : undefined
    });
  } catch (err) {
    console.error(err);
    res.status(500).send("Search failed.");
  }
});

// Optimized filter route
// Optimized filter route
router.get('/filter', async (req, res) => {
  const tag = req.query.tag;
  const page = parseInt(req.query.page) || 1;
  const limit = 6;
  const skip = (page - 1) * limit;

  if (!tag) {
    return res.status(400).send("Tag is required.");
  }

  try {
    const query = { mainmaterials: tag, shared: true };

    const [recommendedProjects, totalPosts, posts] = await Promise.all([
      getDailyRecommendations(req.user._id, 3), // Fetch recommended projects
      GeneratedProject.countDocuments(query),
      GeneratedProject.find(query)
        .select('name image mainmaterials likes dislikes createdAt generatedBy')
        .lean()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
    ]);

    const enhancedPosts = posts.map(post => ({
      ...post,
      isFavorite: req.user?.favorites?.includes(post._id.toString()),
      isLiked: req.user?.likes?.includes(post._id.toString()),
      isDisliked: req.user?.dislikes?.includes(post._id.toString()),
      likesCount: post.likes ? post.likes.length : 0,
      dislikesCount: post.dislikes ? post.dislikes.length : 0
    }));

    res.render('projects', {
      posts: enhancedPosts,
      recommendedProjects, // Always pass recommendedProjects
      currentPage: page,
      totalPages: Math.ceil(totalPosts / limit),
      currentUser: req.user,
      currentSort: 'newest',
      layout: req.xhr ? false : undefined
    });
  } catch (err) {
    console.error(err);
    res.status(500).send("Error loading filtered posts.");
  }
});


// Toggle favorite (optimized)
router.post('/toggle-favorite/:projectId', async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ success: false, error: 'Not authenticated' });
  }

  const { projectId } = req.params;

  try {
    const user = await User.findById(req.user._id);
    const isFavorite = user.favorites.includes(projectId);
    
    if (isFavorite) {
      user.favorites.pull(projectId);
    } else {
      user.favorites.push(projectId);
    }

    await user.save();
    res.json({ 
      success: true, 
      action: isFavorite ? 'removed' : 'added',
      isFavorite: !isFavorite
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

// Toggle like/dislike (optimized)
router.post('/toggle-like-dislike/:projectId', async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ success: false, error: 'Not authenticated' });
  }

  const { projectId } = req.params;
  const { action } = req.body;
  const userId = req.user._id;

  try {
    const [user, project] = await Promise.all([
      User.findById(userId),
      GeneratedProject.findById(projectId)
    ]);

    if (!project || !user) {
      return res.status(404).json({ success: false, error: 'User or project not found' });
    }

    const hasLiked = user.likes.includes(projectId);
    const hasDisliked = user.dislikes.includes(projectId);

    // Optimized update operations
    if (action === 'like') {
      if (!hasLiked) {
        user.likes.addToSet(projectId);
        project.likes.addToSet(userId);
      }
      if (hasDisliked) {
        user.dislikes.pull(projectId);
        project.dislikes.pull(userId);
      }
    } else if (action === 'dislike') {
      if (!hasDisliked) {
        user.dislikes.addToSet(projectId);
        project.dislikes.addToSet(userId);
      }
      if (hasLiked) {
        user.likes.pull(projectId);
        project.likes.pull(userId);
      }
    } else {
      return res.status(400).json({ success: false, error: 'Invalid action' });
    }

    await Promise.all([user.save(), project.save()]);

    return res.json({
      success: true,
      action,
      likesCount: project.likes.length,
      dislikesCount: project.dislikes.length,
      isLiked: action === 'like' && !hasLiked,
      isDisliked: action === 'dislike' && !hasDisliked
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, error: 'Server error' });
  }
});

router.post('/:projectId/ai-assist', async (req, res) => {
  try {
    const { projectId } = req.params;
    const { stepIndex, title, content, imageUrl } = req.body;
    
    // Optional: Validate the input
    if (!projectId || !title || !content || !imageUrl) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Optional: Get additional project context for better AI response
    let projectName = "";
    let projectLevel = "";
    try {
      const project = await GeneratedProject.findById(projectId);
      if (project) {
        projectName = project.name;
        projectLevel = project.level;
      }
    } catch (err) {
      console.log("Could not fetch project details, continuing with basic info");
    }
    
    // Format the prompt for the Vision API
    const prompt = `Analyze this DIY project step and provide clear, concise guidance in exactly 4 lines maximum.
    
    Project: "${projectName || 'DIY Project'}" (${projectLevel || 'Unknown'} difficulty)
    Step: "${title}"
    Instructions: "${content}"
    
    Focus on:
    1. Clarifying any potential confusion
    2. Adding useful tips or shortcuts
    3. Warning about potential mistakes
    4. Ensuring safety where applicable
    
    Keep your response to EXACTLY 4 lines maximum, be direct and practical.`;
    
    // Call the OpenAI Vision API
    const response = await axios.post('https://api.openai.com/v1/chat/completions', {
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            {
              type: "image_url",
              image_url: { url: imageUrl }
            }
          ]
        }
      ],
      max_tokens: 150
    }, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
      }
    });

    // Extract and format the AI's response
    const aiResponse = response.data.choices[0].message.content.trim();
    
    // Return the response
    res.json({ response: aiResponse });
    
  } catch (error) {
    console.error('Error calling OpenAI API:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to process request', details: error.message });
  }
});



// Single project view
router.get('/:id', async (req, res) => {
  try {
    const project = await GeneratedProject.findById(req.params.id)
      .populate('likes')
      .populate('dislikes');

    if (!project) {
      return res.status(404).send("Post not found");
    }

    // Fetch related projects (same main material, exclude current project)
    let relatedProjects = await GeneratedProject.find({
      mainmaterials: { $in: project.mainmaterials },
      _id: { $ne: project._id }
    }).limit(4);

    // If not enough related projects, fetch random projects as fallback
    if (relatedProjects.length < 4) {
      const fallbackProjects = await GeneratedProject.find({
        _id: { $ne: project._id }
      }).limit(4 - relatedProjects.length);

      relatedProjects = relatedProjects.concat(fallbackProjects);
    }

    res.render("generated-project", {
      currentUser: req.user,
      name: project.name,
      image: project.image,
      level: project.level,
      materials: project.materials,
      mainmaterials: project.mainmaterials,
      instructions: project.instructions,
      createdAt: project.createdAt,
      shared: project.shared,
      likes: project.likes,
      dislikes: project.dislikes,
      uploads: project.uploads,
      relatedProjects: relatedProjects // Passing related projects to EJS
    });
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
});

module.exports = router;