
-- ------------------------------------------
-- Ability Pulse
--   by: Xsear
-- ------------------------------------------

require "unicode"
require "math"
require "table"
require "lib/lib_Debug"
require "lib/lib_Items"
require "lib/lib_Slash"
require "lib/lib_ChatLib"
require "lib/lib_Callback2"
require "lib/lib_InterfaceOptions"


-- ------------------------------------------
-- CONSTANTS
-- ------------------------------------------

AddonInfo = {
    release  = "2015-08-23",
    version = "1.2",
    patch = "1.3.1334 (pts)",
    save = 1.0,
}

OUTPUT_PREFIX = "[xAP] "
TRIGGER_BUSY_DELAY_SECONDS = 1
TRIGGER_UNLOCK_DELAY_SECONDS = 1


-- ------------------------------------------
-- GLOBALS
-- ------------------------------------------

w_ICONFRAME = Component.GetFrame("IconFrame")
w_ICON = Component.GetWidget("Icon")

g_Abilities = {}
g_ActiveCooldowns = {}
g_Temp_UsedAbilityHasCharges_Id = {}
g_PulseBusy = false


-- ------------------------------------------
-- SLASH
-- ------------------------------------------

c_SlashList = "xap,xabilitypulse,abilitypulse"
c_SlashTable_Stat = {
    ["stat"] = true,
    ["state"] = true,
    ["dump"] = true,
}
c_SlashTable_Test = {
    ["test"] = true,
    ["try"] = true,
}
c_SlashTable_Scale = {
    ["scale"] = true,
}
--[[
c_SlashTable_Toggle = {
    ["toggle"] = true,
    ["on"] = true,
    ["off"] = true,
    ["enable"] = true,
    ["enabled"] = true,
    ["disable"] = true,
    ["disabled"] = true,
}
c_SlashTable_Debug = {
    ["debug"] = true,
}
--]]
--[[
c_SlashTable_Options = {
    ["options"] = true,
    ["config"] = true,
    ["conf"] = true,
    ["setup"] = true,
    ["edit"] = true,
}
--]]


-- ------------------------------------------
-- Options
-- ------------------------------------------

g_Options = {}
g_Options.Enabled = true
g_Options.Debug = false
g_Options.ScaleSize = 25

function OnOptionChanged(id, value)

    if id == "Debug" then
        Debug.EnableLogging(value)
    elseif id == "Enabled" then
        -- Nothing that I care to do
    elseif id == "ScaleSize" then
        SetIconScale(value)
    end
    
    g_Options[id] = value
end

do
    InterfaceOptions.SaveVersion(1)

    InterfaceOptions.AddCheckBox({id = "Enabled", label = "Enable addon", default = g_Options.Enabled})
    InterfaceOptions.AddCheckBox({id = "Debug", label = "Enable debug", default = g_Options.Debug})
    InterfaceOptions.AddSlider({id = "ScaleSize", label = "Icon size scale", default = g_Options.ScaleSize, min = 5, max = 200, inc = 5, suffix = "%"})
end


-- ------------------------------------------
-- LOAD
-- ------------------------------------------å

function OnComponentLoad()
    Debug.EnableLogging(g_Debug)
    InterfaceOptions.SetCallbackFunc(OnOptionChanged)
    LIB_SLASH.BindCallback({slash_list=c_SlashList, func=OnSlash})
end


-- ------------------------------------------
-- EVENTS
-- ------------------------------------------

function OnSlash(args)
    local slashKey = args[1] or args.text
    slashKey = unicode.lower(slashKey)
    
    if c_SlashTable_Stat[slashKey] then
        Output("Stat")
        Debug.Log("State")
        Debug.Divider()
        Debug.Table("g_Abilities", g_Abilities)
        Debug.Table("g_ActiveCooldowns", g_ActiveCooldowns)
        Debug.Divider()
    elseif c_SlashTable_Test[slashKey] then
        Output("Test")
        TestPulse()
    elseif c_SlashTable_Scale[slashKey] then
        Output("Scale")
        local value = args[2] or Options.ScaleSize
        SetIconScale(value)
    --[[
    elseif c_SlashTable_Toggle[slashKey] then
        if slashKey == "toggle" then
            local enabled = not g_Options.Enabled
            OnOptionChanged("Enabled", enabled)
        end

    elseif c_SlashTable_Debug[slashKey] then
    --]]
    --[[
    elseif c_SlashTable_Options[slashKey] then
        InterfaceOptions.OpenToMyOptions()
    --]]

    else
        Output("Version " .. AddonInfo.version .. ", currently " .. (g_Options.Enabled and "Enabled" or "Disabled"))
        Output("Slash commands")
        if g_Options.Debug then
            Output("Stat: " .. _table.concatKeys(c_SlashTable_Stat, ", "))
        end
        Output("Test: " .. _table.concatKeys(c_SlashTable_Test, ", "))
        Output("Scale: " .. _table.concatKeys(c_SlashTable_Scale, ","))
        --Output("Options: " .. _table.concatKeys(c_SlashTable_Options, ","))
    end
    
