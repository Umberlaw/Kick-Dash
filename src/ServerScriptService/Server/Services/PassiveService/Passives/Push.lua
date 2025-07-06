local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Push = {}
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

Push.Services = {}

function Push:StartRelease(player)
	print(player.Name, "ReleasedThe Mouse")
end

function Push:Start(player, otherdatas)
	self.Services["PlayerService"] = self.Services["PlayerService"] or Knit.GetService("PlayerService")
	self.Services["StatusService"] = self.Services["StatusService"] or Knit.GetService("StatusService")
	self.Services["EffectService"] = self.Services["EffectService"] or Knit.GetService("EffectService")
	self.Services["RagdollService"] = self.Services["RagdollService"] or Knit.GetService("RagdollService")
	self.Services["PassiveService"] = self.Services["PassiveService"] or Knit.GetService("PassiveService")

	local playerData = self.Services["PlayerService"].PlayerDatas[player.UserId] or nil
	local VFXFolder = ReplicatedStorage.Shared.Assets.VFX.Passives.KickStyle.Push
	if not playerData then
		warn("PLAYER DATA YOK ")
		return
	end

	local ragdoll = otherdatas.ragdollData
		or {
			Direction = player.Character.HumanoidRootPart.CFrame.LookVector,
			KnockPower = 50,
			RagdollDuration = 4,
		}
	if game.Players:FindFirstChild(otherdatas.hittingplayer.Name) then
		local HitVfx = VFXFolder:FindFirstChild("OnHit"):Clone()
		HitVfx.Parent = player.Character.Torso
		HitVfx.Enabled = true
		task.delay(0.1, function()
			HitVfx.Enabled = false
			task.delay(0.4, function()
				HitVfx:Destroy()
			end)
		end)

		local OnFlight = VFXFolder:FindFirstChild("OnFlight"):Clone()
		OnFlight.Parent = otherdatas.hittingplayer.Character.Torso
		OnFlight.Enabled = true
		task.delay(1.4, function()
			OnFlight.Enabled = false
			task.delay(0.4, function()
				OnFlight:Destroy()
			end)
		end)

		self.Services["RagdollService"]:RagdollStatus(otherdatas.hittingplayer, true, ragdoll)
		if playerData.FusionPassive then
			self.Services["PassiveService"]:StartAuraPassive(
				player,
				{ HittedPlayer = otherdatas.hittingplayer, otherDatas = otherdatas.otherdatas }
			)
			self.Services["PlayerService"]:UpdatePlayerData(player, { FusionPassive = false })
		end
	else
		local HitVfx = VFXFolder:FindFirstChild("OnHit"):Clone()
		HitVfx.Parent = player.Character.Torso
		HitVfx.Enabled = true
		task.delay(0.1, function()
			HitVfx.Enabled = false
			task.delay(0.4, function()
				HitVfx:Destroy()
			end)
		end)

		local OnFlight = VFXFolder:FindFirstChild("OnFlight"):Clone()
		OnFlight.Parent = otherdatas.hittingplayer.Torso
		OnFlight.Enabled = true
		task.delay(1.4, function()
			OnFlight.Enabled = false
			task.delay(0.4, function()
				OnFlight:Destroy()
			end)
		end)
		self.Services["RagdollService"]:NPCRagdoll(otherdatas.hittingplayer, true, ragdoll)
		if playerData.FusionPassive then
			self.Services["PassiveService"]:StartAuraPassive(
				player,
				{ HittedPlayer = otherdatas.hittingplayer, otherDatas = otherdatas }
			)
			self.Services["PlayerService"]:UpdatePlayerData(player, { FusionPassive = false })
		end
	end
end

return Push
