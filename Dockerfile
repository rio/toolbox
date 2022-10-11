FROM docker.io/library/debian:11.4

ARG UID=1000
ARG DOCKER_GID=976

RUN apt update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt install -y --no-install-recommends \
      vim \
      curl \
      unzip \
      ca-certificates \
      git \
      openssh-client \
      zsh \
      bind9-dnsutils \
      sudo && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN echo '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/toolbox && chmod 440 /etc/sudoers.d/toolbox

COPY --from=ghcr.io/k3d-io/k3d:5.4-dind /bin/k3d /usr/local/bin/k3d
COPY --from=ghcr.io/k3d-io/k3d:5.4-dind /usr/local/bin/docker /usr/local/bin/docker
COPY --from=ghcr.io/k3d-io/k3d:5.4-dind /usr/local/bin/kubectl /usr/local/bin/kubectl

COPY --from=k8s.gcr.io/kustomize/kustomize:v4.5.5 /app/kustomize /usr/local/bin/kustomize

COPY --from=gcr.io/kpt-dev/kpt:v1.0.0-beta.20 /usr/local/bin/kpt /usr/local/bin/kpt

COPY --from=docker.io/loftsh/vcluster:0.12.2 /vcluster /usr/local/bin/vcluster

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

RUN curl -sSfLo /tmp/k9s.tar.gz https://github.com/derailed/k9s/releases/download/v0.26.3/k9s_Linux_x86_64.tar.gz && \
    echo '3447ac17cfa46fe91ab2bfcb021d43f7f2d40ac37c7b573241a511b85fc162cf  /tmp/k9s.tar.gz' | sha256sum -c - && \
    tar xf /tmp/k9s.tar.gz --directory=/usr/local/bin k9s && \
    rm /tmp/k9s.tar.gz

RUN curl -sSfLo /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.2.9/terraform_1.2.9_linux_amd64.zip && \
    echo '0e0fc38641addac17103122e1953a9afad764a90e74daf4ff8ceeba4e362f2fb  /tmp/terraform.zip' | sha256sum -c - && \
    unzip -d /usr/local/bin /tmp/terraform.zip terraform && \
    rm /tmp/terraform.zip

RUN curl -sSfLo /tmp/flux.tar.gz https://github.com/fluxcd/flux2/releases/download/v0.34.0/flux_0.34.0_linux_amd64.tar.gz && \
    echo '9f72f4b821d534f4298fa33c93e28bc0ef13f851f634e4249a63f3c797f94412  /tmp/flux.tar.gz' | sha256sum -c - && \
    tar xf /tmp/flux.tar.gz --directory=/usr/local/bin flux && \
    rm /tmp/flux.tar.gz

RUN curl -sSfLo /tmp/istio.tar.gz https://github.com/istio/istio/releases/download/1.15.0/istio-1.15.0-linux-amd64.tar.gz && \
    echo '5d84897dc25be6757568ef50bb3ddf86388456768cd658ed2670a4f12803c3f8 /tmp/istio.tar.gz' | sha256sum -c - && \
    tar xf /tmp/istio.tar.gz --strip-components=2 --directory=/usr/local/bin istio-1.15.0/bin/istioctl && \
    rm /tmp/istio.tar.gz

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
