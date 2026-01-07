# thed-guestbook – My GitOps Journey with ArgoCD

## Table of Contents

* Background
* Project Goal
* Architecture Overview
* Reuse of Previous Work
* Repository Structure
* ArgoCD Application
* GitOps in Practice
* Problems I Encountered
* Design Decisions
* Future Improvements
* Final Thoughts

---

## Background

In this project I migrated the deployment workflow for **thed-guestbook** from a manual Helm / kubectl based approach into a fully GitOps-driven solution using **ArgoCD**.

Previously I deployed the application manually, which worked – but it was fragile, hard to reproduce and easy to break.

Old flow:

```
Developer → helm install / kubectl apply → Kubernetes
```

New flow:

```
Git commit → ArgoCD → Kubernetes
```

Now Git truly controls my cluster.

---

## Project Goal

My main objectives were to:

* Reuse Docker images from my earlier projects
* Reuse and adapt my existing Helm charts
* Let ArgoCD take over full responsibility for deployments
* Eliminate configuration drift
* Build something that is repeatable, transparent and production-like

---

## Architecture Overview

The cluster is now continuously reconciled by ArgoCD.
If something changes in the cluster that is not in Git, ArgoCD corrects it automatically.

Git is the **single source of truth**.

---

## Reuse of Previous Work

Instead of rebuilding everything from scratch, I reused:

| Resource       | Source                               |
| -------------- | ------------------------------------ |
| Docker images  | My earlier image repository          |
| Helm charts    | My previous Helm chart repo          |
| YAML manifests | Refactored versions of old manifests |

This significantly reduced the workload and forced me to design reusable components.

---

## Repository Structure

```
thed-guestbook/
├── argocd/
│   └── application.yaml
├── helm/
│   └── guestbook/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── README.md
```

---

## ArgoCD Application

The ArgoCD Application points directly to this repository and the Helm chart:

```yaml
spec:
  source:
    repoURL: https://github.com/<user>/thed-guestbook.git
    path: helm/guestbook
    targetRevision: main
    helm:
      valueFiles:
        - values.yaml
```

Automated sync with `selfHeal` and `prune` enabled means the cluster is always aligned with Git.

---

## GitOps in Practice

Working this way changed how I think about Kubernetes:

* I no longer deploy manually
* Every change is a Git commit
* Rollback is simply `git revert`
* The cluster state is never a mystery

---

## Problems I Encountered

### Helm Charts Not Designed for GitOps

Some charts expected CLI overrides.

**Fix:**
Everything was moved into `values.yaml` so ArgoCD could deploy without manual flags.

---

### Image Drift Caused by `latest`

Using `latest` tags resulted in unexpected updates.

**Fix:**
All images are now version-pinned.

---

### ArgoCD Sync Issues

I initially had drift due to namespaces and Helm defaults.

**Fix:**
Explicit namespaces were defined and automated sync with self-healing was enabled.

---

### Reusing Multiple Repositories

Older repos were tightly coupled with hard-coded paths.

**Fix:**
Charts were modularized and referenced through Git URLs instead of local paths.

---

## Design Decisions

| Choice                  | Reason                              |
| ----------------------- | ----------------------------------- |
| ArgoCD                  | Industry standard GitOps controller |
| Helm                    | Flexible templating and reuse       |
| Single application repo | Clear source of truth               |
| Version-pinned images   | Predictable releases                |

---

## Future Improvements

### Security

* Introduce SealedSecrets or ExternalSecrets
* Harden ArgoCD RBAC
* Add Trivy image scanning in CI
* Add NetworkPolicies
* Disable ArgoCD admin login

### Performance

* Add HPA for autoscaling
* Define resource limits and requests
* Add readiness and liveness probes
* Use Argo Rollouts for blue/green deployments
* Introduce caching where possible

---

## Final Thoughts

This project clearly showed me the real power of GitOps.

What started as “just another Kubernetes app” has now become a:

* Fully version-controlled system
* Self-healing environment
* Reproducible deployment pipeline

This GitOps foundation will make future development, debugging and scaling significantly easier.

