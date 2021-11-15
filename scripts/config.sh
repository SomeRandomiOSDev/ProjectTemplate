#!/usr/bin/env bash
#
# config.sh
# Usage example: ./config.sh --verbose project_name

# Set Script Variables

SCRIPT="$("$(dirname "$0")/resolvepath.sh" "$0")"
SCRIPTS_DIR="$(dirname "$SCRIPT")"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"

EXIT_MESSAGE=""
EXIT_CODE=0

# Help

function printhelp() {
    local HELP="Configure a new framework project using this workspace as a template.\n\n"
    HELP+="config.sh [--help | -h] [--verbose | -v] [--dryrun | -t] [--open-project]\n"
    HELP+="          [(--output | -o) <output_folder>] <project_name>\n"
    HELP+="\n"
    HELP+="FLAGS:\n"
    HELP+="\n"
    HELP+="--help, -h)     Print this help message and exit.\n"
    HELP+="\n"
    HELP+="--verbose, -v)  Enable verbose logging.\n"
    HELP+="\n"
    HELP+="--dryrun, -t)   Run as if a new project was being configured with the given\n"
    HELP+="                inputs without actually creating the project. This flag\n"
    HELP+="                implicitly sets the --verbose flag.\n"
    HELP+="\n"
    HELP+="--open-project) Open the newly created project after configuring it.\n"
    HELP+="\n"
    HELP+="--output, -o)   The folder in which to write the newly configured project to. If\n"
    HELP+="                not specified this defaults to folder containing this template\n"
    HELP+="                project (i.e. \"$(dirname "$0")/../../\").\n"
    HELP+="\n"
    HELP+="ARGUMENTS:\n"
    HELP+="\n"
    HELP+="project_name:   The name of the project to create.\n"

    IFS='%'
    echo -e "$HELP" 1>&2
    unset IFS

    exit $EXIT_CODE
}

# Parse Arguments

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help | -h)
        printhelp
        ;;

        --dryrun | -t)
        DRYRUN=1
        VERBOSE=1
        shift # --dryrun | -t
        ;;

        --verbose | -v)
        VERBOSE=1
        shift # --verbose | -v
        ;;

        --open-project)
        OPEN_PROJECT=1
        shift # --open-project
        ;;

        --output | -o)
        OUTPUT_DIR="$2"
        shift # --output | -o
        shift # <output_folder>
        ;;

        *)
        if [[ $1 == -* ]]; then # argument starts with "-"
            "$SCRIPTS_DIR/printformat.sh" "foreground:red" "Unknown argument: $1\n" 1>&2
            EXIT_CODE=1
            printhelp
        elif [ -z ${PROJECT_NAME+x} ]; then
            PROJECT_NAME="$1"
            shift # <project_name>
        else
            "$SCRIPTS_DIR/printformat.sh" "foreground:red" "Unexpected positional argument: $1\n" 1>&2
            EXIT_CODE=1
            printhelp
        fi
        ;;
    esac
done

if [ -z ${PROJECT_NAME+x} ]; then
    "$SCRIPTS_DIR/printformat.sh" "foreground:red" "Missing <project_name> positional argument\n" 1>&2
    EXIT_CODE=1
    printhelp
fi

if [ -z ${OUTPUT_DIR+x} ]; then
    OUTPUT_DIR="$(dirname "$ROOT_DIR")"
fi

# Initialize Environment Variables

PROJECT_DIR="$OUTPUT_DIR/$PROJECT_NAME"

source "$SCRIPTS_DIR/env.sh"

# Functions

function cleanup() {
    if [[ "$DRYRUN" == "1" ]] || [[ "$EXIT_CODE" != "0" ]]; then
        rm -rf "$PROJECT_DIR"
    elif [[ "$OPEN_PROJECT" == "1" ]] && [[ "$EXIT_CODE" == "0" ]]; then
        open -a Xcode "$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
    fi

    if [ "${#EXIT_MESSAGE}" != 0 ]; then
        if [ "$EXIT_MESSAGE" == "**printhelp**" ]; then
            printhelp
        else
            echo -e "$EXIT_MESSAGE" 1>&2
        fi
    fi

    exit $EXIT_CODE
}

function checkresult() {
    if [ "$1" != "0" ]; then
        if [ "${#2}" != "0" ]; then
            EXIT_MESSAGE="$("$SCRIPTS_DIR/printformat.sh" "foreground:red" "$2")"
        else
            EXIT_MESSAGE="**printhelp**"
        fi

        EXIT_CODE=$1
        cleanup
    fi
}

function lower() {
    echo "$(echo "$1" | tr '[:upper:]' '[:lower:]')"
}

function upper() {
    echo "$(echo "$1" | tr '[:lower:]' '[:upper:]')"
}

