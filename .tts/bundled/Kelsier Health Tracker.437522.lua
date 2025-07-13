-- Universal Counter Tokens      starter code by: MrStump
-- Scale and position adapted by kensuaga
-- Scale, position, and display altered by RecaldeAnd

--Center positions for the buttons
    posX = 0.02;
    posY = 0.1;
    posZ = 0.03;

--Scale of the buttons
    scale1 = 0.65;
    scale2 = 1.75;



-- Do not change anything below these line unless you know what you are doing.

--Saves the count value into a table (data_to_save) then encodes it into the Tabletop save
function onSave()
    local data_to_save = {saved_count = count};
    saved_data = JSON.encode(data_to_save);
    return saved_data;
end

--Loads the saved data then creates the buttons
function onload(saved_data)
    generateButtonParamiters();
    --Checks if there is a saved data. If there is, it gets the saved value for 'count'
    if saved_data != '' then
        local loaded_data = JSON.decode(saved_data);
        count = loaded_data.saved_count;
    else
        --If there wasn't saved data, the default value is set to default starter health 36.
        count = 36;
    end

    --Generates the buttons after putting the count value onto the 'display' button
    self.createButton(b_display_digit_1);
    self.createButton(b_display_digit_2);
    self.createButton(b_plus);
    self.createButton(b_minus);
    self.createButton(b_plus5);
    self.createButton(b_minus5);
    updateDisplay();
end

--Activates when + is hit. Adds 1 to 'count' then updates the display button.
function increase()
    count = count + 1;
    updateDisplay();
end

--Activates when - is hit. Subtracts 1 from 'count' then updates the display button.
function decrease()
    --Prevents count from going below 0
    count = count - 1;
    updateDisplay();
end

--Activates when + is hit. Adds 5 to 'count' then updates the display button.
function increase5()
    count = count + 5;
    updateDisplay();
end

--Activates when - is hit. Subtracts 5 from 'count' then updates the display button.
function decrease5()
    --Prevents count from going below 0
    count = count - 5;
    updateDisplay();
end

function get_digits_from_count()
    local second_digit = count % 10;
    local first_digit  = math.floor(count / 10);

    return first_digit, second_digit;
end

-- This actually is not set to execute since the button associated with 
-- this has a width and height of 0
function customSet()
    local description   = self.getDescription();
    local health_number = string.sub(description, 8);
    if description != '' and type(tonumber(description)) == 'number' then
        count = tonumber(description);
        updateDisplay();
        return;
    end

    if health_number != '' and type(tonumber(health_number)) == 'number' then
        count = tonumber(health_number);
        updateDisplay();
        return;
    end
end

--function that updates the display. I trigger it whenever I change 'count'
function updateDisplay()
    -- Max Health in game is 40, run check and set value here
    -- since this is always called
    if count > 40 then
        count = 40;
    end

    if count < 0 then
        count = 0;
    end

    local digit_1, digit_2 = get_digits_from_count();

    b_display_digit_1.label = tostring(digit_1);
    b_display_digit_2.label = tostring(digit_2);
    self.editButton(b_display_digit_1);
    self.editButton(b_display_digit_2);
    -- useful if customSet function comes into use
    -- self.setDescription("Health: " .. tostring(count));
end



--This is activated when onload runs. This sets all paramiters for our buttons.
--I do not have to put this all into a function, but I prefer to do it this way.
function generateButtonParamiters()
    b_display_digit_1 = {
        index = 1, click_function = 'customSet', function_owner = self, label = '3',
        position = {posX - 0.35, posY, posZ}, width = 0, height = 0, font_size = 500,
        font_color = {1,1,1}, scale = {scale1,scale1,scale1}
    };
    b_display_digit_2 = {
        index = 0, click_function = 'customSet', function_owner = self, label = '6',
        position = {posX + 0.35, posY, posZ}, width = 0, height = 0, font_size = 500,
        font_color = {1,1,1}, scale = {scale1,scale1,scale1}
    };
    b_plus = {
        click_function = 'increase', function_owner = self, label =  '+1',
        position = {posX + 0.9*scale2, posY, posZ + 0.26*scale2},
        width = 175, height = 300, font_size = 100, scale = {scale2,scale2,scale2}
    };
    b_minus = {
        click_function = 'decrease', function_owner = self, label =  '-1',
        position = {posX + -0.9*scale2, posY, posZ + 0.26*scale2},
        width = 175, height = 300, font_size = 100, scale = {scale2,scale2,scale2}
    };
    b_plus5 = {
        click_function = 'increase5', function_owner = self, label =  '+5',
        position = {posX + 0.9*scale2, posY, posZ + -0.29*scale2},
        width = 175, height = 230, font_size = 100, scale = {scale2,scale2,scale2}
    };
    b_minus5 = {
        click_function = 'decrease5', function_owner = self, label =  '-5',
        position = {posX + -0.9*scale2, posY, posZ + -0.29*scale2},
        width = 175, height = 230, font_size = 100, scale = {scale2,scale2,scale2}
    }
end
