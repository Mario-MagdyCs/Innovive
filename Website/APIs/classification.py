from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing import image as keras_image
from inference_sdk import InferenceHTTPClient
from PIL import Image
import cv2
import os
import tempfile
from flask_cors import CORS
import torch, gc
import base64
from openai import OpenAI

app = Flask(__name__)
CORS(app)

# Class labels
class_names = [
    'aluminum_food_can', 'aluminum_soda_can', 'cardboard', 'fabric', 'glass_bottle', 'glass_jar',
    'paper', 'plain_cup', 'plastic_bag', 'plastic_bottle', 'plastic_cup', 'plastic_cutlery',
    'plastic_detergent_bottle', 'plastic_food_container', 'plastic_straws', 'styrofoam_food_containers'
]

# Model loading
script_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(script_dir, "V2S.keras")

# Patch RandomRotation if needed
from tensorflow.keras import layers
_original_random_rotation_init = layers.RandomRotation.__init__
def patched_random_rotation_init(self, *args, **kwargs):
    kwargs.pop("value_range", None)
    _original_random_rotation_init(self, *args, **kwargs)
layers.RandomRotation.__init__ = patched_random_rotation_init

model = tf.keras.models.load_model(model_path)

# Roboflow client
CLIENT = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="8LF915HpGE0JRvfE5IpS"
)

# OpenAI client
openai_client = OpenAI(api_key="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")

def preprocess_image(img_pil, target_size=(384, 384)):
    img = img_pil.resize(target_size)
    img_array = keras_image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = tf.keras.applications.efficientnet.preprocess_input(img_array)
    return img_array

def clear_gpu_memory():
    # Fix the if condition by removing extra parenthesis
    if tf.config.list_physical_devices('GPU'):
        tf.keras.backend.clear_session()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect()

def get_local_prediction(image_path):
    try:
        rf_result = CLIENT.infer(image_path, model_id="multi-object-material/1")
        
        if not rf_result.get('predictions'):
            return None
            
        image = cv2.imread(image_path)
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        detected_materials = []

        for bbox in rf_result['predictions']:
            x1 = int(bbox['x'] - bbox['width'] / 2)
            x2 = int(bbox['x'] + bbox['width'] / 2)
            y1 = int(bbox['y'] - bbox['height'] / 2)
            y2 = int(bbox['y'] + bbox['height'] / 2)
            cropped = image[max(y1, 0):min(y2, image.shape[0]), max(x1, 0):min(x2, image.shape[1])]
            cropped_pil = Image.fromarray(cropped).copy()

            img_array = preprocess_image(cropped_pil)
            prediction = model.predict(img_array)
            predicted_index = np.argmax(prediction, axis=1)
            detected_materials.append(class_names[predicted_index[0]])

        if detected_materials:
            # Return the most frequently detected material
            from collections import Counter
            return Counter(detected_materials).most_common(1)[0][0]
        return None
        
    except Exception as e:
        print(f"Local prediction error: {str(e)}")
        return None

def get_chatgpt_prediction(image_path):
    try:
        with open(image_path, "rb") as image_file:
            base64_image = base64.b64encode(image_file.read()).decode('utf-8')
            
        response = openai_client.chat.completions.create(
            model="gpt-4o",
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "text", 
                        "text": (
                            "Identify the main material of this object. Choose ONLY from these options:\n"
                            f"{', '.join(class_names)}\n\n"
                            "Respond with EXACTLY ONE of these material names in the exact same spelling and format. "
                            "If you're absolutely certain the material isn't in this list, "
                            "respond with a new material name in lowercase_with_underscores format. "
                            "Never explain your answer - just provide the material name."
                        )
                    },
                    {
                        "type": "image_url", 
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{base64_image}"
                        }
                    }
                ]
            }],
            max_tokens=100,
        )
        
        # Clean and verify the response
        result = response.choices[0].message.content.strip().lower().replace(" ", "_")
        
        # Check if the result matches our class names exactly
        if result in class_names:
            return result
        else:
            print(f"New material detected by ChatGPT: {result} (not in our list)")
            return result
            
    except Exception as e:
        print(f"ChatGPT prediction error: {str(e)}")
        return None

@app.route("/classify", methods=["POST"])
def classify():
    if 'images' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    files = request.files.getlist('images')
    results = []

    for file in files:
        # Create a temporary file
        temp_fd, temp_path = tempfile.mkstemp(suffix='.jpg')
        try:
            # Close the file descriptor immediately
            os.close(temp_fd)
            
            # Save the uploaded file
            file.save(temp_path)
            
            # Process the image
            local_pred = get_local_prediction(temp_path)
            chatgpt_pred = get_chatgpt_prediction(temp_path)
            
            print(f"\nImage: {file.filename}")
            print(f"Local model prediction: {local_pred}")
            print(f"ChatGPT Vision prediction: {chatgpt_pred}")
            
            # Use ChatGPT prediction if available, otherwise fall back to local
            final_pred = chatgpt_pred if chatgpt_pred is not None else local_pred
            if final_pred is not None:
                results.append(final_pred)
                
        except Exception as e:
            print(f"Error processing image {file.filename}: {str(e)}")
        finally:
            # Ensure the temporary file is deleted even if an error occurs
            try:
                if os.path.exists(temp_path):
                    os.remove(temp_path)
            except Exception as e:
                print(f"Warning: Could not delete temporary file {temp_path}: {str(e)}")
            clear_gpu_memory()

    return jsonify({'results': results})





@app.route("/classify-base64", methods=["POST"])
def classify_base64():
    print("📥 Received request to /classify-base64")

    from base64 import b64decode
    from io import BytesIO

    data = request.get_json()
    img_str = data.get("image")
    print(f"🧾 Got base64 string: {img_str[:30]}...")  # Log part of the base64

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

        print(f"✅ Predicted: {predicted_label}")
        return jsonify({"results": [predicted_label]})

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return jsonify({"error": str(e)}), 500



if __name__ == "__main__":
    app.run(host="0.0.0.0",port=5000)