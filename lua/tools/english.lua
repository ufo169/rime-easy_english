local function english()
	local preedit, cands = {}, {}
	local num_selection, fold_comments, used_punct, wildcard, changing, page_size

	local function init(env)
		local engine = env.engine
		local schema = engine.schema
		local config = schema.config

		page_size = schema.page_size
		env.kRejected, env.kAccepted, env.kNoop = 0, 1, 2
		env.kPair = {["Release+Shift_L"]="Shift+Shift_L",["Release+Shift_R"]="Shift+Shift_R",["Lock+Release+Control_L"]="Lock+Control+Control_L",["Lock+Release+Control_R"]="Lock+Control+Control_R",
				     ["Lock+Release+Shift_L"]="Shift+Lock+Shift_L",["Lock+Release+Shift_R"]="Shift+Lock+Shift_R",["Release+Control_L"]="Control+Control_L",["Release+Control_R"]="Control+Control_R"}
		wildcard = config:get_string("translator/wildcard")
		used_punct = config:get_string("translator/used_punct")
		wildcard = wildcard and wildcard:gsub("[^%p]", ""):sub(1, 2) or ""
		wildcard = {t = wildcard, m = (wildcard.." "):sub(1, 1), o = wildcard:sub(2, 2), p = "([" .. (wildcard == "" and "%s" or wildcard:gsub("(%p)", "%%%1")) .. "])"}
		used_punct = used_punct and used_punct:gsub("[^%p]", ""):gsub(wildcard.p, "") or ""
	end

	local function processor(key, env)
		local engine = env.engine
		local context = engine.context
		local composition = context.composition
		local segment = composition:back()

		local input = context.input
		local caret_pos = context.caret_pos
		local has_menu = context:has_menu()
		local is_composing = context:is_composing()

		local keycode = key.keycode
		local keychar = string.format("%c", keycode)    --不能使用string.char(keycode)
		local keyrepr = key:repr()

		if context:get_option("ascii_mode") then
			local candidate_count, candidate, index

			num_selection = context:get_option("num_selection")
			fold_comments = context:get_option("fold_comments")

			if env.kPair[keyrepr] then return env.kPair[keyrepr] == env.keyrepr and env.kNoop or env.kAccepted else env.keyrepr = keyrepr end
			
			if key:release() or key:alt() or key:super() then return env.kNoop end

			if key:ctrl() then
				if (keyrepr == "Control+Control_L" or keyrepr == "Lock+Control+Control_L") and has_menu then
					context:set_option("num_selection", not num_selection) return env.kAccepted
				elseif (keyrepr == "Control+Control_R" or keyrepr == "Lock+Control+Control_R") and has_menu then
					context:set_option("fold_comments", not fold_comments) return env.kAccepted
				end
				return env.kNoop
			end

			if (keycode >= 0x41 and keycode <= 0x5a) or (keycode >= 0x61 and keycode <= 0x7a) then
				context:push_input(keychar)
				return env.kAccepted
			end

			if not is_composing then return env.kNoop end

			if keycode >= 0x30 and keycode <= 0x39 or keyrepr:match("^KP_%d$") ~= nil or keyrepr:match("^Lock%+KP_%d$") ~= nil then keychar = keyrepr:sub(-1)
			elseif (keycode >= 0x21 and keycode <= 0x2f) or (keycode >= 0x3a and keycode <= 0x40) or (keycode >= 0x5b and keycode <= 0x60) or (keycode >= 0x7b and keycode <= 0x7e) then
			elseif keycode == 0x20 then
			elseif keyrepr == "Return" or keyrepr == "Lock+Return" then keychar = ""
			elseif keyrepr == "Tab" or keyrepr == "Shift+Tab" or keyrepr == "Lock+Tab" or keyrepr == "Shift+Lock+Tab" then keychar = "\t"
			elseif keyrepr == "Down" or keyrepr == "Next" or keyrepr == "Lock+Down" or keyrepr == "Lock+Next" then
				if has_menu then
					index = segment.selected_index + ((keyrepr == "Down" or keyrepr == "Lock+Down") and 1 or page_size)
					candidate_count = segment.menu:candidate_count()
					if index >= candidate_count and candidate_count % page_size == 0 then candidate_count = segment.menu:prepare(candidate_count + page_size) end
					segment.selected_index = math.min(index, candidate_count - 1)
				end
				return env.kAccepted
			elseif keyrepr == "Up" or keyrepr == "Page_Up" or keyrepr == "Lock+Up" or keyrepr == "Lock+Page_Up" then
				if has_menu then
					segment.selected_index = math.max(segment.selected_index - ((keyrepr == "Up" or keyrepr == "Lock+Up") and 1 or page_size), 0)
				end
				return env.kAccepted
			elseif keyrepr == "Lock+End" then if has_menu then context.caret_pos = input:len() end return env.kAccepted
			elseif keyrepr == "Lock+Home" then if has_menu and segment.selected_index ~= 0 then segment.selected_index = 0 else context.caret_pos = 0 end return env.kAccepted
			elseif keyrepr == "Lock+BackSpace" then context:pop_input(1) return env.kAccepted
			elseif keyrepr == "Lock+Delete" then context:delete_input(1) return env.kAccepted
			elseif keyrepr == "Lock+Escape" then context:clear() return env.kAccepted
			elseif keyrepr == "Lock+Left" then context.caret_pos = caret_pos - 1 return env.kAccepted
			elseif keyrepr == "Lock+Right" then context.caret_pos = caret_pos == input:len() and 0 or caret_pos + 1 return env.kAccepted
			else
				return env.kNoop
			end
			if has_menu then
				index = tonumber(keychar)
				if index and num_selection then
					index = math.floor(segment.selected_index / page_size) * page_size + (index + 9) % 10
					if index >= segment.menu:candidate_count() then return env.kAccepted else keychar = " " end
					candidate = segment:get_candidate_at(index)
				else
					if segment.selected_index == 0 and keychar ~= "" then
						if wildcard.t:find(keychar, 1, 1) then context:push_input(keychar) return env.kAccepted
						elseif used_punct:find(keychar, 1, 1) then
							local pattern = preedit.p:sub(1, -6) .. "%" .. keychar .. preedit.p:sub(-5)
							for _, cand in ipairs(cands) do
								if cand.text:lower():match(pattern) then context:push_input(keychar) return env.kAccepted end
							end
						end
					end
					candidate = segment:get_selected_candidate()
				end
				engine:commit_text(candidate.type .. keychar)
			else
				engine:commit_text(input:sub(1, caret_pos) .. keychar)
			end
			context.input = input:sub(caret_pos + 1, -1)
			return env.kAccepted
		end
		return env.kNoop
	end

	local function segmentor(segmentation, env)
		local engine = env.engine
		local context = engine.context

		if context:get_option("ascii_mode") and not changing then
			preedit.t = segmentation.input
			preedit.l = preedit.t:lower()
			preedit.s = preedit.t:len()
			preedit.a = {{"", string.lower}}
			preedit.p = "^" .. (preedit.t .. wildcard.m):gsub("(.-(%a?)[^%a]-)" .. wildcard.p,
									function(a, b, c)
										if b ~= "" then preedit.a[#preedit.a][2] = b:lower() == b and string.lower or string.upper
										elseif #preedit.a == 1 then preedit.a[1][1] = preedit.a[1][1] .. a .. c return (a .. c):gsub("(%p)", "%%%1") end
										preedit.a[#preedit.a][1] = preedit.a[#preedit.a][1] .. a
										table.insert(preedit.a, {"", preedit.a[#preedit.a][2]})
										return a:gsub("(%p)", "%%%1") .. (c == wildcard.m and "(.-)" or "(.?)")
									end):lower() .. "$"
			preedit.w = #preedit.a > 2
			segmentation.input = preedit.l
		end
		return true
	end

	local function translator(input, seg, env)
	end

	local function filter(input, env)
		local engine = env.engine
		local context = engine.context
		local schema = engine.schema
		local config = schema.config
		local composition = context.composition
		local segment = composition:back()

		if changing then changing = false return end

		if context:get_option("ascii_mode") then
			local separator = fold_comments and "  " or "|"
			-- local prompt = "♥" .. (wildcard.t==""and""or"通配符"..wildcard.t.." ") .. "左Ctrl" .. (num_selection and"關"or"開") .. "數字選詞 右Ctrl" .. (fold_comments and"展開"or"疊起")
-- 			local prompt = "♥" .. (wildcard.t==""and""or""..wildcard.t.." ") .. "；L_Ctrl:(🔝" .. (num_selection and"🔛)"or"🔚)") .. "；R_Ctrl:" .. (fold_comments and"(🔜)"or"(🔙)")
			local prevcand = {text = preedit.t, comment = " "}
			local newcand = {start = context:get_preedit().sel_start, _end = context:get_preedit().sel_end}
			local candcount = 0
			if preedit.w then
				prevcand.comment = preedit.t:sub(-1):find(wildcard.p) and " " or ""
			else
				cands = {}
				for cand in input:iter() do
					table.insert(cands, {text = preedit.t .. cand.comment:sub(2), comment = cand.text, index = #cands})
				end
				if #cands ~=0 then
					table.sort(cands, function(a, b) return a.text:lower() == b.text:lower() and a.index < b.index or a.text:lower() < b.text:lower() end)  --Rime是按編碼長度排序,所以要重排
					table.insert(cands, {text = ""})
					prevcand.comment = cands[1].text:lower() ~= preedit.l and " " or ""
				end
			end
-- 			segment.prompt = context.caret_pos == context.input:len() and "    " .. prompt or ""
			for _, cand in pairs(cands) do
				local text = ""
				cand.text:lower():gsub(preedit.p, function(...) for a, b in ipairs({...}) do text = text .. preedit.a[a][1] .. preedit.a[a][2](b) end return text end)
				if text ~= "" or cand.text == "" then
					for comment in prevcand.comment:gsub("\\n", separator):gmatch("[^|]+") do
						candcount = candcount + 1
						newcand = Candidate(prevcand.text,newcand.start,newcand._end,(newcand.type==prevcand.text and candcount%schema.page_size~=1)and""or prevcand.text," "..comment)
						newcand.preedit = preedit.t
						yield(newcand)
					end
					prevcand = {text = text, comment = cand.comment}
				end
			end
			if candcount == 0 then
				changing = true      --避免進入死循環
				context:refresh_non_confirmed_composition()  --無匹配單詞,將segmentation.input還原爲preedit
			end
		else
			for cand in input:iter() do yield(cand)	end
		end
	end

	local function filter0(input, env)
		local engine = env.engine
		local context = engine.context
		local schema = engine.schema
		local config = schema.config
		local composition = context.composition
		local segment = composition:back()

		if changing then changing = false return end

		if context:get_option("ascii_mode") then
			local separator = fold_comments and "  " or "|"
			-- local prompt = "♥" .. (wildcard.t==""and""or"通配符"..wildcard.t.." ") .. "左Ctrl" .. (num_selection and"關"or"開") .. "數字選詞 右Ctrl" .. (fold_comments and"展開"or"疊起")
			local prompt = "♥" .. (wildcard.t==""and""or""..wildcard.t.." ") .. "；L_Ctrl:(🔝" .. (num_selection and"🔛)"or"🔚)") .. "；R_Ctrl:" .. (fold_comments and"(🔜)"or"(🔙)")
			local prevcand = {text = preedit.t, comment = " "}
			local newcand = {start = context:get_preedit().sel_start, _end = context:get_preedit().sel_end}
			local candcount = 0
			if preedit.w then
				prevcand.comment = preedit.t:sub(-1):find(wildcard.p) and " " or ""
			else
				cands = {}
				if preedit.s <= 1 then				--爲加快速度,首碼不使用反查,如確保所有詞義唯一,或者不介意頭幾碼被Rime忽略部份同義詞,可增加此數值
					for cand in input:iter() do
						table.insert(cands, {text = preedit.t .. cand.comment:sub(2), comment = cand.text, index = #cands})
					end
				else
					local english_rvdb = ReverseDb("build/" .. config:get_string("translator/dictionary") .. ".reverse.bin")   --因Rime對詞義相同,拼寫接近的單詞只保留一個,反查可全部找出
					for cand in input:iter() do
						for comment in english_rvdb:lookup(cand:get_genuine().text):gmatch("[^ ]+") do
							if comment:sub(1, preedit.s):lower() == preedit.l then
								table.insert(cands, {text = comment, comment = cand.text, index = #cands})
							end
						end
					end
				end
				if #cands ~=0 then
					table.sort(cands, function(a, b) return a.text:lower() == b.text:lower() and a.index < b.index or a.text:lower() < b.text:lower() end)  --Rime是按編碼長度排序,所以要重排
					table.insert(cands, {text = ""})
					prevcand.comment = cands[1].text:lower() ~= preedit.l and " " or ""
				end
			end
			segment.prompt = context.caret_pos == context.input:len() and "                " .. prompt or ""
			for _, cand in pairs(cands) do
				local text = ""
				cand.text:lower():gsub(preedit.p, function(...) for a, b in ipairs({...}) do text = text .. preedit.a[a][1] .. preedit.a[a][2](b) end return text end)
				if text ~= "" or cand.text == "" then
					if text == prevcand.text then    --允許詞典中出現編碼相同單詞
						prevcand.comment = prevcand.comment .. "\\n" .. cand.comment
					else
						for comment in prevcand.comment:gsub("\\n", separator):gmatch("[^|]+") do
							candcount = candcount + 1
							newcand = Candidate(prevcand.text,newcand.start,newcand._end,(newcand.type==prevcand.text and candcount%page_size~=1)and""or prevcand.text," "..comment)
							newcand.preedit = preedit.t
							yield(newcand)
						end
						prevcand = {text = text, comment = cand.comment}
					end
				end
			end
			if candcount == 0 then
				changing = true      --避免進入死循環
				context:refresh_non_confirmed_composition()  --無匹配單詞,將segmentation.input還原爲preedit
			end
		else
			for cand in input:iter() do yield(cand)	end
		end
	end

	return { processor = { init = init, func = processor }, segmentor = segmentor, translator = translator, filter = filter, filter0 = filter0 }
end

return english