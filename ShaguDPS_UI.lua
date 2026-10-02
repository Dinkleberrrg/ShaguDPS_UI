--[[
    ShaguDPS Skin
    ---------------------------------------------------------------------------
    Legt sich ueber ShaguDPS, ohne dessen Dateien anzufassen. Ein Update von
    ShaguDPS ueberschreibt hier also nichts.

    Was es macht:
      * Balkentextur aus deinem UI statt der Blizzard-Statusbar
      * Flacher Hintergrund mit 1px-Rahmen statt der Tooltip-Kachel
      * Friz Quadrata in einstellbarer Groesse, wie im restlichen UI
      * Grosse Zahlen gekuerzt: 47320 -> 47.3k, 1284000 -> 1.28M

    Bedienung:  /sdui

    Lua 5.0 / WoW 1.12: kein #, kein string.gmatch, kein select.
]]

local ADDON = "ShaguDPS_UI"
local FONT = "Fonts\\FRIZQT__.TTF"

-- Auswahl an Balkentexturen. Alle liegen in Addons, die du ohnehin geladen
-- hast, deshalb kommt hier nichts Neues auf die Platte.
-- "dfrl" ist eine entsaettigte Kopie der DFRL-Castbar. Das Original hat einen
-- kraeftigen Gelbstich (Mittelwert RGB 232/215/85). SetStatusBarTexture und
-- SetStatusBarColor multiplizieren sich, mit dem Original kaeme also aus jeder
-- Klassenfarbe ein Gelbton heraus. Die Kopie behaelt das Helligkeitsprofil und
-- ist farbneutral, damit die Klassenfarben stimmen.
local TEXTURES = {
    ["dfrl"]  = "Interface\\AddOns\\ShaguDPS_UI\\img\\dfrlbar",
    ["dfrlorig"] = "Interface\\AddOns\\DragonflightUI-Reforged\\media\\tex\\castbar\\CastingBarStandard3",
    ["grad"]  = "Interface\\AddOns\\ShaguPlates\\img\\bar_gradient",
    ["flat"]  = "Interface\\AddOns\\ShaguPlates\\img\\bar",
    ["elvui"] = "Interface\\AddOns\\ShaguPlates\\img\\bar_elvui",
    ["tukui"] = "Interface\\AddOns\\ShaguPlates\\img\\bar_tukui",
    ["blizz"] = "Interface\\TargetingFrame\\UI-StatusBar",
}
local TEXTURE_ORDER = { "dfrl", "dfrlorig", "grad", "flat", "elvui", "tukui", "blizz" }

local OUTLINES = {
    ["none"]  = "",
    ["thin"]  = "THINOUTLINE",
    ["thick"] = "OUTLINE",
}

local DEFAULTS = {
    fontsize   = 11,
    outline    = "thin",
    texture    = "dfrl",
    bgalpha    = 0.75,
    borderfade = 0.28,
    short      = 1,
    valuecolor = 0.78, -- Graustufe der rechten Zahl, 1 = weiss
}

local backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = -1, right = -1, top = -1, bottom = -1 },
}

-- Wird bei jeder Konfigurationsaenderung hochgezaehlt. Frames und Balken
-- merken sich den Stand, mit dem sie zuletzt gestylt wurden - so laufen
-- SetBackdrop und SetFont nicht bei jedem Kampflog-Eintrag mit.
local skinversion = 1

