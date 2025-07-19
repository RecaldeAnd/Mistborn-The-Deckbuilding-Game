function onLoad()
    params = {
        click_function = "click_func",
        function_owner = self,
        label          = "RAW Start",
        position       = {0, 1, 0},
        rotation       = {0, 180, 0},
        width          = 1400,
        height         = 500,
        font_size      = 200,
        color          = {1.0, 1.0, 1.0},
        font_color     = {0, 0, 0},
        press_color    = {0, 1, 0},
        tooltip        = "Starts game with random characters and random missions",
    }
    self.createButton(params)
end

-- Use Alt-Click to just spawn decks all decks and pieces and let user choose
-- how to setup the game.
function click_func(obj, color, alt_click)
    local main_deck, mission_deck, character_deck = spawn_decks(alt_click);
    assign_characters_and_spawn_pieces(main_deck, mission_deck, character_deck); 
end

function spawn_decks(is_custom_start)
    -- TODO - make sure you don't clone the main deck, character deck, and mission deck
    local main_deck = create_and_spawn_main_deck();
    local mission_deck, character_deck = spawn_mission_and_character_decks(is_custom_start);
    return main_deck, mission_deck, character_deck;
end

function create_and_spawn_main_deck()
    local ally_deck   = getObjectFromGUID(get_ally_deck_GUID()  );
    local action_deck = getObjectFromGUID(get_action_deck_GUID());
    local global_tags = Global.getSnapPoints();
    
    local main_deck_snap_point = get_snap_points_with_tag(global_tags, "Main Deck")[1]; -- Should just be an array with 1 object
    local main_deck_position   = main_deck_snap_point.position;
    local main_deck_rotation   = main_deck_snap_point.rotation;

    action_deck.setLock(false);
    ally_deck.setLock(false);

    local main_deck   = action_deck.putObject(ally_deck);
    main_deck.setName("Main Deck");
    main_deck.removeTag("Action");
    main_deck.setPosition(main_deck_position + vector(0, 1, 0)); -- +1 in y to avoid table clipping
    main_deck.setRotation(main_deck_rotation);

    shuffle_deck(main_deck);

    return main_deck;
end

function spawn_mission_and_character_decks(is_custom_start)
    local mission_deck   = getObjectFromGUID(get_mission_deck_GUID());
    local character_deck = getObjectFromGUID(get_character_deck_GUID());

    if is_custom_start then
        local mission_deck_position   = {-15.26, 1.50,  0.01};
        local character_deck_position = {-21.13, 1.50,  0.05};

        mission_deck  .setLock(false);
        character_deck.setLock(false);

        mission_deck  .setPosition(mission_deck_position  );
        character_deck.setPosition(character_deck_position);
    end

    shuffle_deck(mission_deck);
    shuffle_deck(character_deck);

    return mission_deck, character_deck;
end

-- This most certainly is going to need the character deck and mission
-- deck passed into it
function assign_characters_and_spawn_pieces(main_deck, mission_deck, character_deck)
    -- Consider renaming the character based keys as just the character name
    -- so you can make a function that just loops through searching for names as keys
    local donor_metal_tokens    = get_objects_from_guids_map(get_donor_metal_token_GUIDS()  );
    local health_trackers       = get_objects_from_guids_map(get_health_tracker_GUIDS()     );
    local starter_decks         = get_objects_from_guids_map(get_starter_deck_GUIDS()       );
    local donor_markers         = get_objects_from_guids_map(get_donor_marker_GUIDS()       );
    local donor_training_track  = getObjectFromGUID(         get_doner_training_track_GUID());
    local global_tags           = Global.getSnapPoints();
    local players               = Player.getPlayers();

    -- Assign characters to players and put the players in the appropriate seat
    local assigned_characters = assign_and_set_character_cards(character_deck, players);
    local missions_array      = setup_mission_tracks(mission_deck, global_tags);

    local training_tracks = {};

    -- Loop through the assign characters and spawn all their pieces in the correct positions
    for name,_ in pairs(assigned_characters) do
        training_tracks[name] = setup_training_track(name, global_tags, donor_training_track, donor_metal_tokens, donor_markers[name]);
        setup_mission_tracker_markers(name, missions_array, donor_markers);
        setup_health_dial_and_starter_deck(name, global_tags, health_trackers, starter_decks);
    end

    local mission_track_buttons = expose_mission_buttons();

    -- Wait for 1 second for cards to settle before locking them in place
    -- Comment this out to see if its necessary with new deck acquiring algo
    Wait.time(function() lock_pieces_that_should_not_move(assigned_characters, training_tracks, missions_array, mission_track_buttons) end, 1);
end

