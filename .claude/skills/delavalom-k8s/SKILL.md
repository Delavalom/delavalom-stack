---
name: delavalom-k8s
description: Kubernetes operations — kubectl commands, pod debugging, deployment strategies, Helm charts, service mesh, log aggregation
version: 1.0.0
author: Luis Arvelo (Delavalom)
triggers:
  - kubernetes
  - kubectl
  - k8s
  - helm
  - pod
  - deployment
  - service mesh
  - container
---

# Kubernetes Operations Skill

## Purpose
Assist with Kubernetes cluster management, debugging, deployment strategies, and infrastructure operations across multi-cell architectures.

## When to Use
- Debugging pod failures, CrashLoopBackOff, OOMKilled
- Writing or reviewing Helm charts and K8s manifests
- Deployment strategies (rolling, blue-green, canary)
- Service mesh configuration (Istio, Linkerd)
- Log aggregation and observability setup
- Multi-cluster / multi-cell management

## Debugging Playbook

### Pod Not Starting
1. `kubectl describe pod <name> -n <ns>` — check Events section
2. `kubectl logs <pod> -n <ns> --previous` — check previous container logs
3. Check resource requests vs limits: `kubectl top pod -n <ns>`
4. Check node capacity: `kubectl describe node | grep -A 5 "Allocated"`

### Networking Issues
1. `kubectl exec -it <pod> -- nslookup <service>` — DNS resolution
2. `kubectl get endpoints <service> -n <ns>` — verify endpoints exist
3. Check NetworkPolicies: `kubectl get networkpolicy -n <ns>`
4. Test connectivity: `kubectl exec -it <pod> -- curl -v <target>`

### Performance Issues
1. `kubectl top pod -n <ns> --sort-by=cpu`
2. Check HPA status: `kubectl get hpa -n <ns>`
3. Review resource quotas: `kubectl describe resourcequota -n <ns>`

## Deployment Patterns

### Rolling Update (Default, Safe)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 0
```

### Blue-Green (Zero Downtime)
- Maintain two identical deployments (blue/green)
- Switch service selector to new version
- Rollback = switch selector back

### Canary (Gradual, Data-Driven)
- Deploy new version to small subset (5-10% traffic)
- Monitor metrics for 15-30 minutes
- Gradually increase traffic if healthy
- Use gstack /canary for post-deploy monitoring

## Helm Chart Best Practices
- Always pin chart versions in requirements.yaml
- Use `helm diff upgrade` before applying
- Store values files in git, never pass --set for production
- Template all environment-specific values
- Include health checks (readiness + liveness probes)

## Security Checklist
- [ ] Pod security context: runAsNonRoot, readOnlyRootFilesystem
- [ ] Network policies restricting ingress/egress
- [ ] Secrets via external-secrets-operator, not plain K8s secrets
- [ ] RBAC: least privilege, no cluster-admin for workloads
- [ ] Image scanning in CI (trivy, grype)
- [ ] Resource limits on every container

## Multi-Cell Architecture
When working across multiple cells/clusters:
- Use consistent naming: `<env>-<region>-<cell>`
- Federate service discovery via DNS or service mesh
- Deploy config changes to canary cell first
- Maintain cell-specific overrides in separate values files
- Monitor cross-cell latency and error rates
