steamcmdAppRoot="./SteamCMD"
steamPath=$( cat < "./SteamModUpdate.config" )
logFile="$steamcmdAppRoot/SteamUpdateLog.txt"
tmpLogFile="$steamcmdAppRoot/tmp.log"

echo -n $steamPath

function Write-Log {
	echo -e $1
	echo $1 | sed -r 's/\\033[^m]+m//g' >> $logFile
}

function Check-LogExistsAndClean {
    if [ -f $logFile ]
	then
		rm $logFile
    else
        Write-Log "Log file does not exist. Creating new log file."
    fi
}

Check-LogExistsAndClean

steamAppsPath="$steamPath/steamapps"
steamCommonPath="$steamAppsPath/common"
steamUser="anonymous"

function Get-InstallDirectoryFromACF {
    acfFilePath="$1"
	
    content=$(cat $acfFilePath)
    matches=$(echo -n $content | grep -oE '"name" "([^"]+)"')
    if [ ! -z "$matches" ]
	then
        installDir=$(echo -n "$matches" | sed -r 's/"name" "([^"]+)"/\1/g')
        echo -n "$installDir"
    else
        echo -n ""
    fi
}

function Get-AppIdsFromACFFiles {
	directory="$1"

    acfFiles=($(find "$directory" -maxdepth 1 -name appmanifest_*.acf))
    appIds=()
    for file in ${acfFiles[@]}; do
        content=$(cat "$file")
        appIdMatch=$(echo -n $content | grep -oE '"appid" "([^"]+)"')
        nameMatch=$(echo -n $content | grep -oE '"name" "([^"]+)"')
        if [ ! -z "$appIdMatch" ] && [ ! -z "$nameMatch" ]
		then
            appId=$(echo -n $appIdMatch | sed -r 's/"appid" "([^"]+)"/\1/g')
            name=$(echo -n $nameMatch | sed -r 's/"name" "([^"]+)"/\1/g')
            Write-Log "Found app with ID:\033[34m$appId\033[0m and name:\033[36m$name\033[0m"
			end=(${!appIds[@]})
			end=$(( ${end[@]: -1} + 1))
			appInfo="$appId|$(echo -n $name | tr ' ' '|')"
            appIds[$end]=$appInfo
        fi
    done
    return $appIds
}

Get-AppIdsFromACFFiles $steamAppsPath
appIds=$?
if [ ${#appIds[@]} -eq 0 ]
then
    Write-Log "\033[1;31mNo app IDs found in ACF files.\033[0m"
    exit
fi

function ReadTmpLogFile {
	rm -f "$tmpLogFile"
	touch "$tmpLogFile"
	name=""
	while read log; do
		if [[ $log == n###* ]]
		then
			name=${log:4}
		else
			text=$(echo -n $log | sed -r "s/^/\\\033[36m$name\\\033[0m | /g")
			Write-Log "$text"
		fi
	done < <(tail -f "$tmpLogFile")
}

ReadTmpLogFile &
for appInfo in ${appIds[@]}; do
	appId=$(echo -n $appInfo | sed -r 's/^([^|]+).*/\1/g')
	name=$(echo -n $appInfo | sed -r 's/^[^|]+\|(.*)$/\1/g' | tr '|' ' ')
	echo "n###$name" >> "$tmpLogFile"
	if [ $appId != "0" ]
	then
		acfFilePath="$steamAppsPath/appmanifest_$appId.acf"
		echo "Reading content of ACF file: $acfFilePath" >> "$tmpLogFile"
		installDir=$(Get-InstallDirectoryFromACF $acfFilePath)
		if [ ! -z "$installDir" ]
		then
			gameInstallPath="$steamCommonPath/$installDir"
			echo "Updating game on path: $gameInstallPath" >> "$tmpLogFile"
			
			arguments="+force_install_dir $gameInstallPath +login anonymous +app_update $appId validate +quit"
			{
				$steamcmdAppRoot/steamcmd.exe $arguments >> "$tmpLogFile"
			} && {
				echo "\\\033[32mGame with ID:$appId updated at path:$gameInstallPath\\\033[0m" >> "$tmpLogFile"
			} || {
				echo "\\\033[31mFailed to update game with ID:$appId and name:$name. Error: $_\\\033[0m" >> "$tmpLogFile"
			}
		else
			echo "\\\033[31mFailed to find install directory for app ID:$appId.\\\033[0m" >> "$tmpLogFile"
		fi
	fi
done
echo "Steam games updated." >> "$tmpLogFile"
echo "---Press any key to continue---" >> "$tmpLogFile"
read  -n 1
rm "$tmpLogFile"


