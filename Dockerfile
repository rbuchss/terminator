################################################################################
# Args
################################################################################

ARG BUILDER_IMAGE_NAME=rbuchss/terminator-tester-builder
ARG IMAGE_BASH_PATH=/usr/local/bin/bash
ARG USER=kyle-reese
ARG GROUP=skynet-resistance
ARG WORKDIR=/opt

################################################################################
# Tester Image - Uses builder image to speed up test image setup
################################################################################

FROM ${BUILDER_IMAGE_NAME} as terminator-tester

# We need to export ARG in each stage to make them available
ARG IMAGE_BASH_PATH
ARG USER
ARG GROUP
ARG WORKDIR

ENV BASH_PATH=${IMAGE_BASH_PATH}

WORKDIR ${WORKDIR}

RUN addgroup ${GROUP}

RUN adduser \
  --disabled-password \
  --gecos "" \
  --shell ${BASH_PATH} \
  --ingroup ${GROUP} \
  ${USER}

RUN chown --recursive ${USER}:${GROUP} ${WORKDIR}

USER ${USER}

COPY --chown=${USER}:${GROUP} . .

CMD exec make
