import os
from flask import Flask, request, send_file
from flask_cors import CORS  # <-- NEW
from diffusers import StableDiffusionPipeline
import torch, gc
import uuid

base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'public', 'generated_images', 'products'))
os.makedirs(base_dir, exist_ok=True) 

app = Flask(__name__)
CORS(app)
device = "cuda" if torch.cuda.is_available() else "cpu"

# Load model and LoRA weights
pipeline = StableDiffusionPipeline.from_pretrained(
    "stabilityai/stable-diffusion-2-1",
    torch_dtype=torch.float16 if device == "cuda" else torch.float32
).to(device)

lora_weights = torch.load("../models_paths/lora_industrial_weightsV2.1.pth", map_location=device)
pipeline.unet.load_state_dict(lora_weights, strict=False)

def clear_gpu_memory():
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect()

@app.route("/generate-industrial-image", methods=["POST"])
def generate():
    
    prompt = request.json.get("prompt", "")
    
    if not prompt:
        print("No prompt received.")
        return {"error": "Prompt required"}, 400

    print(f"\nReceived prompt: {prompt}")
    print("Generating image...")

    try:
        with torch.autocast(device_type=device):
            image = pipeline(prompt).images[0]
        print("Image generated successfully")
        
        # Save with UUID name (optional: keep old if needed)
        image_name = f"image_{uuid.uuid4().hex[:6]}.png"
        image_path = os.path.join(base_dir, image_name)
        image.save(image_path)
        print(f"Image saved at: {image_path}")
        
        del image
        clear_gpu_memory()
        
        return send_file(image_path, mimetype='image/png')

    except Exception as e:
        print("Generation failed:", e)
        return {"error": "Generation failed", "details": str(e)}, 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5008)
