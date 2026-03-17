--[[
    IsraelAI v7 — Memory + Logic + Copy/Export + Anti-Filter
    Free AI: https://console.groq.com/keys
    Terminal: host IsraelAI_Server.py on Replit
--]]

--═══ FILESYS ═══
local HS=game:GetService("HttpService")
local wf,rf,fe
pcall(function() wf = writefile end)
pcall(function() if not wf and syn then wf = syn.write_file end end)
pcall(function() rf = readfile end)
pcall(function() if not rf and syn then rf = syn.read_file end end)
pcall(function() fe = isfile end)
pcall(function() if not fe and syn then fe = syn.is_file end end)
local function sav(d) pcall(function() if wf then wf("israelai.json",HS:JSONEncode(d)) end end) end
local function loadCfg() local o,r=pcall(function() if fe and rf and fe("israelai.json") then return HS:JSONDecode(rf("israelai.json")) end end) return o and r or{} end
-- Memory file
local function saveMem(m) pcall(function() if wf then wf("israelai_memory.json",HS:JSONEncode(m)) end end) end
local function loadMem() local o,r=pcall(function() if fe and rf and fe("israelai_memory.json") then return HS:JSONDecode(rf("israelai_memory.json")) end end) return o and r or{} end

local cfg=loadCfg() local API_KEY=cfg.key or"" local AUTO_REPLY=cfg.autoReply or false local TERM_URL=cfg.termUrl or"" local TERM_KEY=cfg.termKey or""
local memory=loadMem()
if not memory.facts then memory.facts={} end

-- PACKAGES SYSTEM — personality/behavior modifiers that persist
local function savePkgs(p) pcall(function() if wf then wf("israelai_packages.json",HS:JSONEncode(p)) end end) end
local function loadPkgs() local o,r=pcall(function() if fe and rf and fe("israelai_packages.json") then return HS:JSONDecode(rf("israelai_packages.json")) end end) return o and r or{} end

local installedPkgs = loadPkgs()
if type(installedPkgs) ~= "table" then installedPkgs = {} end

-- Available packages catalog
local PKG_CATALOG = {
    {id="genz", name="GenZ Slang", desc="Responds with Gen Z slang, brainrot, and internet culture",
        prompt="Use Gen Z slang heavily. Say things like 'no cap', 'fr fr', 'bussin', 'slay', 'based', 'lowkey', 'highkey', 'rizz', 'gyatt', 'skibidi', 'fanum tax', 'sigma', 'aura'. Talk like a zoomer. Use abbreviations like 'ngl', 'tbh', 'imo', 'idk'. Be casual and funny."},
    {id="formal", name="Formal Mode", desc="Professional, formal English responses",
        prompt="Respond in formal, professional English. Use proper grammar, full sentences, and a polite tone. Avoid slang, contractions, and casual language."},
    {id="pirate", name="Pirate Talk", desc="Responds like a pirate",
        prompt="Talk like a pirate! Use 'arr', 'matey', 'ye', 'landlubber', 'walk the plank', 'shiver me timbers'. Replace 'my' with 'me', 'you' with 'ye'. Be dramatic and nautical."},
    {id="coder", name="Code Expert", desc="Always includes code examples and technical details",
        prompt="Always include code examples when relevant. Use technical terminology. Format code clearly. Explain concepts with Lua/Python/JS examples. Be precise and technical."},
    {id="roaster", name="Friendly Roaster", desc="Playfully roasts while still being helpful",
        prompt="Be playfully sarcastic and roast the user lightly while still being helpful. Add friendly burns and jokes. Think of it like roasting a friend — never mean, always funny."},
    {id="emoji", name="Emoji Mode", desc="Heavy emoji usage in every response",
        prompt="Use LOTS of emojis in every response. At least 3-5 emojis per message. Make responses feel expressive and fun."},
    {id="short", name="Ultra Short", desc="Extremely concise responses, under 30 words",
        prompt="Keep ALL responses under 30 words. Be extremely concise. No fluff. Get straight to the point. One or two sentences max."},
    {id="teacher", name="Teacher Mode", desc="Explains things step by step like a patient teacher",
        prompt="Explain everything step by step like a patient teacher. Use analogies, examples, and break complex things into simple parts. Ask if the user understands."},
    {id="multilang", name="Multi-Language", desc="Auto-detects and responds in any language", paid=true,
        price="$2.99", payUrl="",
        prompt="IMPORTANT: Detect what language the user is speaking and ALWAYS respond in that SAME language. If they write in Spanish, respond entirely in Spanish. If French, respond in French. If Arabic, respond in Arabic. Match their language perfectly. If they mix languages, use their dominant language."},
}

local PAYMENT_LINK = "" -- Set your payment link here

