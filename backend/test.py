import requests
import time

BASE_URL = "http://127.0.0.1:8000"

print("\n🚀 SPROUT BACKEND FULL TEST\n")


# ================================
# Helper
# ================================
def post(path, data):
    try:
        r = requests.post(f"{BASE_URL}{path}", json=data, timeout=20)
        return r.status_code, r.json()
    except Exception as e:
        return None, str(e)


def get(path):
    try:
        r = requests.get(f"{BASE_URL}{path}", timeout=20)
        return r.status_code, r.json()
    except Exception as e:
        return None, str(e)


# ================================
# 1. SERVER STATUS
# ================================
print("🔹 Checking server...")
code, res = get("/")

if code == 200:
    print("✅ Server Online:", res)
else:
    print("❌ Server not responding")
    exit()


# ================================
# 2. SEND FAKE SENSOR DATA
# ================================
print("\n🔹 Sending fake sensor data...")

fake_sensor = {
    "soil_moisture": 32,
    "temperature": 28.4,
    "humidity": 65,
    "light_level": 300
}

code, res = post("/update_sensors", fake_sensor)

if code == 200:
    print("✅ Sensor logged:", res)
else:
    print("❌ Sensor logging failed:", res)


time.sleep(1)


# ================================
# 3. CHAT TEST (AI RESPONSE)
# ================================
print("\n🔹 Testing AI chat...")

fake_chat = {
    "user_message": "why are my leaves turning brown?",
    "current_sensors": fake_sensor,
    "plant_name": "Aloe Vera"
}

code, res = post("/chat", fake_chat)

if code == 200:
    print("✅ AI Reply:", res.get("reply"))
    print("⚡ Model Used:", res.get("engine"))
else:
    print("❌ Chat failed:", res)


time.sleep(1)


# ================================
# 4. CARE PROFILE TEST
# ================================
print("\n🔹 Testing care profile...")

code, res = post("/plant/care_profile", {"plant_name": "Rose"})

if code == 200:
    print("✅ Care Profile:", res)
else:
    print("❌ Care profile failed:", res)


time.sleep(1)


# ================================
# 5. ANALYTICS TEST
# ================================
print("\n🔹 Testing analytics...")

code, res = get("/analytics/week")

if code == 200:
    print("✅ Analytics Response:")
    print(res)
else:
    print("❌ Analytics failed:", res)


print("\n🎉 BACKEND TEST COMPLETE\n")
