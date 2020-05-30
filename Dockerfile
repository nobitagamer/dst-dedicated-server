FROM debian:latest

LABEL \
    maintainer="Nguyen Khac Trieu <trieunk@yahoo.com>" \
    description="Don't Starve Together dedicated server" \
    source="https://github.com/nobitagamer/dst-dedicated-server"

# Create specific user to run DST server
RUN useradd -ms /bin/bash/ dst
WORKDIR /home/dst

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386 && apt-get update

RUN apt install -y locales apt-utils debconf-utils
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

ENV DEPOT_DOWNLOADER_VERSION 2.3.5
ENV DEPOT_APPID=343050
ENV DEPOT_ID=343051

# Don't Starve Together version: 413172
ENV DEPOT_MANIFEST=6669740038738489084

# Add Microsoft repository key and feed
RUN apt-get install -y wget gnupg \
    && wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
    && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
    && wget https://packages.microsoft.com/config/debian/10/prod.list \
    && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
    && chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
    && chown root:root /etc/apt/sources.list.d/microsoft-prod.list

# Install required packages
RUN set -x \
    && apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        nano \
        unzip \
        ca-certificates \
        lib32gcc1 \
        lib32stdc++6 \
        libcurl4-gnutls-dev:i386 \
        apt-transport-https \
        dotnet-runtime-3.1 \
    && chown -R dst:dst ./ && \
    # Cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER dst
RUN mkdir -p .klei/DoNotStarveTogether server_dst/mods

RUN wget https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/depotdownloader-${DEPOT_DOWNLOADER_VERSION}.zip -O depotdownloader.zip \
    && unzip depotdownloader.zip -d depotdownloader \
    && rm -f depotdownloader.zip

# Install Don't Starve Together
RUN dotnet depotdownloader/DepotDownloader.dll \
    -validate -app $DEPOT_APPID -depot $DEPOT_ID \
    -manifest $DEPOT_MANIFEST \
    -dir /home/dst/server_dst

VOLUME ["/home/dst/.klei/DoNotStarveTogether", "/home/dst/server_dst/mods"]

COPY ["start-container-server.sh", "/home/dst/"]
ENTRYPOINT ["/home/dst/start-container-server.sh"]
