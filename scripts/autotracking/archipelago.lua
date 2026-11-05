require("scripts.autotracking.item_mapping")
require("scripts.autotracking.location_mapping")
require("scripts.autotracking.option_mapping")

CUR_INDEX = -1
--SLOT_DATA = nil

ALL_LOCATIONS = {}
SLOT_DATA = {}

MANUAL_CHECKED = true
ROOM_SEED = "default"

if Highlight then
    HIGHLIGHT_LEVEL= {
        [0] = Highlight.Unspecified,
        [10] = Highlight.NoPriority,
        [20] = Highlight.Avoid,
        [30] = Highlight.Priority,
        [40] = Highlight.None,
        [100] = Highlight.Unspecified, --Filler
        [101] = Highlight.Priority, --Progression
        [102] = Highlight.NoPriority, --Useful
        [103] = Highlight.Priority, -- Prog + Useful
        [104] = Highlight.Avoid, --Trap
        [105] = Highlight.Priority, -- Prog + Trap
        [106] = Highlight.NoPriority, -- Useful + Trap
        [107] = Highlight.Priority, -- Prog + Useful + Trap
    }
end

---function to build a pretty-printable representation of a provided table
---@param o table
---@param depth? integer
---@return string
function DumpTable(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('\t'):rep(depth)
        local tabs2 = ('\t'):rep(depth + 1)
        local s = '{\n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. DumpTable(v, depth + 1) .. ',\n'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

---helper function that gets called when a LocationSection has changed state.
---checks if the interaction was from the server or manual.
---if manual, puts it into a cache for keeping that LocationSection toggled when reconnecting
---@param location LocationSection
function LocationHandler(location)
    if MANUAL_CHECKED then
        local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
        if not custom_storage_item then
            return
        end
        if Archipelago.PlayerNumber == -1 then -- not connected
            if ROOM_SEED ~= "default" then -- seed is from previous connection
                ROOM_SEED = "default"
                custom_storage_item.MANUAL_LOCATIONS["default"] = {}
            else -- seed is default
            end
        end
        local full_path = location.FullID
        if not custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] then
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] = {}
        end
        if location.AvailableChestCount < location.ChestCount then --add to list
            -- print("add to list")
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][full_path] = location.AvailableChestCount
        else --remove from list of set back to max chestcount
            -- print("remove from list")
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][full_path] = nil
        end
    end
    -- local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    -- print(DumpTable(storage_item.ItemState.MANUAL_LOCATIONS))
    ForceUpdate() --
end

--function to force an update even if the interaction within poptracker noramlly would not call for a state update
function ForceUpdate()
    local update = Tracker:FindObjectForCode("update")
    if update == nil then
        return
    end
    update.Active = not update.Active
end

---resets or updates a given item back to default or what's saved for the given seed in the pseudo-cache LuaItems
---@param item_code JsonItem|string Tracker:FindObjectForCode(item) return object
---@param item_type string|nil table of the ItemCode and extra parameters from the Item_Mapping.lau
---@param consumable_multiplier integer|nil table of the ItemCode and extra parameters from the Item_Mapping.lua
---@param item_id integer AP-ID of the item from ITEM_MAPPING
---@param reset boolean|nil flag to update or reset the item false=update, true=reset, nil=update
local function ItemUpdate(item_code, item_type, consumable_multiplier, item_id, reset)
    local item_obj = nil

    if type(item_code) == "string" then
        item_obj = Tracker:FindObjectForCode(item_code)
    else
        item_obj = item_code
    end
    if item_obj == nil then
        print(string.format("ItemUpdate: could not find item_object for code %s", item_code))
        return
    end

    if item_type == nil then
        item_type = item_obj.Type
    end

    if item_type == "toggle" then
        item_obj.Active = not reset --reset and false or true
    elseif item_type == "progressive" then
        item_obj.CurrentStage = reset and 0 or (item_obj.CurrentStage + 1)
    elseif item_type == "consumable" then
        item_obj.AcquiredCount = reset and (item_obj.MinCount or 0) or
        (item_obj.AcquiredCount + item_obj.Increment * (consumable_multiplier or 1))
    elseif item_type == "progressive_toggle" then
        item_obj.CurrentStage = reset and 0 or (item_obj.CurrentStage + 1)
        item_obj.Active = not reset -- reset and false or true
    end
end


