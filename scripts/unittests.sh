#!/usr/bin/env bash
#
# unittests.sh
# Usage example: ./unittests.sh [--no-clean | --no-clean-on-fail]

# Set Script Variables

SCRIPT="$("$(dirname "$0")/resolvepath.sh" "$0")"
SCRIPTS_DIR="$(dirname "$SCRIPT")"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"

TEMP_DIR="$(mktemp -d)"
PROJECT_NAME="$(basename "$(mktemp -u $TEMP_DIR/ProjectTemplateUnitTests_XXXXXXXX)")"
OUTPUT_DIR="$TEMP_DIR/$PROJECT_NAME"

NO_CLEAN=0
NO_CLEAN_ON_FAIL=0

EXIT_CODE=0
EXIT_MESSAGE=""

# Help

function printhelp() {
    local HELP="Run 'ProjectTemplate' unit tests.\n\n"
    HELP+="unittests.sh [--help | -h] [--no-clean | --no-clean-on-fail]\n"
    HELP+="\n"
    HELP+="--help, -h)         Print this help message and exit.\n"
    HELP+="\n"
    HELP+="--no-clean)         Never clean up the temporary project created to run these\n"
    HELP+="                    tests upon completion.\n"
    HELP+="\n"
    HELP+="--no-clean-on-fail) Same as --no-clean with the exception that if the tests\n"
    HELP+="                    succeed clean up will continue as normal. This is mutually\n"
    HELP+="                    exclusive with --no-clean with --no-clean taking precedence.\n"

    IFS='%'
    echo -e $HELP 1>&2
    unset IFS

    exit $EXIT_CODE
}

# Parse Arguments

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-clean)
        NO_CLEAN=1
        shift # --no-clean
        ;;

        --no-clean-on-fail)
        NO_CLEAN_ON_FAIL=1
        shift # --no-clean-on-fail
        ;;

        *)
        echo -e "Unknown argument: $1\n" 1>&2
        printhelp
    esac
done

# Function Definitions

function cleanup() {
    if [[ "$NO_CLEAN" == "1" ]] || [[ "$NO_CLEAN_ON_FAIL" == "1" && "$EXIT_CODE" != "0" ]]; then
        echo "Test Project: $OUTPUT_DIR"
    else
        rm -rf "$TEMP_DIR"
    fi

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

"$SCRIPTS_DIR/config.sh" --output "$TEMP_DIR" "$PROJECT_NAME"
checkresult $? "'config.sh' script failed"

# Check For Dependencies

printstep "Checking for Configuration Dependencies..."

if which xcodeproj >/dev/null; then
    echo "Xcodeproj: $(xcodeproj --version)"
else
    checkresult -1 "'xcodeproj' Ruby Gem is not installed and is required for running unit tests: \033[4;34mhttps://rubygems.org/gems/xcodeproj"
fi

### Add Sources To Project

printstep "Configuring Test Project..."

echo -e "class SomeClass {\n    var value: Int = 3\n}" > "$OUTPUT_DIR/Sources/$PROJECT_NAME/SomeClass.swift"
echo -e "@testable import $PROJECT_NAME\nimport XCTest\n\nclass SomeClassTests: XCTestCase {\n\n    func testSomeClass() {\n        let object = SomeClass()\n        XCTAssertEqual(object.value, 3)\n    }\n}" > "$OUTPUT_DIR/Tests/${PROJECT_NAME}Tests/SomeClassTests.swift"

ruby "$SCRIPTS_DIR/unittests.rb" "$OUTPUT_DIR/$PROJECT_NAME.xcodeproj" "$OUTPUT_DIR/Sources/$PROJECT_NAME/SomeClass.swift" "$OUTPUT_DIR/Tests/${PROJECT_NAME}Tests/SomeClassTests.swift"
checkresult $? "Unable to configure the test project for testing"

# Run Tests

ARGS=(--is-running-in-temp-env --project-name "$PROJECT_NAME")

if [ "$NO_CLEAN" == "1" ]; then
    ARGS+=(--no-clean)
elif [ "$NO_CLEAN_ON_FAIL" == "1" ]; then
    ARGS+=(--no-clean-on-fail)
fi

"$OUTPUT_DIR/$(basename "$SCRIPTS_DIR")/workflowtests.sh" "${ARGS[@]}"
checkresult $? "Unit tests failed"

# Success

cleanup
