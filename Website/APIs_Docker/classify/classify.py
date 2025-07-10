from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing import image as keras_image
from tensorflow.keras import layers
from inference_sdk import InferenceHTTPClient
from PIL import Image
import cv2
import os
import tempfile
import torch, gc

# Init Flask
app = Flask(__name__)
CORS(app)

# Class labels
class_names = [
    'aluminum_food_can', 'aluminum_soda_can', 'cardboard', 'fabric', 'glass_bottle', 'glass_jar',
    'paper', 'plain_cup', 'plastic_bag', 'plastic_bottle', 'plastic_cup', 'plastic_cutlery',
    'plastic_detergent_bottle', 'plastic_food_container', 'plastic_straws', 'styrofoam_food_containers'
]

# Fix for RandomRotation layer issue
_original_random_rotation_init = layers.RandomRotation.__init__
def patched_random_rotation_init(self, *args, **kwargs):
    kwargs.pop("value_range", None)
    _original_random_rotation_init(self, *args, **kwargs)
layers.RandomRotation.__init__ = patched_random_rotation_init

# Load model
script_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(script_dir, "V2S.keras")
model = tf.keras.models.load_model(model_path)

# Roboflow client
CLIENT = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="8LF915HpGE0JRvfE5IpS"
)

def preprocess_image(img_pil, target_size=(384, 384)):
    img = img_pil.resize(target_size)
    img_array = keras_image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    return tf.keras.applications.efficientnet.preprocess_input(img_array)

def clear_gpu_memory():
    if tf.config.list_physical_devices('GPU'):
        tf.keras.backend.clear_session()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect()

@app.route("/classify", methods=["POST"])
def classify():
    if 'images' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    files = request.files.getlist('images')
    results = []

    for file in files:
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            file.save(temp_file.name)
            image_path = temp_file.name

            try:
                rf_result = CLIENT.infer(image_path, model_id="multi-object-material/1")
                if 'predictions' not in rf_result or not rf_result['predictions']:
                    continue

                image = cv2.imread(image_path)
                image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                detected_materials = []

                for bbox in rf_result['predictions']:
                    if bbox['confidence'] >= 0.7:
                        x1 = int(bbox['x'] - bbox['width'] / 2)
                        x2 = int(bbox['x'] + bbox['width'] / 2)
                        y1 = int(bbox['y'] - bbox['height'] / 2)
                        y2 = int(bbox['y'] + bbox['height'] / 2)
                        cropped = image[max(y1, 0):min(y2, image.shape[0]), max(x1, 0):min(x2, image.shape[1])]
                        cropped_pil = Image.fromarray(cropped).copy()
                    else:
                        cropped_pil = Image.fromarray(image)

                    img_array = preprocess_image(cropped_pil)
                    prediction = model.predict(img_array)
                    predicted_index = np.argmax(prediction, axis=1)
                    predicted_label = class_names[predicted_index[0]]
                    detected_materials.append(predicted_label)

                if detected_materials:
                    combined = ", ".join(sorted(set(detected_materials)))
                    results.append(combined)

                clear_gpu_memory()

            except Exception as e:
                return jsonify({"error": str(e)}), 500
            finally:
                try:
                    cv2.destroyAllWindows()
                    if os.path.exists(image_path):
                        os.remove(image_path)
                except Exception as cleanup_err:
                    print("Cleanup error:", cleanup_err)

    return jsonify({'results': results})


@app.route("/classify-base64", methods=["POST"])
def classify_base64():
    from base64 import b64decode
    from io import BytesIO

    data = request.get_json()
    img_str = data.get("image")
    if not img_str:
        return jsonify({"error": "No image provided"}), 400

    try:
        if "," in img_str:
            img_str = img_str.split(",")[1]
        img_bytes = BytesIO(b64decode(img_str))
        img = Image.open(img_bytes).convert("RGB")
        img_array = preprocess_image(img)

        prediction = model.predict(img_array)
        predicted_index = np.argmax(prediction, axis=1)
        predicted_label = class_names[predicted_index[0]]

        return jsonify({"results": [predicted_label]})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
