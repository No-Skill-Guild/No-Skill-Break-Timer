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
	"Tek3",
	"Tek4",
	"Gornag",
	"Gornag2",
	"Wood",
	"Denied",
	"Paint1",
	"Paint2",
	"Paint3",
	"Paint4",
	"Paint5",
	"Paint6",
	"Paint7",
	"Paint8",
	"Paint9",
	"Paint10",
	"Paint11",
    "Paint12",
}

local MIN_SIZE = 200
local MIN_WIDTH = 320 -- room for the countdown, header and close button
local MAX_SIZE = 900

---------------------------------------------------------------------
-- Flat "modern" skin (ElvUI-style: dark fill, 1px borders, accent line)
---------------------------------------------------------------------
local FONT = "Fonts\\ARIALN.TTF"
local TITLE_HEIGHT = 24
local HEADER_HEIGHT = 36 -- taller title bar for the main frame's big header
local PADDING = 6
local ACCENT = { r = 0.0, g = 0.8, b = 0.4 }
local BG_COLOR = { r = 0.06, g = 0.06, b = 0.06, a = 0.92 }
local TITLE_COLOR = { r = 0.10, g = 0.10, b = 0.10, a = 1 }
local BORDER_COLOR = { r = 0, g = 0, b = 0, a = 1 }
local INSET_BORDER_COLOR = { r = 0.20, g = 0.20, b = 0.20, a = 1 }

-- 1 physical pixel border drawn with four textures so it stays crisp at any UI scale
local function CreatePixelBorder(f, color)
    local edges = {}
    for i = 1, 4 do
        local t = f:CreateTexture(nil, "BORDER", nil, 7)
        t:SetColorTexture(color.r, color.g, color.b, color.a)
        edges[i] = t
    end
    local top, bottom, left, right = edges[1], edges[2], edges[3], edges[4]
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT")
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT")
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT")
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT")
    PixelUtil.SetHeight(top, 1, 1)
    PixelUtil.SetHeight(bottom, 1, 1)
    PixelUtil.SetWidth(left, 1, 1)
    PixelUtil.SetWidth(right, 1, 1)
end

local function CreateFlatCloseButton(parent, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(TITLE_HEIGHT, TITLE_HEIGHT)
    local lines = {}
    for i, angle in ipairs({ 45, -45 }) do
        local line = btn:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1, 1)
        line:SetSize(12, 2)
        line:SetPoint("CENTER")
        line:SetRotation(math.rad(angle))
        line:SetVertexColor(0.7, 0.7, 0.7)
        lines[i] = line
    end
    btn:SetScript("OnEnter", function()
        for _, line in ipairs(lines) do line:SetVertexColor(1, 0.3, 0.3) end
    end)
    btn:SetScript("OnLeave", function()
        for _, line in ipairs(lines) do line:SetVertexColor(0.7, 0.7, 0.7) end
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Skins a frame and returns (titleBar, titleText, content, accent) where
-- content is a bordered inset area for the meme texture and accent is the
-- line under the title bar.
local function ApplyModernSkin(f, titleHeight)
    titleHeight = titleHeight or TITLE_HEIGHT
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a)
    CreatePixelBorder(f, BORDER_COLOR)

    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(titleHeight)
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(1, 1, 1, 1)
    titleBg:SetGradient("VERTICAL",
        CreateColor(TITLE_COLOR.r * 0.6, TITLE_COLOR.g * 0.6, TITLE_COLOR.b * 0.6, TITLE_COLOR.a),
        CreateColor(TITLE_COLOR.r * 1.5, TITLE_COLOR.g * 1.5, TITLE_COLOR.b * 1.5, TITLE_COLOR.a))

    local accent = titleBar:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT")
    accent:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT")
    accent:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    PixelUtil.SetHeight(accent, 1, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT, 14, "OUTLINE")
    titleText:SetShadowOffset(0, 0)
    titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)

    local closeButton = CreateFlatCloseButton(titleBar, function() f:Hide() end)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", 0, 0)

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", PADDING - 1, -PADDING)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, PADDING)
    local contentBg = content:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0, 0, 0, 0.6)
    CreatePixelBorder(content, INSET_BORDER_COLOR)

    return titleBar, titleText, content, accent
