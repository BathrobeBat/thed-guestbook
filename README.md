# thed-guestbook - GitOps-migrering med ArgoCD

## Innehåll
- Bakgrund
- Mål
- Arkitektur
- Återanvändning av resurser
- Repostruktur
- ArgoCD-Konfiguration
- GitOps-principer
- Problem och åtgärder
- Motivering av designval
- Förbättringsförslag (säkerhet och prestanda)
- Slutsats

## Bakgrund
Detta projekt syftade till att migrera deploymenten av **thed-guestbook** från ett manuellt Helm/Kubectl-flöde till ett fullt GitOps-baserat arbetssätt med **ArgoCD**

Tidigare flöde:
`Developer → helm install / kubectl apply → Kubernetes`

Nytt flöde:
`Git commit → ArgoCD → Kubernetes`

## Mål
- Återanvända befintliga Docker images
- Återanvända Helm-charts från tidigare repositories
- Låta ArgoCD ta fullt ansvar för deployment
- Eliminera manuell drift
- Skapa ett reproducerbart och spårbart flöde

## Arkitektur
Git fungerar nu som **single source of truth**.

Alla förändringar i klustret sker genom Git-commits som ArgoCD synkar automatiskt.

## Återanvändning av resurser
```
Resurs            Ursprung
---               ---
Docker images     Tidigare image-repo
Helm charts       Tidigare helm-repo
YAML-manifest     Modifierade versioner av befintliga
```
Detta minimerade duplicering och ökade stabiliteten i migreringen.

## Repostruktur
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

## ArgoCD-konfiguration
`argocd/application.yaml` pekar på detta repo och Helm-chartet:
```
spec:
  source:
    repoURL: https://github.com/<user>/thed-guestbook.git
    path: helm/guestbook
    targetRevision: main
    helm:
      valueFiles:
        - values.yaml
```
Automatisk synk är aktiverad med `selfheal`och `prune`.

## GitOps-principer
- Git är alltid sanning
- Ingen manuell deployment i klustret
- Alla ändringar sker via Pull Requests
- Rollback = Git revert

## Problem och lösningar
**Helm-beroenden**

Tidigare charts krävde CLI-flaggar.

**Lösning:** Alla värden flyttades till `values.yaml`.

---
**Image-drift (`latest`)**

Orsakade oförutsägbara uppdateringar.

**Lösning:** Versionspinnande images

---

**ArgoCD-synkproblem**

Fel namespaces och defaults.

**Lösning:** Explicit namespace + aktiverad `selfheal` och `prune`.

---

**Återanvändning av repos**

Hårdkodade paths mellan repos

**Lösning:** Modularisering och konsekventa Git-URL-referenser.

## Motivering av designval

```
Val                        Motivering
---                        ---
ArgoCD                     Standard för GitOps
Helm                       Parametrisering och återanvändning
Ett app-repo               Tydligare single source of truth
Versionspinnande images    Reproducerbara releaser
```

## Förbättringsförslag
**Säkerhet**
```
Förslag                          Effekt
---                              ---
SealedSecrets/ExternalSecrets    Inga hemligheter i Git
RBAC-härdning i ArgoCD           Mindre attackyta
Image scanning (Trivy)           Stoppa sårbara images
NetworkPolicies                  Isolera applikationen
Stäng av admin-login i ArgoCD    Ökad säkerhet
```

---

**Prestanda**
```
Förslag                          Effekt
---                              ---
HPA                              Automatisk skalning
Resource limits/requests         Stabilare pods
Liveness/readiness probes        Snabbare återhämtning
Argo Rollouts (blue/green)       Noll-downtime deploy
Cache-strategier                 Lägre svarstider
```

## Slutsats
Migreringen till GitOps med ArgoCD har gjort **thed-guestbook**
- Mer pålitlig
- Enklare att underhålla
- Fullt versionsstyrd

Projektet utgör nu en stabil grund för framtida vidareutveckling och CI/CD-automatisering.

Det gick inte helt smärtfritt i början men under arbetets gång lärde jag mig mycket som gör att liknande projekt kommer gå betydligt snabbare att genomföra i framtiden.
