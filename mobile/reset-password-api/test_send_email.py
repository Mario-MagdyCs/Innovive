import os
import sendgrid
from sendgrid.helpers.mail import Mail
from dotenv import load_dotenv

# Load .env variables
load_dotenv()

SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")

# Initialize SendGrid
sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)

# This is your verified sender
from_email = "inoviveproject@gmail.com"
# Send to yourself (use your real inbox to test)
to_email = "mariomagdyfa@gmail.com"

subject = "Test Email from SendGrid"
content = "🎯 This is a test email sent directly using SendGrid API."

# Build the email
message = Mail(
    from_email=from_email,
    to_emails=to_email,
    subject=subject,
    plain_text_content=content
)

try:
    response = sg.send(message)
    print("✅ Email sent!")
    print("Response Code:", response.status_code)
    print("Message ID:", response.headers.get("X-Message-Id"))
except Exception as e:
    print("❌ Failed to send email:", str(e))