---resets or updates a given location back to default or whats saved for the gives seed in the pseudo-cache LuaItems
---@param location_obj LocationSection Tracker:FindObjectForCode(location) return object
---@param custom_storage_item table Reference for the custom LuaItem CachesItems
---@param location_id integer AP-ID of the location from LOCATION_MAPPING
---@param reset boolean flag to update or reset the item false=update, true=reset, nil=update
local function LocationUpdate(location_obj, custom_storage_item, location_id, reset)
    ---@cast location_obj LocationSection

    if reset then --reset
        if custom_storage_item and custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][location_obj.FullID] then
            location_obj.AvailableChestCount = custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][location_obj.FullID]
        else
            location_obj.AvailableChestCount = location_obj.ChestCount
        end
        location_obj.Highlight = HIGHLIGHT_LEVEL[40]
    else --update
        (location_obj --[[@as LocationSection]]).AvailableChestCount = location_obj.AvailableChestCount - 1
    end
end


--- Function to prepare custom LuaItems for caching, check for mischieve/traps, subscribe to datastorage
local function PreOnClear()
    PLAYER_ID = Archipelago.PlayerNumber or -1
	TEAM_NUMBER = Archipelago.TeamNumber or 0
    if PLAYER_ID > -1 then
        if #ALL_LOCATIONS > 0 then
            ALL_LOCATIONS = {}
        end
        for _, value in pairs(Archipelago.MissingLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end

        for _, value in pairs(Archipelago.CheckedLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end
        ---add more of those for other datastorage keys
        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        GOAL_ID = string.format("_read_client_status_%i_%i", Archipelago.TeamNumber, Archipelago.PlayerNumber)
        Archipelago:SetNotify({HINTS_ID, GOAL_ID}) --{HINTS_ID, other vars, ...}
        Archipelago:Get({HINTS_ID, GOAL_ID}) --{HINTS_ID, other vars, ...}
    end


    -- print(Archipelago.Seed)
    local seed_base = (Archipelago.Seed or tostring(#ALL_LOCATIONS)).."_"..Archipelago.TeamNumber.."_"..Archipelago.PlayerNumber
    if ROOM_SEED == "default" or ROOM_SEED ~= seed_base then -- seed is default or from previous connection

        ROOM_SEED = seed_base --something like 2345_0_12
        for _, custom_item_code in pairs({"manual_location_storage"}) do -- add more to the table if you created more storage cache items
            local custom_storage_item = Tracker:FindObjectForCode(custom_item_code).ItemState
            if custom_storage_item then
                if #custom_storage_item.MANUAL_LOCATIONS > 10 then
                    custom_storage_item.MANUAL_LOCATIONS[custom_storage_item.MANUAL_LOCATIONS_ORDER[1]] = nil
                    table.remove(custom_storage_item.MANUAL_LOCATIONS_ORDER, 1)
                end
                if custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] == nil then
                    custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] = {}
                    table.insert(custom_storage_item.MANUAL_LOCATIONS_ORDER, ROOM_SEED)
                end
            end
        end
    else -- seed is from previous connection
        -- do nothing
    end
end

---function that gets called when the pack connects to an AP server
---@param slot_data? table Slotdata send from AP server for the specific user/slot
function OnClear(slot_data)
    MANUAL_CHECKED = false
    local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    if custom_storage_item == nil then
        CreateLuaManualStorageItem("manual_location_storage")
        custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    end
    -- repeat that here for every cache-storage item you create just to be safe

    PreOnClear()
    
    local goal_location = Tracker:FindObjectForCode("@Dr. Wily's Fortress 4/Wily Capsule - Defeated (Goal)")
    goal_location.AvailableChestCount = goal_location.ChestCount
    
    ScriptHost:RemoveWatchForCode("StateChanged")
    ScriptHost:RemoveOnLocationSectionHandler("location_section_change_handler")
    --SLOT_DATA = slot_data
    CUR_INDEX = -1
    -- reset locations
    for location_ID, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                if type(location) == "table" then
                    local item_code, item_type, consumable_multiplies = table.unpack(location)
                    ItemUpdate(item_code, item_type, consumable_multiplies, location_ID, true)
                else
                    if location:sub(1, 1) == "@" then
                        ---@type LocationSection
                        local location_obj = Tracker:FindObjectForCode(location) --[[@as LocationSection]]
                        local custom_storage_item = (Tracker:FindObjectForCode("manual_location_storage") --[[@as LuaItem]])
                        .ItemState

                        if location_obj then
                            LocationUpdate(location_obj, custom_storage_item, location_ID, true)
                        end
                    else
                        ---@cast location JsonItem
                        ItemUpdate(location, nil, nil, location_ID, true)
                    end
                end
            end
        end
    end
    -- reset items
    for item_ID, item_array in pairs(ITEM_MAPPING) do
        for _, item_pair in pairs(item_array) do
            local item_code = item_pair[1]
            local item_type = item_pair[2]
            local consumable_multiplier = tonumber(item_pair[3]) or 1
            -- print("on clear", item_code, item_type)
			---@type JsonItem
            local item_obj = Tracker:FindObjectForCode(item_code) --[[@as JsonItem]]
            if item_obj then
                ItemUpdate(item_obj, item_type, consumable_multiplier, item_ID, true)
            end
        end
    end
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data
    -- syncing up options to slot data if available
    for k, v in pairs(slot_data) do
        if SLOT_CODES[k] then
            local setting = Tracker:FindObjectForCode(SLOT_CODES[k].code)
            local stage = (SLOT_CODES[k].mapping and SLOT_CODES[k].mapping[v] or v)
            setting.CurrentStage = stage
        elseif k == "wily_3_requirement" then
            local req = v - 1
            Tracker:FindObjectForCode("opt_rematchreq").CurrentStage = req
        elseif k == "jammed_buster" then
            if v == 0 then
                Tracker:FindObjectForCode("chargebuster").Active = true
            elseif v == 1 then
                Tracker:FindObjectForCode("chargebuster").Active = false
            end
        end
    end
    if Archipelago.PlayerNumber > -1 then
        if #ALL_LOCATIONS > 0 then
            ALL_LOCATIONS = {}
        end
        for _, value in pairs(Archipelago.MissingLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end

        for _, value in pairs(Archipelago.CheckedLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end

        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        GOAL_ID = string.format("_read_client_status_%i_%i", Archipelago.TeamNumber, Archipelago.PlayerNumber)
        Archipelago:SetNotify({HINTS_ID, GOAL_ID})
        Archipelago:Get({HINTS_ID, GOAL_ID})
    end
    -- forcing the consumables setting to sync with the server
    local eddiegift = 520 --@Ring Man Stage/Item from Eddie
    local energypickup = 519 --@Ring Man Stage/Health Energy
    local eddiegifts_enabled = false
    local energypickups_enabled = false
    for _, i in ipairs(Archipelago.CheckedLocations) do
        if i == eddiegift then
            eddiegifts_enabled = true
        elseif i == energypickup then
            energypickups_enabled = true
        end
    end
    for _, i in ipairs(Archipelago.MissingLocations) do
        if i == eddiegift then
            eddiegifts_enabled = true
        elseif i == energypickup then
            energypickups_enabled = true
        end
    end
    if eddiegifts_enabled and energypickups_enabled then
        Tracker:FindObjectForCode("opt_consumables").CurrentStage = 3
    elseif energypickups_enabled then
        Tracker:FindObjectForCode("opt_consumables").CurrentStage = 2
    elseif eddiegifts_enabled then
        Tracker:FindObjectForCode("opt_consumables").CurrentStage = 1
    else
        Tracker:FindObjectForCode("opt_consumables").CurrentStage = 0
    end
    ScriptHost:AddOnFrameHandler("load handler", OnFrameHandler)
    MANUAL_CHECKED = true
end

---Run every time an Item gets sent to the connected slot
---@param index integer running index for the items the connected slot has received so far
---@param item_id integer ID of the received item, matching the game's datapackage ID
---@param item_name string name of the item from the datapackage for the given itemID
---@param player_number integer slotnumber of the player who picked up the item
function OnItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        --print(string.format("OnItem: could not find item mapping for id %s", item_id))
        return
    end
    for _, item_pair in pairs(item) do
        local item_code = item_pair[1]
        local item_type = item_pair[2]
        local consumable_multiplier = tonumber(item_pair[3]) or 1

        local item_obj = Tracker:FindObjectForCode(item_code)
        if item_obj then
            ItemUpdate(item_code, item_type, consumable_multiplier, item_id, false)
        else
            print(string.format("OnItem: could not find object for code %s", item_code))
        end
    end
end

---called when a location gets cleared
---@param location_id integer ID of the location cleared from the datapackage
---@param location_name string name of the location cleared from the datapackage
function OnLocation(location_id, location_name)
    MANUAL_CHECKED = false
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("OnLocation: could not find location mapping for id %s", location_id))
        return
    end

    for _, location in pairs(location_array) do
        if location then
            if type(location) == "table" then
                local item_code, item_type, consumable_multiplier = table.unpack(location)
                ItemUpdate(item_code, item_type, consumable_multiplier, location_id, false)
            else

                if location:sub(1, 1) == "@" then
                    ---@type LocationSection
                    local location_obj = Tracker:FindObjectForCode(location) --[[@as LocationSection]]
                    if location_obj then
                        LocationUpdate(location_obj, custom_storage_item, location_id, false)
                    else
                        print(string.format("OnLocation: could not find location_object for code %s", location))
                    end
                else
                    ItemUpdate(location, nil, nil, location_id, false)
                end
            end
        end
    end
    if location_id == 9 then
        Tracker:FindObjectForCode("cossack1clear").Active = true
    end
    if location_id == 10 then
        Tracker:FindObjectForCode("cossack2clear").Active = true
    end
    if location_id == 11 then
        Tracker:FindObjectForCode("cossack3clear").Active = true
    end
    if location_id == 12 then
        Tracker:FindObjectForCode("cossack4clear").Active = true
    end
    if location_id == 13 then
        Tracker:FindObjectForCode("wily1clear").Active = true
    end
    if location_id == 14 then
        Tracker:FindObjectForCode("wily2clear").Active = true
    end
    if location_id == 15 then
        Tracker:FindObjectForCode("wily3clear").Active = true
    end
    MANUAL_CHECKED = true
end

---@class APHintMessage
---@field receiving_player integer
---@field finding_player integer
---@field location integer
---@field item integer
---@field found boolean
---@field entrance string
---@field item_flags 0|1|2|3|4|5|6|7
---@field status 0|10|20|30|40

---function to update the Highlight of a LocationSection to represent the status of the hint that is present
---for that LocationSection
---@param locationID integer ID of the locations the hint is being given for
---@param status 0|10|20|30|40|100|101|102|103|104|105|106|107 status to determine the color of the hint glow
local function UpdateHints(locationID, status) -->
    if Highlight then
        -- print(locationID, status)
        local location_table = LOCATION_MAPPING[locationID]
        
        -- Safetly stop if the location ID returns nil in location_mapping.lua
        if not location_table then
            print(string.format("UpdateHints: Location ID %s not found in LOCATION_MAPPING. Skipping highlight.", locationID))
            return
        end

        for _, location in ipairs(location_table) do
            if location:sub(1, 1) == "@" then
				---@type LocationSection
                local obj = Tracker:FindObjectForCode(location)

                if obj then
                    obj.Highlight = HIGHLIGHT_LEVEL[status]
                else
                    print(string.format("No object found for code: %s", location))
                end
            end
        end
    end
end

---triggers as AP sends live updates from the server using a given key we subscribed to in Archipelago:SetNotify
---@param key string Name of the key that was used to send the message
---@param value table<integer, APHintMessage>
---@param old_value table<integer, APHintMessage>
function OnNotify(key, value, old_value)
    print("OnNotify", key, value, old_value)
    if value ~= old_value and key == GOAL_ID then
        if value == 30 then
        local goal_location = Tracker:FindObjectForCode("@Dr. Wily's Fortress 4/Wily Capsule - Defeated (Goal)")
        goal_location.AvailableChestCount = goal_location.AvailableChestCount - 1
        end
    elseif value ~= old_value and key == HINTS_ID then
        Tracker.BulkUpdate = true
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
        Tracker.BulkUpdate = false
    end
end

---triggers on connecting to AP when we receive this message from the server after providing a given key to Archipelago:Get
---@param key string Name of the key that was used to send the message
---@param value table<integer, APHintMessage>
function OnNotifyLaunch(key, value)
    if key == GOAL_ID then
        if value == 30 then
        local goal_location = Tracker:FindObjectForCode("@Dr. Wily's Fortress 4/Wily Capsule - Defeated (Goal)")
        goal_location.AvailableChestCount = goal_location.AvailableChestCount - 1
        end
    elseif key == HINTS_ID then
        Tracker.BulkUpdate = true
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
        Tracker.BulkUpdate = false
    end
end
