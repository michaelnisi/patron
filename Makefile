project=Patron.xcodeproj
scheme=Patron
sdk=iphonesimulator

all: clean build

clean:
	-rm -rf build

build:
	xcodebuild -configuration Debug build

start_server:
	./start_server.sh

test: start_server
	xctool test \
		-project $(project) \
		-scheme $(scheme) \
		-sdk $(sdk) \
		-reporter pretty
	./stop_server.sh

.PHONY: all clean test start_server
