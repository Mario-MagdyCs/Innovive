import os
import uuid
import replicate
from flask import Flask, request, jsonify,send_file
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.utils import secure_filename
import requests
import random

# Load token from .env
load_dotenv()
REPLICATE_API_TOKEN = os.getenv("REPLICATE_API_TOKEN")
os.environ["REPLICATE_API_TOKEN"] = REPLICATE_API_TOKEN

# Create Flask app
app = Flask(__name__)
CORS(app)

# Output directory
image_dir = os.path.abspath(os.path.join(os.path.dirname(__file__),'..', 'public', 'generated_images', 'projects'))
os.makedirs(image_dir, exist_ok=True)

# Model and version
MODEL_VERSION = "lucataco/sdxl-controlnet:06d6fae3b75ab68a28cd2900afa6033166910dd09fd9751047043a5bbb4c184b"

# Inference handler (send file object instead of URL)
def run_replicate_inference(prompt, image_file_path, negative_prompt="", seed=0, condition_scale=0.5, num_inference_steps=50):
    with open(image_file_path, "rb") as image_file:
        input_data = {
            "prompt": prompt,
            "image": image_file,  # Sending file object
            "negative_prompt": negative_prompt,
            "seed": seed,
            "condition_scale": condition_scale,
            "num_inference_steps": num_inference_steps
        }

        print("▶️ Sending to Replicate with inputs: ", {**input_data, "image": "FILE_OBJECT"})

        output_url = replicate.run(MODEL_VERSION, input=input_data)

        if not output_url:
            raise Exception("No image returned by Replicate")

        image_filename = f"preserved_{uuid.uuid4().hex[:8]}.png"
        image_path = os.path.join(image_dir, image_filename)

        # Download and save the generated image
        img_data = requests.get(output_url).content
        with open(image_path, "wb") as f:
            f.write(img_data)

        print(f"✅ Generated Image saved at {image_path}")
        return {
            "filename": image_filename,
            "path": image_path,
            "url": f"../public/generated_images/projects/{image_filename}"
        }

# API endpoint
@app.route("/generate-replicate", methods=["POST"])
def generate_replicate():
    if 'images' not in request.files:
        print("No images uploaded for preserving")
        return jsonify({'error': 'No image uploaded'}), 400

    file = request.files.getlist('images')[0]

    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400
 
    # Save the uploaded file temporarily
    filename = secure_filename(file.filename)
    temp_path = os.path.join(image_dir, filename)

    os.makedirs(os.path.dirname(temp_path), exist_ok=True)
    file.save(temp_path)

    # Now send the local file path
    image_path = temp_path

    # System-generated values
    prompt = request.form.get("prompt", "")

    
    if not prompt:
        print("No prompt received.")
        return {"error": "Prompt required"}, 400

    print(f"\nReceived prompt: {prompt}")
    print("Generating image...")

    negative_prompt = "blurry, distorted, watermark, low quality, split Images, unrealistic"

    seed=0
    condition_scale = 0.7
    num_inference_steps = 300

    try:
        result = run_replicate_inference(
            prompt=prompt,
            image_file_path=image_path,
            negative_prompt=negative_prompt,
            seed=seed,
            condition_scale=condition_scale,
            num_inference_steps=num_inference_steps
        )

        return send_file(result['path'], mimetype='image/png')
    except Exception as e:
        return jsonify({"success": False, "error": str(e.message)}), 500
    
    


@app.route("/generate-replicate-base64", methods=["POST"])
def generate_base64():
    import base64
    from PIL import Image
    from io import BytesIO
    import os

    try:
        print("Generating preserved project using base64....")
        data = request.get_json()
        base64_str = data.get("image")
        prompt = data.get("prompt", "")

        if not base64_str or not prompt:
            return jsonify({"error": "Missing image or prompt"}), 400

        # Decode base64 to image
        image_data = base64.b64decode(base64_str.split(",")[-1])
        image = Image.open(BytesIO(image_data))
        filename = f"base64_input_{uuid.uuid4().hex[:8]}.png"
        image_path = os.path.join(image_dir, filename)
        image.save(image_path)

        # Use same replicate inference
        result = run_replicate_inference(
            prompt=prompt,
            image_file_path=image_path,
            negative_prompt="blurry, distorted, watermark, low quality, split Images, unrealistic",
            seed=0,
            condition_scale=0.7,
            num_inference_steps=300
        )

        # ✅ Check if request is from mobile client
        if request.headers.get("X-Client-Type") == "mobile":
            base_url = f"http://{request.host}"
            return jsonify({
                "success": True,
                "url": f"{base_url}/generated_images/projects/{os.path.basename(result['path'])}",
                "filename": os.path.basename(result['path'])
            })

        # 🌐 Fallback for web
        return send_file(result['path'], mimetype='image/png')

    except Exception as e:
        print("Base64 generation error:", str(e))
        return jsonify({"error": str(e)}), 500
    

@app.route('/generated_images/projects/<filename>')
def serve_generated_image(filename):
    try:
        filename = secure_filename(filename)
        file_path = os.path.join(image_dir, filename)

        if not os.path.exists(file_path):
            return jsonify({"error": "Image not found"}), 404

        return send_file(file_path, mimetype='image/png')

    except Exception as e:
        print("❌ Error serving image:", str(e))
        return jsonify({"error": str(e)}), 500



# Run server
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5006)
