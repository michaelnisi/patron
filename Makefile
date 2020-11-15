all: clean

clean:
	-rm -rf build

Tests/Server/node_modules:
	cd Tests/Server && npm install

test: Tests/Server/node_modules
	./Tests/start_server.sh && swift test
	./Tests/stop_server.sh

.PHONY: all clean test
