################################################################################
# Args
################################################################################

ARG BUILDER_IMAGE_NAME=rbuchss/terminator-tester-builder
ARG IMAGE_BASH_PATH=/usr/local/bin/bash
ARG USER=kyle-reese
ARG GROUP=skynet-resistance
ARG WORKDIR=/cyberdyne

################################################################################
# Tester Image - Uses builder image to speed up test image setup
################################################################################

FROM ${BUILDER_IMAGE_NAME} as terminator-tester-base

# We need to export any ARG's we want in each stage to make them available
ARG IMAGE_BASH_PATH

ENV BASH_PATH=${IMAGE_BASH_PATH}

################################################################################
# Local docker version
################################################################################

FROM terminator-tester-base as terminator-tester-local

# We need to export any ARG's we want in each stage to make them available
ARG USER
ARG GROUP
ARG WORKDIR

WORKDIR ${WORKDIR}

ENV TERMINATOR_MODULE_SRC_DIR=${WORKDIR}/terminator/src

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

CMD exec make guards

################################################################################
# Github actions docker version
# Note Github recommends that we do not set USER and WORKDIR:
# ref https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions
################################################################################

FROM terminator-tester-base as terminator-tester-github-actions

# Set working directory for GitHub Actions (even though GH docs recommend not to,
# we need it to properly locate terminator source files)
WORKDIR /github/workspace

ENV TERMINATOR_MODULE_SRC_DIR=/github/workspace/terminator/src

COPY . .

ENTRYPOINT ["./.github/actions/run-make/entrypoint.sh"]
