#!/usr/bin/env bash

# config.sh
# Usage example: ./config.sh -name <project_name> [-test] [-verbose]

# Set Script Variables

SCRIPT="$("$(dirname "$0")/resolvepath.sh" "$0")"
SCRIPTS_DIR="$(dirname "$SCRIPT")"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"

# Help

function print_help() {
    echo "./config.sh -name <project_name> [-output <output_folder>] [-help] [-test] [-verbose]"
    exit 1
}

# Parse Arguments

while [[ $# -gt 0 ]]; do
    case "$1" in
        -name)
        PROJECT_NAME="$2"
        shift # -name
        shift # <project_name>
        ;;

        -output)
        OUTPUT_DIR="$2"
        shift # -output
        shift # <output_folder>
        ;;

        -help)
        print_help
        ;;

        -test)
        TEST_MODE=1
        VERBOSE=1
        shift # -test
        ;;

        -verbose)
        VERBOSE=1
        shift # -verbose
        ;;

        *)
        echo "Unknown argument: $1"
        print_help
    esac
done

if [ -z ${PROJECT_NAME+x} ]; then
    echo "Missing `-name` argument"
    print_help
fi

if [ -z ${OUTPUT_DIR+x} ]; then
    OUTPUT_DIR="$(dirname "$ROOT_DIR")"
fi

# Initialize Environment Variables

source "$(dirname "$SCRIPT")/env.sh"

# Functions

function lower() {
    echo "$(echo "$1" | tr '[:upper:]' '[:lower:]')"
}

function upper() {
    echo "$(echo "$1" | tr '[:lower:]' '[:upper:]')"
}

function setup_git() {
    if [ "$INIT_GIT" = "1" ]; then
        # Init Git Repo
        local PWD="$(pwd)"
        cd "$1"

        git init --quiet --initial-branch=main
        cd "$PWD"

        # Local Git Options
        if [ -n ${GIT_USERNAME+x} ]; then
            git config credential.username "$GIT_USERNAME"
        fi
        if [ -n ${GIT_NAME+x} ]; then
            git config user.name "$GIT_NAME"
        fi
        if [ -n ${GIT_EMAIL+x} ]; then
            git config user.email "$GIT_EMAIL"
        fi
        if [ -n ${GIT_GPG+x} ]; then
            git config user.signingkey "$GIT_GPG"
            git config commit.gpgsign true
            git config tag.gpgsign true
        fi
    fi
}

# Copy Project Template

if [ ! -e "$OUTPUT_DIR/$PROJECT_NAME" ]; then
    if [ "$VERBOSE" = "1" ]; then
        echo "Copying \"$ROOT_DIR\" to \"$OUTPUT_DIR/$PROJECT_NAME\""
    fi

    mkdir "$OUTPUT_DIR/$PROJECT_NAME"
    cp -R "${ROOT_DIR%/}/" "$OUTPUT_DIR/$PROJECT_NAME"

    ROOT_DIR="$OUTPUT_DIR/$PROJECT_NAME"
    SCRIPTS_DIR="$ROOT_DIR/$(basename "$SCRIPTS_DIR")"
    SCRIPT="$SCRIPTS_DIR/$(basename "$SCRIPT")"

    rm -f "$SCRIPT"
    rm -f "$SCRIPTS_DIR/env.sh"
    rm -f "$SCRIPTS_DIR/unittests.sh"
    rm -f "$SCRIPTS_DIR/unittests.rb"
    rm -f "$ROOT_DIR/README.md"
    rm -rf "$ROOT_DIR/.git"

    rm -rf "$ROOT_DIR/.github/workflows"
    mv "$ROOT_DIR/workflows" "$ROOT_DIR/.github/workflows"

    find "$ROOT_DIR" -regex ".*\.gitkeep" -delete

    setup_git "$ROOT_DIR"
else
    echo "Destination project folder already exits: \"$OUTPUT_DIR/$PROJECT_NAME\""
    exit 1
fi

# Rename files with placeholders

function rename_placeholder_files() {
    local IFS=$'\n'
    local FILES=($(find "$ROOT_DIR" -regex ".*$1.*"))
    local COUNT=${#FILES[@]}

    while [ ${#FILES[@]} -gt 0 ]; do
        for FILE in "${FILES[@]}"; do
            local NEW_FILE="$(echo "$FILE" | sed "s/$1/$2/g")"

            if [ "$VERBOSE" = "1" ]; then
                echo "Renaming \"$FILE\" to \"$NEW_FILE\""
            fi

            if [ -z ${TEST_MODE+x} ]; then
                mv "$FILE" "$NEW_FILE"
                FILES=($(find "$ROOT_DIR" -regex ".*$1.*"))
                break
            fi
        done

        if [ "$TEST_MODE" == "1" ]; then
            break
        fi
    done
}

rename_placeholder_files "<#templateproject#>" "$(lower "$PROJECT_NAME")"
rename_placeholder_files "<#TemplateProject#>" "$PROJECT_NAME"
rename_placeholder_files "<#TEMPLATEPROJECT#>" "$(upper "$PROJECT_NAME")"
rename_placeholder_files "<#TemplateREADME#>" "README"

# Replace placeholders in files

function replace_placeholders_in_files() {
    local IFS=$'\n'
    local FILES=($(grep -lr "$1" "$ROOT_DIR"))

    if [ -n "$FILES" ]; then
        for FILE in "${FILES[@]}"; do
            if [ "$VERBOSE" = "1" ]; then
                echo "Replacing instances of \"$1\" with \"$2\" in \"$FILE\""
            fi

            if [ -z ${TEST_MODE+x} ]; then
                sed -e "s/$1/$2/g" -i "" "$FILE"
            fi
        done
    fi
}

replace_placeholders_in_files "<#templateproject#>" "$(lower "$PROJECT_NAME")"
replace_placeholders_in_files "<#TemplateProject#>" "$PROJECT_NAME"
replace_placeholders_in_files "<#TEMPLATEPROJECT#>" "$(upper "$PROJECT_NAME")"

replace_placeholders_in_files "<#templateusername#>" "$(lower "$USERNAME")"
replace_placeholders_in_files "<#TemplateUsername#>" "$USERNAME"
replace_placeholders_in_files "<#TEMPLATEUSERNAME#>" "$(upper "$USERNAME")"

replace_placeholders_in_files "<#templateemail#>" "$(lower "$EMAIL")"
replace_placeholders_in_files "<#TemplateEmail#>" "$EMAIL"
replace_placeholders_in_files "<#TEMPLATEEMAIL#>" "$(upper "$EMAIL")"

replace_placeholders_in_files "<#templatename#>" "$(lower "$NAME")"
replace_placeholders_in_files "<#TemplateName#>" "$NAME"
replace_placeholders_in_files "<#TEMPLATENAME#>" "$(upper "$NAME")"

replace_placeholders_in_files "<#TemplateYear#>" "$(date +%Y)"

#

if [ "$TEST_MODE" = "1" ]; then
    rm -rf "$ROOT_DIR"
fi
