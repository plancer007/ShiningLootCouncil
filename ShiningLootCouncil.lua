--[[
	Original addon made by Zernin (wotlk) and backported to TBC by CrapSoda.
	Originally called MasterLootManager I decided to give the addon sort of an overhaul to make it a loot council addon and make it as similar as I can to retail's RCLootCouncil addon
	Link to original addon: https://legacy-wow.com/tbc-addons/master-loot-manager/
]]

notifiedNewVersion = false
notifiedNewVersionDate = nil

ShiningLootCouncil = {
	frame = nil,
	constFrame = nil,
	debugging = nil, 
	countdownRange = 10, 
	countdownRunning = false,
    disenchant = nil,
    bank = nil,
    dropdownData = {}, --TODO: change all instanaces of dropdown/Dropdown to dropDown/DropDown to match conventions
    dropdownGroupData = {},
    deDropdownFrame = nil, 
    bankDropdownFrame = nil,
    settingsDropDownFrame = nil,
    settingsMenuList = nil,
    updateFrequency = 1, -- how often to get player's gear data (in seconds)
    lastUpdate = 0,
    starTexture = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    queryingPlayer = false,
    inCombat = false,
    inspectFrequency = 1, -- how often to inspect the players talents
    lastInspect = 0,
    inspectIndex = 0,
    inspectTargetName,
    raidSpecs = {},
    raidRoles = {
    	["Balance"]				= "Damage",
    	["Beast Mastery"]		= "Damage",
    	["Marksmanship"]		= "Damage",
    	["Survival"]			= "Damage",
    	["Arcane"]				= "Damage",
    	["Fire"]				= "Damage",
    	["Frost"]				= "Damage",
    	["Retribution"]			= "Damage",
    	["Shadow"]				= "Damage",
    	["Assassination"]		= "Damage",
    	["Combat"]				= "Damage",
    	["Subtlety"]			= "Damage",
    	["Elemental"]			= "Damage",
    	["Enhancement"]			= "Damage",
    	["Affliction"]			= "Damage",
    	["Demonology"]			= "Damage",
    	["Destruction"]			= "Damage",
		["Protection"]			= "Tank",
   		["Restoration"]			= "Healer",
   		["Holy"]				= "Healer",
   		["Discipline"]			= "Healer",
   		["Feral Combat"]		= "Tank/Damage"
	},
	specIcons = {},
	raids = {
		"Karazhan",
		"Gruul's Lair",
		"Serpentshrine Cavern",
		"Magtheridon's Lair",
		"Tempest Keep",
		"Black Temple",
		"Hyjal Summit",
		"Zul'Aman",
		"Sunwell Plateau",
	}
}
                     
ShiningLootCouncilSettings = {
	ascending = true,
	enforcelow = true,
	enforcehigh = true,
    ignorefixed = true,
}

SlotName = {
	"Head",
	"Neck",
	"Shoulder",
	"Back",
	"Chest",
	"Wrist",
	"Hands",
	"Waist",
	"Legs",
	"Feet",
	"Finger0",
	"Finger1",
	"Trinket0",
	"Trinket1",
	"MainHand",
	"SecondaryHand",
	"Ranged"
}

-- lootCount 	the amount of loot is left to loot from the mob
-- loot 		info about the loot from the mob
-- itemlevels 	keeps the itemlevels of players in the raid saved in a table
-- itemlevel 	the itemlevel of the current item that's being rolled for.
SLCTable = {lootCount = 0, loot = {}, itemlevels = {}, itemlevel = 0, playerSpecs = {}}

SLCRolls = {itemCount = 0, items = {}, playerVotedFor = nil}

function ShiningLootCouncil:Split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function ShiningLootCouncil:Print(str)
	DEFAULT_CHAT_FRAME:AddMessage(str)
end

function ShiningLootCouncil:Trim(str)
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function ShiningLootCouncil:DebugPrint(str)
	if (ShiningLootCouncil.debugging) then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF15FF15" .. str .. "|r")
	end
end

function ShiningLootCouncil:SelectionButtonClicked(buttonFrame)
	self.selectionFrame:Hide()
	self.currentItemIndex = buttonFrame:GetID()
	self:UpdateCurrentItem()
end

function ShiningLootCouncil:PlayerTalentSpec(unit)
	local name = UnitName(unit)
	if name == UnitName("player") then
		local totalPoints, maxPoints, specIdx, specName, specIcon = 0,0,0

		for i = 1, MAX_TALENT_TABS do
			local name, icon, pointsSpent = GetTalentTabInfo(i, isInspect)
			totalPoints = totalPoints + pointsSpent
			if maxPoints < pointsSpent then
				maxPoints = pointsSpent
				specIdx = i
				specName = name
				specIcon = icon
			end
		end

		if totalPoints < 61 then return end

		--if specName then self.raidSpecs[name] = specName end
		if specName then
			if not self.raidSpecs[name] then
				self.raidSpecs[name] = {}
			end
			table.insert(self.raidSpecs[name], specName)
		end
		if specIcon then
			if not self.specIcons[specName] then
				self.specIcons[specName] = {}
			end
			--self.specIcons[specName] = specIcon
			table.insert(self.specIcons[specName], specIcon)
		end
	else
		local canInspect = CheckInteractDistance(unit, 1); -- check if we're close enough to inspect them.
		if canInspect and CanInspect(unit) then
			--self:Print("querying for inspection on " .. unit)
			self.queryingPlayer = true
			NotifyInspect(unit)
		end
	end


	--Print(table.concat(talents, "/"));

	--[[local nums = {string.split("/", talents)};
	Print(nums)
	if(table.getn(nums) ~= 3) then return talents; end
	
	--if(not WIM_SpellTree[WIM_Windows[theUser].class]) then return talents; end
	
	local classTree = WIM_SpellTree[WIM_Windows[theUser].class];
	
	if(talents == "0/0/0") then return _G.NONE or "None"; end
	
	--calculate which order the tabs should be in; in relation to spec.
	local order = {};
	local num = "";
	for i=1,3 do
		nums[i] = tonumber(nums[i]);
		num = nums[i];
		if(string.len(num) == 1) then num = "0"..num; end
		table.insert(order, num..i);
	end
	table.sort(order);
	
	local first, second, third = tonumber(string.sub(order[3],-1)), tonumber(string.sub(order[2],-1)), tonumber(string.sub(order[1],-1));
	
	if(nums[first]*.75 <= nums[second]) then
		if(nums[first]*.75 <= nums[third]) then
			return WIM_SpellTree["Hybrid"]..": "..talents;
		else
			return classTree[tostring(first)].."/"..classTree[tostring(second)]..": "..talents;
		end
	else
		return classTree[tostring(first)]..": "..talents;
	end]]


