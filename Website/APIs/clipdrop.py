import requests

# Your ClipDrop API key
API_KEY = "43a507c692b6c81acdd8f92765e803ea6b801199026fa0d6317e74967bbd5ee03e832e4a1a72d8d7893b3c0b067fb004"

# Path to your image file
image_path = "image_4f15ed.png"

# Desired output dimensions (max 4096 x 4096)
target_width = "1024"
target_height = "1024"

# API endpoint
url = "https://clipdrop-api.co/image-upscaling/v1/upscale"

# Prepare the image file and parameters
with open(image_path, "rb") as image_file:
    files = {
        "image_file": image_file,
    }
    data = {
        "target_width": target_width,
        "target_height": target_height
    }
    headers = {
        "x-api-key": API_KEY
    }

    # Send POST request
    response = requests.post(url, headers=headers, files=files, data=data)

    # Handle response
    if response.status_code == 200:
        with open("upscaled_image.hpg", "wb") as out:
            out.write(response.content)
        print("✅ Image saved as 'upscaled_image.webp'")
    else:
        print("❌ Error:", response.status_code)
        print(response.json())
