{% set short_repository = repository.split("/")[1] -%}

### Add Your App

By default the startup script checks for the following packages and uses the first one it can find-

* `/app/app/worker.py`
* `/app/worker.py`

By default the celery application should be inside the package in a variable named `celery`. Both the locations and variable name can be changed via environment variables.

If you are using pip to install dependencies your dockerfile could look like this-

```dockerfile
FROM ghcr.io/{{ organization  }}/{{ short_repository }}:py{{ python_versions|last }}-{{ package_versions|last }}

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
