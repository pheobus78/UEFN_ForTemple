using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Verse.org/Simulation/Tags }

# Game zones tags
pickup_zone_tag<public> := class(tag):
pickup_zone_level_1_tag<public> := class(pickup_zone_tag):
pickup_zone_level_2_tag<public> := class(pickup_zone_tag):
pickup_zone_level_3_tag<public> := class(pickup_zone_tag):
pickup_zone_level_4_tag<public> := class(pickup_zone_tag):
pickup_zone_level_5_tag<public> := class(pickup_zone_tag):
pickup_zone_level_6_tag<public> := class(pickup_zone_tag):
pickup_zone_level_7_tag<public> := class(pickup_zone_tag):
pickup_zone_level_8_tag<public> := class(pickup_zone_tag):
pickup_zone_level_9_tag<public> := class(pickup_zone_tag):

delivery_zone_tag<public> := class(tag):
delivery_zone_level_1_tag<public> := class(delivery_zone_tag):
delivery_zone_level_2_tag<public> := class(delivery_zone_tag):
delivery_zone_level_3_tag<public> := class(delivery_zone_tag):
delivery_zone_level_4_tag<public> := class(delivery_zone_tag):
delivery_zone_level_5_tag<public> := class(delivery_zone_tag):
delivery_zone_level_6_tag<public> := class(delivery_zone_tag):
delivery_zone_level_7_tag<public> := class(delivery_zone_tag):
delivery_zone_level_8_tag<public> := class(delivery_zone_tag):
delivery_zone_level_9_tag<public> := class(delivery_zone_tag):

