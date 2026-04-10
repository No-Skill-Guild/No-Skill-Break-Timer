-- No Skill Break Timer
-- Hooks into DBM, BigWigs, and Blizzard countdown to show a meme during breaks
-- Uses multiple detection methods for maximum compatibility

local ADDON_NAME = "NoSkillBreakTimer"
local MEME_PATH = "Interface\\AddOns\\NoSkillBreakTimer\\Memes\\"

local MEME_FILES = {
    "Bingo1",
    "Cyc1",
    "Elijah1",
    "Elijah2",
    "Menu",
    "NS_Logo",
    "Pad1",
    "Richard1",
    "Rocky1",
    "Rocky2",
    "Rocky3",
    "Rocky4",
    "Tank",
    "Tehlmar1",
    "Tek1",
    "Tek2",
}

local MIN_SIZE = 200
local MAX_SIZE = 900

---------------------------------------------------------------------
-- Main display frame
---------------------------------------------------------------------
local frame = CreateFrame("Frame", "NoSkillBreakTimerFrame", UIParent, "BackdropTemplate")
frame:SetSize(512, 560)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(true)
frame:Hide()

frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function() frame:Hide() end)

local headerText = frame:CreateFontString(nil, "OVERLAY")
headerText:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
headerText:SetPoint("TOP", frame, "TOP", 0, -16)
headerText:SetText("|cff00ff00BREAK TIME|r")

local memeTexture = frame:CreateTexture(nil, "ARTWORK")
memeTexture:SetPoint("TOP", headerText, "BOTTOM", 0, -8)
memeTexture:SetPoint("LEFT", frame, "LEFT", 16, 0)
memeTexture:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
memeTexture:SetPoint("BOTTOM", frame, "BOTTOM", 0, 16)

local resizer = CreateFrame("Button", nil, frame)
resizer:SetSize(16, 16)
resizer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

---------------------------------------------------------------------
-- Lock/Unlock
---------------------------------------------------------------------
local function SavePosition()
    if NoSkillBreakTimerDB then
        local point, _, relPoint, x, y = frame:GetPoint()
        NoSkillBreakTimerDB.point = point
        NoSkillBreakTimerDB.relPoint = relPoint
        NoSkillBreakTimerDB.x = x
        NoSkillBreakTimerDB.y = y
        NoSkillBreakTimerDB.width = frame:GetWidth()
        NoSkillBreakTimerDB.height = frame:GetHeight()
    end
end

local function ApplyLockState()
    local locked = NoSkillBreakTimerDB and NoSkillBreakTimerDB.locked
    frame:SetMovable(not locked)
    frame:SetResizable(not locked)
    if not locked then
        frame:SetResizeBounds(MIN_SIZE, MIN_SIZE + 48, MAX_SIZE, MAX_SIZE + 48)
    end
    frame:RegisterForDrag(not locked and "LeftButton" or "")
    resizer:SetShown(not locked)
end

frame:SetScript("OnDragStart", function(self)
    if not NoSkillBreakTimerDB.locked then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
end)

resizer:SetScript("OnMouseDown", function()
    if not NoSkillBreakTimerDB.locked then
        frame:StartSizing("BOTTOMRIGHT")
    end
end)

resizer:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    SavePosition()
end)

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local isRunning = false
local isTesting = false
local hideTimer = nil
local lastMemeIndex = 0

