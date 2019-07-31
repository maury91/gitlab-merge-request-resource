FROM alpine/git

RUN apk add --no-cache curl curl-dev bash jq

COPY scripts/ /opt/resource/
RUN chmod +x /opt/resource/*
