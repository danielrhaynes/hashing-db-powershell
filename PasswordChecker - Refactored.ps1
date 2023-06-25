#Function declarations
function Get-StringHash {

    param (
        $String
        )
    
    [string]$private:_string = $String
    $stream = [System.IO.MemoryStream]::new()
    $streamWriter = [System.IO.StreamWriter]::new($stream)

    $streamWriter.Write($_string)
    $streamWriter.Flush()
    $stream.Position = 0

    $shadowPass = Get-FileHash -InputStream $stream
    return $shadowPass.Hash
}

#User Input
$usernamePrompt = Read-Host -Prompt 'Username'
$passwordPrompt = Read-Host -Prompt 'Please enter your password'

#Inserting the entered username into regex with capture groups for Username, Salt, and Shadowpass
$pattern = '^' + '(' + [regex]::escape($usernamePrompt) + ')' + '\s+(\d+)\s(\w+)'

#Performing lookup in the password "database" for any line containing the entered username
$searchReturn = Get-Content "D:\Daniel\Desktop\Scripting Projects\Password Script Experiment\Passwords\ShadowPass.txt" | Select-String -Pattern $pattern

#On the condition that $searchReturn contains something, splits its contents off into a table based on the regex capture groups, sets a flag
#to determine whether the opperation found a user by that name or not
&{
    if ($searchReturn){

        $script:resultsTable = @{
            Username = $searchReturn.Matches.Groups[1].Value
            Salt = $searchReturn.Matches.Groups[2].Value
            Shadowpass = $searchReturn.Matches.Groups[3].Value
            }
        [bool]$script:foundUser = $true
        }

    else{
        [bool]$script:foundUser = $false
        }
}

#If there is something in the $resultsTable, concatenates the Salt field of the table with the password prompt input and calls our Get-StringHash function
&{
    if ($foundUser){
    $saltPWConcat = ($passwordPrompt + [string]$resultsTable.Salt)
    $script:pwCheck = Get-StringHash -String $saltPWConcat
    }
}

#if the stored copy and the reconstructed version of the shadowpass match, and if the $foundUser flag is true, reports a success, reports failure otherwise.
&{
    if ($pwCheck -eq $resultsTable.Shadowpass -and $foundUser){
        Write-Host "You did it!"
        }
     else{
        Write-Warning -Message "Oopsie daisy!"
        }
}

#variable cleanup
#Unnecessary if you're running this script in a way that terminates the current context on exit, but running things in the ISE does not do that, and so this block just exists
#so that the script will clean up after itself when run in ISE
$global:searchReturn = $null
$global:resultsTable = $null
$global:usernamePrompt = $null
$global:passwordPrompt = $null
$global:foundUser = $false

#Notes:
#Evaluating each check in the script even after setting the foundUser flag to false might not be the most efficient, but the most expensive thing dependent on that flag check,
#the hashing function, doesn't actually run if the flag is false, and a couple of bool evaluations probably wouldn't make the biggest impact on performance even if you
#imagine that through some grevious deficiency in judgement we were somehow actually running this as our login script in a production thing. Also, keeping the script down to a single
#exit point theoretically keeps information leakage to a minimum re: whether or not a username/password combo you just brute forced actually hit on the username side of things 
#or whether it missed on both counts. I guess if you wanted to completely eliminate that, you would have to account for the hashing function not running and institute a wait time
#corresponding to its usual process time or generate some garbage for it to run on, which is an idea so noodley it makes my head spin and I have no idea if actual enterprise trust 
#management software does anything like that or not.

#This is also obviously just for learning purposes, you wouldn't write something like this in Powershell for actual production, even if you needed it for use in PowerShell, since
#there are myriad existing, better solutions for password protection in .NET land. This was just an excuse to learn the ins and outs of PowerShell a bit, and explore the basic ideas
#behind how hashed password storage and retrieval works.