# The Stronghold is a game mode in which the goal is for players to eliminate all hostile enemies at a heavily guarded Stronghold
# The Stronghold Game Manager Verse device is used to manage, monitor, and control the AIs at the Stronghold
stronghold_game_manager := class(creative_device):
    
    # Device reference to guard spawner device to keep track of for eliminations
    @editable
    GuardsInitialSpawners:[]guard_spawner_device := array{}

    # Device reference to guard spawner device to keep track of for eliminations for multiplayer scaling
    @editable
    GuardsInitialSpawnersAdditional:[]guard_spawner_device := array{}

    # Device reference to reinforcement guard spawner device to trigger when one of the Stronghold guards is alerted
    @editable
    GuardsReinforcementSpawners:[]guard_spawner_device := array{}

    # Device reference to reinforcement guard spawner device to trigger when one of the Stronghold guards is alerted for multiplayer scaling
    @editable
    GuardsReinforcementSpawnersAdditional:[]guard_spawner_device := array{}

    # Device reference to display and track objectives
    @editable
    GuardTracker:tracker_device := tracker_device{}

    # Device reference to display and track objectives
    @editable
    ItemTracker:tracker_device := tracker_device{}
    # Device reference to display reinforcement in-game message
    @editable
    MessageDeviceReinforcement:hud_message_device := hud_message_device{}

    # Device reference to display fallback in-game message
    @editable
    MessageDeviceFallback:hud_message_device := hud_message_device{}

    # Device reference to end the game with a victory if the players completed the Stronghold without being detected
    @editable
    EndGameVictoryDeviceDetected:end_game_device := end_game_device{}

    # Device reference to end the game with a victory if the players completed the Stronghold while being detected
    @editable
    EndGameFailDeviceTimeout:end_game_device := end_game_device{}

    # Device reference to end the game with a fail if the players ran out of retries
    @editable
    EndGameFailDevice:end_game_device := end_game_device{}

    # Adjustable number of player lives
    @editable
    var PlayerRetries:int = 10

    # Device to reference Stronghold leash position
    @editable
    ReinforcementLeashReference:stronghold_leash_position := stronghold_leash_position{}

    # Device to reference Fallback leash position
    @editable
    FallbackLeashReference:stronghold_leash_position := stronghold_leash_position{}

    # Leashes that must be disabled after fallback
    @editable
    LeashesToDisableForFallback:[]stronghold_leash_position := array{}

    # Device for the explosion
    @editable
    ExplosiveDevice:explosive_device := explosive_device{}
    # Device for the explosion
    @editable
    ExplosiveTriggerDevice:player_checkpoint_device := player_checkpoint_device{}

    @editable
    PickupMarker<public> : objective_marker = objective_marker{}
   
    @editable
    DeliveryMarker<public> : objective_marker = objective_marker{}

    @editable
    ItemRemover<public> : item_remover_device = item_remover_device{}

    # How long the countdown timer will start counting down from.
    @editable
    InitialCountdownTime<public> : float = 30.0

     # How many seconds to add to the countdown timer when a pickup is delivered.
    @editable
    DeliveryBonusSeconds<public> : float = 20.0
 
    @editable
    # Maps how many points a pickup is worth based on its pickup level.
    PointsForPickupLevel<public> : []int = array{1, 2, 3, 4, 5, 6, 7, 8, 9}
  
    PickupZonesTags : []pickup_zone_tag = array{pickup_zone_level_1_tag{}, pickup_zone_level_2_tag{}, pickup_zone_level_3_tag{}, pickup_zone_level_4_tag{}, pickup_zone_level_5_tag{}, pickup_zone_level_6_tag{}, pickup_zone_level_7_tag{}, pickup_zone_level_8_tag{}, pickup_zone_level_9_tag{}}
  
    DeliveryTags : []delivery_zone_tag = array{delivery_zone_level_1_tag{}, delivery_zone_level_2_tag{}, delivery_zone_level_3_tag{}, delivery_zone_level_4_tag{}, delivery_zone_level_5_tag{}, delivery_zone_level_6_tag{}, delivery_zone_level_7_tag{}, delivery_zone_level_8_tag{}, delivery_zone_level_9_tag{}}

    # Event broadcasted when a guard call for reinforcement
    ReinforcementsCalledEvent:event(agent) = event(agent){}

    # Event broadcasted when guards defend the center of the Stronghold
    FallbackEvent:event() = event(){}

    # Event broadcasted when a guard becomes suspicious
    GuardsSuspiciousEvent:event(agent) = event(agent){}

    # Event broadcasted when all guards become unaware
    GuardsUnawareEvent:event(agent) = event(agent){}

    # Event broadcasted when a player is detected
    PlayerDetectedEvent:event(agent) = event(agent){}

    # Event broadcasted when all guards have lost their target
    PlayerLostEvent:event(agent) = event(agent){}

    # Lists of guards in a specific alert state to monitor perception changes

    # Variable to store reinforcement guards
    var<private> NumGuardsSpawned:int := 0

    # Variable to store all Stronghold guards
    var<private> StrongholdGuards:[]agent := array{}

    # Variable to store reinforcement guards
    var<private> ReinforcementGuards:[]agent := array{}

    # List of guards currently suspicious
    var<private> SuspiciousGuards : []agent = array{}

    # List of guards currently alerted
    var<private> AlertedGuards : []agent = array{}

    # List of guards currently investigating
    var<private> InvestigatingGuards : []agent = array{}

    # Initial guard spawners, will include additional spawners with multiplayer session
    var<private> GuardsInitialSpawnersInternal:[]guard_spawner_device = array{}

    # Reinforcement guard spawners, will include additional spawners with multiplayer session
    var<private> GuardsReinforcementSpawnersInternal:[]guard_spawner_device = array{}

    # Gameplay logic variables

    # Variable to track the number of eliminations from all Stronghold guard spawners
    var<private> GuardsEliminated:int := 0

    # Variable to track if the reinforcement were called or not
    var<private> ReinforcementTriggered:logic := false

    # Variable to track if the fallback was triggered
    var<private> FallbackTriggered:logic := false

    # Variable to store the first player agent that gets detected by the guards
    var<private> DetectedPlayer:?player := false
    
    # Variable to track if the collection is completed
    var<private> CaptureItemCompleted:logic := false

    # Runs when the device is started in a running game.
    OnBegin<override>()<suspends>:void=
        
        Log("Stronghold verse manager is starting", ?Level:=log_level.Normal)

        # Check active player for difficulty scaling
        var NumberOfActivePlayers:int = 0
        for (StrongholdPlayer : GetPlayspace().GetPlayers(), not StrongholdPlayer.IsSpectator[], StrongholdPC := StrongholdPlayer.GetFortCharacter[]):
            set NumberOfActivePlayers += 1
            # Subscribing to player elimination event
            StrongholdPC.EliminatedEvent().Subscribe(OnPlayerEliminated)

        Log("Game manager - Total player number is {NumberOfActivePlayers}")

        set GuardsInitialSpawnersInternal = GuardsInitialSpawners
        set GuardsReinforcementSpawnersInternal = GuardsReinforcementSpawners

        # Add additional Guard Spawner when there is more than 2 players
        if (NumberOfActivePlayers > 2):
            set GuardsInitialSpawnersInternal += GuardsInitialSpawnersAdditional
            set GuardsReinforcementSpawnersInternal += GuardsReinforcementSpawnersAdditional
            
        var NumInitialGuards:int = 0
        for (GuardSpawner : GuardsInitialSpawnersInternal):
            GuardSpawner.Enable()
            SubscribeToGuardSpawnerEvents(GuardSpawner);
            set NumInitialGuards += GuardSpawner.GetSpawnLimit()

        GuardTracker.SetTarget(NumInitialGuards)
        
        for (GuardReinforcementSpawner : GuardsReinforcementSpawnersInternal):
            SubscribeToGuardSpawnerEvents(GuardReinforcementSpawner);

            # Subscribing to reinforcement spawned event
            GuardReinforcementSpawner.SpawnedEvent.Subscribe(OnReinforcementSpawned)
            GuardReinforcementSpawner.AlertedEvent.Subscribe(OnReinforcementAlerted)
            GuardReinforcementSpawner.UnawareEvent.Subscribe(OnReinforcementUnaware)
        GuardTracker.AssignToAll()
        ExplosiveTriggerDevice.FirstActivationEvent.Subscribe(OnHandleFirstActivation)

    SubscribeToGuardSpawnerEvents(SpawnerDevice:guard_spawner_device):void = 
        SpawnerDevice.SpawnedEvent.Subscribe(OnGuardSpawned)
        SpawnerDevice.EliminatedEvent.Subscribe(OnGuardEliminated)
        SpawnerDevice.SuspiciousEvent.Subscribe(OnGuardSuspicious)
        SpawnerDevice.AlertedEvent.Subscribe(OnGuardAlerted)
        SpawnerDevice.TargetLostEvent.Subscribe(OnGuardLostTarget)
        SpawnerDevice.UnawareEvent.Subscribe(OnGuardUnaware)
        
    # Start tracking eliminated guards and trigger the explosion  
    StartGameplay()<suspends>:void = 
        FindPlayer()
        SetupZones()
        StartPickupDeliveryGame()

        #Sleep(3.0)
        #if (FirstPlayer:=GetPlayspace().GetPlayers()[0]):
        #    ExplosiveDevice.Explode(FirstPlayer)

    OnHandleFirstActivation(Player:agent):void=    
        ExplosiveDevice.Explode(Player)


    # Runs when guard spawner receives an alerted event and considers only the first alert event
    OnGuardAlerted(InteractionResult:device_ai_interaction_result):void=
        if:
            not ReinforcementTriggered?
            set DetectedPlayer = option{player[InteractionResult.Target?]}
            Guard:=InteractionResult.Source?
        then:
            Log("Game manager - Stronghold is alerted. Incoming reinforcement", ?Level:=log_level.Normal)

            var NumGuards:int = GuardTracker.GetTarget()

            # Enabling the reinforcement guard spawner device ensures that we spawn the amount of guards configured in the guard spawner device.
            for (GuardReinforcementSpawner : GuardsReinforcementSpawnersInternal):
                GuardReinforcementSpawner.Enable()
                set NumGuards += GuardReinforcementSpawner.GetSpawnLimit()
    
            GuardTracker.SetTarget(NumGuards)

            # Displaying in-game message for detection and incoming reinforcement
            MessageDeviceReinforcement.Show()
            set ReinforcementTriggered = true
            # Signal Reinforcement event
            ReinforcementsCalledEvent.Signal(Guard)
       
        # Add the guard to the list of alerted guards if it hasn't been previously added
        if(Guard:=InteractionResult.Source?):
            if (not AlertedGuards.Find[Guard]):
                set AlertedGuards += array{Guard}

            option {set SuspiciousGuards = SuspiciousGuards.RemoveFirstElement[Guard]}
            option {set InvestigatingGuards = InvestigatingGuards.RemoveFirstElement[Guard]}
        
            # Broadcast the Player Detected Event when one guard is alerted
            if (AlertedGuards.Length = 1):
                PlayerDetectedEvent.Signal(Guard)

    # Runs when reinforcement guard spawner receives an alerted event
    OnReinforcementAlerted(InteractionResult:device_ai_interaction_result):void=      
        if:
            not FallbackTriggered?
            Guard:=InteractionResult.Source?
        then:
            # Clear leash for reinforcement on alerted so they attack their target
            ReinforcementLeashReference.ClearLeashOnGuard(Guard)
            Log("Game manager - Reinforcement is alerted. Clear Leash.", ?Level:=log_level.Normal)

    # Runs when reinforcement guard spawner receives an unaware event
    OnReinforcementUnaware(Guard:agent):void=    
        if (not FallbackTriggered?):
            # Set back the leash
            Log("Game manager - Reinforcement is unaware. Reset leash.", ?Level:=log_level.Normal)
            ReinforcementLeashReference.ApplyLeashOnGuard(Guard)

    # Runs when guard spawner receives an unaware event
    OnGuardSuspicious(Guard:agent):void=
        if (not SuspiciousGuards.Find[Guard]):
            set SuspiciousGuards += array{Guard}

            # Broadcast the Suspicious Event when one guard is suspicious
            if:
                SuspiciousGuards.Length = 1
                AlertedGuards.Length = 0
                InvestigatingGuards.Length = 0
            then:
                GuardsSuspiciousEvent.Signal(Guard)

    # Runs when guard spawner receives an unaware event
    OnGuardUnaware(Guard:agent):void=
        option {set AlertedGuards = AlertedGuards.RemoveFirstElement[Guard]}
        option {set SuspiciousGuards = SuspiciousGuards.RemoveFirstElement[Guard]}
        option {set InvestigatingGuards = InvestigatingGuards.RemoveFirstElement[Guard]}

        # Broadcast the Unaware Event when no guard is suspicious, alerted or investigating
        if:
            SuspiciousGuards.Length = 0
            AlertedGuards.Length = 0
            InvestigatingGuards.Length = 0
        then:
            GuardsUnawareEvent.Signal(Guard)  

    # When a guard loses track of the player, remove it from the alerted guards list, when all guards have lost player, signal the event
    OnGuardLostTarget(InteractionResult:device_ai_interaction_result):void=
        if (Guard := InteractionResult.Source?):
            if (not InvestigatingGuards.Find[Guard]):
                set InvestigatingGuards += array{Guard}

            # Broadcast the Player Lost Event when no guard is alerted                
            if (set AlertedGuards = AlertedGuards.RemoveFirstElement[Guard]):
                if (AlertedGuards.Length = 0):
                    PlayerLostEvent.Signal(Guard)


    # Runs when a reinforcement guard is spawned. Each reinforcement guard is forced to attack the player that alerted the Stronghold
    OnReinforcementSpawned(Guard:agent):void=
        set ReinforcementGuards += array{Guard}
        ReinforcementLeashReference.ApplyLeashOnGuard(Guard)

        # Assigns the player that alerted the Stronghold guards as the target
        if (Target := DetectedPlayer?):
            for (GuardReinforcementSpawner : GuardsReinforcementSpawnersInternal):
                GuardReinforcementSpawner.ForceAttackTarget(Target, ?ForgetTime:=30.0)
                Log("Game manager - ForceAttackTarget given to reinforcement guard", ?Level:=log_level.Normal)

    
    # Runs when any guard from the Stronghold is spawned
    OnGuardSpawned(Guard:agent):void=
        set StrongholdGuards += array{Guard}
        set NumGuardsSpawned += 1
    
    # Runs when initial or reinforcement spawners receive an elimination
    OnGuardEliminated(InteractionResult:device_ai_interaction_result):void=
        set GuardsEliminated += 1
        Log("Game manager - Stronghold guard eliminated count = {GuardsEliminated} / {NumGuardsSpawned}", ?Level:=log_level.Normal)

        if (EliminatedAgent := InteractionResult.Target?):
            # Remove eliminated guard from the alerted guards list
            option {set AlertedGuards = AlertedGuards.RemoveFirstElement[EliminatedAgent]}
            option {set SuspiciousGuards = SuspiciousGuards.RemoveFirstElement[EliminatedAgent]}
            option {set InvestigatingGuards = InvestigatingGuards.RemoveFirstElement[EliminatedAgent]}
            option {set StrongholdGuards = StrongholdGuards.RemoveFirstElement[EliminatedAgent]}
        else:
            Log("Game manager - No interaction target for elimination", ?Level:=log_level.Error)

        if (EliminationAgent := InteractionResult.Source?):
            OnGuardEliminatedByPlayer(EliminationAgent)
        else:
            Log("Game manager - No interaction source for elimination.", ?Level:=log_level.Error)

    OnGuardEliminatedByPlayer(EliminationPlayer:agent):void=

        # Increasing progress value for tracker device for each elimination
        GuardTracker.Increment(EliminationPlayer)

        if (ReinforcementTriggered?):

            if (NumGuardsSpawned - GuardsEliminated = 3):
                StartFallback()
                
            # Ends the game mode if all guards were eliminated without the reinforcements
            if (GuardsEliminated >= NumGuardsSpawned):
                if (CaptureItemCompleted?):
                    EndGameVictoryDeviceDetected.Activate(EliminationPlayer)
                    Log("Game manager - Completed Stronghold detected", ?Level:=log_level.Normal)
        else:
            # Ends the game mode if all guards were eliminated with the reinforcements
            if (GuardsEliminated >= NumGuardsSpawned):
                if (CaptureItemCompleted?):
                    EndGameVictoryDeviceDetected.Activate(EliminationPlayer)
                    Log("Game manager - Completed Stronghold undetected", ?Level:=log_level.Normal)

    # Assigns a new fallback leash when a few alerted guards are remaining to defend the center of the Stronghold
    StartFallback():void=
        # Displaying in-game message for guards retreating inside the Stronghold building
        MessageDeviceFallback.Show()
        set FallbackTriggered = true

        for (LeashDevice : LeashesToDisableForFallback):  
            LeashDevice.DisableLeashAndPatrolPaths()

        FallbackLeashPosition := FallbackLeashReference.GetTransform().Translation
        FallbackEvent.Signal()
        for (Guard : StrongholdGuards):  
            FallbackLeashReference.ApplyLeashOnGuard(Guard)
            Log("Game manager - Fallback leash is assigned", ?Level:=log_level.Normal)
    
        
    # Runs when a player elimination event is received
    OnPlayerEliminated(EliminationResult:elimination_result):void=
        set PlayerRetries -= 1
        if (PlayerRetries = 0, Agent := EliminationResult.EliminatedCharacter.GetAgent[]):
            EndGameFailDevice.Activate(Agent)
            Log("Game manager - Player was eliminated", ?Level:=log_level.Normal)

    var MaybePlayer<private> : ?player = false
    var CountdownTimer<private> : countdown_timer = countdown_timer{}
    var DeliveryZones<private> : []tagged_zone_selector = array{}
    var PickupZones<private> : []tagged_zone_selector = array{}
    var MaxPickupLevelCounts : []int = array{0, 0, 0, 0, 0, 0, 0, 0, 0, 0}


    FindPlayer<private>() : void =
        # Since this is a single player experience, the first player (0)
        # should be the only one available.
        Playspace := Self.GetPlayspace()
        if (FirstPlayer := Playspace.GetPlayers()[0]):
            set MaybePlayer = option{FirstPlayer}
            Log("Player found", ?Level:=log_level.Normal)
        else:
            # Log an error if we can't find a player.
            # This shouldn't happen because at least one player is always present.
            Log("Cannot find valid player", ?Level := log_level.Error)

    SetupZones<private>() : void =
        # There's only one type of delivery zone, since they don't scale by difficulty level.
        Log("Setup zones", ?Level:=log_level.Normal)
        set DeliveryZones= for (ZoneTag : DeliveryTags):
            Log("Init delivery zones", ?Level:=log_level.Normal)
            NewZone := tagged_zone_selector{}
            NewZone.InitZones(ZoneTag, false)
            NewZone
        # We use gameplay tags to select zones (represented by devices) based on their difficulty level.
        # Using an array makes it easier to modify difficulty levels: we can add more
        # levels, increase/decrease their granularity or change their order without touching the code.
        # Create one tagged_zone_selector for each difficulty level tag so all devices with the same tag (i.e. same difficulty level)
        # end up in the same selection pool.
        var Index : int = 0
        
        set PickupZones = for (ZoneTag : PickupZonesTags):
            Log("Init pickup zones", ?Level:=log_level.Normal)
            NewZone := tagged_zone_selector{}
            NewZone.InitZones(ZoneTag, false)
            ZoneLength := NewZone.GetZonesLength()
            if (set MaxPickupLevelCounts[Index] = ZoneLength):
                set Index += 1
            NewZone
           
    StartPickupDeliveryGame<private>()<suspends> : void =
        Log("Trying to start the game...", ?Level:=log_level.Normal)
        ItemTracker.AssignToAll()
        <# We construct a new countdown_timer that'll countdown from InitialCountdownTime once started.
        Also construct a new score_manager that'll keep track of the player's score and pickup level.
        The countdown_timer and score_manager require a player to show their UI to.
        We should have a valid player by now: the one that entered the vehicle, triggering the game start. #>
        if (ValidPlayer := MaybePlayer?):
            Log("Valid player, starting game...", ?Level:=log_level.Normal)

            set CountdownTimer = MakeCountdownTimer(InitialCountdownTime, ValidPlayer)
            CountdownTimer.StartCountdown()

            # We wait for the countdown to end.
            # At the same time, we also run the Pickup and Delivery game loop that constitutes the core gameplay.
            race:
                HandleCountdownEnd(ValidPlayer)
                PickupDeliveryLoop()
        else:
            Log("Cannot find valid player. Aborting game start", ?Level := log_level.Error)

    HandleCountdownEnd<private>(InPlayer : player)<suspends> : void =
        TotalTime := CountdownTimer.CountdownEndedEvent.Await()
        EndGameFailDeviceTimeout.Activate(InPlayer)


    PickupDeliveryLoop<private>()<suspends> : void =
        MaxPickupLevel := PickupZonesTags.Length - 1
        FirstPickupZoneCompletedEvent := event(){}

        var PickupLevel : int = 0
        var TotalPickupCount : int = 0
        var TotalDeliveryCount : int = 0
        var IsTotalPickupCompleted : logic = false
        var PickupLevelCounts : []int = array{0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        
        <# Defer disabling the MapIndicator so that terminating the PickupDeliveryLoop always ends up disabling the marker.
        Defer also executes if the PickupDeliveryLoop is canceled. #>
        defer:
            for(ValidPlayer : Self.GetPlayspace().GetPlayers()):
                PickupMarker.MapIndicator.DeactivateObjectivePulse(ValidPlayer)
                DeliveryMarker.MapIndicator.DeactivateObjectivePulse(ValidPlayer)
            PickupMarker.MapIndicator.Disable()
            DeliveryMarker.MapIndicator.Disable()

        PickupMarker.MapIndicator.Enable()
        DeliveryMarker.MapIndicator.Enable()
        
        var ItemNum : int = 0
        for (ZoneNum : MaxPickupLevelCounts):
            set ItemNum += ZoneNum
        ItemTracker.SetTarget(ItemNum)

        loop: 
            var IsFirstPickup : logic = true
            Log("Picked up level: {PickupLevel} ", ?Level:=log_level.Normal)
            sync: 
                block:
                    loop:
                        if (PickupZone:base_zone = PickupZones[PickupLevel].SelectNext[]):
                            Log("Get picked up zone: {PickupLevel} ", ?Level:=log_level.Normal)
                            PickupZone.ActivateZone()
                            Sleep(0.0)
                            PickupMarker.MoveMarker(PickupZone.GetTransform(), ?OverTime := 0.0)
                            for(ValidPlayer : Self.GetPlayspace().GetPlayers()):
                                PickupMarker.MapIndicator.ActivateObjectivePulse(ValidPlayer)

                            PickupZone.ZoneCompletedEvent.Await()
                            # After the first pickup we can enable the delivery zone.
                            if (IsFirstPickup?):
                                set IsFirstPickup = false
                                FirstPickupZoneCompletedEvent.Signal() 

                            if:
                                set PickupLevelCounts[PickupLevel] += 1
                            then:
                                Log("Picked up level: {PickupLevel} total: {TotalPickupCount}", ?Level:=log_level.Normal)

                            set TotalPickupCount += 1
                            if (CurrentNum := PickupLevelCounts[PickupLevel]):    
                                Log("Picked up level: {PickupLevel} current num: {CurrentNum} total: {TotalPickupCount}", ?Level:=log_level.Normal)

                            for(ValidPlayer : Self.GetPlayspace().GetPlayers()):
                                PickupMarker.MapIndicator.DeactivateObjectivePulse(ValidPlayer)

                            set MaybePlayer = PickupZone.GetPlayer()
                            #if (ValidPlayer := MaybePlayer?):
                            #    DeliveryMarker.MapIndicator.ActivateObjectivePulse(ValidPlayer)
                                            
                            <# This is the only defer we need for any PickupZone we activate. It will either deactivate the first PickupZone at the end of each outer loop,
                            or it'll deactivate any later PickupZone. That's because the expression is evaluated at the end, when the PickupZone variable has been bound to a newer zone. #>
                            defer:
                                PickupZone.DeactivateZone()

                            if (PickupLevelCounts[PickupLevel] >= MaxPickupLevelCounts[PickupLevel]):
                                Log("break the loop.", ?Level := log_level.Normal)
                                break   
                        else:
                            Log("Cannot find next PickupZone to select.", ?Level := log_level.Normal)
                            set CaptureItemCompleted = true
                            if (FirstPlayer := GetPlayspace().GetPlayers()[0]):
                                if (GuardsEliminated >= NumGuardsSpawned):
                                    EndGameVictoryDeviceDetected.Activate(FirstPlayer)
                                    Log("Game manager - Completed collect all pickup items")
                            
                                return
                            break 
                    
                block:
                    var CurrentDeliveryNum : int = 0
                    CurrentPickupLevel := PickupLevel
                    Log("Enter delivery zone: {CurrentPickupLevel} wait for first pickup item", ?Level:=log_level.Normal)
                    FirstPickupZoneCompletedEvent.Await()
                    if (DeliveryZone := DeliveryZones[CurrentPickupLevel].GetZone[0]):
                        Log("Get delivery zone: {CurrentPickupLevel} ", ?Level:=log_level.Normal)
                        DeliveryZone.ActivateZone()
                        DeliveryMarker.MoveMarker(DeliveryZone.GetTransform(), ?OverTime := 0.0)
                        
                        if (ValidPlayer := MaybePlayer?):
                            DeliveryMarker.MapIndicator.ActivateObjectivePulse(ValidPlayer)
                        loop:
                            Log("Wait for delivery zone completed event: {CurrentPickupLevel} ", ?Level:=log_level.Normal)
                            DeliveryZone.ZoneCompletedEvent.Await()
                            #set MaybePlayer = DeliveryZone.GetPlayer()
                            set TotalDeliveryCount += 1
                            set CurrentDeliveryNum += 1

                            if (FirstPlayer := GetPlayspace().GetPlayers()[0]):
                                ItemTracker.Increment(FirstPlayer)
                            Log("Current Delivered num: {CurrentDeliveryNum} total num: {TotalDeliveryCount}", ?Level:=log_level.Normal)
                            <# We remove pizzas pickups from the player inventory to avoid stacking them and having them drop to the ground once the stack is full. #>
                            if (RemovingPlayer := MaybePlayer?):
                                ItemRemover.Remove(RemovingPlayer)
                                Log("Delivery marker deactivate pulse!", ?Level:=log_level.Normal)
                                DeliveryMarker.MapIndicator.DeactivateObjectivePulse(RemovingPlayer)
                       
                            else:
                                Log("Get agent of player error!", ?Level:=log_level.Error)
                            
                            if (BonusTime : float = DeliveryBonusSeconds * PointsForPickupLevel[CurrentPickupLevel]):
                                CountdownTimer.AddRemainingTime(BonusTime)
                                
                            if (CurrentDeliveryNum >= MaxPickupLevelCounts[CurrentPickupLevel]):
                                Log("Break delivery loop!", ?Level:=log_level.Normal)
                                break

                        # We defer zone deactivation so that canceling PickupDeliveryLoop also ends up deactivating any active delivery zone.
                        defer:
                            Log("Deactivating delivery zone.", ?Level:=log_level.Normal)
                            DeliveryZone.DeactivateZone()
                    else:
                        Log("Get the delivery zone failed!", ?Level:=log_level.Normal)
                        
                    block:
                        Log("End the loop!", ?Level:=log_level.Normal)
                        # Update the pickup level
                        if (PickupLevel < MaxPickupLevel):
                            set PickupLevel += 1
                        else:
                            return