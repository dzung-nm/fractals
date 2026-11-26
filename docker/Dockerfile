# syntax=docker/dockerfile:1
ARG FLUTTER_IMAGE=ghcr.io/gmeligio/flutter-linux:3.50.1
FROM ${FLUTTER_IMAGE}

WORKDIR /workspace

RUN dart pub global activate melos
ENV PATH="$PATH:$HOME/.pub-cache/bin"

COPY --chown=flutter:flutter pubspec.yaml pubspec.lock* ./
COPY --chown=flutter:flutter packages/fractals_gen/pubspec.yaml ./packages/fractals_gen/
COPY --chown=flutter:flutter apps/fractals/pubspec.yaml ./apps/fractals/

RUN dart pub get

COPY --chown=flutter:flutter . .
RUN melos bootstrap
