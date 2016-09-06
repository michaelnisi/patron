project=Patron.xcodeproj
scheme=Patron
sdk=iphonesimulator

all: clean build

clean:
	-rm -rf build

build:
	xcodebuild -configuration Debug build

test:
	xcodebuild test \
		-project $(project) \
		-scheme $(scheme) \
		-sdk $(sdk)

.PHONY: all clean test
