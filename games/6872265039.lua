Song Beats",
	    Category = "Game",
	    Icon = GetVapeAsset("catsix/assets/new/legit_songbeats.png"),
	    Function = function(Callback: boolean)
	        if Callback then
	            SongObject = Instance.new("Sound")
	            SongObject.Volume = Volume.Value / 100
	            SongObject.Parent = workspace
	            repeat
	                if not SongObject.Playing then
	                    ChooseSong()
	                end
	                if BeatTick < tick() and SongBeats.Enabled and FOV.Enabled then
	                    BeatTick = tick() + SongBPM
	                    OldFOV = math.min(Bedwars.FovController:getFOV() * (Bedwars.SprintController.sprinting and 1.1 or 1), 120)
	                    Camera.FieldOfView = OldFOV - FOVValue.Value
	                    SongTween = TweenService:Create(Camera, TweenInfo.new(math.min(SongBPM, 0.2), Enum.EasingStyle.Linear), {FieldOfView = OldFOV})
	                    SongTween:Play()
	                end
	                task.wait()
	            until not SongBeats.Enabled
	        else
	            if SongObject then
	                SongObject:Destroy()
	            end
	            if SongTween then
	                SongTween:Cancel()
	            end
	            if OldFOV then
	                Camera.FieldOfView = OldFOV
	            end
	            table.clear(AlreadyPicked)
	        end
	    end,
	    Tooltip = "Built in mp3 player"
	})
	
	List = SongBeats:CreateTextList({
	    Name = "Songs",
	    Placeholder = "filepath/bpm/start"
	})
	FOV = SongBeats:CreateToggle({
	    Name = "Beat FOV",
	    Function = function(Callback: boolean)
	        if FOVValue.Object then
	            FOVValue.Object.Visible = Callback
	        end
	        if SongBeats.Enabled then
	            SongBeats:Toggle()
	            SongBeats:Toggle()
	        end
	    end,
	    Default = true
	})
	FOVValue = SongBeats:CreateSlider({
	    Name = "Adjustment",
	    Min = 1,
	    Max = 30,
	    Default = 5,
	    Darker = true
	})
	Volume = SongBeats:CreateSlider({
	    Name = "Volume",
	    Function = function(Val: number)
	        if SongObject then
	            SongObject.Volume = Val / 100
	        end
	    end,
	    Min = 1,
	    Max = 100,
	    Default = 100,
	    Suffix = "%"
	})
end)

Run(function()
	local SoundChanger
	local List
	local SoundList: {[string]: string} = {}
	local Old: (...any) -> ...any
	
	SoundChanger = vape.Legit:CreateModule({
	    Name = "SoundChanger",
	    Category = "Game",
	    Icon = GetVapeAsset("catsix/assets/new/legit_soundchanger.png"),
	    Function = function(Callback: boolean)
	        if Callback then
	            Old = Bedwars.AudioManager.playAudio
	            Bedwars.AudioManager.playAudio = function(self, SoundId, ...)
	                if SoundList[SoundId] then
	                    SoundId = SoundList[SoundId]
	                end
	
	                return Old(self, SoundId, ...)
	            end
	        else
	            Bedwars.AudioManager.playAudio = Old
	        end
	    end,
	    Tooltip = "Change ingame sounds to custom ones."
	})
	
	List = SoundChanger:CreateTextList({
	    Name = "Sounds",
	    Placeholder = "(DAMAGE_1/ben.mp3)",
	    Function = function()
	        table.clear(SoundList)
	        for _, v: string in List.ListEnabled do
	            local Parts: {string} = v:split("/")
	            local SoundId: string? = Bedwars.SoundList[Parts[1]]
	            if SoundId and #Parts > 1 then
	                SoundList[SoundId] = Parts[2]:find("rbxasset") and Parts[2] or isfile(Parts[2]) and AssetFunction(Parts[2]) or ""
	            end
	        end
	    end
	})
end)

