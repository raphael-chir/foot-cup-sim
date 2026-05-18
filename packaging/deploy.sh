#!/bin/bash
set -euo pipefail

echo "Deploying World Cup Simulator packaging..."
echo "Namespace: $(oc project -q)"
echo

echo "1/5 Applying secrets, configmaps and DB dump..."
oc apply -f packaging/k8s/postgrest-secret.yaml
oc apply -f packaging/k8s/postgrest-config.yaml
oc apply -f packaging/k8s/db-dump-configmap.yaml

echo
echo "2/5 Restoring database..."
oc delete job worldcup-db-restore --ignore-not-found=true || true
oc apply -f packaging/k8s/db-restore-job.yaml

echo "Waiting for restore pod..."
sleep 2

RESTORE_POD=$(oc get pods \
  -l job-name=worldcup-db-restore \
  -o jsonpath='{.items[0].metadata.name}')

oc logs -f "$RESTORE_POD"

oc wait --for=condition=complete job/worldcup-db-restore --timeout=300s

echo
echo "3/5 Deploying PostgREST..."
oc apply -f packaging/k8s/postgrest-deployment.yaml
oc delete route postgrest --ignore-not-found=true || true
oc apply -f packaging/k8s/postgrest-service-route.yaml
oc rollout status deployment/postgrest

echo
echo "4/5 Deploying Swagger UI..."
oc delete route swagger-ui --ignore-not-found=true || true
oc apply -f packaging/k8s/swagger-ui.yaml
oc rollout status deployment/swagger-ui

echo
echo "5/5 Deploying Frontend..."
oc delete route worldcup-ui --ignore-not-found=true || true
oc apply -f packaging/k8s/frontend.yaml
oc rollout status deployment/worldcup-ui

echo
echo "Routes:"
oc get route

echo
echo "Deployment completed."