end

---------------------------------------------------------------------
-- Main display frame
---------------------------------------------------------------------
local frame = CreateFrame("Frame", "NoSkillBreakTimerFrame", UIParent)
frame:SetSize(512, 560)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(true)
frame:Hide()

local titleBar, headerText, memeContent, titleAccent = ApplyModernSkin(frame, HEADER_HEIGHT)

-- Accent-colored header with a soft drop shadow instead of a heavy outline
headerText:SetFont(FONT, 22, "")
headerText:SetShadowColor(0, 0, 0, 0.9)
headerText:SetShadowOffset(1, -1)
headerText:ClearAllPoints()
headerText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
headerText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b)
headerText:SetText("BREAK TIME")

-- Remaining-time countdown in the top left
local timerText = titleBar:CreateFontString(nil, "OVERLAY")
timerText:SetFont(FONT, 16, "")
timerText:SetShadowColor(0, 0, 0, 0.9)
timerText:SetShadowOffset(1, -1)
timerText:SetPoint("LEFT", titleBar, "LEFT", 10, 0)

-- The accent line doubles as a progress bar that drains as the break runs
PixelUtil.SetHeight(titleAccent, 4, 4)
titleAccent:SetAlpha(0.2)
local progressBar = CreateFrame("StatusBar", nil, titleBar)
progressBar:SetAllPoints(titleAccent)
progressBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
progressBar:SetStatusBarColor(ACCENT.r, ACCENT.g, ACCENT.b)
progressBar:SetMinMaxValues(0, 1)
progressBar:SetValue(1)

local memeTexture = memeContent:CreateTexture(nil, "ARTWORK")
memeTexture:SetPoint("TOPLEFT", 1, -1)
memeTexture:SetPoint("BOTTOMRIGHT", -1, 1)

local resizer = CreateFrame("Button", nil, frame)
resizer:SetSize(14, 14)
resizer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
resizer:SetFrameLevel(memeContent:GetFrameLevel() + 2)
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizer:GetNormalTexture():SetDesaturated(true)
resizer:GetNormalTexture():SetVertexColor(0.6, 0.6, 0.6)
resizer:GetPushedTexture():SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b)

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
        frame:SetResizeBounds(MIN_WIDTH, MIN_SIZE + 48, MAX_SIZE, MAX_SIZE + 48)
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
-- Enabled memes helper
---------------------------------------------------------------------
local function GetEnabledMemes()
    local enabled = {}
    for _, name in ipairs(MEME_FILES) do
        if NoSkillBreakTimerDB.memes[name] ~= false then
            enabled[#enabled + 1] = name
        end
    end
    return enabled
end

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local isRunning = false
local isTesting = false
local hideTimer = nil
local lastMemeIndex = 0
local breakDuration = 0
local breakEndTime = 0

---------------------------------------------------------------------
-- Countdown display
---------------------------------------------------------------------
local TEST_DURATION = 120 -- demo countdown shown in test mode
local UPDATE_INTERVAL = 0.1
local WARNING_SECONDS = 60  -- yellow below this
local CRITICAL_SECONDS = 30 -- red below this

local function FormatTime(seconds)
    seconds = math.max(0, math.ceil(seconds))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function UpdateCountdown()
    local remaining = math.max(0, breakEndTime - GetTime())
    if remaining < CRITICAL_SECONDS then
        timerText:SetTextColor(1, 0.3, 0.3)
    elseif remaining < WARNING_SECONDS then
        timerText:SetTextColor(1, 0.85, 0.2)
    else
        timerText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b)
    end
    timerText:SetText(FormatTime(remaining))
    progressBar:SetValue(breakDuration > 0 and remaining / breakDuration or 0)
end

local function SetCountdown(seconds)
    breakDuration = seconds
    breakEndTime = GetTime() + seconds
    UpdateCountdown()
end

