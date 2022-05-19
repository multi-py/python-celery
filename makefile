

build_test:
	docker build --progress=plain \
		--build-arg python_version=3.10 \
		--build-arg package_version=5.2.3 \
		--build-arg package=celery\[gevent\] \
		-t multi-py-celery:test .


build_test_arm_v7:
	docker build --progress=plain \
		--build-arg python_version=3.10 \
		--build-arg package_version=5.2.3 \
		--build-arg package=celery\[gevent\] \
		--platform=linux/arm/v7 \
		-t multi-py-celery:test .


build_alpine:
	docker build --progress=plain \
		--build-arg python_version=3.10 \
		--build-arg build_target=alpine \
		--build-arg publish_target=alpine  \
		--build-arg package_version=5.2.3 \
		--build-arg package=celery\[gevent\] \
		-t multi-py-celery:test .


build_alpine_arm_v7:
	docker build --progress=plain \
		--build-arg python_version=3.10 \
		--build-arg build_target=alpine \
		--build-arg publish_target=alpine  \
		--build-arg package_version=5.2.3 \
		--build-arg package=celery\[gevent\] \
		--platform=linux/arm/v7 \
		-t multi-py-celery:test .




run_test:
	docker compose up --build
