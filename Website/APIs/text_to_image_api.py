import os
import uuid
import replicate
import requests
from flask import Flask, request, jsonify, send_file, send_from_directory, make_response
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.utils import secure_filename

# Load environment variables
load_dotenv()

# Configuration
REPLICATE_API_TOKEN = os.getenv("REPLICATE_API_TOKEN")
os.environ["REPLICATE_API_TOKEN"] = REPLICATE_API_TOKEN
MODEL_VERSION = "black-forest-labs/flux-1.1-pro"

# Initialize Flask app with better CORS configuration
app = Flask(__name__)
CORS(app, resources={
    r"/generate-replicate": {"origins": "*"},
    r"/generated_images/*": {"origins": "*"}
})

# Configure paths
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
IMAGE_DIR = os.path.join(BASE_DIR, '..', 'public', 'generated_images', 'projects')
os.makedirs(IMAGE_DIR, exist_ok=True)

# Constants
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

def run_replicate_inference(
    prompt: str,
    seed: int = 0,
    aspect_ratio: str = "1:1",
    output_format: str = "png",
    output_quality: int = 100,
    safety_tolerance: int = 3,
    prompt_upsampling: bool = True
) -> dict:
    """Run inference with Replicate API and save the resulting image."""
    input_data = {
        "prompt": prompt,
        "seed": seed,
        "aspect_ratio": aspect_ratio,
        "output_format": output_format,
        "output_quality": output_quality,
        "safety_tolerance": safety_tolerance,
        "prompt_upsampling": prompt_upsampling
    }

    print("▶️ Sending to Replicate:", input_data)
    
    try:
        output_url = replicate.run(MODEL_VERSION, input=input_data)
        if not output_url:
            raise ValueError("No image URL returned by Replicate")

        # Generate secure filename
        image_filename = f"flux_{uuid.uuid4().hex[:8]}.png"
        image_path = os.path.join(IMAGE_DIR, image_filename)

        # Download and save image
        response = requests.get(output_url, timeout=30)
        response.raise_for_status()
        
        with open(image_path, "wb") as f:
            f.write(response.content)

        print(f"✅ Image saved at {image_path}")
        return {
            "filename": image_filename,
            "path": image_path,
            "url": f"/generated_images/projects/{image_filename}"
        }

    except Exception as e:
        print(f"❌ Replicate inference failed: {str(e)}")
        raise

@app.route("/generate-replicate", methods=["POST"])
def generate_replicate():
    """Handle image generation requests."""
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 400

    prompt = request.json.get("prompt", "").strip()
    if not prompt:
        return jsonify({"error": "Prompt is required"}), 400

    print(f"\nReceived prompt: {prompt}")
    
    try:
        result = run_replicate_inference(
            prompt=prompt,
            seed=42,
            aspect_ratio="1:1",
            output_format="png",
            output_quality=100,
            safety_tolerance=3,
            prompt_upsampling=True
        )

        # Mobile client response
        if request.headers.get("X-Client-Type") == "mobile":
            base_url = f"http://{request.host}"  # Dynamically get host
            return jsonify({
                "success": True,
                "url": f"{base_url}/generated_images/projects/{result['filename']}",
                "filename": result["filename"]
            })

        # Web client response
        return send_file(
            result['path'],
            mimetype='image/png',
            as_attachment=False,
            download_name=result['filename']
        )

    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {str(e)}")
        return jsonify({"error": "Network error during image generation"}), 500
    except Exception as e:
        print(f"❌ Generation failed: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/generated_images/projects/<filename>')
def serve_generated_image(filename):
    try:
        if not secure_filename(filename) == filename:
            print("🚨 Invalid filename:", filename)
            return jsonify({"error": "Invalid filename"}), 400

        file_path = os.path.join(IMAGE_DIR, filename)
        print("🧩 Trying to send file:", file_path)

        return send_file(
            file_path,
            mimetype='image/png',
            as_attachment=False,
            download_name=filename,
            conditional=False
        )

    except FileNotFoundError:
        print("❌ File not found:", filename)
        return jsonify({"error": "Image not found"}), 404
    except Exception as e:
        print("🔥 ERROR serving image:", e)
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5005,
        threaded=True
    )