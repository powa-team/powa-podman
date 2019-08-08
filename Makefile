all:
	$(MAKE) -C powa-archivist
	cp -r misc/powa-web.conf powa-web/
	cp -r misc/powa-web.conf powa-web-git/
	cp -r misc/powa-collector.conf powa-collector/
	cp -r misc/powa-collector.conf powa-collector-git/
images: all git
	./build_all.sh

git:
	cp -r misc/setup_powa-archivist.sh powa-archivist-git/
	cp -r misc/install_all_powa_ext.sql powa-archivist-git/
	cp -r misc/powa-web.conf powa-web-git/
	docker build -q --no-cache -t powateam/powa-archivist-git powa-archivist-git
	docker build -q --no-cache -t powateam/powa-web-git powa-web-git
	docker build -q --no-cache -t powateam/powa-collector-git powa-collector-git
