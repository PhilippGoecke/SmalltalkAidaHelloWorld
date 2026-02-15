FROM debian:trixie-slim as build-env

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests \
     curl unzip build-essential ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/cache/apt/archives

# Create user
ARG USER=smalltalk
RUN useradd --create-home --shell /bin/bash $USER

ARG HOME="/home/$USER"
WORKDIR $HOME
USER $USER

# Install Pharo
RUN curl -L https://get.pharo.org/64/stable+vm | bash

# Install Aida/Web
RUN $HOME/pharo Pharo.image eval --save "
Metacello new
  baseline: 'Aida';
  repository: 'github://AidaWeb/Aida:master/source';
  load.
" || (cat PharoDebug.log && exit 1)

# Create Aida site and Hello World app
RUN $HOME/pharo Pharo.image eval --save "
| site app |

site := AIDASite new.
site name: 'demo'.
AIDASite default: site.

app := AIDAApplication new.
app
  name: 'hello';
  rootClass: AIDARootApp.

site addApplication: app.

AIDARootApp compile: '
main
  ^ WebElement new
      addTextH1: ''Hello World from Aida!'';
      yourself
'.
" || (cat PharoDebug.log && exit 1)

# Disable development mode
RUN $HOME/pharo Pharo.image eval --save "
AIDASite default developmentMode: false.
" || (cat PharoDebug.log && exit 1)

EXPOSE 8080

HEALTHCHECK --interval=35s --timeout=4s CMD curl --fail http://localhost:8080/hello || exit 1

# Start Aida Web Server
CMD ["/home/smalltalk/pharo", "Pharo.image", "eval", "--no-quit", "AIDASite default start"]
