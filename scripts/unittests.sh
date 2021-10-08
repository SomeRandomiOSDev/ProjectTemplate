#!/usr/bin/env bash

# unittests.sh
# Usage example: ./unittests.sh [--no-clean]

# Set Script Variables

SCRIPT="$("$(dirname "$0")/resolvepath.sh" "$0")"
SCRIPTS_DIR="$(dirname "$SCRIPT")"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"
CURRENT_DIR="$(pwd -P)"

TEMP_DIR="$(mktemp -d)"
PROJECT_NAME="$(basename "$(mktemp -u $TEMP_DIR/ProjectTemplateUnitTests_XXXXXX)")"
OUTPUT_DIR="$TEMP_DIR/$PROJECT_NAME"

EXIT_CODE=0
EXIT_MESSAGE=""

if [ "$1" == "--no-clean" ]; then
    NO_CLEAN=1
fi

# Function Definitions

function cleanup() {
    if [ -z ${NO_CLEAN+x} ]; then
        cd "$CURRENT_DIR"
        rm -rf "$TEMP_DIR"
    else
        echo "Test Project: $OUTPUT_DIR"
    fi

    #

    local CARTHAGE_CACHE="$HOME/Library/Caches/org.carthage.CarthageKit"
    if [ -e "$CARTHAGE_CACHE" ]; then
        if [ -e "$CARTHAGE_CACHE/dependencies/$PROJECT_NAME" ]; then
            rm -rf "$CARTHAGE_CACHE/dependencies/$PROJECT_NAME"
        fi

        for DIR in $(find "$CARTHAGE_CACHE/DerivedData" -mindepth 1 -maxdepth 1 -type d); do
            if [ -e "$DIR/$PROJECT_NAME" ]; then
                rm -rf "$DIR/$PROJECT_NAME"
            fi
        done
    fi

    #

    if [ ${#EXIT_MESSAGE} -gt 0 ]; then
        echo -e "$EXIT_MESSAGE"
    fi

    exit $EXIT_CODE
}

function checkresult() {
    if [ "$1" != "0" ]; then
        EXIT_MESSAGE="\033[31m$2\033[0m"
        EXIT_CODE=$1

        cleanup
    fi
}

function printstep() {
    echo -e "\033[32m$1\033[0m"
}

# Run Config

printstep "Setting Up Test Project..."

"$SCRIPTS_DIR/config.sh" -name "$PROJECT_NAME" -output "$TEMP_DIR"
checkresult $? "'config.sh' script failed"

# Check For Unit Test Dependencies

cd "$OUTPUT_DIR"
printstep "Checking Dependencies..."

### Carthage

if which carthage >/dev/null; then
    CARTHAGE_VERSION="$(carthage version)"
    echo "Carthage: $CARTHAGE_VERSION"

    "$SCRIPTS_DIR/versions.sh" "$CARTHAGE_VERSION" "0.37.0"

    if [ $? -lt 0 ]; then
        echo -e "\033[33mCarthage version of at least 0.37.0 is recommended for running these unit tests\033[0m"
    fi
else
    checkresult -1 "Carthage is not installed and is required for running unit tests: \033[4;34mhttps://github.com/Carthage/Carthage#installing-carthage"
fi

### CocoaPods

if which pod >/dev/null; then
    PODS_VERSION="$(pod --version)"
    "$SCRIPTS_DIR/versions.sh" "$PODS_VERSION" "1.7.3"

    if [ $? -ge 0 ]; then
        echo "CocoaPods: $(pod --version)"
    else
        checkresult -1 "These unit tests require version 1.7.3 or later of CocoaPods: \033[4;34mhttps://guides.cocoapods.org/using/getting-started.html#updating-cocoapods"
    fi
else
    checkresult -1 "CocoaPods is not installed and is required for running unit tests: \033[4;34mhttps://guides.cocoapods.org/using/getting-started.html#installation"
fi

### Xcodeproj

# This should be installed with CocoaPods, but we'll include it just in case CocoaPods removes it from its dependencies in a future release
if which xcodeproj >/dev/null; then
    echo "Xcodeproj: $(xcodeproj --version)"
else
    checkresult -1 "'xcodeproj' Ruby Gem is not installed and is required for running unit tests: \033[4;34mhttps://rubygems.org/gems/xcodeproj"
fi

### Add Sources To Project

printstep "Configuring Test Project..."

echo -e "class SomeClass {\n    var value: Int = 3\n}" > "$OUTPUT_DIR/Sources/$PROJECT_NAME/SomeClass.swift"
echo -e "@testable import $PROJECT_NAME\nimport XCTest\n\nclass SomeClassTests: XCTestCase {\n\n    func testSomeClass() {\n        let object = SomeClass()\n        XCTAssertEqual(object.value, 3)\n    }\n}" > "$OUTPUT_DIR/Tests/${PROJECT_NAME}Tests/SomeClassTests.swift"

echo "SCRIPTS_DIR: $SCRIPTS_DIR"
ruby "$SCRIPTS_DIR/unittests.rb" "$OUTPUT_DIR/$PROJECT_NAME.xcodeproj" "$OUTPUT_DIR/Sources/$PROJECT_NAME/SomeClass.swift" "$OUTPUT_DIR/Tests/${PROJECT_NAME}Tests/SomeClassTests.swift"
checkresult $? "Unable to configure the test project for testing"

# Run Unit Tests

printstep "Running Unit Tests..."

### Carthage Workflow

printstep "Testing 'carthage.yml' Workflow..."

git add .
git commit -m "Commit"
git tag | xargs git tag -d
git tag 1.0
checkresult $? "Unable to tag local git repo for running Carthage unit tests"

echo "git \"file://$OUTPUT_DIR\"" > ./Cartfile

./scripts/carthage.sh update
checkresult $? "Carthage Unit Test failed: \"Build\""

printstep "'carthage.yml' Workflow Tests Passed\n"

### CocoaPods Workflow

printstep "Testing 'cocoapods.yml' Workflow..."

pod lib lint
checkresult $? "CocoaPods Unit Test failed: \"Lint (Dynamic Library)\""

pod lib lint --use-libraries
checkresult $? "CocoaPods Unit Test failed: \"Lint (Static Library)\""

printstep "'cocoapods.yml' Workflow Tests Passed\n"

### Swift Package Workflow

printstep "Testing 'swift-package.yml' Workflow..."

swift build -v
checkresult $? "Swift Package Unit Test failed: \"Build\""

swift test -v
checkresult $? "Swift Package Unit Test failed: \"Test\""

printstep "'swift-package.yml' Workflow Tests Passed\n"

### XCFramework Workflow

printstep "Testing 'xcframework.yml' Workflow..."

./scripts/xcframework.sh -output "./$PROJECT_NAME.xcframework"
checkresult $? "XCFramework Unit Test failed: \"Build\""

printstep "'xcframework.yml' Workflow Tests Passed\n"

### Upload Assets Workflow

printstep "Testing 'upload-assets.yml' Workflow..."

zip -rX "$PROJECT_NAME.xcframework.zip" "$PROJECT_NAME.xcframework"
checkresult $? "XCFramework Unit Test failed: \"Zip\""

tar -zcvf "$PROJECT_NAME.xcframework.tar.gz" "$PROJECT_NAME.xcframework"
checkresult $? "XCFramework Unit Test failed: \"Tar\""

printstep "'upload-assets.yml' Workflow Tests Passed\n"

### Xcodebuild Workflow

printstep "Testing 'xcodebuild.yml' Workflow..."

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" -destination "generic/platform=iOS" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build iOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" -destination "generic/platform=iOS Simulator" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build iOS Simulator\""

IOS_SIM="$(xcrun simctl list devices available | grep "iPhone [0-9]" | sort -rV | head -n 1 | sed -E 's/(.+)[ ]*\([^)]*\)[ ]*\([^)]*\)/\1/' | awk '{$1=$1};1')"

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" -testPlan "${PROJECT_NAME}Tests" -destination "platform=iOS Simulator,name=$IOS_SIM" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test iOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "${PROJECT_NAME}Tests" -testPlan "${PROJECT_NAME}Tests" -destination "platform=iOS Simulator,name=$IOS_SIM" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test iOS\""

###

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" -destination "generic/platform=macOS,variant=Mac Catalyst" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build MacCatalyst\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" -testPlan "${PROJECT_NAME}Tests" -destination "platform=macOS,variant=Mac Catalyst" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test MacCatalyst\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "${PROJECT_NAME}Tests" -testPlan "${PROJECT_NAME}Tests" -destination "platform=macOS,variant=Mac Catalyst" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test MacCatalyst\""

###

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME macOS" -destination "generic/platform=macOS" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build macOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME macOS" -testPlan "$PROJECT_NAME macOS Tests" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test macOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME macOS Tests" -testPlan "$PROJECT_NAME macOS Tests" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test macOS\""

###

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME tvOS" -destination "generic/platform=tvOS" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build tvOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME tvOS" -destination "generic/platform=tvOS Simulator" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build tvOS Simulator\""

TVOS_SIM="$(xcrun simctl list devices available | grep "Apple TV" | sort -V | head -n 1 | sed -E 's/(.+)[ ]*\([^)]*\)[ ]*\([^)]*\)/\1/' | awk '{$1=$1};1')"

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME tvOS" -testPlan "$PROJECT_NAME tvOS Tests" -destination "platform=tvOS Simulator,name=$TVOS_SIM" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test tvOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME tvOS Tests" -testPlan "$PROJECT_NAME tvOS Tests" -destination "platform=tvOS Simulator,name=$TVOS_SIM" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test tvOS\""

###

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME watchOS" -destination "generic/platform=watchOS" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build watchOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME watchOS" -destination "generic/platform=watchOS Simulator" -configuration Debug
checkresult $? "Xcodebuild Unit Test failed: \"Build watchOS Simulator\""

WATCHOS_SIM="$(xcrun simctl list devices available | grep "Apple Watch" | sort -rV | head -n 1 | sed -E 's/(.+)[ ]*\([^)]*\)[ ]*\([^)]*\)/\1/' | awk '{$1=$1};1')"

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME watchOS" -testPlan "$PROJECT_NAME watchOS Tests" -destination "platform=watchOS Simulator,name=$WATCHOS_SIM" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test watchOS\""

xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME watchOS Tests" -testPlan "$PROJECT_NAME watchOS Tests" -destination "platform=watchOS Simulator,name=$WATCHOS_SIM" -configuration Debug ONLY_ACTIVE_ARCH=YES test
checkresult $? "Xcodebuild Unit Test failed: \"Test watchOS\""

printstep "'xcodebuild.yml' Workflow Tests Passed\n"

### Success

cleanup
