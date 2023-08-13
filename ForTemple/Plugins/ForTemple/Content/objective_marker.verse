using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /UnrealEngine.com/Temporary/Diagnostics }

objective_marker<public> := struct<concrete>:

    # The prop that will be moved
    @editable
    RootProp<public> : creative_prop = creative_prop{}

    # The child of the prop that will move with it
    @editable
    MapIndicator<public> : map_indicator_device = map_indicator_device{}

# An extension method for objective_marker
# The ? in front of OverTime specifies it as a named argument
(Marker : objective_marker).MoveMarker<public>(Transform : transform, ?OverTime : float)<suspends> : void =
    Log("Move to transform {Transform.Translation.X} {Transform.Translation.Y}", ?Level:=log_level.Normal)
    if (OverTime > 0.0):
        Marker.RootProp.MoveTo(Transform.Translation, Transform.Rotation, OverTime)
    else:
        if:
            Marker.RootProp.TeleportTo[Transform.Translation, Transform.Rotation]
        then:
            Log("Move to transform {Transform.Translation.X} {Transform.Translation.Y} finished", ?Level:=log_level.Normal)
        else:
            Log("Move to transform {Transform.Translation.X} {Transform.Translation.Y} Failed", ?Level:=log_level.Error)