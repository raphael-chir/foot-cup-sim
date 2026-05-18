#!/bin/bash
set -euo pipefail

echo "Cleaning World Cup Simulator resources..."
echo "Namespace: $(oc project -q)"
echo

echo "Deleting frontend..."
oc delete -f packaging/k8s/frontend.yaml --ignore-not-found=true

echo "Deleting Swagger UI..."
oc delete -f packaging/k8s/swagger-ui.yaml --ignore-not-found=true

echo "Deleting PostgREST..."
oc delete -f packaging/k8s/postgrest-service-route.yaml --ignore-not-found=true
oc delete -f packaging/k8s/postgrest-deployment.yaml --ignore-not-found=true

echo "Deleting DB restore job..."
oc delete job worldcup-db-restore --ignore-not-found=true

echo "Deleting configmaps and secrets..."
oc delete configmap worldcup-db-dump --ignore-not-found=true
oc delete configmap postgrest-config --ignore-not-found=true
oc delete secret postgrest-secret --ignore-not-found=true

echo
echo "Remaining resources:"
oc get all || true

echo
echo "Cleanup completed."
