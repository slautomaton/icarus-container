#!/bin/bash

function initial_setup () {

  echo ██╗.██████╗.█████╗ ██████╗ ██╗...██╗███████╗
  echo ██║██╔════╝██╔══██╗██╔══██╗██║...██║██╔════╝
  echo ██║██║.....███████║██████╔╝██║...██║███████╗
  echo ██║██║.....██╔══██║██╔══██╗██║...██║╚════██║
  echo ██║╚██████╗██║..██║██║..██║╚██████╔╝███████║
  echo ╚═╝ ╚═════╝╚═╝..╚═╝╚═╝..╚═╝ ╚═════╝ ╚══════╝
  echo ""
  echo ███████╗███████╗██████╗ ██╗...██╗███████╗██████╗ 
  echo ██╔════╝██╔════╝██╔══██╗██║...██║██╔════╝██╔══██╗
  echo ███████╗█████╗..██████╔╝██║...██║█████╗..██████╔╝
  echo ╚════██║██╔══╝..██╔══██╗╚██╗ ██╔╝██╔══╝..██╔══██╗
  echo ███████║███████╗██║..██║ ╚████╔╝ ███████╗██║..██║
  echo ╚══════╝╚══════╝╚═╝..╚═╝..╚═══╝..╚══════╝╚═╝..╚═╝
  echo ""
  echo Server Name : $SERVERNAME
  echo Game Port   : $PORT
  echo Query Port  : $QUERYPORT
  echo Steam UID   : $STEAM_USERID
  echo Steam GID   : $STEAM_GROUPID
  echo Branch      : $BRANCH
  echo ""
  echo ====================
  echo Setting User ID...

  groupmod -g "${STEAM_GROUPID}" steam \
    && usermod -u "${STEAM_USERID}" -g "${STEAM_GROUPID}" steam

  export WINEPREFIX=/home/steam/icarus
  export WINEARCH=win64
  export WINEPATH=/game/icarus

  echo Initializing Wine...
  sudo -u steam wineboot --init > /dev/null 2>&1

  echo Changing wine folder permissions...
  chown -R "${STEAM_USERID}":"${STEAM_GROUPID}" /home/steam
}

function update() {
  echo ==============================================================
  echo Updating SteamCMD...
  echo ==============================================================
  sudo -u steam /home/steam/steamcmd/steamcmd.sh +quit

  echo ==============================================================
  echo Updating/downloading game through steam
  echo ==============================================================
  MAX_RETRIES=3
  RETRY_COUNT=0

  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do

    sudo -u steam /home/steam/steamcmd/steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir /game/icarus \
        +login anonymous \
        +app_update 2089300 -beta "${BRANCH}" validate \
        +quit

      EXIT_CODE=$?
      
      if [ $EXIT_CODE -eq 0 ]; then
          echo "Game update successful"
          date > /home/steam/steamcmd/.last_update
          break
      else
          RETRY_COUNT=$((RETRY_COUNT + 1))
          
          if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
              echo "Update failed with exit code $EXIT_CODE"
              echo "Cleaning manifest and retrying..."
              
              rm -rf /game/icarus/steamapps/appmanifest_2089300.acf
              
              sleep 1
          fi
      fi
  done

  if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
      echo "ERROR: Failed to update game after $MAX_RETRIES attempts"
      echo "Check disk space and network connectivity. If the issue persists, please delete the /game/icarus folder or the volume you've mapped this to and try again. (This will remove any existing game files.)"
      exit 1
  fi
}

function setAsyncTimeout () {
  echo ==============================================================
  echo Setting Steam Async Timeout value in Engine.ini to $STEAM_ASYNC_TIMEOUT
  echo ==============================================================
  configPath='/home/steam/.wine/drive_c/icarus/Saved/Config/WindowsServer'
  engineIni="${configPath}/Engine.ini"
  if [[ ! -e ${engineIni} ]]; then
    mkdir -p ${configPath}
    touch ${engineIni}
  fi
  chown -R "${STEAM_USERID}":"${STEAM_GROUPID}" ${engineIni}

  if ! grep -Fq "[OnlineSubsystemSteam]" ${engineIni}
  then
      echo '[OnlineSubsystemSteam]' >> ${engineIni}
      echo 'AsyncTaskTimeout=' >> ${engineIni}
  fi

  sedCommand="/AsyncTaskTimeout=/c\AsyncTaskTimeout=${STEAM_ASYNC_TIMEOUT}"
  sed -i ${sedCommand} ${engineIni}
}

