cls()
-------------------------------
-- useful globals -------------
-- players pool
p_pool={}
p_pool[0],p_pool[1]={},{}

-- possible button press results
l,r,u,d,o,x="l","r","u","d","o","x"
btn_prs={l, r, u, d, o, x}

-- hold_t: how many secs to hold a button to trigger special
-- dble_t: how many secs you have to tap a button again for it to trigger special
hold_t, dble_t=2, 1

-------------------------------
-- functional helpers
function iterpool(pool, fn)
	for k, v in pairs(pool) do
		fn(k, v)
	end
end

function time_since(t)
	return time() - t
end
-------------------------------
-- pico8 lifecycle
function _update()
	-- update all players
	iterpool(p_pool, update_p)
end

function _init()
	iterpool(p_pool, init_p)
end

-- init all player values here
function init_p(n, p)
		p.pressed={}

		-- Sprites:
		-- player 1 is sprites 1 and 17. 2 is 2 and 18. and so on.
		p.draw=function()
			local id=(n+1)
			if (p.dir==l) then id=n+16 end
			spr(id, p.x, p.y)
		end

		-- set drawing-related props
		p.dir=r
		p.x=16
		p.y=16

		p.act=function(dir, type)
			local mvs={
				l={-1, 0},
				r={1, 0},
				u={0, -1},
				d={0, 1}
			}
			if (type==nil) then
				if (mvs[dir]) then
					p.move(mvs[dir])
				else
				--TODO:
				-- handle jump
				-- handle moving down ladders/drop down ledges
				-- handle action buttons
				end
			elseif (type=='dble') then
				p.move(mvs[dir], 4) -- dash
			elseif (type=='hold') then
				p.move(mvs[dir], 1.5)	-- jog
			end
		end

		p.move=function(mv, multi)
			multi=multi or 1
			p.x=p.x+(mv[1]*multi)
			p.y=p.y+(mv[2]*multi)
		end

		function init_p_btns(k, v)
			p.pressed[v]={}
			p.pressed[v].last_pressed=nil
			p.pressed[v].held=false
			p.pressed[v].heldstart=nil
		end

		-- api: could use p.sprite instead?
		p.glyph=p_glyph

		iterpool(btn_prs, init_p_btns)
end

-------------------------------
-- \140 movement handling code \140
-------------------------------

function update_p(n, p)
	-- check 4 press by player no.

	iterpool(btn_prs, function (k, v)
		local i=k-1 -- zero-indexed buttons
		local pressed=p.pressed
		local _btn=pressed[v]

		function was_tapped(t)
			if (t and (time_since(t) <= dble_t)) then
				return true
			end
			return false
		end

		function was_held(t)
			if (time_since(t) <= hold_t) then
				return true
			end
			return false
		end

		function clearbtn()
			_btn.held=false
			_btn.heldstart=nil
			_btn.last_pressed=(_btn.last_pressed or time())
		end

		if (btn(i, n)) then
			-- handle tapping
			if (btnp(i, n)) then
				if (was_tapped(_btn.last_pressed)) then
					-- trigger tapped effect
					-- something like:
					-- tapped(p, v)
					p.act(v, 'dble')
				else
					p.act(v)
				end
				clearbtn()
			else
				_btn.last_pressed=time()
				_btn.held=true
				-- check for holding down button
				if (_btn.heldstart) then
					if (was_held(_btn.heldstart)) then
						-- trigger 'held' effect
						-- something like
						-- held(p, v)
						p.act(v, 'hold')
					else
						p.act(v)
					end
				else
					p.act(v)
					_btn.heldstart=time()
				end
			end
		else
			-- maybe p.end(v) to trigger animations/fx
			clearbtn()
		end
	end)
end

function _draw()
	cls()



	iterpool(p_pool, function (n, p)
		print(p.x .. " - " .. p.y, 24,20 * n)
		p.draw()
	end)

	function debug_p(n, p)
		function debug_p_btns(k, v)
			local button=p.pressed[v]
			held='n'
			last_pressed=0
			if (button.held) then held='y' end
			if (button.last_pressed) then last_pressed=button.last_pressed end
			print(v .. ' held: ' .. held .. ' last_pressed: ' .. last_pressed, 2, (n * 40) + (k * 8))
		end
		iterpool(btn_prs, debug_p_btns)
	end
	-- uncomment to debug
	--iterpool(p_pool, debug_p)
end