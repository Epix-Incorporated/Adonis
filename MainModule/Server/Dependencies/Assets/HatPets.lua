local hats = script.Parent
local events = {}
if hats then
	local mode = hats.Mode
	local target = hats.Target
	repeat
		for i,hat in next,hats:children() do
			if hat:IsA('Part') then
				local bpos = hat.bpos
				hat.CanCollide = false
	
				if events[hat.Name..'hatpet'] then
					events[hat.Name..'hatpet']:disconnect()
					events[hat.Name..'hatpet'] = nil
				end
	
				if mode.Value=='Follow' then
					waittime = 0.3
					bpos.position = target.Value.Position+Vector3.new(math.random(-10,10),math.random(7,9),math.random(-10,10))
					hat.CanCollide = false
				elseif mode.Value=='Float' then
					waittime = 0.1
					bpos.position = target.Value.Position+Vector3.new(math.random(-2.5,2.5),-3,math.random(-2.5,2.5))
					hat.CanCollide = true
				elseif mode.Value=='Attack' then
					waittime = 0.3
					bpos.position = target.Value.Position+Vector3.new(math.random(-3,3),math.random(-3,3),math.random(-3,3))
					events[hat.Name..'hatpet'] = hat.Touched:connect(function(p) 
						if not tonumber(p.Name) and game:service("Players"):GetPlayerFromCharacter(p.Parent) then 
							p.Parent.Humanoid:TakeDamage(1) 
						end 
					end)
					
					hat.CanCollide = true
				elseif mode.Value=='Swarm' then
					waittime = 0.2
					bpos.position = target.Value.Position+Vector3.new(math.random(-8,8),math.random(-8,8),math.random(-8,8))
					hat.CanCollide = true
				end
			end
		end
		wait(0.5)
	until not script.Parent
end