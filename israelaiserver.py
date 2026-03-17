"""
IsraelAI Terminal Server v2
- Persistent working directory (cd works)
- Full Linux commands
- Git clone with storage
- Session tracking

Update your Replit main.py with this.
"""
from flask import Flask, request, jsonify
import subprocess, os, re, shutil

app = Flask(__name__)
SECRET_KEY = "israelai123"

# Persistent state per session
sessions = {}
HOME = os.path.expanduser("~")

# Ensure a workspace folder exists for storage
WORKSPACE = os.path.join(HOME, "workspace")
os.makedirs(WORKSPACE, exist_ok=True)

def get_session(sid):
    if sid not in sessions:
        sessions[sid] = {"cwd": WORKSPACE}
    return sessions[sid]

def strip_ansi(text):
    return re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])').sub('', text)

@app.route("/", methods=["GET"])
def home():
    # Show disk usage
    total, used, free = shutil.disk_usage(HOME)
    return jsonify({
        "status": "ok",
        "storage": {
            "total_mb": round(total / 1024 / 1024),
            "used_mb": round(used / 1024 / 1024),
            "free_mb": round(free / 1024 / 1024)
        }
    })

@app.route("/run", methods=["POST"])
def run():
    data = request.json
    if not data or data.get("key") != SECRET_KEY:
        return jsonify({"error": "Invalid key"}), 403
    
    cmd = data.get("cmd", "").strip()
    sid = data.get("session", "default")
    if not cmd:
        return jsonify({"error": "No command"}), 400
    
    # Block dangerous commands
    for b in ["rm -rf /", "mkfs", ":()", "fork bomb", "dd if=/dev"]:
        if b in cmd.lower():
            return jsonify({"error": "Blocked"}), 403
    
    session = get_session(sid)
    cwd = session["cwd"]
    
    # Make sure cwd still exists
    if not os.path.isdir(cwd):
        cwd = WORKSPACE
        session["cwd"] = cwd
    
    # Handle 'cd' specially — it needs to persist
    if cmd.strip().startswith("cd "):
        target = cmd.strip()[3:].strip()
        # Expand ~ and env vars
        target = os.path.expanduser(target)
        target = os.path.expandvars(target)
        
        if not os.path.isabs(target):
            target = os.path.join(cwd, target)
        target = os.path.realpath(target)
        
        if os.path.isdir(target):
            session["cwd"] = target
            return jsonify({"stdout": "", "stderr": "", "code": 0, "cwd": target})
        else:
            return jsonify({"stdout": "", "stderr": f"cd: {target}: No such directory", "code": 1, "cwd": cwd})
    
    # Handle bare 'cd' — go to workspace
    if cmd.strip() == "cd":
        session["cwd"] = WORKSPACE
        return jsonify({"stdout": "", "stderr": "", "code": 0, "cwd": WORKSPACE})
    
    # Handle 'pwd'
    if cmd.strip() == "pwd":
        return jsonify({"stdout": cwd + "\n", "stderr": "", "code": 0, "cwd": cwd})
    
    # Special: show storage info
    if cmd.strip() == "storage" or cmd.strip() == "disk":
        total, used, free = shutil.disk_usage(HOME)
        out = f"Storage:\n  Total: {total // (1024*1024)} MB\n  Used:  {used // (1024*1024)} MB\n  Free:  {free // (1024*1024)} MB\n  Path:  {cwd}\n"
        return jsonify({"stdout": out, "stderr": "", "code": 0, "cwd": cwd})
    
    try:
        env = os.environ.copy()
        env["TERM"] = "dumb"
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["HOME"] = HOME
        
        # Wrap command to cd into the right directory first
        full_cmd = f"cd {cwd} && {cmd}"
        
        result = subprocess.run(
            full_cmd, shell=True, capture_output=True, text=True,
            timeout=60,  # 60 second timeout for git clones etc
            env=env
        )
        
        out = strip_ansi(result.stdout)[:6000]
        err = strip_ansi(result.stderr)[:3000]
        
        # For git and similar, stderr has useful info
        combined = out
        if err:
            # If stderr has content and stdout is empty, show stderr
            if not out.strip():
                combined = err
            # If stderr has errors/warnings, append
            elif any(w in err.lower() for w in ["error", "fatal", "warning", "cloning", "resolving", "receiving", "unpacking"]):
                combined = out + ("\n" if out.strip() else "") + err
        
        # Check if the command might have changed directory via subshell
        # (won't work for && chains, but covers basic cases)
        
        return jsonify({
            "stdout": combined if combined.strip() else "(no output)",
            "stderr": "",
            "code": result.returncode,
            "cwd": cwd
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Timeout (60s)"}), 408
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/upload", methods=["POST"])
def upload():
    """Upload a file to the workspace"""
    data = request.json
    if not data or data.get("key") != SECRET_KEY:
        return jsonify({"error": "Invalid key"}), 403
    
    filename = data.get("filename", "")
    content = data.get("content", "")
    sid = data.get("session", "default")
    
    if not filename:
        return jsonify({"error": "No filename"}), 400
    
    session = get_session(sid)
    filepath = os.path.join(session["cwd"], filename)
    
    try:
        with open(filepath, "w") as f:
            f.write(content)
        return jsonify({"status": "ok", "path": filepath})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/download", methods=["POST"])
def download():
    """Read a file from the workspace"""
    data = request.json
    if not data or data.get("key") != SECRET_KEY:
        return jsonify({"error": "Invalid key"}), 403
    
    filename = data.get("filename", "")
    sid = data.get("session", "default")
    
    if not filename:
        return jsonify({"error": "No filename"}), 400
    
    session = get_session(sid)
    filepath = os.path.join(session["cwd"], filename)
    
    try:
        with open(filepath, "r") as f:
            content = f.read()[:10000]  # Cap at 10KB
        return jsonify({"content": content, "path": filepath})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print(f"IsraelAI Terminal Server v2")
    print(f"Workspace: {WORKSPACE}")
    print(f"Storage: {shutil.disk_usage(HOME).free // (1024*1024)} MB free")
    app.run(host="0.0.0.0", port=8080)
