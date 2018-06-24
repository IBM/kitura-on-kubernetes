#!/bin/bash

# This script is intended to be run by Travis CI. If running elsewhere, invoke
# it with: TRAVIS_PULL_REQUEST=false [path to script]

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

check_swift() {
    swift -version
}

build_microservices() {
    echo "Building leaderboards microservice"
    swift build --package-path containers/leaderboards

    echo "Building shop microservice"
    swift build --package-path containers/shop

    echo "Building users microservice"
    swift build --package-path containers/users
}

main(){
    if ! check_swift; then
        echo "Swift not found."
        test_failed "$0"
    elif ! build_microservices; then
        echo "Building with swift failed."
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main
