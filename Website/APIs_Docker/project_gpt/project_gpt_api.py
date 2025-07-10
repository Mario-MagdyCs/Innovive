from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import io
import gc
import re
import os
from PIL import Image
from dotenv import load_dotenv
from openai import OpenAI

# Load API Key
load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=api_key)

# Init Flask
app = Flask(__name__)
CORS(app)

def clear_memory():
    gc.collect()

def parse_output(raw_text):
    text = raw_text.replace("**", "").strip()

    # Project Name
    name_match = re.search(r"(?i)(?:^|\n).*project.*name.*?[:\-]\s*(.+)", text)
    name = name_match.group(1).strip() if name_match else "Unknown"

    # Difficulty Level
    level_match = re.search(r"(?i)(?:^|\n).*difficulty.*level.*?[:\-]\s*(.+)", text)
    level = level_match.group(1).strip() if level_match else "Unspecified"

    # Materials List
    materials_match = re.search(
        r"(?i)(?:^|\n).*materials.*?(?:needed)?[:\-]\s*\n((?:.*\n)*?)(?=\n\s*(?:.*instructions.*[:\-]))",
        text
    )
    materials = []
    if materials_match:
        materials_block = materials_match.group(1).strip()
        materials = [
            re.sub(r'^(\d+\.\s*|\-|\•|\*)\s*', '', line.strip())
            for line in materials_block.split('\n')
            if re.match(r'^(\d+\.\s*|\-|\•|\*)\s*.+', line.strip())
        ]

    # Instructions
    instructions_match = re.search(r"(?i)(?:^|\n).*instructions.*[:\-]\s*((?:.|\n)+)", text)
    instructions = []
    if instructions_match:
        raw_instructions = instructions_match.group(1).strip()
        instructions = re.findall(r"\d+\.\s(.+)", raw_instructions)
        instructions = [step.strip() for step in instructions]

    return name, level, materials, instructions

@app.route("/generate-instructions", methods=["POST"])
def analyze():
    try:
        data = request.json
        base64_image = data.get("image")

        if not base64_image:
            return jsonify({"error": "No image provided"}), 400

        print("📤 Sending to GPT-4o...")

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": (
                                "Generate the Project Name, Difficulty Level (Beginner, Intermediate, Hard), "
                                "Materials (as a list), and Step-by-Step Instructions of this DIY project. "
                                "The instructions should be written as a direct, flat numbered list without section titles or bold formatting."
                            )
                        },
                        {
                            "type": "image_url",
                            "image_url": {"url": base64_image}
                        }
                    ]
                }
            ],
            max_tokens=1000
        )

        output_text = response.choices[0].message.content
        print("🧠 GPT-4o Output:\n", output_text)

        name, level, materials, instructions = parse_output(output_text)

        return jsonify({
            "name": name,
            "level": level,
            "materials": materials,
            "instructions": instructions,
            "raw_output": output_text
        })

    except Exception as e:
        print("❌ GPT-4o processing failed:", e)
        return jsonify({"error": str(e)}), 500

    finally:
        clear_memory()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5003)
