#!/bin/bash -e

# shellcheck disable=SC1090
source "$(dirname "$0")"/../pattern-ci/scripts/resources.sh

build_images() {
    set -x
    docker build -q -t leaderboards-"$TRAVIS_BUILD_ID" containers/leaderboards
    docker build -q -t users-"$TRAVIS_BUILD_ID" containers/users
    docker build -q -t shop-"$TRAVIS_BUILD_ID" containers/shop
    docker images
    set +x

    echo "Removing imagePullPolicy in yaml files... Pods would use the local images built"
    sed -i "/imagePullPolicy/d" manifests/*
}

kubectl_deploy() {
    echo "Enabling minikube ingress"
    minikube addons enable ingress

    echo "Deploying postgres"
    kubectl create cm postgres-cm --from-env-file=postgres-config.env
    kubectl apply -f manifests/postgres.yaml

    echo "Waiting for postgres..."
    i=0
    while [[ $(kubectl get pods | grep -c Running) -ne 1 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on postgres to be ready"
            kubectl get pods -a
            test_failed "$0"
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done

    echo "Deploying user microservice"
    kubectl apply -f manifests/users.yaml
    kubectl set image deployment users users="leaderboard-$TRAVIS_BUILD_ID"

    echo "Deploying shop microservice"
    kubectl apply -f manifests/shop.yaml
    kubectl set image deployment shop shop="leaderboard-$TRAVIS_BUILD_ID"

    echo "Deploying leaderboard microservice"
    kubectl apply -f manifests/leaderboard.yaml
    kubectl set image deployment leaderboard leaderboard="leaderboard-$TRAVIS_BUILD_ID"

    echo "Waiting for pods to be running"
    i=0
    while [[ $(kubectl get pods | grep -c Running) -ne 4 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on pods to be ready"
            kubectl get pods -a
            test_failed "$0"
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done
    echo "All pods are running"

    echo "Deploying Ingress"
    # modify ingress.yaml to remove placeholders
    sed -i 's#\ \ http#\-\ http#; /YOUR/d; /tls/d;/hosts/d' manifests/ingress.yaml
    kubectl apply -f manifests/ingress.yaml
}

verify_deploy(){
    echo "Verifying deployment was successful"
    if ! sleep 1 && curl -sS "https://$(minikube ip)/users" -k; then
        test_failed "$0"
    fi
}

main(){
    if ! build_images; then
        test_failed "$0"
    elif ! kubectl_deploy; then
        test_failed "$0"
    elif ! verify_deploy; then
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main