end

function ShiningLootCouncil:GetClassColor(className)
	if (className == "DEATH KNIGHT") then
		className = "DEATHKNIGHT"
	end
	if (RAID_CLASS_COLORS[className] == nil) then
		self:Print("No such class: " .. className)
		return 0, 0, 0
	end
	return RAID_CLASS_COLORS[className].r, RAID_CLASS_COLORS[className].g, RAID_CLASS_COLORS[className].b
	--[[
	if (className == "DEATHKNIGHT") then
		return 0.77, 0.12, 0.23
	end
	
	if (className == "DRUID") then
		return 1.00, 0.49, 0.04
	end
	
	if (className == "HUNTER") then
		return 0.67, 0.83, 0.45
	end
	
	if (className == "MAGE") then
		return 0.41, 0.80, 0.94
	end
	
	if (className == "PALADIN") then
		return 0.96, 0.55, 0.73
	end
	
	if (className == "PRIEST") then
		return 1.00, 1.00, 1.00
	end
	
	if (className == "ROGUE") then
		return 1.00, 0.96, 0.41
	end
	
	if (className == "SHAMAN") then
		return 0.14, 0.35, 1.00
	end
	
	if (className == "WARLOCK") then
		return 0.58, 0.51, 0.79
	end
	
	if (className == "WARRIOR") then
		return 0.78, 0.61, 0.43
	end
	--]]
end

function ShiningLootCouncil:OnLoad(frame)
	self.frame = frame
	self.constFrame = CreateFrame("Frame")
	
	self.frame:RegisterEvent("LOOT_OPENED")
	self.frame:RegisterEvent("LOOT_CLOSED")
	self.frame:RegisterEvent("CHAT_MSG_RAID")
	self.frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	self.frame:RegisterEvent("LOOT_SLOT_CLEARED")
    self.frame:RegisterEvent("RAID_ROSTER_UPDATE")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("INSPECT_TALENT_READY")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	 
	self.frame:SetScript("OnEvent", 
			function(frame, event, ...)
				self:OnEvent(self, event, ...)
			end)

	self.constFrame:SetScript("OnUpdate",self.OnUpdate)

	self.frame:RegisterForDrag("LeftButton")
	self.frame:SetClampedToScreen(true)
    
    self.settingsDropDownFrame = CreateFrame("Frame", "ShiningLootCouncil_SettingsDropDownFrame", nil, "UIDropDownMenuTemplate")
    
    self:InitializeSettingsMenuList()
    
    for index = 1, 8 do
        self.dropdownData[index] = {};
    end
    
    self:UpdateDropdowns()
    
    UIDropDownMenu_Initialize(self.deDropdownFrame, ShiningLootCouncil.InitializeDropdown);
    UIDropDownMenu_Initialize(self.bankDropdownFrame, ShiningLootCouncil.InitializeDropdown);
	
	self:DebugPrint("ShiningLootCouncil loaded")
end

