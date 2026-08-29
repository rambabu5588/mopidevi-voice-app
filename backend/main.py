import os
import uuid
import asyncio
import time
from typing import Optional, Dict, Any, List
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel
from pydub import AudioSegment

import backend.database as db
from backend.text_processing.telugu_normalizer import segment_sentences, normalize_telugu_text
from backend.text_processing.pronunciation_dict import apply_pronunciation_rules
from backend.speech_director.director import SpeechDirector, get_available_styles
from backend.voice_engine.tts_generator import TTSGenerator
from backend.audio_validation.validator import AudioValidator
from backend.mastering.masterer import AudioMasterer

app = FastAPI(title="Mopidevi Temple Telugu Voice Application", version="1.0.0")

# Enable CORS for frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MEDIA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "media_storage")
RECORDINGS_DIR = os.path.join(MEDIA_DIR, "recordings")
OUTPUTS_DIR = os.path.join(MEDIA_DIR, "outputs")
os.makedirs(RECORDINGS_DIR, exist_ok=True)
os.makedirs(OUTPUTS_DIR, exist_ok=True)

# Pydantic Schemas
class LoginRequest(BaseModel):
    username: str
    password: str

class CreateUserRequest(BaseModel):
    name: str
    password: str
    mobile_email: Optional[str] = ""
    role: Optional[str] = "operator"
    status: Optional[str] = "Active"

class ChangePasswordRequest(BaseModel):
    user_id: str
    current_password: str
    new_password: str

class AdminSetPasswordRequest(BaseModel):
    user_id: str
    new_password: str

class GenerateRequest(BaseModel):
    user_id: str = "user_default"
    voice_id: str
    telugu_script: str
    style: str = "Devotional"

class RegenerateRequest(BaseModel):
    style: Optional[str] = None

TEMPLE_TEMPLATES = [
    {
        "id": "tpl_welcome",
        "title": "స్వాగతం (Temple Welcome)",
        "category": "General",
        "script": "శ్రీ మోపిదేవి సుబ్రహ్మణ్యేశ్వర స్వామి వారి దివ్య క్షేత్రానికి విచ్చేసిన భక్తులందరికీ హృదయపూర్వక స్వాగతం."
    },
    {
        "id": "tpl_darshan",
        "title": "దర్శన ప్రకటన (Darshan Queue)",
        "category": "Darshan",
        "script": "భక్తులు అందరూ లైనులో ప్రశాంతంగా వెళ్ళి నాగేంద్రస్వామి వారి దివ్య దర్శనం చేసుకోవాల్సిందిగా మనవి."
    },
    {
        "id": "tpl_pooja",
        "title": "సర్పదోష నివారణ పూజ (Pooja Notice)",
        "category": "Pooja",
        "script": "ఉదయం 10:30 AM గంటలకు సర్పదోష నివారణ అభిషేకం మరియు సహస్రనామార్చన ప్రారంభమగును."
    },
    {
        "id": "tpl_prasadam",
        "title": "తీర్థప్రసాదాల వితరణ (Prasadam Notice)",
        "category": "Prasadam",
        "script": "స్వామివారి పవిత్ర తీర్థప్రసాదములు ప్రాంగణము వెనుక భాగాన వితరణ చేయబడుచున్నవి."
    },
    {
        "id": "tpl_festival",
        "title": "ఉత్సవ ప్రకటన (Festival Announcement)",
        "category": "Festival",
        "script": "శ్రీ సుబ్రహ్మణ్య షష్ఠి మహోత్సవాల సందర్భంగా ప్రత్యేక హారతి మరియు కళ్యాణం నిర్వహించబడును."
    },
    {
        "id": "tpl_emergency",
        "title": "ముఖ్యమైన సూచన (Important Notice)",
        "category": "Emergency",
        "script": "దయచేసి భక్తులు తమ పిల్లలను మరియు పవిత్ర వస్తువులను జాగ్రత్తగా చూసుకోవాల్సిందిగా సూచించడమైనది."
    }
]