Run(function()
	local UICleanup
	local OpenInventory
	local KillFeed
	local OldTabList
	local HotbarApp = GetRoactRender(require(LocalPlayer.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-app"]).HotbarApp.render)
	local HotbarOpenInventory = require(LocalPlayer.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-open-inventory"]).HotbarOpenInventory
	local OldConstants, NewConstants = {}, {}
	local OldKillFeed
	
	vape:Clean(function()
	    for _, v: {[number]: any} in NewConstants do
	        table.clear(v)
	    end
	    for _, v: {[number]: any} in OldConstants do
	        table.clear(v)
	    end
	    table.clear(NewConstants)
	    table.clear(OldConstants)
	end)
	
	local function ModifyConstant(Function, Index: number, Value)
	    if not OldConstants[Function] then
	        OldConstants[Function] = {}
	    end
	    if not NewConstants[Function] then
	        NewConstants[Function] = {}
	    end
	    if not OldConstants[Function][Index] then
	        OldConstants[Function][Index] = debug.getconstant(Function, Index)
	    end
	    if typeof(OldConstants[Function][Index]) ~= typeof(Value) and Value ~= nil then
	        return
	    end
	
	    NewConstants[Function][Index] = Value
	    if UICleanup.Enabled then
	        if Value then
	            debug.setconstant(Function, Index, Value)
	        else
	            debug.setconstant(Function, Index, OldConstants[Function][Index])
	            OldConstants[Function][Index] = nil
	        end
	    end
	end
	
	UICleanup = vape.Legit:CreateModule({
	    Name = "UI Cleanup",
	    Category = "Game",
	    Icon = GetVapeAsset("catsix/assets/new/legit_uicleanup.png"),
	    Function = function(Callback: boolean)
	        for Function: (...any) -> ...any, Constants: {[number]: any} in (Callback and NewConstants or OldConstants) do
	            for i: number, Value: any in Constants do
	                debug.setconstant(Function, i, Value)
	            end
	        end
	        if Callback then
	            if OpenInventory.Enabled then
	                OldInventoryRender = HotbarOpenInventory.render
	                HotbarOpenInventory.render = function()
	                    return Bedwars.Roact.createElement("TextButton", {Visible = false}, {})
	                end
	            end
	
	            if KillFeed.Enabled then
	                OldKillFeed = Bedwars.KillFeedController.addToKillFeed
	                Bedwars.KillFeedController.addToKillFeed = function() end
	            end
	
	            if OldTabList.Enabled then
	                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	            end
	        else
	            if OldInventoryRender then
	                HotbarOpenInventory.render = OldInventoryRender
	                OldInventoryRender = nil
	            end
	
	            if KillFeed.Enabled then
	                Bedwars.KillFeedController.addToKillFeed = OldKillFeed
	                OldKillFeed = nil
	            end
	
	            if OldTabList.Enabled then
	                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	            end
	        end
	    end,
	    Tooltip = "Cleans up the UI for kits & main"
	})
	
	UICleanup:CreateToggle({
	    Name = "Resize Health",
	    Function = function(Callback: boolean)
	        ModifyConstant(HotbarApp, 60, Callback and 1 or nil)
	        ModifyConstant(debug.getupvalue(HotbarApp, 15).render, 30, Callback and 1 or nil)
	        ModifyConstant(debug.getupvalue(HotbarApp, 23).tweenPosition, 16, Callback and 0 or nil)
	    end,
	    Default = true
	})
	UICleanup:CreateToggle({
	    Name = "No Hotbar Numbers",
	    Function = function(Callback: boolean)
	        local InventoryRender = OldInventoryRender or HotbarOpenInventory.render
	        ModifyConstant(debug.getupvalue(HotbarApp, 23).render, 90, Callback and 0 or nil)
	        ModifyConstant(InventoryRender, 71, Callback and 0 or nil)
	    end,
	    Default = true
	})
	OpenInventory = UICleanup:CreateToggle({
	    Name = "No Inventory Button",
	    Function = function(Callback: boolean)
	        ModifyConstant(HotbarApp, 78, Callback and 0 or nil)
	        if UICleanup.Enabled then
	            if Callback then
	                OldInventoryRender = HotbarOpenInventory.render
	                HotbarOpenInventory.render = function()
	                    return Bedwars.Roact.createElement("TextButton", {Visible = false}, {})
	                end
	            else
	                HotbarOpenInventory.render = OldInventoryRender
	                OldInventoryRender = nil
	            end
	        end
	    end,
	    Default = true
	})
	KillFeed = UICleanup:CreateToggle({
	    Name = "No Kill Feed",
	    Function = function(Callback: boolean)
	        if UICleanup.Enabled then
	            if Callback then
	                OldKillFeed = Bedwars.KillFeedController.addToKillFeed
	                Bedwars.KillFeedController.addToKillFeed = function() end
	            else
	                Bedwars.KillFeedController.addToKillFeed = OldKillFeed
	                OldKillFeed = nil
	            end
	        end
	    end,
	    Default = true
	})
	OldTabList = UICleanup:CreateToggle({
	    Name = "Old Player List",
	    Function = function(Callback: boolean)
	        if UICleanup.Enabled then
	            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, Callback)
	        end
	    end,
	    Default = true
	})
	UICleanup:CreateToggle({
	    Name = "Fix Queue Card",
	    Function = function(Callback: boolean)
	        ModifyConstant(Bedwars.QueueCard.render, 15, Callback and 0.1 or nil)
	    end,
	    Default = true
	})
end)

Run(function()
	local Viewmodel
	local Depth
	local Horizontal
	local Vertical
	local Size
	local NoBob
	local Visuals
	local FillColor
	local OutlineColor
	local Rotations = {}
	local Highlights: {Highlight} = {}
	local Old, OldC1
	local RootJoint, RootC0, RootOffset
	local Rig: Model?
	
	local function HighlightAccessory(Accessory: Accessory)
	    local Handle: BasePart? = Accessory:FindFirstChild("Handle")
	    if Handle then
	        local Highlight: Highlight = Instance.new("Highlight")
	        Highlight.Name = "ViewmodelVisuals"
	        Highlight.FillColor = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
	        Highlight.FillTransparency = FillColor.Opacity
	        Highlight.OutlineColor = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
	        Highlight.OutlineTransparency = OutlineColor.Opacity
	        Highlight.Parent = Handle
	        Viewmodel:Clean(Highlight)
	        table.insert(Highlights, Highlight)
	    end
	end
	
	local function StartViewmodel()
	    local ViewmodelRig: Model?
	    repeat
	        ViewmodelRig = Camera:FindFirstChild("Viewmodel")
	        if ViewmodelRig or not Viewmodel.Enabled then
	            break
	        end
	        task.wait(0.1)
	    until false
	    if not ViewmodelRig or not Viewmodel.Enabled or Rig == ViewmodelRig then
	        return
	    end
	
	    Rig = ViewmodelRig
	    ViewmodelRig:ScaleTo(1)
	    OldC1 = ViewmodelRig.RightHand.RightWrist.C1
	    ViewmodelRig.RightHand.RightWrist.C1 = OldC1 * CFrame.Angles(math.rad(Rotations[1].Value), math.rad(Rotations[2].Value), math.rad(Rotations[3].Value))
	    local LowerTorso: BasePart? = ViewmodelRig:FindFirstChild("LowerTorso")
	    local Accessory: Accessory? = ViewmodelRig:FindFirstChildWhichIsA("Accessory")
	    local Reference = Accessory and Accessory:FindFirstChild("Handle") or ViewmodelRig:FindFirstChild("RightHand")
	    RootJoint = LowerTorso and LowerTorso:FindFirstChildWhichIsA("Motor6D")
	    RootC0 = RootJoint and RootJoint.C0
	    RootOffset = Reference and ViewmodelRig.HumanoidRootPart.CFrame:PointToObjectSpace(Reference.Position)
	    ViewmodelRig:ScaleTo(Size.Value)
	    if RootJoint and RootC0 and RootOffset then
	        RootJoint.C0 = (RootC0 - RootC0.Position) + (RootC0.Position * Size.Value) + (RootOffset * (1 - Size.Value))
	    end
	
	    Viewmodel:Clean(ViewmodelRig.ChildAdded:Connect(function(Child: Instance)
	        if Child:IsA("Accessory") and Size.Value ~= 1 then
	            if Store.matchState == 0 then
	                repeat
	                    task.wait()
	                until Store.matchState ~= 0
	                task.wait(0.5)
	            end
	            Bedwars.scaleTool(Child, Size.Value)
	        end
	    end))
	    Bedwars.InventoryViewmodelController:handleStore(Bedwars.Store:getState())
	end
	
	local function StartVisuals()
	    local ViewmodelRig: Model?
	    repeat
	        ViewmodelRig = Camera:FindFirstChild("Viewmodel")
	        if ViewmodelRig or not Viewmodel.Enabled then
	            break
	        end
	        task.wait(0.1)
	    until false
	    if not ViewmodelRig or not Viewmodel.Enabled then
	        return
	    end
	
	    for _, v: Instance in ViewmodelRig:GetChildren() do
	        if v:IsA("Accessory") then
	            HighlightAccessory(v)
	        end
	    end
	
	    Viewmodel:Clean(ViewmodelRig.ChildAdded:Connect(function(Child: Instance)
	        for i: number = #Highlights, 1, -1 do
	            if not Highlights[i].Parent then
	                table.remove(Highlights, i)
	            end
	        end
	        if Child:IsA("Accessory") then
	            HighlightAccessory(Child)
	        end
	    end))
	end
	
	Viewmodel = vape.Legit:CreateModule({
	    Name = "Viewmodel",
	    Category = "Game",
	    Icon = GetVapeAsset("catsix/assets/new/legit_viewmodel.png"),
	    Function = function(Callback: boolean)
	        local ViewmodelRig: Model? = Camera:FindFirstChild("Viewmodel")
	        if Callback then
	            Old = Bedwars.ViewmodelController.playAnimation
	            if NoBob.Enabled then
	                Bedwars.ViewmodelController.playAnimation = function(self, AnimationType, ...)
	                    if Bedwars.AnimationType and AnimationType == Bedwars.AnimationType.FP_WALK then
	                        return
	                    end
	                    return Old(self, AnimationType, ...)
	                end
	            end
	
	            Viewmodel:Clean(Camera.ChildAdded:Connect(function(Child: Instance)
	                if Child.Name == "Viewmodel" then
	                    StartViewmodel()
	
	                    if Visuals.Enabled then
	                        StartVisuals()
	                    end
	                end
	            end))
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -Depth.Value)
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", Horizontal.Value)
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", Vertical.Value)
	
	            StartViewmodel()
	
	            if Visuals.Enabled then
	                StartVisuals()
	            end
	        else
	            Bedwars.ViewmodelController.playAnimation = Old
	            if ViewmodelRig and OldC1 then
	                ViewmodelRig:ScaleTo(1)
	                ViewmodelRig.RightHand.RightWrist.C1 = OldC1
	
	                if RootJoint and RootC0 then
	                    RootJoint.C0 = RootC0
	                end
	            end
	
	            OldC1 = nil
	            Rig = nil
	            RootJoint = nil
	
	            Bedwars.InventoryViewmodelController:handleStore(Bedwars.Store:getState())
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", 0)
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", 0)
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", 0)
	            table.clear(Highlights)
	        end
	    end,
	    Tooltip = "Changes the viewmodel animations and visuals"
	})
	
	Depth = Viewmodel:CreateSlider({
	    Name = "Depth",
	    Min = 0,
	    Max = 2,
	    Decimal = 10,
	    Function = function(Val: number)
	        if Viewmodel.Enabled then
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -Val)
	        end
	    end,
	    Default = 0.8
	})
	Horizontal = Viewmodel:CreateSlider({
	    Name = "Horizontal",
	    Min = 0,
	    Max = 2,
	    Decimal = 10,
	    Function = function(Val: number)
	        if Viewmodel.Enabled then
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", Val)
	        end
	    end,
	    Default = 0.8
	})
	Vertical = Viewmodel:CreateSlider({
	    Name = "Vertical",
	    Min = -0.2,
	    Max = 2,
	    Decimal = 10,
	    Function = function(Val: number)
	        if Viewmodel.Enabled then
	            LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", Val)
	        end
	    end,
	    Default = -0.2
	})
	Size = Viewmodel:CreateSlider({
	    Name = "Size",
	    Min = 0.1,
	    Max = 2,
	    Decimal = 10,
	    Function = function(Val: number)
	        if Viewmodel.Enabled and Camera:FindFirstChild("Viewmodel") then
	            Camera.Viewmodel:ScaleTo(Val)
	            if RootJoint and RootC0 and RootOffset then
	                RootJoint.C0 = (RootC0 - RootC0.Position) + (RootC0.Position * Val) + (RootOffset * (1 - Val))
	            end
	        end
	    end,
	    Default = 1
	})
	for _, v: string in {"Rotation X", "Rotation Y", "Rotation Z"} do
	    table.insert(Rotations, Viewmodel:CreateSlider({
	        Name = v,
	        Min = 0,
	        Max = 360,
	        Function = function(Val: number)
	            if Viewmodel.Enabled and OldC1 and Camera:FindFirstChild("Viewmodel") then
	                Camera.Viewmodel.RightHand.RightWrist.C1 = (OldC1 + OldC1.Position * (Size.Value - 1)) * CFrame.Angles(math.rad(Rotations[1].Value), math.rad(Rotations[2].Value), math.rad(Rotations[3].Value))
	            end
	        end
	    }))
	end
	NoBob = Viewmodel:CreateToggle({
	    Name = "No Bobbing",
	    Function = function()
	        if Viewmodel.Enabled then
	            Viewmodel:Toggle()
	            Viewmodel:Toggle()
	        end
	    end,
	    Default = true
	})
	Visuals = Viewmodel:CreateToggle({
	    Name = "Visuals",
	    Function = function(Callback: boolean)
	        FillColor.Object.Visible = Callback
	        OutlineColor.Object.Visible = Callback
	        if Viewmodel.Enabled then
	            Viewmodel:Toggle()
	            Viewmodel:Toggle()
	        end
	    end,
	    Tooltip = "Highlights the item held in your viewmodel"
	})
	FillColor = Viewmodel:CreateColorSlider({
	    Name = "Fill Color",
	    DefaultSat = 0,
	    DefaultOpacity = 0.5,
	    Darker = true,
	    Visible = false,
	    Function = function(Hue: number, Sat: number, Val: number, Opacity: number)
	        for _, v: Highlight in Highlights do
	            v.FillColor = Color3.fromHSV(Hue, Sat, Val)
	            v.FillTransparency = Opacity
	        end
	    end
	})
	OutlineColor = Viewmodel:CreateColorSlider({
	    Name = "Outline Color",
	    DefaultValue = 0,
	    DefaultOpacity = 0,
	    Darker = true,
	    Visible = false,
	    Function = function(Hue: number, Sat: number, Val: number, Opacity: number)
	        for _, v: Highlight in Highlights do
	            v.OutlineColor = Color3.fromHSV(Hue, Sat, Val)
	            v.OutlineTransparency = Opacity
	        end
	    end
	})
end)
