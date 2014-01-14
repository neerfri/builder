build:
	docker build -t deis/builder .

config:
	-etcdctl -C $${ETCD:-127.0.0.1:4001} setdir /deis
	-etcdctl -C $${ETCD:-127.0.0.1:4001} setdir /deis/builder
	etcdctl -C $${ETCD:-127.0.0.1:4001} set /deis/builder/port $${PORT:-22}

run:
	docker run -p $${PORT:-22}:$${PORT:-22} deis/builder ; exit 0

shell:
	docker run -t -i -rm deis/builder /bin/bash

clean:
	-docker rmi deis/builder