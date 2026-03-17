# <img src="https://cdn-icons-png.flaticon.com/512/4712/4712027.png" width="32"/> IsraelAI

**The most advanced AI chatbot for Roblox executors.**

IsraelAI is a full-featured AI assistant that runs inside Roblox. One script, paste and execute — get an AI chatbot, Linux terminal, player tracker, OSINT tool, auto-reply system, code generator, and more.

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/74jTp5VY5V)

---

## ⚡ Quick Start

**1. Get a free API key** from [console.groq.com/keys](https://console.groq.com/keys) (takes 30 seconds)

**2. Execute in your executor:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/slovichenia/israelAI/main/IsraelAI_v7.lua"))()
```

**3. Paste your API key when prompted. Done.**

---

## 🔥 Features

### 💬 AI Chat
- Talk to AI naturally inside Roblox
- Powered by Groq (free), OpenAI, Claude, DeepSeek, or Grok — auto-detects from your key
- Memory system — tell it things and it remembers across sessions
- Copy and Export buttons on every response

### 🤖 Auto-Reply
- AI responds to nearby players in game chat automatically
- Smart detection — only replies when someone is talking TO you (uses facing direction, proximity, name mentions, question detection)
- Scoring system prevents spam in crowded servers
- Works in any language — responds in whatever language the other person speaks
- Control it from chat: "stop saying lol", "focus on Xavier", "act like a cop"

### 🗣️ Say/Tell Commands
- `"say hi to them"` — AI generates and sends a message in game chat
- `"tell Xavier about quantum physics"` — talks to a specific player
- `"answer that cop's questions"` — reads chat context and responds appropriately
- `"talk to MrJ"` — starts continuous conversation with that player

### 🔍 OSINT
- `"osint PlayerName"` — full player lookup
- Username, Display Name, User ID, Account Age
- Premium status, Team, Health, Speed, Position
- Inventory, Friend status, Follow status
- New account warnings

### 👥 Players Tab
- Live-updating player list with search bar
- Account age, team, premium status, HP
- Full chat log per player (scrollable)
- Auto-refreshes every 3 seconds

### 📺 Screen Reader
- Reads nearby signs, billboards, and SurfaceGuis
- Triggers naturally: "what does that sign say?", "read that billboard"
- Reports text content, colors, and distance

### 💻 Code Tab
- Describe what you need, AI writes the code
- Auto-detects language (Lua, Python, JS, HTML, Bash)
- Copy and Export buttons on every code block
- Warns if your AI model might struggle with complex code

### 🖥️ Linux Terminal
- Full Linux shell via cloud API
- Persistent working directory (`cd` works)
- Git, Python, Node.js, and more
- Requires a free Replit server (setup below)

### 📦 Packages
- Installable personality/behavior modifiers
- **GenZ Slang** — brainrot, "no cap", "fr fr"
- **Formal Mode** — professional English
- **Pirate Talk** — arr matey!
- **Code Expert** — always includes code examples
- **Friendly Roaster** — playful roasts
- **Emoji Mode** — heavy emoji usage
- **Ultra Short** — under 30 words always
- **Teacher Mode** — step-by-step explanations
- **Multi-Language** *(premium)* — auto-detects and responds in any language
- Packages persist across sessions

### 🧠 Memory
- Tell the AI things and it remembers: "my name is Jake", "I like racing games"
- Memory persists across games and sessions
- Saved to local file, loads automatically
- Clear memory anytime in Settings

---

## 🛠️ Setup

### Basic Setup (AI Chat only)
1. Get a free API key from [console.groq.com/keys](https://console.groq.com/keys)
2. Execute the script in your executor
3. Paste your key when prompted
4. Start chatting

### Terminal Setup (optional)
The Linux terminal requires a small server running on Replit (free):

1. Go to [replit.com](https://replit.com) → Create new Repl → Python
2. Paste the contents of `IsraelAI_Server.py` into `main.py`
3. In Replit's shell, run: `pip install flask`
4. Click **Run**
5. Copy your Replit URL (looks like `https://your-project.replit.dev`)
6. In IsraelAI → Settings → Terminal Server → paste URL + key (`israelai123`)
7. Click Save

**Important:** Change the `SECRET_KEY` in the Python file to something unique, and use that same key in IsraelAI settings.

---

## 🎮 Supported Executors

Works with any executor that supports:
- `http_request` or `syn.request` or `request` or `fluxus.request`
- `writefile` / `readfile` / `isfile` (for saving settings)
- `setclipboard` (for copy features)

Tested on: **Wave, Synapse, Fluxus, KRNL, Arceus X, Delta**

---

## 🔑 Supported AI Providers

| Provider | Free? | Key Prefix | Model |
|----------|-------|-----------|-------|
| **Groq** | ✅ Free | `gsk_` | llama-3.3-70b |
| **OpenAI** | Paid | `sk-` | gpt-4o-mini |
| **Claude** | Paid | contains `ant` | claude-sonnet |
| **Grok** | Paid | `xai-` | grok-3-mini |
| **DeepSeek** | Paid | `sk-` | deepseek-chat |

Auto-detected from key prefix — just paste any key and it works.

---

## 📁 Files

| File | What it is |
|------|-----------|
| `IsraelAI_v7.lua` | Main script — execute this in Roblox |
| `IsraelAI_Server.py` | Terminal server — host on Replit (optional) |

---

## 💬 Commands

| Command | What it does |
|---------|-------------|
| `osint PlayerName` | Full player lookup |
| `say hi to them` | Send message in game chat |
| `tell Xavier about X` | Talk to specific player |
| `talk to PlayerName` | Start continuous conversation |
| `answer that guy` | Respond to nearby player |
| `stop saying X` | Control auto-reply behavior |
| `focus on PlayerName` | Auto-reply focuses on one player |
| `act like a cop` | Change auto-reply persona |
| `remember my name is X` | Save to memory |

---

## 🔗 Links

- **Discord:** [discord.gg/74jTp5VY5V](https://discord.gg/74jTp5VY5V)

---

## ⚠️ Disclaimer

This tool is for educational and entertainment purposes. Use responsibly. The developers are not responsible for any actions taken with this tool. Using executors may violate Roblox's Terms of Service.

---

*Made with ❤️ by the IsraelAI team*
