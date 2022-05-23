extends Node

var HasJetPack = false
var HasGun = false

var PreviousLevel = "Level0"
var SaveLevel = "Level0"
var SaveCoordinates = Vector2.ZERO
var HasDied = false
var HasSavedOnce = false
var HasBlueBullet = false
var HasReceivedRoom16Heart = false
var HasReceivedRoom15Heart = false
var BossRounds = 0
var IsEagleDead = false
var IsSummonDead = false
var IsShootDead = false

var PlayerInput = Vector2.ZERO
var CameraOffsetY = 0
var PlayerDirection = Vector2.ZERO
var PlayerPosition = Vector2.ZERO
var PlayerFlippedH = false

enum BusType {
	SFX,
	MUSIC,
}

enum TotemPhase {
	SHOOT,
	SUMMON,
	FLY,
}
