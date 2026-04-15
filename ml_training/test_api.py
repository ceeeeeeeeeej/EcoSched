import requests

url = "http://127.0.0.1:5000/predict"

files = {
    "image": open("test.jpg", "rb")
}

response = requests.post(url, files=files)

print("Status:", response.status_code)
print("Raw response:", response.text)   # 👈 IMPORTANT