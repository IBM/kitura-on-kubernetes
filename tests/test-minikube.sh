#!/bin/bash -e

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

setup_minikube() {
  export CHANGE_MINIKUBE_NONE_USER=true
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.25.2/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
  sudo -E minikube start --vm-driver=none --kubernetes-version=v1.9.0
  minikube update-context
  JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
}

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
    if ! setup_minikube; then
        test_failed "$0"
    elif ! build_images; then
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
