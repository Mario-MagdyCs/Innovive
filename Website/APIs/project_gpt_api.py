from flask import Flask, request, jsonify
import base64
import io
from PIL import Image
import gc
import re
from openai import OpenAI
from dotenv import load_dotenv
import os

load_dotenv()  # Load from .env
api_key = os.getenv("OPENAI_API_KEY")

client = OpenAI(api_key=api_key)

app = Flask(__name__)


def clear_memory():
    gc.collect()

import re

# def parse_output(raw_text):
#     text = raw_text.replace("**", "").strip()

#     # --- Project Name: flexible match for "project name" ---
#     name_match = re.search(r"(?i)(?:^|\n).*project.*name.*?[:\-]\s*(.+)", text)
#     name = name_match.group(1).strip() if name_match else "Unknown"

#     # --- Difficulty Level: flexible match for "difficulty" ---
#     level_match = re.search(r"(?i)(?:^|\n).*difficulty.*level.*?[:\-]\s*(.+)", text)
#     level = level_match.group(1).strip() if level_match else "Unspecified"

#     # --- Materials: support bullet & numbered list until instructions ---
#     materials_match = re.search(
#         r"(?i)(?:^|\n).*materials.*?(?:needed)?[:\-]\s*\n((?:.*\n)*?)(?=\n\s*(?:.*instructions.*[:\-]))",
#         text
#     )
#     materials = []
#     if materials_match:
#         materials_block = materials_match.group(1).strip()
#         materials = [
#             re.sub(r'^(\d+\.\s*|\-|\•|\*)\s*', '', line.strip())
#             for line in materials_block.split('\n')
#             if re.match(r'^(\d+\.\s*|\-|\•|\*)\s*.+', line.strip())
#         ]

#     # --- Instructions: match everything after instructions header ---
#     instructions_match = re.search(
#         r"(?i)(?:^|\n).*instructions.*[:\-]\s*((?:.|\n)+)",
#         text
#     )
#     instructions = []
#     if instructions_match:
#         raw_instructions = instructions_match.group(1).strip()

#         # Try steps with bolded titles (e.g., "1. **Step Title:** Description")
#         # Extract clean flat steps like: "1. Do this"
#         instructions = re.findall(r"\d+\.\s(.+)", raw_instructions)
#         instructions = [step.strip() for step in instructions]


#     return name, level, materials, instructions

# def parse_output(raw_text):
#     text = raw_text.replace("**", "").strip()

#     # --- Project Name ---
#     name_match = re.search(r"(?i)(?:^|\n).*project.*name.*?[:\-]\s*(.+)", text)
#     name = name_match.group(1).strip() if name_match else "Unknown"

#     # --- Difficulty Level ---
#     level_match = re.search(r"(?i)(?:^|\n).*difficulty.*level.*?[:\-]\s*(.+)", text)
#     level = level_match.group(1).strip() if level_match else "Unspecified"

#     # --- Materials: Flexible Matching ---
#     materials = []
#     materials_section = re.search(r"(?i)(?:materials needed|materials)[:\-]\s*(.+?)(?=\n\s*(?:step|instructions))", text, re.DOTALL)
#     if materials_section:
#         materials_text = materials_section.group(1).strip()
#         # Support both bullet points (-, *, •) and numbered lists
#         materials = re.findall(r"(?:(?:\d+\.\s)|(?:\-|\•|\*)\s)(.+)", materials_text)
#         materials = [
#             {
#                 "title": item.split(":")[0].strip(),
#                 "description": item.split(":")[1].strip() if ":" in item else "No description provided."
#             }
#             for item in materials
#         ]

#     # --- Instructions: Multi-Line Matching ---
#     instructions = []
#     instructions_section = re.search(r"(?i)(?:step-by-step instructions|instructions)[:\-]\s*(.+)", text, re.DOTALL)
#     if instructions_section:
#         instructions_text = instructions_section.group(1).strip()
#         # Use a regex that captures title followed by description on the next line
#         instruction_lines = re.findall(r"\d+\.\s(.+?)(?:\n\s+(.+))?", instructions_text)
#         for title, description in instruction_lines:
#             instructions.append({
#                 "title": title.strip(),
#                 "description": description.strip() if description else "No description provided."
#             })

#     return name, level, materials, instructions

import re

