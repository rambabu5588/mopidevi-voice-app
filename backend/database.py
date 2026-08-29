import sqlite3
import json
import os
import time
import uuid
from typing import Dict, Any, List, Optional

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mopidevi_app.db")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # Users table with auto-generated IDs, auth credentials, and roles
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        auth_id TEXT,
        profile_id TEXT,
        name TEXT NOT NULL,
        mobile_email TEXT,
        role TEXT NOT NULL DEFAULT 'operator', -- 'super_admin', 'voice_manager', 'operator', 'viewer'
        status TEXT NOT NULL DEFAULT 'Active', -- 'Active', 'Inactive'
        password TEXT DEFAULT 'User$1234',
        assigned_voice_id TEXT,
        created_at REAL NOT NULL
    );
    """)
    
    # Safe schema migrations
    for col, col_def in [
        ("auth_id", "TEXT"),
        ("profile_id", "TEXT"),
        ("mobile_email", "TEXT"),
        ("role", "TEXT NOT NULL DEFAULT 'operator'"),
        ("status", "TEXT NOT NULL DEFAULT 'Active'"),
        ("password", "TEXT DEFAULT 'User$1234'"),
        ("assigned_voice_id", "TEXT"),
        ("last_login_at", "REAL"),
        ("last_logout_at", "REAL")
    ]:
        try:
            cursor.execute(f"ALTER TABLE users ADD COLUMN {col} {col_def}")
        except Exception:
            pass

    # Voice Versions table storing model versions (v1.0, v1.1, v2.0)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS voice_versions (
        id TEXT PRIMARY KEY,
        voice_id TEXT NOT NULL,
        version_num TEXT NOT NULL, -- e.g. 'v1.0', 'v1.1', 'v2.0'
        model_path TEXT,
        quality_score TEXT NOT NULL DEFAULT '🟢 Approved (94%)',
        status TEXT NOT NULL DEFAULT 'APPROVED', -- 'DRAFT', 'TRAINING', 'APPROVED'
        created_at REAL NOT NULL,
        FOREIGN KEY (voice_id) REFERENCES voice_profiles (id)
    );
    """)

    # User Voice Assignments table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS user_voice_assignments (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        voice_id TEXT NOT NULL,
        assigned_version_id TEXT NOT NULL,
        created_at REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (voice_id) REFERENCES voice_profiles (id),
        FOREIGN KEY (assigned_version_id) REFERENCES voice_versions (id)
    );
    """)

    # Voice Evaluations table storing test set performance metrics
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS voice_evaluations (
        id TEXT PRIMARY KEY,
        version_id TEXT NOT NULL,
        pronunciation_score REAL NOT NULL DEFAULT 95.0,
        naturalness_score REAL NOT NULL DEFAULT 92.0,
        clarity_score REAL NOT NULL DEFAULT 94.0,
        overall_score REAL NOT NULL DEFAULT 93.5,
        created_at REAL NOT NULL,
        FOREIGN KEY (version_id) REFERENCES voice_versions (id)
    );
    """)
    
    # Voice Profiles table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS voice_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        voice_name TEXT NOT NULL,
        voice_type TEXT NOT NULL, -- 'system' or 'custom'
        audio_sample_path TEXT,
        quality_score TEXT NOT NULL DEFAULT '🟢 Good',
        model_status TEXT NOT NULL DEFAULT 'READY',
        created_at REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );
    """)
    
    # Announcement Jobs table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS announcement_jobs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        voice_id TEXT NOT NULL,
        telugu_script TEXT NOT NULL,
        clean_script TEXT,
        style TEXT NOT NULL,
        effect_settings TEXT NOT NULL, -- JSON string
        status TEXT NOT NULL DEFAULT 'QUEUED',
        current_step TEXT NOT NULL DEFAULT 'Received Request',
        progress_percent INTEGER NOT NULL DEFAULT 0,
        output_audio_path TEXT,
        output_mp3_path TEXT,
        created_at REAL NOT NULL,
        updated_at REAL NOT NULL
    );
    """)

    # Difficult Word Requests table for Adaptive Voice Training
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS difficult_word_requests (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        voice_id TEXT NOT NULL,
        word_text TEXT NOT NULL,
        sentence_text TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING' or 'TRAINED'
        sample_audio_path TEXT,
        created_at REAL NOT NULL
    );
    """)

    # Voice Training Samples table storing acoustic feature embeddings
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS voice_training_samples (
        id TEXT PRIMARY KEY,
        voice_id TEXT NOT NULL,
        word_text TEXT NOT NULL,
        audio_path TEXT NOT NULL,
        acoustic_features TEXT NOT NULL, -- JSON string
        created_at REAL NOT NULL
    );
    """)
    
    # Training Script Database table storing script dataset files
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS training_script_database (
        id TEXT PRIMARY KEY,
        filename TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        script_text TEXT NOT NULL,
        created_at REAL NOT NULL
    );
    """)

    # Seed default admin (sid / Siddhu$1999), operators, and roles
    cursor.execute("SELECT COUNT(*) FROM users WHERE id = 'sid'")
    if cursor.fetchone()[0] == 0:
        now = time.time()
        users_seed = [
            ("sid", "AUTH-00000", "PROF-00000", "Siddhu Temple Admin", "admin@mopidevitemple.org", "super_admin", "Active", "Siddhu$1999", "voice_te_male_1", now),
            ("user_default", "AUTH-00001", "PROF-00001", "Temple Administrator", "admin@mopidevi.org", "super_admin", "Active", "Siddhu$1999", "voice_te_male_1", now),
        ]
        cursor.executemany(
            """INSERT OR REPLACE INTO users (id, auth_id, profile_id, name, mobile_email, role, status, password, assigned_voice_id, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""", 
            users_seed
        )
    
    cursor.execute("SELECT COUNT(*) FROM voice_profiles")
    if cursor.fetchone()[0] == 0:
        default_voices = [
            ("voice_te_female_1", "user_default", "తెలుగు దైవిక స్వరము 1 (Devotional Female)", "system", None, "🟢 Good", "READY", time.time()),
            ("voice_te_male_1", "user_default", "తెలుగు గుడి ప్రకటనా స్వరము 2 (Temple Announcer Male)", "system", None, "🟢 Good", "READY", time.time()),
            ("voice_te_male_2", "user_default", "తెలుగు సుబ్రహ్మణ్య పండిత స్వరము 3 (Pundit Male)", "system", None, "🟢 Good", "READY", time.time())
        ]
        cursor.executemany("INSERT INTO voice_profiles (id, user_id, voice_name, voice_type, audio_sample_path, quality_score, model_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", default_voices)
    
    # Tasks table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        task_type TEXT NOT NULL, -- 'VOICE_IMPROVEMENT', 'RECORDING_RETAKE', 'INITIAL_RECORDING', 'ANNOUNCEMENT_GENERATION', 'QUALITY_CORRECTION'
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'NEW', -- 'NEW', 'IN_PROGRESS', 'COMPLETED', 'RETAKE_REQUIRED'
        total_items INTEGER NOT NULL DEFAULT 1,
        completed_items INTEGER NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL DEFAULT 'Due Today',
        created_at REAL NOT NULL,
        updated_at REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );
    """)

    # Task Items table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS task_items (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        word_id TEXT NOT NULL,
        target_text TEXT NOT NULL,
        sentence_context TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'ACCEPTED', 'REJECTED', 'RETAKE'
        audio_id TEXT,
        audio_path TEXT,
        pronunciation_score REAL DEFAULT 0.0,
        audio_quality_score TEXT DEFAULT '🟢 Good',
        created_at REAL NOT NULL,
        updated_at REAL NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id)
    );
    """)

    # Announcement History table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS announcement_history (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        voice_id TEXT NOT NULL,
        voice_name TEXT NOT NULL,
        title TEXT NOT NULL,
        script_text TEXT NOT NULL,
        style TEXT NOT NULL,
        output_audio_path TEXT NOT NULL,
        duration_seconds REAL NOT NULL DEFAULT 0.0,
        created_at REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );
    """)

    cursor.execute("SELECT COUNT(*) FROM voice_versions")
    if cursor.fetchone()[0] == 0:
        now = time.time()
        default_versions = [
            ("ver_f1_v1", "voice_te_female_1", "v1.0", None, "🟢 Approved (94%)", "APPROVED", now),
            ("ver_m1_v1", "voice_te_male_1", "v1.0", None, "🟢 Approved (95%)", "APPROVED", now),
            ("ver_m2_v1", "voice_te_male_2", "v1.0", None, "🟢 Approved (93%)", "APPROVED", now)
        ]
        cursor.executemany("INSERT INTO voice_versions (id, voice_id, version_num, model_path, quality_score, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)", default_versions)
    
    conn.commit()
    conn.close()
    
    seed_training_scripts_from_folder()

