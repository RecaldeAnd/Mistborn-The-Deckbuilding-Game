function onObjectLeaveContainer(container, object)
    -- When the boxing leaves this container (infinite bag), I want to scale it
    -- in half in the y direction so its more flat like a coin. Also doing this
    -- because scaling it in the y with the gizmo won't persist across reload
    -- or save in Save Object.
    if container.getName() == "Boxing Bag" then
        object.scale({x=1, y=1/2, z=1})
    end
end