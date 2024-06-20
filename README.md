# Fspin k8s Based Infrastructure
![Architecture](docs/architecture.png)

* TODO: Make more generic and continue to factor out manual steps
* TODO: Enable running on a standalone Jenkins instance without cloud services

## Creating a Respin - SIG Members
Details on how to use Jenkins to create a respin and interact with the results.

### Login to Jenkins
[Jenkins](https://jenkins.fspin.org/) is configured to run all of the needed jobs. Login with your FAS account with spin SIG membership.

### Overview
Update the repo from upstream and create a new repository snapshot. Then a build machine image is updated against that snapshot. A spin is then created using the latest snapshot and matching builder. Results are then published to [GCS](https://cloud.google.com/storage) and a distribution server.

### Create a Snapshot
The snapshot job updates the repos to match current upstream, creates a time based snapshot of the repos, boots and updates the official image to the snapshot and creates a builder from that instance. This builder is now used for all spin activities to ensure all installed package and the running kernel matches the spin target.

### Create Fspin
The spin job launches a pipeline of builds that launch their own dedicated virtual machines running the target snapshot. These instances are configured to explicitly use the snapshot they were updated to for dnf, mock, lmc, pungi, etc.

### Publish the Results
The publish job takes the spin results and publishes them to a known location in the build-results GCS storage, combining the hashes and cleaning up. In the future this phase would also do activities such as generating deltas for packages installed, etc.

## Developer Quickstart
These are very specific to the fspin project.

### Install Tools

Setup Google Cloud SDK repo:
```console
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
```

Install required packages:
```console
sudo dnf install dnf-plugins-core google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin libxcrypt-compat kubernetes-client git podman helm
```

Install [Terraform](https://terraform.io/):
```console
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf install terraform
```

### Clone the Git Repo
Clone the git repo read/write:
```console
git clone git@github.com:fspin-k8s/fspin-infrastructure.git
cd fspin-infrastructure
```

### Setup [GCP](https://cloud.google.com/) Environment
Authenticate and setup [ADC](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) and helpers:
```console
gcloud auth login --brief
gcloud auth application-default login
gcloud auth configure-docker
```

Configure kubernetes authentication:
```console
mkdir -p ~/.bashrc.d
tee ~/.bashrc.d/use-gke-cloud-auth-plugin << EORCD
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
EORCD
source ~/.bashrc
```

### Setup GCP Infrastructure
Create remote resources using terraform:
```console
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

If desired, setup some defaults for the environment:
```console
tee terraform/terraform.tfvars << EOM
billing_id = "SOMETHING-VALID"
project_prefix = "fspin"
region = "us-central1"
zone = "us-central1-f"
EOM
```

### Configure Defaults
```console
gcloud config set project `terraform -chdir=terraform output -raw project`
gcloud config set compute/zone `terraform -chdir=terraform output -raw zone`
```

### Confirm Kubernetes Environment
```console
gcloud container clusters list
gcloud container clusters get-credentials `terraform -chdir=terraform output -raw cluster_name`
kubectl get all --namespace kube-system
```

### Build Layers and Push to [GCR](https://cloud.google.com/container-registry/)
This will build the layers locally and publish them as `latest` to GCR where the cluster pulls images from to run the containers. Please note that whatever is pushed last is considered `latest` even if it's an old version so be sure to know what you are pushing. This only needs to be done if you are changing the layers or they don't already exist in the registry.

Build the custom Jenkins runner image that has kubectl, gcloud, and packer included and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-jenkins-runner jenkins-runner
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-jenkins-runner
```

Create the image to serve the repo and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-repo-server repo-server
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-repo-server
```

### Import Upstream GCP Image Into Project
This will import the Fedora GCP release image into GCE for use as the base for the builder VM image.

Import upstream image (temporary until upstream adds this to the fedora-cloud resource in GCP):
```console
gcloud cloud-shell ssh --authorize-session
export TEMP_BUCKET=fspin-images-create-$(date --utc +%F-%s)
wget https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-GCE.x86_64-40-1.14.tar.gz
gcloud storage buckets create gs://${TEMP_BUCKET}
gcloud storage cp Fedora-Cloud-Base-GCE.x86_64-40-1.14.tar.gz gs://${TEMP_BUCKET}
gcloud compute images create fspin-fedora-cloud-base-gce-40-1-14 --source-uri gs://${TEMP_BUCKET}/Fedora-Cloud-Base-GCE.x86_64-40-1.14.tar.gz
gcloud storage rm gs://${TEMP_BUCKET}/*
gcloud storage buckets delete gs://${TEMP_BUCKET}/
```

### Deploy Automatic DNS Management
Create the fspin-dns service account:
```console
kubectl create -f k8s/external-dns-rbac-config.yaml
```

Install external-dns using helm:
```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install fspin-dns -f helm/external-dns-values.yaml bitnami/external-dns
```

### Deploy NGINX Ingress Controller
Install [NGINX](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/) using helm:
```console
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install fspin-ingress -f helm/ingress-nginx-values.yaml ingress-nginx/ingress-nginx
```

Ensure that DNS is resolving before proceeding or [ACME](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment) challenges will fail:
```console
watch dig +short ingress.k8s.fspin.org
```

### Deploy cert-manager for Automatic TLS
Install [cert-manager](https://cert-manager.io/) using helm:
```console
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install fspin-tls jetstack/cert-manager \
  --set crds.enabled=true \
  --set ingressShim.defaultIssuerName=letsencrypt-prod \
  --set ingressShim.defaultIssuerKind=ClusterIssuer \
  --set ingressShim.defaultIssuerGroup=cert-manager.io
```

Install the ClusterIssuer once cert-manager has successfully started:
```console
kubectl create -f k8s/cert-manager-cluster-issuer.yaml
```

### Install Jenkins
Make sure you have already created and pushed the `jenkins-runner` podman image before running this step.

Create the fspin-jenkins service account:
```console
kubectl create -f k8s/jenkins-rbac-config.yaml
```

Install [Jenkins](https://www.jenkins.io/) using helm:
```console
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install fspin-jenkins -f helm/jenkins-values.yaml jenkins/jenkins
```

*** FIXME: fspin-jenkins-repo pod template requires "Run As User ID" = 0 ***
https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/values.yaml#L1128

### Create Empty Repo
Make sure you have already created and pushed the `repo-server` podman image before running these steps.

Create the mirror storage volume:
```console
kubectl create -f k8s/fspin-mirror-storage-pvc.yaml
```

Create the repo server deployment:
```console
kubectl create -f k8s/repo-fspin-org-deployment.yaml
```

Create the repo server service:
```console
kubectl create -f k8s/repo-fspin-org-service.yaml
```

Create the repo server ingress:
```console
kubectl create -f k8s/repo-fspin-org-ingress.yaml
```

Create the retry repo server ingress:
```console
kubectl create -f k8s/repo-retry-fspin-org-ingress.yaml
```

Create the repo server horizontal pod autoscaler:
```console
kubectl create -f k8s/repo-fspin-org-autoscaler.yaml
```