local function getActivePackagePrompts()
    local prompts = {}
    for _, pkg in ipairs(PKG_CATALOG) do
        if installedPkgs[pkg.id] then
            prompts[#prompts+1] = pkg.prompt
        end
    end
    return table.concat(prompts, "\n")
end

local function getProv() if API_KEY=="" then return"Groq","https://api.groq.com/openai/v1/chat/completions","llama-3.3-70b-versatile" end local k=API_KEY if k:sub(1,4)=="xai-" then return"Grok","https://api.x.ai/v1/chat/completions","grok-3-mini" elseif k:find("ant") then return"Claude","https://api.anthropic.com/v1/messages","claude-sonnet-4-20250514" elseif k:sub(1,3)=="sk-" then return"OpenAI","https://api.openai.com/v1/chat/completions","gpt-4o-mini" else return"Groq","https://api.groq.com/openai/v1/chat/completions","llama-3.3-70b-versatile" end end

-- IMPROVED SYSTEM PROMPT — with memory + logic
local function buildSystemPrompt()
    local memStr = ""
    if #memory.facts > 0 then
        memStr = "\n\nMEMORY — Things you remember about this user:\n"
        for i, f in ipairs(memory.facts) do
            if i > 15 then break end
            memStr = memStr .. "- " .. f .. "\n"
        end
    end
    
    local base = [=[You are IsraelAI, a smart and logical AI assistant inside Roblox.

THINKING PROCESS:
1. Read the question carefully
2. Consider what you know and what context is provided
3. Think step by step if the question requires reasoning
4. Give a clear, accurate answer

RULES:
- Be concise but thorough (under 200 words)
- If you don't know something, say so honestly
- When given OSINT data, analyze patterns and connections
- When given sign/screen data, describe the place naturally
- When given chat data, understand the conversation context
- Remember facts the user tells you about themselves
- If the user says "remember X" or tells you personal info, acknowledge it

MEMORY INSTRUCTIONS:
If the user tells you something personal (name, age, preferences, facts about themselves), include [REMEMBER: fact] at the END of your response so the system can save it. Only do this for genuinely personal/important facts, not every message.
Example: If user says "my name is Jake", end response with [REMEMBER: User's name is Jake]]=] .. memStr
    
    local pkgStr = getActivePackagePrompts()
    if pkgStr ~= "" then
        base = base .. "\n\nACTIVE STYLE PACKAGES:\n" .. pkgStr
    end
    return base
end

local AUTO_SYS=[[You are pretending to be a real Roblox player. You ARE the player. You are NOT an AI assistant.

RULES:
- Talk like a real person your age playing Roblox
- Keep messages SHORT (under 20 words)
- NEVER repeat what you already said — check the conversation history
- NEVER ask the same question twice
- NEVER say "How can I help" or "Is there anything" — real players don't say that
- Use varied responses — if you said "lol" before, say something different
- React naturally to what people say — laugh, agree, disagree, joke around
- If someone says something weird, react like a real person would
- Match the vibe — if they're being funny, be funny back
- Respond in the SAME LANGUAGE the other person is speaking
- If you already greeted someone, don't greet them again — continue the conversation

PERSONA INSTRUCTIONS (from your owner, follow these):
{{INSTRUCTIONS}}]]

-- Auto-reply persistent conversation history (remembers what it said)
local autoConv = {}
local autoInstructions = "" -- User commands like "stop saying lol", "focus on X"

local function callAutoReply(sn, sm)
    local sys = AUTO_SYS:gsub("{{INSTRUCTIONS}}", autoInstructions ~= "" and autoInstructions or "None — just be a normal player.")
    
    -- Build FULL chat log context (last 60 messages or all if less)
    local chatLines = {}
    local logCount = math.min(60, #fullChatLog)
    for i = math.max(1, #fullChatLog - logCount + 1), #fullChatLog do
        chatLines[#chatLines+1] = "["..fullChatLog[i].t.."] "..fullChatLog[i].w..": "..fullChatLog[i].m
    end
    local chatContext = #chatLines > 0 and table.concat(chatLines, "\n") or "(no chat yet)"
    
    -- Add to persistent auto-reply conversation
    table.insert(autoConv, {role="user", content=sn..": "..sm})
    while #autoConv > 20 do table.remove(autoConv, 1) end
    
    -- Build messages
    local msgs = {}
    for _, m in ipairs(autoConv) do msgs[#msgs+1] = {role=m.role, content=m.content} end
    
    -- Append full context to latest message
    msgs[#msgs].content = msgs[#msgs].content ..
        "\n\n[FULL GAME CHAT LOG since you joined — READ THIS to understand context]:\n" .. chatContext ..
        "\n\n[GAME]: "..gameCtx()..
        "\n[YOU ARE]: "..plr.DisplayName..
        "\nRespond as "..plr.DisplayName..". Read the chat log above to understand what everyone is talking about. Give a response that makes sense in this conversation. Under 20 words. Do NOT repeat yourself."
    
    local ok, reply = callRaw(msgs, sys)
    if ok then
        table.insert(autoConv, {role="assistant", content=reply})
        while #autoConv > 20 do table.remove(autoConv, 1) end
    end
    return ok, reply
end
local httpReq
pcall(function() if syn then httpReq = syn.request end end)
pcall(function() if not httpReq and http then httpReq = http.request end end)
pcall(function() if not httpReq then httpReq = http_request end end)
pcall(function() if not httpReq and fluxus then httpReq = fluxus.request end end)
pcall(function() if not httpReq then httpReq = request end end)
local P=game:GetService("Players") local TS=game:GetService("TweenService") local UIS=game:GetService("UserInputService") local RS=game:GetService("RunService") local SG=game:GetService("StarterGui")
local plr=P.LocalPlayer local pGui=plr:WaitForChild("PlayerGui")
if pGui:FindFirstChild("IsraelAI") then pGui.IsraelAI:Destroy() end

-- Save player name to memory
if not memory.playerName or memory.playerName ~= plr.Name then
    memory.playerName = plr.Name
    saveMem(memory)
end

--═══ ANTI-FILTER: send chat in chunks with delays ═══
local function sendGameChat(msg)
    -- Split into chunks under 100 chars to avoid filter
    local chunks = {}
    if #msg <= 90 then
        chunks = {msg}
    else
        -- Split at sentence boundaries
        local current = ""
        for sentence in msg:gmatch("[^%.!?]+[%.!?]?") do
            sentence = sentence:match("^%s*(.-)%s*$") -- trim
            if #current + #sentence + 1 > 90 then
                if current ~= "" then table.insert(chunks, current) end
                current = sentence
            else
                current = current == "" and sentence or (current .. " " .. sentence)
            end
        end
        if current ~= "" then table.insert(chunks, current) end
    end
    
    local sent = false
    for i, chunk in ipairs(chunks) do
        if i > 1 then task.wait(1.5) end -- delay between chunks
        pcall(function()
            local tcs = game:GetService("TextChatService")
            local ch = tcs:FindFirstChild("TextChannels")
            if ch then local g = ch:FindFirstChild("RBXGeneral") if g then g:SendAsync(chunk) sent = true end end
        end)
        if not sent then
            pcall(function()
                local re = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                if re then local f = re:FindFirstChild("SayMessageRequest") if f then f:FireServer(chunk, "All") sent = true end end
            end)
        end
    end
    return sent
end

--═══ COPY TO CLIPBOARD ═══
local function copyText(txt)
    pcall(function()
        if setclipboard then setclipboard(txt)
        elseif syn and syn.write_clipboard then syn.write_clipboard(txt)
        elseif toClipboard then toClipboard(txt) end
    end)
    pcall(function() SG:SetCore("SendNotification",{Title="IsraelAI",Text="Copied!",Duration=2}) end)
end

--═══ STRIP ANSI ═══
local function stripAnsi(s) if not s then return"" end return s:gsub('[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]',''):gsub('\27%[%d*;?%d*[A-Za-z]',''):gsub('%[%d*[A-Za-z]',''):gsub('\r','') end

--═══ TERMINAL ═══
local function runTerm(cmd) if TERM_URL==""or TERM_KEY=="" then return false,"Not configured. Set in Settings." end local ok,res=pcall(function() return httpReq({Url=TERM_URL:gsub("/$","").."/run",Method="POST",Headers={["Content-Type"]="application/json"},Body=HS:JSONEncode({key=TERM_KEY,cmd=cmd})}) end) if not ok then return false,"HTTP failed." end if res.StatusCode~=200 then local e="Error "..res.StatusCode pcall(function() local p=HS:JSONDecode(res.Body) if p.error then e=p.error end end) return false,e end local pO,pa=pcall(function() return HS:JSONDecode(res.Body) end) if not pO then return false,"Parse fail." end local out=stripAnsi(pa.stdout or"") if out=="" then out="(no output)" end return true,out,pa.code or 0 end

--═══ OSINT ═══
local function osint(tn) local t for _,p in ipairs(P:GetPlayers()) do if p.Name:lower()==tn:lower()or p.DisplayName:lower()==tn:lower()or p.Name:lower():find(tn:lower(),1,true) then t=p break end end if not t then return"Not found." end local r={"=== OSINT: "..t.Name.." ===","User: "..t.Name,"Display: "..t.DisplayName,"ID: "..t.UserId} pcall(function() local a=t.AccountAge r[#r+1]="Age: "..a.."d ("..math.floor(a/365).."y)" end) pcall(function() r[#r+1]="Premium: "..(t.MembershipType==Enum.MembershipType.Premium and"Y"or"N") end) pcall(function() r[#r+1]="Team: "..(t.Team and t.Team.Name or"None") end) pcall(function() local c=t.Character if c then local h=c:FindFirstChildOfClass("Humanoid") if h then r[#r+1]="HP:"..math.floor(h.Health).."/"..math.floor(h.MaxHealth).." Spd:"..h.WalkSpeed end local hr=c:FindFirstChild("HumanoidRootPart") if hr then local p=hr.Position r[#r+1]="Pos:"..math.floor(p.X)..","..math.floor(p.Y)..","..math.floor(p.Z) end end end) pcall(function() r[#r+1]="Friend:"..(t:IsFriendsWith(plr.UserId)and"Y"or"N") end) return table.concat(r,"\n") end

--═══ SCREEN/CHAT ═══
local function scanScreen() local c=plr.Character if not c or not c:FindFirstChild("HumanoidRootPart") then return"No character." end local root=c.HumanoidRootPart local f={} for _,d in ipairs(workspace:GetDescendants()) do pcall(function() if d:IsA("SurfaceGui")or d:IsA("BillboardGui") then local a=d.Adornee or d.Parent if a and a:IsA("BasePart")and(a.Position-root.Position).Magnitude<=80 then for _,ch in ipairs(d:GetDescendants()) do if(ch:IsA("TextLabel")or ch:IsA("TextButton"))and ch.Text and #ch.Text>1 and #ch.Text<300 then f[#f+1]='"'..ch.Text..'" ('..math.floor((a.Position-root.Position).Magnitude)..'m)' end end end end end) end return #f>0 and table.concat(f,"\n") or"No signs." end

local recentChat,proxChat={},{} local playerJoinTimes,playerChatLogs={},{}
local fullChatLog={} -- FULL log since script started, never trimmed (used by auto-reply)
local lastMsg={} -- dedup
local scriptStartTime = os.time()
for _,p in ipairs(P:GetPlayers()) do playerJoinTimes[p.Name]=scriptStartTime playerChatLogs[p.Name]={} end
P.PlayerAdded:Connect(function(p) playerJoinTimes[p.Name]=os.time() playerChatLogs[p.Name]={} end)

local function isNear(p,r) r=r or 50 local mc,tc=plr.Character,p.Character if not mc or not tc then return false end local mr,tr=mc:FindFirstChild("HumanoidRootPart"),tc:FindFirstChild("HumanoidRootPart") if not mr or not tr then return false end return(mr.Position-tr.Position).Magnitude<=r end

-- Central function to log a chat message (called from either source, deduped)
local function logChat(who, msg)
    local key = who .. ":" .. msg
    local now = tick()
    if lastMsg[key] and (now - lastMsg[key]) < 1.5 then return end
    lastMsg[key] = now
    
    local entry = {w = who, m = msg, t = os.date("%H:%M")}
    
    table.insert(recentChat, 1, entry)
    while #recentChat > 50 do table.remove(recentChat) end
    
    -- Full log — keep everything, cap at 500 to avoid memory issues
    table.insert(fullChatLog, {w = who, m = msg, t = os.date("%H:%M:%S")})
    while #fullChatLog > 500 do table.remove(fullChatLog, 1) end
    
    if not playerChatLogs[who] then playerChatLogs[who] = {} end
    table.insert(playerChatLogs[who], 1, {m = msg, t = os.date("%H:%M")})
    while #playerChatLogs[who] > 30 do table.remove(playerChatLogs[who]) end
    
    local sender = P:FindFirstChild(who)
    if sender and sender ~= plr and isNear(sender) then
        table.insert(proxChat, 1, {w = who, m = msg, t = tick()})
        while #proxChat > 10 do table.remove(proxChat) end
    end
end

local function hookPC(p)
    pcall(function() p.Chatted:Connect(function(m) logChat(p.Name, m) end) end)
end
for _,p in ipairs(P:GetPlayers()) do hookPC(p) end
P.PlayerAdded:Connect(hookPC)
pcall(function() game:GetService("TextChatService").MessageReceived:Connect(function(m)
    local w = m.TextSource and m.TextSource.Name
    if w then logChat(w, m.Text or "") end
end) end)

local function getChat() if #recentChat==0 then return"No chat." end local l={} for i=math.min(15,#recentChat),1,-1 do l[#l+1]=recentChat[i].w..": "..recentChat[i].m end return table.concat(l,"\n") end
local function gameCtx() local c={} pcall(function() c[#c+1]="Game:"..game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end) pcall(function() if plr.Team then c[#c+1]="Team:"..plr.Team.Name end end) pcall(function() local ch=plr.Character if ch and ch:FindFirstChild("HumanoidRootPart") then local p=ch.HumanoidRootPart.Position c[#c+1]="Pos:"..math.floor(p.X)..","..math.floor(p.Y)..","..math.floor(p.Z) end end) return table.concat(c,"; ") end

--═══ API ═══
local conv={} local usage={rem="?",lim="?"}
local function callRaw(msgs,sys) if not httpReq or API_KEY=="" then return false,"No key/HTTP." end local pN,url,model=getProv() local body,hdr if pN=="Claude" then body=HS:JSONEncode({model=model,max_tokens=512,messages=msgs,system=sys}) hdr={["Content-Type"]="application/json",["x-api-key"]=API_KEY,["anthropic-version"]="2023-06-01"} else local ms={{role="system",content=sys}} for _,m in ipairs(msgs) do ms[#ms+1]=m end body=HS:JSONEncode({model=model,messages=ms,max_tokens=512,temperature=0.7}) hdr={["Content-Type"]="application/json",["Authorization"]="Bearer "..API_KEY} end local ok,res=pcall(function() return httpReq({Url=url,Method="POST",Headers=hdr,Body=body}) end) if not ok then return false,"HTTP fail." end pcall(function() local h=res.Headers or res.headers or{} usage.rem=h["x-ratelimit-remaining-requests"]or h["X-RateLimit-Remaining-Requests"]or usage.rem usage.lim=h["x-ratelimit-limit-requests"]or h["X-RateLimit-Limit-Requests"]or usage.lim end) if res.StatusCode~=200 then local e="Err "..res.StatusCode pcall(function() local p=HS:JSONDecode(res.Body) if p.error and p.error.message then e=p.error.message end end) return false,e end local pO,pa=pcall(function() return HS:JSONDecode(res.Body) end) if not pO then return false,"Parse fail." end return true,pN=="Claude"and(pa.content and pa.content[1]and pa.content[1].text or"?")or(pa.choices and pa.choices[1]and pa.choices[1].message and pa.choices[1].message.content or"?") end

-- MEMORY EXTRACTION — pull [REMEMBER: X] from AI response and save
local function extractMemory(response)
    local clean = response
    for fact in response:gmatch("%[REMEMBER:%s*(.-)%]") do
        -- Save to memory
        local exists = false
        for _, f in ipairs(memory.facts) do
            if f:lower() == fact:lower() then exists = true break end
        end
        if not exists then
            table.insert(memory.facts, fact)
            while #memory.facts > 20 do table.remove(memory.facts, 1) end
            saveMem(memory)
        end
        -- Remove the tag from displayed response
        clean = clean:gsub("%[REMEMBER:%s*" .. fact:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%]", "")
    end
    return clean:match("^%s*(.-)%s*$") -- trim
end

local function callAI(msg)
    local lo=msg:lower() local ex=""
    
    -- AUTO-REPLY COMMANDS — intercept messages that control auto-reply behavior
    local autoCmd = false
    local autoCmdPatterns = {
        {"stop saying", "focus on", "dont say", "don't say", "when someone", "if someone", 
         "act like", "be more", "be less", "respond to", "ignore", "talk to", "reply to",
         "auto reply", "auto-reply", "autoreply", "persona", "pretend", "roleplay as"}
    }
    for _, patterns in ipairs(autoCmdPatterns) do
        for _, p in ipairs(patterns) do
            if lo:find(p, 1, true) and (lo:find("auto", 1, true) or lo:find("reply", 1, true) or lo:find("chat", 1, true) or lo:find("say", 1, true) or lo:find("act", 1, true) or lo:find("pretend", 1, true) or lo:find("respond", 1, true) or lo:find("persona", 1, true) or lo:find("focus", 1, true) or lo:find("ignore", 1, true) or lo:find("stop", 1, true)) then
                autoCmd = true
                break
            end
        end
        if autoCmd then break end
    end
    
    if autoCmd then
        -- Save as auto-reply instruction
        autoInstructions = msg
        -- Also clear auto conversation so it starts fresh with new instructions
        autoConv = {}
        trace("⚡ Auto-reply instruction: "..msg, C.Or)
    end
    
    -- Screen reader
    local st={"sign","billboard","text","read","what does","what do","say","written","poster","screen","around","near","see "}
    for _,s in ipairs(st) do if lo:find(s,1,true) then ex=ex.."\n[SIGNS]:\n"..scanScreen() break end end
    -- Chat reader
    local ct={"chat","said","asked","guy","person","someone","answer","question"} local cc=0
    for _,s in ipairs(ct) do if lo:find(s,1,true) then cc=cc+1 end end
    if cc>=2 then ex=ex.."\n[CHAT]:\n"..getChat() end
    -- OSINT
    local tgt=lo:match("osint%s+on%s+([%w_]+)")or lo:match("osint%s+([%w_]+)")or lo:match("who%s+is%s+([%w_]+)")
    if tgt then ex=ex.."\n[OSINT]:\n"..osint(tgt) end
    -- Game context
    local gc=gameCtx() if gc~="" then ex=ex.."\n[GAME]: "..gc end
    
    local full=ex~=""and(msg..ex)or msg
    table.insert(conv,{role="user",content=full}) while #conv>14 do table.remove(conv,1) end
    
    local ok,ai=callRaw(conv,buildSystemPrompt())
    if ok then
        -- Extract and save any memory tags
        ai = extractMemory(ai)
        table.insert(conv,{role="assistant",content=ai})
        while #conv>14 do table.remove(conv,1) end
    end
    return ok,ai
end

--═══ THEME ═══
local BT,PT=0.22,0.32
local C={Bg=Color3.fromRGB(20,20,24),Pn=Color3.fromRGB(28,28,32),Hd=Color3.fromRGB(34,34,38),Inp=Color3.fromRGB(38,38,44),Bd=Color3.fromRGB(58,58,65),Tx=Color3.fromRGB(200,200,206),Dm=Color3.fromRGB(130,130,140),Mt=Color3.fromRGB(85,85,95),Ft=Color3.fromRGB(60,60,68),Ac=Color3.fromRGB(90,140,220),Wh=Color3.fromRGB(220,220,226),BU=Color3.fromRGB(55,95,170),BA=Color3.fromRGB(38,38,44),Rd=Color3.fromRGB(180,60,60),Dc=Color3.fromRGB(88,101,242),Gn=Color3.fromRGB(72,199,130),Or=Color3.fromRGB(220,160,50)}
local W,H,MnW,MnH=800,520,620,380
local TH,UH,TAH,RW,IH,HH=30,20,26,220,42,24

local function tw(o,p,d) TS:Create(o,TweenInfo.new(d or 0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play() end
local function corner(p,r) if r and r>0 then local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end end
local function pad(p,t,r,b,l) local u=Instance.new("UIPadding") u.PaddingTop=UDim.new(0,t or 0) u.PaddingRight=UDim.new(0,r or t or 0) u.PaddingBottom=UDim.new(0,b or t or 0) u.PaddingLeft=UDim.new(0,l or r or t or 0) u.Parent=p end
local function hL(p,y) local f=Instance.new("Frame") f.Size=UDim2.new(1,0,0,1) f.Position=UDim2.new(0,0,0,y) f.BackgroundColor3=C.Bd f.BackgroundTransparency=0.5 f.BorderSizePixel=0 f.Parent=p end
local function vL(p,x) local f=Instance.new("Frame") f.Size=UDim2.new(0,1,1,0) f.Position=UDim2.new(0,x,0,0) f.BackgroundColor3=C.Bd f.BackgroundTransparency=0.5 f.BorderSizePixel=0 f.Parent=p end
local function L(pr) local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Text=pr.t or"" l.TextColor3=pr.c or C.Tx l.TextSize=pr.s or 12 l.Font=pr.f or Enum.Font.SourceSans l.TextXAlignment=pr.ax or Enum.TextXAlignment.Left l.TextWrapped=true l.RichText=pr.rich or false l.TextTruncate=pr.trunc and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None l.Size=pr.sz or UDim2.new(1,0,1,0) l.ClipsDescendants=true if pr.p then l.Position=pr.p end if pr.par then l.Parent=pr.par end return l end

--═══ GUI ═══
local gui=Instance.new("ScreenGui") gui.Name="IsraelAI" gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.DisplayOrder=100 gui.Parent=pGui
local tog=Instance.new("ImageButton") tog.Size=UDim2.new(0,36,0,36) tog.Position=UDim2.new(1,-50,1,-50) tog.BackgroundColor3=C.Bg tog.BackgroundTransparency=BT tog.Image="rbxassetid://103486408225648" tog.AutoButtonColor=false tog.BorderSizePixel=0 tog.Parent=gui corner(tog,8)
local win=Instance.new("Frame") win.Name="W" win.Size=UDim2.new(0,W,0,H) win.Position=UDim2.new(0.5,0,0.5,0) win.AnchorPoint=Vector2.new(0.5,0.5) win.BackgroundColor3=C.Bg win.BackgroundTransparency=BT win.Visible=false win.ClipsDescendants=true win.BorderSizePixel=0 win.Parent=gui corner(win,8)
local rz=Instance.new("TextButton") rz.Size=UDim2.new(0,16,0,16) rz.Position=UDim2.new(1,-16,1,-16) rz.BackgroundTransparency=1 rz.Text="◢" rz.TextSize=12 rz.TextColor3=C.Mt rz.Font=Enum.Font.SourceSans rz.AutoButtonColor=false rz.BorderSizePixel=0 rz.ZIndex=10 rz.Parent=win

-- TITLE BAR
local tb=Instance.new("Frame") tb.Size=UDim2.new(1,0,0,TH) tb.BackgroundColor3=C.Hd tb.BackgroundTransparency=PT tb.BorderSizePixel=0 tb.Parent=win hL(tb,TH-1)
local dragArea=Instance.new("TextButton") dragArea.Size=UDim2.new(1,0,1,0) dragArea.BackgroundTransparency=1 dragArea.Text="" dragArea.AutoButtonColor=false dragArea.ZIndex=1 dragArea.Parent=tb

local isOpen,isMax,isMin=false,false,false local preMaxSz,preMaxPos,preMinSz,preMinPos
local function mkTB(txt,x,hc) local b=Instance.new("TextButton") b.Size=UDim2.new(0,22,0,22) b.Position=UDim2.new(0,x,0.5,0) b.AnchorPoint=Vector2.new(0,0.5) b.BackgroundTransparency=1 b.Text=txt b.TextSize=14 b.TextColor3=C.Mt b.Font=Enum.Font.SourceSansBold b.AutoButtonColor=false b.BorderSizePixel=0 b.ZIndex=3 b.Parent=tb b.MouseEnter:Connect(function() b.TextColor3=hc end) b.MouseLeave:Connect(function() b.TextColor3=C.Mt end) return b end
local cBtn=mkTB("✕",6,C.Rd) local mBtn=mkTB("—",28,C.Wh) local xBtn=mkTB("□",50,C.Wh)
cBtn.MouseButton1Click:Connect(function() isOpen=false isMax=false isMin=false win.Visible=false end)

-- Minimize bubble (top of screen, draggable)
local minBubble=Instance.new("TextButton") minBubble.Size=UDim2.new(0,140,0,32) minBubble.Position=UDim2.new(0.5,0,0,6) minBubble.AnchorPoint=Vector2.new(0.5,0) minBubble.BackgroundColor3=C.Bg minBubble.BackgroundTransparency=BT minBubble.Text="" minBubble.AutoButtonColor=false minBubble.BorderSizePixel=0 minBubble.Visible=false minBubble.Parent=gui corner(minBubble,8)
local minLogo=Instance.new("ImageLabel") minLogo.Size=UDim2.new(0,20,0,20) minLogo.Position=UDim2.new(0,12,0.5,0) minLogo.AnchorPoint=Vector2.new(0,0.5) minLogo.BackgroundTransparency=1 minLogo.Image="rbxassetid://103486408225648" minLogo.Parent=minBubble
L({t="IsraelAI",s=12,c=C.Dm,f=Enum.Font.SourceSansSemibold,ax=Enum.TextXAlignment.Left,sz=UDim2.new(0,80,1,0),p=UDim2.new(0,36,0,0),par=minBubble})

-- Draggable minimize bubble
local minDragging,minDragSt,minStartPos=false,nil,nil
local minDragDist=0
minBubble.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        minDragging=true minDragSt=i.Position minStartPos=minBubble.Position minDragDist=0
    end
end)
minBubble.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        minDragging=false
        -- If barely moved, treat as click (restore window)
        if minDragDist<5 then
            isMin=false minBubble.Visible=false win.Visible=true
            win.Size=preMinSz or UDim2.new(0,W,0,H)
            win.Position=preMinPos or UDim2.new(0.5,0,0.5,0)
        end
    end
end)
UIS.InputChanged:Connect(function(i)
    if minDragging and i.UserInputType==Enum.UserInputType.MouseMovement and minDragSt and minStartPos then
        local d=i.Position-minDragSt
        minDragDist=math.abs(d.X)+math.abs(d.Y)
        minBubble.Position=UDim2.new(minStartPos.X.Scale,minStartPos.X.Offset+d.X,minStartPos.Y.Scale,minStartPos.Y.Offset+d.Y)
    end
end)

mBtn.MouseButton1Click:Connect(function()
    if not isMin then
        preMinSz=win.Size preMinPos=win.Position
        isMin=true win.Visible=false minBubble.Visible=true
    end
end)
xBtn.MouseButton1Click:Connect(function() if not isMax then preMaxSz=win.Size preMaxPos=win.Position isMax=true isMin=false win.Size=UDim2.new(1,0,1,0) win.Position=UDim2.new(0.5,0,0.5,0) xBtn.Text="❐" else isMax=false win.Size=preMaxSz or UDim2.new(0,W,0,H) win.Position=preMaxPos or UDim2.new(0.5,0,0.5,0) xBtn.Text="□" end end)

local lgT=Instance.new("ImageLabel") lgT.Size=UDim2.new(0,20,0,20) lgT.Position=UDim2.new(0.5,-40,0.5,0) lgT.AnchorPoint=Vector2.new(0.5,0.5) lgT.BackgroundTransparency=1 lgT.Image="rbxassetid://103486408225648" lgT.ZIndex=2 lgT.Parent=tb
L({t="IsraelAI",s=13,c=C.Dm,f=Enum.Font.SourceSansSemibold,ax=Enum.TextXAlignment.Center,sz=UDim2.new(0,70,1,0),p=UDim2.new(0.5,0,0,0),par=tb}).ZIndex=2

local dB=Instance.new("TextButton") dB.Size=UDim2.new(0,24,0,24) dB.Position=UDim2.new(1,-32,0.5,0) dB.AnchorPoint=Vector2.new(0,0.5) dB.BackgroundColor3=C.Dc dB.BackgroundTransparency=0.5 dB.Text="" dB.AutoButtonColor=false dB.BorderSizePixel=0 dB.ZIndex=3 dB.Parent=tb corner(dB,5)
local dI=Instance.new("ImageLabel") dI.Size=UDim2.new(0,16,0,16) dI.Position=UDim2.new(0.5,0,0.5,0) dI.AnchorPoint=Vector2.new(0.5,0.5) dI.BackgroundTransparency=1 dI.Image="rbxassetid://117638095097855" dI.ImageColor3=Color3.new(1,1,1) dI.ZIndex=4 dI.Parent=dB
dB.MouseEnter:Connect(function() tw(dB,{BackgroundTransparency=0.15},0.1) end) dB.MouseLeave:Connect(function() tw(dB,{BackgroundTransparency=0.5},0.1) end)
dB.MouseButton1Click:Connect(function() pcall(function() if setclipboard then setclipboard("https://discord.gg/74jTp5VY5V") end end) pcall(function() SG:SetCore("SendNotification",{Title="IsraelAI",Text="COPIED INVITE!",Duration=3}) end) end)

local arI=Instance.new("TextButton") arI.Size=UDim2.new(0,62,0,16) arI.Position=UDim2.new(1,-102,0.5,0) arI.AnchorPoint=Vector2.new(0,0.5) arI.BackgroundColor3=AUTO_REPLY and C.Gn or C.Ft arI.BackgroundTransparency=AUTO_REPLY and 0.3 or 0.5 arI.Text=AUTO_REPLY and"AUTO:ON"or"AUTO:OFF" arI.TextSize=8 arI.TextColor3=AUTO_REPLY and C.Wh or C.Mt arI.Font=Enum.Font.SourceSansBold arI.AutoButtonColor=false arI.BorderSizePixel=0 arI.ZIndex=3 arI.Parent=tb corner(arI,3)
local function togAR() AUTO_REPLY=not AUTO_REPLY cfg.autoReply=AUTO_REPLY sav(cfg) arI.BackgroundColor3=AUTO_REPLY and C.Gn or C.Ft arI.BackgroundTransparency=AUTO_REPLY and 0.3 or 0.5 arI.Text=AUTO_REPLY and"AUTO:ON"or"AUTO:OFF" arI.TextColor3=AUTO_REPLY and C.Wh or C.Mt end
arI.MouseButton1Click:Connect(togAR)

-- USAGE
local uf=Instance.new("Frame") uf.Size=UDim2.new(1,0,0,UH) uf.Position=UDim2.new(0,0,0,TH) uf.BackgroundColor3=C.Pn uf.BackgroundTransparency=PT+0.05 uf.BorderSizePixel=0 uf.Parent=win hL(uf,UH-1)
local uLbl=L({t="Usage: ...",s=10,c=C.Mt,f=Enum.Font.Code,sz=UDim2.new(0.5,0,1,0),p=UDim2.new(0,10,0,0),par=uf})
local pLbl=L({t="",s=10,c=C.Ac,f=Enum.Font.SourceSansSemibold,ax=Enum.TextXAlignment.Right,sz=UDim2.new(0.2,0,1,0),p=UDim2.new(0.5,0,0,0),par=uf})
local uBg=Instance.new("Frame") uBg.Size=UDim2.new(0.2,0,0,6) uBg.Position=UDim2.new(0.76,0,0.5,0) uBg.AnchorPoint=Vector2.new(0,0.5) uBg.BackgroundColor3=C.Bg uBg.BackgroundTransparency=0.3 uBg.BorderSizePixel=0 uBg.Parent=uf corner(uBg,3)
local uFl=Instance.new("Frame") uFl.Size=UDim2.new(1,0,1,0) uFl.BackgroundColor3=C.Gn uFl.BackgroundTransparency=0.2 uFl.BorderSizePixel=0 uFl.Parent=uBg corner(uFl,3)
local function updU() local r=tonumber(usage.rem)or 0 local l=tonumber(usage.lim)or 30 if l==0 then l=30 end uLbl.Text="Usage: "..r.." / "..l.." left" pLbl.Text=select(1,getProv()) tw(uFl,{Size=UDim2.new(math.clamp(r/l,0,1),0,1,0)},0.3) uFl.BackgroundColor3=r/l>0.3 and C.Gn or C.Rd end

-- Memory indicator
local memLbl=L({t=#memory.facts>0 and"🧠"..#memory.facts or"",s=10,c=C.Ac,f=Enum.Font.SourceSansBold,ax=Enum.TextXAlignment.Right,sz=UDim2.new(0.08,0,1,0),p=UDim2.new(0.92,0,0,0),par=uf})

-- TABS
local cTop=TH+UH
local tF=Instance.new("Frame") tF.Size=UDim2.new(1,0,0,TAH) tF.Position=UDim2.new(0,0,0,cTop) tF.BackgroundColor3=C.Pn tF.BackgroundTransparency=PT tF.BorderSizePixel=0 tF.Parent=win hL(tF,TAH-1)
local tabList={"Chat","Code","Terminal","Players","Settings"} local tBs={} local aTab="Chat" local tPs={}
for i,n in ipairs(tabList) do local tabW=52 local t=Instance.new("TextButton") t.Size=UDim2.new(0,tabW,0,TAH-1) t.Position=UDim2.new(0,(i-1)*tabW,0,0) t.BackgroundColor3=C.Bg t.BackgroundTransparency=n==aTab and BT or(PT+0.1) t.Text=n t.TextSize=11 t.TextColor3=n==aTab and C.Wh or C.Mt t.Font=Enum.Font.SourceSansSemibold t.AutoButtonColor=false t.BorderSizePixel=0 t.Parent=tF local ul=Instance.new("Frame") ul.Name="UL" ul.Size=UDim2.new(1,0,0,2) ul.Position=UDim2.new(0,0,1,-2) ul.BackgroundColor3=C.Ac ul.BackgroundTransparency=n==aTab and 0 or 1 ul.BorderSizePixel=0 ul.Parent=t tBs[n]=t end

-- PANELS
local cY=cTop+TAH
local function mkP(n,v) local p=Instance.new("Frame") p.Name=n p.Size=UDim2.new(1,-RW,1,-cY) p.Position=UDim2.new(0,0,0,cY) p.BackgroundColor3=C.Bg p.BackgroundTransparency=BT+0.05 p.BorderSizePixel=0 p.Visible=v p.ClipsDescendants=true p.Parent=win return p end

-- CHAT
local cP=mkP("Chat",true)
local cS=Instance.new("ScrollingFrame") cS.Size=UDim2.new(1,-8,1,-(IH+4)) cS.Position=UDim2.new(0,4,0,2) cS.BackgroundTransparency=1 cS.ScrollBarThickness=3 cS.ScrollBarImageColor3=C.Mt cS.ScrollBarImageTransparency=0.4 cS.CanvasSize=UDim2.new(0,0,0,0) cS.AutomaticCanvasSize=Enum.AutomaticSize.Y cS.BorderSizePixel=0 cS.Parent=cP
-- Smart scroll: only auto-scroll if user is near the bottom (within 80px)
local function smartScroll()
    task.defer(function()
        local maxScroll = cS.AbsoluteCanvasSize.Y - cS.AbsoluteSize.Y
        local currentScroll = cS.CanvasPosition.Y
        if maxScroll <= 0 or (maxScroll - currentScroll) < 80 then
            cS.CanvasPosition = Vector2.new(0, cS.AbsoluteCanvasSize.Y)
        end
    end)
end
Instance.new("UIListLayout",cS).Padding=UDim.new(0,4) pad(cS,6,4,6,4)
local iBar=Instance.new("Frame") iBar.Size=UDim2.new(1,-12,0,IH-10) iBar.Position=UDim2.new(0,6,1,-(IH-2)) iBar.BackgroundColor3=C.Inp iBar.BackgroundTransparency=0.3 iBar.BorderSizePixel=0 iBar.ClipsDescendants=true iBar.Parent=cP corner(iBar,6)
local iSt=Instance.new("UIStroke") iSt.Color=C.Bd iSt.Thickness=1 iSt.Transparency=0.4 iSt.ApplyStrokeMode=Enum.ApplyStrokeMode.Border iSt.Parent=iBar
local iBox=Instance.new("TextBox") iBox.Size=UDim2.new(1,-44,1,0) iBox.Position=UDim2.new(0,10,0,0) iBox.BackgroundTransparency=1 iBox.Text="" iBox.PlaceholderText="Message IsraelAI..." iBox.PlaceholderColor3=C.Ft iBox.TextColor3=C.Tx iBox.TextSize=13 iBox.Font=Enum.Font.SourceSans iBox.TextXAlignment=Enum.TextXAlignment.Left iBox.ClearTextOnFocus=false iBox.ClipsDescendants=true iBox.Parent=iBar
local sBtn=Instance.new("TextButton") sBtn.Size=UDim2.new(0,28,0,28) sBtn.Position=UDim2.new(1,-34,0.5,0) sBtn.AnchorPoint=Vector2.new(0,0.5) sBtn.BackgroundColor3=C.Ac sBtn.BackgroundTransparency=0.2 sBtn.Text="→" sBtn.TextColor3=C.Wh sBtn.TextSize=16 sBtn.Font=Enum.Font.SourceSansBold sBtn.AutoButtonColor=false sBtn.BorderSizePixel=0 sBtn.Parent=iBar corner(sBtn,6)
iBox.Focused:Connect(function() tw(iSt,{Color=C.Ac,Transparency=0.1},0.12) end)
iBox.FocusLost:Connect(function() tw(iSt,{Color=C.Bd,Transparency=0.4},0.12) end)

-- CODE TAB
local cdP=mkP("Code",false)
local cdScr=Instance.new("ScrollingFrame") cdScr.Size=UDim2.new(1,-8,1,-(IH+4)) cdScr.Position=UDim2.new(0,4,0,2) cdScr.BackgroundTransparency=1 cdScr.ScrollBarThickness=3 cdScr.ScrollBarImageColor3=C.Mt cdScr.CanvasSize=UDim2.new(0,0,0,0) cdScr.AutomaticCanvasSize=Enum.AutomaticSize.Y cdScr.BorderSizePixel=0 cdScr.Parent=cdP
Instance.new("UIListLayout",cdScr).Padding=UDim.new(0,4) pad(cdScr,6,4,6,4)

-- Code input bar
local cdBar=Instance.new("Frame") cdBar.Size=UDim2.new(1,-12,0,IH-10) cdBar.Position=UDim2.new(0,6,1,-(IH-2)) cdBar.BackgroundColor3=C.Inp cdBar.BackgroundTransparency=0.3 cdBar.BorderSizePixel=0 cdBar.ClipsDescendants=true cdBar.Parent=cdP corner(cdBar,6)
local cdSt=Instance.new("UIStroke") cdSt.Color=C.Bd cdSt.Thickness=1 cdSt.Transparency=0.4 cdSt.ApplyStrokeMode=Enum.ApplyStrokeMode.Border cdSt.Parent=cdBar
local cdBox=Instance.new("TextBox") cdBox.Size=UDim2.new(1,-44,1,0) cdBox.Position=UDim2.new(0,10,0,0) cdBox.BackgroundTransparency=1 cdBox.Text="" cdBox.PlaceholderText="Describe what code you need..." cdBox.PlaceholderColor3=C.Ft cdBox.TextColor3=C.Tx cdBox.TextSize=13 cdBox.Font=Enum.Font.SourceSans cdBox.TextXAlignment=Enum.TextXAlignment.Left cdBox.ClearTextOnFocus=false cdBox.ClipsDescendants=true cdBox.Parent=cdBar
local cdSend=Instance.new("TextButton") cdSend.Size=UDim2.new(0,28,0,28) cdSend.Position=UDim2.new(1,-34,0.5,0) cdSend.AnchorPoint=Vector2.new(0,0.5) cdSend.BackgroundColor3=C.Ac cdSend.BackgroundTransparency=0.2 cdSend.Text="</>" cdSend.TextColor3=C.Wh cdSend.TextSize=11 cdSend.Font=Enum.Font.SourceSansBold cdSend.AutoButtonColor=false cdSend.BorderSizePixel=0 cdSend.Parent=cdBar corner(cdSend,6)

local cdOrd=0
local CODE_SYS=[=[You are a code generator. The user describes what they need and you write clean, working code.

RULES:
- Write ONLY the code, no explanations before or after
- Include comments inside the code to explain what each part does
- Default to Lua/Luau for Roblox scripts unless the user specifies a language
- If the code requires a specific model or API that the current one can't handle well, add a comment at the top: -- WARNING: This code may benefit from a more powerful AI model (GPT-4, Claude, etc.)
- Make code clean, production-ready, and well-formatted
- If asked for executor scripts, use proper Roblox executor patterns (syn.request, writefile, etc.)]=]

local codeConv={}
local cdProc=false

local function addCodeBlock(code, lang)
    cdOrd=cdOrd+1
    local block=Instance.new("Frame") block.Size=UDim2.new(1,0,0,0) block.AutomaticSize=Enum.AutomaticSize.Y block.BackgroundColor3=Color3.fromRGB(18,18,22) block.BackgroundTransparency=0.1 block.BorderSizePixel=0 block.LayoutOrder=cdOrd block.Parent=cdScr corner(block,6)
    
    -- Header bar with language + buttons
    local hdr=Instance.new("Frame") hdr.Size=UDim2.new(1,0,0,24) hdr.BackgroundColor3=C.Hd hdr.BackgroundTransparency=0.3 hdr.BorderSizePixel=0 hdr.Parent=block corner(hdr,6)
    L({t=lang or"lua",s=10,c=C.Dm,f=Enum.Font.Code,sz=UDim2.new(0.3,0,1,0),p=UDim2.new(0,8,0,0),par=hdr})
    
    -- Copy code button
    local cpCode=Instance.new("TextButton") cpCode.Size=UDim2.new(0,40,0,16) cpCode.Position=UDim2.new(1,-92,0.5,0) cpCode.AnchorPoint=Vector2.new(0,0.5) cpCode.BackgroundColor3=C.Pn cpCode.BackgroundTransparency=0.3 cpCode.Text="Copy" cpCode.TextSize=9 cpCode.TextColor3=C.Mt cpCode.Font=Enum.Font.SourceSansBold cpCode.AutoButtonColor=false cpCode.BorderSizePixel=0 cpCode.Parent=hdr corner(cpCode,3)
    cpCode.MouseButton1Click:Connect(function() copyText(code) cpCode.Text="✓" task.delay(1.5,function() cpCode.Text="Copy" end) end)
    
    -- Export button
    local exCode=Instance.new("TextButton") exCode.Size=UDim2.new(0,46,0,16) exCode.Position=UDim2.new(1,-48,0.5,0) exCode.AnchorPoint=Vector2.new(0,0.5) exCode.BackgroundColor3=C.Gn exCode.BackgroundTransparency=0.4 exCode.Text="Export" exCode.TextSize=9 exCode.TextColor3=C.Wh exCode.Font=Enum.Font.SourceSansBold exCode.AutoButtonColor=false exCode.BorderSizePixel=0 exCode.Parent=hdr corner(exCode,3)
    exCode.MouseButton1Click:Connect(function()
        local ext = lang == "js" and ".js" or lang == "py" and ".py" or lang == "html" and ".html" or ".lua"
        local fname = "israelai_code" .. ext
        pcall(function() if wf then wf(fname, code) end end)
        exCode.Text="Saved!" exCode.TextColor3=C.Gn
        pcall(function() SG:SetCore("SendNotification",{Title="IsraelAI",Text="Saved as "..fname,Duration=3}) end)
        task.delay(2,function() exCode.Text="Export" end)
    end)
    
    -- Code text
    local codeLabel=Instance.new("TextLabel") codeLabel.Size=UDim2.new(1,-16,0,0) codeLabel.Position=UDim2.new(0,8,0,28) codeLabel.AutomaticSize=Enum.AutomaticSize.Y codeLabel.BackgroundTransparency=1 codeLabel.Text=code codeLabel.TextColor3=C.Gn codeLabel.TextSize=11 codeLabel.Font=Enum.Font.Code codeLabel.TextWrapped=true codeLabel.TextXAlignment=Enum.TextXAlignment.Left codeLabel.TextYAlignment=Enum.TextYAlignment.Top codeLabel.Parent=block
    
    local bPad=Instance.new("Frame") bPad.Size=UDim2.new(1,0,0,8) bPad.BackgroundTransparency=1 bPad.Parent=block
    bPad.Position=UDim2.new(0,0,1,0)
    
    task.defer(function() cdScr.CanvasPosition=Vector2.new(0,cdScr.AbsoluteCanvasSize.Y) end)
end

local function addCodeMsg(text,isU)
    cdOrd=cdOrd+1
    local l=Instance.new("TextLabel") l.Size=UDim2.new(1,0,0,0) l.AutomaticSize=Enum.AutomaticSize.Y l.BackgroundColor3=isU and C.BU or C.BA l.BackgroundTransparency=isU and 0.2 or 0.15 l.Text=text l.TextColor3=C.Tx l.TextSize=12 l.Font=Enum.Font.SourceSans l.TextWrapped=true l.TextXAlignment=Enum.TextXAlignment.Left l.LayoutOrder=cdOrd l.BorderSizePixel=0 l.Parent=cdScr corner(l,6) pad(l,6,10,6,10)
    task.defer(function() cdScr.CanvasPosition=Vector2.new(0,cdScr.AbsoluteCanvasSize.Y) end)
end

local function sendCode()
    if cdProc then return end
    local text=cdBox.Text if not text or text:match("^%s*$") then return end
    cdBox.Text="" cdProc=true
    addCodeMsg(text,true)
    
    table.insert(codeConv,{role="user",content=text})
    while #codeConv>10 do table.remove(codeConv,1) end
    
    -- Detect language from request
    local lo=text:lower()
    local lang="lua"
    if lo:find("python")or lo:find("%.py") then lang="py"
    elseif lo:find("javascript")or lo:find("%.js")or lo:find("node") then lang="js"
    elseif lo:find("html")or lo:find("webpage")or lo:find("website") then lang="html"
    elseif lo:find("css") then lang="css"
    elseif lo:find("bash")or lo:find("shell")or lo:find("%.sh") then lang="sh" end
    
    -- Check if current model might struggle
    local prov=select(1,getProv())
    local modelWarn=""
    if (lo:find("complex")or lo:find("advanced")or lo:find("full app")or lo:find("entire")or #text>200) and (prov=="Groq") then
        modelWarn="-- NOTE: For complex code, consider using a more powerful model (OpenAI GPT-4, Claude)\n-- Current: "..prov.."\n\n"
    end
    
    local ok,resp=callRaw(codeConv,CODE_SYS)
    if ok then
        table.insert(codeConv,{role="assistant",content=resp})
        while #codeConv>10 do table.remove(codeConv,1) end
        -- Clean response - strip markdown code fences if present
        resp=resp:gsub("^```%w*\n",""):gsub("\n```$",""):gsub("^```%w*",""):gsub("```$","")
        if modelWarn~="" then resp=modelWarn..resp end
        addCodeBlock(resp,lang)
    else
        addCodeMsg("Error: "..resp,false)
    end
    cdProc=false
end

cdBox.FocusLost:Connect(function(e) if e then sendCode() end end)
cdSend.MouseButton1Click:Connect(function() sendCode() end)

addCodeMsg("Code Generator — describe what you need and I'll write it. Copy or Export the result.",false)

-- TERMINAL
local tP=mkP("Terminal",false)
local tScr=Instance.new("ScrollingFrame") tScr.Size=UDim2.new(1,-8,1,-4) tScr.Position=UDim2.new(0,4,0,2) tScr.BackgroundTransparency=1 tScr.ScrollBarThickness=3 tScr.ScrollBarImageColor3=C.Mt tScr.ScrollBarImageTransparency=0.4 tScr.CanvasSize=UDim2.new(0,0,0,0) tScr.AutomaticCanvasSize=Enum.AutomaticSize.Y tScr.BorderSizePixel=0 tScr.Parent=tP
Instance.new("UIListLayout",tScr).Padding=UDim.new(0,0) pad(tScr,6,8,6,8)
local tOrd=0
local function tLine(txt,col) tOrd=tOrd+1 local l=Instance.new("TextLabel") l.Size=UDim2.new(1,0,0,0) l.AutomaticSize=Enum.AutomaticSize.Y l.BackgroundTransparency=1 l.Text=txt l.TextColor3=col or C.Tx l.TextSize=12 l.Font=Enum.Font.Code l.TextWrapped=true l.TextXAlignment=Enum.TextXAlignment.Left l.TextYAlignment=Enum.TextYAlignment.Top l.LayoutOrder=tOrd l.Parent=tScr task.defer(function() tScr.CanvasPosition=Vector2.new(0,tScr.AbsoluteCanvasSize.Y) end) end
local tProc=false
local function tPrompt()
    tOrd=tOrd+1
    local pf=Instance.new("Frame") pf.Size=UDim2.new(1,0,0,20) pf.BackgroundTransparency=1 pf.LayoutOrder=tOrd pf.Parent=tScr
    L({t="$",s=12,c=C.Gn,f=Enum.Font.Code,sz=UDim2.new(0,14,1,0),par=pf})
    local ib=Instance.new("TextBox") ib.Size=UDim2.new(1,-18,1,0) ib.Position=UDim2.new(0,16,0,0) ib.BackgroundTransparency=1 ib.Text="" ib.TextColor3=C.Tx ib.TextSize=12 ib.Font=Enum.Font.Code ib.TextXAlignment=Enum.TextXAlignment.Left ib.ClearTextOnFocus=false ib.ClipsDescendants=true ib.BorderSizePixel=0 ib.Parent=pf
    task.defer(function() task.wait(0.1) ib:CaptureFocus() tScr.CanvasPosition=Vector2.new(0,tScr.AbsoluteCanvasSize.Y) end)
    ib.FocusLost:Connect(function(enter)
        if not enter or tProc then return end
        local cmd=ib.Text if cmd=="" then tPrompt() return end
        ib.TextEditable=false ib.TextColor3=C.Dm
        local lo=cmd:lower():match("^%s*(.-)%s*$")
        if lo=="clear"or lo=="cls" then for _,ch in ipairs(tScr:GetChildren()) do if ch:IsA("TextLabel")or ch:IsA("Frame") then ch:Destroy() end end tOrd=0 tPrompt() return end
        if lo=="help" then tLine("clear, help — local commands. Everything else runs on server.",C.Dm) tLine("Join discord.gg/74jTp5VY5V for support",C.Dm) tPrompt() return end
        tProc=true task.spawn(function() local ok,out,code=runTerm(cmd) if ok then for line in out:gmatch("[^\n]+") do tLine(line,code==0 and C.Tx or C.Or) end else tLine("Error: "..out,C.Rd) end tProc=false tPrompt() end)
    end)
end
tLine("IsraelAI Terminal",C.Dm)
if TERM_URL~="" then tLine("Server: "..TERM_URL,C.Dm) else tLine("Configure in Settings tab.",C.Dm) end
tLine("",C.Dm) tPrompt()

-- PLAYERS
local plP=mkP("Players",false)

-- Search bar at top
local plSearchBar=Instance.new("Frame") plSearchBar.Size=UDim2.new(1,-12,0,28) plSearchBar.Position=UDim2.new(0,6,0,4) plSearchBar.BackgroundColor3=C.Inp plSearchBar.BackgroundTransparency=0.3 plSearchBar.BorderSizePixel=0 plSearchBar.Parent=plP corner(plSearchBar,6)
local plSearchBox=Instance.new("TextBox") plSearchBox.Size=UDim2.new(1,-16,1,0) plSearchBox.Position=UDim2.new(0,8,0,0) plSearchBox.BackgroundTransparency=1 plSearchBox.Text="" plSearchBox.PlaceholderText="Search players..." plSearchBox.PlaceholderColor3=C.Ft plSearchBox.TextColor3=C.Tx plSearchBox.TextSize=12 plSearchBox.Font=Enum.Font.SourceSans plSearchBox.TextXAlignment=Enum.TextXAlignment.Left plSearchBox.ClearTextOnFocus=false plSearchBox.ClipsDescendants=true plSearchBox.Parent=plSearchBar

local plScr=Instance.new("ScrollingFrame") plScr.Size=UDim2.new(1,-8,1,-38) plScr.Position=UDim2.new(0,4,0,36) plScr.BackgroundTransparency=1 plScr.ScrollBarThickness=3 plScr.ScrollBarImageColor3=C.Mt plScr.CanvasSize=UDim2.new(0,0,0,0) plScr.AutomaticCanvasSize=Enum.AutomaticSize.Y plScr.BorderSizePixel=0 plScr.Parent=plP
Instance.new("UIListLayout",plScr).Padding=UDim.new(0,4) pad(plScr,4,6,4,6)

local plSearchFilter = ""

local function refreshPlayers()
    for _,ch in ipairs(plScr:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    local filter = plSearchFilter:lower()
    local ord = 0
    for _,p in ipairs(P:GetPlayers()) do
        -- Search filter
        local name = p.Name:lower()
        local display = p.DisplayName:lower()
        local match = (filter == "") or name:find(filter, 1, true) or display:find(filter, 1, true)
        
        if match then
        ord = ord + 1
        local card=Instance.new("Frame") card.Size=UDim2.new(1,0,0,0) card.AutomaticSize=Enum.AutomaticSize.Y card.BackgroundColor3=C.Pn card.BackgroundTransparency=0.4 card.BorderSizePixel=0 card.LayoutOrder=ord card.Parent=plScr corner(card,4)
        local inner=Instance.new("Frame") inner.Size=UDim2.new(1,-16,0,0) inner.Position=UDim2.new(0,8,0,6) inner.AutomaticSize=Enum.AutomaticSize.Y inner.BackgroundTransparency=1 inner.Parent=card
        Instance.new("UIListLayout",inner).Padding=UDim.new(0,2)
        local isYou = p == plr
        
        -- Name
        L({t=(isYou and "★ " or "")..p.DisplayName.." ("..p.Name..")", s=12, c=isYou and C.Ac or C.Tx, f=Enum.Font.SourceSansSemibold, sz=UDim2.new(1,0,0,16), par=inner}).LayoutOrder=1
        
        -- Info - use AccountAge for real age, track session time properly
        local info = {}
        pcall(function() 
            local age = p.AccountAge
            if age < 30 then info[#info+1] = "Age:"..age.."d ⚠"
            elseif age < 365 then info[#info+1] = "Age:"..age.."d"
            else info[#info+1] = "Age:"..math.floor(age/365).."y "..(age%365).."d" end
        end)
        pcall(function() if p.MembershipType == Enum.MembershipType.Premium then info[#info+1] = "💎Premium" end end)
        pcall(function() if p.Team then info[#info+1] = "Team:"..p.Team.Name end end)
        pcall(function()
            if playerJoinTimes[p.Name] then
                local elapsed = os.time() - playerJoinTimes[p.Name]
                if elapsed < 60 then info[#info+1] = "In:<1m"
                elseif elapsed < 3600 then info[#info+1] = "In:"..math.floor(elapsed/60).."m"
                else info[#info+1] = "In:"..math.floor(elapsed/3600).."h "..math.floor((elapsed%3600)/60).."m" end
            end
        end)
        pcall(function()
            local c = p.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then info[#info+1] = "HP:"..math.floor(h.Health).."/"..math.floor(h.MaxHealth) end
            end
        end)
        
        L({t=table.concat(info,"  |  "), s=10, c=C.Dm, f=Enum.Font.Code, sz=UDim2.new(1,0,0,14), par=inner}).LayoutOrder=2
        
        -- Chat logs (scrollable)
        local logs = playerChatLogs[p.Name]
        if logs and #logs > 0 then
            local logScr = Instance.new("ScrollingFrame")
            logScr.Size = UDim2.new(1, 0, 0, math.min(#logs * 16, 80))
            logScr.BackgroundTransparency = 1
            logScr.ScrollBarThickness = 2
            logScr.ScrollBarImageColor3 = C.Mt
            logScr.CanvasSize = UDim2.new(0, 0, 0, 0)
            logScr.AutomaticCanvasSize = Enum.AutomaticSize.Y
            logScr.BorderSizePixel = 0
            logScr.LayoutOrder = 3
            logScr.Parent = inner
            local logLay = Instance.new("UIListLayout")
            logLay.Padding = UDim.new(0, 1)
            logLay.Parent = logScr
            for i = 1, math.min(10, #logs) do
                local ml = Instance.new("TextLabel")
                ml.Size = UDim2.new(1, 0, 0, 0)
                ml.AutomaticSize = Enum.AutomaticSize.Y
                ml.BackgroundTransparency = 1
                ml.Text = "["..logs[i].t.."] "..logs[i].m
                ml.TextColor3 = C.Mt
                ml.TextSize = 10
                ml.Font = Enum.Font.Code
                ml.TextWrapped = true
                ml.TextXAlignment = Enum.TextXAlignment.Left
                ml.LayoutOrder = i
                ml.Parent = logScr
            end
        else
            L({t="(no messages)", s=10, c=C.Ft, sz=UDim2.new(1,0,0,14), par=inner}).LayoutOrder=3
        end
        
        local bPad=Instance.new("Frame") bPad.Size=UDim2.new(1,0,0,6) bPad.BackgroundTransparency=1 bPad.LayoutOrder=4 bPad.Parent=inner
        end -- if match
    end
end

-- Search triggers refresh
plSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    plSearchFilter = plSearchBox.Text
    refreshPlayers()
end)

-- Auto-refresh Players tab every 3 seconds when visible
task.spawn(function()
    while true do
        task.wait(3)
        if aTab == "Players" then
            refreshPlayers()
        end
    end
end)

-- SETTINGS
local sP=mkP("Settings",false)
local sSc=Instance.new("ScrollingFrame") sSc.Size=UDim2.new(1,-8,1,-4) sSc.Position=UDim2.new(0,4,0,2) sSc.BackgroundTransparency=1 sSc.ScrollBarThickness=3 sSc.ScrollBarImageColor3=C.Mt sSc.CanvasSize=UDim2.new(0,0,0,0) sSc.AutomaticCanvasSize=Enum.AutomaticSize.Y sSc.BorderSizePixel=0 sSc.Parent=sP
Instance.new("UIListLayout",sSc).Padding=UDim.new(0,6) pad(sSc,10,10,10,10)
L({t="Settings",s=16,c=C.Wh,f=Enum.Font.SourceSansBold,sz=UDim2.new(1,0,0,22),par=sSc}).LayoutOrder=1

-- AI Key
local kSec=Instance.new("Frame") kSec.Size=UDim2.new(1,0,0,56) kSec.BackgroundColor3=C.Pn kSec.BackgroundTransparency=0.4 kSec.BorderSizePixel=0 kSec.LayoutOrder=2 kSec.Parent=sSc corner(kSec,4)
L({t="AI Key",s=10,c=C.Dm,f=Enum.Font.SourceSansSemibold,sz=UDim2.new(0.3,0,0,14),p=UDim2.new(0,8,0,4),par=kSec})
local kIn=Instance.new("TextBox") kIn.Size=UDim2.new(1,-16,0,22) kIn.Position=UDim2.new(0,8,0,22) kIn.BackgroundColor3=C.Inp kIn.BackgroundTransparency=0.2 kIn.Text=API_KEY~=""and string.rep("*",16)or"" kIn.PlaceholderText="Paste key..." kIn.PlaceholderColor3=C.Ft kIn.TextColor3=C.Tx kIn.TextSize=11 kIn.Font=Enum.Font.Code kIn.TextXAlignment=Enum.TextXAlignment.Left kIn.ClearTextOnFocus=true kIn.ClipsDescendants=true kIn.BorderSizePixel=0 kIn.Parent=kSec corner(kIn,3)
local kSv=Instance.new("TextButton") kSv.Size=UDim2.new(0,44,0,14) kSv.Position=UDim2.new(1,-52,0,4) kSv.BackgroundColor3=C.Ac kSv.BackgroundTransparency=0.2 kSv.Text="Save" kSv.TextSize=9 kSv.TextColor3=C.Wh kSv.Font=Enum.Font.SourceSansBold kSv.AutoButtonColor=false kSv.BorderSizePixel=0 kSv.Parent=kSec corner(kSv,3)
local kSt=L({t=API_KEY~=""and select(1,getProv())or"No key",s=9,c=C.Dm,sz=UDim2.new(0.4,0,0,12),p=UDim2.new(0.3,0,0,4),par=kSec})
local dyn={}
kSv.MouseButton1Click:Connect(function() local nk=kIn.Text if nk==""or nk==string.rep("*",16) then return end API_KEY=nk cfg.key=nk sav(cfg) kIn.Text=string.rep("*",16) kSt.Text="Saved! ("..select(1,getProv())..")" kSt.TextColor3=C.Ac end)

-- Terminal Config
local tSec=Instance.new("Frame") tSec.Size=UDim2.new(1,0,0,56) tSec.BackgroundColor3=C.Pn tSec.BackgroundTransparency=0.4 tSec.BorderSizePixel=0 tSec.LayoutOrder=3 tSec.Parent=sSc corner(tSec,4)
L({t="Terminal Server",s=10,c=C.Dm,f=Enum.Font.SourceSansSemibold,sz=UDim2.new(0.4,0,0,14),p=UDim2.new(0,8,0,4),par=tSec})
local tuIn=Instance.new("TextBox") tuIn.Size=UDim2.new(0.6,-4,0,22) tuIn.Position=UDim2.new(0,8,0,22) tuIn.BackgroundColor3=C.Inp tuIn.BackgroundTransparency=0.2 tuIn.Text=TERM_URL tuIn.PlaceholderText="Replit URL" tuIn.PlaceholderColor3=C.Ft tuIn.TextColor3=C.Tx tuIn.TextSize=10 tuIn.Font=Enum.Font.Code tuIn.ClearTextOnFocus=false tuIn.ClipsDescendants=true tuIn.BorderSizePixel=0 tuIn.Parent=tSec corner(tuIn,3)
local tkIn=Instance.new("TextBox") tkIn.Size=UDim2.new(0.28,0,0,22) tkIn.Position=UDim2.new(0.6,4,0,22) tkIn.BackgroundColor3=C.Inp tkIn.BackgroundTransparency=0.2 tkIn.Text=TERM_KEY~=""and"****"or"" tkIn.PlaceholderText="Key" tkIn.PlaceholderColor3=C.Ft tkIn.TextColor3=C.Tx tkIn.TextSize=10 tkIn.Font=Enum.Font.Code tkIn.ClearTextOnFocus=true tkIn.ClipsDescendants=true tkIn.BorderSizePixel=0 tkIn.Parent=tSec corner(tkIn,3)
local tSv=Instance.new("TextButton") tSv.Size=UDim2.new(0,44,0,14) tSv.Position=UDim2.new(1,-52,0,4) tSv.BackgroundColor3=C.Gn tSv.BackgroundTransparency=0.3 tSv.Text="Save" tSv.TextSize=9 tSv.TextColor3=C.Wh tSv.Font=Enum.Font.SourceSansBold tSv.AutoButtonColor=false tSv.BorderSizePixel=0 tSv.Parent=tSec corner(tSv,3)
local tSt=L({t=TERM_URL~=""and"Set"or"Not set",s=9,c=C.Dm,sz=UDim2.new(0.4,0,0,12),p=UDim2.new(0.4,0,0,4),par=tSec})
tSv.MouseButton1Click:Connect(function() local u,k=tuIn.Text,tkIn.Text if u=="" then return end if k==""or k=="****" then k=TERM_KEY end TERM_URL=u TERM_KEY=k cfg.termUrl=u cfg.termKey=k sav(cfg) tkIn.Text="****" tSt.Text="Saved!" tSt.TextColor3=C.Gn end)

-- Memory section
local mSec=Instance.new("Frame") mSec.Size=UDim2.new(1,0,0,30) mSec.BackgroundColor3=C.Pn mSec.BackgroundTransparency=0.4 mSec.BorderSizePixel=0 mSec.LayoutOrder=5 mSec.Parent=sSc corner(mSec,4)
L({t="Memory: "..#memory.facts.." facts stored",s=10,c=C.Dm,f=Enum.Font.SourceSansSemibold,sz=UDim2.new(0.7,0,1,0),p=UDim2.new(0,8,0,0),par=mSec})
local mClr=Instance.new("TextButton") mClr.Size=UDim2.new(0,60,0,18) mClr.Position=UDim2.new(1,-68,0.5,0) mClr.AnchorPoint=Vector2.new(0,0.5) mClr.BackgroundColor3=C.Rd mClr.BackgroundTransparency=0.5 mClr.Text="Clear" mClr.TextSize=9 mClr.TextColor3=C.Wh mClr.Font=Enum.Font.SourceSansBold mClr.AutoButtonColor=false mClr.BorderSizePixel=0 mClr.Parent=mSec corner(mClr,3)
mClr.MouseButton1Click:Connect(function() memory.facts={} saveMem(memory) memLbl.Text="" pcall(function() SG:SetCore("SendNotification",{Title="IsraelAI",Text="Memory cleared",Duration=2}) end) end)

-- PACKAGES section
L({t="Packages",s=14,c=C.Wh,f=Enum.Font.SourceSansBold,sz=UDim2.new(1,0,0,20),par=sSc}).LayoutOrder=6

local pkgFrames = {}
local function refreshPkgUI()
    for _, f in ipairs(pkgFrames) do pcall(function() f:Destroy() end) end
    pkgFrames = {}
    for i, pkg in ipairs(PKG_CATALOG) do
        local isOn = installedPkgs[pkg.id] == true
        local isPaid = pkg.paid == true
        local pf = Instance.new("Frame")
        pf.Size = UDim2.new(1, 0, 0, 36)
        pf.BackgroundColor3 = C.Pn
        pf.BackgroundTransparency = 0.4
        pf.BorderSizePixel = 0
        pf.LayoutOrder = 20 + i
        pf.Parent = sSc
        corner(pf, 4)
        pkgFrames[#pkgFrames+1] = pf
        
        L({t=pkg.name, s=11, c=isOn and C.Ac or C.Tx, f=Enum.Font.SourceSansSemibold, sz=UDim2.new(0.35,0,0,16), p=UDim2.new(0,8,0,4), par=pf})
        L({t=pkg.desc, s=9, c=C.Mt, sz=UDim2.new(0.5,0,0,14), p=UDim2.new(0,8,0,20), par=pf, trunc=true})
        
        local pkgId = pkg.id
        
        if isPaid and not isOn then
            -- PAID package — show price button
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(0, 52, 0, 20)
            buyBtn.Position = UDim2.new(1, -60, 0.5, 0)
            buyBtn.AnchorPoint = Vector2.new(0, 0.5)
            buyBtn.BackgroundColor3 = C.Or
            buyBtn.BackgroundTransparency = 0.2
            buyBtn.Text = pkg.price or "$2.99"
            buyBtn.TextSize = 10
            buyBtn.TextColor3 = C.Wh
            buyBtn.Font = Enum.Font.SourceSansBold
            buyBtn.AutoButtonColor = false
            buyBtn.BorderSizePixel = 0
            buyBtn.Parent = pf
            corner(buyBtn, 4)
            
            buyBtn.MouseEnter:Connect(function() tw(buyBtn, {BackgroundTransparency=0.05}, 0.1) end)
            buyBtn.MouseLeave:Connect(function() tw(buyBtn, {BackgroundTransparency=0.2}, 0.1) end)
            
            buyBtn.MouseButton1Click:Connect(function()
                local url = pkg.payUrl or PAYMENT_LINK or ""
                if url ~= "" then
                    copyText(url)
                    buyBtn.Text = "Copied!"
                    buyBtn.BackgroundColor3 = C.Gn
                    task.delay(2, function()
                        buyBtn.Text = pkg.price or "$2.99"
                        buyBtn.BackgroundColor3 = C.Or
                    end)
                else
                    -- No link set yet — still copy empty and show feedback
                    pcall(function()
                        if setclipboard then setclipboard("") end
                    end)
                    buyBtn.Text = "Link Soon"
                    buyBtn.BackgroundColor3 = C.Ac
                    task.delay(2, function()
                        buyBtn.Text = pkg.price or "$2.99"
                        buyBtn.BackgroundColor3 = C.Or
                    end)
                end
                pcall(function() SG:SetCore("SendNotification",{Title="IsraelAI",Text="Payment link copied! Complete purchase to unlock.",Duration=4}) end)
            end)
        else
            -- FREE package or PAID+ACTIVE — show ON/OFF toggle
            local togP = Instance.new("TextButton")
            togP.Size = UDim2.new(0, 44, 0, 18)
            togP.Position = UDim2.new(1, -52, 0.5, 0)
            togP.AnchorPoint = Vector2.new(0, 0.5)
            togP.BackgroundColor3 = isOn and C.Gn or C.Ft
            togP.BackgroundTransparency = 0.3
            togP.Text = isOn and "ON" or "OFF"
            togP.TextSize = 9
            togP.TextColor3 = isOn and C.Wh or C.Mt
            togP.Font = Enum.Font.SourceSansBold
            togP.AutoButtonColor = false
            togP.BorderSizePixel = 0
            togP.Parent = pf
            corner(togP, 3)
            
            togP.MouseButton1Click:Connect(function()
                installedPkgs[pkgId] = not installedPkgs[pkgId]
                savePkgs(installedPkgs)
                refreshPkgUI()
            end)
        end
    end
end
refreshPkgUI()

-- RIGHT PANEL
local rP=Instance.new('Frame') rP.Size=UDim2.new(0,RW,1,-cY) rP.Position=UDim2.new(1,-RW,0,cY) rP.BackgroundColor3=C.Pn rP.BackgroundTransparency=PT rP.BorderSizePixel=0 rP.ClipsDescendants=true rP.Parent=win vL(rP,0)
local splitPx=150
local spl,tbS
do
local ftHd=Instance.new("TextButton") ftHd.Size=UDim2.new(1,0,0,HH) ftHd.BackgroundColor3=C.Hd ftHd.BackgroundTransparency=PT ftHd.Text="" ftHd.AutoButtonColor=false ftHd.BorderSizePixel=0 ftHd.Parent=rP hL(ftHd,HH-1)
L({t="Function Tree",s=11,c=C.Dm,f=Enum.Font.SourceSansSemibold,sz=UDim2.new(1,-20,1,0),p=UDim2.new(0,10,0,0),par=ftHd})
local ftS=Instance.new("ScrollingFrame") ftS.Position=UDim2.new(0,0,0,HH) ftS.BackgroundTransparency=1 ftS.ScrollBarThickness=2 ftS.ScrollBarImageColor3=C.Mt ftS.CanvasSize=UDim2.new(0,0,0,0) ftS.AutomaticCanvasSize=Enum.AutomaticSize.Y ftS.BorderSizePixel=0 ftS.Parent=rP
Instance.new("UIListLayout",ftS).Padding=UDim.new(0,1) pad(ftS,4,8,4,8)
local td={{t="Model",d=select(3,getProv()),h=1},{t="  Provider",d=select(1,getProv())},{t="Session",d="",h=1},{t="  Messages",d="0",id="mc"},{t="  Memory",d=#memory.facts.." facts"},{t="  Player",d=plr.Name}}
for i,it in ipairs(td) do local row=Instance.new("Frame") row.Size=UDim2.new(1,0,0,16) row.BackgroundTransparency=1 row.LayoutOrder=i row.Parent=ftS L({t=it.t,s=10,c=it.h and C.Dm or C.Mt,f=it.h and Enum.Font.SourceSansSemibold or Enum.Font.Code,sz=UDim2.new(0.55,0,1,0),par=row}) if it.d~="" then local dl=L({t=it.d,s=10,c=C.Tx,f=Enum.Font.Code,ax=Enum.TextXAlignment.Right,trunc=true,sz=UDim2.new(0.42,0,1,0),p=UDim2.new(0.55,0,0,0),par=row}) if it.id then dyn[it.id]=dl end end end

spl=Instance.new("TextButton") spl.Size=UDim2.new(1,0,0,6) spl.BackgroundColor3=C.Bd spl.BackgroundTransparency=0.3 spl.Text="" spl.AutoButtonColor=false spl.BorderSizePixel=0 spl.ZIndex=5 spl.Parent=rP

local tbHd=Instance.new("TextButton") tbHd.Size=UDim2.new(1,0,0,HH) tbHd.BackgroundColor3=C.Hd tbHd.BackgroundTransparency=PT tbHd.Text="" tbHd.AutoButtonColor=false tbHd.BorderSizePixel=0 tbHd.Parent=rP hL(tbHd,0) hL(tbHd,HH-1)
L({t="Traceback",s=11,c=C.Dm,f=Enum.Font.SourceSansSemibold,sz=UDim2.new(1,-20,1,0),p=UDim2.new(0,10,0,0),par=tbHd})
tbS=Instance.new("ScrollingFrame") tbS.BackgroundTransparency=1 tbS.ScrollBarThickness=2 tbS.ScrollBarImageColor3=C.Mt tbS.CanvasSize=UDim2.new(0,0,0,0) tbS.AutomaticCanvasSize=Enum.AutomaticSize.Y tbS.BorderSizePixel=0 tbS.Parent=rP
Instance.new("UIListLayout",tbS).Padding=UDim.new(0,1) pad(tbS,3,6,3,6)

local function updSplit() local pH=rP.AbsoluteSize.Y-36 splitPx=math.clamp(splitPx,40,pH-60) ftS.Size=UDim2.new(1,0,0,splitPx-HH-2) spl.Position=UDim2.new(0,0,0,splitPx) tbHd.Position=UDim2.new(0,0,0,splitPx+6) tbS.Position=UDim2.new(0,0,0,splitPx+6+HH) tbS.Size=UDim2.new(1,0,0,pH-(splitPx+6+HH)) end updSplit()

local bB=Instance.new("Frame") bB.Size=UDim2.new(1,0,0,36) bB.Position=UDim2.new(0,0,1,-36) bB.BackgroundColor3=C.Hd bB.BackgroundTransparency=PT bB.BorderSizePixel=0 bB.Parent=rP hL(bB,0)
local lgB=Instance.new("ImageLabel") lgB.Size=UDim2.new(0,26,0,26) lgB.Position=UDim2.new(0,6,0.5,0) lgB.AnchorPoint=Vector2.new(0,0.5) lgB.BackgroundTransparency=1 lgB.Image="rbxassetid://103486408225648" lgB.Parent=bB
L({t="IsraelAI v7",s=11,c=C.Mt,f=Enum.Font.SourceSansSemibold,sz=UDim2.new(0,80,1,0),p=UDim2.new(0,36,0,0),par=bB})

end
local trOrd=0
function trace(t,col) trOrd=trOrd+1 local r=Instance.new("TextLabel") r.Size=UDim2.new(1,0,0,0) r.AutomaticSize=Enum.AutomaticSize.Y r.BackgroundTransparency=1 r.Text=os.date("[%H:%M:%S] ")..t r.TextColor3=col or C.Mt r.TextSize=9 r.Font=Enum.Font.Code r.TextWrapped=true r.TextXAlignment=Enum.TextXAlignment.Left r.TextYAlignment=Enum.TextYAlignment.Top r.LayoutOrder=trOrd r.Parent=tbS task.defer(function() tbS.CanvasPosition=Vector2.new(0,tbS.AbsoluteCanvasSize.Y) end) end

-- INPUT
local dragging,dragSt,startPos=false,nil,nil local splitDrag,splitSt,splitPxSt=false,nil,nil local resWin,resSt,resSzSt=false,nil,nil
dragArea.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true dragSt=i.Position startPos=win.Position end end)
spl.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then splitDrag=true splitSt=i.Position.Y splitPxSt=splitPx end end)
rz.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then resWin=true resSt=i.Position resSzSt=win.Size end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then if dragging and dragSt and startPos then local d=i.Position-dragSt win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end if splitDrag then splitPx=math.clamp(splitPxSt+(i.Position.Y-splitSt),40,rP.AbsoluteSize.Y-96) updSplit() end if resWin and resSzSt then local d=i.Position-resSt win.Size=UDim2.new(0,math.max(MnW,resSzSt.X.Offset+d.X),0,math.max(MnH,resSzSt.Y.Offset+d.Y)) end end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false splitDrag=false resWin=false end end)

-- TAB SWITCH
tPs={Chat=cP,Code=cdP,Terminal=tP,Players=plP,Settings=sP}
local function swTab(n) aTab=n for tn,t in pairs(tBs) do local a=(tn==n) t.BackgroundTransparency=a and BT or(PT+0.1) t.TextColor3=a and C.Wh or C.Mt local ul=t:FindFirstChild("UL") if ul then ul.BackgroundTransparency=a and 0 or 1 end end for pn,p in pairs(tPs) do p.Visible=(pn==n) end if n=="Players" then refreshPlayers() end end
for n,t in pairs(tBs) do t.MouseButton1Click:Connect(function() swTab(n) end) end
tog.MouseButton1Click:Connect(function() if isOpen then isOpen=false win.Visible=false else isOpen=true win.Visible=true end end)

--═══ BUBBLES — with COPY + EXPORT buttons ═══
local mOrd,tMsgs=0,0
local function mkB(text,isU,skip)
    mOrd=mOrd+1 tMsgs=tMsgs+1 if dyn.mc then dyn.mc.Text=tostring(tMsgs) end
    local fr=Instance.new("Frame") fr.BackgroundTransparency=1 fr.AutomaticSize=Enum.AutomaticSize.Y fr.Size=UDim2.new(1,0,0,0) fr.LayoutOrder=mOrd fr.Parent=cS
    -- Use list layout so bubble + buttons stack vertically
    local frLay=Instance.new("UIListLayout") frLay.Padding=UDim.new(0,2) frLay.SortOrder=Enum.SortOrder.LayoutOrder frLay.Parent=fr
    
    local b=Instance.new("TextLabel") b.Name="B" b.AutomaticSize=Enum.AutomaticSize.Y b.Size=UDim2.new(0.92,0,0,0) b.BackgroundColor3=isU and C.BU or C.BA b.BackgroundTransparency=isU and 0.2 or 0.15 b.TextColor3=C.Tx b.TextSize=12 b.Font=Enum.Font.SourceSans b.TextWrapped=true b.TextXAlignment=Enum.TextXAlignment.Left b.TextYAlignment=Enum.TextYAlignment.Top b.RichText=true b.Text=text b.BorderSizePixel=0 b.LayoutOrder=1 b.Parent=fr corner(b,6) pad(b,8,10,8,10)
    
    if not skip then b.BackgroundTransparency=1 b.TextTransparency=1 tw(b,{BackgroundTransparency=isU and 0.2 or 0.15,TextTransparency=0},0.2) end
    
    -- ACTION BUTTONS — only on AI messages
    if not isU then
        local btnFrame=Instance.new("Frame") btnFrame.Size=UDim2.new(0.92,0,0,20) btnFrame.BackgroundTransparency=1 btnFrame.LayoutOrder=2 btnFrame.Parent=fr
        
        local cpBtn=Instance.new("TextButton") cpBtn.Size=UDim2.new(0,40,0,16) cpBtn.Position=UDim2.new(0,0,0,2) cpBtn.BackgroundColor3=C.Pn cpBtn.BackgroundTransparency=0.3 cpBtn.Text="Copy" cpBtn.TextSize=9 cpBtn.TextColor3=C.Mt cpBtn.Font=Enum.Font.SourceSansSemibold cpBtn.AutoButtonColor=false cpBtn.BorderSizePixel=0 cpBtn.Parent=btnFrame corner(cpBtn,3)
        cpBtn.MouseEnter:Connect(function() cpBtn.TextColor3=C.Wh end) cpBtn.MouseLeave:Connect(function() cpBtn.TextColor3=C.Mt end)
        cpBtn.MouseButton1Click:Connect(function()
            local plainText = b.Text:gsub("<.->","")
            copyText(plainText)
            cpBtn.Text="✓" task.delay(1.5,function() cpBtn.Text="Copy" end)
        end)
        
        local exBtn=Instance.new("TextButton") exBtn.Size=UDim2.new(0,56,0,16) exBtn.Position=UDim2.new(0,44,0,2) exBtn.BackgroundColor3=C.Ac exBtn.BackgroundTransparency=0.5 exBtn.Text="→ Chat" exBtn.TextSize=9 exBtn.TextColor3=C.Mt exBtn.Font=Enum.Font.SourceSansSemibold exBtn.AutoButtonColor=false exBtn.BorderSizePixel=0 exBtn.Parent=btnFrame corner(exBtn,3)
        exBtn.MouseEnter:Connect(function() exBtn.TextColor3=C.Wh tw(exBtn,{BackgroundTransparency=0.2},0.1) end)
        exBtn.MouseLeave:Connect(function() exBtn.TextColor3=C.Mt tw(exBtn,{BackgroundTransparency=0.5},0.1) end)
        exBtn.MouseButton1Click:Connect(function()
            local plainText = b.Text:gsub("<.->","")
            exBtn.Text="..." exBtn.TextColor3=C.Gn
            task.spawn(function()
                sendGameChat(plainText)
                task.wait(0.5) exBtn.Text="Sent ✓"
                task.delay(2,function() exBtn.Text="→ Chat" exBtn.TextColor3=C.Mt end)
            end)
        end)
    end
    
    smartScroll()
    return b
end

local function mkAutoN(sn,sm,ai) mOrd=mOrd+1 local fr=Instance.new("Frame") fr.BackgroundTransparency=1 fr.AutomaticSize=Enum.AutomaticSize.Y fr.Size=UDim2.new(1,0,0,0) fr.LayoutOrder=mOrd fr.Parent=cS local bg=Instance.new("Frame") bg.AutomaticSize=Enum.AutomaticSize.Y bg.Size=UDim2.new(0.95,0,0,50) bg.BackgroundColor3=C.Or bg.BackgroundTransparency=0.85 bg.BorderSizePixel=0 bg.Parent=fr corner(bg,6) pad(bg,6,10,6,10) L({t="⚡ "..sn..': "'..sm..'"',s=10,c=C.Or,f=Enum.Font.SourceSansBold,sz=UDim2.new(1,0,0,14),par=bg}) L({t="→ "..ai,s=11,c=C.Tx,f=Enum.Font.SourceSansSemibold,sz=UDim2.new(1,0,0,0),p=UDim2.new(0,0,0,18),par=bg}).AutomaticSize=Enum.AutomaticSize.Y smartScroll() end

local function showTyp() mOrd=mOrd+1 local f=Instance.new("Frame") f.BackgroundTransparency=1 f.Size=UDim2.new(1,0,0,22) f.LayoutOrder=mOrd f.Parent=cS local b=Instance.new("TextLabel") b.Size=UDim2.new(0,50,0,20) b.BackgroundColor3=C.BA b.BackgroundTransparency=0.15 b.Text="..." b.TextColor3=C.Mt b.TextSize=14 b.Font=Enum.Font.SourceSansBold b.BorderSizePixel=0 b.Parent=f corner(b,4) local dots={".  ",".. ","..."} local idx=1 local conn=RS.Heartbeat:Connect(function() idx=idx+1 if idx>#dots*10 then idx=1 end b.Text=dots[math.ceil(idx/10)] end) smartScroll() return f,conn end

-- SEND
local proc,lastS=false,0
local stopGen=false -- flag to stop AI mid-response

-- Stop button (hidden by default, shows during generation)
local stopBtn=Instance.new("TextButton") stopBtn.Size=UDim2.new(0,40,0,28) stopBtn.Position=UDim2.new(1,-78,0.5,0) stopBtn.AnchorPoint=Vector2.new(0,0.5) stopBtn.BackgroundColor3=C.Rd stopBtn.BackgroundTransparency=0.3 stopBtn.Text="Stop" stopBtn.TextSize=10 stopBtn.TextColor3=C.Wh stopBtn.Font=Enum.Font.SourceSansBold stopBtn.AutoButtonColor=false stopBtn.BorderSizePixel=0 stopBtn.Visible=false stopBtn.Parent=iBar corner(stopBtn,4)
stopBtn.MouseButton1Click:Connect(function() stopGen=true end)

local function send()
    if proc then return end
    local text=iBox.Text if not text or text:match("^%s*$") then return end
    if tick()-lastS<2 then return end
    lastS=tick() iBox.Text="" proc=true stopGen=false
    if aTab~="Chat" then swTab("Chat") end
    mkB(text,true) trace("USER: "..text)
    
    -- Detect "say/tell/talk to" commands
    local lo=text:lower()
    local sayCmd=false
    local talkTarget=nil -- player name to focus on
    
    -- Pattern 1: "tell [player] about/that/to/..." or "tell [player] X"
    local tellPlayer = lo:match("tell%s+(%w+)%s+") or lo:match("tell%s+(%w+)$")
    if tellPlayer then sayCmd=true end
    
    -- Pattern 2: "talk to [player]" — sets up continuous conversation
    local talkTo = lo:match("talk%s+to%s+(%w+)")
    if talkTo then
        sayCmd=true
        talkTarget=talkTo
        -- Set auto-reply to focus on this player
        autoInstructions="Focus on talking to "..talkTo..". Respond to their messages naturally. Have a real conversation with them."
        autoConv={}
        trace("⚡ Now focused on: "..talkTo, C.Or)
    end
    
    -- Pattern 3: general say commands
    local sayPatterns={"say ","tell him","tell her","tell them","tell that","respond to","respond with","answer him","answer her","answer them","answer that","reply to","reply with","send in chat","type in chat","chat back","say to"}
    for _,p in ipairs(sayPatterns) do if lo:find(p,1,true) then sayCmd=true break end end
    
    if sayCmd then
        -- Build chat context
        local chatLines={}
        for i=math.max(1,#fullChatLog-50),#fullChatLog do
            chatLines[#chatLines+1]="["..fullChatLog[i].t.."] "..fullChatLog[i].w..": "..fullChatLog[i].m
        end
        local chatCtx=#chatLines>0 and table.concat(chatLines,"\n") or"(no chat)"
        
        -- Find the target player's recent messages for extra context
        local targetCtx=""
        local targetName = tellPlayer or talkTo
        if targetName then
            -- Find matching player
            for _,p in ipairs(P:GetPlayers()) do
                if p.Name:lower():find(targetName,1,true) or p.DisplayName:lower():find(targetName,1,true) then
                    targetName = p.DisplayName
                    local logs = playerChatLogs[p.Name]
                    if logs and #logs>0 then
                        local tl={}
                        for j=1,math.min(10,#logs) do tl[#tl+1]="["..logs[j].t.."] "..logs[j].m end
                        targetCtx="\n\n[TARGET PLAYER: "..p.DisplayName.." ("..p.Name..") — their recent messages]:\n"..table.concat(tl,"\n")
                    end
                    break
                end
            end
        end
        
        local sayPrompt="The user wants you to say something in game chat."
        if targetName then
            sayPrompt=sayPrompt.." You are talking TO "..targetName..". Address them directly."
        end
        sayPrompt=sayPrompt.." Read the chat log and generate ONLY the message to send — no explanation, no quotes, just the exact words to type in chat. Sound like a real player. Under 40 words.\n\n[FULL CHAT LOG]:\n"..chatCtx..targetCtx.."\n\n[USER INSTRUCTION]: "..text.."\n\n[YOUR NAME]: "..plr.DisplayName.."\n\nRespond with ONLY the chat message:"
        
        stopBtn.Visible=true sBtn.Visible=false
        local tF,tC=showTyp() trace("Generating response"..( targetName and (" → "..targetName) or "").."...")
        
        local sayMsgs={{role="user",content=sayPrompt}}
        local ok,resp=callRaw(sayMsgs,AUTO_SYS:gsub("{{INSTRUCTIONS}}",autoInstructions~=""and autoInstructions or"Be a normal player."))
        if tC then tC:Disconnect() end if tF then tF:Destroy() end mOrd=mOrd-1
        updU()
        
        if ok then
            resp=resp:gsub('^"',''):gsub('"$',''):gsub('\n',' '):sub(1,200)
            mkB("→ "..(targetName and("@"..targetName..": ")or"")..resp,false)
            trace("→ Chat: "..resp,C.Gn)
            task.wait(0.5)
            sendGameChat(resp)
            table.insert(autoConv,{role="assistant",content=resp})
        else
            mkB("Error: "..resp,false)
        end
        
        stopBtn.Visible=false sBtn.Visible=true
        smartScroll() proc=false stopGen=false
        return
    end
    
    -- Normal AI chat flow
    stopBtn.Visible=true sBtn.Visible=false
    
    local tF,tC=showTyp() trace("Calling "..select(1,getProv()).."...")
    local ok,resp=callAI(text)
    if tC then tC:Disconnect() end if tF then tF:Destroy() end mOrd=mOrd-1
    if ok then trace("OK ("..#resp.."c)") memLbl.Text=#memory.facts>0 and"🧠"..#memory.facts or""
    else trace("Err: "..resp) resp="Error: "..resp end
    updU()
    
    -- Type out response (interruptable)
    local aB=mkB("",false)
    for i=1,#resp do
        if stopGen then
            aB.Text=string.sub(resp,1,i).." [stopped]"
            trace("Stopped by user")
            break
        end
        aB.Text=string.sub(resp,1,i)
        task.wait(0.006)
    end
    if not stopGen then aB.Text=resp end
    
    -- Hide stop, show send
    stopBtn.Visible=false sBtn.Visible=true
    smartScroll() proc=false stopGen=false
end
iBox.FocusLost:Connect(function(e) if e then send() end end) sBtn.MouseButton1Click:Connect(function() send() end)

-- AUTO-REPLY — with ANTI-FILTER delay
local lastAR,autoProc=0,false
task.spawn(function() while true do task.wait(1) if AUTO_REPLY and API_KEY~=""and not autoProc and #proxChat>0 then local l=proxChat[1] if l and(tick()-l.t)<5 and l.w~=plr.Name and tick()-lastAR>12 then
    local msg=l.m:lower()
    local myName=plr.Name:lower()
    local myDisplay=plr.DisplayName:lower()
    local score = 0 -- Smart detection score (higher = more likely directed at us)
    
    -- +5: They said our name
    if msg:find(myName,1,true) or msg:find(myDisplay,1,true) then score=score+5 end
    -- +3: Direct question
    if l.m:match("%?%s*$") then score=score+3 end
    -- +3: Very few people nearby (1-2)
    local nearbyCount=0
    for _,p in ipairs(P:GetPlayers()) do if p~=plr and isNear(p,60) then nearbyCount=nearbyCount+1 end end
    if nearbyCount<=1 then score=score+4 elseif nearbyCount<=2 then score=score+3 end
    -- +2: Greeting or direct address
    local greets={"hello","hi ","hey ","hey,","yo ","sup","what's up","whats up","excuse me","bro","dude","sir","ma'am","officer","can you","do you","are you","were you","did you","would you","have you","will you","wanna","come here","follow me","stop","wait","look"}
    for _,g in ipairs(greets) do if msg:find(g,1,true) then score=score+2 break end end
    -- +3: They're facing toward us (within 45 degrees)
    pcall(function()
        local sender=P:FindFirstChild(l.w)
        if sender and sender.Character and plr.Character then
            local sRoot=sender.Character:FindFirstChild("HumanoidRootPart")
            local mRoot=plr.Character:FindFirstChild("HumanoidRootPart")
            if sRoot and mRoot then
                local toUs=(mRoot.Position-sRoot.Position).Unit
                local facing=sRoot.CFrame.LookVector
                local dot=toUs:Dot(facing)
                if dot>0.5 then score=score+3 end -- facing within ~60 degrees
            end
        end
    end)
    -- +2: They're the closest player to us
    pcall(function()
        local sender=P:FindFirstChild(l.w)
        if sender and sender.Character and plr.Character then
            local mRoot=plr.Character:FindFirstChild("HumanoidRootPart")
            local sRoot=sender.Character:FindFirstChild("HumanoidRootPart")
            if mRoot and sRoot then
                local dist=(mRoot.Position-sRoot.Position).Magnitude
                local isClosest=true
                for _,op in ipairs(P:GetPlayers()) do
                    if op~=plr and op~=sender and op.Character then
                        local oRoot=op.Character:FindFirstChild("HumanoidRootPart")
                        if oRoot and(mRoot.Position-oRoot.Position).Magnitude<dist then isClosest=false break end
                    end
                end
                if isClosest then score=score+2 end
            end
        end
    end)
    -- +1: Short message (more likely directed at someone specific)
    if #l.m<40 then score=score+1 end
    -- +2: Recent conversation (we replied to them recently)
    for i=math.max(1,#proxChat-5),#proxChat do
        if proxChat[i] and proxChat[i].w==plr.Name then score=score+2 break end
    end
    
    -- Threshold: need at least 3 points to trigger
    if score>=3 then
        autoProc=true lastAR=tick() trace("⚡ ["..score.."] "..l.w..": "..l.m,C.Or)
        local ok,reply=callAutoReply(l.w,l.m)
        if ok and reply then reply=reply:gsub('^"',''):gsub('"$',''):gsub('\n',' '):sub(1,150) trace("⚡ → "..reply,C.Or) task.wait(1) sendGameChat(reply) mkAutoN(l.w,l.m,reply) updU() end
        autoProc=false
    end
    l.t=0
end end end end)

-- KEY PROMPT
local function showKP() local ov=Instance.new("Frame") ov.Size=UDim2.new(1,0,1,0) ov.BackgroundColor3=Color3.new(0,0,0) ov.BackgroundTransparency=0.5 ov.BorderSizePixel=0 ov.ZIndex=50 ov.Parent=gui local bx=Instance.new("Frame") bx.Size=UDim2.new(0,340,0,150) bx.Position=UDim2.new(0.5,0,0.5,0) bx.AnchorPoint=Vector2.new(0.5,0.5) bx.BackgroundColor3=C.Bg bx.BackgroundTransparency=0.06 bx.BorderSizePixel=0 bx.ZIndex=51 bx.Parent=ov corner(bx,8) local bxStr=Instance.new("UIStroke") bxStr.Color=C.Bd bxStr.Parent=bx
local plIm=Instance.new("ImageLabel") plIm.Size=UDim2.new(0,24,0,24) plIm.Position=UDim2.new(0.5,0,0,12) plIm.AnchorPoint=Vector2.new(0.5,0) plIm.BackgroundTransparency=1 plIm.Image="rbxassetid://103486408225648" plIm.ZIndex=52 plIm.Parent=bx
L({t="IsraelAI",s=15,c=C.Wh,f=Enum.Font.SourceSansBold,ax=Enum.TextXAlignment.Center,sz=UDim2.new(1,0,0,18),p=UDim2.new(0,0,0,38),par=bx}).ZIndex=52
L({t="Paste any API key — auto-detects provider",s=11,c=C.Dm,ax=Enum.TextXAlignment.Center,sz=UDim2.new(1,-20,0,16),p=UDim2.new(0,10,0,58),par=bx}).ZIndex=52
local kb=Instance.new("TextBox") kb.Size=UDim2.new(1,-30,0,26) kb.Position=UDim2.new(0,15,0,80) kb.BackgroundColor3=C.Inp kb.BackgroundTransparency=0.15 kb.Text="" kb.PlaceholderText="gsk_... or sk-..." kb.PlaceholderColor3=C.Ft kb.TextColor3=C.Tx kb.TextSize=12 kb.Font=Enum.Font.Code kb.TextXAlignment=Enum.TextXAlignment.Left kb.ClearTextOnFocus=false kb.ClipsDescendants=true kb.BorderSizePixel=0 kb.ZIndex=52 kb.Parent=bx corner(kb,4)
local function dismiss() ov:Destroy() isOpen=true win.Visible=true end
local goB=Instance.new("TextButton") goB.Size=UDim2.new(0,80,0,24) goB.Position=UDim2.new(0.5,5,0,116) goB.BackgroundColor3=C.Ac goB.BackgroundTransparency=0.15 goB.Text="Start" goB.TextSize=12 goB.TextColor3=C.Wh goB.Font=Enum.Font.SourceSansSemibold goB.AutoButtonColor=false goB.BorderSizePixel=0 goB.ZIndex=52 goB.Parent=bx corner(goB,4)
local skB=Instance.new("TextButton") skB.Size=UDim2.new(0,80,0,24) skB.Position=UDim2.new(0.5,-85,0,116) skB.BackgroundColor3=C.Pn skB.BackgroundTransparency=0.3 skB.Text="Skip" skB.TextSize=12 skB.TextColor3=C.Mt skB.Font=Enum.Font.SourceSansSemibold skB.AutoButtonColor=false skB.BorderSizePixel=0 skB.ZIndex=52 skB.Parent=bx corner(skB,4)
goB.MouseButton1Click:Connect(function() local k=kb.Text if k~=""and #k>10 then API_KEY=k cfg.key=k sav(cfg) kIn.Text=string.rep("*",16) kSt.Text=select(1,getProv()) kSt.TextColor3=C.Ac end dismiss() end)
skB.MouseButton1Click:Connect(function() dismiss() end) end

-- INIT
task.defer(function() task.wait(0.3) trace("IsraelAI v7") trace("Provider: "..select(1,getProv())) trace("Memory: "..#memory.facts.." facts") trace("Auto: "..(AUTO_REPLY and"ON"or"OFF"))
mkB("Welcome to <b>IsraelAI v7</b>.\n\n• I have <b>memory</b> — tell me things and I'll remember\n• <b>Copy</b> + <b>→ Chat</b> buttons on every AI response\n• Auto-reply with anti-filter delays\n• Terminal, Players, OSINT, Screen/Chat reader\n• Say \"remember my name is X\" to save facts",false,true)
if API_KEY=="" then showKP() else isOpen=true win.Visible=true end end)
print("[IsraelAI v7] Ready")
