local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local NotificationFrame = PlayerGui:WaitForChild("CoreHUD"):WaitForChild("Left")

local InterfaceTweens = require(ReplicatedStorage.Shared.configs.InterfaceTweens)
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local NotificationController = Knit.CreateController({
	Name = "NotificationController",
})

function NotificationController:CreateIndicator(infodetails)
	local function KickHit(Template)
		local UIScale = Instance.new("UIScale")
		local success, LocalPlayersData = self.PlayerController:GetPlayerData():await()
		if not success then
			warn("Data yok NotificationIcin")
			return
		end
		UIScale.Scale = 0
		UIScale.Parent = Template.Parent
		Template.Parent.AnchorPoint = Vector2.new(0.5, 0.5)

		local comingPlayer = infodetails.HittedPlayer or nil
		local destroyingChar = Template.ViewportFrame.WorldModel.TemplateChar
		local Animation = Instance.new("Animation")
		Animation.AnimationId = "http://www.roblox.com/asset/?id=180435571"

		if destroyingChar then
			local clone = ReplicatedStorage.Shared.Assets.Models
				:FindFirstChild("CharacterClones")
				:FindFirstChild(comingPlayer.Name)
				:Clone()
			for _, allparts in clone:GetDescendants() do
				if
					allparts:IsA("Script")
					or allparts:IsA("ModuleScript")
					or allparts:IsA("LocalScript")
					or allparts:IsA("BillboardGui")
					or allparts:IsA("VectorForce")
				then
					allparts:Destroy()
				end
			end

			clone.Humanoid.PlatformStand = true
			clone.PrimaryPart = clone.Head
			clone:PivotTo(destroyingChar:GetPivot())
			destroyingChar:Destroy()
			clone.Parent = Template.ViewportFrame.WorldModel
		end
		local KickSymbol = KickStyleDatas.Kicks[LocalPlayersData.KickStyle].Cosmetic.Image or nil
		if KickSymbol then
			Template.Icon.Image = KickSymbol
		end
		Template.HP.Text = "-" .. tostring(infodetails.GivingDamage)
		Template.SP.Text = "+" .. tostring(infodetails.ComingStamina)
		if infodetails.ComingCoin then
			Template.Coins.Text = "+" .. tostring(infodetails.ComingCoin)
		else
			Template.Coins.Visible = false
		end

		local SizeUp, SizeNormal, RotateUp, RotateDown =
			InterfaceTweens:HitNotificationAppear(Template.Parent, { Scale = 1.15 })
		SizeUp:Play()
		RotateUp:Play()
		RotateUp.Completed:Connect(function()
			RotateDown:Play()
			RotateUp:Destroy()
		end)
		SizeUp.Completed:Connect(function()
			SizeNormal:Play()
			SizeUp:Destroy()
		end)
		SizeNormal.Completed:Connect(function()
			SizeNormal:Destroy()
			task.delay(math.random(5, 7), function()
				local diseapperTransparency, Shrink = InterfaceTweens:HitNotificationDisAppear(Template.Parent, {})
				diseapperTransparency:Play()
				Shrink:Play()
				Shrink.Completed:Connect(function()
					diseapperTransparency:Destroy()
					Template.Parent:Destroy()
					Shrink:Destroy()
				end)
			end)
		end)
		RotateDown.Completed:Connect(function()
			RotateDown:Destroy()
		end)
	end

	local function AuraHit(Template) end

	local function Knockout(Template)
		local UIScale = Instance.new("UIScale")
		UIScale.Scale = 0
		UIScale.Parent = Template.Parent
		Template.Parent.AnchorPoint = Vector2.new(0.5, 0.5)

		local comingPlayer = infodetails.KnockedPlayer or nil

		local destroyingChar = Template.ViewportFrame.WorldModel.TemplateChar
		if destroyingChar then
			local clone = ReplicatedStorage.Shared.Assets.Models
				:FindFirstChild("CharacterClones")
				:FindFirstChild(comingPlayer.Name)
				:Clone()
			for _, allparts in clone:GetDescendants() do
				if
					allparts:IsA("Script")
					or allparts:IsA("ModuleScript")
					or allparts:IsA("LocalScript")
					or allparts:IsA("BillboardGui")
				then
					allparts:Destroy()
				end
			end
			clone.Humanoid.PlatformStand = true
			clone:PivotTo(destroyingChar:GetPivot())
			destroyingChar:Destroy()
			clone.Parent = Template.ViewportFrame.WorldModel
		end
		Template.Playername.Text = infodetails.HittingPlayer.Name
		Template.Coins.Text = string.upper("+" .. tostring(infodetails.ComingCoin))
		local SizeUp, SizeNormal, RotateUp, RotateDown =
			InterfaceTweens:HitNotificationAppear(Template.Parent, { Scale = 1.15 })
		SizeUp:Play()
		RotateUp:Play()
		RotateUp.Completed:Connect(function()
			RotateDown:Play()
			RotateUp:Destroy()
		end)
		SizeUp.Completed:Connect(function()
			SizeNormal:Play()
			SizeUp:Destroy()
		end)
		SizeNormal.Completed:Connect(function()
			SizeNormal:Destroy()
			task.delay(math.random(3, 5), function()
				local diseapperTransparency, Shrink = InterfaceTweens:HitNotificationDisAppear(Template.Parent, {})
				diseapperTransparency:Play()
				Shrink:Play()
				Shrink.Completed:Connect(function()
					diseapperTransparency:Destroy()
					Template.Parent:Destroy()
					Shrink:Destroy()
				end)
			end)
		end)
		RotateDown.Completed:Connect(function()
			RotateDown:Destroy()
		end)
	end

	local function Wipeout(Template)
		local UIScale = Instance.new("UIScale")
		UIScale.Scale = 0
		UIScale.Parent = Template.Parent
		Template.Parent.AnchorPoint = Vector2.new(0.5, 0.5)

		local comingPlayer = infodetails.HittingPlayer or nil

		local destroyingChar = Template.ViewportFrame.WorldModel.TemplateChar
		if destroyingChar then
			local clone = ReplicatedStorage.Shared.Assets.Models
				:FindFirstChild("CharacterClones")
				:FindFirstChild(comingPlayer.Name)
				:Clone()
			for _, allparts in clone:GetDescendants() do
				if
					allparts:IsA("Script")
					or allparts:IsA("ModuleScript")
					or allparts:IsA("LocalScript")
					or allparts:IsA("BillboardGui")
				then
					allparts:Destroy()
				end
			end
			clone.Humanoid.PlatformStand = true
			clone:PivotTo(destroyingChar:GetPivot())
			destroyingChar:Destroy()
			clone.Parent = Template.ViewportFrame.WorldModel
		end
		Template.HP.Text = tostring(infodetails.LosingHealth)
		Template.Playername.Text = infodetails.HittingPlayer.Name
		local SizeUp, SizeNormal, RotateUp, RotateDown =
			InterfaceTweens:HitNotificationAppear(Template.Parent, { Scale = 1.15 })
		SizeUp:Play()
		RotateUp:Play()
		RotateUp.Completed:Connect(function()
			RotateDown:Play()
			RotateUp:Destroy()
		end)
		SizeUp.Completed:Connect(function()
			SizeNormal:Play()
			SizeUp:Destroy()
		end)
		SizeNormal.Completed:Connect(function()
			SizeNormal:Destroy()
			task.delay(math.random(3, 5), function()
				local diseapperTransparency, Shrink = InterfaceTweens:HitNotificationDisAppear(Template.Parent, {})
				diseapperTransparency:Play()
				Shrink:Play()
				Shrink.Completed:Connect(function()
					diseapperTransparency:Destroy()
					Template.Parent:Destroy()
					Shrink:Destroy()
				end)
			end)
		end)
		RotateDown.Completed:Connect(function()
			RotateDown:Destroy()
		end)
	end

	local function HitTaken(Template)
		local UIScale = Instance.new("UIScale")
		UIScale.Scale = 0
		UIScale.Parent = Template.Parent
		Template.Parent.AnchorPoint = Vector2.new(0.5, 0.5)

		local comingPlayer = infodetails.HittingPlayer or nil

		local destroyingChar = Template.ViewportFrame.WorldModel.TemplateChar
		if destroyingChar then
			local clone = ReplicatedStorage.Shared.Assets.Models
				:FindFirstChild("CharacterClones")
				:FindFirstChild(comingPlayer.Name)
				:Clone()
			for _, allparts in clone:GetDescendants() do
				if
					allparts:IsA("Script")
					or allparts:IsA("ModuleScript")
					or allparts:IsA("LocalScript")
					or allparts:IsA("BillboardGui")
				then
					allparts:Destroy()
				end
			end
			clone.Humanoid.PlatformStand = true
			clone:PivotTo(destroyingChar:GetPivot())
			destroyingChar:Destroy()
			clone.Parent = Template.ViewportFrame.WorldModel
		end
		local KickSymbol = KickStyleDatas.Kicks[infodetails.HittingPlayerData.KickStyle].Cosmetic.Image or nil
		if KickSymbol then
			Template.Reason.Image = KickSymbol
		end
		Template.HP.Text = tostring(infodetails.LosingDamage)
		Template.SP.Text = "-" .. tostring(infodetails.LosingStamina)
		local SizeUp, SizeNormal, RotateUp, RotateDown =
			InterfaceTweens:HitNotificationAppear(Template.Parent, { Scale = 1.15 })
		SizeUp:Play()
		RotateUp:Play()
		RotateUp.Completed:Connect(function()
			RotateDown:Play()
			RotateUp:Destroy()
		end)
		SizeUp.Completed:Connect(function()
			SizeNormal:Play()
			SizeUp:Destroy()
		end)
		SizeNormal.Completed:Connect(function()
			SizeNormal:Destroy()
			task.delay(math.random(3, 5), function()
				local diseapperTransparency, Shrink = InterfaceTweens:HitNotificationDisAppear(Template.Parent, {})
				diseapperTransparency:Play()
				Shrink:Play()
				Shrink.Completed:Connect(function()
					diseapperTransparency:Destroy()
					Template.Parent:Destroy()
					Shrink:Destroy()
				end)
			end)
		end)
		RotateDown.Completed:Connect(function()
			RotateDown:Destroy()
		end)
	end

	local KickTemplate = if infodetails.IndicatorType == "KickHit" or infodetails.IndicatorType == "AuraHit"
		then NotificationFrame.NotificationTemplates.KickHit:Clone()
		elseif infodetails.IndicatorType == "Knockout" then NotificationFrame.NotificationTemplates.Knockout:Clone()
		elseif infodetails.IndicatorType == "Wipeout" then NotificationFrame.NotificationTemplates.Wipeout:Clone()
		elseif
			infodetails.IndicatorType == "HitTaken"
		then NotificationFrame.NotificationTemplates.HitTaken:Clone() --Vurulan kisiye gidiyo
		else nil
	if not KickTemplate then
		warn("Kick Template Data didnt find")
		return
	end

	KickTemplate.Parent = NotificationFrame.NotificationConteyner
	KickTemplate.Visible = true
	KickTemplate.LayoutOrder = #NotificationFrame.NotificationConteyner:GetChildren()
	if infodetails.IndicatorType == "KickHit" then
		KickHit(KickTemplate:FindFirstChild(KickTemplate.Name))
	elseif infodetails.IndicatorType == "AuraHit" then
		AuraHit(KickTemplate:FindFirstChild(KickTemplate.Name))
	elseif infodetails.IndicatorType == "Knockout" then
		Knockout(KickTemplate:FindFirstChild(KickTemplate.Name))
	elseif infodetails.IndicatorType == "Wipeout" then
		Wipeout(KickTemplate:FindFirstChild(KickTemplate.Name))
	elseif infodetails.IndicatorType == "HitTaken" then
		HitTaken(KickTemplate:FindFirstChild(KickTemplate.Name)) --Vurulan kisiye gidiyo
	end
end

function NotificationController:KnitInit()
	self.NotificationService = Knit.GetService("NotificationService")
	self.PlayerController = Knit.GetController("PlayerController")
end

function NotificationController:KnitStart()
	self.NotificationService.CreateIndicator:Connect(function(infodetails)
		self:CreateIndicator(infodetails)
	end)
end

return NotificationController
