

![Docker Pulls](https://img.shields.io/docker/pulls/nerodon/icarus-dedicated)
![Docker Stars](https://img.shields.io/docker/stars/nerodon/icarus-dedicated)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/nerodon/icarus-dedicated/latest)
![GitLab (self-managed)](https://img.shields.io/gitlab/license/fred-beauch/icarus-dedicated-server)



For assistance, message **@Nerodon** on the official Icarus Discord or open an issue on Gitlab

[<img src="https://img.shields.io/badge/Discord-Linux_Docker_Support-7289da?logo=discord&logoColor=white">](https://discord.com/channels/715761957667602502/1048852109996593172)
[<img src="https://img.shields.io/badge/Repository-Gitlab-orange?logo=gitlab">](https://gitlab.com/fred-beauch/icarus-dedicated-server)



# icarus-dedicated-server
This dedicated server will automatically download/update to the latest available server version when started. The dedicated server runs in Ubuntu 24.04 and wine

## Environment Vars
Refer to https://github.com/RocketWerkz/IcarusDedicatedServer/wiki/Server-Config-&-Launch-Parameters for more detail on server configs
| ENV Var | Description| Default Value if unspecified|
|---------|------------|-----------------------------|
|SERVERNAME| The name of the server on the server browser| Icarus Server
|PORT| The game port| 17777
|QUERYPORT| The query port| 27015
|JOIN_PASSWORD|Password required to join the server. Leave empty to not use a password.|
|MAX_PLAYERS|Max Players that can be on the server at once. Minimum 1, Maximum 8|8
|ADMIN_PASSWORD|Password required for using admin RCON commands.<br /> **NOTE:** If left empty just using the RCON /AdminLogin will give admin privilege's to a player (effectively an empty password)|admin
|SHUTDOWN_NOT_JOINED_FOR|When the server starts up, if no players join within this time, the server will shutdown and return to lobby. During this window the game will be paused. <br />Values of < 0 will cause the server to run indefinitely. <br />A value of 0 will cause the server to shutdown immediately. <br />Values of > 0 will wait that time in seconds.|-1
|SHUTDOWN_EMPTY_FOR|When the server becomes empty the server will shutdown and return to lobby after this time (in seconds). During this window the game will be paused. <br />Values of < 0 will cause the server to run indefinitely. <br />A value of 0 will cause the server to shutdown immediately. <br />Values of > 0 will wait that time in seconds.|-1
|ALLOW_NON_ADMINS_LAUNCH|If true anyone who joins the lobby can create a new prospect or load an existing one. If false players will be required to login as admin in order to create or load a prospect.|True
|ALLOW_NON_ADMINS_DELETE|If true anyone who joins the lobby can delete prospects from the server. If false players will be required to login as admin in order to delete a prospect.|False
|LOAD_PROSPECT|Attempts to load a prospect by name from the Saved/PlayerData/DedicatedServer/Prospects/ folder.|
|CREATE_PROSPECT|Creates and launches a new prospect. <br />**[ProspectType] [Difficulty] [Hardcore?] [SaveName]** <br />ProspectType - The internal name of the prospect to launch <br />Difficulty - A value of 1 to 4 for the difficulty (1 = easy, 4 = extreme) <br />Hardcore? - True or False value for if respawns are disabled <br />SaveName - The save name to use for this prospect. Must be included for outposts, if not included with regular prospects this will generate a random name. <br />**Example:** "Tier1_Forest_Recon_0 3 false TestProspect01" Will create a prospect on the tutorial prospect on hard difficulty and save it as TestProspect01|
|RESUME_PROSPECT|Resumes the last prospect from the config file|True
|STEAM_USERID| Linux User ID used by the steam user and volumes|1000
|STEAM_GROUPID| Linux Group ID used by the steam user and volumes|1000
|STEAM_ASYNC_TIMEOUT| Sets the Async timeout to this value in the Engine.ini on server start| 60
|BRANCH| Version branch (public or experimental)| public
|SAVEGAMEONEXIT| Whether to force save when the game exits (True/False)
|GAMESAVEFREQUENCY| How many seconds between each save
|FIBERFOLIAGERESPAWN| Whether to have foliage that was removed respawns over time (True/False) (can help with performance)
|LARGESTONERESPAWN|  Whether to have large stones that have been mined to respawn over time (True/False) (can help with performance)

## Ports
The server requires 2 UDP Ports, the game port (Default 17777) and the query port (Default 27015)
They can be changed by specifying the PORT and QUERYPORT env vars respectively.

## Volumes
- The server binaries are stored at /game/icarus
- The server saves are stored at /home/steam/.wine/drive_c/icarus

**Note:** by default, the volumes are owned by user 1000:1000 please set the permissions to the volumes accordingly. To change the user and group ID, simply define the STEAM_USERID and STEAM_GROUPID environment variables.

## Example Docker Run
```bash
docker run -p 17777:17777/udp -p 27015:27015/udp -v data:/home/steam/.wine/drive_c/icarus -v game:/game/icarus -e SERVERNAME=AmazingServer -e JOIN_PASSWORD=mypassword -e ADMIN_PASSWORD=mysupersecretpassword  nerodon/icarus-dedicated:latest
```
## Example Docker Compose
```yaml
version: "3.8"

services:
 
  icarus:
    container_name: icarus-dedicated
    image: nerodon/icarus-dedicated:latest
    hostname: icarus-dedicated
    init: true
    restart: "unless-stopped"
    ports:
      - 17777:17777/udp
      - 27015:27015/udp
    volumes:
      - data:/home/steam/.wine/drive_c/icarus
      - game:/game/icarus
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

volumes:
  data: {}
  game: {}
 
```

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