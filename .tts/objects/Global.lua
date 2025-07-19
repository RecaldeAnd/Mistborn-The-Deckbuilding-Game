--[[ Lua code. See documentation: https://api.tabletopsimulator.com/ --]]

--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
    --[[ print('onLoad!') --]]
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate()
    --[[ print('onUpdate loop!') --]]
end

function onPlayerAction(player, action, targets)
    local marker_objects = {};
    for _,target in pairs(targets) do
        if target.type == "Block" then
            table.insert(marker_objects, target);
        end
    end

    if #marker_objects < 1 then
        return true;
    end

    if action == Player.Action.Select or action == Player.Action.PickUp then
        for _,marker in pairs(marker_objects) do
            if not search_for_tag(marker.getTags(), player.color .. " Marker") then
                log("You cannot move a marker that is not your color");
                return false;
            end
        end
    end

    return true;
end

function search_for_tag(tags, target_tag)
    for i=1,#tags do
        local curr_tag = tags[i];
        if curr_tag == target_tag then
            return true;
        end
    end

    return false;
end