---------------------------------------------------------------------
-- Meme selection
---------------------------------------------------------------------
local function ShowRandomMeme()
    local idx
    if #MEME_FILES == 1 then
        idx = 1
    else
        repeat
            idx = math.random(1, #MEME_FILES)
        until idx ~= lastMemeIndex
    end
    lastMemeIndex = idx
    memeTexture:SetTexture(MEME_PATH .. MEME_FILES[idx])
end

---------------------------------------------------------------------
-- Core start/stop
---------------------------------------------------------------------
local function StartBreak(seconds, source)
    isTesting = false
    isRunning = true
    headerText:SetText("|cff00ff00BREAK TIME|r")
    ShowRandomMeme()
    frame:Show()

    if hideTimer then
        hideTimer:Cancel()
    end
    hideTimer = C_Timer.NewTimer(seconds, function()
        isRunning = false
        frame:Hide()
    end)
end

local function StopBreak()
    isRunning = false
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
    frame:Hide()
end

local function ToggleTest()
    if isTesting then
        isTesting = false
        frame:Hide()
    else
        isTesting = true
        headerText:SetText("|cff00ff00BREAK TIME|r")
        ShowRandomMeme()
        frame:Show()
    end
end

---------------------------------------------------------------------
-- HOOK 1: DBM Callback API (the official public API)
-- DBM fires "DBM_TimerStart" with simpleType "break"
---------------------------------------------------------------------
local function HookDBMCallbacks()
    if not DBM then return end

    -- Method A: RegisterCallback (modern DBM public API)
    if DBM.RegisterCallback then
        local callbackHandler = {}
        DBM:RegisterCallback("DBM_TimerStart", function(event, id, msg, timer, icon, timerType, spellId, dbmType, ...)
            -- dbmType/simpleType for break timers is "break"
            if timerType == "break" or (msg and type(msg) == "string" and msg:lower():find("break")) then
                    StartBreak(timer, "DBM callback")
            end
        end)
    end

    -- Method B: hooksecurefunc on known break timer functions
    -- These receive time in MINUTES from /dbm break
    for _, funcName in ipairs({"StartBreakTimer", "breakTimerStart", "CreateBreakTimer"}) do
        if DBM[funcName] then
            hooksecurefunc(DBM, funcName, function(self, timer, ...)
                if timer and timer > 0 then
                    -- DBM break functions receive minutes; convert to seconds
                    local seconds = timer <= 60 and timer * 60 or timer
                    StartBreak(seconds, "DBM " .. funcName)
                end
            end)
            break
        end
    end
end

---------------------------------------------------------------------
-- HOOK 2: Addon message listener (D4 and D5 prefixes)
-- DBM break timer sync: "BT\t<minutes>"
-- DBM's /dbm break command takes MINUTES and syncs the raw value
---------------------------------------------------------------------
local addonListener = CreateFrame("Frame")
addonListener:RegisterEvent("CHAT_MSG_ADDON")
addonListener:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= "D4" and prefix ~= "D5" then return end

    -- Break timer start: BT\t<minutes>
    local btTime = msg:match("^BT\t(%d+)")
    if btTime then
        local minutes = tonumber(btTime)
        if minutes and minutes > 0 then
            StartBreak(minutes * 60, prefix .. " addon msg")
        end
        return
    end

    -- Break timer cancel
    if msg:match("^BTC") and isRunning then
        StopBreak()
    end
end)

---------------------------------------------------------------------
-- HOOK 3: BigWigs break bar via callback system
-- BigWigs_StartBar args: event, module, key, text, time, icon
-- The "text" contains the display string (e.g. "Break"), key may be
-- numeric or a string. Check both.
---------------------------------------------------------------------
local bigWigsHooked = false

local function HookBigWigs()
    if bigWigsHooked then return end

    -- Try BigWigsLoader first (available early), then BigWigs global
    local registrar = BigWigsLoader or BigWigs
    if not registrar or not registrar.RegisterMessage then return end

    local plugin = {}
    registrar.RegisterMessage(plugin, "BigWigs_StartBar", function(event, mod, key, text, time, icon)
        local isBreak = false
        -- Check key
        if key and type(key) == "string" and key:lower():find("break") then
            isBreak = true
        end
        -- Check display text
        if text and type(text) == "string" and text:lower():find("break") then
            isBreak = true
        end
        if isBreak and time and time > 0 then
            StartBreak(time, "BigWigs bar")
        end
    end)
    registrar.RegisterMessage(plugin, "BigWigs_StopBar", function(event, mod, text)
        if isRunning then
            local isBreak = false
            if text and type(text) == "string" and text:lower():find("break") then
                isBreak = true
            end
            if isBreak then
                StopBreak()
            end
        end
    end)
    bigWigsHooked = true
end

---------------------------------------------------------------------
-- HOOK 4: Blizzard countdown (C_PartyInfo.DoCountdown)
-- DBM uses this internally for break timers in Midnight
---------------------------------------------------------------------
local countdownListener = CreateFrame("Frame")
countdownListener:RegisterEvent("START_TIMER")
countdownListener:SetScript("OnEvent", function(self, event, timerType, timeRemaining, totalTime)
    -- timerType 2 = party countdown
    -- Trigger on any countdown >= 60s as a likely break timer
    if totalTime and totalTime >= 60 then
        StartBreak(totalTime, "Blizzard countdown")
    end
end)