local sinceLastUpdate = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    sinceLastUpdate = sinceLastUpdate + elapsed
    if sinceLastUpdate >= UPDATE_INTERVAL then
        sinceLastUpdate = 0
        UpdateCountdown()
    end
end)

---------------------------------------------------------------------
-- Meme selection
---------------------------------------------------------------------
local function ShowRandomMeme()
    local enabled = GetEnabledMemes()
    if #enabled == 0 then
        memeTexture:SetTexture(nil)
        return
    end
    local idx
    if #enabled == 1 then
        idx = 1
    else
        repeat
            idx = math.random(1, #enabled)
        until idx ~= lastMemeIndex
    end
    lastMemeIndex = idx
    memeTexture:SetTexture(MEME_PATH .. enabled[idx])
end

---------------------------------------------------------------------
-- Core start/stop
---------------------------------------------------------------------
local function StartBreak(seconds, source)
    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then return end
    if InCombatLockdown() or C_InstanceEncounter.IsEncounterInProgress() then return end

    isTesting = false
    isRunning = true
    SetCountdown(seconds)
    ShowRandomMeme()
    frame:Show()

    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end

    hideTimer = C_Timer.NewTimer(seconds, function()
        isRunning = false
        hideTimer = nil
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

-- Keep state in sync no matter how the frame is hidden (close button,
-- timer expiry, StopBreak) so Toggle Test never gets stuck.
-- IsShown() stays true when only UIParent is hidden (Alt+Z, cinematics),
-- so ignore those and let the break keep running.
frame:SetScript("OnHide", function(self)
    if self:IsShown() then return end
    isTesting = false
    isRunning = false
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end)

local function ToggleTest()
    if isTesting then
        isTesting = false
        frame:Hide()
    elseif isRunning then
        -- Don't start test mode while a real break is active
        return
    else
        isTesting = true
        SetCountdown(TEST_DURATION)
        ShowRandomMeme()
        frame:Show()
    end
end

local function ResetPosition()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
    frame:SetSize(512, 560)
    NoSkillBreakTimerDB.point = nil
    NoSkillBreakTimerDB.relPoint = nil
    NoSkillBreakTimerDB.x = nil
    NoSkillBreakTimerDB.y = nil
    NoSkillBreakTimerDB.width = nil
    NoSkillBreakTimerDB.height = nil
end

---------------------------------------------------------------------
-- HOOK 1: DBM Callback API
-- Strict: only trust timerType == "break", no substring matching
---------------------------------------------------------------------
local dbmHooked = false

local function HookDBMCallbacks()
    if dbmHooked or not DBM then return end
    dbmHooked = true

    if DBM.RegisterCallback then
        DBM:RegisterCallback("DBM_TimerStart", function(event, id, msg, timer, icon, timerType, spellId, dbmType, ...)
            timerType = scrubsecretvalues(timerType)
            if timerType == "break" and timer and timer > 0 then
                StartBreak(timer, "DBM callback")
            end
        end)
        DBM:RegisterCallback("DBM_TimerStop", function(event, id)
            id = scrubsecretvalues(id)
            if type(id) == "string" and id:lower():find("^break") then
                StopBreak()
            end
        end)
    end

    -- hooksecurefunc on known break timer functions (receive minutes)
    -- Note: timer <= 60 is assumed to be minutes since /dbm break takes minutes
    for _, funcName in ipairs({"StartBreakTimer", "breakTimerStart", "CreateBreakTimer"}) do
        if DBM[funcName] then
            hooksecurefunc(DBM, funcName, function(self, timer, ...)
                if timer and timer > 0 then
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
-- DBM syncs break timer as "BT\t<minutes>"
---------------------------------------------------------------------
local addonListener = CreateFrame("Frame")
addonListener:RegisterEvent("CHAT_MSG_ADDON")
addonListener:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= "D4" and prefix ~= "D5" then return end

    local btTime = msg:match("^BT\t(%d+)")
    if btTime then
        local minutes = tonumber(btTime)
        if minutes and minutes > 0 then
            StartBreak(minutes * 60, prefix .. " addon msg")
        elseif minutes == 0 then
            StopBreak()
        end
        return
    end

    if msg:match("^BTC") then
        StopBreak()
    end
end)

---------------------------------------------------------------------
-- HOOK 3: BigWigs break bar via callback system
-- Matches any text starting with "Break". Combat guard in StartBreak
-- is the primary protection against false positives.
-- Uses scrubsecretvalues() to handle Midnight's tainted strings.
---------------------------------------------------------------------
local bigWigsHooked = false

local function IsLikelyBreakText(s)
    s = scrubsecretvalues(s)
    if type(s) ~= "string" then return false end
    return s:lower():find("^break") ~= nil
end

local function HookBigWigs()
    if bigWigsHooked then return end

    local registrar = BigWigsLoader or BigWigs
    if not registrar or not registrar.RegisterMessage then return end

    local plugin = {}
    registrar.RegisterMessage(plugin, "BigWigs_StartBar", function(event, mod, key, text, time, icon)
        if (IsLikelyBreakText(key) or IsLikelyBreakText(text)) and time and time > 0 then
            StartBreak(time, "BigWigs bar")
        end
    end)
    registrar.RegisterMessage(plugin, "BigWigs_StopBar", function(event, mod, text)
        if isRunning and IsLikelyBreakText(text) then
            StopBreak()
        end
    end)
    bigWigsHooked = true
end

---------------------------------------------------------------------
-- Preview frame (popup for previewing memes in options)
---------------------------------------------------------------------
local previewFrame = CreateFrame("Frame", "NSBT_PreviewFrame", UIParent)
previewFrame:SetSize(300, 340)
previewFrame:SetPoint("CENTER")
previewFrame:SetFrameStrata("TOOLTIP")
previewFrame:SetMovable(true)
previewFrame:EnableMouse(true)
previewFrame:RegisterForDrag("LeftButton")
previewFrame:SetScript("OnDragStart", previewFrame.StartMoving)
previewFrame:SetScript("OnDragStop", previewFrame.StopMovingOrSizing)
previewFrame:Hide()

local _, previewTitle, previewContent = ApplyModernSkin(previewFrame)
previewTitle:SetTextColor(0.9, 0.9, 0.9)

local previewTexture = previewContent:CreateTexture(nil, "ARTWORK")
previewTexture:SetPoint("TOPLEFT", 1, -1)
previewTexture:SetPoint("BOTTOMRIGHT", -1, 1)

---------------------------------------------------------------------
-- Options panel
---------------------------------------------------------------------
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel:SetSize(600, 400)

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("No Skill Break Timer")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Shows a random meme during DBM/BigWigs break timers.")

    -- Lock checkbox (UICheckButtonTemplate)
    local lockCheck = CreateFrame("CheckButton", "NSBT_LockCheck", panel, "UICheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -2, -12)

    local lockLabel = lockCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lockLabel:SetPoint("LEFT", lockCheck, "RIGHT", 4, 1)
    lockLabel:SetText("Lock frame (prevent moving and resizing)")
    lockCheck.label = lockLabel

    lockCheck:SetChecked(NoSkillBreakTimerDB and NoSkillBreakTimerDB.locked or false)
    lockCheck:SetScript("OnClick", function(self)
        NoSkillBreakTimerDB.locked = self:GetChecked()
        ApplyLockState()
    end)

    -- Test button
    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(120, 24)
    testBtn:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 2, -8)
    testBtn:SetText("Toggle Test")
    testBtn:SetScript("OnClick", function()
        ToggleTest()
    end)

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 24)
    resetBtn:SetPoint("LEFT", testBtn, "RIGHT", 8, 0)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        ResetPosition()
    end)

    local testDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    testDesc:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
    testDesc:SetText("Unlock > Test > drag/resize > Lock")

    -- Meme list header
    local memeHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    memeHeader:SetPoint("TOPLEFT", testBtn, "BOTTOMLEFT", 0, -16)
    memeHeader:SetText("Memes")

    local memeDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    memeDesc:SetPoint("LEFT", memeHeader, "RIGHT", 8, 0)
    memeDesc:SetText("(uncheck to disable, click Preview to see)")

    -- Select All / Deselect All buttons
    local selectAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(90, 20)
    selectAllBtn:SetPoint("LEFT", memeDesc, "RIGHT", 12, 0)
    selectAllBtn:SetText("Select All")

    local deselectAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deselectAllBtn:SetSize(100, 20)
    deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 4, 0)
    deselectAllBtn:SetText("Deselect All")

    -- Scroll frame for meme list
    local scrollFrame = CreateFrame("ScrollFrame", "NSBT_MemeScroll", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", memeHeader, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Build meme rows
    local ROW_HEIGHT = 26
    local PREVIEW_X = 150
    local checkboxes = {}

    for i, memeName in ipairs(MEME_FILES) do
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(400, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        -- Checkbox (UICheckButtonTemplate)
        local cb = CreateFrame("CheckButton", "NSBT_Meme_" .. memeName, row, "UICheckButtonTemplate")
        cb:SetPoint("LEFT", row, "LEFT", 0, 0)

        local cbLabel = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        cbLabel:SetPoint("LEFT", cb, "RIGHT", 4, 1)
        cbLabel:SetText(memeName)
        cb.label = cbLabel

        cb:SetChecked(NoSkillBreakTimerDB.memes[memeName] ~= false)
        cb:SetScript("OnClick", function(self)
            NoSkillBreakTimerDB.memes[memeName] = self:GetChecked()
        end)

        -- Preview button (fixed position)
        local previewBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        previewBtn:SetSize(64, 20)
        previewBtn:SetPoint("LEFT", row, "LEFT", PREVIEW_X, 0)
        previewBtn:SetText("Preview")
        previewBtn:SetScript("OnClick", function()
            previewTitle:SetText(memeName)
            previewTexture:SetTexture(MEME_PATH .. memeName)
            previewFrame:Show()
        end)

        checkboxes[memeName] = cb
    end

    scrollChild:SetHeight(#MEME_FILES * ROW_HEIGHT)
    scrollChild:SetWidth(400)

    -- Wire up Select All / Deselect All
    selectAllBtn:SetScript("OnClick", function()
        for _, memeName in ipairs(MEME_FILES) do
            NoSkillBreakTimerDB.memes[memeName] = true
            if checkboxes[memeName] then
                checkboxes[memeName]:SetChecked(true)
            end
        end
    end)

    deselectAllBtn:SetScript("OnClick", function()
        for _, memeName in ipairs(MEME_FILES) do
            NoSkillBreakTimerDB.memes[memeName] = false
            if checkboxes[memeName] then
                checkboxes[memeName]:SetChecked(false)
            end
        end
    end)

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
    elseif cmd == "reset" then
        ResetPosition()
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
        NoSkillBreakTimerDB = { locked = true, memes = {} }
    end
    if NoSkillBreakTimerDB.locked == nil then
        NoSkillBreakTimerDB.locked = true
    end
    if not NoSkillBreakTimerDB.memes then
        NoSkillBreakTimerDB.memes = {}
    end

    -- Default all memes to enabled
    for _, name in ipairs(MEME_FILES) do
        if NoSkillBreakTimerDB.memes[name] == nil then
            NoSkillBreakTimerDB.memes[name] = true
        end
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

    C_ChatInfo.RegisterAddonMessagePrefix("D4")
    C_ChatInfo.RegisterAddonMessagePrefix("D5")

    HookDBMCallbacks()
    HookBigWigs()

    -- Late-load hook for DBM/BigWigs if they load after us
    if not dbmHooked or not bigWigsHooked then
        local lateLoader = CreateFrame("Frame")
        lateLoader:RegisterEvent("ADDON_LOADED")
        lateLoader:SetScript("OnEvent", function(self2, ev, addon)
            if not dbmHooked and DBM then
                HookDBMCallbacks()
            end
            if not bigWigsHooked and (BigWigsLoader or BigWigs) then
                HookBigWigs()
            end
            if dbmHooked and bigWigsHooked then
                self2:UnregisterAllEvents()
            end
        end)
    end

    settingsCategory = CreateOptionsPanel()
    self:UnregisterAllEvents()
end)
