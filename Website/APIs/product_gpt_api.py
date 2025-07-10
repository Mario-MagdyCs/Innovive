from flask import Flask, request, jsonify
import base64, io, gc, re, json
from PIL import Image
from openai import OpenAI
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")

client = OpenAI(api_key=api_key)

app = Flask(__name__)

def clear_memory():
    gc.collect()

def extract_json_block(text):
    try:
        match = re.search(r"```json\s*(\{.*?\})\s*```", text, re.DOTALL)
        if not match:
            match = re.search(r"(\{.*\})", text, re.DOTALL)
        if match:
            return json.loads(match.group(1))
        else:
            raise ValueError("No JSON found")
    except Exception as e:
        print("⚠️ Failed to parse structured JSON:", e)
        return None

@app.route("/analyze-product", methods=["POST"])
def analyze_industrial_image():
    try:
        data = request.json
        base64_image = data.get("image")

        if not base64_image:
            return jsonify({"error": "Image not provided"}), 400

        print("Sending image to GPT-4o for industrial analysis...")

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": (
                                    "Analyze this product image and provide an estimated breakdown of its physical structure.\n\n"
                                    "Return only valid JSON with two keys:\n"
                                    "1. 'measurements': a dictionary (object) where each key is a descriptive part name like 'seat_height', 'leg_length', etc. and the value is an approximate size as a string in centimeters (e.g., '45 cm').\n"
                                    "If measurements cannot be determined, return an empty object: {}.\n"
                                    "2. 'additional_materials': a list of extra materials used in the product.\n\n"
                                    "Do not include explanation — only valid JSON. Avoid vague keys like 'height' or 'width'. Use 'cm'."
                                )
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": base64_image
                            }
                        }
                    ]
                }
            ],
            max_tokens=800
        )

        output_text = response.choices[0].message.content
        print("GPT-4o Raw Output:\n", output_text)

        parsed = extract_json_block(output_text)

        if parsed:
            parts = parsed.get("measurements", [])
            extra_materials = parsed.get("additional_materials", [])
        else:
            parts = []
            extra_materials = []

        return jsonify({
            "parts": parts,
            "additional_materials": extra_materials,
            "raw_output": output_text
        })

    except Exception as e:
        print("GPT-4o generation failed:", e)
        return jsonify({"error": str(e)}), 500

    finally:
        clear_memory()

if __name__ == "__main__":
    app.run(port=5007)
