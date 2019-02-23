def contains(string, char)
    i = 0
    while i < string.length
        if char == string[i]
            return true
        else
            i += 1
        end
    end
    return false
end

p contains("the quick brown fox jumps over the lazy dog", "d")