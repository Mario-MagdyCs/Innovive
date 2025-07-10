const axios = require("axios");
const FormData = require("form-data");
const fs = require("fs");
const getPromptGenerator = require("../utils/getPromptGenerator");

class ProjectGenerator {
  constructor(materials, base64 = null) {
    this.base64 = base64;
    this.mainmaterials = materials;
    this.materials = [];
    this.prompt = null;
    this.promptOverride = null;
    this.image = null;
    this.name = null;
    this.level = null;
    this.instructions = [];
  }

  async generatePrompt(similarity, files) {

    if (this.promptOverride) {
      this.prompt = this.promptOverride;
      return;
    }


    var promptGenerator = await getPromptGenerator(similarity);
    if (similarity === '50' || similarity === 50) {
      const formData = new FormData();
      // if (this.base64) {
      //   console.log("Sending Base64 Image for Prompt");
      //   this.prompt = await promptGenerator(this.mainmaterials, `data:image/png;base64,${this.base64}`);
      // }
      // else {
      //   files.forEach(file => {
      //     formData.append("images", fs.createReadStream(file.path));
      //   });
      //   this.prompt = await promptGenerator(this.mainmaterials, formData);
      // }

      if (files) {
        files.forEach(file => {
          formData.append("images", fs.createReadStream(file.path));
        });
        this.prompt = await promptGenerator(this.mainmaterials, null, formData);
      }
      else {
        console.log("Sending Base64 Image for Prompt");
        this.prompt = await promptGenerator(this.mainmaterials, `data:image/png;base64,${this.base64}`);
      }


    }
    else {
      this.prompt = await promptGenerator(this.mainmaterials);
    }


  }


  async generateImage(similarity, files) {
    //Handling image generation from chatbot
    if (this.base64 && (similarity === '75' || similarity === 75)) {
      try {
        const response = await axios.post("http://127.0.0.1:5006/generate-replicate-base64", {
          image: this.base64,
          prompt: this.prompt
        }, {
          responseType: "arraybuffer"
        });

        const base64 = Buffer.from(response.data, 'binary').toString('base64');
        this.image = `data:image/png;base64,${base64}`;
        return;
      } catch (err) {
        console.error("Image generation for chatbot failed:", err.message);
        throw err;
      }
    }

    //Handling image generation from upload page
    let url;

    // Choose API endpoint based on similarity level
    if (similarity === '25' || similarity === 25) { //sd based
      url = "http://127.0.0.1:5002/generate-image";
    } else if (similarity === '50' || similarity === 50) {
      url = "http://127.0.0.1:5005/generate-replicate"; //text-to-image
    } else if (similarity === '75' || similarity === 75) {
      url = "http://127.0.0.1:5006/generate-replicate"; //preserving
    } else {
      throw new Error("Invalid similarity value: must be 25, 50, or 75");
    }

    var response;
    if (similarity === '75' || similarity === 75) {
      const formData = new FormData();
      files.forEach(file => {
        formData.append("images", fs.createReadStream(file.path));
      });
      formData.append("prompt", this.prompt);
      try {
        response = await axios.post(url, formData, {
          headers: formData.getHeaders(),
          responseType: "arraybuffer"
        });


      } catch (err) {
        console.error("Image generation from upload failed:", err.message);
        throw err;
      }

    } else {
      response = await axios.post(url, {
        prompt: this.prompt
      }, { responseType: "arraybuffer" });
    }

    const base64 = Buffer.from(response.data, 'binary').toString('base64');
    this.image = `data:image/png;base64,${base64}`;
  }


  async generateInstructions() {
    try {
      const textRes = await axios.post("http://127.0.0.1:5003/generate-instructions", {
        image: this.image
      });

      this.name = textRes.data.name || "";
      this.level = textRes.data.level || "";
      this.instructions = textRes.data.instructions || [];
      this.materials = textRes.data.materials || [];
    } catch (error) {
      console.error("Text generation failed:", error.message);
    }
  }

  async build(similarity = 50, files = null) {
    await this.generatePrompt(similarity, files);
    await this.generateImage(similarity, files);
    await this.generateInstructions();

    return {
      name: this.name,
      image: this.image,
      level: this.level,
      materials: this.materials,
      mainmaterials: this.mainmaterials,
      instructions: this.instructions,
    };
  }
}

module.exports = ProjectGenerator;
