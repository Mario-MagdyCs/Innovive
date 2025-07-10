from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import requests
import tempfile
import os

app = Flask(__name__)
CORS(app)

API_KEY = "43a507c692b6c81acdd8f92765e803ea6b801199026fa0d6317e74967bbd5ee03e832e4a1a72d8d7893b3c0b067fb004"
CLIPDROP_URL = "https://clipdrop-api.co/image-upscaling/v1/upscale"

@app.route("/upscale", methods=["POST"])
def upscale_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    file = request.files['image']
    target_width = request.form.get('target_width', '1024')
    target_height = request.form.get('target_height', '1024')

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as temp_file:
            file.save(temp_file.name)

            with open(temp_file.name, "rb") as image_file:
                files = {"image_file": image_file}
                data = {
                    "target_width": target_width,
                    "target_height": target_height
                }
                headers = {"x-api-key": API_KEY}

                response = requests.post(CLIPDROP_URL, headers=headers, files=files, data=data)

                if response.status_code == 200:
                    output_path = temp_file.name.replace(".jpg", "_upscaled.webp")
                    with open(output_path, "wb") as out:
                        out.write(response.content)
                    return send_file(output_path, mimetype='image/webp')
                else:
                    return jsonify({"error": response.status_code, "message": response.json()}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        try:
            os.remove(temp_file.name)
        except Exception as cleanup_err:
            print("Cleanup error:", cleanup_err)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