# Pipelines Job Processor
async def process_announcement_pipeline(job_id: str):
    try:
        job = db.get_job(job_id)
        if not job:
            return

        # Stage 1: Received & Queued
        db.update_job_status(job_id, "PROCESSING", "● Processing Telugu text", 15)
        await asyncio.sleep(0.3)

        raw_script = job["telugu_script"]
        style = job["style"]
        voice_id = job["voice_id"]

        # Stage 2: Sentence-by-Sentence Generation & Automated Validation using mopidevi_voice
        from mopidevi_voice.pipeline.generate import SentencePipelineGenerator
        from mopidevi_voice.audio.masterer import master_speech_audio
        from mopidevi_voice.text_processing import normalize_telugu
        from mopidevi_voice.voice_clone.trainer import detect_difficult_words

        clean_script = normalize_telugu(raw_script)
        db.update_job_status(job_id, "PROCESSING", "✓ Telugu normalized & Mopidevi pronunciation checked", 30, clean_script=clean_script)

        # Detect difficult words and issue adaptive voice training requests
        diff_words = detect_difficult_words(raw_script)
        for d_word in diff_words:
            req_id = f"TR-{uuid.uuid4().hex[:6].upper()}"
            db.create_training_request(
                req_id=req_id,
                job_id=job_id,
                user_id=job["user_id"],
                voice_id=voice_id,
                word_text=d_word,
                sentence_text=raw_script
            )

        def report_progress(status: str, step_msg: str, percent: int):
            db.update_job_status(job_id, status, step_msg, percent)

        speech_audio = await SentencePipelineGenerator.generate_speech_pipeline(
            telugu_script=raw_script,
            voice_id=voice_id,
            style_name=style,
            progress_callback=report_progress
        )

        # Stage 3: Audio Mastering
        db.update_job_status(job_id, "PROCESSING", "● Final speech audio mastering", 90)
        out_wav = os.path.join(OUTPUTS_DIR, f"announcement_{job_id}.wav")
        out_mp3 = os.path.join(OUTPUTS_DIR, f"announcement_{job_id}.mp3")

        mastered = master_speech_audio(speech_audio, out_wav, out_mp3)

        if mastered:
            rel_wav = f"/api/audio/announcement_{job_id}.wav"
            rel_mp3 = f"/api/audio/announcement_{job_id}.mp3"
            db.update_job_status(job_id, "COMPLETED", "✓ Pure Voice Announcement Ready!", 100, output_audio_path=rel_wav, output_mp3_path=rel_mp3)

            # Record in announcement history
            voice_prof = db.get_voice_profile_by_id(voice_id)
            v_name = voice_prof.get("voice_name", "తెలుగు గుడి ప్రకటన స్వరము") if voice_prof else "తెలుగు గుడి ప్రకటన స్వరము"
            title = raw_script[:35] + "..." if len(raw_script) > 35 else raw_script
            duration_sec = len(speech_audio) / 1000.0 if speech_audio else 0.0
            db.record_announcement_history(
                job_id=job_id,
                user_id=user_id,
                voice_id=voice_id,
                voice_name=v_name,
                title=title,
                script_text=raw_script,
                style=style,
                output_audio_path=rel_wav,
                duration_seconds=duration_sec
            )
        else:
            db.update_job_status(job_id, "FAILED", "Audio mastering failed", 0)

    except Exception as e:
        print(f"[Pipeline] Pipeline error: {e}")
        db.update_job_status(job_id, "FAILED", f"Error: {str(e)}", 0)

# Endpoints
@app.get("/api/templates")
def get_templates():
    return TEMPLE_TEMPLATES

@app.get("/api/styles")
def get_styles():
    return get_available_styles()

@app.get("/api/voices")
def get_voices(user_id: str = "user_default"):
    return db.get_voice_profiles(user_id)

@app.post("/api/voices/analyze")
async def analyze_voice_recording(file: UploadFile = File(...)):
    temp_path = os.path.join(RECORDINGS_DIR, f"temp_analysis_{uuid.uuid4().hex[:6]}.wav")
    with open(temp_path, "wb") as f:
        content = await file.read()
        f.write(content)
        
    from mopidevi_voice.voice_clone.analyzer import analyze_voice_sample
    analysis = analyze_voice_sample(temp_path)
    
    if os.path.exists(temp_path):
        os.remove(temp_path)
        
    return analysis

@app.post("/api/voices/upload")
async def upload_voice_sample(
    voice_name: str = Form(...),
    user_id: str = Form("user_default"),
    file: UploadFile = File(...)
):
    voice_id = f"voice_custom_{uuid.uuid4().hex[:8]}"
    ext = file.filename.split(".")[-1] if "." in file.filename else "wav"
    file_path = os.path.join(RECORDINGS_DIR, f"{voice_id}.{ext}")
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
        
    from mopidevi_voice.voice_clone.analyzer import analyze_voice_sample
    from mopidevi_voice.voice_clone.deep_clone import extract_neural_speaker_embedding
    
    analysis = analyze_voice_sample(file_path)
    quality = analysis.get("quality_badge", "🟢 Good")
    
    # Extract 512-dim Deep Neural Speaker Embedding for true voice cloning
    neural_emb = extract_neural_speaker_embedding(file_path, voice_id)
    
    voice_profile = db.create_voice_profile(
        voice_id=voice_id,
        user_id=user_id,
        voice_name=voice_name,
        voice_type="custom",
        audio_sample_path=file_path,
        quality_score=quality
    )
    return {**voice_profile, "analysis": analysis, "neural_embedding": neural_emb}

