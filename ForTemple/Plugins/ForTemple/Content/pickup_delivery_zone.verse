
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

<# A zone is an area of the map (represented by a device) that can be Activated/Deactivated and that provides events
to signal when the zone has been "Completed" (can't be completed anymore until next activation).
Zone "Completed" depends on the device type (ActivatorDevice) for the zone.
Suggested usage: ActivateZone() -> ZoneCompletedEvent.Await() -> DeactivateZone() #>
base_zone<public> := class:
    ActivatorDevice<public> : creative_object_interface
    ZoneCompletedEvent<public> : event(base_zone) = event(base_zone){}
    var MaybePlayer<private> : ?player = false

    GetTransform<public>() : transform =
        ActivatorDevice.GetTransform()

    <# Activates the Zone.
    You should enable devices and any visual indicators for the zone here. #>
    ActivateZone<public>() : void =
        # The base zone can handle zones defined as item spawners or capture areas.
        # Try and cast to each type to see which we're dealing with.
        if (CaptureArea := capture_area_device[ActivatorDevice]):
            CaptureArea.Enable()
            CaptureArea.AllowCapture()
            CaptureArea.ItemIsDeliveredEvent.Subscribe(HandleItemDelivered)
            #spawn { WaitForZoneCompleted(option{CaptureArea.ItemIsDeliveredEvent}) }
        else if (ItemSpawner := capture_item_spawner_device[ActivatorDevice]):
            ItemSpawner.Enable()
            ItemSpawner.ItemPickedUpEvent.Subscribe(HandleItemPickedUp)
            spawn { WaitForZoneCompleted(option{ItemSpawner.ItemPickedUpEvent}) }
        else if (ItemSpawner := item_spawner_device[ActivatorDevice]):
            ItemSpawner.Enable()
            ItemSpawner.ItemPickedUpEvent.Subscribe(HandleItemPickedUp)
            spawn { WaitForZoneCompleted(option{ItemSpawner.ItemPickedUpEvent}) }
   
    <# Deactivates the Zone.
    You should disable devices and any visual indicators for the zone here. #>
    DeactivateZone<public>() : void =
        if (CaptureArea := capture_area_device[ActivatorDevice]):
            CaptureArea.Disable()
            CaptureArea.DisallowCapture()
        else if (ItemSpawner := capture_item_spawner_device[ActivatorDevice]):
            ItemSpawner.Disable()
        else if (ItemSpawner := item_spawner_device[ActivatorDevice]):
            ItemSpawner.Disable()
        ZoneDeactivatedEvent.Signal()
    
    GetPlayer<public>() : ?player =
        return MaybePlayer

    <# This event is necessary to terminate the WaitForZoneCompleted coroutine if the zone is deactivated without being completed. #>
    ZoneDeactivatedEvent<protected> : event() = event(){}

    WaitForZoneCompleted<private>(ZoneDeviceCompletionEventOpt : ?awaitable(agent))<suspends> : void =
        if (DeviceEvent := ZoneDeviceCompletionEventOpt?):
            Log("Wait For ZoneCompleted!", ?Level:=log_level.Normal)
            race:
                block:
                    DeviceEvent.Await()
                    Log("An event of zone coming!", ?Level:=log_level.Normal)
                    ZoneCompletedEvent.Signal(Self)
                ZoneDeactivatedEvent.Await()

    HandleItemDelivered<private>(DeliveryPlayer : agent) : void =
        set MaybePlayer = option{player[DeliveryPlayer]}
        ZoneCompletedEvent.Signal(Self)
        Log("Handle Item Delivered event!", ?Level:=log_level.Normal)

    HandleItemPickedUp<private>(DeliveryPlayer : agent) : void =
        set MaybePlayer = option{player[DeliveryPlayer]}
        #ZoneCompletedEvent.Signal(Self)
        Log("Handle Item PickedUp event!", ?Level:=log_level.Normal)

MakeBaseZone<constructor><public>(InActivatorDevice : creative_object_interface) := base_zone:
    ActivatorDevice := InActivatorDevice

# The tagged_zone_selector creates zones based on triggers tagged with the tag passed to InitZones.
tagged_zone_selector<public> := class:
    var Zones<protected> : []base_zone = array{}
    var Index<protected> : int = 0

    InitZones<public>(ZoneTag : tag, IsEnable : logic) : void =
        Log("Init Zones!", ?Level:=log_level.Normal)
        <# On creation of a zone selector, find all available zones
        and cache them so we don't consume time searching for tagged devices
        every time the next zone is selected. #>
        ZoneDevices := GetCreativeObjectsWithTag(ZoneTag)
        set Zones = for (ZoneDevice : ZoneDevices):
            if (IsEnable?):
                if (CaptureArea := capture_area_device[ZoneDevice]):
                    CaptureArea.Enable()
                else if (ItemSpawner := capture_item_spawner_device[ZoneDevice]):
                    ItemSpawner.Enable()
                else if (ItemSpawner := item_spawner_device[ZoneDevice]):
                    ItemSpawner.Enable()
            else:
                if (CaptureArea := capture_area_device[ZoneDevice]):
                    Log("CaptureArea disabled!", ?Level:=log_level.Normal)
                    CaptureArea.Disable()
                else if (ItemSpawner := capture_item_spawner_device[ZoneDevice]):
                    ItemSpawner.Disable()
                else if (ItemSpawner := item_spawner_device[ZoneDevice]):
                    ItemSpawner.Disable()
            MakeBaseZone(ZoneDevice)

    RandomSelectNext<public>()<transacts><decides> : base_zone =
        Zones[GetRandomInt(0, Zones.Length-1)]

    GetZone<public>(ZoneIndex : int)<transacts><decides> : base_zone =
        Zones[ZoneIndex]

    SelectNext<public>()<transacts><decides> : base_zone =
        if (Index = Zones.Length):
           set Index = 0
        else:
            set Index += 1
        Zones[Index-1]


    GetZonesLength<public>() : int =
        Zones.Length
    
    GetZones<public>()<transacts><decides> :  []base_zone =
        Zones
    