local function Msg(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffDPS |cff888888Skin:|r " .. text)
end

-- ------------------------------------------------------------------ Config

local cfg

local function LoadConfig()
    if not ShaguDPS_UI_Config then ShaguDPS_UI_Config = {} end
    cfg = ShaguDPS_UI_Config
    local k, v
    for k, v in pairs(DEFAULTS) do
        if cfg[k] == nil then cfg[k] = v end
    end
    return cfg
end

-- ------------------------------------------------------------------ Zahlen

-- 47320 -> "47.3k", 1284000 -> "1.28M". Kleine Werte bleiben exakt stehen,
-- damit man bei einzelnen Treffern noch die echte Zahl liest.
local function Shorten(n)
    if n >= 1000000 then
        return string.format("%.2fM", n / 1000000)
    elseif n >= 10000 then
        return string.format("%.1fk", n / 1000)
    end
    return nil
end

-- Ersetzt in einem fertigen Balkentext alle Zahlen ab 10000 durch die
-- Kurzform. Das Muster fasst Nachkommastellen mit ein, sonst bliebe bei
-- "12345.6" ein ".6" stehen. Prozentwerte sind immer dreistellig oder
-- kleiner und werden dadurch nie angefasst.
local function ShortenNumbers(text)
    if not text then return text end
    local out = string.gsub(text, "%d[%d%.]*", function(token)
        -- ein abschliessender Punkt gehoert nicht zur Zahl
        local trimmed = token
        while string.sub(trimmed, -1) == "." do
            trimmed = string.sub(trimmed, 1, string.len(trimmed) - 1)
        end
        local num = tonumber(trimmed)
        if not num then return token end
        local shortform = Shorten(num)
        if not shortform then return token end
        return shortform .. string.sub(token, string.len(trimmed) + 1)
    end)
    return out
end

-- ------------------------------------------------------------------ Skin

local function StyleButton(btn)
    if not btn then return end
    btn:SetBackdrop(backdrop)
    btn:SetBackdropColor(0.11, 0.11, 0.12, 1)
    btn:SetBackdropBorderColor(cfg.borderfade, cfg.borderfade, cfg.borderfade, 1)
    if btn.caption then
        btn.caption:SetFont(FONT, cfg.fontsize - 2, OUTLINES[cfg.outline] or "")
    end
end

local function StyleFrame(frame)
    if frame.__skin == skinversion then return end
    frame.__skin = skinversion

    -- Hintergrund nur anfassen, wenn ShaguDPS ihn ueberhaupt zeichnen soll
    if ShaguDPS.config.backdrop == 1 then
        frame:SetBackdrop(backdrop)
        frame:SetBackdropColor(0, 0, 0, cfg.bgalpha)
        frame:SetBackdropBorderColor(cfg.borderfade, cfg.borderfade, cfg.borderfade, 1)
        -- der eigene Rahmenframe von ShaguDPS wuerde daneben doppelt liegen
        if frame.border then frame.border:SetBackdrop(nil) end
    end

    if frame.title then
        frame.title:SetTexture(0, 0, 0, 0.55)
    end

    StyleButton(frame.btnSegment)
    StyleButton(frame.btnMode)
    StyleButton(frame.btnAnnounce)
    StyleButton(frame.btnSettings)
    StyleButton(frame.btnReset)
    StyleButton(frame.btnWindow)

    if frame.buttons then
        local i
        for i = 1, table.getn(frame.buttons) do
            StyleButton(frame.buttons[i])
        end
    end
end

local function StyleBar(bar)
    if bar.__skin == skinversion then return end
    bar.__skin = skinversion

    local tex = TEXTURES[cfg.texture] or TEXTURES["grad"]
    local outline = OUTLINES[cfg.outline] or ""

    bar:SetStatusBarTexture(tex)
    if bar.lowerBar then
        bar.lowerBar:SetStatusBarTexture(tex)
    end

    if bar.textLeft then
        bar.textLeft:SetFont(FONT, cfg.fontsize, outline)
        bar.textLeft:SetTextColor(1, 1, 1, 1)
    end
    if bar.textRight then
        bar.textRight:SetFont(FONT, cfg.fontsize, outline)
        local g = cfg.valuecolor
        bar.textRight:SetTextColor(g, g, g, 1)
    end
end

-- Bei einem erzwungenen Refresh setzt ShaguDPS Hintergrund, Balkentextur und
-- Schrift selbst wieder auf seine Standardwerte. Dann muss der Skin nochmal
-- drueber, also die Merker loeschen.
local function Invalidate(frame)
    if not frame then return end
    frame.__skin = nil
    if frame.bars then
        local id, bar
        for id, bar in pairs(frame.bars) do
            bar.__skin = nil
        end
    end
end

local function ApplyToWindow(frame)
    if not frame then return end
    StyleFrame(frame)

    if not frame.bars then return end
    local id, bar
    for id, bar in pairs(frame.bars) do
        StyleBar(bar)
        if cfg.short == 1 and bar.textRight and bar:IsShown() then
            bar.textRight:SetText(ShortenNumbers(bar.textRight:GetText()))
        end
    end
end

local function ApplyAll()
    if not ShaguDPS or not ShaguDPS.window then return end
    local i
    for i = 1, 10 do
        if ShaguDPS.window[i] then ApplyToWindow(ShaguDPS.window[i]) end
    end
end

-- ------------------------------------------------ Nachfrage vor dem Schliessen

-- Der "-"-Knopf loescht ein Meter-Fenster samt seiner Konfiguration sofort.
-- Der Reset-Knopf daneben fragt vorher nach - hier fehlte das. Wir benutzen
-- denselben Dialog, den ShaguDPS fuer den Reset anlegt, damit es gleich
-- aussieht, und dieselbe Abkuerzung: mit gedrueckter Shift-Taste ohne Nachfrage.
local function HookCloseConfirm(frame)
    if frame.__closeconfirm then return end
    -- Fenster 1 traegt "+" (neues Fenster), da gibt es nichts zu bestaetigen
    if frame:GetID() == 1 then return end
    if not frame.btnWindow then return end

    local orig = frame.btnWindow:GetScript("OnClick")
    if not orig then return end
    frame.__closeconfirm = true

    frame.btnWindow:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            orig()
            return
        end
        local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
        if not dialog then
            orig()
            return
        end
        dialog.text = "Dieses Fenster wirklich schliessen?"
        dialog.OnAccept = orig
        StaticPopup_Show("SHAGUMETER_QUESTION")
    end)
end

-- ------------------------------------------------------------------ Hooks

-- ShaguDPS zeichnet an zwei Stellen neu: window.Refresh() fuer alle Fenster
-- und frame:Refresh() direkt beim Ziehen der Groesse. Beide werden umhuellt,
-- damit der Skin in keinem Fall zurueckfaellt.
local hookedFrames = {}

