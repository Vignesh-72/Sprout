import os
import motor.motor_asyncio
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

# --- DATABASE CONNECTION ---
client = motor.motor_asyncio.AsyncIOMotorClient(
    os.getenv("MONGO_URI"),
    serverSelectionTimeoutMS=5000
)
db = client[os.getenv("DB_NAME", "sprout_db")]
collection = db[os.getenv("COLLECTION_NAME", "sensor_logs")]
profile_collection = db["plant_config"]

# --- CORE FUNCTIONS ---

async def smart_log_data(data: dict) -> bool:
    """Logs new sensor data from the hardware."""
    data["timestamp"] = datetime.utcnow()
    await collection.insert_one(data)
    print(f"💾 Logged data: {data['timestamp']}")
    return True

async def get_recent_history(limit: int = 5):
    """Fetches the last N entries for AI Context."""
    cursor = collection.find().sort("timestamp", -1).limit(limit)
    history = await cursor.to_list(length=limit)
    # Convert ObjectIDs to strings or remove them for JSON serialization
    for h in history: h.pop("_id", None)
    return history

async def get_weekly_analytics():
    """Aggregates daily averages for the Dashboard Chart."""
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    
    pipeline = [
        {"$match": {"timestamp": {"$gte": seven_days_ago}}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$timestamp"}},
            "avg_soil": {"$avg": "$soil_moisture"},
            "avg_temp": {"$avg": "$temperature"},
            "count": {"$sum": 1}
        }},
        {"$sort": {"_id": 1}}
    ]
    
    results = await collection.aggregate(pipeline).to_list(length=7)
    # Format for Frontend: [{"date": "2023-10-27", "avg_soil": 45.5, ...}]
    return [{"date": r["_id"], "avg_soil": r["avg_soil"], "avg_temp": r["avg_temp"]} for r in results]

async def get_raw_history_for_ai(days=7):
    """Fetches raw text logs for Gemini analysis."""
    start_date = datetime.utcnow() - timedelta(days=days)
    cursor = collection.find({"timestamp": {"$gte": start_date}}).sort("timestamp", 1)
    # Limit to 100 to save tokens, AI doesn't need every single minute
    logs = await cursor.to_list(length=100) 
    
    simple_logs = []
    for log in logs:
        ts = log['timestamp'].strftime('%Y-%m-%d')
        simple_logs.append(f"{ts}: Soil {log.get('soil_moisture',0)}%, Temp {log.get('temperature',0)}C")
    return simple_logs

# --- PROFILE FUNCTIONS ---

async def get_plant_profile():
    profile = await profile_collection.find_one({"_id": "current_plant"})
    return profile if profile else {"name": "Sprout", "species": "Plant"}

async def save_plant_profile(name: str, species: str):
    await profile_collection.update_one(
        {"_id": "current_plant"}, 
        {"$set": {"name": name, "species": species}}, 
        upsert=True
    )