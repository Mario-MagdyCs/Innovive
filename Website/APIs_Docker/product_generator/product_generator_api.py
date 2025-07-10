import os
import uuid
import gc
import torch
from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
from diffusers import StableDiffusionPipeline
# Setup
app = Flask(__name__)
CORS(app)

device = "cuda" if torch.cuda.is_available() else "cpu"

# Output directory
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'public', 'generated_images', 'products'))
os.makedirs(base_dir, exist_ok=True)

# Load the model and LoRA weights
def load_model():
    try:
        pipe = StableDiffusionPipeline.from_pretrained(
            "stabilityai/stable-diffusion-2-1",
            torch_dtype=torch.float16 if device == "cuda" else torch.float32
        ).to(device)

        lora_weights = torch.load(
            os.path.join(os.path.dirname(__file__), "../models_paths/lora_industrial_weightsV2.1.pth"),
            map_location=device
        )
        pipe.unet.load_state_dict(lora_weights, strict=False)
        return pipe

    except Exception as e:
        print("❌ Failed to load model or weights:", e)
        raise RuntimeError("Model loading failed: " + str(e))

pipeline = load_model()

def clear_gpu_memory():
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect()

@app.route("/generate-industrial-image", methods=["POST"])
def generate():
    prompt = request.json.get("prompt", "").strip()

    if not prompt:
        return jsonify({"error": "Prompt required"}), 400

    print(f"\n Prompt: {prompt}\n  Generating...")

    try:
        with torch.autocast(device_type=device):
            image = pipeline(prompt).images[0]

        image_name = f"image_{uuid.uuid4().hex[:6]}.png"
        image_path = os.path.join(base_dir, image_name)
        image.save(image_path)

        print(f"✅ Image saved: {image_path}")
        del image
        clear_gpu_memory()

        return send_file(image_path, mimetype="image/png")

    except Exception as e:
        print("❌ Generation error:", e)
        clear_gpu_memory()
        return jsonify({"error": "Image generation failed", "details": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5004)
