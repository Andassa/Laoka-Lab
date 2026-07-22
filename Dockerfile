# Image Laoka Lab : GAMA headless officiel + modele embarque (reproductible / CI).
# Base : https://hub.docker.com/r/gamaplatform/gama
ARG GAMA_VERSION=2025.06.4
FROM gamaplatform/gama:${GAMA_VERSION}

LABEL org.opencontainers.image.title="Laoka Lab"
LABEL org.opencontainers.image.description="Batch headless GAMA pour Inona ny laoka (SMA)"
LABEL org.opencontainers.image.source="https://github.com/Andassa/Laoka-Lab"

USER root
WORKDIR /work

# Copie du projet (hors fichiers exclus par .dockerignore)
COPY . /work/

RUN mkdir -p /work/results /work/results/docker /tmp/gama_ws \
	&& chmod -R a+rwX /work/results /tmp/gama_ws

ENV GAMA_MEMORY=4096m \
	GAMA_WS=/tmp/gama_ws \
	LAOKA_MODEL=/work/models/LaokaLab.gaml

# Entrypoint = gama-headless.sh (image officielle)
# Defaut : ScenarioBase (reference)
CMD ["-m", "4096m", "-ws", "/tmp/gama_ws", "-batch", "ScenarioBase", "/work/models/LaokaLab.gaml"]
