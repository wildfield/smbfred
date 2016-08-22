marioWidth = 16
marioHeight = 32

-- 0x0087/B
-- 0x00CF-0x00D3

function everyframe()
       marioX = memory.readbyte(0x3AD)
       marioTrueX = memory.readbyte(0x0086)
       screenOffsetRel = memory.readbyte(0x071D)
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
       	
       	gui.text(5, i * 10 + 50, string.format("%02f %02f hor:%02f",enemyX,enemyY,enemyAbsMultX))
       	if enemyActive ~= 0 and enemyX > 0 and enemyX < 256 then
       		gui.drawbox(enemyX, enemyY + 8, enemyX + 16, enemyY + 24, "clear", "red")
       	end
       end
end

emu.registerafter(everyframe)