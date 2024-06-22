BUILD_CMD = ./build_all.sh

ifneq ($(filter-out undefined, ${CONTAINER_PUSH} ${PODMAN_PUSH} ${DOCKER_PUSH}),)
BUILD_CMD += -p
endif

ifneq ($(filter-out undefined, ${CONTAINER_PUSH_YES}),)
BUILD_CMD += -y
endif

.PHONY: git git-misc powa-archivist powa-archivist-git powa-web-git powa-collector-git

all: powa-web-misc powa-collector-misc
	$(MAKE) -C powa-archivist
	cp -r misc/setup_powa-archivist.sh powa-archivist-git/
	cp -r misc/install_all_powa_ext.sql powa-archivist-git/

images: all git-misc
	${BUILD_CMD}

powa-archivist:
	$(MAKE) -C powa-archivist
	${BUILD_CMD} -i powa-archivist

powa-archivist-git-misc: misc/setup_powa-archivist.sh misc/install_all_powa_ext.sql
	cp -r misc/setup_powa-archivist.sh powa-archivist-git/
	cp -r misc/install_all_powa_ext.sql powa-archivist-git/

powa-archivist-git: powa-archivist-git-misc
	$(BUILD_CMD) -i powa-archivist-git

powa-web-misc:
	cp -r misc/powa-web.conf powa-web/
	cp -r misc/powa-web.conf powa-web-git/

powa-web: powa-web-misc
	${BUILD_CMD} -i powa-web

powa-web-git-misc: misc/powa-web.conf
	cp -r misc/powa-web.conf powa-web-git/

powa-web-git: powa-web-git-misc
	$(BUILD_CMD) -i powa-web-git

powa-collector-misc:
	cp -r misc/powa-collector.conf powa-collector/
	cp -r misc/powa-collector.conf powa-collector-git/

powa-collector: powa-collector-misc
	${BUILD_CMD} -i powa-collector

powa-collector-git-misc: misc/powa-collector.conf
	cp -r misc/powa-collector.conf powa-collector-git/

powa-collector-git: powa-collector-git-misc
	$(BUILD_CMD) -i powa-collector-git

git-misc:
	$(MAKE) powa-archivist-git-misc
	$(MAKE) powa-web-git-misc
	$(MAKE) powa-collector-git-misc

git: git-misc
	$(BUILD_CMD) -i "powa-archivist-git" -i "powa-web-git" -i "powa-collector-git"
