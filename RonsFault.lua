-- Ron's Fault
-- Shows Ron when you die. Because it's his fault.

local ADDON_NAME, ns = ...

local IMAGE_PATH = "Interface\\AddOns\\RonsFault\\ron-warrior"
local IMAGE_WIDTH = 180
local IMAGE_HEIGHT = 240

-------------------------------------------------------------------------------
-- Saved variables
-------------------------------------------------------------------------------

local DEFAULTS = { enabled = true }

-------------------------------------------------------------------------------
-- Main frame (no backdrop, no border, just the image + label)
-------------------------------------------------------------------------------

local frame = CreateFrame("Frame", "RonsFaultFrame", UIParent)
frame:SetSize(IMAGE_WIDTH, IMAGE_HEIGHT + 60)
frame:SetFrameStrata("HIGH")
frame:Hide()

-- Ron image
local image = frame:CreateTexture(nil, "ARTWORK")
image:SetSize(IMAGE_WIDTH, IMAGE_HEIGHT)
image:SetPoint("TOP", frame, "TOP")
image:SetTexture(IMAGE_PATH)

-- "Ron's Fault" label beneath the image (3x size)
local label = frame:CreateFontString(nil, "OVERLAY")
label:SetFont(GameFontNormalLarge:GetFont(), select(2, GameFontNormalLarge:GetFont()) * 3, "OUTLINE")
label:SetPoint("TOP", image, "BOTTOM", 0, -8)
label:SetText("Ron's Fault")

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function HSVtoRGB(h, s, v)
    local c = v * s
    local hp = (h % 360) / 60
    local x = c * (1 - math.abs(hp % 2 - 1))
    local r, g, b = 0, 0, 0
    if hp < 1 then     r, g, b = c, x, 0
    elseif hp < 2 then r, g, b = x, c, 0
    elseif hp < 3 then r, g, b = 0, c, x
    elseif hp < 4 then r, g, b = 0, x, c
    elseif hp < 5 then r, g, b = x, 0, c
    else                r, g, b = c, 0, x
    end
    local m = v - c
    return r + m, g + m, b + m
end

-------------------------------------------------------------------------------
-- Effect 1: Rainbow gradient on the "Ron's Fault" label
-------------------------------------------------------------------------------

local LABEL_TEXT = "Ron's Fault"
local LABEL_LEN = #LABEL_TEXT

local function RainbowStart()
    frame._hue = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self._hue = ((self._hue or 0) + elapsed * 120) % 360
        local colored = ""
        for i = 1, LABEL_LEN do
            local charHue = (self._hue + (i - 1) * (360 / LABEL_LEN)) % 360
            local r, g, b = HSVtoRGB(charHue, 1, 1)
            colored = colored .. string.format("|cff%02x%02x%02x%s|r",
                r * 255, g * 255, b * 255, LABEL_TEXT:sub(i, i))
        end
        label:SetText(colored)
    end)
end

local function RainbowStop()
    frame:SetScript("OnUpdate", nil)
    label:SetText("Ron's Fault")
    label:SetTextColor(1, 1, 1)
end

-------------------------------------------------------------------------------
-- Effect 2: "DON'T RELEASE" sine-wave scroller
-------------------------------------------------------------------------------

local SCROLL_TEXT = "DON'T RELEASE "
local SCROLL_FONT_SIZE = select(2, GameFontNormalLarge:GetFont()) * 9
local SCROLL_SPEED = 300   -- px/sec
local SINE_AMP = 50        -- px vertical amplitude
local SINE_FREQ = 0.015    -- how tight the wave is (per px)
local SINE_SPEED = 3       -- how fast the wave itself moves

local scrollFrame = CreateFrame("Frame", "RonsFaultScrollFrame", UIParent)
scrollFrame:SetAllPoints(UIParent)
scrollFrame:SetFrameStrata("HIGH")
scrollFrame:Hide()

-- Pre-create a pool of character FontStrings (sized at runtime)
local scrollChars = {}
local MAX_CHARS = 80

for i = 1, MAX_CHARS do
    local fs = scrollFrame:CreateFontString(nil, "OVERLAY")
    fs:SetFont(GameFontNormalLarge:GetFont(), SCROLL_FONT_SIZE, "OUTLINE")
    fs:SetTextColor(1, 0.2, 0.2)
    fs:Hide()
    scrollChars[i] = fs
