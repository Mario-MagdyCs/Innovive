import os
import requests
from dotenv import load_dotenv

load_dotenv()

SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")

headers = {
    "Authorization": f"Bearer {SENDGRID_API_KEY}",
    "Content-Type": "application/json"
}

url = "https://api.sendgrid.com/v3/messages?limit=10"

response = requests.get(url, headers=headers)

if response.status_code == 200:
    print("✅ Email activity:")
    print(response.json())
else:
    print(f"❌ Failed to retrieve activity. Status Code: {response.status_code}")
    print(response.text)