function server_config () {


  if [ -z "$ADMIN_PASSWORD" ] ; then
    # If you neglect to set the admin password you will regret it sooner or later
    # Using openssl to generate a random 32 character string if the password is empty
    # Base64 encoding ensures there is no weird characters in the password that could mess up this script
    echo "ADMIN_PASSWORD is set to: ${ADMIN_PASSWORD:=$(openssl rand -base64 32)}"
  fi

  if [ -z "$SERVERNAME" ] ; then
    echo "SERVERNAME default set to: ${SERVERNAME:=Icarus Dedicated Server}"
  fi

  if [ -z "$SERPORTVERNAME" ] ; then
    echo "PORT default set to: ${PORT:=17777}"
  fi

  if [ -z "$QUERYPORT" ] ; then
    echo "QUERYPORT default set to: ${QUERYPORT:=27015}"
  fi

  if [ -z "$SHUTDOWN_NOT_JOINED_FOR" ] ; then
    echo "ShutdownIfNotJoinedFor default set to: ${SHUTDOWN_NOT_JOINED_FOR:=40.000000}"
  fi

  if [ -z "$SHUTDOWN_EMPTY_FOR" ] ; then
    echo "ShutdownIfEmptyFor default set to: ${SHUTDOWN_EMPTY_FOR:=30.000000}"
  fi

  if [ -z "$GAMESAVEFREQUENCY" ] ; then
    echo "GameSaveFrequency default set to: ${GAMESAVEFREQUENCY:=60.000000}"
  fi

    if [ -z "$RESUME_PROSPECT" ] ; then
    echo "Resume prospects default set to: ${RESUME_PROSPECT:="True"}"
  fi

    if [ -z "$ALLOW_NON_ADMINS_LAUNCH" ] ; then
    echo "Allow non admins to launch default set to: ${ALLOW_NON_ADMINS_LAUNCH:="True"}"
  fi

    if [ -z "$ALLOW_NON_ADMINS_DELETE" ] ; then
    echo "Allow non admins to delete default set to: ${ALLOW_NON_ADMINS_DELETE:="False"}"
  fi

  # Here's what we are going to configure
  echo "============================================================="
  echo "Configuring ${SERVERNAME:-Icarus Dedicated Server} with the following config"
  echo "============================================================="
  echo ""
  echo "SessionName=${SERVERNAME:-Icarus Dedicated Server}"
  echo "Port=${PORT}"
  echo "QueryPort=${QUERYPORT}"
  echo ""
  echo "JoinPassword=${JOIN_PASSWORD}"
  echo "MaxPlayers=${MAX_PLAYERS}"
  echo "ShutdownIfNotJoinedFor=${SHUTDOWN_NOT_JOINED_FOR}"
  echo "ShutdownIfEmptyFor=${SHUTDOWN_EMPTY_FOR}"
  echo "AdminPassword=${ADMIN_PASSWORD}"
  echo "LoadProspect=${LOAD_PROSPECT}"
  echo "CreateProspect=${CREATE_PROSPECT}"
  echo "ResumeProspect=${RESUME_PROSPECT}"
  echo "LastProspect=${LAST_PROSPECT}"
  echo "AllowNonAdminsToLaunchProspects=${ALLOW_NON_ADMINS_LAUNCH}"
  echo "AllowNonAdminsToDeleteProspects=${ALLOW_NON_ADMINS_DELETE}"
  echo "FiberFoliageRespawn=${FIBERFOLIAGERESPAWN}"
  echo "LargeStonesRespawn=${LARGESTONESRESPAWN}"
  echo "GameSaveFrequency=${GAMESAVEFREQUENCY}"
  echo "SaveGameOnExit=${SAVEGAMEONEXIT}"
  echo ""
  echo "============================================================="

  serverconfigdir="$STEAM_GAME_DIR/drive_c/icarus/Saved/Config/WindowsServer"
  serversettingsini="$serverconfigdir/ServerSettings.ini"

  # Ensure the server config dir exists
  if [ ! -e $serverconfigdir ] ; then mkdir -p $serverconfigdir ; fi
  # Ensure the serversettings.ini file exists
  if [ ! -e $serversettingsini ] ; then
  # The 'here document' '<<-' redirection deletes all leading tabs
  # Replacing the tabs with spaces will break the script.
  cat > $serversettingsini <<- EOF
	[/Script/Icarus.DedicatedServerSettings]
	SessionName=
	JoinPassword=
	MaxPlayers=
	ShutdownIfNotJoinedFor=
	ShutdownIfEmptyFor=
	AdminPassword=
	LoadProspect=
	CreateProspect=
	ResumeProspect=
	LastProspect=
	AllowNonAdminsToLaunchProspects=
	AllowNonAdminsToDeleteProspects=
	FiberFoliageRespawn=
	LargeStonesRespawn=
	GameSaveFrequency=
	SaveGameOnExit=
	EOF
  fi

  # Always apply the settings
  sed -i "/SessionName=/c\SessionName=${SERVERNAME}" ${serversettingsini}
  sed -i "/JoinPassword=/c\JoinPassword=${JOIN_PASSWORD}" ${serversettingsini}
  sed -i "/MaxPlayers=/c\MaxPlayers=${MAX_PLAYERS}" ${serversettingsini}
  sed -i "/ShutdownIfNotJoinedFor=/c\ShutdownIfNotJoinedFor=${SHUTDOWN_NOT_JOINED_FOR}" ${serversettingsini}
  sed -i "/ShutdownIfEmptyFor=/c\ShutdownIfEmptyFor=${SHUTDOWN_EMPTY_FOR}" ${serversettingsini}
  sed -i "/AdminPassword=/c\AdminPassword=${ADMIN_PASSWORD}" ${serversettingsini}
  sed -i "/LoadProspect=/c\LoadProspect=${LOAD_PROSPECT}" ${serversettingsini}
  sed -i "/CreateProspect=/c\CreateProspect=${CREATE_PROSPECT}" ${serversettingsini}
  sed -i "/ResumeProspect=/c\ResumeProspect=${RESUME_PROSPECT}" ${serversettingsini}
  sed -i "/AllowNonAdminsToLaunchProspects=/c\AllowNonAdminsToLaunchProspects=${ALLOW_NON_ADMINS_LAUNCH}" ${serversettingsini}
  sed -i "/AllowNonAdminsToDeleteProspects=/c\AllowNonAdminsToDeleteProspects=${ALLOW_NON_ADMINS_DELETE}" ${serversettingsini}
  sed -i "/FiberFoliageRespawn=/c\FiberFoliageRespawn=${FIBERFOLIAGERESPAWN}" ${serversettingsini}
  sed -i "/LargeStonesRespawn=/c\LargeStonesRespawn=${LARGESTONERESPAWN}" ${serversettingsini}
  sed -i "/GameSaveFrequency=/c\GameSaveFrequency=${GAMESAVEFREQUENCY}" ${serversettingsini}
  sed -i "/SaveGameOnExit=/c\SaveGameOnExit=${SAVEGAMEONEXIT}" ${serversettingsini}

  echo ==============================================================
  echo Changing config folder permissions...
  chown -R "${STEAM_USERID}":"${STEAM_GROUPID}" home/steam/.wine/drive_c/icarus
}

