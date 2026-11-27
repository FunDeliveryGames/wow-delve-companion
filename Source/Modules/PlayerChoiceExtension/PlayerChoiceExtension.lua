local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion
---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit
---@type ProgressTracker
local ProgressTracker = DelveCompanion.ProgressTracker
---@type DelveCompanionAccountData
local AccSaveData = DelveCompanionAccountData

--#region Constants

---@type string
local AUTO_ENTER_CHECKBOX_PARENT_KEY = "AutoEnterCheckbox"
---@type number
local PCFRAME_LABYRINTH_WIDGET_SET_ID = 2327
--#endregion

---@class (exact) PlayerChoiceExtension
---@field AutoEnterCheckbox CheckButton
local PlayerChoiceExtension = {}
DelveCompanion.PlayerChoiceExtension = PlayerChoiceExtension

---@type boolean
local isSetupDone = false

local function PlayerChoiceFrame_OnShow()
    -- Logger:Log("[PlayerChoiceExtension] PlayerChoiceFrame OnShow hook...")

    if not ProgressTracker.isDelveInProgress then
        return
    end

    local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
    if choiceInfo then
        local options = choiceInfo.options
        if options and #options > 0 and options[1].widgetSetID == PCFRAME_LABYRINTH_WIDGET_SET_ID then
            if not AccSaveData.labyrinthAutoEnterChambers then
                PlayerChoiceExtension.AutoEnterCheckbox:Show() -- No reason to show it if the auto enter checked. The response is almost immediate, the frame won't be seen.
                return
            end

            local buttons = options[1].buttons
            if buttons and #buttons > 0 then
                C_PlayerChoice.SendPlayerChoiceResponse(buttons[1].id)
                if not choiceInfo.keepOpenAfterChoice then
                    HideUIPanel(PlayerChoiceFrame)
                end
            end
        end
    end
end

local function PlayerChoiceFrame_OnHide()
    PlayerChoiceExtension.AutoEnterCheckbox:Hide()
end

---@param self PlayerChoiceExtension
---@param pcFrame Frame PlayerChoiceframe
local function CreateAutoEnterCheckbox(self, pcFrame)
    local cb = CreateFrame("CheckButton",
        "$DelveCompanion." .. AUTO_ENTER_CHECKBOX_PARENT_KEY,
        pcFrame,
        "UICheckButtonTemplate"
    )
    self.AutoEnterCheckbox = cb
    cb:SetPoint("BOTTOMLEFT", pcFrame, "BOTTOMLEFT", 65, 42)
    cb.Text:SetText(Lockit.UI_LABYRINTH_AUTO_ENTER_CHAMBERS_NAME)
    cb.Text:SetWidth(100)
    cb.Text:SetJustifyH("LEFT")
    DelveCompanion.UISkin:Apply("PickerCheckbox", cb)

    cb:HookScript("OnShow", function()
        cb:SetChecked(AccSaveData.labyrinthAutoEnterChambers)
    end)
    cb:HookScript("OnEnter", function()
        local tooltip = GameTooltip
        tooltip:SetOwner(cb, "ANCHOR_TOP")
        GameTooltip_SetTitle(tooltip,
            Lockit.UI_LABYRINTH_AUTO_ENTER_CHAMBERS_NAME,
            HIGHLIGHT_FONT_COLOR)
        GameTooltip_AddNormalLine(tooltip, Lockit.UI_SETTING_LABYRINTH_AUTO_ENTER_CHAMBERS_TOOLTIP, true)

        tooltip:Show()
    end)
    cb:HookScript("OnLeave", function()
        securecall(GameTooltip.Hide, GameTooltip)
    end)
    cb:HookScript("OnClick", function()
        AccSaveData.labyrinthAutoEnterChambers = cb:GetChecked()
    end)
    cb:Hide()
end

---@param self PlayerChoiceExtension
function PlayerChoiceExtension:Init()
    -- Logger:Log("[PlayerChoiceExtension] Init started...")

    if isSetupDone then
        return
    end

    if C_AddOns.IsAddOnLoaded(DelveCompanion.Definitions.DependencyAddonName.playerChoice) or PlayerChoice_LoadUI() then
        ---@type Frame
        local pcFrame = PlayerChoiceFrame

        if not pcFrame then
            Logger:Log("[PlayerChoiceExtension] PlayerChoiceFrame is nil. Cannot init!")
            return
        end

        pcFrame:HookScript("OnShow", PlayerChoiceFrame_OnShow)
        pcFrame:HookScript("OnHide", PlayerChoiceFrame_OnHide)
        CreateAutoEnterCheckbox(self, pcFrame)
    end

    isSetupDone = true
end
