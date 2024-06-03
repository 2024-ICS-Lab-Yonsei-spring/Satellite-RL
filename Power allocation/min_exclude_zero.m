function min_value = min_exclude_zero(array)

    non_zero_values = array(array ~= 0);

    if isempty(non_zero_values)
        error('배열에 0이 아닌 값이 없습니다.');
    else
        min_value = min(non_zero_values);
    end

end