local function HookFrame(frame)
    if not frame then return end
    HookCloseConfirm(frame)
    if hookedFrames[frame] then return end
    hookedFrames[frame] = true
    local orig = frame.Refresh
    frame.Refresh = function(self, force, report)
        orig(self, force, report)
        if force then Invalidate(self) end
        ApplyToWindow(self)
    end
end

local function InstallHooks()
    local orig = ShaguDPS.window.Refresh
    ShaguDPS.window.Refresh = function(force, report)
        orig(force, report)
        local i
        for i = 1, 10 do
            if ShaguDPS.window[i] then
                HookFrame(ShaguDPS.window[i])
                if force then Invalidate(ShaguDPS.window[i]) end
            end
        end
        ApplyAll()
    end

    local i
    for i = 1, 10 do
        if ShaguDPS.window[i] then HookFrame(ShaguDPS.window[i]) end
    end
end

-- ------------------------------------------------------------------ Befehle

local function Help()
    Msg("Befehle:")
    local lines = {
        "  /sdui texture <dfrl|dfrlorig|grad|flat|elvui|tukui|blizz>",
        "  /sdui font <8-16>        Schriftgroesse",
        "  /sdui outline <none|thin|thick>",
        "  /sdui bg <0-1>           Deckkraft des Hintergrunds",
        "  /sdui border <0-1>       Helligkeit des Rahmens",
        "  /sdui value <0-1>        Helligkeit der rechten Zahl",
        "  /sdui short <0|1>        47320 als 47.3k anzeigen",
        "  /sdui reset              Alles zurueck auf Standard",
    }
    local i
    for i = 1, table.getn(lines) do
        DEFAULT_CHAT_FRAME:AddMessage(lines[i])
    end
end

local function Handle(msg)
    local text = string.lower(msg or "")
    local _, _, cmd, arg = string.find(text, "^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd or ""

    if cmd == "" or cmd == "help" then
        Help()
        return
    end

    if cmd == "texture" then
        if not TEXTURES[arg] then
            Msg("Bekannt: dfrl, dfrlorig, grad, flat, elvui, tukui, blizz")
            return
        end
        cfg.texture = arg
        Msg("Textur: |cffffffff" .. arg .. "|r")
        if arg == "dfrlorig" then
            Msg("|cffff8800Hinweis:|r diese Textur ist gelb getoent, die Klassenfarben werden dadurch verfaelscht.")
        end

    elseif cmd == "font" then
        local v = tonumber(arg)
        if not v then Msg("Zahl von 8 bis 16 erwartet.") return end
        if v < 8 then v = 8 end
        if v > 16 then v = 16 end
        cfg.fontsize = v
        Msg("Schriftgroesse: |cffffffff" .. v .. "|r")

    elseif cmd == "outline" then
        if not OUTLINES[arg] then Msg("Bekannt: none, thin, thick") return end
        cfg.outline = arg
        Msg("Kontur: |cffffffff" .. arg .. "|r")

    elseif cmd == "bg" or cmd == "border" or cmd == "value" then
        local v = tonumber(arg)
        if not v then Msg("Zahl von 0 bis 1 erwartet.") return end
        if v < 0 then v = 0 end
        if v > 1 then v = 1 end
        if cmd == "bg" then
            cfg.bgalpha = v
        elseif cmd == "border" then
            cfg.borderfade = v
        else
            cfg.valuecolor = v
        end
        Msg(cmd .. ": |cffffffff" .. string.format("%.2f", v) .. "|r")

    elseif cmd == "short" then
        cfg.short = (arg == "1" or arg == "on") and 1 or 0
        Msg("Kurzzahlen: |cffffffff" .. (cfg.short == 1 and "an" or "aus") .. "|r")

    elseif cmd == "reset" then
        local k, v
        for k, v in pairs(DEFAULTS) do cfg[k] = v end
        Msg("Zurueckgesetzt.")

    else
        Help()
        return
    end

    -- Neu zeichnen erzwingen, damit Groessen und Texturen sofort sitzen
    skinversion = skinversion + 1
    if ShaguDPS and ShaguDPS.window and ShaguDPS.window.Refresh then
        ShaguDPS.window.Refresh(true)
    end
end

-- ------------------------------------------------------------------ Start

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function()
    if loader.done then return end
    if not ShaguDPS or not ShaguDPS.window then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000" .. ADDON .. ":|r ShaguDPS nicht gefunden.")
        return
    end
    loader.done = true

    LoadConfig()
    InstallHooks()

    SLASH_SHAGUDPSUI1 = "/sdui"
    SLASH_SHAGUDPSUI2 = "/sdskin"
    SlashCmdList["SHAGUDPSUI"] = Handle

    -- ShaguDPS setzt seine eigene Optik im PLAYER_ENTERING_WORLD-Handler.
    -- Kurz warten und danach drueberlegen.
    local delay = CreateFrame("Frame")
    local elapsed = 0
    delay:SetScript("OnUpdate", function()
        elapsed = elapsed + (arg1 or 0)
        if elapsed > 1 then
            delay:SetScript("OnUpdate", nil)
            ShaguDPS.window.Refresh(true)
        end
    end)
end)
