marioWidth = 16
marioHeight = 32

-- 0x0087/B
-- 0x00CF-0x00D3

-- Tile positions
local tiles_start_addr = 0x0500
local tiles_final_addr = 0x069F
local tiles_count = tiles_final_addr - tiles_start_addr + 1

function tile2px(tilenum, screenpos)
  if tilenum < 0 or tilenum >= 0x1A0 then
    return false;
  end;

  px      = math.fmod(tilenum, 0xD0) * 0x10

  if px < 0 then
    px    = px + 0x200;
  end;

  py      = math.floor(tilenum / 0xD) * 0x10;
  returnval = {x = px, y = py};
  return returnval;
end;

function everyframe()
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

       gui.text(5, 30, string.format("X: %02f", memory.readbyte(0x0086)))
       gui.text(5, 40, string.format("2nd X: %02f", memory.readbyte(0x006D)))
       

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

    for i = 1, tiles_count do
      tile_num = i
      tile_addr = tiles_start_addr + i - 1
      tile = memory.readbyte(tile_num)
      if tile ~= 0 then
        tile_px = tile2px(tile_num, screenOffset)
        if tile_px['x'] >= 0 and tile_px['y'] >= 0 then
          gui.drawbox(tile_px['x'], tile_px['y'], tile_px['x'] + 16, tile_px['y'] + 16, "clear", "black")
        end
      end
    end
end

emu.registerafter(everyframe)