end

local function ScrollStart()
    -- Measure character width
    scrollChars[1]:SetText("W")
    local charW = scrollChars[1]:GetStringWidth()

    -- Only enough characters to fill the screen + one extra repetition for seamless wrap
    local screenW = UIParent:GetWidth()
    local charsNeeded = math.ceil(screenW / charW) + #SCROLL_TEXT
    local charCount = math.min(charsNeeded, MAX_CHARS)
    local totalW = charW * charCount

    for i = 1, MAX_CHARS do
        if i <= charCount then
            local idx = ((i - 1) % #SCROLL_TEXT) + 1
            scrollChars[i]:SetText(SCROLL_TEXT:sub(idx, idx))
        else
            scrollChars[i]:Hide()
        end
    end

    scrollFrame._time = 0
    scrollFrame._charW = charW
    scrollFrame._totalW = totalW
    scrollFrame._charCount = charCount

    scrollFrame:SetScript("OnUpdate", function(self, elapsed)
        self._time = self._time + elapsed
        local offsetX = (self._time * SCROLL_SPEED) % self._totalW

        for i = 1, self._charCount do
            local x = (i - 1) * self._charW - offsetX
            while x < -self._charW do
                x = x + self._totalW
            end
            local y = math.sin(x * SINE_FREQ + self._time * SINE_SPEED) * SINE_AMP

            scrollChars[i]:ClearAllPoints()
            scrollChars[i]:SetPoint("BOTTOMLEFT", UIParent, "LEFT", x, y)
            scrollChars[i]:Show()
        end
    end)

    scrollFrame:Show()
end

local function ScrollStop()
    scrollFrame:SetScript("OnUpdate", nil)
    for i = 1, MAX_CHARS do
        scrollChars[i]:Hide()
    end
    scrollFrame:Hide()
end

-------------------------------------------------------------------------------
-- Effects table (picked at random each death)
-------------------------------------------------------------------------------

local EFFECTS = {
    { start = RainbowStart,  stop = RainbowStop },
}

local activeEffect = nil

local function StartEffect()
    local effect = EFFECTS[math.random(#EFFECTS)]
    effect.start()
    activeEffect = effect
end

local function StopEffect()
    if activeEffect then
        activeEffect.stop()
        activeEffect = nil
    end
end

-------------------------------------------------------------------------------
-- Core logic
-------------------------------------------------------------------------------

local function Show()
    if not RonsFaultDB or not RonsFaultDB.enabled then return end

    local popup = StaticPopup1
    if popup and popup:IsShown() then
        frame:SetParent(popup)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", popup, "BOTTOM", popup:GetWidth() / 2, 0)
    else
        frame:SetParent(UIParent)
        frame:ClearAllPoints()
        frame:SetPoint("LEFT", UIParent, "TOP", 0, -235)
    end
    frame:SetFrameStrata("HIGH")
    StartEffect()
    ScrollStart()
    frame:Show()
end

local function Hide()
    StopEffect()
    ScrollStop()
    frame:Hide()
    frame:SetParent(UIParent)
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_UNGHOST")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == ADDON_NAME then
            if not RonsFaultDB then
                RonsFaultDB = CopyTable(DEFAULTS)
            end
            self:UnregisterEvent("ADDON_LOADED")
            print("|cffff4444Ron's Fault|r loaded. /rf test to preview.")
        end

    elseif event == "PLAYER_DEAD" then
        C_Timer.After(0.1, Show)

    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        Hide()
    end
end)

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------

SLASH_RONSFAULT1 = "/ronsfault"
SLASH_RONSFAULT2 = "/rf"

SlashCmdList["RONSFAULT"] = function(input)
    local cmd = strtrim(input):lower()

    if cmd == "toggle" then
        RonsFaultDB.enabled = not RonsFaultDB.enabled
        local state = RonsFaultDB.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
        print("|cffff4444Ron's Fault|r is now " .. state)
    elseif cmd == "test" then
        StaticPopup_Show("DEATH")
        C_Timer.After(0.1, Show)
    elseif cmd == "hide" then
        StaticPopup_Hide("DEATH")
        Hide()
    else
        print("|cffff4444Ron's Fault|r commands:")
        print("  /rf toggle - Enable/disable")
        print("  /rf test   - Preview")
        print("  /rf hide   - Hide")
    end
end