function assign_and_set_character_cards(character_deck, players)
    local assigned_character_cards      = {};
    local character_card                = {};
    local global_tags                   = Global.getSnapPoints();
    local character_card_snap_points    = get_snap_points_with_tag(global_tags, "Character Card");
    local character_card_point          = {};
    local character_card_point_position = {};
    local character_card_point_rotation = {};
    local character_card_color_map      = get_character_card_name_to_color_map();
    local last_character_card = nil;

    for _, current_player in ipairs(players) do
        -- Draw card from character card deck
        if last_character_card == nil then
            character_card      = character_deck.takeObject({position = {0, 0, 0}});
            -- remainder only return a card if it'd be the last card in the deck
            last_character_card = character_deck.remainder;
        else
            character_card = last_character_card;
        end
        -- Get the character card and snap point data
        local card_name      = character_card.getName();
        local character_name = string.sub(card_name, 1, -16); -- Should remove the back 15 characters thus removing " Character Card"
        character_card_point = get_snap_points_with_tag(character_card_snap_points, character_name)[1]; -- Indexing 1 because it should just be 1 point
        character_card_point_position = character_card_point.position;
        character_card_point_rotation = character_card_point.rotation;

        -- Put the character card in game ready state
        character_card.flip();
        character_card.setPosition(character_card_point_position);
        character_card.setRotation(character_card_point_rotation);

        -- Put the player in the seat that corresponds with the character's color
        print(current_player)
        local character_color = character_card_color_map[card_name];
        print(character_color)
        if Player[character_color].seated == false then
            current_player.changeColor(character_color);
        else
            Player[character_color].changeColor("Grey");
            current_player.changeColor(character_color);
        end
        
        -- Map the character names to the character cards
        assigned_character_cards[character_name] = character_card;
    end

    return assigned_character_cards
end

function lock_pieces_that_should_not_move(assigned_characters, training_tracks, missions_array, mission_track_buttons) 
    for name,_ in pairs(assigned_characters) do
        assigned_characters[name].setLock(true);
        training_tracks[name]    .setLock(true);
    end

    for i=1,3 do
        missions_array[i].setLock(true); -- Could just explicitly write [1], [2], [3] instead of loop
    end

    for _,button in pairs(mission_track_buttons) do
        button.setLock(true);
    end

    print("LLLLLLLLLET'S PLAY!");
end

-- If you replace tags on snap points or remove and replace a snap point to move it, it will mess up the
-- spawn of the mission cards because the mission_deck is sitting on a "mission_tracker" snap point
function setup_mission_tracks(mission_deck, global_tags)
    local mission_snap_points = get_snap_points_with_tag(global_tags, "Mission Tracker");
    local missions_array      = {};
    for i=1,3 do
        mission_card = mission_deck.takeObject({position = {0, 0, 0}});

        mission_card.setPosition(mission_snap_points[i].position);
        mission_card.setRotation(mission_snap_points[i].rotation);

        missions_array[i] = mission_card;
    end

    return missions_array;
end

function setup_training_track(character_name, global_tags, donor_training_track, donor_metal_tokens, donor_marker)
    local character_snap_points   = get_snap_points_with_tag(global_tags, character_name);
    local training_track_position = get_snap_points_with_tag(character_snap_points, "Training Track")[1].position; -- Should only be 1 snap point at this point
    local training_track_rotation = get_snap_points_with_tag(character_snap_points, "Training Track")[1].rotation; -- Should only be 1 snap point at this point

    local training_track = donor_training_track.clone();
    training_track.setLock(false);
    training_track.setPosition(training_track_position);
    training_track.setRotation(training_track_rotation);

    set_up_metal_tokens(character_name, training_track, donor_metal_tokens);
    set_up_marker(character_name, training_track, donor_marker);
    
    return training_track;
end

function set_up_metal_tokens(character_name, training_track, donor_metal_tokens)
    local training_track_snap_points = training_track.getSnapPoints();
    local metal_token                = {};
    local metal_token_point          = {};

    for metal, token in pairs(donor_metal_tokens) do
        metal_token_point    = get_snap_points_with_tag(training_track_snap_points, metal)[1]; -- Indexing here because it should just be one point
        metal_token          = token.clone();
        metal_token.setLock(false);
        -- positionToWorld is important bc the snap point position is relative to the tracker, 
        -- vector(0,1,0) is to prevent spawn collision with tracker board
        metal_token.setPosition(training_track.positionToWorld(metal_token_point.position) + vector(0,1,0));
        -- If you don't have an if statement for a side of the board as below, 2 people will end
        -- up with upside down metal tokens
        if character_name == "Marsh" or character_name == "Shan" then
            metal_token.setRotation(metal_token_point.rotation);
        end
    end
end