---------------------------------------------------------------------
-- HOOK 5: Chat message detection (fallback)
-- Catches DBM/BigWigs break announcements in raid warning
---------------------------------------------------------------------
local chatListener = CreateFrame("Frame")
chatListener:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatListener:SetScript("OnEvent", function(self, event, msg, sender)
    if msg then
        -- DBM break start messages like "Break time started" or "Break Starting Now"
        local breakMin = msg:match("[Bb]reak.-(%d+)%s*min")
        if breakMin then
            local minutes = tonumber(breakMin)
            if minutes and minutes > 0 then
                StartBreak(minutes * 60, "raid warning")
            end
        end
    end
end)

---------------------------------------------------------------------
-- Options panel
---------------------------------------------------------------------
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel:SetSize(300, 200)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("No Skill Break Timer")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Shows a random meme during DBM/BigWigs break timers.")

    local lockCheck = CreateFrame("CheckButton", "NSBT_LockCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -2, -16)
    lockCheck.Text:SetText("Lock frame (prevent moving and resizing)")
    lockCheck:SetChecked(NoSkillBreakTimerDB and NoSkillBreakTimerDB.locked or false)
    lockCheck:SetScript("OnClick", function(self)
        NoSkillBreakTimerDB.locked = self:GetChecked()
        ApplyLockState()
    end)

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(140, 24)
    testBtn:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 2, -16)
    testBtn:SetText("Toggle Test")
    testBtn:SetScript("OnClick", function()
        ToggleTest()
    end)

    local testDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    testDesc:SetPoint("LEFT", testBtn, "RIGHT", 8, 0)
    testDesc:SetText("Preview the frame to adjust position/size")

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", testBtn, "BOTTOMLEFT", 0, -12)
    hint:SetText("Unlock > Test > drag to move, corner grip to resize > Lock")

    local category = Settings.RegisterCanvasLayoutCategory(panel, "No Skill Break Timer")
    Settings.RegisterAddOnCategory(category)
    return category
end

---------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------
local settingsCategory

SLASH_NSBT1 = "/nsbt"

SlashCmdList["NSBT"] = function(msg)
    local cmd = msg:match("^(%S+)") or ""
    cmd = cmd:lower()

    if cmd == "lock" then
        NoSkillBreakTimerDB.locked = not NoSkillBreakTimerDB.locked
        ApplyLockState()
        if NSBT_LockCheck then
            NSBT_LockCheck:SetChecked(NoSkillBreakTimerDB.locked)
        end
    elseif cmd == "test" then
        ToggleTest()
    else
        if settingsCategory then
            Settings.OpenToCategory(settingsCategory:GetID())
        end
    end
end

---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if not NoSkillBreakTimerDB then
        NoSkillBreakTimerDB = { locked = true }
    end
    if NoSkillBreakTimerDB.locked == nil then
        NoSkillBreakTimerDB.locked = true
    end
    local db = NoSkillBreakTimerDB

    if db.width and db.height then
        frame:SetSize(db.width, db.height)
    end
    if db.point then
        frame:ClearAllPoints()
        frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
    end

    ApplyLockState()

    -- Register addon message prefixes
    C_ChatInfo.RegisterAddonMessagePrefix("D4")
    C_ChatInfo.RegisterAddonMessagePrefix("D5")

    -- Hook DBM and BigWigs
    HookDBMCallbacks()
    HookBigWigs()

    -- If DBM or BigWigs loads later, hook them then
    if not DBM or not bigWigsHooked then
        local lateLoader = CreateFrame("Frame")
        lateLoader:RegisterEvent("ADDON_LOADED")
        lateLoader:SetScript("OnEvent", function(self2, ev, addon)
            if DBM then
                HookDBMCallbacks()
            end
            if not bigWigsHooked and (BigWigsLoader or BigWigs) then
                HookBigWigs()
            end
            if DBM and bigWigsHooked then
                self2:UnregisterAllEvents()
            end
        end)
    end

    settingsCategory = CreateOptionsPanel()
    self:UnregisterAllEvents()
end)