end

function OnPlayerReady(args)
    UpdateAbilities(args)
end

function OnBattleframeChanged(args)
    UpdateAbilities(args)
end

function OnAbilityUsed(args)
    if g_Options.Enabled then
        local abilityId = tostring(args.id) or 0 -- Ensure not userdata
        local noCooldown = (args.cooldown < 1)


        if IsWatchedAbility(abilityId) then
            Debug.Table("OnAbilityUsed", {abilityId, noCooldown})

            
            local abilityState = Player.GetAbilityState(abilityId)
            Debug.Table("abilityState", abilityState)
            if abilityState.requirements.chargeCount ~= -1 then
                Debug.Log("This ability can have charges")
                g_Temp_UsedAbilityHasCharges_Id[abilityId] = abilityState.requirements.chargeCount
                Debug.Log("OnAbilityUsed set g_Temp_UsedAbilityHasCharges_Id["..abilityId.." to ", g_Temp_UsedAbilityHasCharges_Id[abilityId], " which is ", g_Abilities[abilityId].name)
            end

            AddCooldown(abilityId)
        end
    end
end

function OnAbilityReady(args)
    if g_Options.Enabled then
        local abilityId = tostring(args.id) -- Ensure not userdata
        if not g_Abilities[abilityId] then return end
        local isReady = args.ready or false
        local hasJustComeOffCooldown = args.elapsed_cooldown ~= nil and args.elapsed_cooldown > 1
        --Debug.Table("Player.GetAbilityState(abilityId)", Player.GetAbilityState(abilityId))
            

        -- If ready get more advanced data
        if isReady and IsOnCooldown(abilityId) then 
            local abilityState = Player.GetAbilityState(abilityId)
            Debug.Table("OnAbilityReady for ".. abilityId .. " (" .. g_Abilities[abilityId].name .. ") with abilityState", abilityState)
            Debug.Log("hasJustComeOffCooldown: ", tostring(hasJustComeOffCooldown))

            if abilityState.inEffect then
                Debug.Log("Well, this ability is currently active, so we definitely didnt get this event because it came off cooldown, probably.")

            elseif g_Temp_UsedAbilityHasCharges_Id[abilityId] then
                Debug.Log("OnAbilityReady finds event that says that ability " .. abilityId .. " (" .. g_Abilities[abilityId].name .. ") has refreshed, but we know it can have charges, so we must check carefully")

                Debug.Log("g_Temp_UsedAbilityHasCharges_Id[abilityId] = ", g_Temp_UsedAbilityHasCharges_Id[abilityId])
                
                Debug.Log("abilityState.requirements.chargeCount = ", abilityState.requirements.chargeCount)

                if abilityState.requirements.chargeCount > g_Temp_UsedAbilityHasCharges_Id[abilityId] then
                    Debug.Log("There are more charges now than we have stored, so this looks like a legit cooldown refresh!")
                    PopCooldown(abilityId)
                    Debug.Log("Updating known charges")
                    g_Temp_UsedAbilityHasCharges_Id[abilityId] = abilityState.requirements.chargeCount
                    Debug.Log("g_Temp_UsedAbilityHasCharges_Id[abilityId]", g_Temp_UsedAbilityHasCharges_Id[abilityId])

                elseif abilityState.requirements.chargeCount < g_Temp_UsedAbilityHasCharges_Id[abilityId] then
                    Debug.Log("There are less charges now than we had when we activated the ability, not sure what that means, but it definitely does not mean we should pop anything")
                else
                    Debug.Log("The number of charges is the same as when we activated, so this is not the time to celebrate a cooldown completion.")
                end
        
            elseif hasJustComeOffCooldown then
                Debug.Log("OnAbilityReady suggests that ability " .. abilityId .. " (" .. g_Abilities[abilityId].name .. ") has refreshed, and we trust blindly")
                PopCooldown(abilityId)
            end
        end
    end
end


