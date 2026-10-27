Localplayer = {}
Localplayer.CurrentVehicle = 0
Localplayer.Ped = PlayerPedId()
Localplayer.Sex = 0
Localplayer.InstanceID = 0
Localplayer.InVehicle = false
Localplayer.InCombat = false
Localplayer.Ragdoll = false
Localplayer.Inconscious = false
Localplayer.Pos = vector3(0.0, 0.0, 0.0)
Localplayer.GameplayCamPos = vector3(0.0, 0.0, 0.0)
Localplayer.Rotation = vector3(0.0, 0.0, 0.0)
Localplayer.Heading = 0.0
Localplayer.ZoneName = ""
Localplayer.Invincible = false
Localplayer.InteriorID = 0
Localplayer.RoomKey = 0
Localplayer.Armed = false
Localplayer.Shooting = false
Localplayer.Cuffed = false
Localplayer.Health = 0
Localplayer.Armor = 0
Localplayer.Visible = true
Localplayer.Freezed = false
Localplayer.NoCollide = false
Localplayer.County = "LS"
Localplayer.MaxHealth = GetConvarInt("sh_maxHealth", 250)
Localplayer.SelectedWeapon = 0
Localplayer.SelectedVehicleWeapon = 0
Localplayer.HealthRechargeMultiplier = 0.0
Localplayer.MeleeWeaponDefenseMultiplier = 0.0
Localplayer.VehicleModel = 0
Localplayer.Running = false
Localplayer.InteriorHash = 0
Localplayer.RunSpeed = 1.0
Localplayer.Deathcause = 0
Localplayer.Animal = false
Localplayer.KO = false
Localplayer.Grids = {}
PROOF_FLAGS = {
    BULLET = 1,
    FIRE = 2,
    EXPLOSION = 4,
    COLLISION = 8,
    MELEE = 16,
    STEAM = 32,
    UNK_7 = 64,
    DROWN = 128
}
Localplayer.Proof = 0

function Localplayer:Matrix()
    return GetEntityMatrix(self.Ped)
end

function Localplayer:GetVehicle()
    if self.InVehicle and self.CurrentVehicle and self.CurrentVehicle > 0 then
        return self.CurrentVehicle
    end
    return nil
end

function Localplayer:Set(key, value)
    Localplayer[key] = value
end

function Localplayer:Freeze(state)
    if state ~= nil then
        self.Freezed = state
    else
        self.Freezed = not self.Freezed
    end
    FreezeEntityPosition(self.Ped, self.Freezed)
end

function Localplayer:GetFlag(flagId)
    return GetPedConfigFlag(self.Ped, flagId, true)
end

function Localplayer:SetFlag(flagId, state)
    SetPedConfigFlag(self.Ped, flagId, state)
end

function Localplayer:SetProof(flag, state)
    if state then
        if not HasFlag(self.Proof, flag) then
            self.Proof = self.Proof + flag
        end
    else
        if HasFlag(self.Proof, flag) then
            self.Proof = self.Proof - flag
        end
    end
end

function Localplayer:SetInvincible(state)
    self.Invincible = state
    self:SetProof(PROOF_FLAGS.MELEE, state)
    self:SetProof(PROOF_FLAGS.BULLET, state)
end

function Localplayer:SetNoCollision(state)
    if state ~= nil then
        self.NoCollide = state
    else
        self.NoCollide = not self.NoCollide
    end
    SetEntityCollision(self.Ped, not self.NoCollide, not self.NoCollide)
    SetEntityCompletelyDisableCollision(self.Ped, not self.NoCollide, not self.NoCollide)
end

function LocalPlayer()
    return Localplayer
end

CreateThread(function()
    Localplayer.ID = PlayerId()
    Localplayer.ServerID = GetPlayerServerId(Localplayer.ID)

    if IS_DEV then
        FreezeEntityPosition(Localplayer.Ped, false)
    end

    while true do
        Localplayer.Pos = GetEntityCoords(Localplayer.Ped)
        Localplayer.GameplayCamPos = GetFinalRenderedCamCoord()
        Localplayer.Rotation = GetEntityRotation(Localplayer.Ped, 2)
        Localplayer.Heading = Localplayer.Rotation.z
        Localplayer.Health = GetEntityHealth(Localplayer.Ped)
        Localplayer.Armor = GetPedArmour(Localplayer.Ped)
        Localplayer.Shooting = IsPedShooting(Localplayer.Ped)
        Localplayer.InteriorID = GetInteriorFromEntity(Localplayer.Ped)
        Localplayer.RoomKey = GetRoomKeyFromEntity(Localplayer.Ped)
        Localplayer.InVehicle = IsPedInAnyVehicle(Localplayer.Ped, false)
        Localplayer.SelectedWeapon = GetSelectedPedWeapon(Localplayer.Ped)
        Localplayer.Running = IsPedRunning(Localplayer.Ped)
        Localplayer.Grids = GetGridsSurroundingPosition(Localplayer.Pos)

        if Localplayer.InVehicle then
            Localplayer.CurrentVehicle = GetVehiclePedIsUsing(Localplayer.Ped)
        else
            Localplayer.CurrentVehicle = nil
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        Localplayer.Ped = PlayerPedId()
        Localplayer.ZoneName = string.upper(GetNameOfZone(Localplayer.Pos.x, Localplayer.Pos.y, Localplayer.Pos.z))
        Localplayer.Armed = IsPedArmed(Localplayer.Ped, 6)

        if Localplayer.CurrentVehicle then
            Localplayer.IsVehicleDriver = (Localplayer.Ped == GetPedInVehicleSeat(Localplayer.CurrentVehicle, -1))
        else
            Localplayer.IsVehicleDriver = false
        end

        if Localplayer.CurrentVehicle then
            Localplayer.VehicleModel = GetEntityModel(Localplayer.CurrentVehicle)
        else
            Localplayer.VehicleModel = 0
        end

        Localplayer.InWater = IsEntityInWater(Localplayer.Ped)

        SetEntityCanBeDamagedByRelationshipGroup(Localplayer.Ped, false, GetHashKey("PLAYER"))

        if Localplayer.InVehicle then
            local retval, weapon = GetCurrentPedVehicleWeapon(Localplayer.Ped)
            if retval then
                Localplayer.SelectedVehicleWeapon = weapon
            else
                Localplayer.SelectedVehicleWeapon = 0
            end
        else
            if Localplayer.SelectedVehicleWeapon ~= 0 then
                Localplayer.SelectedVehicleWeapon = 0
            end
        end

        Wait(1000)
    end
end)
