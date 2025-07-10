const express = require('express');
const router = express.Router();
const multer = require('multer');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const ProductGenerator = require("../controllers/productGenerator");
const GeneratedProduct = require('../models/Product');
const { isLoggedIn } = require('../middleware');

const upload = multer(); 

// Render the upload page
router.get("/", async(req, res) => {
  let userProjects = [];

  if (req.user) {
    userProjects = await GeneratedProduct.find({ user: req.user._id })
      .sort({ createdAt: -1 }) // sort by newest
      .limit(3)                // only get 3
      .lean();                 // improve read performance
  }

  res.render("select-materials",
    {currentUser: req.user,
    userProjects});
});


router.post("/generate", isLoggedIn,upload.none(), async (req, res) => {
  res.setHeader('Content-Type', 'application/x-ndjson');
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  try {
    console.log(req.body)
    const materials=req.body.materials;
    const category=req.body.category;
    const numberOfImages=req.body.numberOfImages;

    console.log(materials);
    console.log(numberOfImages);
    console.log(category);

    for (let i = 0; i < numberOfImages; i++) {
      const generator = new ProductGenerator(materials, category);
      const product = await generator.build();


      // Save the generated project to the database
      const newProduct = new GeneratedProduct({
        name: product.name,
        category: product.category,
        materials: product.materials,
        image: product.image,
        measurements: product.measurements,
        additionalMaterials: product.additionalMaterials,
        user:req.user
      });

      
      const saved = await newProduct.save();
      const json = JSON.stringify(saved.toObject());
      res.write(json + '\n');
      res.flush?.();

    }
    res.end();
    // // Redirect to view by ID
    // res.redirect(`/generated-products/${saved._id}`);
  } catch (err) {
    console.error("❌ Product generation failed:", err.message);
    res.write(`event: error\ndata: ${JSON.stringify({ error: err.message })}\n\n`);
    res.end();
  }
});



module.exports = router;