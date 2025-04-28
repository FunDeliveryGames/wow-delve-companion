local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

---@type DashboardCompanion
local DashboardCompanion = DelveCompanion.DelvesDashboard.Companion

--#region Constants

---@type number
local SLOT_SCALE_VERTICAL = 0.65
---@type number
local SLOT_SCALE_HORIZONTAL = 0.6
--#endregion

--- A short-cut widget to display and change Companion's configuration.
---@class (exact) CompanionConfigWidget : CompanionConfigWidgetXml
DelveCompanion_DashboardCompanionConfigWidgetMixin = {}

--- Create an adjustable pin.
---@param optionsList Frame Config slot optionsList.
local function CreateOptionsListPin(optionsList)
    ---@type Texture
    local optionsPin = optionsList:CreateTexture("$parent.Pin")
    optionsPin:SetParentKey("Pin")
    optionsPin:SetDrawLayer("BACKGROUND", 5)
    optionsPin:SetRotation(math.pi)
    optionsPin:SetWidth(15)
    optionsPin:SetHeight(36)
    optionsPin:SetTexture("interface/talentframe/talents")
    optionsPin:SetTexCoord(0.46782, 0.47903, 0.0830078125, 0.1181640625)
end

--- Prepare slot parameters. Only layout-independent setup.
---@param slot CompanionConfigSlotXml
local function InitSlot(slot)
    slot.OptionsList:SetFrameStrata("HIGH")

    ---@type Texture
    local optionsTop = slot.OptionsList.Top
    optionsTop:SetAtlas("talents-pvpflyout-background-top")
    optionsTop:SetRotation(0)

    CreateOptionsListPin(slot.OptionsList)
end

--- Set slot parameters for `Horizontal` layout.
---@param slot CompanionConfigSlotXml
---@param anchorPoint string
local function SetSlotHorizontal(slot, anchorPoint)
    slot:SetScale(SLOT_SCALE_HORIZONTAL)
    slot:SetPoint(anchorPoint)

    slot.Label:Hide()
    slot.Value:Hide()

    slot.OptionsList:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -10)
    slot.OptionsList:SetScale(1.8)

    slot.OptionsList.Pin:SetPoint("TOP", -73, 37)
end

--- Display the widget as `Horizontal` layout.
---@param self CompanionConfigWidget
function DelveCompanion_DashboardCompanionConfigWidgetMixin:SetHorizontalLayout()
    DashboardCompanion.ParentPanel.CompanionModelScene:Show()
    DashboardCompanion.ParentPanel.isCompanionButtonPanelFrame = true

    self:SetSize(130, 40)
    self:SetPoint("BOTTOMLEFT", DashboardCompanion.ParentPanel, "BOTTOMLEFT", 24, 23)

    local defConfigButton = DashboardCompanion.ParentPanel.CompanionConfigButton
    defConfigButton:Hide()

    local customConfigButton = CreateFrame("Button", "$parent.CustomConfigButton", DashboardCompanion.ParentPanel,
        "DelveCompanionDashboardCompanionConfigButtonTemplate")
    customConfigButton:SetPoint("LEFT", self, "RIGHT", 5, 0)
    customConfigButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        if button.disabled then
            GameTooltip_AddErrorLine(GameTooltip, _G["DELVES_COMPANION_NOT_ENABLED_TOOLTIP"], true)
        else
            GameTooltip_AddNormalLine(GameTooltip, _G["DELVES_CONFIGURE_BUTTON"], true)
        end
        GameTooltip:Show()
    end)

    SetSlotHorizontal(self.RoleSlot, "LEFT")
    SetSlotHorizontal(self.CombatSlot, "CENTER")
    SetSlotHorizontal(self.UtilitySlot, "RIGHT")
end

--- Set slot parameters for `Vertical` layout.
---@param slot CompanionConfigSlotXml
---@param anchorPoint string
local function SetSlotVertical(slot, anchorPoint)
    slot:SetScale(SLOT_SCALE_VERTICAL)
    slot:SetPoint(anchorPoint)

    slot.Label:SetWidth(160)
    slot.Value:SetWidth(160)

    slot.OptionsList:SetPoint("TOP", slot, "BOTTOM", 60, -8)
    slot.OptionsList:SetScale(1.5)

    slot.OptionsList.Pin:SetPoint("TOP", -60, 37)
end

--- Display the widget as `Vertical` layout.
---@param self CompanionConfigWidget
function DelveCompanion_DashboardCompanionConfigWidgetMixin:SetVerticalLayout()
    DashboardCompanion.ParentPanel.CompanionModelScene:Hide()
    DashboardCompanion.ParentPanel.isCompanionButtonPanelFrame = false

    self:SetSize(170, 145)
    self:SetPoint("TOP", DashboardCompanion.ExpBar, "BOTTOM", 0, -5)

    SetSlotVertical(self.RoleSlot, "TOPLEFT")
    SetSlotVertical(self.CombatSlot, "LEFT")
    SetSlotVertical(self.UtilitySlot, "BOTTOMLEFT")
end

---@param self CompanionConfigWidget
function DelveCompanion_DashboardCompanionConfigWidgetMixin:OnLoad()
    -- Logger.Log("CompanionConfigWidget OnLoad start")

    InitSlot(self.RoleSlot)
    InitSlot(self.CombatSlot)
    InitSlot(self.UtilitySlot)
end

---@param self CompanionConfigWidget
function DelveCompanion_DashboardCompanionConfigWidgetMixin:OnShow()
    -- Logger.Log("CompanionConfigWidget OnShow start")

    -- self:SetVerticalLayout()
    self:SetHorizontalLayout()
end

--#region XML Annotations

--- `CompanionConfigSlotTemplate` ([Blizzard template](https://www.townlong-yak.com/framexml/live/Blizzard_DelvesCompanionConfiguration/Blizzard_DelvesCompanionConfiguration.xml#4)).
---@class CompanionConfigSlotXml : Button
---@field type string
---@field Label FontString
---@field Value FontString
---@field Texture Texture
---@field OptionsList Frame

--- `DelveCompanionDashboardCompanionConfigWidgetTemplate`
---@class CompanionConfigWidgetXml : Frame
---@field RoleSlot CompanionConfigSlotXml
---@field CombatSlot CompanionConfigSlotXml
---@field UtilitySlot CompanionConfigSlotXml

--#endregion
