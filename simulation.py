import time
import random
import requests

# URL de votre base de données identifiée
DATABASE_URL = "https://digitalsense-5a6f2-default-rtdb.firebaseio.com/tracking.json"

def update_simulation(lat, lng, temp):
    payload = {
        "camion_01": {
            "lat": lat,
            "lng": lng,
            "temp": temp,
            "timestamp": time.time(),
            "status": "EN_ROUTE",
            "jobs_target": 62
        }
    }
    try:
        response = requests.put(DATABASE_URL, json=payload)
        if response.status_code == 200:
            print(f"✅ Synchro Cloud : GPS({lat:.4f}, {lng:.4f}) Temp({temp}°C)")
        else:
            print(f"⚠️ Erreur Firebase : {response.status_code}")
    except Exception as e:
        print(f"❌ Connexion impossible : {e}")

def start():
    print("--- DEMARRAGE OXYONE ENGINE (SSCI) ---")
    lat, lng = 35.6971, -0.6308 # Départ Oran
    while True:
        lat += 0.0004
        lng += 0.0004
        temp = round(-21.4 + random.uniform(-0.3, 0.3), 2)
        update_simulation(lat, lng, temp)
        time.sleep(4)

if __name__ == "__main__":
    start()
