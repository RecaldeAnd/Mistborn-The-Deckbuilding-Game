function onLoad()
    params = {
        click_function = "click_func",
        function_owner = self,
        label          = "⇑",
        position       = {0, 0, 0},
        rotation       = {0, 180, 0},
        width          = 130,
        height         = 250,
        scale          = {2, 2, 2},
        font_size      = 200,
        color          = {1.0, 1.0, 1.0},
        font_color     = {0, 0, 0},
        press_color    = {0, 1, 0},
        tooltip        = "+1",
    }
    self.createButton(params)
end

function click_func(obj, color, alt_click) 
    local scripting_zone           = getObjectFromGUID('aca294');
    local zone_objects             = scripting_zone.getObjects();
    local color_to_marker_name_map = get_color_to_marker_name_map();
    -- TODO: 
    -- NICE TO HAVE, set up a permanent variable that is reset on turns that makes a ghost of the
    -- marker for where it started that turn... likely will be tied to turn script and not this one
    local mission_card             = {};
    local player_marker            = {};

    -- Get the marker for the player that clicked the button
    for _,value in pairs(zone_objects) do
        if value.getName() == color_to_marker_name_map[color] then
            player_marker = value;
            break;
        end
    end

    mission_card = player_marker.getVar("mission_card");

    -- Get the mission card's snap points and next position the marker needs to go
    local mission_card_snap_points     = mission_card.getTable(player_marker.getName());
    local player_marker_track_position = player_marker.getVar("track_position");
    local next_track_pos               = player_marker_track_position + 1;
    
    if next_track_pos <= #mission_card_snap_points then      
        local next_local_pos            = mission_card_snap_points[next_track_pos].position;
        local next_world_pos            = mission_card.positionToWorld(next_local_pos);
        -- Ensure the block is always touching the top surface of the mission card
        local next_world_pos_adjusted_y = {next_world_pos.x, player_marker.getPosition().y, next_world_pos.z}

        player_marker.setPositionSmooth(next_world_pos_adjusted_y);
        player_marker.setVar("track_position", next_track_pos);
    elseif next_track_pos == #mission_card_snap_points + 1 then
        -- Get victory_row data for use later
        local victory_row_snap_points        = mission_card.getTable("victory_row_snap_points");
        local victory_row_occupied_positions = mission_card.getTable("victory_row_occupied_pos");
        
        -- iterate through all victory row positions looking for the first open slot
        for i=1,4 do 
            if victory_row_occupied_positions[i] == nil then
                local victory_row_pos_local = victory_row_snap_points[i].position;
                local victory_row_pos_world = mission_card.positionToWorld(victory_row_pos_local);
                local marker_final_position = {victory_row_pos_world.x, player_marker.getPosition().y, victory_row_pos_world.z};
                player_marker.setPositionSmooth(marker_final_position);

                -- Update Data
                victory_row_occupied_positions[i] = player_marker;
                mission_card.setTable("victory_row_occupied_pos", victory_row_occupied_positions);
                player_marker.setVar("track_position", next_track_pos);
                break;
            end
        end
    end
end

function get_color_to_marker_name_map()
    return {
        ["Red"   ]           = "Vin Marker",
        ["Purple"]           = "Shan Marker",
        ["Blue"  ]           = "Kelsier Marker",
        ["Yellow"]           = "Marsh Marker"
    };
end