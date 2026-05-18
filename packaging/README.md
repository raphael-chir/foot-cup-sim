# World Cup Simulator Packaging

## Prerequisites

- OpenShift / Kubernetes
- Existing PostgreSQL 17 database
- `oc` CLI
- Database URI available

---

## 1. Configure database secret

Edit:

packaging/k8s/postgrest-secret.yaml

Set:

PGRST_DB_URI

Example:

postgresql://app:password@cluster-rw:5432/postgres

---

## 2. Restore database

Apply dump ConfigMap:

oc apply -f packaging/k8s/db-dump-configmap.yaml

Run restore Job:

oc apply -f packaging/k8s/db-restore-job.yaml

Watch logs:

oc logs -f job/worldcup-db-restore

---

## 3. Deploy PostgREST

Apply:

oc apply -f packaging/k8s/postgrest-secret.yaml
oc apply -f packaging/k8s/postgrest-config.yaml
oc apply -f packaging/k8s/postgrest-deployment.yaml
oc apply -f packaging/k8s/postgrest-service-route.yaml

Verify:

oc get route postgrest

---

## 4. Deploy Swagger UI

Apply:

oc apply -f packaging/k8s/swagger-ui.yaml

Verify:

oc get route swagger-ui

---

## 5. Deploy Frontend

Apply:

oc apply -f packaging/k8s/frontend.yaml

Verify:

oc get route worldcup-ui

---

## 6. Test

Frontend:

https://worldcup-ui-<namespace>.<domain>

Swagger UI:

https://swagger-ui-<namespace>.<domain>

PostgREST:

https://postgrest-<namespace>.<domain>