@app.get("/api/training/dataset-scripts")
def get_dataset_scripts():
    return db.get_all_training_scripts()

@app.post("/api/training/generate-script-tasks")
def generate_script_tasks_endpoint(script_id: str = Form(...), user_id: str = Form("user_default"), voice_id: str = Form("voice_te_female_1")):
    from mopidevi_voice.voice_clone.trainer import generate_tasks_from_database_script
    return generate_tasks_from_database_script(script_id, user_id, voice_id)

@app.get("/api/voices/training-requests/{user_id}")
def get_training_requests(user_id: str):
    return db.list_pending_training_requests(user_id)

@app.post("/api/voices/train-sample")
async def upload_training_word_sample(
    req_id: str = Form(...),
    voice_id: str = Form(...),
    word_text: str = Form(...),
    file: UploadFile = File(...)
):
    snippets_dir = os.path.join(RECORDINGS_DIR, "training_snippets")
    os.makedirs(snippets_dir, exist_ok=True)
    
    file_path = os.path.join(snippets_dir, f"snippet_{uuid.uuid4().hex[:6]}.wav")
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
        
    from mopidevi_voice.voice_clone.trainer import train_word_sample
    result = train_word_sample(
        req_id=req_id,
        voice_id=voice_id,
        word_text=word_text,
        audio_sample_path=file_path
    )
    return result

@app.get("/api/voices/{voice_id}/versions")
def get_voice_versions(voice_id: str):
    from mopidevi_voice.voice_clone.version_manager import list_versions
    return list_versions(voice_id)

@app.post("/api/voices/{voice_id}/versions/create")
def create_voice_version_endpoint(voice_id: str):
    from mopidevi_voice.voice_clone.version_manager import create_new_version
    return create_new_version(voice_id)

@app.post("/api/voices/versions/{version_id}/evaluate")
def evaluate_version_endpoint(version_id: str):
    from mopidevi_voice.voice_clone.evaluator import evaluate_version
    return evaluate_version(version_id)

@app.post("/api/voices/versions/{version_id}/approve")
def approve_version_endpoint(version_id: str):
    from mopidevi_voice.voice_clone.version_manager import approve_version
    return approve_version(version_id)

class AssignVoiceRequest(BaseModel):
    user_id: str
    voice_id: str
    version_id: Optional[str] = "v1.0"

class LogoutRequest(BaseModel):
    user_id: str

@app.post("/api/auth/login")
def login_endpoint(req: LoginRequest):
    user = db.authenticate_user(req.username, req.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid ID or Password")
    return {"status": "SUCCESS", "user": user}

@app.post("/api/auth/logout")
def logout_endpoint(req: LogoutRequest):
    db.record_user_logout(req.user_id)
    return {"status": "SUCCESS", "message": f"User {req.user_id} logged out"}

@app.get("/api/users")
def get_all_users_endpoint():
    return db.list_all_users()

@app.post("/api/users/create")
def create_user_endpoint(req: CreateUserRequest):
    new_user = db.create_user(
        name=req.name,
        password=req.password,
        mobile_email=req.mobile_email or "",
        role=req.role or "operator",
        status=req.status or "Active"
    )
    return new_user

@app.delete("/api/users/{user_id}")
def delete_user_endpoint(user_id: str):
    success = db.delete_user(user_id)
    if not success:
        raise HTTPException(status_code=400, detail="Cannot delete root admin account or user not found")
    return {"status": "SUCCESS", "message": f"User {user_id} deleted successfully"}

@app.post("/api/users/change-password")
def change_password_endpoint(req: ChangePasswordRequest):
    res = db.change_user_password(req.user_id, req.current_password, req.new_password)
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("message", "Password change failed"))
    return res

@app.post("/api/admin/users/set-password")
def admin_set_password_endpoint(req: AdminSetPasswordRequest):
    res = db.admin_set_user_password(req.user_id, req.new_password)
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("message", "Password update failed"))
    return res

@app.get("/api/users/{user_id}/assigned-voice")
def get_user_assigned_voice_endpoint(user_id: str):
    user = db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    voice_id = user.get("assigned_voice_id", "voice_te_male_1")
    versions = db.list_voice_versions(voice_id)
    active_ver = versions[0]["version_num"] if versions else "v1.0"
    return {
        "user_id": user_id,
        "role": user["role"],
        "assigned_voice_id": voice_id,
        "assigned_version": active_ver
    }

