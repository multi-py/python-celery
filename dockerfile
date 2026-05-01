ARG python_version=3.9
ARG build_target=$python_version
ARG publish_target=$python_version
ARG OTEL_ENABLED=false

FROM python:$build_target as Builder

# Add arguments to container scope
ARG build_target
ARG package
ARG package_version
ARG TARGETPLATFORM
ARG OTEL_ENABLED

# Only add build tools for alpine image. The ubuntu based images have build tools already.
# Only runs if `apk` is on the system.
RUN if which apk ; then apk add python3-dev libffi-dev libevent-dev build-base bash; fi

# Install rust on alpine if not using linux/arm/v7
RUN bash -c 'if which apk && [[ "$TARGETPLATFORM" != "linux/arm/v7" ]] ; then apk add cargo rust gcc musl-dev; fi'

# Install rust on alpine if not using linux/arm/v7
RUN bash -c 'if which apt-get && [[ "$TARGETPLATFORM" != "linux/arm/v7" ]] ; then curl https://sh.rustup.rs -sSf | bash -s -- -y; fi'
ENV PATH="/root/.cargo/bin:${PATH}"


# Watchfiles will not work on linux/arm/v7.
RUN bash -c 'if [[ "$TARGETPLATFORM" == "linux/arm/v7" ]] ; then pip install $package==$package_version ; fi'
RUN bash -c 'if [[ "$TARGETPLATFORM" != "linux/arm/v7" ]] ; then pip install $package==$package_version watchfiles>=0.15 ; fi'

# Install OpenTelemetry packages if enabled.
RUN bash -c 'if [[ "$OTEL_ENABLED" == "true" ]] ; then pip install opentelemetry-distro opentelemetry-exporter-otlp && opentelemetry-bootstrap -a install ; fi'


# Build our actual container now.
FROM python:$publish_target

# Add args to container scope.
ARG publish_target
ARG python_version
ARG package
ARG maintainer=""
ARG TARGETPLATFORM=""
ARG OTEL_ENABLED=false
LABEL python=$python_version
LABEL package=$package
LABEL maintainer=$maintainer
LABEL otel_enabled=$OTEL_ENABLED
LABEL org.opencontainers.image.description="python:$publish_target $package:$package_version $TARGETPLATFORM"

# Used for Celery Beat.
RUN mkdir /var/celery


# Copy all of the python files built in the Builder container into this smaller container.
COPY --from=Builder /usr/local/lib/python$python_version /usr/local/lib/python$python_version

# Copy binaries (e.g. opentelemetry-instrument) installed by pip in the Builder stage.
COPY --from=Builder /usr/local/bin /usr/local/bin

# Entrypoint Script
COPY ./assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Example application so container "works" when run directly.
COPY ./assets/worker.py /app/worker.py
WORKDIR /app/

ENV PYTHONPATH=/app

CMD ["/entrypoint.sh"]
