from waitress import serve
import preserving_api  # 👈 make sure this matches your file name

print("🛡️ Starting Preserving Flask app using Waitress...")
serve(preserving_api.app, host='0.0.0.0', port=5006)