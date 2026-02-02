---@meta _

--#region Addon annotations

--- Utility class representing map coordinates.
---@class MapCoord
---@field x number X-coordinate on the map [0.0–100.0].
---@field y number Y-coordinate on the map [0.0–100.0].
--#endregion

--#region Blizzard tables annotations

--- Format of elements in [EJ_TIER_DATA](https://www.townlong-yak.com/framexml/beta/Blizzard_EncounterJournal/Blizzard_EncounterJournal.lua#105) table
---@class EJTierData : table
---@field expansionLevel number Mapping to LE_EXPANSION as they don't match EJ Tiers.
---@field backgroundAtlas string Atlas ID of the background used for EJ frames for this expansion.
--#endregion

--#region FrameXML annotations

--- `VerticalLayoutFrame` ([Blizzard template](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/LayoutFrame.xml#9)).
---@class VerticalLayoutFrame : Frame, LayoutMixin, VerticalLayoutMixin
---@field spacing number Spacing is the number of pixels between child elements

--- `HorizontalLayoutFrame` ([Blizzard template](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/LayoutFrame.xml#85)).
---@class HorizontalLayoutFrame : Frame, LayoutMixin, HorizontalLayoutMixin
---@field fixedHeight number
---@field spacing number Spacing is the number of pixels between child elements

--- `MagicButtonTemplate` ([Blizzard template](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SharedUIPanelTemplates.xml#909)).
---@class MagicButton : Button, UIButtonFitToTextBehaviorMixin
---@field fitTextCanWidthDecrease boolean Whether the button width can decrease depending on the text width.
---@field fitTextWidthPadding number Extra padding around the text.
---@field Text FontString Button text.

--- `DelvesDashboardButtonPanelFrame` ([Blizzard template](https://www.townlong-yak.com/framexml/live/Blizzard_DelvesDashboardUI/Blizzard_DelvesDashboardUI.xml#18)).
---@class DelvesDashboardButtonPanelFrame : Frame
---@field isCompanionButtonPanelFrame boolean If true, this button panel frame will use a highlighted background
---@field ButtonPanelBackground Texture
---@field PanelTitle FontString
---@field PanelDescription FontString

--- `CompanionConfigSlotTemplate` ([Blizzard template](https://www.townlong-yak.com/framexml/live/Blizzard_DelvesCompanionConfiguration/Blizzard_DelvesCompanionConfiguration.xml#4)).
---@class (exact) CompanionConfigSlotXml : Button
---@field type string
---@field Label FontString
---@field Value FontString
---@field Texture Texture
---@field OptionsList CompanionConfigListXml
--#endregion

--#region Mixin annotations

--- `BaseLayoutMixin` ([Blizzard object](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/LayoutFrame.lua#10)).
---@class BaseLayoutMixin
local BaseLayoutMixin = {}

--- Get all children of the `Layout`.
---@return Frame[] # List of children. Note: `Frame` here may not match the exact type of the objects.
function BaseLayoutMixin:GetLayoutChildren() end

--- `LayoutMixin` ([Blizzard object](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/LayoutFrame.lua#197)).
---@class LayoutMixin : BaseLayoutMixin
local LayoutMixin = {}

--- Set proper layout for all children considering Layout parameters (paddings, offsets, etc.).
function LayoutMixin:Layout() end

--- `VerticalLayoutMixin` ([Blizzard object](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/LayoutFrame.lua#264)).
---@class VerticalLayoutMixin
local VerticalLayoutMixin = {}

--- `HorizontalLayoutMixin` ([Blizzard object](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/LayoutFrame.lua#361)).
---@class HorizontalLayoutMixin
local HorizontalLayoutMixin = {}

--- `WeeklyRewardMixin` ([Blizzard object](https://www.townlong-yak.com/framexml/live/Blizzard_WeeklyRewardsUtil/Blizzard_WeeklyRewardsUtil.lua#100)).
---@class WeeklyRewardMixin
local WeeklyRewardMixin = {}

--- Check unlocked reward in the Great Vault of the desired type.
---@param activityType Enum.WeeklyRewardChestThresholdType  Type from `Enum.WeeklyRewardChestThresholdType`.
---@return boolean # True if player has at least 1 unlocked reward, false otherwise.
function WeeklyRewardMixin:HasUnlockedRewards(activityType) end

--- Get max possible number of rewards in the Great Vault of the desired type.
---@param activityType Enum.WeeklyRewardChestThresholdType Type from `Enum.WeeklyRewardChestThresholdType`.
---@return integer # Max possible number of rewards.
function WeeklyRewardMixin:GetMaxNumRewards(activityType) end

--- Get number of unlocked rewards in the Great Vault of the desired type.
---@param activityType Enum.WeeklyRewardChestThresholdType Type from `Enum.WeeklyRewardChestThresholdType`.
---@return integer # Number of unlocked rewards.
function WeeklyRewardMixin:GetNumUnlockedRewards(activityType) end

--- `UIButtonFitToTextBehaviorMixin` ([Blizzard object](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SecureUIPanelTemplates.lua#210)).
---@class UIButtonFitToTextBehaviorMixin
local UIButtonFitToTextBehaviorMixin = {}

--- Set `text` and adjust the button width to fit item.
---@param text string Button text.
function UIButtonFitToTextBehaviorMixin:SetTextToFit(text) end

--#endregion