def parse_output(raw_text):
    text = raw_text.strip()

    # --- Project Name ---
    name_match = re.search(r"(?i)project\s*name\s*:\s*(.+)", text)
    name = name_match.group(1).strip() if name_match else "Unknown"

    # --- Difficulty Level ---
    level_match = re.search(r"(?i)difficulty\s*level\s*:\s*(.+)", text)
    level = level_match.group(1).strip() if level_match else "Unspecified"

    # --- Materials: Match Title and Description on the Same Line ---
    materials = []
    materials_section = re.findall(r"-\s*Title\s*\[([^\]]+)\]\s*:\s*Description\s*\[([^\]]+)\]", text)
    for title, description in materials_section:
        materials.append({
            "title": title.strip(),
            "description": description.strip()
        })

    # --- Instructions: Match Step Title and Description on the Same Line ---
    instructions = []
    instructions_section = re.findall(r"-\s*Step\s*Title\s*\[([^\]]+)\]\s*:\s*Step\s*Description\s*\[([^\]]+)\]", text)
    for title, description in instructions_section:
        instructions.append({
            "title": title.strip(),
            "description": description.strip()
        })

    return name, level, materials, instructions





@app.route("/generate-instructions", methods=["POST"])
def analyze():
    try:
        data = request.json
        base64_image = data.get("image")

        if not base64_image:
            return jsonify({"error": "No image provided"}), 400

        print("Sending request to OpenAI GPT-4o...")

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": """Generate a clear, structured DIY project description using the provided image with the following details:

1. Project Name: A descriptive and creative name for the project (e.g., Enchanted Animal Terrarium).

2. Difficulty Level: One of Beginner, Intermediate, or Advanced.

3. Materials Needed:
   List each material in the following format:
    - Title [Material Name]: Description [Short description explaining the purpose of this material].

4. Step-by-Step Instructions:
   Each step must be a numbered list in the following format and on the same line:
    - Step Title [Short, clear title for the step]: Step Description [Detailed instructions for this step].
    
Fill the text inside the square brackets without any unnecessary edit to the structure. No section titles like 'Materials' or 'Instructions'. Direct, flat, and clean."""
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
            max_tokens=1000
        )

        output_text = response.choices[0].message.content
        print("Full output decoded:\n", output_text)

        name, level, materials, instructions = parse_output(output_text)
        print(f"\nExtracted name: {name}")
        print(f"\nExtracted level: {level}")
        print(f"\nExtracted materials: {materials}")
        print(f"\nExtracted instructions: {instructions}")
        
        return jsonify({
            "name": name,
            "level": level,
            "materials": materials,
            "instructions": instructions,
            "raw_output": output_text
        })

    except Exception as e:
        print("GPT-4o generation failed:", e)
        return jsonify({"error": str(e)}), 500

    finally:
        clear_memory()




@app.route("/generate-prompt", methods=["POST"])
def generate_prompt():
    try:
        data = request.get_json() if request.is_json else request.form
        materials_raw = data.get("materials", "")
        
        # Handle materials
        materials = materials_raw.split(",") if isinstance(materials_raw, str) else materials_raw
        material_list_str = ", ".join(materials)
        
        # Check for base64 image
        base64_image = data.get("base64_image", "")
        image_contents = []

        if base64_image:
            print("Base64 image detected.")
            image_contents.append({
                "type": "image_url",
                "image_url": {"url": base64_image}
            })
        else:
            # Handle image files (if sent using FormData)
            files = request.files.getlist("images")
            if files:
                print(f"{len(files)} image file(s) received.")
                for file in files:
                    image_data = file.read()
                    base64_image = "data:image/png;base64," + base64.b64encode(image_data).decode("utf-8")
                    image_contents.append({
                        "type": "image_url",
                        "image_url": {"url": base64_image}
                    })

        # Build OpenAI message
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"Give a concise, descriptive DIY prompt that combines the visual shapes/colors of the entered material images with the following material type(s): {material_list_str}. Focus on realistic and practical use."
                    }
                ] + image_contents
            }
        ]

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=messages,
            max_tokens=300
        )

        prompt = response.choices[0].message.content.strip()
        print(prompt)
        return jsonify({"prompt": prompt})

    except Exception as e:
        print("Prompt generation with images failed:", e)
        return jsonify({"error": str(e)}), 500
    


@app.route('/clarify-step', methods=['POST'])
def clarify_step():
    data = request.json
    project_name = data.get("project_name")
    step_number = data.get("step_number")
    title = data.get("step_title")
    description = data.get("step_description")

    if not project_name or not title or not description or not step_number:
        return jsonify({"text": "❌ Missing required fields"}), 400

    prompt = f"""
You are an expert DIY assistant.

The user is working on the project: "{project_name}".

They asked for clarification about Step {step_number}: "{title}: {description}"

🔵 Clarify this step in a simple, friendly, and helpful way.
✅ Use examples or tips if needed.
✅ Limit your response to 3-5 sentences.
"""

    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "system", "content": prompt}],
            temperature=0.7,
        )

        explanation = response.choices[0].message.content.strip()
        return jsonify({"text": f"🔍 Step {step_number} clarified:\n{explanation}"})

    except Exception as e:
        print(f"❌ Clarification error: {str(e)}")
        return jsonify({"text": f"❌ Failed to clarify step: {str(e)}"}), 500

    



if __name__ == "__main__":
    app.run(host="0.0.0.0",port=5003)