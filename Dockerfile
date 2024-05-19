FROM alpine:3.19.1
RUN apk update && apk add inotify-tools
RUN apk add curl
RUN mkdir -p /script
WORKDIR /script
COPY . /script
CMD ["sh","/script/script.sh"]
