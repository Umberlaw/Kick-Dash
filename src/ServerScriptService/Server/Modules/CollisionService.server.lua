local PhysicsService = game:GetService("PhysicsService")

local CollideParts = "CollideParts"
local RagdolledPlayers = "RagdolledPlayers"
local Players = "Players"
local NPC = "NPC"
local World = "World"
local Portals = "Portals"

PhysicsService:RegisterCollisionGroup(CollideParts)
PhysicsService:RegisterCollisionGroup(RagdolledPlayers)
PhysicsService:RegisterCollisionGroup(Players)
PhysicsService:RegisterCollisionGroup(NPC)
PhysicsService:RegisterCollisionGroup(World)
PhysicsService:RegisterCollisionGroup(Portals)

PhysicsService:CollisionGroupSetCollidable(CollideParts, CollideParts, false)
PhysicsService:CollisionGroupSetCollidable(CollideParts, Players, false)
PhysicsService:CollisionGroupSetCollidable(CollideParts, NPC, false)
PhysicsService:CollisionGroupSetCollidable(CollideParts, RagdolledPlayers, true)
PhysicsService:CollisionGroupSetCollidable(CollideParts, Portals, false)

PhysicsService:CollisionGroupSetCollidable(Players, Players, false)
PhysicsService:CollisionGroupSetCollidable(Players, NPC, false)
PhysicsService:CollisionGroupSetCollidable(Players, RagdolledPlayers, false)
PhysicsService:CollisionGroupSetCollidable(Players, Portals, false)

PhysicsService:CollisionGroupSetCollidable(NPC, NPC, false)
PhysicsService:CollisionGroupSetCollidable(NPC, RagdolledPlayers, false)

PhysicsService:CollisionGroupSetCollidable(World, CollideParts, true)
PhysicsService:CollisionGroupSetCollidable(World, Players, true)
PhysicsService:CollisionGroupSetCollidable(World, RagdolledPlayers, true)
PhysicsService:CollisionGroupSetCollidable(World, NPC, true)

PhysicsService:CollisionGroupSetCollidable(RagdolledPlayers, Portals, false)