@app.post("/api/users/assign-voice")
def assign_voice_endpoint(req: AssignVoiceRequest):
    success = db.assign_voice_to_user(req.user_id, req.voice_id, req.version_id)
    return {"status": "SUCCESS", "message": f"Voice {req.voice_id} ({req.version_id}) assigned to user {req.user_id}"}

@app.delete("/api/voices/{voice_id}")
def delete_voice(voice_id: str, user_id: str = "user_default"):
    success = db.delete_voice_profile(voice_id, user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Voice profile not found or permission denied")
    return {"message": "Voice profile and associated raw recording deleted successfully"}

@app.post("/api/announcements/generate")
async def generate_announcement(req: GenerateRequest, background_tasks: BackgroundTasks):
    job_id = f"JOB-{uuid.uuid4().hex[:6].upper()}"
    
    # Resolve user assigned voice if not specified
    target_voice_id = req.voice_id
    if not target_voice_id:
        user = db.get_user_by_id(req.user_id)
        if user and user.get("assigned_voice_id"):
            target_voice_id = user["assigned_voice_id"]
        else:
            target_voice_id = "voice_te_male_1"

    job = db.create_job(
        job_id=job_id,
        user_id=req.user_id,
        voice_id=target_voice_id,
        telugu_script=req.telugu_script,
        style=req.style
    )
    background_tasks.add_task(process_announcement_pipeline, job_id)
    return job

@app.get("/api/announcements/jobs/{job_id}")
def get_job_status(job_id: str):
    job = db.get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job

@app.post("/api/announcements/regenerate/{job_id}")
async def regenerate_announcement(job_id: str, req: RegenerateRequest, background_tasks: BackgroundTasks):
    existing_job = db.get_job(job_id)
    if not existing_job:
        raise HTTPException(status_code=404, detail="Original job not found")
    
    new_job_id = f"JOB-{uuid.uuid4().hex[:6].upper()}"
    new_style = req.style if req.style else existing_job["style"]
    
    job = db.create_job(
        job_id=new_job_id,
        user_id=existing_job["user_id"],
        voice_id=existing_job["voice_id"],
        telugu_script=existing_job["telugu_script"],
        style=new_style
    )
    background_tasks.add_task(process_announcement_pipeline, new_job_id)
    return job

# Task Engine Endpoints
@app.get("/api/tasks")
def get_user_tasks_endpoint(user_id: str = "USR-00001", status: Optional[str] = None):
    return db.get_user_tasks(user_id, status)

@app.get("/api/tasks/{task_id}")
def get_task_details_endpoint(task_id: str):
    task = db.get_task_details(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@app.post("/api/tasks/{task_id}/submit-item")
async def submit_task_item_endpoint(
    task_id: str,
    item_id: str = Form(...),
    user_id: str = Form("USR-00001"),
    target_text: str = Form(...),
    file: UploadFile = File(...)
):
    ext = file.filename.split(".")[-1] if "." in file.filename else "wav"
    audio_filename = f"task_{task_id}_{item_id}_{uuid.uuid4().hex[:4]}.{ext}"
    saved_path = os.path.join(RECORDINGS_DIR, audio_filename)
    
    with open(saved_path, "wb") as f:
        content = await file.read()
        f.write(content)
        
    validation = AudioValidator.validate_training_sample(saved_path, target_text)
    p_score = validation.get("pronunciation_score", 95.0)
    q_score = validation.get("quality_score", "🟢 Good")
    is_valid = validation.get("is_valid", True)
    
    result = db.submit_task_item_audio(
        task_id=task_id,
        item_id=item_id,
        user_id=user_id,
        audio_path=saved_path,
        target_text=target_text,
        pronunciation_score=p_score,
        audio_quality=q_score,
        is_accepted=is_valid
    )
    result["validation"] = validation
    return result

@app.get("/api/user/profile")
def get_user_profile_endpoint(user_id: str = "USR-00001"):
    return db.get_user_profile_summary(user_id)

@app.get("/api/announcements/history")
def get_history(user_id: str = "USR-00001"):
    hist = db.get_user_announcement_history(user_id)
    if not hist:
        return db.list_recent_jobs(user_id)
    return hist

@app.get("/api/audio/{filename}")
def get_audio_file(filename: str):
    file_path = os.path.join(OUTPUTS_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Audio file not found")
    media_type = "audio/mpeg" if filename.endswith(".mp3") else "audio/wav"
    return FileResponse(file_path, media_type=media_type)

# Serve Frontend static directory if present
FRONTEND_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "frontend")
if os.path.exists(FRONTEND_DIR):
    app.mount("/", StaticFiles(directory=FRONTEND_DIR, html=True), name="frontend")
