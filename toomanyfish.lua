-- ------------------------- Core ------------------------

-- I made this so I could run "Fishing Guide" non-stop.
-- That addon stops itself whenever your inventory gets full,
-- so this was my answer to that.

TooManyFish = {}
local self = TooManyFish

-- ------------------------- Info ------------------------

self.Info = {
    Author      = "Mash#3428",
    AddonName   = "TooManyFish",
    ClassName   = "TooManyFish",
	Version     = 105,
	StartDate   = "18-05-2021",
	LastUpdate  = "11-12-2021",
    Description = "Deletes seafood when inventory is full.",
	ChangeLog = {
        [1] = "0.0.1 - Starting development.",
        [100] = "1.0.0 - First release.",
        [101] = "1.0.1 - Bugfix, blacklist area.",
        [102] = "1.0.2 - Adding the option to blacklist aquarium fish.",
        [103] = "1.0.3 - Discarding untradable items is now supported.",
        [104] = "1.0.4 - Auto discard fishes after ocean fishing expeditions.",
        [105] = "1.0.5 - Fishes on the spot.",
	}
}

-- ------------------------- Paths ------------------------

local LuaPath           = GetLuaModsPath()
self.MinionSettings     = LuaPath                   .. [[ffxivminion\]]
self.ModulePath         = LuaPath                   .. self.Info.ClassName  .. [[\]]
self.ModuleSettingPath  = self.MinionSettings       .. self.Info.ClassName  .. [[\]]
self.SettingsPath       = self.ModulePath           .. [[settings.lua]]
self.IRTPath            = self.ModulePath           .. [[irt.lua]]

-- ------------------------- Settings ------------------------

self.DefaultSettings = {
    EnableTooManyFish           = false,
    AutoDiscardAfterExpedition  = true,
    BlacklistAquarium           = false,
    AddonVersion                = self.Info.Version,
    FishBlacklist               = [[30487]]
}

if FileExists(self.SettingsPath) then
    local CheckBeforeDelete = FileLoad(self.SettingsPath)

    -- Add new BlacklistAquarium settings for settings versions < 1.0.2
    if not CheckBeforeDelete.AddonVersion and CheckBeforeDelete.AddonVersion < 102 then
        CheckBeforeDelete.AddonVersion      = 102
        CheckBeforeDelete.BlacklistAquarium = false
        FileSave(self.SettingsPath, self.DefaultSettings)
    end

    -- Add new AutoDiscardAfterExpedition settings for settings versions < 1.0.4
    if not CheckBeforeDelete.AddonVersion and CheckBeforeDelete.AddonVersion < 104 then
        CheckBeforeDelete.AddonVersion                  = 104
        CheckBeforeDelete.AutoDiscardAfterExpedition    = true
        FileSave(self.SettingsPath, CheckBeforeDelete)
    end
    
    self.Settings = FileLoad(self.SettingsPath)
else
    FileSave(self.SettingsPath, self.DefaultSettings)
    self.Settings = FileLoad(self.SettingsPath)
end

-- ------------------------- Modules ------------------------

self.Style          = { MainWindow = {} }
self.Helpers        = {}
self.Misc           = {}
self.SaveLastCheck  = Now()

-- ------------------------- States ------------------------

self.ManualStart    = false
self.OnFishExpedit  = false
self.Wait           = false
self.Timer          = 0
self.FinishItem     = false
self.StartDelete    = false
self.ItemList       = {}
self.RunningFishOnSpot = false
self.PreparingFishCast = {
    Cordial = false,
    Prize = false,
    Thaliak = false,
    Cast = false
}
self.FishCastTimer = Now()

-- ------------------------- GUI ------------------------

self.GUI = {
    name        = self.Info.AddonName,
    NavName     = self.Info.AddonName,
    open        = false,
    visible     = true,
    OnClick     = loadstring(self.Info.ClassName .. [[.GUI.open = not ]] .. self.Info.ClassName .. [[.GUI.open]]),
    IsOpen      = loadstring([[return ]] .. self.Info.ClassName .. [[.GUI.open]]),
    ToolTip     = self.Info.Description
}