SLASH_SLC1 = "/slc"
SlashCmdList["SLC"] = function(msg, editBox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");

    ShiningLootCouncil:DebugPrint("Command = " .. command or "")

    if (command == "show" or command == "") then
        if (not ShiningLootCouncil.frame:IsShown()) then
            ShiningLootCouncil.frame:Show()
        else
            ShiningLootCouncil.frame:Hide()
        end
    elseif (command == "hide") then
        ShiningLootCouncil.frame:Hide()
    elseif command == "talents" then
    	for k,v in pairs(ShiningLootCouncil.raidSpecs) do
    		ShiningLootCouncil:Print(k .. " - " .. v[math.ceil(#v/2)])
    	end
    elseif command == "ilvl" then
    	for k,v in pairs(SLCTable.itemlevels) do
    		ShiningLootCouncil:Print(k .. " - " .. v[math.ceil(#v/2)])
    	end
    else
        ShiningLootCouncil:Print("Acceptable subcommands to /slc:".."\nshow - shows the roll window".."\nhide - hides the roll window")
    end
end

function ShiningLootCouncil:AwardLootClicked(buttonFrame)
	for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == SLCRolls.winningPlayer) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == SLCTable:GetItemLink(self.currentItemIndex)) then
						GiveMasterLoot(itemIndex, winningPlayerIndex)
						self:Speak("Congratulations to " .. SLCRolls.winningPlayer .. " on winning " .. itemLink)
						return
					end
				end
				self:Print("MasterLootManger: Cannot find item - " .. SLCTable:GetItemLink(self.currentItemIndex))
			end
		end
	end
	if SLCRolls.winningPlayer then
		self:Print("MasterLootManger: Cannot find player - " .. SLCRolls.winningPlayer .. ". Player not registered as viable to receive the item in the addon. Please give them the item manually.")
	else
		self:Print("No player selected.")
	end
end

function ShiningLootCouncil:OnEvent(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	if (event == "LOOT_OPENED") then
		if (self:PlayerIsMasterLooter()) then
			self:DebugPrint("Loot was opened and the player is the master looter.")
			self:FillLootTable()
			self:UpdateSelectionFrame()
			if (SLCTable.lootCount > 0) then
				self.frame:Show()
			end
		else
			self:DebugPrint("Loot was opened, but the player is not the master looter.")
		end
	elseif (event == "LOOT_CLOSED") then
		self.frame:Hide()
	elseif (event == "LOOT_SLOT_CLEARED") then
		self:FillLootTable()
		self:UpdateSelectionFrame()
		if (SLCTable.lootCount > 0) then
			self.frame:Show()
		else
			self.frame:Hide()
			collectgarbage("collect")
		end
	elseif event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID" then
		if SLCTable.lootCount > 0 then
			local message = arg1
			local sender = arg2
			self:HandlePossibleRoll(message,sender)
		end
    elseif (event == "RAID_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD") then
    	self.inspectIndex = 0
        self:UpdateDropdowns()
    elseif event == "INSPECT_TALENT_READY" then
    	local totalPoints, maxPoints, specIdx, specName, specIcon = 0,0,0

		for i = 1, MAX_TALENT_TABS do
			local name, icon, pointsSpent = GetTalentTabInfo(i, true)
			totalPoints = totalPoints + pointsSpent
			if maxPoints < pointsSpent then
				maxPoints = pointsSpent
				specIdx = i
				specName = name
				specIcon = icon
			end
		end

		if totalPoints < 61 then return end

		ClearInspectPlayer()

		if self.raidSpecs and self.inspectTargetName and specName then
			if not self.raidSpecs[self.inspectTargetName] then
				self.raidSpecs[self.inspectTargetName] = {}
			end
			--self.raidSpecs[self.inspectTargetName] = specName
			table.insert(self.raidSpecs[self.inspectTargetName], specName)
		end
		if specIcon then
			if not self.specIcons[specName] then
				self.specIcons[specName] = {}
			end
			--self.specIcons[specName] = specIcon
			table.insert(self.specIcons[specName], specIcon)
		end
		self.queryingPlayer = false
		self.inspectTargetName = nil
    elseif event == "PLAYER_REGEN_DISABLED" then
    	if UnitLevel("target") < 0 or UnitLevel("targettarget") < 0 then
    		self.inCombat = true
    	end
    elseif event == "PLAYER_REGEN_ENABLED" then
    	self.inCombat = false
    end
end

function ShiningLootCouncil:HandlePossibleRoll(message,sender)
	if sender ~= nil and SLCTable.lootCount > 0 then
		local rollPattern = "item[%-?%d:]+"
		item = string.match(message, rollPattern)

		if item then
			local msg = "" -- empty string created to get all the non-item link text in the message that was sent. So if the player links an item and says "t5 bis", msg will be "t5 bis"
			stop = false -- indicates whether to add onto msg or not. This becomes true if we're iterating over the item link, then turns back to false when we're past the item

			-- loop through the player's message. If the index is not going through an item link, append message[i] to msg.
			for i = 1, #message do
				-- if the next two chars are "|c" that means it's starting a link
				if (#message - i) >= 2 and message:sub(i,i+1) == "|c" then
					stop = true
				-- if the last 4 chars are "|h|r" that means the link just ended
				elseif i >= 5 and message:sub(i-4,i-1) == "|h|r" then
					stop = false
				end
				if stop == false then
					msg = msg .. message:sub(i,i)
				end
			end
			msg = self:Trim(msg)

			-- 'item' is a string that looks like item:7073:0:0:0:0:0:0:0:80:0 so we need to find the index of the second semicolon so we know where the ID ends index-wise
			endIndex = 0
			for i = 6, #item do
				if item:sub(i,i) == ":" then
					endIndex = i-1
					break
				end
			end
			itemID = string.sub(tostring(item),6,endIndex)
			itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemID)

			if sender ~= nil and itemLink ~= nil and itemRarity > 1 then
				self:DebugPrint(sender .. " linked " .. itemLink)
				guildName, guildRankName, guildRankIndex = GetGuildInfo(sender) -- change this somehow to the player who linked item instead of us
				player = {
					name = sender,
					guildRank = guildRankName or "not found",
					role = SLCRolls:GetPlayerRole(sender), 
					votes = 0,
					--ilvl = SLCTable.itemlevels[sender] or 0,
					ilvl = SLCTable.itemlevels[sender][math.ceil(#SLCTable.itemlevels[sender]/2)] or 0,
					note = msg or ""
				}
				item = {
					name = itemName,
					rarity = itemRarity,
					ilvl = itemLevel or 0,

				}
				SLCRolls:AddPlayer(player, item)
			end
		end
	end
end

function SLCRolls:AddPlayer(player, item)
	ShiningLootCouncil:DebugPrint("Adding item for " .. player.name)
	for itemIndex = 1, self.itemCount do
		if (self.items[itemIndex].playerName == player.name) and ShiningLootCouncil.debugging ~= true then
			ShiningLootCouncil:DebugPrint("Ignoring the item linked.")
			return
		end
	end
	self.itemCount 								= self.itemCount + 1
	self.items[self.itemCount] 					= {}
	self.items[self.itemCount].playerName 		= player.name
	self.items[self.itemCount].playerGuildRank 	= player.guildRank or "Not Found"
	self.items[self.itemCount].playerRole 		= player.role
	self.items[self.itemCount].votes 			= player.votes
	self.items[self.itemCount].playerIlvl 		= player.ilvl
	self.items[self.itemCount].note 			= player.note
	self.items[self.itemCount].itemName 		= item.name
	self.items[self.itemCount].itemRarity 		= item.rarity
	self.items[self.itemCount].itemIlvl 		= item.ilvl
	ShiningLootCouncil:DebugPrint("Added item for " .. player.name)

	self:UpdateRollList()
end

function ShiningLootCouncil:PlayerSelectionButtonClicked(buttonFrame)
	local buttonName = buttonFrame:GetName()
	local playerNameLabel = getglobal(buttonName .. "_PlayerName")
	local playerName = playerNameLabel:GetText()
	local index = string.sub(buttonName, 22) -- gets the index of the player from the button's name (the last digit(s) are the index)

	SLCRolls:VotePlayer(index)
	if SLCRolls.winningPlayer == playerName then
		SLCRolls.winningPlayer = nil
	else
		SLCRolls.winningPlayer = playerName
	end
	SLCRolls:UpdateRollList()
end

function SLCRolls:GetPlayerIndex(name)
	for i = 1, #self.items do
		if self.items[i].playerName == name then
			return i
		end
	end
	return 0
end

function ShiningLootCouncil:Count(table,element)
	local c = 0
	for i = 1, #table do
		if table[i] == element then
			c = c + 1
		end
	end
	return c
end

-- Function taken from ElvUI tooltip.lua
function SLCTable:GetAllPlayersIlvl()
	for i = 1, 40 do
		local player = UnitName("raid" .. i)
		if player ~= nil --[[and UnitIsConnected("raid"..i) and CheckInteractDistance("raid"..i,1)]] then
			local total, item = 0, 0
			for j = 1, #SlotName do
				local itemLink = GetInventoryItemLink("raid" .. i, GetInventorySlotInfo(("%sSlot"):format(SlotName[j])))
				if itemLink then
					local itemLevel = select(4, GetItemInfo(itemLink))
					if itemLevel and itemLevel > 0 then
						item = item + 1
						total = total + itemLevel
					end
				end
			end 
			total = total/item
			if total > 0 then
				if not self.itemlevels[player] then
					self.itemlevels[player] = {}
				end
				table.insert(self.itemlevels[player],tonumber(math.floor(total)))
			end
		end
	end

	if #SLCTable.itemlevels >= 25 then
		ShiningLootCouncil.updateFrequency = 60
	end
end

-- Function taken from ElvUI core.lua
function SLCRolls:GetTalentSpecInfo(isInspect)
	local maxPoints, specIdx, specName, specIcon = 0, 0

	for i = 1, MAX_TALENT_TABS do
		local name, icon, pointsSpent = GetTalentTabInfo(i, isInspect)
		if maxPoints < pointsSpent then
			maxPoints = pointsSpent
			specIdx = i
			specName = name
			specIcon = icon
		end
	end

	if not specName then
		specName = NONE
	end
	if not specIcon then
		specIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
	end

	return specIdx, specName, specIcon
end

function SLCTable:GetPlayerIlvl(index)
	local name = SLCRolls:GetPlayerName(index)
	return self.itemlevels[name][math.ceil(#self.itemlevels[name]/2)]
end

function SLCRolls:GetPlayerName(index)
	return self.items[index].playerName
end

function SLCRolls:GetPlayerItem(index)
	return self.items[index].itemName
end

function SLCRolls:GetPlayerGuildRank(index)
	return self.items[index].playerGuildRank
end

function SLCRolls:GetPlayerRole(name)
	return ShiningLootCouncil.raidRoles[ShiningLootCouncil.raidSpecs[name][math.ceil(#ShiningLootCouncil.raidSpecs[name]/2)]] or "not found"
end

function SLCRolls:GetItemIlvl(index)
	return self.items[index].ilvl
end

function SLCRolls:GetPlayerItemlevelDifference(index)
	return (SLCTable.itemlevel - self.items[index].itemIlvl)
end

--[[function SLCRolls:GetPlayerIlvl(index)
	return self.items[index].playerIlvl
end]]

function SLCRolls:GetPlayerVotes(index)
	return self.items[index].votes
end

function SLCRolls:GetPlayerNote(index)
	return self.items[index].note
end

function SLCRolls:GetPlayerItemRarity(index)
	return self.items[index].itemRarity
end

function SLCRolls:ClearRolls()
	self.itemCount 		= 0
	self.items 			= {}
	self.playerVotedFor = nil
	self:ClearRollList()
end

-- Adds a vote to the player at a specified index. If you've already voted for the player then it retracts their vote instead.
-- 
-- @author Hildigunnur
-- @params index : the index of the player we're giving a vote to in the SLCRolls.items table
-- return Nothing
function SLCRolls:VotePlayer(index)
	local diff = self.itemCount - index
	local i = self.itemCount - diff 	-- ugliest hack I've ever seen but for some reason using the index parameter DOESN'T FUCKING WORK.
	local playerName = self:GetPlayerName(i)
	local j = nil -- this becomes the ID of the player whose vote you're retracting. If this is not equal to nil then don't add a vote for the player else you just retract their vote then give it back to them.
	-- sendaddonmessage to other council members
	-- if you've already voted for a player then remove your vote from their count
	if self.playerVotedFor ~= nil then -- self.playerVotedFor == playerName
		ShiningLootCouncil:DebugPrint("Voting for player already voted for. Retracting vote")
		local votedIndex = self:GetPlayerIndex(self.playerVotedFor)
		local votedDiff = self.itemCount - votedIndex
		local votedI = self.itemCount - votedDiff
		self.items[votedI].votes = self.items[votedI].votes - 1
		j = votedI

		if self.playerVotedFor == playerName then
			self.playerVotedFor = nil
		else
			self.playerVotedFor = playerName
		end
	end

	-- add 1 vote to the current player
	-- If j is equal to nil then you didn't retract a vote. If you retracted a vote and j (the index of the player vote retracted) is equal to i then it's trying to add a vote to the player whose vote you just retracted.
	if j ~= i or j == nil then
		self.items[i].votes = self.items[i].votes + 1
		self.playerVotedFor = playerName
	end
end

function SLCRolls:ClearRollList()
	local itemIndex = 1
	local rollFrame = getglobal("PlayerSelectionButton" .. itemIndex)
	while (rollFrame ~= nil) do
		rollFrame:Hide()
		itemIndex = itemIndex + 1
		rollFrame = getglobal("PlayerSelectionButton" .. itemIndex)
	end
end

function SLCRolls:UpdateRollList()
	local totalHeight = 0
	local scrollFrame = getglobal("ShiningLootCouncilMain_ScrollFrame")	
	local scrollChild = getglobal("ShiningLootCouncilMain_ScrollFrame_ScrollChildFrame")
	
	scrollChild:SetHeight(scrollFrame:GetHeight())
	scrollChild:SetWidth(scrollFrame:GetWidth())
		
	for i = 1, self.itemCount do
		local buttonName = "PlayerSelectionButton" .. i
		local rollFrame = getglobal(buttonName) or CreateFrame("Button", buttonName, scrollChild, "PlayerSelectionButtonTemplate")
		rollFrame:Show()
		
		-- player name
		local playerName = self:GetPlayerName(i)
		local playerNameLabel = getglobal(buttonName .. "_PlayerName")
		local r, g, b = ShiningLootCouncil:GetClassColor(string.upper(UnitClass(playerName)))
		playerNameLabel:SetText(playerName)
		playerNameLabel:SetTextColor(r, g, b)
			
		-- the texture in front of the player name. Either a star, if they're selected by the player, otherwise their spec icon.
		local texture = getglobal(buttonName .. "_Texture")
		if (playerName == self.winningPlayer) then
			texture:Show() -- remove this and make it always visible
			texture:SetTexture(ShiningLootCouncil.starTexture,true)
			texture:SetSize(16,16)
			texture:SetTexCoord(0,0.25,0,0.25)
		else
			texture:Show()
			-- the table with all the icon paths for that spec
			local specIconsTable = ShiningLootCouncil.specIcons[ShiningLootCouncil.raidSpecs[playerName][math.ceil(#ShiningLootCouncil.raidSpecs[playerName]/2)]]
			texture:SetTexture(specIconsTable[math.ceil(#specIconsTable/2)],true)
			texture:SetSize(16,16)
			texture:SetTexCoordModifiesRect(false) -- hmm
			--texture:SetScale(0.5) --error
			texture:SetTexCoord(0,1,0,1)
		end
			
		-- player item
		local playerItem = self:GetPlayerItem(i)
		local playerItemLabel = getglobal(buttonName .. "_PlayerItem")

		-- player guild rank
		local playerGuildRank = self:GetPlayerGuildRank(i)
		local playerGuildRankLabel = getglobal(buttonName .. "_PlayerGuildRank")
		playerGuildRankLabel:SetText(playerGuildRank)

		-- player role
		local playerRole = self:GetPlayerRole(playerName)
		local playerRoleLabel = getglobal(buttonName .. "_PlayerRole")
		playerRoleLabel:SetText(playerRole)

		-- player item level
		local playerIlvl = SLCTable:GetPlayerIlvl(i)
		local playerIlvlLabel = getglobal(buttonName .. "_PlayerItemlevel")
		playerIlvlLabel:SetText(playerIlvl)

		-- player's item level difference for the item
		local playerItemlevelDifference = self:GetPlayerItemlevelDifference(i)
		local playerItemlevelDifferenceLabel = getglobal(buttonName .. "_PlayerItemlevelDifference")
		playerItemlevelDifferenceLabel:SetText(playerItemlevelDifference)

		-- sets the color of the text to green if it's an ilvl upgrade, red if it's an ilvl downgrade and gray if it's the same ilvl
		if playerItemlevelDifference > 0 then
			playerItemlevelDifferenceLabel:SetText("|cff00ff00" .. playerItemlevelDifference)
		elseif playerItemlevelDifference < 0 then
			playerItemlevelDifferenceLabel:SetText("|cFFFF0000" .. playerItemlevelDifference)
		else
			playerItemlevelDifferenceLabel:SetText("|cFF808080" .. playerItemlevelDifference)
		end

		-- player votes
		local playerVotes = self:GetPlayerVotes(i)
		local playerVotesLabel = getglobal(buttonName .. "_PlayerVotes")
		playerVotesLabel:SetText(playerVotes)

		-- player note
		local playerNote = self:GetPlayerNote(i)
		local playerNoteLabel = getglobal(buttonName .. "_PlayerNote")
		playerNoteLabel:SetText(playerNote)

		-- set the item's rarity color
		if (self:GetPlayerItemRarity(i) == 5) then
			playerItemLabel:SetText("|cffff8000" .. playerItem)
		elseif (self:GetPlayerItemRarity(i) == 4) then
			playerItemLabel:SetText("|cffa335ee" .. playerItem)
		elseif (self:GetPlayerItemRarity(i) == 3) then
			playerItemLabel:SetText("|cff0070dd" .. playerItem)
		elseif (self:GetPlayerItemRarity(i) == 2) then
			playerItemLabel:SetText("|cff1eff00" .. playerItem)
		end

		-- set the item level difference's color
		-- todo
		
		rollFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -totalHeight)
		rollFrame:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
		totalHeight = totalHeight + rollFrame:GetHeight()
	end

	local slider = getglobal("ShiningLootCouncilMain_ScrollFrame_Slider")
	local maxValue = totalHeight - scrollChild:GetHeight()
	if (maxValue < 0) then
		maxValue = 0
	end
	slider:SetMinMaxValues(0, maxValue)
	slider:SetValue(0)

	ShiningLootCouncil:DebugPrint("Updated roll list.")
end

function ShiningLootCouncil:FillLootTable()
	local oldLootItem
	if (SLCTable.lootCount > 0) then
		oldLootItem = SLCTable:GetItemLink(self.currentItemIndex)
	end
	SLCTable:Clear()
	for lootIndex = 1, GetNumLootItems() do
		if (LootSlotIsItem(lootIndex)) then
			local itemLink = GetLootSlotLink(lootIndex)
			self:DebugPrint("Adding " .. itemLink .. " to loot table")
			SLCTable:AddItem(itemLink)
		end
	end
	self.currentItemIndex = 1
	if (oldLootItem ~= nil) then
		for itemIndex = 1, SLCTable:GetItemCount() do
			if (oldLootItem == SLCTable:GetItemLink(itemIndex)) then
				self.currentItemIndex = itemIndex
			end
		end
	end
	self:UpdateCurrentItem()
end

function ShiningLootCouncil:UpdateSelectionFrame()
	self:CreateBasicSelectionFrame()
	local frameHeight = 5
	for itemIndex = 1, SLCTable:GetItemCount() do
		local buttonName = "SelectionButton" .. itemIndex
		local buttonFrame = getglobal(buttonName) or CreateFrame("Button", buttonName, self.selectionFrame, "SelectionButtonTemplate")
		buttonFrame:Show()
		buttonFrame:SetID(itemIndex)
		local itemLink = SLCTable:GetItemLink(itemIndex)
		local buttonItemLink = getglobal(buttonName .. "_ItemLink")
		buttonItemLink:SetText(itemLink)
		
		local itemTexture = SLCTable:GetItemTexture(itemIndex)
		local buttonItemTexture = getglobal(buttonName .. "_ItemTexture")
		buttonItemTexture:SetTexture(itemTexture)
		
		buttonFrame:SetPoint("TOPLEFT", self.selectionFrame, "TOPLEFT", 0, -frameHeight)
		frameHeight = frameHeight + 37
	end
	self.selectionFrame:SetHeight(frameHeight)
end

function SLCTable:GetItemCount()
	return self.lootCount
end

function ShiningLootCouncil:CreateBasicSelectionFrame()
	if (self.selectionFrame == nil) then
		self.selectionFrame = CreateFrame("Frame", nil, UIParent)
		self.selectionFrame:SetBackdrop( {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 10,
			edgeSize = 10,
			insets = {
				left = 3,
				right = 3,
				top = 3,
				bottom = 3 }})
		self.selectionFrame:SetAlpha(1)
		self.selectionFrame:SetBackdropColor(0, 0, 0, 1)
		
		self.selectionFrame.texture = self.selectionFrame:CreateTexture()
		self.selectionFrame.texture:SetTexture(0, 0, 0, 1)
		self.selectionFrame.texture:SetPoint("TOPLEFT", self.selectionFrame, "TOPLEFT", 3, -3)
		self.selectionFrame.texture:SetPoint("BOTTOMRIGHT", self.selectionFrame, "BOTTOMRIGHT", -3, 3)
		
		self.selectionFrame:SetWidth(200)
		self.selectionFrame:SetHeight(100)
		self.selectionFrame:SetFrameStrata("DIALOG")
		self.selectionFrame:Hide()
	end
	local index = 1
	local buttonName = "SelectionButton" .. index
	local buttonHandle = getglobal(buttonName)
	while (buttonHandle ~= nil) do
		buttonHandle:Hide()
		index = index + 1
		buttonName = "SelectionButton" .. index
		buttonHandle = getglobal(buttonName)
	end
end

function ShiningLootCouncil:UpdateCurrentItem()

	if (SLCTable:ItemExists(self.currentItemIndex)) then
		local itemLink = SLCTable:GetItemLink(self.currentItemIndex)
		local itemLinkLabel = getglobal("ShiningLootCouncilMain_CurrentItemLink")
		itemLinkLabel:SetText(itemLink)
		
		local itemTexture = SLCTable:GetItemTexture(self.currentItemIndex)
		local currentItemTexture = getglobal("ShiningLootCouncilMain_CurrentItemTexture")
		currentItemTexture:SetTexture(itemTexture)

		SLCTable.itemlevel = SLCTable:GetItemIlvl(self.currentItemIndex) or 0
		getglobal("ShiningLootCouncilMain_CurrentItemIlvl"):SetText("ilvl: " .. SLCTable.itemlevel)

		self:DebugPrint("Changed item link")
	else
		self:DebugPrint("Item doesn't exist")
	end
	
end

function SLCTable:ItemExists(index)
	return self.loot[index] ~= nil
end

function SLCTable:GetItemLink(index)
	if index and self.loot and self.loot[index] and self.loot[index].itemLink then
 		return self.loot[index].itemLink
 	end
end

function SLCTable:GetItemTexture(index)
	return self.loot[index].itemTexture
end

function SLCTable:GetItemIlvl(index)
	return self.loot[index].ilvl
end

function SLCTable:Clear()
	self.lootCount = 0
	self.loot = {}
end

function SLCTable:AddItem(itemLink)
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemLink)
	local lootThreshold = GetLootThreshold()
	if (itemRarity < lootThreshold) and ShiningLootCouncil.debugging ~= true then
		return
	end
	self.lootCount = self.lootCount + 1
	self.loot[self.lootCount] 				= {}
	self.loot[self.lootCount].itemLink 		= itemLink
	self.loot[self.lootCount].itemTexture 	= itemTexture
	self.loot[self.lootCount].ilvl 			= itemLevel
	ShiningLootCouncil:DebugPrint("New loot count: " .. self.lootCount)
end

function ShiningLootCouncil:SelectItemClicked(buttonFrame)
	if not self.selectionFrame then return end
	if (self.selectionFrame:IsShown()) then
		self.selectionFrame:Hide()
	else
		self.selectionFrame:SetPoint("TOP", buttonFrame, "BOTTOM")
		self.selectionFrame:Show()
	end
end

function ShiningLootCouncil:AnnounceMainSpecClicked(buttonFrame)
	local itemLink = SLCTable:GetItemLink(self.currentItemIndex)
	if not itemLink then return end
	SLCRolls:ClearRolls()
	self:Speak("Link your current item if you need " .. itemLink .. ", MAIN SPEC")
end

function ShiningLootCouncil:AnnounceOffSpecClicked(buttonFrame)
	local itemLink = SLCTable:GetItemLink(self.currentItemIndex)
	if not itemLink then return end
	SLCRolls:ClearRolls()
	self:Speak("Link your current item if you need " .. itemLink .. ", OFF SPEC")
end

function ShiningLootCouncil:AnnounceNoSpecClicked(buttonFrame)
	local itemLink = SLCTable:GetItemLink(self.currentItemIndex)
	if not itemLink then return end
	SLCRolls:ClearRolls()
	self:Speak("Link your current item if you need " .. itemLink .. ", for DISENCHANT")
end

function ShiningLootCouncil:AnnounceLootClicked(buttonFrame)
	local output = "The boss dropped: "
	for itemIndex = 1, SLCTable:GetItemCount() do
		local itemLink = SLCTable:GetItemLink(itemIndex)
		output = output .. itemLink
	end
	self:Speak(output)
end

function ShiningLootCouncil:ClearRollList(buttonFrame)
	SLCRolls:ClearRolls()
end

function ShiningLootCouncil:CountdownClicked(buttonFrame)
	self.countdownRunning = true
	self.countdownStartTime = GetTime()
	self.countdownLastDisplayed = self.countdownRange + 1
end

function ShiningLootCouncil:CollectInfo()
	if self.inCombat then
		return false
	end

	local zone = GetRealZoneText()

	local inRaid = false
	for i = 1, #self.raids do
		if self.raids[i] == zone then inRaid = true break end
	end

	if not inRaid then
		--self:Print("not collecting info")
		return false
	end

	return true
end

function ShiningLootCouncil:OnUpdate()
	if (ShiningLootCouncil.countdownRunning) then
		local currentCountdownPosition = math.ceil(ShiningLootCouncil.countdownRange - GetTime() + ShiningLootCouncil.countdownStartTime)
		if (currentCountdownPosition < 1) then
			currentCountdownPosition = 1
		end
		local i = ShiningLootCouncil.countdownLastDisplayed - 1
		while (i >= currentCountdownPosition) do
			ShiningLootCouncil:Speak(i)
			i = i - 1
		end
		
		ShiningLootCouncil.countdownLastDisplayed = currentCountdownPosition
		if (currentCountdownPosition <= 1) then
			ShiningLootCouncil.countdownRunning = false
		end
	end
	if ShiningLootCouncil:CollectInfo() and ShiningLootCouncil.updateFrequency < (GetTime() - ShiningLootCouncil.lastUpdate) then
		ShiningLootCouncil.lastUpdate = GetTime()
		SLCTable:GetAllPlayersIlvl()
		--ShiningLootCouncil:Print("Getting ilvl")
	end

	if ShiningLootCouncil:CollectInfo() and ShiningLootCouncil.inspectFrequency < GetTime() - ShiningLootCouncil.lastInspect and ShiningLootCouncil.queryingPlayer == false then
		ShiningLootCouncil.inspectIndex = ShiningLootCouncil.inspectIndex + 1
		if UnitName("raid"..ShiningLootCouncil.inspectIndex) then
			ShiningLootCouncil.inspectTargetName = UnitName("raid"..ShiningLootCouncil.inspectIndex)
			ShiningLootCouncil:PlayerTalentSpec("raid"..ShiningLootCouncil.inspectIndex)
			--ShiningLootCouncil:Print("getting talents")
		else
			ShiningLootCouncil.lastInspect = GetTime()
			ShiningLootCouncil.inspectIndex = 0
		end
	end
end

function ShiningLootCouncil:Speak(str)
	local chatType = "SAY";
	
	if (self:PlayerIsInAParty()) then
		chatType = "PARTY";
	end
	
	if (self:PlayerIsInARaid()) then
		chatType = "RAID_WARNING";
	end
	
	SendChatMessage(str, chatType)
end

function ShiningLootCouncil:PlayerIsInAParty()
	return GetNumPartyMembers() ~= 0
end

function ShiningLootCouncil:PlayerIsInARaid()
	return GetNumRaidMembers() ~= 0
end

function ShiningLootCouncil:PlayerIsMasterLooter()		
	local lootMethod, masterLooterPartyID, masterLooterRaidID = GetLootMethod()
	if (lootMethod ~= "master") then
		return false
	end

	-- temporary so I can test its performancce
	if UnitName("player") == "Hildigunnur" then
		return true
	end
	
	if (masterLooterPartyID ~= 0) then
		return false
	end
	return true
end

function ShiningLootCouncil:UpdateDropdowns()
        
    local numRaidMembers = GetNumRaidMembers();
    
    for x = 1, numRaidMembers do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(x);
        --sets the group member key to the players name. Also stores thier raid index. 
        --TODO: figure out why I set the value and key as name, instead of one as x o.O
        self.dropdownData[subgroup][name] = name;
        --TODO: confirm current DE/Bank char is still in raid
        self.dropdownGroupData[subgroup] = true;
    end
end

function ShiningLootCouncil:InitializeDropdown()
    --ShiningLootCouncil:DebugPrint("Dropdown Init Level: " .. UIDROPDOWNMENU_MENU_LEVEL);
    if (UIDROPDOWNMENU_MENU_LEVEL == 2) then
        local groupnumber = UIDROPDOWNMENU_MENU_VALUE;
        groupmembers = ShiningLootCouncil.dropdownData[groupnumber];
        for key, value in pairs(groupmembers) do
            local info = UIDropDownMenu_CreateInfo();
            info.hasArrow = false;
            info.notCheckable = true;
            info.text = key;
            info.value = key;
            info.owner = UIDROPDOWNMENU_OPEN_MENU;
            info.func = ShiningLootCouncil.DropClicked;
            UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
        end
    end
    
    if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
        for key, value in pairs(ShiningLootCouncil.dropdownData) do
            if (ShiningLootCouncil.dropdownGroupData[key] == true) then
                local info = UIDropDownMenu_CreateInfo();
                info.hasArrow = true;
                info.notCheckable = true;
                info.text = "Group " .. key;
                info.value = key;
                info.owner = UIDROPDOWNMENU_OPEN_MENU;
                UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL );
            end
        end
   end    
   ShiningLootCouncil:DebugPrint("Dropdown initialized!");
end

function ShiningLootCouncil:DropClicked()
    ShiningLootCouncil:DebugPrint("DropClicked(): this.owner == " .. this.owner:GetName());
    UIDropDownMenu_SetText(this.owner, this.value);
end

function ShiningLootCouncil:AssignDEClicked(buttonFrame)
    local disenchanter = UIDropDownMenu_GetText(ShiningLootCouncil.deDropdownFrame)
    for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == disenchanter) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == SLCTable:GetItemLink(self.currentItemIndex)) then
						GiveMasterLoot(itemIndex, winningPlayerIndex)
						self:Speak("Nobody wanted " .. itemLink .. ", so " .. disenchanter .. " gets to crush its hopes and dreams.")
						return
					end
				end
				self:Print("MasterLootManger: Cannot find item - " .. SLCTable:GetItemLink(self.currentItemIndex))
			end
		end
	end
	self:Print("MasterLootManger: Cannot find player - " .. disenchanter)
end

function ShiningLootCouncil:AssignBankClicked(buttonFrame)
    local banker = UIDropDownMenu_GetText(ShiningLootCouncil.bankDropdownFrame)
    for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == banker) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == SLCTable:GetItemLink(self.currentItemIndex)) then
						GiveMasterLoot(itemIndex, winningPlayerIndex)
						self:Speak(itemLink .. " is going to " .. banker .. " to serve the greater good.")
						return
					end
				end
				self:Print("MasterLootManger: Cannot find item - " .. SLCTable:GetItemLink(self.currentItemIndex))
			end
		end
	end
	self:Print("MasterLootManger: Cannot find player - " .. disenchanter)
end

function ShiningLootCouncil:SettingsClicked(buttonFrame)
    EasyMenu(ShiningLootCouncil.settingsMenuList, ShiningLootCouncil.settingsDropDownFrame, buttonFrame:GetName(), 0, 0, "MENU")
end

function ShiningLootCouncil:InitializeSettingsMenuList()
    self.settingsMenuList = {
        {
            text = "Sort Ascending",
            func = function() ShiningLootCouncilSettings.ascending = not ShiningLootCouncilSettings.ascending end,
            checked = function() return ShiningLootCouncilSettings.ascending end,
            keepShownOnClick = 1,
        },
        {
            text = "Enforce 1 Roll",
            func = function() ShiningLootCouncilSettings.enforcelow = not ShiningLootCouncilSettings.enforcelow end,
            checked = function() return ShiningLootCouncilSettings.enforcelow end,
            keepShownOnClick = 1,
        },
        {
            text = "Enforce 100 Roll",
            func = function() ShiningLootCouncilSettings.enforcehigh = not ShiningLootCouncilSettings.enforcehigh end,
            checked = function() return ShiningLootCouncilSettings.enforcehigh end,
            keepShownOnClick = 1,
        },
        {
            text = "Ignore Fixed Rolls",
            func = function() ShiningLootCouncilSettings.ignorefixed = not ShiningLootCouncilSettings.ignorefixed end,
            checked = function() return ShiningLootCouncilSettings.ignorefixed end,
            keepShownOnClick = 1,
        },
        {
            text = "Close",
            func = function() CloseDropDownMenus() end,
            notCheckable = 1,
        },
    }
end