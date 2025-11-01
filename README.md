![Docker Image Version](https://img.shields.io/docker/v/slautomaton/icarus?arch=amd64&style=plastic&logo=docker&label=Image%20Version)
![Docker Pulls](https://img.shields.io/docker/pulls/slautomaton/icarus?style=plastic&logo=docker&label=Docker%20Pulls)
![Docker Image Size](https://img.shields.io/docker/image-size/slautomaton/icarus?arch=amd64&style=plastic&logo=docker&label=Image%20Size)
![GitHub License](https://img.shields.io/github/license/slautomaton/icarus?style=plastic&logo=github)
![GitHub last commit](https://img.shields.io/github/last-commit/slautomaton/icarus?style=plastic&logo=github&label=Last%20Commit)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/slautomaton/icarus/01.yml?style=plastic&logo=github&label=Build)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/slautomaton/icarus/02.yml?style=plastic&logo=google&label=OSV%20Scan%20Check)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/slautomaton/icarus/03.yml?style=plastic&logo=docker&label=Docker%20Scout)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/slautomaton/icarus/04.yml?style=plastic&logo=trivy&label=Trivy%20CVE)




# Fork of Nerodon's Icarus Container

### Core Differences as of 10/31/2025:

1. Updated Nerodon's  **`runicarus.sh`** script to write **`ServerSettings.ini`** into config directory at /home/steam/.wine/*, NOT into the directory where binaries are installed. This is fixes some confusion around Rocketwertz's documentation instructing dedicated server configurers to write **`ServerSettings.ini`** into the installation binaries, where the game no longer reads. 
2. Added timezone support via tzdata and TZINFO env variable
3. Added sample instruction set to use **`.env`** for preventing passing hardcoded passwords into build config metadata
4. Added mount path on host to get to container logs faster
5. Updated mount paths to reflect location of where settings, mods, and prospect files should be.
6. Added CI github actions so I can learn

## icarus-dedicated-server containerized
This dedicated server will automatically download/update to the latest available server version when the container starts or restarts. The dedicated server runs in Ubuntu 25.10 and wine64. With the number of env variables to set, I find it best to use docker-compose.yml. 

## Environmental Variables
Refer to https://github.com/RocketWerkz/IcarusDedicatedServer/wiki/Server-Config-&-Launch-Parameters for more detail on server configs
| ENV Var | Description| Default Value if unspecified|
|---------|------------|-----------------------------|
|SERVERNAME| The name of the server on the server browser| Icarus Server
|PORT| The game port| 17777/udp
|QUERYPORT| The Steam discoverability port| 27015/udp
|MAX_PLAYERS|Max Players that can be on the server at once. Minimum 1, Maximum 8|8
|JOIN_PASSWORD|Password required to join the server. Leave empty to not use a password.|
|ADMIN_PASSWORD|Password required for using admin RCON commands.<br /> **NOTE:** Do not leave empty, otherwise any player can have RCON admin access by default. 
|SHUTDOWN_NOT_JOINED_FOR|When the server starts up, if no players join within this time, the server will shutdown and return to lobby. During this window the game will be paused. <br />Values of < 0 will cause the server to run indefinitely. <br />A value of 0 will cause the server to shutdown immediately. <br />Values of > 0 will wait that time in SECONDS.|-1
|SHUTDOWN_EMPTY_FOR|When the server becomes empty the server will shutdown and return to lobby after this time (in seconds). During this window the game will be paused. <br />Values of < 0 will cause the server to run indefinitely. <br />A value of 0 will cause the server to shutdown immediately. <br />Values of > 0 will wait that time in SECONDS.|-1
|ALLOW_NON_ADMINS_LAUNCH|If true anyone who joins the lobby can create a new prospect or load an existing one. If false players will be required to login as admin in order to create or load a prospect.|True
|ALLOW_NON_ADMINS_DELETE|If true anyone who joins the lobby can delete prospects from the server. If false players will be required to login as admin in order to delete a prospect.|False
|LOAD_PROSPECT|Attempts to load a prospect by name from the home/steam/.wine/drive_c/icarus/Saved/PlayerData/DedicatedServer/Prospects/ folder.|
|CREATE_PROSPECT|Creates and launches a new prospect. <br />**[ProspectType] [Difficulty] [Hardcore?] [SaveName]** <br />ProspectType - The internal name of the prospect to launch <br />Difficulty - A value of 1 to 4 for the difficulty (1 = easy, 4 = extreme) <br />Hardcore? - True or False value for if respawns are disabled <br />SaveName - The save name to use for this prospect. Must be included for outposts, if not included with regular prospects this will generate a random name. <br />**Example:** "Tier1_Forest_Recon_0 3 false TestProspect01" Will create a prospect on the tutorial prospect on hard difficulty and save it as TestProspect01|
|RESUME_PROSPECT|Resumes the last prospect from the config file|True
|STEAM_USERID| Linux User ID on the HOST used by the container steam user and volumes|1000
|STEAM_GROUPID| Linux Group ID on the HOST used by the container steam user and volumes|1000
|STEAM_ASYNC_TIMEOUT| Sets the Async timeout to this value in the Engine.ini on server start in SECONDS| 60
|BRANCH| Version branch (public or experimental)| public
|SAVEGAMEONEXIT| Whether to force save when the game exits (True/False) | True
|GAMESAVEFREQUENCY| How many MINUTES between each save
|FIBERFOLIAGERESPAWN| Whether to have foliage that was removed respawns over time (True/False) (can help with performance)
|LARGESTONESRESPAWN|  Whether to have large stones that have been mined to respawn over time (True/False) (can help with performance)
|TZINFO| Time Zone (lookup params for tzdata) | America/Los_Angeles

## Ports
The server requires 2 UDP Ports, the game port (Default 17777) and the query port (Default 27015)
They can be changed by specifying the PORT and QUERYPORT env vars respectively.

## Volumes
- The server binaries are stored at /game/icarus
- The server game data e.g. saved prospects, configs, serversettings.ini are stored at /home/steam/.wine/drive_c/icarus

**Note:** by default, the container volumes are owned by user 1000:1000. Please set the permissions of the mounted volumes on the host accordingly. Define the STEAM_USERID and STEAM_GROUPID environment variables with the UID and GID of the host user to ensure that permissions across volume mounts are aligned between container and host. 

## Example Docker Run
```bash
docker run -p 17777:17777/udp -p 27015:27015/udp -v data:/home/steam/.wine/drive_c/icarus -v game:/game/icarus -e SERVERNAME=AmazingServer -e JOIN_PASSWORD=mypassword -e ADMIN_PASSWORD=mysupersecretpassword  slautomaton/icarus:latest
```
## Example Docker Compose
```yaml
services:
  icarus:
    container_name: icarus-dedicated
    image: slautomaton/icarus:latest
    hostname: icarus-dedicated
    init: true
    restart: "unless-stopped"
    ports:
      - 17777:17777/udp
      - 27015:27015/udp
    volumes:
      - /host/path/to/folder/data:/home/steam/.wine/drive_c/icarus/ ## Create Saved/PlayerData/DedicatedServer/Prospects and upload your previous json save here. Cd
                                                                    ## into Saved/Config/WindowsServer. Container will write ServerSettings.ini into it.
      - /host/path/to/folder/game:/game/icarus ## game binaries will install here inside the container. From your mounted drive, create the /Icarus/Content/Paks/mods                                                    ## folder. That is where you upload your mod _P.paks or .EXMOD files (use the latter).
      - /host/path/to/folder/logs:/home/steam/Steam/logs ## Easier access to logs written on the container.
    environment:
      - SERVERNAME=myAmazingServer
      - BRANCH=public
      - PORT=17777
      - QUERYPORT=27015
      - JOIN_PASSWORD=mypassword
      - ADMIN_PASSWORD=mysupersecretpassword
      - STEAM_USERID=1000
      - STEAM_GROUPID=1000
      - STEAM_ASYNC_TIMEOUT=60

```

## Security
We should not hard code passwords into configs like above. We can/should use a **`.env`** file for our passwords. 

In the same working directory as your **`docker-compose.yml`**:

```bash
touch .env
nano .env
```

**`.env`** contents should simply be:

```yaml
JOIN_PASSWORD=mypassword
ADMIN_PASSWORD=mysupersecretpassword
```

Update your **`docker-compose.yml`** to pick up **`.env`** variables:

```yaml
- JOIN_PASSWORD=${JOIN_PASSWORD}
- ADMIN_PASSWORD=${ADMIN_PASSWORD}
```

Finally, use ```bash docker compose config --environment ``` to verify variables are picked up.

Note: stick with **`.env`**. Named environmental files like **`example.env`** will not work. Also update your **`.gitignore`** and **`.dockerignore`** to include /.env* so that you dont upload your passwords into your repos.

## License
MIT License

## Known Issues

* Out of memory error: `Freeing x bytes from backup pool to handle out of memory`
  and `Fatal error: [File: Unknown] [Line: 197] \nRan out of memory allocating 0 bytes with alignment 0\n` but system
  has enough memory.
  * **Solution:** Increase maximum number of memory map areas (vm.max_map_count) tested with `262144`<br/>
    **temporary:**
    ```bash
      sysctl -w vm.max_map_count=262144
    ```
    **permanent:**
    ```bash
      echo "vm.max_map_count=262144" >> /etc/sysctl.conf && sysctl -p
    ```

  **Credit:** Thanks to Icarus discord user **Fabiryn** for the solution. 
  
### Thanks to Nerodon for building this first, and setting a license that lets me upskill.

See his repo here: https://gitlab.com/fred-beauch/icarus-dedicated-server