-- ------------------------- Style ------------------------

self.Style.MainWindow = {
    Title       = self.Info.AddonName,
    Position    = { X = 40, Y = 175 },
    Size        = { Width = 300, Height = 250 },
    Components  = { MainTabs = GUI_CreateTabs([[Home,Fish,Blacklist,About]]) }
}

-- ------------------------- Aquarium Fish ------------------------

self.AquariumFish = {
    4948,
    4876,
    4886,
    4979,
    4959,
    4951,
    12721,
    8776,
    4918,
    4903,
    4917,
    7941,
    12803,
    4926,
    4874,
    7940,
    7902,
    4883,
    5000,
    12749,
    4908,
    4922,
    8774,
    12739,
    20048,
    5011,
    7699,
    4973,
    4898,
    4905,
    7924,
    4924,
    20018,
    4970,
    4879,
    12743,
    5023,
    20052,
    20220,
    20221,
    5025,
    20054,
    4923,
    20021,
    20162,
    5007,
    20051,
    20053,
    20145,
    20186,
    20228,
    20171,
    20211,
    21178,
    20038,
    20100,
    20183,
    20193,
    21177,
    4893,
    7943,
    23054,
    8762,
    17590,
    4986,
    12750,
    12768,
    12764,
    12741,
    20185,
    20204,
    21176,
    12752,
    21175,
    7685,
    7709,
    5013,
    20020,
    20090,
    20180,
    20157,
    20184,
    7690,
    12742,
    4999,
    12781,
    4987,
    20229,
    7693,
    4895,
    20192,
    20226,
    17579,
    27423,
    27481,
    22397,
    22398,
    23059,
    27415,
    27531,
    22389,
    24994,
    27503,
    20233,
    27543,
    20110,
    27454,
    27474,
    27490,
    27559,
    27534,
    27437,
    27424,
    24995,
    27494,
    27430,
    27536,
    27530,
    29785,
    27560,
    29787,
    24990,
    29790,
    24203,
    24204,
    20218,
    27546,
    27557,
    29719,
    27436,
    27579,
    12830,
    29784,
    28065,
    32052,
    32063,
    27566,
    27563,
    27525,
    27486,
    28940,
    30434,
    29782
}

-- ------------------------- Log ------------------------

function TooManyFish.Log(log)
    local content = "==== [" .. self.Info.AddonName .. "] " .. tostring(log)
    d(content)
end

-- ------------------------- Save ------------------------

function TooManyFish.Save(force)
    if FileExists(self.SettingsPath) then
        if (force or TimeSince(self.SaveLastCheck) > 500) then
            self.SaveLastCheck = Now()
            FileSave(self.SettingsPath, self.Settings)
        end
    end
end

-- ------------------------- Init ------------------------

function TooManyFish.Init()
    self.Log([[Addon started]])

    local ModuleTable = self.GUI
    ml_gui.ui_mgr:AddMember({
        id = self.Info.ClassName,
        name = self.Info.AddonName,
        onClick = function() ModuleTable.OnClick() end,
        tooltip = ModuleTable.ToolTip,
        texture = ""
    }, "FFXIVMINION##MENU_HEADER")
end

function TooManyFish.SplitString(inputstr, sep)
    local sep = sep or [[%s]]
    local t = {}

    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end

    return t
end

-- ------------------------- GetFreeInvSlots ------------------------

function TooManyFish.GetFreeInvSlots()
    local Inventories   = { 0, 1, 2, 3 }
    local freeslots     = 0
    
    for i = 0, 3, 1 do
        freeslots = freeslots + Inventory:Get(i).free
    end

    return freeslots
end

-- ------------------------- GetListToDelete ------------------------

