local PhysicsService = game:GetService("PhysicsService")

local CollideParts = "CollideParts"
local RagdolledPlayers = "RagdolledPlayers"
local Players = "Players"
local NPC = "NPC"
local World = "World"

PhysicsService:RegisterCollisionGroup(CollideParts)
PhysicsService:RegisterCollisionGroup(RagdolledPlayers)
PhysicsService:RegisterCollisionGroup(Players)
PhysicsService:RegisterCollisionGroup(NPC)
PhysicsService:RegisterCollisionGroup(World)

PhysicsService:CollisionGroupSetCollidable(CollideParts, CollideParts, false)
PhysicsService:CollisionGroupSetCollidable(CollideParts, Players, false)
PhysicsService:CollisionGroupSetCollidable(CollideParts, NPC, false)
PhysicsService:CollisionGroupSetCollidable(CollideParts, RagdolledPlayers, true)

PhysicsService:CollisionGroupSetCollidable(Players, Players, false)
PhysicsService:CollisionGroupSetCollidable(Players, NPC, false)
PhysicsService:CollisionGroupSetCollidable(Players, RagdolledPlayers, false)

PhysicsService:CollisionGroupSetCollidable(NPC, NPC, false)
PhysicsService:CollisionGroupSetCollidable(NPC, RagdolledPlayers, false)

PhysicsService:CollisionGroupSetCollidable(World, CollideParts, true)
PhysicsService:CollisionGroupSetCollidable(World, Players, true)
PhysicsService:CollisionGroupSetCollidable(World, RagdolledPlayers, true)
PhysicsService:CollisionGroupSetCollidable(World, NPC, true)
