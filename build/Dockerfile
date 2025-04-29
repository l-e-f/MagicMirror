FROM karsten13/magicmirror:latest

USER root

COPY ./build/entrypoint.sh .
RUN apt update && apt install -y dos2unix && dos2unix entrypoint.sh

RUN chmod +x ./entrypoint.sh

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

ENTRYPOINT ["./entrypoint.sh", "npm", "run", "server"]