function TooManyFish.GetListToDelete()
    if table.size(self.ItemList) == 0 then
        local Blacklist = TooManyFish.SplitString(self.Settings.FishBlacklist, ",")

        if self.Settings.BlacklistAquarium then
            Blacklist = table.merge(Blacklist, self.AquariumFish, true)
        end
        
        for i = 0, 3, 1 do
            local Items = Inventory:Get(i):GetList()
    
            for k, v in pairs(Items) do
                if v.uicategory == 47 and not table.contains(Blacklist, tostring(v.id)) then
                    self.ItemList[#self.ItemList+1] = v
                end
            end
        end
    end
    
    self.StartDelete = true
end

-- ------------------------- ExecuteOrder66 ------------------------

function TooManyFish.ExecuteOrder66()
    if Inventory:Get(self.ItemList[1].type):Get(self.ItemList[1].id).type == self.ItemList[1].type then
        if IsControlOpen("SelectYesno") then
            local Prompt = GetControl("SelectYesno")
            Prompt:Action("CheckAccept")
            Prompt:Action("Yes")
            self.Wait           = false
            self.FinishItem     = true
            table.remove(self.ItemList, 1)
        else
            self.ItemList[1]:Discard()
        end
    else
        self.Wait           = false
        self.FinishItem     = true
        table.remove(self.ItemList, 1)
    end
end

-- ------------------------- Update ------------------------

function TooManyFish.Update()
    TooManyFish.Save(false)

-- ------------------------- StartFishingAtSpot ------------------------

    if self.RunningFishOnSpot then
        if MashLib and MashLib.System.GetJob(Player.Job) == [[Fisher]] then
            self.StartFishingAtSpot()
        else
            self.RunningFishOnSpot = false
        end
    end
    
-- ------------------------- When to Start ------------------------

    if self.Settings.EnableTooManyFish then

        if TooManyFish.GetFreeInvSlots() < 5 and not FFXIV_Common_BotRunning and gBotMode == "Fishing Guide" then
            self.ManualStart = true
        end

-- ------------------------- AutoDiscardAfterExpedition ------------------------

        if self.Settings.AutoDiscardAfterExpedition then 
            if Player.localmapid == 900 and not self.OnFishExpedit then
                self.OnFishExpedit = true
            end

            if self.OnFishExpedit and Player.localmapid ~= 900 then
                TooManyFish.Log([[Auto start after ocean fishing]])

                self.OnFishExpedit = false

                if FFXIV_Common_BotRunning then
                    ml_global_information.ToggleRun()
                end

                self.ManualStart = true
            end
        end

-- ------------------------- ManualStart ------------------------

        if self.ManualStart then
            self.ItemList = { }
            TooManyFish.GetListToDelete()
        end

-- ------------------------- Start ------------------------

        if TooManyFish.StartDelete then
            
-- ------------------------- If nothing to delete, start bot ------------------------

            if table.size(self.ItemList) == 0 then
                self.ManualStart    = false
                self.Wait           = false
                self.Timer          = 0
                self.FinishItem     = false
                self.StartDelete    = false
                self.ItemList       = {}

                if not FFXIV_Common_BotRunning and gBotMode == "Fishing Guide" and TooManyFish.GetFreeInvSlots() > 10 then
                    ml_global_information.ToggleRun()
                end
            else

-- ------------------------- if there's something to delete ------------------------

                -- There probably is a way less jank way to do this :B
                if self.FinishItem then
                    self.Wait       = false
                    self.FinishItem = false
                    self.Timer      = 0
                end

                if table.valid(self.ItemList) then
                    if not self.Wait then
                        self.Wait = true
                        self.Timer = Now()
                    end

                    if TimeSince(self.Timer) > 2000 then
                        if self.ItemList[1] then
                            TooManyFish.ExecuteOrder66()
                        end
                    end
                end
            end
        end
    end
end

-- Fish Here

function self.StartFishingAtSpot()
    if Player:GetFishingState() == 6 then
        self.FishCastTimer = Now()
    end

    if Player:GetFishingState() ~= 9 and Player:GetFishingState() ~= 5 then
        if Player:GetFishingState() == 4 or Player:GetFishingState() == 0 then
            if not self.PreparingFishCast.Cordial and Player.GP.current < 200 and MashLib.Helpers.TimeSince(self.FishCastTimer) > 1000 then
                local GetCordials = MashLib.Helpers.First(MashLib.Character.Inventory.GetById(12669))

                if GetCordials then
                    if GetCordials:Cast() then
                        GetCordials:Cast()
                        d("== [MashFish] - Using Hi-Cordial.")
                    end
                end

                self.PreparingFishCast.Cordial = true
                self.FishCastTimer = Now()
            elseif not self.PreparingFishCast.Thaliak and MashLib.Helpers.TimeSince(self.FishCastTimer) > 1000 then
                if MashLib.System.SearchActionById(1, 26804):IsReady() then
                    MashLib.System.SearchActionById(1, 26804):Cast()
                end
                d("== [MashFish] - Casting Thaliak's Favor.")

                self.PreparingFishCast.Thaliak = true
                self.FishCastTimer = Now()
            elseif not self.PreparingFishCast.Prize and MashLib.Helpers.TimeSince(self.FishCastTimer) > 1000 then
                if MashLib.System.SearchActionById(1, 26806):IsReady() then
                    MashLib.System.SearchActionById(1, 26806):Cast()
                end
                d("== [MashFish] - Casting Prize Catch.")

                self.PreparingFishCast.Prize = true
                self.FishCastTimer = Now()
            end

            if self.PreparingFishCast.Prize and self.PreparingFishCast.Thaliak and MashLib.Helpers.TimeSince(self.FishCastTimer) > 1000 then
                if MashLib.System.SearchActionById(1, 289):IsReady() then
                    MashLib.System.SearchActionById(1, 289):Cast()
                end
                d("== [MashFish] - Casting Cast.")

                self.PreparingFishCast.Cast = true
                self.FishCastTimer = Now()
            end
        end
    else
        if Player:GetFishingState() == 5 then
            if MashLib.System.SearchActionById(1, 296):IsReady() then
                MashLib.System.SearchActionById(1, 296):Cast()
            end
            d("== [MashFish] - Casting Hook.")
        end

        self.PreparingFishCast = {
            Cordial = false,
            Prize = false,
            Thaliak = false,
            Cast = false
        }
    end
end

-- ------------------------- Main Window ------------------------

function TooManyFish.MainWindow(event, tickcount)
    if self.GUI.open then
        local flags = (GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoResize)
        GUI:SetNextWindowSize(self.Style.MainWindow.Size.Width, self.Style.MainWindow.Size.Height, GUI.SetCond_Always)
        self.GUI.visible, self.GUI.open = GUI:Begin(tostring(self.Style.MainWindow.Title), self.GUI.open, flags)

            local TabIndex, TabName = GUI_DrawTabs(self.Style.MainWindow.Components.MainTabs)
            
            if TabIndex == 1 then   
                
-- ------------------------- Enable Addon ------------------------

                self.Settings.EnableTooManyFish = GUI:Checkbox("Enable TooManyFish##EnableAddonBehavior", self.Settings.EnableTooManyFish)

                if self.Settings.EnableTooManyFish then
                    self.Settings.AutoDiscardAfterExpedition = GUI:Checkbox("Auto start after ocean fishing##AutoDiscardAfterExpedition", self.Settings.AutoDiscardAfterExpedition)
                end

                GUI:NewLine()

-- ------------------------- Enabled Behavior ------------------------

                if self.Settings.EnableTooManyFish then
                    local BtnText = self.ManualStart and "Stop" or "Start Discard Manually"
                    local DebugButton = GUI:Button(BtnText .. "##DebugBtn", 283, 30)

                    if GUI:IsItemClicked(DebugButton) then
                        if self.ManualStart then
                            self.ManualStart    = false
                            self.Wait           = false
                            self.Timer          = 0
                            self.FinishItem     = false
                            self.StartDelete    = false
                            self.ItemList       = {}
                        else
                            self.ManualStart = true
                        end
                    end

-- ------------------------- Debug ------------------------

                    -- GUI:NewLine()
                    -- GUI:NewLine()

                    -- GUI:Text([[Wait: ]]         .. tostring(self.Wait))
                    -- GUI:Text([[Timer: ]]        .. tostring(TimeSince(self.Timer)))
                    -- GUI:Text([[StartDelete: ]]  .. tostring(self.StartDelete))
                    -- GUI:Text([[ManualStart: ]]  .. tostring(self.ManualStart))
                    -- GUI:Text([[ItemList: ]]     .. tostring(table.size(self.ItemList)))
                end
            end

            if TabIndex == 2 then
                GUI:TextWrapped([[Simple script to fish at the spot you're in, it doesn't change jobs nor takes your character somewhere, just fish.]])
                GUI:TextWrapped([[It does use certain actions though, so you can level up faster, like cordials, Thaliak's Favor and Prize Catch.]])
                GUI:TextWrapped([[If you go to Old Sharlayan ( 13 , 13 ) or nearby, you can get your Fisher from 80 to 90 in 2 hours or so.]])
                GUI:NewLine()

                local FishOnSpotHoldEnabled = self.RunningFishOnSpot and [[Stop fishing]] or [[Start fishing]]
                local FishOnSpotToggle = GUI:Button(FishOnSpotHoldEnabled .. "##FishOnSpotBtn", 283, 30)

                if GUI:IsItemClicked(FishOnSpotToggle) then
                    if self.RunningFishOnSpot then
                        self.PreparingFishCast = {
                            Cordial = false,
                            Prize = false,
                            Thaliak = false,
                            Cast = false
                        }
                    else
                        self.FishCastTimer = Now()
                    end

                    self.RunningFishOnSpot = not self.RunningFishOnSpot
                end

                if GUI:IsItemHovered(FishOnSpotToggle) then
                    GUI:BeginTooltip()
                        GUI:Text([[Change your job to Fisher and go near a body of water.]])
                        GUI:Text([[This routine requires MashLib to work, free in the store.]])
                    GUI:EndTooltip()
                end

                GUI:NewLine()
            end
            
-- ------------------------- Blacklist ------------------------

            if TabIndex == 3 then
                GUI:Text(GetString([[Fish Blacklist]]))
                GUI:Separator()
                GUI:NewLine()

                self.Settings.BlacklistAquarium = GUI:Checkbox("Blacklist Aquarium Fish##BlacklistAquariumFish", self.Settings.BlacklistAquarium)

                GUI:NewLine()
                
                self.Settings.FishBlacklist = GUI:InputTextMultiline([[##FishBlacklistArea]], self.Settings.FishBlacklist, 283, 80)
                
                if GUI:IsItemHovered() then
                    GUI:BeginTooltip()
                        GUI:Text([[Fish ID, separated by comma, no space]])
                    GUI:EndTooltip()
                end
            end
            
-- ------------------------- About ------------------------

            if TabIndex == 4 then
                GUI:Text(GetString([[About TooManyFish]]))
                GUI:Separator()
                GUI:NewLine()

                GUI:Indent()
                    GUI:Text([[Author: ]].. self.Info.Author)
                    GUI:Text([[Version: ]].. self.Info.AddonName .. [[ v]] .. self.Info.Version)
                    GUI:Text([[Last Update: ]].. self.Info.LastUpdate)
                    GUI:NewLine()
                GUI:Unindent()
            end

        GUI:End()
    end
end

-- ------------------------- RegisterEventHandler ------------------------

RegisterEventHandler([[Module.Initalize]], TooManyFish.Init, [[TooManyFish.Init]])
RegisterEventHandler([[Gameloop.Update]], TooManyFish.Update, [[TooManyFish.Update]])
RegisterEventHandler([[Gameloop.Draw]], TooManyFish.MainWindow, [[TooManyFish.MainWindow]])