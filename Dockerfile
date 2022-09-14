FROM docker.io/library/debian:11.4

ARG UID=1000
ARG DOCKER_GID=976

RUN apt update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt install -y --no-install-recommends \
      vim \
      curl \
      ca-certificates \
      git \
      openssh-client \
      zsh \
      sudo

RUN echo '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/toolbox && chmod 440 /etc/sudoers.d/toolbox

COPY --from=ghcr.io/k3d-io/k3d:5.4-dind /bin/k3d /usr/local/bin/k3d
COPY --from=ghcr.io/k3d-io/k3d:5.4-dind /usr/local/bin/docker /usr/local/bin/docker
COPY --from=ghcr.io/k3d-io/k3d:5.4-dind /usr/local/bin/kubectl /usr/local/bin/kubectl

RUN curl -sSfLo /tmp/helm.tar.gz  https://get.helm.sh/helm-v3.9.4-linux-amd64.tar.gz && \
    echo '31960ff2f76a7379d9bac526ddf889fb79241191f1dbe2a24f7864ddcb3f6560  /tmp/helm.tar.gz' | sha256sum -c - && \
    tar xf /tmp/helm.tar.gz --strip-components=1 --directory=/usr/local/bin linux-amd64/helm && \
    rm /tmp/helm.tar.gz

RUN curl -sSfLo /usr/local/bin/skaffold https://storage.googleapis.com/skaffold/releases/v1.39.2/skaffold-linux-amd64 && \
    echo '6ecdda952ce8e917dde9a362859952dd1d3ad8ae44b2c56696ec6a89c5d8ce4d  /usr/local/bin/skaffold' | sha256sum -c - && \
    chmod +x /usr/local/bin/skaffold

RUN curl -sSfLo /tmp/chezmoi.tar.gz https://github.com/twpayne/chezmoi/releases/download/v2.22.1/chezmoi_2.22.1_linux_amd64.tar.gz && \
    echo '6ab4593b807e9c2db7536540b00537d61aff00726ff7a6a79e449285f3480b52  /tmp/chezmoi.tar.gz' | sha256sum -c - && \
    tar xf /tmp/chezmoi.tar.gz --directory=/usr/local/bin chezmoi && \
    rm /tmp/chezmoi.tar.gz

RUN groupadd --gid ${DOCKER_GID} docker
RUN useradd \
	--uid ${UID} \
	--create-home \
	--user-group \
	--groups sudo,docker \
	--shell /bin/zsh \
	toolbox

RUN cp -v /etc/zsh/newuser.zshrc.recommended /home/toolbox/.zshrc

USER toolbox
WORKDIR /home/toolbox

COPY ./scripts ./scripts
