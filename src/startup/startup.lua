local function completeMultipleChoice( sText, tOptions, bAddSpaces )
    local tResults = {}
    for n=1,#tOptions do
        local sOption = tOptions[n]
        if #sOption + (bAddSpaces and 1 or 0) > #sText and string.sub( sOption, 1, #sText ) == sText then
            local sResult = string.sub( sOption, #sText + 1 )
            if bAddSpaces then
                table.insert( tResults, sResult .. " " )
            else
                table.insert( tResults, sResult )
            end
        end
    end
    return tResults
end

shell.setCompletionFunction(
    fs.getDir(shell.getRunningProgram()).."/bin/pack", 
    function(shell, index, text)
        if index == 1 then
            return completeMultipleChoice(text, {"install","show","search","remove","list","fetch","add-source"})
        end
    end
)
