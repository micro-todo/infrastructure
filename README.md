# MicroTodo Infrastructure

Minimal, task-focused guide for provisioning AWS infra (Terraform) and deploying Kubernetes workloads for MicroTodo.

## What’s here
- Terraform: EKS, VPC, IAM, ALB controller, EBS CSI, ECR repos
- Kubernetes: namespaces, Postgres + RabbitMQ, External Secrets, services, ingress

## Prerequisites
- Terraform >= 1.13, AWS CLI, kubectl
- AWS credentials with permissions for EKS/VPC/IAM/ELB/ECR/Secrets Manager

## Quick start
1) Provision AWS infra
```bash
cd terraform
terraform init
terraform apply
```

2) Configure kubectl
```bash
aws eks update-kubeconfig --name microtodo_eks_cluster --region eu-west-2
```

3) Deploy Kubernetes
```bash
kubectl apply -f k8s/namespaces
kubectl apply -R -f k8s/
```

## Images and ECR
- Terraform creates ECR repos for: api-gateway, users-service, tasks-service, notifications-service
- Outputs: `ecr_registry_url`, `ecr_repository_urls`
- Push your images to those repos and use the tags in Deployments

## Secrets (External Secrets)
- `ClusterSecretStore` reads from AWS Secrets Manager via IRSA
- `ExternalSecret` writes to `microtodo-secrets` (DB/RabbitMQ/JWT secrets)

## Databases & Storage
- Postgres and RabbitMQ run as StatefulSets on EBS (EBS CSI addon via Terraform)
- Default StorageClass: gp3 (see `k8s/storage/gp3-storageclass.yaml`)

## Migrations (Prisma)
- Each service has a `migrate.yaml` Job that runs `npx prisma migrate deploy`
- `DATABASE_URL` is constructed at runtime from env
```bash
kubectl apply -f k8s/services/users-service/migrate.yaml
kubectl apply -f k8s/services/tasks-service/migrate.yaml
kubectl apply -f k8s/services/notifications-service/migrate.yaml
kubectl -n microtodo wait --for=condition=complete job/users-service-migrate job/tasks-service-migrate job/notifications-service-migrate --timeout=5m
```

## Health checks (TCP exec probes)
- Services are TCP (NestJS). Probes send a payload to localhost:
  - Payload: `39#{"pattern":"health","data":[],"id":"1"}`
  - Probes use Node’s `net` module; port comes from `PROBE_PORT` or `TCP_PORT/PORT`
  - `startupProbe` (lenient), `readinessProbe` (moderate), `livenessProbe` (resilient)

## Ingress / ALB
- Ingress uses `ingressClassName: alb`
- Get hostname:
```bash
kubectl -n microtodo get ingress api-gateway-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```
- For HTTPS, set certificate ARN and SSL redirect annotations

## Common gotchas (fast fixes)
- PVC Pending: ensure EBS CSI addon is running; gp3 StorageClass applied
- Postgres CrashLoop (lost+found): PGDATA set to subdirectory; initContainer chowns volume
- Prisma fails: ensure `DATABASE_URL` expands (or is exported in command) and DB reachable
- ALB hostname empty: verify subnet tags and ALB controller IAM policy
- RabbitMQ auth: ensure secret creds match; delete RabbitMQ PVC to re-seed if needed

## Cleanup
```bash
kubectl delete namespace microtodo --grace-period=0 --force --ignore-not-found
terraform -chdir=terraform destroy -auto-approve
```
