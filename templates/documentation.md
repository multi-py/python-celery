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
