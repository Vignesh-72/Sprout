import os
import asyncio
import logging
from dotenv import load_dotenv
from google import genai

load_dotenv()
logger = logging.getLogger("AIService")

# =====================================================
# CONFIG (2026 Strict Priority)
# =====================================================

GEMINI_KEY = os.getenv("GEMINI_KEY")
if not GEMINI_KEY:
    raise RuntimeError("❌ GEMINI_KEY missing in .env")

client = genai.Client(api_key=GEMINI_KEY)

# ⭐ YOUR SPECIFIC PRIORITY LIST
MODEL_PRIORITY = [
    "gemini-2.5-flash-lite",  # First
    "gemini-2.5-flash",       # Second
    "gemini-2.0-flash",       # Third
    "gemini-2.0-flash-lite",  # Fourth
    "gemini-2.0-flash-exp",   # Fifth
    "gemini-2.5-pro"          # Finally
]

REQUEST_TIMEOUT = 12
MAX_RETRIES = 2

# =====================================================
# CORE AI LOGIC
# =====================================================

async def _call_model(model: str, prompt: str):
    return await asyncio.wait_for(
        asyncio.to_thread(
            client.models.generate_content,
            model=model,
            contents=prompt
        ),
        timeout=REQUEST_TIMEOUT
    )

async def generate_raw_response(prompt: str, model_name=None):
    """
    Automatic cascading fallback based on your specific 6-tier list.
    """
    models_to_try = []
    
    # If a specific model is requested by the endpoint, try that first
    if model_name:
        models_to_try.append(model_name)
    
    # Add the rest from the priority list
    for m in MODEL_PRIORITY:
        if m not in models_to_try:
            models_to_try.append(m)

    for model in models_to_try:
        for attempt in range(MAX_RETRIES):
            try:
                logger.info(f"⚡ Tier: {model} (Attempt {attempt+1})")
                res = await _call_model(model, prompt)

                if res and res.text:
                    return res.text.strip()

            except Exception as e:
                err = str(e).lower()
                # Catch Quota (429), Not Found (404), or Server Overload
                if any(x in err for x in ["429", "quota", "404", "not found", "limit", "overloaded"]):
                    logger.warning(f"Tier {model} failed/exhausted → Trying next model...")
                    break 

                logger.error(f"Error on {model}: {err[:50]}")
            
            await asyncio.sleep(1) # Backoff before retry on same model

    logger.error("❌ Critical: All 6 AI tiers failed to respond.")
    return None

async def chat_with_plant(user_msg, sensors, profile, model_name=None):
    prompt = f"""
    You are a {profile.get('species','plant')} named {profile.get('name','Sprout')}.
    
    CURRENT VITALS:
    - Moisture: {sensors.get('soil_moisture',0)}%
    - Temp: {sensors.get('temperature',0)}°C
    - Light: {sensors.get('light_level',0)}%

    USER MESSAGE: "{user_msg}"

    TASK: Respond in 1-2 witty, dramatic, first-person sentences based on your vitals.
    """
    return await generate_raw_response(prompt, model_name)