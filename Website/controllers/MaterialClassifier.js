const axios = require("axios");
const FormData = require("form-data");
const fs = require("fs");

class MaterialClassifier {
  constructor(files, base64 = null) {
    this.files = files;      // Array of multer-uploaded files
    this.base64 = base64;    // Base64 image string (chatbot)
    this.results = [];
  }

  async classify() {
    try {
      // ✅ Chatbot-based base64 classification
      if (this.base64) {
        const response = await axios.post("http://127.0.0.1:5000/classify-base64", {
          image: this.base64
        });
        this.results = response.data.results;
        return;
      }
    } catch (err) {
      console.error("Classification for chatbot failed:", err.message);
      throw err;
    }

    // ✅ Standard multer-based upload classification

    const formData = new FormData();
    this.files.forEach(file => {
      formData.append("images", fs.createReadStream(file.path));
    });

    try {
      const response = await axios.post("http://127.0.0.1:5000/classify", formData, {
        headers: formData.getHeaders()
      });

      this.results = response.data.results;

      // Clean up local files
      // this.files.forEach(file => {
      //   try {
      //     fs.unlinkSync(file.path);
      //   } catch (err) {
      //     console.warn(`Could not delete ${file.path}: ${err.message}`);
      //   }
      // });

    } catch (err) {
      console.error("Classification failed:", err.message);
      throw err;
    }
  }

  getResults() {
    return this.results;
  }
}

module.exports = MaterialClassifier;
