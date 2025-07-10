const express = require("express");
const ProductGenerator = require("../controllers/productGenerator");
const GeneratedProduct = require("../models/Product");

const router = express.Router();

router.post("/generate-another", async (req, res) => {
    try {
        const id = req.body.productId;
        const product = await GeneratedProduct.findById(id);
        const materials = product.materials;
        const category = product.category;
        const generator = new ProductGenerator(materials, category);
        let newProduct = await generator.build();

        // Save to MongoDB
        const newproduct = new GeneratedProduct({
            name: newProduct.name,
            category: newProduct.category,
            materials: newProduct.materials,
            image: newProduct.image,
            measurements: newProduct.measurements,
            additionalMaterials: newProduct.additionalMaterials
        });

        const saved = await newproduct.save();

        // Redirect to view by ID
        res.redirect(`/generated-products/${saved._id}`);
    } catch (err) {
        console.error("Generation failed:", err);
        res.status(500).json({ error: "product generation failed" });
    }
});


router.get("/:id", async (req, res) => {
    try {
        const product = await GeneratedProduct.findById(req.params.id).lean();

        if (!product) {
            return res.status(404).send("product not found.");
        }

        if (product.measurements instanceof Map) {
            product.measurements = Object.fromEntries(product.measurements);
        }

         let relatedProjects = await GeneratedProduct.find({
            category: { $in: product.category },
            _id: { $ne: product._id }
        }).limit(4);

            // If not enough related projects, fetch random projects as fallback
        if (relatedProjects.length < 4) {
            const fallbackProjects = await GeneratedProduct.find({
                _id: { $ne: product._id }
            }).limit(4 - relatedProjects.length);

            relatedProjects = relatedProjects.concat(fallbackProjects);
        }

        res.render("generated-product", {
            projectId: req.params.id,
            name: product.name,
            category: product.category,
            materials: product.materials,
            image: product.image,
            measurements: product.measurements,
            additionalMaterials: product.additionalMaterials,
            currentUser: req.user,
            relatedProjects 
        });
    } catch (err) {
        console.error(err);
        res.status(500).send("Server Error");
    }
});



module.exports = router;