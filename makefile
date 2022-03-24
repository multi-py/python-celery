

build_test:
	docker build --build-arg package_version=5.2.3 --build-arg package=celery\[gevent\] -t multi-py-celery:test .

run_test:
	docker compose up --build
