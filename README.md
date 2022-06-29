# python-celery


A multiarchitecture container image for running Celery. This image precompiles dependencies such as `gevent` to speed up builds across all architectures.

Looking for the containers? [Head over to the Github Container Registry](https://github.com/multi-py/python-celery/pkgs/container/python-celery)!

<!--ts-->
* [python-celery](#python-celery)
   * [Benefits](#benefits)
      * [Multi Architecture Builds](#multi-architecture-builds)
      * [Small Images via Multi Stage Builds](#small-images-via-multi-stage-builds)
      * [No Rate Limits](#no-rate-limits)
      * [Rapid Building of New Versions](#rapid-building-of-new-versions)
      * [Regular Updates](#regular-updates)
   * [How To](#how-to)
      * [Using the Full Image](#using-the-full-image)
      * [Using the Slim Image](#using-the-slim-image)
      * [Using the Alpine Image](#using-the-alpine-image)
      * [Copy Just the Packages](#copy-just-the-packages)
      * [Add Your App](#add-your-app)
      * [PreStart Script](#prestart-script)
      * [Running the Beat Scheduler](#running-the-beat-scheduler)
      * [Switching Pools](#switching-pools)
   * [Environment Variables](#environment-variables)
      * [ENABLE_BEAT](#enable_beat)
      * [POOL](#pool)
      * [CONCURRENCY](#concurrency)
      * [PREFETCH_MULTIPLIER](#prefetch_multiplier)
      * [LOG_LEVEL](#log_level)
      * [MODULE_NAME](#module_name)
      * [VARIABLE_NAME](#variable_name)
      * [APP_MODULE](#app_module)
      * [PRE_START_PATH](#pre_start_path)
      * [RELOAD](#reload)
      * [RELOAD_SIGINT_TIMEOUT](#reload_sigint_timeout)
   * [Python Versions](#python-versions)
   * [Image Variants](#image-variants)
      * [Full](#full)
      * [Slim](#slim)
      * [Alpine](#alpine)
   * [Architectures](#architectures)
   * [Sponsorship](#sponsorship)
   * [Tags](#tags)
      * [Older Tags](#older-tags)
<!--te-->

## Benefits

### Multi Architecture Builds

Every tag in this repository supports these architectures:

* linux/amd64
* linux/arm64
* linux/arm/v7


### Small Images via Multi Stage Builds

All libraries are compiled in one image before being moved into the final published image. This keeps all of the build tools out of the published container layers.

### No Rate Limits

This project uses the Github Container Registry to store images, which have no rate limiting on pulls (unlike Docker Hub).

### Rapid Building of New Versions

Within 30 minutes of a new release to celery on PyPI builds will kick off for new containers. This means new versions can be used in hours, not days.

### Regular Updates

Containers are rebuilt weekly in order to take on the security patches from upstream containers.

## How To

### Using the Full Image
The Full Images use the base Python Docker images as their parent. These images are based off of Ubuntu and contain a variety of build tools.

To pull the latest full version:

```bash
docker pull ghcr.io/multi-py/python-celery:py3.10-LATEST
```

To include it in the dockerfile instead:

```dockerfile
FROM ghcr.io/multi-py/python-celery:py3.10-LATEST
```

### Using the Slim Image

The Slim Images use the base Python Slim Docker images as their parent. These images are very similar to the Full images, but without the build tools. These images are much smaller than their counter parts but are more difficult to compile wheels on.

To pull the latest slim version:

```bash
docker pull ghcr.io/multi-py/python-celery:py3.10-slim-LATEST
```

To include it in the dockerfile instead:

```dockerfile
FROM ghcr.io/multi-py/python-celery:py3.10-slim-LATEST
```



### Using the Alpine Image

The Alpine Images use the base Python Alpine Docker images as their parent. These images use Alpine as their operating system, with musl instead of glibc.

In theory these images are smaller than even the slim images, but this amounts to less than 30mb difference. Additional Python libraries tend not to be super well tested on Alpine. These images should be used with care and testing until this ecosystem matures.


To pull the latest alpine version:

```bash
docker pull ghcr.io/multi-py/python-celery:py3.10-alpine-LATEST
```

To include it in the dockerfile instead:

```dockerfile
FROM ghcr.io/multi-py/python-celery:py3.10-alpine-LATEST
```




### Copy Just the Packages
It's also possible to copy just the Python packages themselves. This is particularly useful when you want to use the precompiled libraries from multiple containers.

```dockerfile
FROM python:3.10

COPY --from=ghcr.io/multi-py/python-celery:py3.10-slim-LATEST /usr/local/lib/python3.10/site-packages/* /usr/local/lib/python3.10/site-packages/
```

### Add Your App

By default the startup script checks for the following packages and uses the first one it can find-

* `/app/app/worker.py`
* `/app/worker.py`

By default the celery application should be inside the package in a variable named `celery`. Both the locations and variable name can be changed via environment variables.

If you are using pip to install dependencies your dockerfile could look like this-

```dockerfile
FROM ghcr.io/multi-py/python-celery:py3.10-5.3.0

COPY requirements /requirements
RUN pip install --no-cache-dir -r /requirements
COPY ./app app
```

### PreStart Script

When the container is launched it will run the script at `/app/prestart.sh` before starting the celery service. This is an ideal place to put things like database migrations.


### Running the Beat Scheduler

If the container is launched with the environment variable `ENABLE_BEAT` it will run the beat scheduler instead of the normal worker process.

Only one scheduler should run at a time, otherwise duplicate tasks will run. The container running the scheduler will not process tasks, so a second container should be launched.

### Switching Pools

This container runs the celery defaults where appropriate, which includes using the `prefork` pool as the default option. This project precompiled `gevent` as well to enable easy switching between pool types.

Choosing the right pool is extremely important for efficient use of resources. As a starting basis you can rely on these rules-

* If the tasks are CPU bound (processing lots of data, generating images, running inference on cpu based ML models) then you should stick with the prefork model and set the `CONCURRENCY` to the number of CPUs. This will then run one task at a time split by the number of CPUs.
* If the tasks rely on external resources (filesystem reads, database calls, API requests) then the `gevent` pool with a high `CONCURRENCY` (100 per CPU to start, then adjust based on how it works) will work best. This is because these types of tasks spend more time waiting than they do processing, so more tasks are able to run at a time.

## Environment Variables

These variables are in addition to the environment variables defined by Celery itself.

### `ENABLE_BEAT`

When set to `true` the container will start the Beat Scheduler instead of a normal worker. Only one container in each cluster should have Beat enabled at a time in order to prevent duplicate tasks from being created.

Beat Schedulers will not run tasks, so at least one additional container running as a normal worker needs to be launched.

### `POOL`

Can be `prefork`, `eventlet`, `gevent`, `solo`, `processes`, or `threads`.

As a simple rule use `prefork` (the default) when your tasks are CPU heavy and `gevent` otherwise.

### `CONCURRENCY`

How many tasks to run at a time. For process based pools this will define the number of processes, and for others it will define the number of threads.

### `PREFETCH_MULTIPLIER`

The prefetch multiplier tells Celery how many items in the queue to reserve for the current worker.

### `LOG_LEVEL`

The celery log level. Must be one of the following:

- `critical`
- `error`
- `warning`
- `info`
- `debug`
- `trace`

### `MODULE_NAME`

The python module that celery will import. This value is used to generate the APP_MODULE value.

### `VARIABLE_NAME`

The python variable containing the celery application inside of the module. This value is used to generate the APP_MODULE value.

### `APP_MODULE`

The python module and variable that is passed to celery. When used the `VARIABLE_NAME` and `MODULE_NAME` environmental variables are ignored.

### `PRE_START_PATH`

Where to find the prestart script, if a developer adds one.

### `RELOAD`

If `RELOAD` is set to `true` and any files in the `/app` directory change celery will be restarted, allowing for quick debugging. This comes at a performance cost, however, and should not be enabled on production machines.

This functionality is not available on the `linux/arm/v7` images.

### `RELOAD_SIGINT_TIMEOUT`

When `RELOAD` is set this value determines how long to wait for the worker to gracefully shutdown before forcefully terminating it and reloading.

Defaults to 30 seconds.

## Python Versions

This project actively supports these Python versions:

* 3.10
* 3.9
* 3.8
* 3.7
* 3.6


## Image Variants

Like the upstream Python containers themselves a variety of image variants are supported.


### Full

The default container type, and if you're not sure what container to use start here. It has a variety of libraries and build tools installed, making it easy to extend.



### Slim

This container is similar to Full but with far less libraries and tools installed by default. If yo're looking for the tiniest possible image with the most stability this is your best bet.



### Alpine

This container is provided for those who wish to use Alpine. Alpine works a bit differently than the other image types, as it uses `musl` instead of `glibc` and many libaries are not well tested under `musl` at this time.



## Architectures

Every tag in this repository supports these architectures:

* linux/amd64
* linux/arm64
* linux/arm/v7


## Sponsorship

If you get use out of these containers please consider sponsoring me using Github!
<center>

[![Github Sponsorship](https://raw.githubusercontent.com/mechPenSketch/mechPenSketch/master/img/github_sponsor_btn.svg)](https://github.com/sponsors/tedivm)

</center>

## Tags
* Recommended Image: `ghcr.io/multi-py/python-celery:py3.10-5.3.0`
* Slim Image: `ghcr.io/multi-py/python-celery:py3.10-slim-5.3.0`

Tags are based on the package version, python version, and the upstream container the container is based on.

| celery Version | Python Version | Full Container | Slim Container | Alpine Container |
|-----------------------|----------------|----------------|----------------|------------------|
| latest | 3.10 | py3.10-latest | py3.10-slim-latest | py3.10-alpine-latest |
| latest | 3.9 | py3.9-latest | py3.9-slim-latest | py3.9-alpine-latest |
| latest | 3.8 | py3.8-latest | py3.8-slim-latest | py3.8-alpine-latest |
| latest | 3.7 | py3.7-latest | py3.7-slim-latest | py3.7-alpine-latest |
| latest | 3.6 | py3.6-latest | py3.6-slim-latest | py3.6-alpine-latest |
| 5.3.0 | 3.10 | py3.10-5.3.0 | py3.10-slim-5.3.0 | py3.10-alpine-5.3.0 |
| 5.3.0 | 3.9 | py3.9-5.3.0 | py3.9-slim-5.3.0 | py3.9-alpine-5.3.0 |
| 5.3.0 | 3.8 | py3.8-5.3.0 | py3.8-slim-5.3.0 | py3.8-alpine-5.3.0 |
| 5.3.0 | 3.7 | py3.7-5.3.0 | py3.7-slim-5.3.0 | py3.7-alpine-5.3.0 |
| 5.3.0 | 3.6 | py3.6-5.3.0 | py3.6-slim-5.3.0 | py3.6-alpine-5.3.0 |
| 5.2.7 | 3.10 | py3.10-5.2.7 | py3.10-slim-5.2.7 | py3.10-alpine-5.2.7 |
| 5.2.7 | 3.9 | py3.9-5.2.7 | py3.9-slim-5.2.7 | py3.9-alpine-5.2.7 |
| 5.2.7 | 3.8 | py3.8-5.2.7 | py3.8-slim-5.2.7 | py3.8-alpine-5.2.7 |
| 5.2.7 | 3.7 | py3.7-5.2.7 | py3.7-slim-5.2.7 | py3.7-alpine-5.2.7 |
| 5.2.7 | 3.6 | py3.6-5.2.7 | py3.6-slim-5.2.7 | py3.6-alpine-5.2.7 |
| 5.2.6 | 3.10 | py3.10-5.2.6 | py3.10-slim-5.2.6 | py3.10-alpine-5.2.6 |
| 5.2.6 | 3.9 | py3.9-5.2.6 | py3.9-slim-5.2.6 | py3.9-alpine-5.2.6 |
| 5.2.6 | 3.8 | py3.8-5.2.6 | py3.8-slim-5.2.6 | py3.8-alpine-5.2.6 |
| 5.2.6 | 3.7 | py3.7-5.2.6 | py3.7-slim-5.2.6 | py3.7-alpine-5.2.6 |
| 5.2.6 | 3.6 | py3.6-5.2.6 | py3.6-slim-5.2.6 | py3.6-alpine-5.2.6 |
| 5.2.5 | 3.10 | py3.10-5.2.5 | py3.10-slim-5.2.5 | py3.10-alpine-5.2.5 |
| 5.2.5 | 3.9 | py3.9-5.2.5 | py3.9-slim-5.2.5 | py3.9-alpine-5.2.5 |
| 5.2.5 | 3.8 | py3.8-5.2.5 | py3.8-slim-5.2.5 | py3.8-alpine-5.2.5 |
| 5.2.5 | 3.7 | py3.7-5.2.5 | py3.7-slim-5.2.5 | py3.7-alpine-5.2.5 |
| 5.2.5 | 3.6 | py3.6-5.2.5 | py3.6-slim-5.2.5 | py3.6-alpine-5.2.5 |
| 5.2.4 | 3.10 | py3.10-5.2.4 | py3.10-slim-5.2.4 | py3.10-alpine-5.2.4 |
| 5.2.4 | 3.9 | py3.9-5.2.4 | py3.9-slim-5.2.4 | py3.9-alpine-5.2.4 |
| 5.2.4 | 3.8 | py3.8-5.2.4 | py3.8-slim-5.2.4 | py3.8-alpine-5.2.4 |
| 5.2.4 | 3.7 | py3.7-5.2.4 | py3.7-slim-5.2.4 | py3.7-alpine-5.2.4 |
| 5.2.4 | 3.6 | py3.6-5.2.4 | py3.6-slim-5.2.4 | py3.6-alpine-5.2.4 |


### Older Tags

Older tags are left for historic purposes but do not receive updates. A full list of tags can be found on the package's [registry page](https://github.com/multi-py/python-celery/pkgs/container/python-celery).

