#!/usr/bin/env bash
# slugify — turn a title into a URL slug.
#
# The whole "product" of the demo sample project. Deliberately tiny: the point of
# the demo is the build system around it, not this.
#
#   ./slugify.sh "Hello, World!"   ->  hello-world
set -uo pipefail

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]\{1,\}/-/g'
}

[ "$#" -ge 1 ] || { echo "usage: slugify.sh TITLE" >&2; exit 2; }
slugify "$1"
echo