function rungame () {
  echo ==============================================================
  echo Starting Server...
  echo ==============================================================
  echo ░█▀▄░█░█░█▀▀░█░█░█░░░█▀▀░░░█░█░█▀█░░          
  echo ░█▀▄░█░█░█░░░█▀▄░█░░░█▀▀░░░█░█░█▀▀░░          
  echo ░▀▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░░░▀▀▀░▀░░░░          
  echo ░█▀█░█▀▄░█▀█░█▀▀░█▀█░█▀▀░█▀▀░▀█▀░█▀█░█▀▄░█▀▀░█
  echo ░█▀▀░█▀▄░█░█░▀▀█░█▀▀░█▀▀░█░░░░█░░█░█░█▀▄░▀▀█░▀
  echo .▀░░░▀░▀░▀▀▀░▀▀▀░▀░░░▀▀▀░▀▀▀░░▀░░▀▀▀░▀░▀░▀▀▀░▀                                                                                                
  echo ==============================================================
  exec sudo -u steam wine /game/icarus/Icarus/Binaries/Win64/IcarusServer-Win64-Shipping.exe \
    -Log \
    -UserDir='C:\icarus' \
    -SteamServerName="${SERVERNAME:-Icarus Dedicated Server}" \
    -PORT="${PORT:-17777}" \
    -QueryPort="${QUERYPORT:-27015}"
}

#=============================================================
# Main Script Logic
initial_setup
update
setAsyncTimeout
server_config
rungame
#=============================================================