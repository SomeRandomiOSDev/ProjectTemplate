#!/usr/bin/env bash
#
# resolvepath.sh
# Copyright (c) <#TemplateYear#> <#TemplateName#>. All rights reserved.
# Originated from https://github.com/SomeRandomiOSDev/ProjectTemplate
#
# Usage example: ./resolvepath.sh "./some/random/path/../../"

cd "$(dirname "$1")" &>/dev/null && echo "$PWD/${1##*/}"
