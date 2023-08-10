# LiveStreamDVR

[![Check Server](https://github.com/MrBrax/LiveStreamDVR/actions/workflows/check-server.yml/badge.svg)](https://github.com/MrBrax/LiveStreamDVR/actions/workflows/check-server.yml) [![Check Client](https://github.com/MrBrax/LiveStreamDVR/actions/workflows/check-client.yml/badge.svg)](https://github.com/MrBrax/LiveStreamDVR/actions/workflows/check-client.yml) [![Publish Docker image](https://github.com/MrBrax/LiveStreamDVR/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/MrBrax/LiveStreamDVR/actions/workflows/docker-publish.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/mrbrax/twitchautomator) ![Server version](https://img.shields.io/badge/dynamic/json?color=darkgreen&url=https://raw.githubusercontent.com/MrBrax/LiveStreamDVR/master/server/package.json&query=$.version&label=Server) ![Client version](https://img.shields.io/badge/dynamic/json?color=darkgreen&url=https://raw.githubusercontent.com/MrBrax/LiveStreamDVR/master/client-vue/package.json&query=$.version&label=Client)

![1603661434863-wc](https://user-images.githubusercontent.com/1517911/97119662-fe1b0a80-1711-11eb-8f40-20c1690a01c9.png)


⚠️⚠️⚠️

*Until Twitch changes the max quota on Websocket Eventsubs, a public facing HTTPS server is required for this application to function.*

A reverse proxy is a good way to get around this:
- [Nginx](https://www.nginx.com/)
- [Apache](https://httpd.apache.org/)
- [Caddy](https://caddyserver.com/)
- [Traefik](https://traefik.io/)
- [Tailscale Funnel](https://tailscale.com/kb/1223/tailscale-funnel/) *(Docker-only; see configuration below)*

etc. I have only tested this with Nginx and letsencrypt.

⚠️⚠️⚠️



## Features
- Automatic VOD recording around when the stream goes live, instead of checking it every minute like many other scripts do.
    - Because of notification delays, the stream usually starts capturing after ~2 minutes after the stream goes live.
- Cyclic recording, as in when a specified amount or storage per streamer is reached, the oldest stream gets deleted.
- Tons of metadata, maybe too much. Stores info about games played, stream titles, duration, if the stream got muted from copyrighted music, etc.
- Viewer count logging with graphs.
- Chapters (titles and games) are written to the final video file.
- [Video player](https://github.com/MrBrax/twitch-vod-chat) with chat playback.
- Video cutter with chapter display for easy exporting, also cuts the downloaded chat for synced rendering.
- Notifications with optional speech when the website is open, get stream live notifications far earlier than the mobile app does.
- Writes a [losslesscut](https://github.com/mifi/lossless-cut/) compatible csv file for the full VOD, so you don't have to find all the games.
- Uses `ts` instead of `mp4` so if the stream or program crashes, the file won't be corrupted.
- Audio only support.
- Optionally either dumps chat while capturing or downloads the chat file after it's done.
- Basic tools for downloading any VOD, chat, or clip.
- Can be set to automatically download the whole stream chat to a JSON file, to be used in my [twitch-vod-chat](https://github.com/MrBrax/twitch-vod-chat) webapp or automatically burned in with [TwitchDownloader](https://github.com/lay295/TwitchDownloader).
- Basic webhook support for external scripting.
- Notifications over the browser, telegram, pushover, and discord.
- Mobile friendly site with PWA.
- Exporting of videos to external file, SFTP, and YouTube.
    - Can be enabled for all finished captures
    - Can be run for an entire channel at once

*One high-profile streamer VOD of 10 hours at 1080p60 is about 30-50GB.*

Post issues/help on the issues tab above. I already run an up-to-date version, so starting fresh might break stuff.

Thanks to the contributors that helped expand the project!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y4ES6VE)

<a href="https://jb.gg/OpenSourceSupport">
    <img src="https://resources.jetbrains.com/storage/products/company/brand/logos/WebStorm.png" alt="WebStorm" height="50">
</a>

---
## Docker setup

Reminder that I don't use docker myself on my capturing setup, so any specific errors to this are hard to test.


### Docker hub

1. Download the [docker-compose.yml](https://raw.githubusercontent.com/MrBrax/LiveStreamDVR/master/docker-compose.yml) file and place it in a directory.
2. Run `docker-compose pull` and `docker-compose up -d` to start it.
3. Visit the webapp at `localhost:8082`
4. Check stored vods in the `/data/storage` directory. Permissions might be an issue.

Hub: https://hub.docker.com/r/mrbrax/twitchautomator

*The dockerhub build is preconfigured to be hosted at the root (`/`) and such, does not work when placed in a subdirectory.*

### Manual build
Run `docker-compose up --build -d` in the app directory. The `docker-compose.yml` file is required.

If you want the public webapp to have a custom base folder, you must provide `BASE_URL` and `VITE_BASE_URL` in the environment variable settings.

### Tailscale support
You can use [Tailscale Funnel](https://tailscale.com/kb/1223/tailscale-funnel/) to allow incoming traffic from port 443. Note that Tailscale Funnel is in beta and must be enabled in your Tailscale account and your tailnet policy file. You also need to have HTTPS enabled for your Tailscale account.

Once the environment variables below have been set and the container has been setup, your App URL will be something like https://livestreamdvr.tailnet-name.ts.net. 

#### Tailscale configuration

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `TAILSCALE_ENABLE` | `false` | Set to true to enable Tailscale integration. |
| `TAILSCALE_AUTH_KEY` | None | An auth key for your Tailscale account, created in your [account settings](https://login.tailscale.com/admin/settings/keys). **Required if `TAILSCALE_ENABLE` is true.** |
| `TAILSCALE_ENABLE_SSH` | `false` | Set to true to enable SSH access via Tailscale. |

---

## Standalone setup

### Main requirements
- [node.js](https://nodejs.org/) 18+
- npm and yarn 3+
- Python 3.11+
- [pip](https://pypi.org/project/pip/)
- [FFmpeg](https://ffmpeg.org/download.html)
- [MediaInfo](https://mediaarea.net/en/MediaInfo)
- [TwitchDownloader](https://github.com/lay295/TwitchDownloader) (optional for chat downloading and burning)
- Public facing webserver (nginx, apache, etc) for reverse proxy with an HTTP certificate that's valid (Let's Encrypt works fine)


### pip packages
- [streamlink](https://github.com/streamlink/streamlink) (required)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) (not used at the moment)
- [tcd](https://github.com/PetterKraabol/Twitch-Chat-Downloader) (optional)

### Steps

1. Clone the repository with submodules `git clone --recurse-submodules https://github.com/MrBrax/LiveStreamDVR.git` (zip download doesn't include submodules, [Git help](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository?tool=webui)
    - If anyone knows how to make an automatic zip release with all the packages using GitHub Actions, please let me know.
2. Place the downloaded files in a folder with good permissions.
3. Enter the root folder and run `pip install -r requirements.txt`
4. Build the packages (yarn pnp is now used, so `yarn install` might not be required)
    - Enter the `/twitch-vod-chat` folder and run `yarn install` and `yarn run buildlib`.
    - Enter the `/client-vue` folder and run `yarn install` and `yarn run build`.
    - Enter the `/server` folder and run `yarn install` and `yarn run build`.
    - Enter the `/twitch-chat-dumper` folder and run `yarn install` and `yarn run build`.
5. In the `/server` folder, run `yarn run start` to start the server in production mode.
6. Go to the settings page and set up basic stuff, get api key from twitch dev site.
7. Check the About page for subscription status.
8. Check stored vods in the `/data/storage` directory. Permissions might be an issue.

Follow this guide to hackjob nginx: https://serversforhackers.com/c/nginx-php-in-subdirectory

## Command line arguments
### `--port <number>`
Specify port to run the server on.

### `--debug`
Run the server in debug mode.

### `--dataroot <path>`
Specify the data directory to use.

### `--home`
Store the data in the home directory.

---

## Environment variables
### `TCD_ENABLE_FILES_API=1`

Enable the files api, making it possible to download and delete files in storage.
*This might open up filesystem exploits.*

### `TCD_EXPOSE_LOGS_TO_PUBLIC=1`

Make viewing logs in the file manager possible. Requires the above environment variable to be set.

### `TCD_MIGRATE_OLD_VOD_JSON=1`

Migrate old vod json files to the new format. This is automatically done when the server starts.
Make sure to back up your data before doing this, as it will overwrite the old files and can't be undone. Bugs might occur, so use with caution.