project=Patron.xcodeproj
scheme=Patron
sdk=iphonesimulator
dest='platform=iOS Simulator,name=iPhone 7'

all: clean build

clean:
	-rm -rf build

build:
	xcodebuild build -configuration Release

PatronTests/server/node_modules:
	cd PatronTests/server && npm install

# Setting PATRON_CLI environment variable to signal our Xcode scheme that it
# should not start the server--it does so from within Xcode. I'm sure there's an
# internal flag for doing this more elegantly.
#
# This is a workaround to prevent xcodebuild from starting Test before our
# Pre-action, which starts the test server, is done, when running from the
# command-line. Mainly, this has been an inconsistent issue while running on
# Travis CI, starting with Xcode 8.
test: PatronTests/server/node_modules
	cd PatronTests && ./start_server.sh
	PATRON_CLI=1 xcodebuild test \
		-project $(project) \
		-scheme $(scheme) \
		-sdk $(sdk) \
		-destination $(dest)
	cd PatronTests && ./stop_server.sh

.PHONY: all clean test
