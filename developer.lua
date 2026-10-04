local ADDON_NAME, addon = ...

-- MARK: Default values
local FRAME_WIDTH = 800
local FRAME_HEIGHT = 300
local CLOSE_BUTTON_SIZE = 20
local CLOSE_BUTTON_TEXTURE = "Interface\\AddOns\\HBLyx_Tools\\GUI\\Assets\\Close_Button.png"

---@class Developer
local Developer = {
    displayFrame = nil
}

---Fill the scroll frame with the modules overview, states info, and event registrations
local function RenderAddonInfo(container)
    addon.GUI:CreateInlineGroup(container, "Modules")
    local loadedModContent = "|cff8788eeLoaded|r"
    local loadedModules, loadedModulesCount = addon.core:GetLoadedModulesList(true)
    loadedModContent = loadedModContent .. "(" .. loadedModulesCount .. "): "
    loadedModContent = loadedModContent .. table.concat(loadedModules, ", ")
    addon.GUI:CreateInformationTag(container, loadedModContent, "LEFT")
    local unloadedModContent = "|cff8788eeUnloaded|r"
    local unloadedModules, unloadedModulesCount = addon.core:GetUnloadedModulesList(true)
    unloadedModContent = unloadedModContent .. "(" .. unloadedModulesCount .. "): "
    unloadedModContent = unloadedModContent .. table.concat(unloadedModules, ", ")
    addon.GUI:CreateInformationTag(container, unloadedModContent, "LEFT")

    addon.GUI:CreateHeader(container, "States")
    local statesInfo = addon.core:GetStatesInfo()
    local statesDisplay = ""
    statesDisplay = table.concat(statesInfo, "\n")
    addon.GUI:CreateInformationTag(container, statesDisplay, "LEFT")

    addon.GUI:CreateHeader(container, "States Monitor")
    local statesMonitorInfo = addon.core:GetStatesMonitorInfo()
    local statesMonitorDisplay = ""
    statesMonitorDisplay = table.concat(statesMonitorInfo, "\n")
    addon.GUI:CreateInformationTag(container, statesMonitorDisplay, "LEFT")

    addon.GUI:CreateHeader(container, "State Events")
    local stateEventInfo = addon.core:GetStateEventInfo()
    local stateEventDisplay = table.concat(stateEventInfo, "\n")
    addon.GUI:CreateInformationTag(container, stateEventDisplay, "LEFT")

    addon.GUI:CreateHeader(container, "Events")
    local eventInfo = addon.core:GetEventInfo()
    local eventDisplay = table.concat(eventInfo, "\n")
    addon.GUI:CreateInformationTag(container, eventDisplay, "LEFT")
end

function Developer:Initialize()
    return self
end

function Developer:DisplayAddonInfo()
    if not self.displayFrame then
        local scrollFrame = addon.UICore:Build("ScrollFrame")
        scrollFrame:SetParent(UIParent)
        scrollFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
        scrollFrame:SetPoint("CENTER")
        scrollFrame:SetRenderer(RenderAddonInfo)
        scrollFrame.frame:SetFrameStrata("HIGH")

        -- dragging the border moves the frame, like the config panels
        scrollFrame.frame:SetMovable(true)
        scrollFrame.frame:EnableMouse(true)
        scrollFrame.frame:RegisterForDrag("LeftButton")
        scrollFrame.frame:SetScript("OnDragStart", scrollFrame.frame.StartMoving)
        scrollFrame.frame:SetScript("OnDragStop", scrollFrame.frame.StopMovingOrSizing)
        scrollFrame.frame:SetClampedToScreen(true)

        local close = CreateFrame("Button", nil, scrollFrame.frame)
        close:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
        close:SetPoint("BOTTOMRIGHT", scrollFrame.frame, "TOPRIGHT", 0, 0)
        close:SetNormalTexture(CLOSE_BUTTON_TEXTURE)
        close:SetPushedTexture(CLOSE_BUTTON_TEXTURE)
        close:SetHighlightTexture(CLOSE_BUTTON_TEXTURE)
        close:GetHighlightTexture():SetAlpha(0.75)
        close:SetScript("OnClick", function() scrollFrame:Hide() end)
        addon.UICore:BuildHover(close)

        self.displayFrame = scrollFrame
    end

    -- refresh with the current module/state snapshot every time the frame is shown
    self.displayFrame:Rerender()
    self.displayFrame:Show()
end

addon.Developer = Developer:Initialize()