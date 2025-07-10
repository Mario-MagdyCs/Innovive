from waitress import serve
import text_to_image_api  # 👈 your actual Flask file

print("🚀 Starting Flask app using Waitress...")
serve(text_to_image_api.app, host='0.0.0.0', port=5005)
