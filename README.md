[![Generic badge](https://img.shields.io/badge/Version-1.0-<COLOR>.svg)](https://shields.io/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
![Maintainer](https://img.shields.io/badge/maintainer-raphael.chir@gmail.com-blue)

# ⚽ foot-cup-sim

**World Cup 2026 Simulator** built with:

- **PostgreSQL 17** (business logic engine)
- **PostgREST** (automatic REST API layer)
- **React + Vite** frontend
- **Swagger UI**
- **OpenShift / Kubernetes** deployment

The project simulates a complete football world cup tournament in real time:

- Group stage
- Knockout phases (16èmes, 8èmes, quarter-finals, semi-finals, final)
- Live match simulation
- Top scorers
- Dynamic bracket
- Champion screen

The goal of this project is to demonstrate how **PostgreSQL can host complex business logic** while exposing APIs through **PostgREST**, with a lightweight frontend deployed on **OpenShift**.

---

# Architecture

```text
React/Vite Frontend
          ↓
      PostgREST
          ↓
 PostgreSQL 17
 (business logic)
```
---

# Prerequisites

This project assumes:

* an **OpenShift cluster**
* a **CloudNativePG (CNPG) PostgreSQL cluster already running**
* `oc` CLI installed
* access to a PostgreSQL database

> PostgreSQL/CNPG deployment is considered a prerequisite and is not included in this repository.

---

# Quick Start (OpenShift)

## 1. Clone repository

```bash
git clone https://github.com/raphael-chir/foot-cup-sim.git
cd foot-cup-sim
```

---

## 2. Select your OpenShift project

```bash
oc project <your-project>
```

Example:

```bash
oc project edb-emea-user-b
```

---

## 3. Configure PostgreSQL connection

Find your PostgreSQL connection details.

```
oc project
oc get svc | grep rw
oc get secret
oc get route
oc get pods
```

Find Postgres URI :

```
URI=$(oc get secret cluster-user-a-app -o jsonpath='{.data.uri}' | base64 -d)
echo "$URI"
```

Connexion test :

```
oc exec -it psql-client -- psql "$URI"
```
```
SELECT current_database(), current_user, now();
```

Update:

```text
packaging/k8s/postgrest-secret.yaml
```

with your database URI.

Example:

```yaml
stringData:
  PGRST_DB_URI: <Postgres URI>
```

---

## 4. Configure Routes

Update:

```text
packaging/k8s/postgrest-config.yaml
packaging/k8s/frontend.yaml
packaging/k8s/swagger-ui.yaml
```

Replace route hostnames with your OpenShift domain.

Example:

```text
postgrest-<myproject>.apps-crc.testing
worldcup-ui-<myproject>.apps-crc.testing
swagger-ui-<myproject>.apps-crc.testing
```
---

## 5. Deploy

Run:

```bash
./packaging/deploy.sh
```

This will:

1. Create secrets/configmaps
2. Restore PostgreSQL database
3. Deploy PostgREST
4. Deploy Swagger UI
5. Deploy frontend

---

## 6. Verify deployment

```bash
oc get pods
oc get route
```

Expected routes:

```text
worldcup-ui
swagger-ui
postgrest
```

---

# Accessing the Application

## Frontend

```text
http://worldcup-ui-<project>.apps-<cluster-domain>
```

## Swagger UI

```text
http://swagger-ui-<project>.apps-<cluster-domain>
```

## PostgREST

```text
http://postgrest-<project>.apps-<cluster-domain>
```

---

# Redeploy

Clean deployment:

```bash
./packaging/undeploy.sh
```

Reinstall:

```bash
./packaging/deploy.sh
```
---

# Useful Commands

View pods:

```bash
oc get pods
```

Check logs:

```bash
oc logs -f <pod>
```

Check deployment rollout:

```bash
oc rollout status deployment/postgrest
```

Inspect routes:

```bash
oc get route
```

---

# Project Structure

```text
foot-cup-sim/
├── src/                     # React frontend
├── public/                  # Runtime config
├── packaging/
│   ├── deploy.sh
│   ├── undeploy.sh
│   ├── db/
│   │   └── worldcup.dump
│   └── k8s/
│       ├── frontend.yaml
│       ├── swagger-ui.yaml
│       ├── postgrest-*.yaml
│       └── db-restore-job.yaml
├── Dockerfile
├── nginx.conf
└── README.md
```

---

# Troubleshooting

## CORS issue

Most CORS issues are caused by **OpenShift Routes forcing HTTPS**.

Verify route configuration and allowed origins.

---

## PostgreSQL restore fails

Check:

```bash
oc logs -f job/worldcup-db-restore
```

---

## PostgREST not responding

Check rollout:

```bash
oc rollout status deployment/postgrest
```