marioWidth = 16
marioHeight = 32

-- 0x0087/B
-- 0x00CF-0x00D3

-- Tile positions
local tiles_start_addr = 0x0500
local tiles_half_addr = 0x05cf
local tiles_final_addr = 0x069F
local tiles_count = tiles_final_addr - tiles_start_addr + 1

-- Converts tile number to pixel number
-- Each tile is drawn on page of 208 tiles, 32 columns
-- Tiles are drawn on two pages: 0x0500 to 0x05cf and 0x05cf to 0x069F
-- Pages are swapped while mario is running, so we are seeing page 1, page 2, page 1, etc...
function tile2px(tilenum, screenpos, current_page)
  if tilenum < 0 or tilenum >= 0x1A0 then
    return false;
  end;

  page_size = 208
  page = math.floor(tilenum / page_size)
  page_x = math.fmod(tilenum, page_size) 
  tile_x = math.fmod(page_x, 0x10) * 0x10 + page * 0x100 + math.floor(current_page / 2) * 0x200 - screenpos

  if tilenum < tiles_count / 2 and math.fmod(current_page, 2) == 1 then
  	tile_x = tile_x + 0x200
  end

  py = math.floor(math.fmod(tilenum, page_size) / 0x10) * 0x10 + 0x20
  -- print(tilenum, screenpos, px)

  returnval = {x = tile_x, y = py};
  return returnval;
end;

n_clock = 0
last_mario_pos_x = 0
speed = {}
jump_frames_timer = 0

function everyframe()
	-- Enable invincibility
	memory.writebyte(0x79F, 10)

	-- Measure time
	elapsed_time = os.clock() - n_clock
	n_clock = os.clock()

	-- Measure speed
	mario_x = memory.readbyte(0x0086) + memory.readbyte(0x006D) * 256
	diff_x = math.abs(last_mario_pos_x - mario_x)
	last_mario_pos_x = mario_x

	speed_x = diff_x / elapsed_time -- Pixels/second
	measured_frames = 10

	if #speed < measured_frames then
		speed[#speed + 1] = speed_x
	else
		new_speed = {}
		for i = 1, measured_frames - 1 do
			new_speed[i] = speed[i + 1]
		end
		new_speed[measured_frames] = speed_x
		speed = new_speed
	end

	speed_average = 0
	for i = 1, #speed do
		speed_average = speed_average + speed[i]
	end
	speed_average = speed_average / #speed

	-- Predictions

	screenOffsetRel = memory.readbyte(0x071C)
    screenOffsetMult = memory.readbyte(0x071A)
    screenOffset = screenOffsetRel + screenOffsetMult * 256

    mario_pixel_x = mario_x - screenOffset
    marioY = memory.readbyte(0xCE)

    -- Tiles

    tiles_map = {}

    tiles_map_px = {}
    for i=1,256 do
      tiles_map_px[i] = {}
      for j=1,256 do
        tiles_map_px[i][j] = 0
      end
    end

    tile_map_num = 0

    for i = 1, tiles_count do
      tile_num = i
      tile_addr = tiles_start_addr + i - 1
      tile = memory.readbyte(tile_addr)
      if tile ~= 0 then
        tile_px = tile2px(tile_num - 1, screenOffset, screenOffsetMult)
        -- print(tile_num, tile_addr, tile, tile_px)
        if tile_px['x'] >= 0 and tile_px['y'] >= 0 then
        	tiles_map[tile_map_num] = tile_px
        	tile_map_num = tile_map_num + 1

        	tiles_map_px[tile_px['y']][tile_px['x']] = 1
        end
      end
      -- if i < 10 then
      --   
      -- end
    end

    for i, tile in pairs(tiles_map) do
    	gui.text(tile['x'], tile['y'], string.format("%i %i", tile['x'], tile['y']))
    	-- gui.drawbox(tile['x'], tile['y'], tile['x'] + 16, tile['y'] + 16, "clear", "white")
    end

    -- Inputs

    inputs = {}
    inputs['right']= true
    inputs['B'] = true

    mario_pixel_x_snapped = mario_pixel_x - mario_x % 16
    mario_pixel_y_snapped = marioY - marioY % 16 + 16

    block_px_check = {x = mario_pixel_x_snapped + 16, y = mario_pixel_y_snapped}
    pit_px_check = {x = mario_pixel_x_snapped + 16, y = mario_pixel_y_snapped + 16}

    block_check = false

    if tiles_map_px[block_px_check['y']][block_px_check['x']] ~= 0 and jump_frames_timer == 0 then
    	jump_frames_timer = 22
    	block_check = true
    end

    pit_check = false

    if tiles_map_px[pit_px_check['y']][pit_px_check['x']] == 0 and jump_frames_timer == 0 then
    	jump_frames_timer = 22
    	pit_check = true
    end

    if jump_frames_timer > 3 then
    	inputs['A'] = true
    end

    if jump_frames_timer > 0 then
    	jump_frames_timer = jump_frames_timer - 1
    end

    joypad.set(1, inputs)

    -- Visual debug

       marioX = memory.readbyte(0x3AD)
       marioTrueX = memory.readbyte(0x0086)
       
       marioState = memory.readbyte(0x0756)
       if marioState == 0 then
       	gui.drawbox(marioX, marioY + marioHeight / 2, marioX + marioWidth, marioY + marioHeight, "clear", "green")
       else
       	gui.drawbox(marioX, marioY, marioX + marioWidth, marioY + marioHeight, "clear", "green")
       end

       gui.text(5, 10, string.format("offset: %02f", screenOffset))

       gui.text(5, 20, string.format("Total X: %02f", mario_x))
       gui.text(5, 30, string.format("Elapsed: %02f", elapsed_time))
       gui.text(5, 40, string.format("Speed: %02f", speed_average))

       gui.text(5, 50, string.format("Mario X snapped: %02f", mario_pixel_x_snapped))
       gui.text(5, 60, string.format("Mario Y snapped: %02f", mario_pixel_y_snapped))
       gui.text(5, 70, string.format("Block check: %s", tostring(block_check)))
       gui.text(5, 80, string.format("Pit check: %s", tostring(pit_check)))
       gui.text(5, 90, string.format("Tile X Y: %02f %02f", tiles_map[1]['x'], tiles_map[1]['y']))

       for i = 0, 4 do
       	enemyActive = memory.readbyte(0x000F + i)
   		enemyAbsX = memory.readbyte(0x0087 + i)
   		enemyAbsMultX = memory.readbyte(0x006E + i)
   		enemyTrueX = enemyAbsX + enemyAbsMultX * 256

   		enemyX = enemyTrueX - screenOffset
       	enemyY = memory.readbyte(0x0CF + i)
       	
       	--gui.text(5, i * 10 + 50, string.format("%02f %02f hor:%02f",enemyX,enemyY,enemyAbsMultX))
       	if enemyActive ~= 0 and enemyX > 0 and enemyX < 256 then
       		gui.drawbox(enemyX, enemyY + 8, enemyX + 16, enemyY + 24, "clear", "red")
       	end
       end

    current_page = screenOffsetMult
end

emu.registerafter(everyframe)