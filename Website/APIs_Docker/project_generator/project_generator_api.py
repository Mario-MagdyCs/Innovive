import os
import uuid
import gc
import torch
from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
from diffusers import StableDiffusionPipeline

# Init Flask
app = Flask(__name__)
CORS(app)

device = "cuda" if torch.cuda.is_available() else "cpu"

# Output directory
image_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'public', 'generated_images', 'projects'))
os.makedirs(image_dir, exist_ok=True)

# Load model and LoRA weights
def load_pipeline():
    try:
        pipeline = StableDiffusionPipeline.from_pretrained(
            "stabilityai/stable-diffusion-2-1",
            torch_dtype=torch.float16 if device == "cuda" else torch.float32
        ).to(device)

        weights_path = os.path.join(os.path.dirname(__file__), "../models_paths/full_lora_diy_weightsV2.1.pth")
        lora_weights = torch.load(weights_path, map_location=device)
        pipeline.unet.load_state_dict(lora_weights, strict=False)

        return pipeline
    except Exception as e:
        print("❌ Failed to load pipeline or weights:", e)
        raise RuntimeError("Model load error: " + str(e))

pipeline = load_pipeline()

def clear_gpu_memory():
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect()

@app.route("/generate-image", methods=["POST"])
def generate():
    prompt = request.json.get("prompt", "").strip()

    if not prompt:
        return jsonify({"error": "Prompt required"}), 400

    print(f"🧠 Prompt: {prompt}\n🎨 Generating image...")

    try:
        with torch.autocast(device_type=device):
            image = pipeline(prompt).images[0]

        image_name = f"image_{uuid.uuid4().hex[:6]}.png"
        image_path = os.path.join(image_dir, image_name)
        image.save(image_path)

        print(f"✅ Saved to {image_path}")
        del image
        clear_gpu_memory()

        return send_file(image_path, mimetype='image/png')

    except Exception as e:
        print("❌ Generation error:", e)
        clear_gpu_memory()
        return jsonify({"error": "Generation failed", "details": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)
