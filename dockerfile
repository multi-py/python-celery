ARG python_version=3.9
ARG build_target=$python_version
ARG publish_target=$python_version

FROM python:$build_target as Builder

# Add arguments to container scope
ARG build_target
ARG package
ARG package_version

# Only add build tools for alpine image. The ubuntu based images have build tools already.
# Only runs if `apk` is on the system.
RUN if which apk ; then apk add python3-dev libffi-dev libevent-dev build-base ; fi

# Install package and build all dependencies.
RUN pip install $package==$package_version

# Build our actual container now.
FROM python:$publish_target

# Add args to container scope.
ARG publish_target
ARG python_version
ARG package
ARG maintainer=""
ARG TARGETPLATFORM=""
LABEL python=$python_version
LABEL package=$package
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.description="python:$publish_target $package:$package_version $TARGETPLATFORM"

# Used for Celery Beat.
RUN mkdir /var/celery

# Copy all of the python files built in the Builder container into this smaller container.
COPY --from=Builder /usr/local/lib/python$python_version /usr/local/lib/python$python_version

# Entrypoint Script
COPY ./assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Example application so container "works" when run directly.
COPY ./assets/worker.py /app/worker.py
WORKDIR /app/

ENV PYTHONPATH=/app

CMD ["/entrypoint.sh"]