def seed_training_scripts_from_folder():
    scripts_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "mopidevi_voice", "training_scripts")
    if not os.path.exists(scripts_dir):
        return
        
    conn = get_db()
    cursor = conn.cursor()
    
    titles_map = {
        "01_temple_welcome.txt": ("General", "స్వాగతం మరియు పరిచయం (Temple Welcome)"),
        "02_darshan_guidelines.txt": ("Darshan", "దర్శన నియమావళి (Darshan Guidelines)"),
        "03_pooja_abhishekam.txt": ("Pooja", "సర్పదోష నివారణ పూజ (Pooja & Abhishekam)"),
        "04_prasadam_distribution.txt": ("Prasadam", "పవిత్ర తీర్థప్రసాదాలు (Prasadam Distribution)"),
        "05_subrahmanya_stotram.txt": ("Stotram", "శ్రీ సుబ్రహ్మణ్య స్తుతి (Deity Stotram)")
    }
    
    for f_name in sorted(os.listdir(scripts_dir)):
        if f_name.endswith(".txt"):
            file_path = os.path.join(scripts_dir, f_name)
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read().strip()
                if content:
                    script_id = f"SCRIPTDATABASE-{f_name.split('.')[0].upper()}"
                    category, title = titles_map.get(f_name, ("General", f_name))
                    cursor.execute(
                        """INSERT OR REPLACE INTO training_script_database (id, filename, category, title, script_text, created_at)
                           VALUES (?, ?, ?, ?, ?, ?)""",
                        (script_id, f_name, category, title, content, time.time())
                    )
            except Exception as e:
                print(f"[DB] Seed script error for {f_name}: {e}")
                
    conn.commit()
    conn.close()

