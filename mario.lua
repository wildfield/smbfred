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

function everyframe()
	-- Enable invincibility
	memory.writebyte(0x79F, 10)

       marioX = memory.readbyte(0x3AD)
       marioTrueX = memory.readbyte(0x0086)
       screenOffsetRel = memory.readbyte(0x071C)
       screenOffsetMult = memory.readbyte(0x071A)
       screenOffset = screenOffsetRel + screenOffsetMult * 256

       marioY = memory.readbyte(0xCE)
       marioState = memory.readbyte(0x0756)
       if marioState == 0 then
       	gui.drawbox(marioX, marioY + marioHeight / 2, marioX + marioWidth, marioY + marioHeight, "clear", "green")
       else
       	gui.drawbox(marioX, marioY, marioX + marioWidth, marioY + marioHeight, "clear", "green")
       end

       gui.text(5, 10, string.format("offset: %02f", screenOffset))

       playerX = memory.readbyte(0x0086) + memory.readbyte(0x006D) * 256

       gui.text(5, 20, string.format("Total X: %02f", playerX))
       

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

    for i = 1, tiles_count do
      tile_num = i
      tile_addr = tiles_start_addr + i - 1
      tile = memory.readbyte(tile_addr)
      if tile ~= 0 then
        tile_px = tile2px(tile_num - 1, screenOffset, screenOffsetMult)
        -- print(tile_num, tile_addr, tile, tile_px)
        if tile_px['x'] >= 0 and tile_px['y'] >= 0 then
          gui.drawbox(tile_px['x'], tile_px['y'], tile_px['x'] + 16, tile_px['y'] + 16, "clear", "white")
        end
      end
      -- if i < 10 then
      --   
      -- end
    end
end

emu.registerafter(everyframe)