function set_up_marker(character_name, training_track, donor_marker)
    local training_track_snap_points = training_track.getSnapPoints();
    local first_marker_snap_point = get_snap_points_with_tag(training_track_snap_points, "Marker")[1]; -- pre-index for the first marker position
    local marker                  = donor_marker.clone();
    marker.setLock(false);
    -- positionToWorld is important bc the snap point position is relative to the tracker, 
    -- vector(0,1,0) is to prevent spawn collision with tracker board
    marker.setPosition(training_track.positionToWorld(first_marker_snap_point.position) + vector(0,1,0));
    -- Unimportant if that would prevent the marker from spinning when lifted for these 2 characters
    if character_name == "Kelsier" or character_name == "Vin" then
        marker.setRotation(first_marker_snap_point.rotation + vector(0,180,0));
    else
        marker.setRotation(first_marker_snap_point.rotation);
    end
end

function setup_mission_tracker_markers(character_name, missions_array, donor_markers)
    local mission_card              = {};
    local mission_track_snap_points = {};
    local starting_positions        = {};
    local character_starting_point  = {};
    local position_on_card          = {};
    local rotation                  = {};
    local marker_name               = get_character_marker_name_map()[character_name];
    local markers                   = {
        donor_markers[character_name].clone(),
        donor_markers[character_name].clone(),
        donor_markers[character_name].clone()
    };


    for i=1,#missions_array do
        mission_card                     = missions_array[i];
        mission_track_snap_points        = mission_card.getSnapPoints();
        character_marker_snap_points     = get_snap_points_with_tag(mission_track_snap_points, marker_name);
        character_marker_starting_point  = get_snap_points_with_tag(character_marker_snap_points, "Starting Position")[1]; -- Should just be 1 point that has "Starting Position" and target character name
        position_on_card                 = mission_card.positionToWorld(character_marker_starting_point.position);
        rotation                         = character_marker_starting_point.rotation
        
        markers[i].setLock(false);
        markers[i].setPosition(position_on_card + vector(0,1,0)); -- +1 in y to avoid spawn collision
        markers[i].setRotation(rotation + vector(0,90,0));        -- +90 degrees because it "needed" it

        organize_mission_card_snap_points(mission_card, character_marker_snap_points, markers[i]);
    end
end

function setup_health_dial_and_starter_deck(character_name, global_tags, health_trackers, starter_decks)
    local health_tracker = health_trackers[character_name];
    local starter_deck   = starter_decks[character_name];

    local health_tracker_snap_points     = get_snap_points_with_tag(global_tags, "Health Tracker");
    local character_health_tracker_point = get_snap_points_with_tag(health_tracker_snap_points, character_name)[1]; -- Index 1 because it should be an array with one item

    local starter_deck_snap_points     = get_snap_points_with_tag(global_tags, "Starter Deck");
    local character_starter_deck_point = get_snap_points_with_tag(starter_deck_snap_points, character_name)[1];   -- Index 1 because it should be an array with one item

    health_tracker.setLock(false);
    health_tracker.setPosition(character_health_tracker_point.position + vector(0, 3, 0)); -- 3 in y because it needs to be on player character card
    health_tracker.setRotation(character_health_tracker_point.rotation);

    starter_deck.setLock(false);
    starter_deck.setPosition(character_starter_deck_point.position + vector(0, 1, 0));
    starter_deck.setRotation(character_starter_deck_point.rotation);

    shuffle_deck(starter_deck);
end

-- THE FOLLOWING ASSUMES THE SNAP POINTS ARE IN ORDER, if not, uncomment sorting code
function organize_mission_card_snap_points(mission_card, snap_points_for_character, marker)
    marker.setVar("track_position", 1);
    local all_mission_track_snap_points = mission_card.getSnapPoints();
    -- We can get index 1 of the four points below because there should only
    -- be one of each
    -- TODO: When importing the newly scanned assets for the mission cards, give
    -- the victory row the "victory row" tag and just get and store that array here
    local victory_row_first             = get_snap_points_with_tag(all_mission_track_snap_points, "First Place")[1];
    local victory_row_second            = get_snap_points_with_tag(all_mission_track_snap_points, "Second Place")[1];
    local victory_row_third             = get_snap_points_with_tag(all_mission_track_snap_points, "Third Place")[1];
    local victory_row_fourth            = get_snap_points_with_tag(all_mission_track_snap_points, "Fourth Place")[1];
    -- assuming the Starting Position is index 1 as logging has shown
    -- local starting_position = table.remove(snap_points_for_character, 1);

    --[[
    table.sort(snap_points_for_character, function(left, right)
        return left.position.z > right.position.z;
    end);
    ]]
    -- There are 13 snap points per marker, 1 starting position specific to the marker,
    -- 4 different end points that can each hold 1 marker (12th row), and the 11 rows between.
    -- Store the starting position in the empty 12th slot
    --snap_points_for_character[12] = starting_position;

    mission_card.setTable(marker.getName(), snap_points_for_character);
    mission_card.setTable("victory_row_snap_points", {victory_row_first, victory_row_second, victory_row_third, victory_row_fourth});
    mission_card.setTable("victory_row_occupied_pos", {nil, nil, nil, nil});
    marker      .setVar("mission_card", mission_card);