-- ------------------------------------------
-- Functions
-- ------------------------------------------

function UpdateAbilities(args)
    Debug.Table("UpdateAbilities", args)

    -- Clear current data
    g_Abilities = {}
    if next(g_ActiveCooldowns) then
        if g_Options.Debug then 
            Output("Losing cooldowns because of updating abilities")
        end
    end
    g_ActiveCooldowns = {}

    -- Get current abilities
    local abilities = Player.GetAbilities().slotted

    -- Build abilities table
    for _, ability in ipairs(abilities) do
        local abilityId = tostring(ability.abilityId) -- Ensure not userdata
        local abilityInfo = Player.GetAbilityInfo(ability.abilityId) -- Well if this makes it any faster might as well use it here
        g_Abilities[abilityId] = {name = tostring(abilityInfo.name), abilityId = abilityId, iconId = abilityInfo.iconId}
    end
end

function IsWatchedAbility(abilityId)
    return g_Abilities[abilityId] ~= nil or false
end

function IsOnCooldown(abilityId)
    return g_ActiveCooldowns[abilityId] ~= nil or false
end

function AddCooldown(abilityId)
    Debug.Log("AddCooldown", abilityId)
    if g_ActiveCooldowns[abilityId] then
        g_ActiveCooldowns[abilityId].count = g_ActiveCooldowns[abilityId].count + 1
        Debug.Log("Increased stack count to ", g_ActiveCooldowns[abilityId].count)
    else
        g_ActiveCooldowns[abilityId] = {count = 1}
        Debug.Log("Created cooldown entry")
    end
end

function PopCooldown(abilityId)
    Debug.Log("PopCooldown", abilityId)
    local abilityData = g_Abilities[abilityId]
        
    if g_ActiveCooldowns[abilityId] then

        TriggerPulse(abilityData)

        if g_ActiveCooldowns[abilityId].count > 1 then
            g_ActiveCooldowns[abilityId].count = g_ActiveCooldowns[abilityId].count - 1
            Debug.Log("Decremented stack count to ", g_ActiveCooldowns[abilityId].count)
        else
            g_ActiveCooldowns[abilityId] = nil
        end

    else
        Debug.Error("PopCooldown on non-existent cooldown :(")
    end
end

function TriggerPulse(abilityData)
    -- abilityData = {abilityId = ability.abilityId, iconId = abilityInfo.iconId}
    if g_Options.Debug then Output("TriggerPulse for abilityId " .. tostring(abilityData.abilityId) .. " (" .. abilityData.name .. ")") end


    Debug.Table("TriggerPulse", abilityData)
    -- Check Lock
    if g_PulseBusy then
        Debug.Log("g_PulseBusy, firing a callback")
        Callback2.FireAndForget(TriggerPulse, abilityData, TRIGGER_BUSY_DELAY_SECONDS)
        return
    end

    -- Lock
    g_PulseBusy = true
    Debug.Log("g_PulseBusy now true")

    -- Set icon
    w_ICON:SetIcon(abilityData.iconId)

    w_ICON:SetParam("alpha", 0, 0.1)
    w_ICON:QueueParam("alpha", 0.8, 0.25, "ease-in")
    w_ICON:QueueParam("alpha", 0, 0.75, "ease-out")

    -- Queue Unlock
    Callback2.FireAndForget(function() g_PulseBusy = false Debug.Log("g_PulseBusy now false") end, nil, TRIGGER_UNLOCK_DELAY_SECONDS)
end

function SetIconScale(value)
    w_ICONFRAME:SetDims(unicode.format("center-x:_; center-y:_; width:%i%%; height:%i%%", value, value))
end

function TestPulse()
    -- Pick ability "randomly"
    local abilityKey = nil
    for key, abilityData in pairs(g_Abilities) do
        if math.random(1,10) % 2 == 0 then
            abilityKey = key
            break
        end
    end

    local abilityData = g_Abilities[abilityKey]

    TriggerPulse(abilityData)
end


-- ------------------------------------------
-- UTILITY/RETURN FUNCTIONS
-- ------------------------------------------

function Output(text)
    local args = {
        text = OUTPUT_PREFIX .. tostring(text),
    }

    ChatLib.SystemMessage(args);
end

function _table.concatKeys(inputTable, separator)
    local output = {}
    for key, _ in pairs(inputTable) do
        output[#output + 1] = key
    end
    return table.concat(output, separator)
end

function _table.empty(table)
    if not table or next(table) == nil then
       return true
    end
    return false
end