function setup_git() {
    if [ "$INIT_GIT" = "1" ]; then
        # Init Git Repo
        local ERROR_MESSAGE="An error occurred while configuring the git repo for the project: $PROJECT_DIR\n"
        local PWD="$(pwd)"
        cd "$1"

        git init --quiet --initial-branch=main
        checkresult $? "$ERROR_MESSAGE"

        # Local Git Options
        if [ -n ${GIT_USERNAME+x} ]; then
            git config credential.username "$GIT_USERNAME"
            checkresult $? "$ERROR_MESSAGE"
        fi
        if [ -n ${GIT_NAME+x} ]; then
            git config user.name "$GIT_NAME"
            checkresult $? "$ERROR_MESSAGE"
        fi
        if [ -n ${GIT_EMAIL+x} ]; then
            git config user.email "$GIT_EMAIL"
            checkresult $? "$ERROR_MESSAGE"
        fi
        if [ -n ${GIT_GPG+x} ]; then
            git config user.signingkey "$GIT_GPG"
            checkresult $? "$ERROR_MESSAGE"

            if [ "$GIT_SIGN_COMMITS" == "1" ]; then
                git config commit.gpgsign true
                checkresult $? "$ERROR_MESSAGE"
            fi

            if [ "$GIT_SIGN_TAGS" == "1" ]; then
                git config tag.gpgsign true
                checkresult $? "$ERROR_MESSAGE"
            fi
        fi

        cd "$PWD"
    fi
}

# Copy Project Template

if [ ! -e "$PROJECT_DIR" ]; then
    ERROR_MESSAGE="An error occurred while configuring the project directory: $PROJECT_DIR\n"

    if [ "$VERBOSE" = "1" ]; then
        echo "Copying \"$ROOT_DIR\" to \"$PROJECT_DIR\""
    fi

    mkdir "$PROJECT_DIR"
    checkresult $? "$ERROR_MESSAGE"

    cp -R "${ROOT_DIR%/}/" "$PROJECT_DIR"
    checkresult $? "$ERROR_MESSAGE"

    #

    for SCRIPT in "config.sh" "env.sh" "unittests.sh" "unittests.rb"; do
        rm -f "$PROJECT_DIR/$(basename "$SCRIPTS_DIR")/$SCRIPT"
        checkresult $? "$ERROR_MESSAGE"
    done

    for FILE in "README.md" ".remarkrc" ".git" ".github"; do
        rm -rf "$PROJECT_DIR/$FILE"
        checkresult $? "$ERROR_MESSAGE"
    done

    for REPLACEMENT in "README.md" ".remarkrc" ".github"; do
        mv "$PROJECT_DIR/Replacements/$REPLACEMENT" "$PROJECT_DIR/$REPLACEMENT"
        checkresult $? "$ERROR_MESSAGE"
    done

    rm -rf "$PROJECT_DIR/Replacements"

    #

    find "$PROJECT_DIR" -regex ".*\.gitkeep" -delete
    checkresult $? "$ERROR_MESSAGE"

    setup_git "$PROJECT_DIR"
else
    checkresult 1 "Destination project folder already exits: \"$PROJECT_DIR\""
fi

# Rename files with placeholders

function rename_placeholder_files() {
    local IFS=$'\n'
    local FILES=($(find "$PROJECT_DIR" -regex ".*$1.*"))

    while [ ${#FILES[@]} -gt 0 ]; do
        for FILE in "${FILES[@]}"; do
            local NEW_FILE="${FILE//$1/$2}"

            if [ "$VERBOSE" = "1" ]; then
                echo "Renaming \"$FILE\" to \"$NEW_FILE\""
            fi

            if [ -z ${DRYRUN+x} ]; then
                mv "$FILE" "$NEW_FILE"
                checkresult $? "An error occurred while renaming a file: \"$FILE\" -> \"$NEW_FILE\""

                FILES=($(find "$PROJECT_DIR" -regex ".*$1.*"))
                break
            fi
        done

        if [ "$DRYRUN" == "1" ]; then
            break
        fi
    done
}

rename_placeholder_files "<#templateproject#>" "$(lower "$PROJECT_NAME")"
rename_placeholder_files "<#TemplateProject#>" "$PROJECT_NAME"
rename_placeholder_files "<#TEMPLATEPROJECT#>" "$(upper "$PROJECT_NAME")"

# Replace placeholders in files

function replace_placeholders_in_files() {
    local IFS=$'\n'
    local FILES=($(grep -lr "$1" "$PROJECT_DIR"))

    if [ -n "$FILES" ]; then
        for FILE in "${FILES[@]}"; do
            if [ "$VERBOSE" = "1" ]; then
                echo "Replacing instances of \"$1\" with \"$2\" in \"$FILE\""
            fi

            if [ -z ${DRYRUN+x} ]; then
                sed -e "s/$1/$2/g" -i "" "$FILE"
                checkresult $? "An error occurred while replacing placeholders (\"$1\" -> \"$2\") in file: \"$FILE\""
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

cleanup
