local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Burned = {}

Burned.OpenedTaskes = {}
Burned.KnitServices = {}

local Knit = require(ReplicatedStorage.Packages.knit)

function Burned:Remove(player, effectTable, SfxTable)
	for _, allEffects in effectTable do
		allEffects.Enabled = false
		task.delay(1, function()
			allEffects:Destroy()
		end)
	end
	for _, AllSfx in SfxTable do
		TweenService:Create(
			AllSfx,
			TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
			{ Volume = 0 }
		):Play()
		task.delay(1, function()
			AllSfx:Destroy()
		end)
	end
	effectTable = nil
	SfxTable = nil
	if self.OpenedTaskes[player.UserId] then
		if coroutine.status(self.OpenedTaskes[player.UserId]) == "Running" then
			task.cancel(self.OpenedTaskes[player.UserId])
		end
		self.OpenedTaskes[player.UserId] = nil
		print("kapaniyorum")
	end
end

function Burned:Active(player, _, _)
	self.KnitServices["PlayerService"] = self.KnitServices["PlayerService"] or Knit.GetService("PlayerService")
	self.KnitServices["EffectService"] = self.KnitServices["EffectService"] or Knit.GetService("EffectService")
	local playerData = self.KnitServices["PlayerService"].PlayerDatas[player.UserId] or nil
	if not playerData then
		warn("Player data Didnt find")
		return
	end

	if not self.OpenedTaskes[player.UserId] then
		local effectsTable = {}
		local SfxTable = {}
		local SfxTargetFolder = ReplicatedStorage.Shared.Assets.SFX.Status.Burned
		local targetParticleFolder = ReplicatedStorage.Shared.Assets.VFX.Particles.StatusEffects.Burned

		if targetParticleFolder then
			for _, allEffects in targetParticleFolder:GetChildren() do
				local clonnedEffect = allEffects:Clone()
				clonnedEffect.Parent = player.Character.Torso
				if clonnedEffect.Name == "FireLoop" then
					clonnedEffect.Enabled = true
				end

				table.insert(effectsTable, clonnedEffect)
			end
		end
		if SfxTargetFolder then
			for _, AllSfxTemplates in SfxTargetFolder:GetChildren() do
				local clonnedSFX = AllSfxTemplates:Clone()
				if clonnedSFX.Name == "LoopBurn" then
					clonnedSFX.Looped = true
				end
				clonnedSFX.Parent = player.Character.Head
				table.insert(SfxTable, clonnedSFX)
				clonnedSFX:Play()
			end
		end
		self.OpenedTaskes[player.UserId] = task.spawn(function()
			while task.wait(1) do
				print("gorevimi yapiyorum buirned")
				local BurnedTime = playerData.Debuffes["Burned"].RemainingTime
				local remainingBurnedTime = math.clamp(BurnedTime - 1, 0, math.huge)

				local HitEffect = effectsTable[1]

				local HitSFX = SfxTable[1]
				if HitSFX then
					if not HitSFX.Playing then
						HitSFX:Play()
					end
				else
					warn("HIT SFX DE YOK KRAL")
				end
				if not HitEffect.Enabled then
					HitEffect.Enabled = true
					print("BurnedEffectOnyadi")
					task.delay(0.6, function()
						HitEffect.Enabled = false
					end)
				else
					warn("BurnHitEffecti yok")
				end
				self.KnitServices["EffectService"]:CreateShake(player, "Burned")
				if remainingBurnedTime <= 0 then
					self.KnitServices["PlayerService"]:RemoveDebuff(player, "Burned")
					self:Remove(player, effectsTable, SfxTable)
					break
				elseif remainingBurnedTime > 0 then
					local RemainingHP = math.clamp(
						math.floor(playerData.Health - (playerData.MaximumHealth * 0.01)),
						playerData.MaximumHealth * 0.01,
						playerData.MaximumHealth
					)

					print(RemainingHP, player)
					self.KnitServices["PlayerService"]:UpdatePlayerData(player, { Health = RemainingHP })
					self.KnitServices["PlayerService"]:UpdateDebuffData(player, "Burned", { RemainingTime = -1 })
				end
			end
		end)
	else
		print("ZATEN AKTIF OLARAK VAR")
	end
end

return Burned
