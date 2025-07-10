import os
import sys
from flask import Flask, request, jsonify

# Dynamically include your generator module path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GENERATOR_DIR = os.path.abspath(os.path.join(BASE_DIR, '../../DIY Text Generation'))
sys.path.append(GENERATOR_DIR)

from final_diy_prompt_generator import generate_diy_prompt

# Flask App
app = Flask(__name__)

@app.route('/generate-prompt', methods=['POST'])
def generate_prompt():
    data = request.get_json()
    materials = data.get('materials', [])
    
    if not materials:
        return jsonify({"error": "No materials provided"}), 400
    
    try:
        prompt = generate_diy_prompt(materials)
        print(f"📋 Generated prompt: {prompt}")
        return jsonify({"prompt": prompt})
    except Exception as e:
        print("❌ Prompt generation failed:", e)
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5001)
