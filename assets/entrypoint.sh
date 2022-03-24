#! /usr/bin/env bash
set -e

#
# The follow block is based on code from tiangolo/gunicorn-uvicorn-docker
# MIT License: https://github.com/tiangolo/gunicorn-uvicorn-docker/blob/master/LICENSE
#

if [ -f /app/app/worker.py ]; then
    DEFAULT_MODULE_NAME=app.worker
elif [ -f /app/worker.py ]; then
    DEFAULT_MODULE_NAME=worker
fi
MODULE_NAME=${MODULE_NAME:-$DEFAULT_MODULE_NAME}
VARIABLE_NAME=${VARIABLE_NAME:-celery}
export APP_MODULE=${APP_MODULE:-"$MODULE_NAME.$VARIABLE_NAME"}


# If there's a prestart.sh script in the /app directory or other path specified, run it before starting
PRE_START_PATH=${PRE_START_PATH:-/app/prestart.sh}
echo "Checking for script in $PRE_START_PATH"
if [ -f $PRE_START_PATH ] ; then
    echo "Running prestart script $PRE_START_PATH"
    . "$PRE_START_PATH"
else
    echo "There is no prestart script at $PRE_START_PATH"
fi

#
# End of tiangolo/gunicorn-uvicorn-docker block
#


if [[ "$ENABLE_BEAT" == "true" ]]; then
  COMMAND="python -m celery -A $APP_MODULE beat -s /var/celery/celerybeat-schedule"
else
  POOL=${POOL:-prefork}
  if [[ "$POOL" = "gevent" ]] || [[ "$POOL" = "eventlet" ]] ; then
    CONCURRENCY=${CONCURRENCY:-100}
  else
    CONCURRENCY=${CONCURRENCY:-2}
  fi
  COMMAND="python -m celery -A $APP_MODULE worker \
    --pool=$POOL \
    --concurrency=$CONCURRENCY \
    --prefetch-multiplier=${PREFETCH_MULTIPLIER:-4}"
  if [[ ! -z "$QUEUES" ]]; then
    COMMAND="$COMMAND --queues=$QUEUES"
  fi
fi

COMMAND="$COMMAND --loglevel=${LOG_LEVEL:-INFO}"

echo $COMMAND
$COMMAND