def get_all_training_scripts() -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM training_script_database ORDER BY filename ASC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def get_training_script_by_id(script_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM training_script_database WHERE id = ?", (script_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_voice_profile(voice_id: str, user_id: str, voice_name: str, voice_type: str, audio_sample_path: Optional[str], quality_score: str) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute(
        "INSERT INTO voice_profiles (id, user_id, voice_name, voice_type, audio_sample_path, quality_score, model_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (voice_id, user_id, voice_name, voice_type, audio_sample_path, quality_score, "READY", now)
    )
    conn.commit()
    conn.close()
    return {
        "id": voice_id,
        "user_id": user_id,
        "voice_name": voice_name,
        "voice_type": voice_type,
        "audio_sample_path": audio_sample_path,
        "quality_score": quality_score,
        "model_status": "READY",
        "created_at": now
    }

def get_voice_profiles(user_id: str) -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM voice_profiles WHERE user_id = ? OR voice_type = 'system' ORDER BY created_at ASC", (user_id,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

def get_voice_profile_by_id(voice_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM voice_profiles WHERE id = ?", (voice_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None


def delete_voice_profile(voice_id: str, user_id: str) -> bool:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT audio_sample_path FROM voice_profiles WHERE id = ? AND user_id = ?", (voice_id, user_id))
    row = cursor.fetchone()
    if row:
        sample_path = row["audio_sample_path"]
        if sample_path and os.path.exists(sample_path):
            try:
                os.remove(sample_path)
            except Exception:
                pass
        cursor.execute("DELETE FROM voice_profiles WHERE id = ?", (voice_id,))
        conn.commit()
        conn.close()
        return True
    conn.close()
    return False

def create_job(job_id: str, user_id: str, voice_id: str, telugu_script: str, style: str, effect_settings: Optional[dict] = None) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    fx_json = json.dumps(effect_settings or {})
    cursor.execute(
        """INSERT INTO announcement_jobs 
           (id, user_id, voice_id, telugu_script, style, effect_settings, status, current_step, progress_percent, created_at, updated_at) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (job_id, user_id, voice_id, telugu_script, style, fx_json, "QUEUED", "Job Created", 5, now, now)
    )
    conn.commit()
    conn.close()
    return get_job(job_id)

def update_job_status(job_id: str, status: str, current_step: str, progress_percent: int, clean_script: str = None, output_audio_path: str = None, output_mp3_path: str = None):
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    if clean_script or output_audio_path or output_mp3_path:
        cursor.execute(
            """UPDATE announcement_jobs 
               SET status = ?, current_step = ?, progress_percent = ?, 
                   clean_script = COALESCE(?, clean_script),
                   output_audio_path = COALESCE(?, output_audio_path),
                   output_mp3_path = COALESCE(?, output_mp3_path),
                   updated_at = ?
               WHERE id = ?""",
            (status, current_step, progress_percent, clean_script, output_audio_path, output_mp3_path, now, job_id)
        )
    else:
        cursor.execute(
            "UPDATE announcement_jobs SET status = ?, current_step = ?, progress_percent = ?, updated_at = ? WHERE id = ?",
            (status, current_step, progress_percent, now, job_id)
        )
    conn.commit()
    conn.close()

def get_job(job_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM announcement_jobs WHERE id = ?", (job_id,))
    row = cursor.fetchone()
    conn.close()
    if row:
        data = dict(row)
        data["effect_settings"] = json.loads(data["effect_settings"]) if data.get("effect_settings") else {}
        return data
    return None

def list_recent_jobs(user_id: str, limit: int = 10) -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM announcement_jobs WHERE user_id = ? ORDER BY created_at DESC LIMIT ?", (user_id, limit))
    rows = cursor.fetchall()
    conn.close()
    res = []
    for r in rows:
        d = dict(r)
        d["effect_settings"] = json.loads(d["effect_settings"]) if d.get("effect_settings") else {}
        res.append(d)
    return res

# Difficult Word Adaptive Training Helpers
def create_training_request(req_id: str, job_id: str, user_id: str, voice_id: str, word_text: str, sentence_text: str) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute(
        """INSERT INTO difficult_word_requests (id, job_id, user_id, voice_id, word_text, sentence_text, status, created_at)
           VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?)""",
        (req_id, job_id, user_id, voice_id, word_text, sentence_text, now)
    )
    conn.commit()
    conn.close()
    return {"id": req_id, "job_id": job_id, "user_id": user_id, "voice_id": voice_id, "word_text": word_text, "sentence_text": sentence_text, "status": "PENDING", "created_at": now}

def list_pending_training_requests(user_id: str) -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM difficult_word_requests WHERE user_id = ? AND status = 'PENDING' ORDER BY created_at DESC", (user_id,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def save_word_training_sample(sample_id: str, req_id: str, voice_id: str, word_text: str, audio_path: str, acoustic_features: dict):
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    features_json = json.dumps(acoustic_features)
    cursor.execute(
        "INSERT INTO voice_training_samples (id, voice_id, word_text, audio_path, acoustic_features, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (sample_id, voice_id, word_text, audio_path, features_json, now)
    )
    cursor.execute(
        "UPDATE difficult_word_requests SET status = 'TRAINED', sample_audio_path = ? WHERE id = ?",
        (audio_path, req_id)
    )
    conn.commit()
    conn.close()

# System 2: User Roles & Voice Assignment Helpers
def list_all_users() -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users ORDER BY created_at ASC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def get_user_by_id(user_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_user(name: str, password: str, mobile_email: str = "", role: str = "operator", status: str = "Active") -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    
    # Calculate next sequence number for auto-generated IDs
    cursor.execute("SELECT COUNT(*) FROM users")
    count = cursor.fetchone()[0] + 1
    
    user_id = f"USR-{count:05d}"
    auth_id = f"AUTH-{count:05d}"
    profile_id = f"PROF-{count:05d}"
    
    cursor.execute(
        """INSERT INTO users (id, auth_id, profile_id, name, mobile_email, role, status, password, assigned_voice_id, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'voice_te_male_1', ?)""",
        (user_id, auth_id, profile_id, name, mobile_email, role, status, password, now)
    )
    conn.commit()
    conn.close()
    return {
        "id": user_id,
        "auth_id": auth_id,
        "profile_id": profile_id,
        "name": name,
        "mobile_email": mobile_email,
        "role": role,
        "status": status,
        "assigned_voice_id": "voice_te_male_1",
        "created_at": now
    }

def get_user_by_id(user_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT * FROM users WHERE id = ? OR auth_id = ? OR name = ?", 
        (user_id.strip(), user_id.strip(), user_id.strip())
    )
    row = cursor.fetchone()
    conn.close()
    if row:
        return dict(row)
    if user_id.strip() in ("sid", "user_default"):
        return {
            "id": "sid",
            "auth_id": "AUTH-00000",
            "profile_id": "PROF-00000",
            "name": "Siddhu Temple Admin",
            "role": "super_admin",
            "status": "Active",
            "assigned_voice_id": "voice_te_male_1"
        }
    return None


def delete_user(user_id: str) -> bool:
    if user_id in ["sid", "user_default"]:
        return False # Prevent deleting root admin
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE id = ?", (user_id,))
    cursor.execute("DELETE FROM user_voice_assignments WHERE user_id = ?", (user_id,))
    conn.commit()
    conn.close()
    return True

def change_user_password(user_id: str, current_password: str, new_password: str) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    # Support lookup by id, auth_id, or name
    cursor.execute(
        "SELECT id, name, password FROM users WHERE id = ? OR auth_id = ? OR name = ?", 
        (user_id.strip(), user_id.strip(), user_id.strip())
    )
    row = cursor.fetchone()
    if not row:
        conn.close()
        return {"success": False, "message": "యూజర్ ఖాతా కనుగొనబడలేదు (User account not found)"}
    
    actual_user_id = row["id"]
    stored_password = row["password"] if row["password"] is not None else ""
    
    # Verify current password
    if stored_password != current_password.strip():
        if (actual_user_id in ("sid", "user_default")) and current_password.strip() == "Siddhu$1999":
            pass # Root admin fallback match
        else:
            conn.close()
            return {"success": False, "message": "ప్రస్తుత పాత పాస్‌వర్డ్ సరిపోలలేదు (Old password does not match)"}
    
    # Save new password into database
    cursor.execute("UPDATE users SET password = ? WHERE id = ?", (new_password.strip(), actual_user_id))
    conn.commit()
    conn.close()
    return {"success": True, "message": "పాస్‌వర్డ్ విజయవంతంగా డేటాబేస్ లో సేవ్ చేయబడింది! (Password updated successfully)", "user_id": actual_user_id}

def admin_set_user_password(user_id: str, new_password: str) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, name FROM users WHERE id = ? OR auth_id = ? OR name = ?", 
        (user_id.strip(), user_id.strip(), user_id.strip())
    )
    row = cursor.fetchone()
    if not row:
        conn.close()
        return {"success": False, "message": "యూజర్ ఖాతా కనుగొనబడలేదు (User account not found)"}
    
    actual_user_id = row["id"]
    cursor.execute("UPDATE users SET password = ? WHERE id = ?", (new_password.strip(), actual_user_id))
    conn.commit()
    conn.close()
    return {"success": True, "message": "పాస్‌వర్డ్ విజయవంతంగా డేటాబేస్ లో సేవ్ చేయబడింది!", "user_id": actual_user_id}

def record_user_logout(user_id: str):
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute("UPDATE users SET last_logout_at = ? WHERE id = ?", (now, user_id.strip()))
    conn.commit()
    conn.close()

def authenticate_user(username_or_id: str, password: str) -> Optional[Dict[str, Any]]:
    now = time.time()
    conn = get_db()
    cursor = conn.cursor()
    
    # 1. Check exact match in database
    cursor.execute(
        "SELECT * FROM users WHERE (id = ? OR auth_id = ? OR name = ?) AND password = ?",
        (username_or_id.strip(), username_or_id.strip(), username_or_id.strip(), password.strip())
    )
    row = cursor.fetchone()
    if row:
        user_id = row["id"]
        cursor.execute("UPDATE users SET last_login_at = ? WHERE id = ?", (now, user_id))
        conn.commit()
        d = dict(row)
        d["last_login_at"] = now
        conn.close()
        return d
    
    # 2. Root admin fallback check (sid / Siddhu$1999)
    if (username_or_id.strip() == "sid" or username_or_id.strip() == "user_default") and password.strip() == "Siddhu$1999":
        cursor.execute("UPDATE users SET last_login_at = ? WHERE id IN ('sid', 'user_default')", (now,))
        conn.commit()
        conn.close()
        return {
            "id": "sid",
            "auth_id": "AUTH-00000",
            "profile_id": "PROF-00000",
            "name": "Siddhu Temple Admin",
            "role": "super_admin",
            "status": "Active",
            "last_login_at": now
        }
    
    conn.close()
    return None


def assign_voice_to_user(user_id: str, voice_id: str, assigned_version_id: str = "v1.0") -> bool:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute("UPDATE users SET assigned_voice_id = ? WHERE id = ?", (voice_id, user_id))
    assign_id = f"ASN-{uuid.uuid4().hex[:6].upper()}"
    cursor.execute(
        "INSERT INTO user_voice_assignments (id, user_id, voice_id, assigned_version_id, created_at) VALUES (?, ?, ?, ?, ?)",
        (assign_id, user_id, voice_id, assigned_version_id, now)
    )
    conn.commit()
    conn.close()
    return True

def list_voice_versions(voice_id: str) -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM voice_versions WHERE voice_id = ? ORDER BY created_at DESC", (voice_id,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def create_voice_version(ver_id: str, voice_id: str, version_num: str, model_path: str = None, quality_score: str = "🟢 Approved (94%)", status: str = "APPROVED") -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute(
        "INSERT INTO voice_versions (id, voice_id, version_num, model_path, quality_score, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (ver_id, voice_id, version_num, model_path, quality_score, status, now)
    )
    conn.commit()
    conn.close()
    return {"id": ver_id, "voice_id": voice_id, "version_num": version_num, "quality_score": quality_score, "status": status, "created_at": now}

def save_voice_evaluation(eval_id: str, version_id: str, p_score: float, n_score: float, c_score: float, o_score: float) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute(
        "INSERT INTO voice_evaluations (id, version_id, pronunciation_score, naturalness_score, clarity_score, overall_score, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (eval_id, version_id, p_score, n_score, c_score, o_score, now)
    )
    conn.commit()
    conn.close()
    return {"id": eval_id, "version_id": version_id, "pronunciation_score": p_score, "naturalness_score": n_score, "clarity_score": c_score, "overall_score": o_score}

DEFAULT_TEMPLE_TRAINING_WORDS = [
    ("WORD-001", "మోపిదేవి", "శ్రీ మోపిదేవి సుబ్రహ్మణ్యేశ్వర స్వామి వారి దివ్య క్షేత్రం."),
    ("WORD-002", "సుబ్రహ్మణ్యేశ్వర", "శ్రీ సుబ్రహ్మణ్యేశ్వర స్వామి వారికి ప్రత్యేక అభిషేకం."),
    ("WORD-003", "సహస్రనామార్చన", "ఉదయం స్వామివారికి సహస్రనామార్చన పూజ జరుగును."),
    ("WORD-004", "తీర్థప్రసాదాలు", "పవిత్ర తీర్థప్రసాదాలు ప్రాంగణంలో అందజేయబడును."),
    ("WORD-005", "కళ్యాణోత్సవం", "శ్రీ వల్లీ దేవసేన సమేత సుబ్రహ్మణ్య కళ్యాణోత్సవం."),
    ("WORD-006", "బ్రహ్మోత్సవాలు", "మోపిదేవి క్షేత్రంలో వార్షిక బ్రహ్మోత్సవాలు ఘనంగా జరుగును."),
    ("WORD-007", "సర్పదోష", "సర్పదోష నివారణకు విశేష పూజలు జరుగుచున్నవి."),
    ("WORD-008", "నివారణ", "సకల దోష నివారణ కొరకు భక్తులు దర్శనం చేసుకుంటారు."),
    ("WORD-009", "మహాత్మ్యం", "మోపిదేవి క్షేత్ర పురాణ మహాత్మ్యం ఎంతో ప్రసిద్ధి చెందినది."),
    ("WORD-010", "వల్లీ", "శ్రీ వల్లీ సమేత సుబ్రహ్మణ్య స్వామి దర్శనం."),
    ("WORD-011", "దేవసేన", "అమ్మవారు శ్రీ దేవసేన సమేతంగా దర్శనమిచ్చును."),
    ("WORD-012", "అభిషేకం", "నాగేంద్రునికి పంచామృత అభిషేకం నిర్వహించబడును.")
]

def seed_default_tasks_for_user(user_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM tasks WHERE user_id = ?", (user_id,))
    if cursor.fetchone()[0] == 0:
        now = time.time()
        # Task 1: 12-Word Voice Improvement Task
        t1_id = f"TASK-{uuid.uuid4().hex[:5].upper()}"
        cursor.execute(
            """INSERT INTO tasks (id, user_id, task_type, title, description, status, total_items, completed_items, due_date, created_at, updated_at)
               VALUES (?, ?, 'VOICE_IMPROVEMENT', '🎙 Voice Improvement', 'Record 12 required temple words to calibrate and improve your voice model.', 'NEW', 12, 0, 'Due Today', ?, ?)""",
            (t1_id, user_id, now, now)
        )
        for idx, (w_id, word, sentence) in enumerate(DEFAULT_TEMPLE_TRAINING_WORDS):
            item_id = f"ITEM-{t1_id}-{idx+1:02d}"
            cursor.execute(
                """INSERT INTO task_items (id, task_id, word_id, target_text, sentence_context, status, created_at, updated_at)
                   VALUES (?, ?, ?, ?, ?, 'PENDING', ?, ?)""",
                (item_id, t1_id, w_id, word, sentence, now, now)
            )

        # Task 2: Recording Retake Task (3 words)
        t2_id = f"TASK-{uuid.uuid4().hex[:5].upper()}"
        cursor.execute(
            """INSERT INTO tasks (id, user_id, task_type, title, description, status, total_items, completed_items, due_date, created_at, updated_at)
               VALUES (?, ?, 'RECORDING_RETAKE', '🔄 Recording Retake', 'Retake 3 high-importance sacred words with optimal clarity.', 'NEW', 3, 0, 'Due Today', ?, ?)""",
            (t2_id, user_id, now, now)
        )
        for idx, (w_id, word, sentence) in enumerate(DEFAULT_TEMPLE_TRAINING_WORDS[:3]):
            item_id = f"ITEM-{t2_id}-{idx+1:02d}"
            cursor.execute(
                """INSERT INTO task_items (id, task_id, word_id, target_text, sentence_context, status, created_at, updated_at)
                   VALUES (?, ?, ?, ?, ?, 'PENDING', ?, ?)""",
                (item_id, t2_id, w_id, word, sentence, now, now)
            )
        conn.commit()
    conn.close()

def get_user_tasks(user_id: str, status_filter: Optional[str] = None) -> List[Dict[str, Any]]:
    seed_default_tasks_for_user(user_id)
    conn = get_db()
    cursor = conn.cursor()
    if status_filter and status_filter.upper() != 'ALL':
        cursor.execute(
            "SELECT * FROM tasks WHERE user_id = ? AND status = ? ORDER BY created_at DESC",
            (user_id, status_filter.upper())
        )
    else:
        cursor.execute(
            "SELECT * FROM tasks WHERE user_id = ? ORDER BY created_at DESC",
            (user_id,)
        )
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def get_task_details(task_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM tasks WHERE id = ?", (task_id,))
    task_row = cursor.fetchone()
    if not task_row:
        conn.close()
        return None
    task = dict(task_row)
    cursor.execute("SELECT * FROM task_items WHERE task_id = ? ORDER BY id ASC", (task_id,))
    items = [dict(r) for r in cursor.fetchall()]
    task["items"] = items
    conn.close()
    return task

def submit_task_item_audio(
    task_id: str,
    item_id: str,
    user_id: str,
    audio_path: str,
    target_text: str,
    pronunciation_score: float = 95.0,
    audio_quality: str = "🟢 Good",
    is_accepted: bool = True
) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    audio_id = f"AUD-{uuid.uuid4().hex[:6].upper()}"
    status = "ACCEPTED" if is_accepted else "RETAKE"

    cursor.execute(
        """UPDATE task_items 
           SET status = ?, audio_id = ?, audio_path = ?, pronunciation_score = ?, audio_quality_score = ?, updated_at = ?
           WHERE id = ?""",
        (status, audio_id, audio_path, pronunciation_score, audio_quality, now, item_id)
    )

    # Save to voice_training_samples
    user = get_user_by_id(user_id)
    voice_id = user.get("assigned_voice_id", "voice_te_male_1") if user else "voice_te_male_1"
    sample_id = f"SMPL-{uuid.uuid4().hex[:6].upper()}"
    cursor.execute(
        """INSERT INTO voice_training_samples (id, voice_id, word_text, audio_path, acoustic_features, created_at)
           VALUES (?, ?, ?, ?, ?, ?)""",
        (sample_id, voice_id, target_text, audio_path, json.dumps({"quality": audio_quality, "p_score": pronunciation_score}), now)
    )

    # Recalculate completed items on task
    cursor.execute("SELECT COUNT(*) FROM task_items WHERE task_id = ? AND status = 'ACCEPTED'", (task_id,))
    completed = cursor.fetchone()[0]
    cursor.execute("SELECT total_items FROM tasks WHERE id = ?", (task_id,))
    total_row = cursor.fetchone()
    total = total_row[0] if total_row else 12

    task_status = "COMPLETED" if completed >= total else ("IN_PROGRESS" if completed > 0 else "NEW")
    cursor.execute(
        "UPDATE tasks SET completed_items = ?, status = ?, updated_at = ? WHERE id = ?",
        (completed, task_status, now, task_id)
    )
    conn.commit()
    conn.close()

    # If task completed, check if we can advance voice model version
    if task_status == "COMPLETED":
        advance_voice_version_if_ready(voice_id, user_id)

    return {
        "success": True,
        "audio_id": audio_id,
        "status": status,
        "completed_items": completed,
        "total_items": total,
        "task_status": task_status
    }

def advance_voice_version_if_ready(voice_id: str, user_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute("SELECT * FROM voice_versions WHERE voice_id = ? ORDER BY created_at DESC", (voice_id,))
    versions = cursor.fetchall()
    latest_ver_num = "v1.0"
    if versions:
        latest_ver_num = versions[0]["version_num"]
    
    try:
        major, minor = latest_ver_num.replace("v", "").split(".")
        next_ver = f"v{major}.{int(minor) + 1}"
    except Exception:
        next_ver = "v1.1"

    new_ver_id = f"ver_{voice_id[:6]}_{next_ver.replace('.', '_')}_{uuid.uuid4().hex[:4]}"
    cursor.execute(
        "INSERT INTO voice_versions (id, voice_id, version_num, model_path, quality_score, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (new_ver_id, voice_id, next_ver, None, "🟢 Approved (96%)", "APPROVED", now)
    )
    assign_id = f"ASN-{uuid.uuid4().hex[:6].upper()}"
    cursor.execute(
        "INSERT INTO user_voice_assignments (id, user_id, voice_id, assigned_version_id, created_at) VALUES (?, ?, ?, ?, ?)",
        (assign_id, user_id, voice_id, new_ver_id, now)
    )
    conn.commit()
    conn.close()
    return {"version_id": new_ver_id, "version_num": next_ver, "voice_id": voice_id}

def get_user_profile_summary(user_id: str) -> Dict[str, Any]:
    seed_default_tasks_for_user(user_id)
    user = get_user_by_id(user_id)
    if not user:
        user = {
            "id": user_id,
            "name": "Mopidevi Operator",
            "role": "operator",
            "status": "Active",
            "assigned_voice_id": "voice_te_male_1"
        }
    voice_id = user.get("assigned_voice_id", "voice_te_male_1") or "voice_te_male_1"
    voice = get_voice_profile_by_id(voice_id)
    voice_name = voice["voice_name"] if voice else "తెలుగు గుడి ప్రకటనా స్వరము 2"

    versions = list_voice_versions(voice_id)
    active_version = versions[0]["version_num"] if versions else "v1.0"

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM tasks WHERE user_id = ? AND status IN ('NEW', 'IN_PROGRESS', 'RETAKE_REQUIRED')", (user_id,))
    pending_tasks_count = cursor.fetchone()[0]
    conn.close()

    return {
        "user_id": user["id"],
        "name": user["name"],
        "role": user["role"],
        "status": user["status"],
        "assigned_voice_id": voice_id,
        "voice_name": voice_name,
        "active_version": active_version,
        "voice_status": "🟢 Ready",
        "pending_tasks_count": pending_tasks_count
    }

def record_announcement_history(
    job_id: str,
    user_id: str,
    voice_id: str,
    voice_name: str,
    title: str,
    script_text: str,
    style: str,
    output_audio_path: str,
    duration_seconds: float = 0.0
) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    hist_id = f"HIST-{uuid.uuid4().hex[:6].upper()}"
    cursor.execute(
        """INSERT INTO announcement_history (id, job_id, user_id, voice_id, voice_name, title, script_text, style, output_audio_path, duration_seconds, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (hist_id, job_id, user_id, voice_id, voice_name, title, script_text, style, output_audio_path, duration_seconds, now)
    )
    conn.commit()
    conn.close()
    return {"id": hist_id, "job_id": job_id, "created_at": now}

def get_user_announcement_history(user_id: str) -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT * FROM announcement_history WHERE user_id = ? ORDER BY created_at DESC",
        (user_id,)
    )
    rows = cursor.fetchall()
    conn.close()
    
    now = time.time()
    results = []
    for r in rows:
        d = dict(r)
        created_time = d["created_at"]
        diff_days = (now - created_time) / 86400.0
        if diff_days < 1:
            d["date_group"] = "Today"
        elif diff_days < 2:
            d["date_group"] = "Yesterday"
        else:
            d["date_group"] = "Older"
        results.append(d)
    return results

# Run database init on import
init_db()


