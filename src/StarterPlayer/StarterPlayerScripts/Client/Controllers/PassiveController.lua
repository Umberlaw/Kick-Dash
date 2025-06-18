local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
local InterFaceTweens = require(ReplicatedStorage.Shared.configs.InterfaceTweens)

local LocalPlayer = Players.LocalPlayer

local PassiveController = Knit.CreateController({
	Name = "PassiveController",
	MainHud = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("CoreHUD"),
})

function PassiveController:SetPassiveIndicators(PassiveType, Count)
	local passiveIndicatorArea = self.MainHud
		:FindFirstChild("Bottom")
		:FindFirstChild("PassiveRelatives")
		:FindFirstChild(PassiveType .. "PassiveBar")
		:FindFirstChild("Points") or nil
	if passiveIndicatorArea and Count > 0 then
		self.SoundController:PlaySoundOnlyClient({ SoundName = PassiveType .. "PassivePoint" })
		for i = 1, Count do
			local targetIndicator = passiveIndicatorArea:FindFirstChild("Point_" .. tostring(i)) or nil
			if targetIndicator then
				local targetPont = targetIndicator:FindFirstChild("PassivePoint_" .. PassiveType)
				local IconGroup = passiveIndicatorArea.Parent:FindFirstChild("IconGroup")

				if targetPont then
					targetPont.Visible = true
					local originalSize = targetIndicator.Size
					local originalPos = targetIndicator.Position
					local PopSize = UDim2.new(
						originalSize.X.Scale * 1.2,
						originalSize.X.Offset,
						originalSize.Y.Scale * 1.2,
						originalSize.Y.Offset
					)
					local PopPosition = UDim2.new(
						originalPos.X.Scale,
						originalPos.X.Offset - 1.5,
						originalPos.Y.Scale,
						originalPos.Y.Offset - 2
					)
					local PopUpAnim =
						InterFaceTweens:PassivePopUp(targetIndicator, { Size = PopSize, Position = PopPosition })
					local PopUpScaleUpAnim = InterFaceTweens:PassivePopUpScaleUp(targetIndicator.UIScale)
					local PopNormalAnim = InterFaceTweens:PassivePopNormal(
						targetIndicator,
						{ Size = originalSize, Position = originalPos }
					)
					local PopUpScaleNormalAnim = InterFaceTweens:PassivePopUpScaleNormal(targetIndicator.UIScale)
					local PassivePointVisible = InterFaceTweens:ShowPassiveBubble(targetPont, { ImageTransparency = 0 })

					if IconGroup then
						local IconGroupNormalSize = IconGroup.Size
						local IconGroupPosition = IconGroup.Position
						local popSize = UDim2.new(
							IconGroupNormalSize.X.Scale * 1.2,
							IconGroupNormalSize.X.Offset,
							IconGroupNormalSize.Y.Scale * 1.2,
							IconGroupNormalSize.Y.Offset
						)
						local popPosition = UDim2.new(
							IconGroupPosition.X.Scale,
							IconGroupPosition.X.Offset + 1.25,
							IconGroupPosition.Y.Scale,
							IconGroupPosition.Y.Offset - 6.5
						)
						local targetTransparency = 0.9 - (Count * 0.3)
						local IconTrasnparencyTween =
							InterFaceTweens:IconTransparency(IconGroup, { Transparency = targetTransparency })

						local IconPopUp =
							InterFaceTweens:PassivePopUp(IconGroup, { Size = popSize, Position = popPosition })
						local IconNormal = InterFaceTweens:PassivePopNormal(
							IconGroup,
							{ Size = IconGroupNormalSize, Position = IconGroupPosition }
						)

						IconPopUp:Play()

						IconPopUp.Completed:Connect(function()
							IconNormal:Play()
							IconPopUp:Destroy()
						end)
						IconNormal.Completed:Connect(function()
							IconNormal:Destroy()
						end)
						IconTrasnparencyTween:Play()
					end
					PopUpAnim:Play()
					PopUpScaleUpAnim:Play()

					PassivePointVisible:Play()
					PopUpAnim.Completed:Connect(function()
						PopNormalAnim:Play()
						PopUpScaleNormalAnim:Play()
						PopUpAnim:Destroy()
						PopUpScaleUpAnim:Destroy()
					end)
					PopNormalAnim.Completed:Connect(function()
						PopNormalAnim:Destroy()
						PopUpScaleNormalAnim:Destroy()
					end)
				end
			end
		end
	elseif passiveIndicatorArea and Count <= 0 then
		for _, allPassivePoints in passiveIndicatorArea:GetChildren() do
			allPassivePoints:FindFirstChild("PassivePoint_" .. PassiveType).Visible = false
			passiveIndicatorArea.Parent:FindFirstChild("IconGroup").GroupTransparency = 0.9
			allPassivePoints:FindFirstChild("PassivePoint_" .. PassiveType).ImageTransparency = 1
		end
	end
end

function PassiveController:KnitInit()
	self.PassiveService = Knit.GetService("PassiveService")
	self.SoundController = Knit.GetController("SoundController")
end

function PassiveController:KnitStart()
	self.PassiveService.PassiveActivate:Connect(function(PassiveType, Count)
		self:SetPassiveIndicators(PassiveType, Count)
	end)
end

return PassiveController
