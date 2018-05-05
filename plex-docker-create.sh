sudo docker create \
--name=plex \
--net=host \
--restart=always \
-e VERSION=latest \
-e PUID=1000 -e PGID=1000 \
-e TZ=America/New_York \
-v /pool/videos/plex:/config \
-v /pool/videos/series:/data/tvshows \
-v /pool/videos/movies:/data/movies \
-v /pool/videos/transcode:/transcode \
linuxserver/plex
