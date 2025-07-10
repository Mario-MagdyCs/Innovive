const axios = require("axios");
const fs = require("fs");

async function generatePromptFlux(materials, base64 = null, form = null) {
  try {
    console.log("entered flux");

    if (form) {
      form.append("materials", materials.join(","));
      const response = await axios.post("http://127.0.0.1:5003/generate-prompt", form, {
        headers: form.getHeaders()
      });

      return response.data.prompt;
    }

    
    // If base64 is provided, send it directly in JSON
    if (base64) {
      console.log("Sending Base64 Image to Prompt Generator");
      const response = await axios.post("http://127.0.0.1:5003/generate-prompt", {
        materials: materials,
        base64_image: base64
      }, {
        headers: {
          "Content-Type": "application/json"
        }
      });

      console.log("Prompt Generated:", response.data.prompt);
      return response.data.prompt;
    }

    
    throw new Error("Flux Generator: No base64 image or form provided.");


  } catch (err) {
    console.error("GPT prompt generation (50) failed:", err.message);
    return `Create a DIY project using ${materials.join(", ")}`;
  }
}

module.exports = generatePromptFlux;


