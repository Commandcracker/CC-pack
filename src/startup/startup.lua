shell.setCompletionFunction(
    fs.getDir(shell.getRunningProgram()).."/bin/pack", 
    function(shell, index, text)
        if index == 2 then return end
        return {"install","show","search","remove","list","fetch","add-source"}
    end
)
