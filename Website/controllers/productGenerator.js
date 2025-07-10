const axios = require("axios");
const categoryMap = require('../utils/categoryMap');
const getRandomPromptForCategory = require('../utils/getRandomPrompt');

class ProductGenerator {
    constructor(materials, category) {
        this.materials = materials;
        this.prompt = null;
        this.image = null;
        this.name = null;
        this.measurements = null;
        this.additionalMaterials = null;
        this.category = category;
    }

    async generatePrompt() {
        const internalCategories = categoryMap[this.category];
    
        if (!internalCategories || internalCategories.length === 0) {
            throw new Error('Invalid category mapping.');
        }
    
        const selectedGenCategory = internalCategories[Math.floor(Math.random() * internalCategories.length)];
        this.name = selectedGenCategory;
    
        const description = getRandomPromptForCategory(selectedGenCategory);
        if (!description) {
            throw new Error('No prompt found for this category.');
        }
    
        const materialList = Array.isArray(this.materials) ? this.materials.join(', ') : this.materials;
        this.prompt = `Using materials: ${materialList}. ${description}`;
    }
    

    async generateImage() {
        try {
            const response = await axios.post('http://127.0.0.1:5008/generate-industrial-image',
                { prompt: this.prompt },
                { responseType: "arraybuffer" }
            );

            const base64 = Buffer.from(response.data, 'binary').toString('base64');
            this.image = `data:image/png;base64,${base64}`;

        } catch (error) {
            console.error('Generation failed:', error.message);
            throw new Error('Image generation failed.');
        }
    }

    async generateDescription() {
        try {
            const res = await axios.post("http://127.0.0.1:5007/analyze-product", {
                image: this.image
            });

            this.measurements = typeof res.data.parts === 'object' && !Array.isArray(res.data.parts)? res.data.parts: {};
            this.additionalMaterials = res.data.additional_materials;
        } catch (err) {
            console.error("Product GPT analysis failed:", err.message);
            this.measurements = ["Unavailable"];
            this.additionalMaterials = ["Unavailable"];
        }
    }

    async build() {
        await this.generatePrompt();
        await this.generateImage();
        await this.generateDescription();

        return {
            name: this.name,
            category: this.category,
            materials: this.materials,
            prompt: this.prompt,
            image: this.image,
            measurements: this.measurements,
            additionalMaterials: this.additionalMaterials
        };
    }
}

module.exports = ProductGenerator;