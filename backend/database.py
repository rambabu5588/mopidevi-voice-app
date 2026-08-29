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
            ("USR-00001", "AUTH-00002", "PROF-00002", "Temple Operator 1", "operator1@mopidevi.org", "operator", "Active", "User$1234", "voice_te_male_1", now),
            ("USR-00002", "AUTH-00003", "PROF-00003", "Temple Operator 2", "operator2@mopidevi.org", "operator", "Active", "User$1234", "voice_te_male_1", now),
            ("manager_01", "AUTH-00004", "PROF-00004", "Voice Manager", "manager@mopidevi.org", "voice_manager", "Active", "User$1234", "voice_te_female_1", now),
            ("operator_01", "AUTH-00005", "PROF-00005", "Sri Venkateswara Rao (Operator)", "venkat@mopidevi.org", "operator", "Active", "User$1234", "voice_te_male_1", now),
            ("operator_02", "AUTH-00006", "PROF-00006", "Sri Subrahmanyam (Operator)", "subbu@mopidevi.org", "operator", "Active", "User$1234", "voice_te_male_1", now)
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
    cursor.execute("SELECT password FROM users WHERE id = ?", (user_id.strip(),))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return {"success": False, "message": "User not found"}
    
    stored_password = row[0] if row[0] is not None else ""
    if stored_password != current_password.strip():
        conn.close()
        return {"success": False, "message": "Current password does not match"}
    
    # Save exact plain-text password into database
    cursor.execute("UPDATE users SET password = ? WHERE id = ?", (new_password.strip(), user_id.strip()))
    conn.commit()
    conn.close()
    return {"success": True, "message": "Password changed successfully"}

def record_user_logout(user_id: str):
    conn = get_db()
    cursor = conn.cursor()
    now = time.time()
    cursor.execute("UPDATE users SET last_logout_at = ? WHERE id = ?", (now, user_id.strip()))
    conn.commit()
    conn.close()

def authenticate_user(username_or_id: str, password: str) -> Optional[Dict[str, Any]]:
    now = time.time()
    # Root admin check
    if (username_or_id.strip() == "sid" or username_or_id.strip() == "user_default") and password.strip() == "Siddhu$1999":
        conn = get_db()
        cursor = conn.cursor()
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
    
    conn = get_db()
    cursor = conn.cursor()
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

# Run database init on import
init_db()


