all:
	podman build -q -t powateam/powa-pyutils powa-pyutils/
	podman build -q -t powateam/powa-pgbin powa-pgbin/
	podman build -q -t powateam/powa-pgbench powa-pgbench/
	podman build -q -t powateam/powa-web-dev powa-web-dev/
	podman build -q -t powateam/powa-collector-dev powa-collector-dev/

push: all
	podman push powateam/powa-pyutils:latest docker://docker.io/powateam/powa-pyutils:latest
	podman push powateam/powa-pgbin:latest docker://docker.io/powateam/powa-pgbin:latest
	podman push powateam/powa-pgbench:latest docker://docker.io/powateam/powa-pgbench:latest
	podman push powateam/powa-web-dev:latest docker://docker.io/powateam/powa-web-dev:latest
	podman push powateam/powa-collector-dev:latest docker://docker.io/powateam/powa-collector-dev:latest
