FROM karsten13/magicmirror:latest

USER root

COPY ./build/entrypoint.sh .

RUN chmod +x ./entrypoint.sh

RUN mkdir -p modules \
	&& cd modules/ \
	&& git clone https://github.com/raywo/MMM-NowPlayingOnSpotify.git \
	&& cd MMM-NowPlayingOnSpotify \
	&& npm install

RUN mkdir -p modules \
	&& cd modules/ \
	&& git clone https://github.com/wonderslug/MMM-HomeAssistantDisplay.git \
	&& cd MMM-HomeAssistantDisplay \
	&& npm install --force

RUN mkdir -p modules \
	&& cd modules/ \
	&& git clone https://github.com/sdetweil/MMM-ImagesPhotos \
	&& cd MMM-ImagesPhotos \
	&& npm install

COPY wifiQR.png modules/MMM-ImagesPhotos/uploads
COPY ../mounts/modules/MMM-NowPlayingOnSpotify/css modules/MMM-NowPlayingOnSpotify/css

ENTRYPOINT ["./entrypoint.sh", "npm", "run", "server"]
