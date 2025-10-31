FROM ubuntu:25.10

# Default Environment Vars
ENV SERVERNAME="Icarus Server"
ENV PORT=17777
ENV QUERYPORT=27015
ENV SHUTDOWN_NOT_JOINED_FOR=-1
ENV SHUTDOWN_EMPTY_FOR=-1
ENV ALLOW_NON_ADMINS_LAUNCH="True"
ENV ALLOW_NON_ADMINS_DELETE="False"
ENV MAX_PLAYERS=8
ENV TZINFO=America/Los_Angeles
ENV DEBIAN_FRONTEND=noninteractive

# Server Settings
ENV JOIN_PASSWORD=""
ENV ADMIN_PASSWORD=""
ENV LOAD_PROSPECT=""
ENV CREATE_PROSPECT=""
ENV RESUME_PROSPECT="True"
ENV SAVEGAMEONEXIT=""
ENV GAMESAVEFREQUENCY=""
ENV FIBERFOLIAGERESPAWN=""
ENV LARGESTONESRESPAWN=""

# Default User/Group ID
ENV STEAM_USERID=1000
ENV STEAM_GROUPID=1000

# Engine.ini Async Timeout
ENV STEAM_ASYNC_TIMEOUT=60

# SteamCMD Environment Vars
ENV BRANCH="public"

# Get prereq packages
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        sudo \
        wine \
        wine64 \
        tzdata && \
    ln -snf /usr/share/zoneinfo/$TZINFO /etc/localtime && \
    echo $TZINFO > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create various folders
RUN mkdir -p /root/icarus/drive_c/icarus \ 
             /game/icarus \
             /home/steam/steamcmd

# Copy run script
COPY runicarus.sh /
# Convert line endings to LF
RUN sed -i 's/\r$//' /runicarus.sh
RUN chmod +x /runicarus.sh

# Create Steam user
RUN groupadd -o -g "${STEAM_GROUPID}" steam \
  && useradd --create-home --no-log-init -o -u "${STEAM_USERID}" -g "${STEAM_GROUPID}" steam
RUN chown -R "${STEAM_USERID}":"${STEAM_GROUPID}" /home/steam
RUN chown -R "${STEAM_USERID}":"${STEAM_GROUPID}" /game/icarus

# Install SteamCMD
RUN curl -s http://media.steampowered.com/installer/steamcmd_linux.tar.gz | tar -v -C /home/steam/steamcmd -zx

ENTRYPOINT ["/bin/bash"]
CMD ["/runicarus.sh"]