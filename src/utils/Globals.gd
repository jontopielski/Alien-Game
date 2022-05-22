extends Node

var HasJetPack = false
var HasGun = true

var PreviousLevel = "Level0"
var SaveLevel = "Level0"
var SaveCoordinates = Vector2.ZERO
var HasDied = false
var HasSavedOnce = false
var HasBlueBullet = false
var HasReceivedRoom16Heart = false

var PlayerInput = Vector2.ZERO
var CameraOffsetY = 0
var PlayerDirection = Vector2.ZERO
var PlayerPosition = Vector2.ZERO
var PlayerFlippedH = false

enum BusType {
	SFX,
	MUSIC,
}
