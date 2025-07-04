--[[
    Amplitude: - Gucunu ayarliyor ne kadar cok artarsa o kadar fazla sallar
    Frequency: - Sallama sikligi
    FadeInTime: Maximum guce cikma suresi
    FadeOutTime: 0 a dusme suresi
    Sustained: True ya da false  sonsuza kadar devam ediyo ben dur diyene kadar ondan gendel false kalsin
    SustainTime: Full gucte kac sn duracagi  Genel sure  Fadein+Sustain+FadeOut olarak hesaplaniyo
    PositionInfluence: Camerayi kaydirmayi sagliyor
    RotationInfluence: Camerayi dondurmeyi sagliyor

    Amplitude = 5,
    Frequency = 0.1,
    FadeInTime = 0,
    FadeOutTime = 0,
    Sustained = false,
    SustainTime =  1,
    PositionInfluence = Vector3.one,
    RotationInfluence = Vector3.new(0.1,0.1,0.1),


]]

local Shakes = {}

Shakes.Hit = {
	Amplitude = 1,
	Frequency = 0.225,
	FadeInTime = 0,
	FadeOutTime = 0.275,
	Sustained = false,
	SustainTime = 0.45,
	PositionInfluence = Vector3.one,
	RotationInfluence = Vector3.new(5, 5, 5),
}

Shakes.Burned = {
	Amplitude = 2.5,
	Frequency = 0.325,
	FadeInTime = 0,
	FadeOutTime = 0.225,
	Sustained = false,
	SustainTime = 0.1,
	PositionInfluence = Vector3.one,
	RotationInfluence = Vector3.new(0.5, 0, -15),
}

return Shakes
