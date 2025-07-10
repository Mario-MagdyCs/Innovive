from flask import Flask, request, jsonify
import requests
import os
from dotenv import load_dotenv
import sendgrid
from sendgrid.helpers.mail import Mail
import random
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")


# Temporary in-memory code storage (for now)
codes = {}

# ============= Send verification email ====================
def send_verification_email(to_email, code):
    sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
    from_email = 'inoviveproject@gmail.com'
    subject = 'Your Password Reset Code'
    content = f'Your verification code is: {code}'

    message = Mail(
        from_email=from_email,
        to_emails=to_email,
        subject=subject,
        plain_text_content=content
    )

    try:
        response = sg.send(message)
        print("✅ Email Sent")
        print("Response Code:", response.status_code)
        print("Message ID:", response.headers.get("X-Message-Id"))
    except Exception as e:
        print("❌ Failed to send email:", str(e))

# ============= Search user helper ====================
def find_user_by_email(email):
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}"
    }
    res = requests.get(f"{SUPABASE_URL}/auth/v1/admin/users", headers=headers)
    data = res.json()
    users = data.get("users", [])

    for user in users:
        if user.get("email") == email:
            return user
    return None

# ============= Generate reset code + send email ====================
@app.route("/send-reset-code/", methods=["POST"])
def send_reset_code():
    data = request.get_json()
    email = data.get("email")
    if not email:
        return jsonify({"error": "Email is required."}), 400

    print("Received email:", email)

    user = find_user_by_email(email)
    if not user:
        return jsonify({"error": "User not found."}), 404

    code = str(random.randint(100000, 999999))
    codes[email] = code
    send_verification_email(email, code)

    return jsonify({"message": "Reset code sent successfully."}), 200

# ============= Verify code entered by user ====================
@app.route("/verify-code/", methods=["POST"])
def verify_code():
    data = request.get_json()
    email = data.get("email")
    entered_code = data.get("code")

    if not email or not entered_code:
        return jsonify({"error": "Email and code are required."}), 400

    stored_code = codes.get(email)

    if stored_code == entered_code:
        return jsonify({"message": "Code verified."}), 200
    else:
        return jsonify({"error": "Invalid code."}), 400

# ============= Actually reset the password ====================
@app.route("/reset-password/", methods=["POST"])
def reset_password():
    data = request.get_json()
    email = data.get("email")
    new_password = data.get("new_password")

    if not email or not new_password:
        return jsonify({"error": "Email and new password are required."}), 400

    user = find_user_by_email(email)
    if not user:
        return jsonify({"error": "User not found."}), 404

    user_id = user["id"]
    print(f"✅ Found User ID: {user_id}")

    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}"
    }

    update_res = requests.put(
        f"{SUPABASE_URL}/auth/v1/admin/users/{user_id}",
        headers=headers,
        json={"password": new_password}
    )

    print("Update Response Code:", update_res.status_code)
    print("Update Response Body:", update_res.text)

    if update_res.status_code != 200:
        return jsonify({"error": "Failed to update password."}), 500

    return jsonify({"message": "Password updated successfully."}), 200

# ============= Start Flask Server ====================
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
