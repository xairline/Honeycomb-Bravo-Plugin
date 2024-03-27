-- Helper functions
function int_to_bool(value)
	if value == 0 then
		return false
	else
		return true
	end
end

function get_ap_state(array)
	if array[0] >= 1 then
		return true
	else
		return false
	end
end

function array_has_true(array, max_lenght)
	if max_lenght == nil then
		max_lenght = 16
	end
	for i = 0, max_lenght do
		if array[i] == 1 then
			return true
		end
	end

	return false
end

function array_has_positives(array, max_lenght)
	if max_lenght == nil then
		max_lenght = 16
	end
	for i = 0, max_lenght do
		if not array[i] then
			write_log('ERROR array_has_positives: array[' .. i .. '] is nil')
			break
		end
		if array[i] > 0.01 then
			return true
		end
	end
	return false
end