end

function expose_mission_buttons()
    local mission_track_buttons = get_objects_from_guids_map(get_mission_button_GUIDS());

    -- This should go through all the mission buttons, release them from the table
    -- and make the button clickable
    for _,button in pairs(mission_track_buttons) do
        button.setLock(false);
        button.flip();
    end

    return mission_track_buttons;
end
----------------------- REUSABLE HELPER FUNCTIONS -----------------------
function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+i] = t2[i]
    end
    return t1
end

function get_snap_points_with_tag(snap_points, target_tag)
    -- Add all snap points that have the target tag into target_snaps table
    local target_snaps = {};
    for i=1,#snap_points do
        local curr_snap = snap_points[i];
        if search_for_tag(curr_snap.tags, target_tag) then
            target_snaps[#target_snaps + 1] = curr_snap;
        end
    end

    return target_snaps;
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

function get_objects_from_guids_map(guids_map)
    for key, value in pairs(guids_map) do
        guids_map[key] = getObjectFromGUID(value);
    end

    return guids_map; -- This is actually a map of name to object, not guid
end

function shuffle_deck(deck)
    deck.randomize();
    deck.randomize();
    deck.randomize();
    deck.randomize();
    deck.randomize();
    deck.randomize();
end
-- ************************** DATA TABLES ************************* --
-- These need set manually everytime the deck or object is replaced
function get_action_deck_GUID()
    return '6c8baf'; -- eaa3a6 'bbdb7c';
end

function get_ally_deck_GUID()
    return 'f97506'; -- b6d519 'cbbbaa';
end

function get_character_deck_GUID()
    return 'de0a91';
end

function get_mission_deck_GUID()
    return '92874a';
end

function get_character_card_name_to_color_map()
    return {
        ["Vin Character Card"    ]  = "Red",
        ["Shan Character Card"   ]  = "Purple",
        ["Kelsier Character Card"]  = "Blue",
        ["Marsh Character Card"  ]  = "Yellow"
    }
end

function get_donor_metal_token_GUIDS()
    return {
        ["Pewter Token"]             = '314dea',
        ["Tin Token"   ]             = '66d0e9',
        ["Bronze Token"]             = '487fec',
        ["Copper Token"]             = 'd47f53',
        ["Zinc Token"  ]             = 'b9061b',
        ["Brass Token" ]             = '35a8cb',
        ["Iron Token"  ]             = 'db01d0',
        ["Steel Token" ]             = '4b8cbb'
    }
end

function get_health_tracker_GUIDS()
    return {
        ["Vin"     --[[Health Tracker]]]   = 'c7bb7b',
        ["Shan"    --[[Health Tracker]]]   = '1bacbb',
        ["Kelsier" --[[Health Tracker]]]   = '437522',
        ["Marsh"   --[[Health Tracker]]]   = '52e800'
    }
end

function get_starter_deck_GUIDS()
    return {
        ["Vin"     --[[Starter Deck]]]     = 'aa8271', --'2dfb86', --'013560',
        ["Shan"    --[[Starter Deck]]]     = '54205c', --'02a1d6', --'4fda84',
        ["Kelsier" --[[Starter Deck]]]     = '93a859', --'286310', --'20bf13',
        ["Marsh"   --[[Starter Deck]]]     = '450e48', --'071e2a', --'f3b1a6'
    }
end

function get_donor_marker_GUIDS()
    return {
        ["Vin"     --[[Marker]]]           = 'a6c65d',
        ["Shan"    --[[Marker]]]           = '541161',
        ["Kelsier" --[[Marker]]]           = '586779',
        ["Marsh"   --[[Marker]]]           = '8e6354'
    }
end

function get_doner_training_track_GUID()
    return 'a5ebe7';
end

function get_character_marker_name_map()
    return {
        ["Vin"    ]           = "Red Marker",
        ["Shan"   ]           = "Purple Marker",
        ["Kelsier"]           = "Blue Marker",
        ["Marsh"  ]           = "Yellow Marker"
    }
end

function get_mission_button_GUIDS()
    return {
        ["Left Mission Up"    ] = 'aeb75d',
        ["Left Mission Down"  ] = '67a699',
        ["Middle Mission Up"  ] = 'ec48d9',
        ["Middle Mission Down"] = 'a337b6',
        ["Right Mission Up"   ] = 'e636ad',
        ["Right Mission Down" ] = 'fa2809',
    }
end