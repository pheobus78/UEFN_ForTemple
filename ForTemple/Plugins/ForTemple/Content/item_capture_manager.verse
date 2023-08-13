
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

item_capture_manager := class(creative_device):

    @editable
    CaptureItemSpawner:capture_item_spawner_device = capture_item_spawner_device{}
    @editable
    CaptureItemIndicator:creative_prop = creative_prop{}
    @editable
    UpdateRateSeconds:float = 0.033
    @editable
    VerticalOffset:float = 180.0

    OnBegin<override>()<suspends>:void=
        CaptureItemSpawner.ItemPickedUpEvent.Subscribe(OnItemGrabbed)
   
    OnItemGrabbed(InAgent:agent):void=
        Log("Objective Captured", ?Level:=log_level.Normal)
        if(FortCharacter := InAgent.GetFortCharacter[]):
            spawn{FollowCharacter(FortCharacter)}

    FollowCharacter(FortCharacter:fort_character)<suspends>:void=
        Log("Spawned FollowCharacter function", ?Level:=log_level.Normal)
        race:
            loop:
                Transform := FortCharacter.GetTransform()
                if:
                    CaptureItemIndicator.TeleportTo[Transform.Translation + vector3{Z := VerticalOffset}, Transform.Rotation]
                Sleep(UpdateRateSeconds)
            CaptureItemSpawner.ItemCapturedEvent.Await()
            CaptureItemSpawner.ItemDroppedEvent.Await()
            FortCharacter.EliminatedEvent().Await()

        Sleep(UpdateRateSeconds)
        Log("Objective dropped or captured", ?Level:=log_level.Normal)
        SpawnerTransform := CaptureItemSpawner.GetTransform()
        if:
            # Teleport back to spawner
            CaptureItemIndicator.TeleportTo[SpawnerTransform.Translation + vector3{Z := VerticalOffset * -10}, SpawnerTransform.Rotation]
        else:
            Log("Returned Beacon to capture spawner", ?Level:=log_level.Normal)