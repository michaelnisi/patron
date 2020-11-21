all: clean

clean:
	-rm -rf .build .pid

Tests/Server/node_modules:
	cd Tests/Server && npm install

.pid:
	./Tests/start_server.sh

# test = swift test
destination = 'platform=iOS Simulator,name=iPhone 12,OS=14.0'
test = xcodebuild -scheme Patron -sdk iphonesimulator -destination $(destination) build test

test: Tests/Server/node_modules .pid
	$(test) && ./Tests/stop_server.sh

.PHONY: all clean test
