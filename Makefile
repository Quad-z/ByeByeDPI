.PHONY: all project build

all: project

project:
	xcodegen generate

build: project
	xcodebuild -project ByeByeDPI.xcodeproj -scheme ByeByeDPI -destination 'generic/platform=iOS' build

archive: project
	xcodebuild -project ByeByeDPI.xcodeproj -scheme ByeByeDPI -destination 'generic/platform=iOS' -archivePath build/ByeByeDPI archive

clean:
	rm -rf ByeByeDPI.xcodeproj build
