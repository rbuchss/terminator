################################################################################
# Args
################################################################################

# defaults to macOS buggy bash version to ensure backwards compatibility
ARG IMAGE_BASH_VERSION=3.2.57
ARG IMAGE_KCOV_VERSION=v42
ARG WORKDIR=/opt

################################################################################
# Kcov stage - Compiles kcov to use downstream.
# Required since apk does include kcov
################################################################################

FROM bash:${IMAGE_BASH_VERSION} as terminator-kcov-builder

# We need to export ARG in each stage to make them available
ARG IMAGE_KCOV_VERSION
ARG WORKDIR

ENV KCOV=https://github.com/SimonKagstrom/kcov/archive/${IMAGE_KCOV_VERSION}.tar.gz

WORKDIR ${WORKDIR}

RUN apk update

RUN apk add build-base cmake ninja \
  python3 binutils-dev curl-dev elfutils-dev

RUN wget -q "${KCOV}" -O - | tar xz -C ./ --strip-components 1

RUN mkdir build \
  && cd build \
  && CXXFLAGS='-D__ptrace_request=int' cmake -G Ninja .. \
  && cmake --build . --target install

################################################################################
# Builder stage - Includes all testing and linting dependencies
################################################################################

FROM bash:${IMAGE_BASH_VERSION} as terminator-tester-builder

# We need to export ARG in each stage to make them available
ARG IMAGE_KCOV_VERSION
ARG WORKDIR

WORKDIR ${WORKDIR}

RUN apk update
RUN apk add git
RUN apk add make
# ncurses required for tput - bats pretty print
RUN apk add ncurses
RUN apk add shellcheck
RUN apk add tmux

# Adds kcov from kcov-builder stage since apk does not include kcov
# Needs to also include kcov runtime dependencies
RUN apk add python3 binutils-dev curl-dev elfutils-dev

COPY --from=terminator-kcov-builder /usr/local/bin/kcov* /usr/local/bin/
COPY --from=terminator-kcov-builder /usr/local/share/doc/kcov /usr/local/share/doc/kcov
