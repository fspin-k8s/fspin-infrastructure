# Fspin k8s Based Infrastructure
![Architecture](docs/architecture.png)

* TODO: Automate pipeline based on SCM events.
* TODO: Automate openqa testing.
* TODO: Make everything more generic.
* TODO: A lot.

## Creating a Respin - SIG Members
Details on how to use Jenkins to create a respin and interact with the results.

### Install Tools
Install gcloud CLI to make interacting with [GCP Resources](https://cloud.google.com/) easy via `gcloud`.

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

Setup [Terraform](https://www.terraform.io/) repo:
```console
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
```

Install required packages:
```console
sudo dnf install google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin libxcrypt-compat terraform kubernetes-client helm
```

Configure kubernetes authentication:
```console
mkdir -p ~/.bashrc.d
tee ~/.bashrc.d/use-gke-cloud-auth-plugin << EORCD
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
EORCD
source ~/.bashrc
```

### Login to Jenkins
[Jenkins](https://jenkins.fspin.org/) is configured to run all of the needed jobs. Login with your FAS account with spin SIG membership.

### Overview
Update the repo from upstream, create a new snapshot and builder via `create-snapshot`. 
Create a spin using the latest snapshot and matching builder via `create-fspin`. 
Publish the results of a the spin via `publish-fspin`. 
Results publish to [build-results](http://build-results.fspin.org) GCS.

### Create a Snapshot
The snapshot job updates the repos to match current upstream, creates a time based snapshot of the repos, boots and updates the official image to the snapshot and creates a builder from that instance. This builder is now used for all spin activities to ensure all installed package and the running kernel matches the spin target.

### Create Fspin
The spin job launches a pipeline of builds that launch their own dedicated virtual machines running the target snapshot. These instances are configured to explicitly use the snapshot they were updated to for dnf, mock, lmc, pungi, etc.

### Publish the Results
The publish job takes the spin results and publishes them to a known location in the build-results GCS storage, combining the hashes and cleaning up. In the future this phase would also do activities such as generating deltas for packages installed, etc.

### Accessing the Results
To download the results browse to the [build-results](http://build-results.fspin.org) and construct a download url manually to fetch files. Alternatively, use `gcloud storage` for easy access to this content.

List what releases are available:
```console
gcloud storage ls gs://build-results.fspin.org/releases/
```

Download a published spin into httpd hosting:
```console
gcloud storage cp gs://build-results.fspin.org/releases/YYYY-MM-DD/ /var/www/html/ --recursive
```
*Note: Current user needs to be able to write to destination.*

## Developer Quickstart
These are very specific to the fspin project.

### Install Tools

Setup Google Cloud SDK repo:
```console
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
```

Install required packages:
```console
sudo dnf install dnf-plugins-core google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin libxcrypt-compat git podman helm kubectl
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

### Setup GCP Environment
Authenticate and setup [ADC](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) and helpers:
```console
gcloud auth login --brief
gcloud auth application-default login
gcloud auth configure-docker
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

Build the Jenkins runner image that has kubectl included and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-jenkins-runner jenkins-runner
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-jenkins-runner
```

Create the image to update the repo/snapshot and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-repo-update repo-update
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-repo-update
```

Create the image to serve the repo and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-repo-server repo-server
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-repo-server
```

Create the image to build the updated GCE image and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-x86-64-builder-update builder-update
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-x86-64-builder-update
```

Create the image that spins live images and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-x86-64-livemedia-creator lmc-create-spin
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-x86-64-livemedia-creator
```

Create the image that publishes content and push to GCR:
```console
podman build --no-cache -t gcr.io/`terraform -chdir=terraform output -raw project`/fspin-publish publisher
podman push gcr.io/`terraform -chdir=terraform output -raw project`/fspin-publish
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
  --set installCRDs=true \
  --set ingressShim.defaultIssuerName=letsencrypt-prod \
  --set ingressShim.defaultIssuerKind=ClusterIssuer \
  --set ingressShim.defaultIssuerGroup=cert-manager.io
```

Install the ClusterIssuer once cert-manager has successfully started:
```console
kubectl create -f k8s/cert-manager-cluster-issuer.yaml
```

### Install Jenkins
Make sure you have already created the `jenkins-runner` podman image before running this step.

*Do not proceed unless TLS is working.*

Create the fspin-jenkins service account:
```console
kubectl create -f k8s/jenkins-rbac-config.yaml
```

Install Jenkins using helm:
```console
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install fspin-jenkins -f helm/jenkins-values.yaml jenkins/jenkins
```

### Install Jenkins Jobs
TODO: Automate adding of Jenkins jobs. For now, manually create the pipeline jobs with the jobs defined in [jenkins-jobs](jenkins-jobs)

### Create/Update Repo
Make sure you have already created the `repo-update` and `repo-server` podman images before running this step.

If repo already deployed, delete repo hosting (does not delete repo data):
```console
kubectl delete deploy repo-fspin-org-deployment
```

Run the repo update/snapshot job:
```console
kubectl create -f k8s/fspin-update-repo-job.yaml
kubectl logs -f job/fspin-repo-update
kubectl delete job/fspin-repo-update
```

Create the repo server deployment:
```console
kubectl create -f k8s/repo-fspin-org-deployment.yaml
```

Create the repo server service (if not already created):
```console
kubectl create -f k8s/repo-fspin-org-service.yaml
```

Create the repo server ingress (if not already created):
```console
kubectl create -f k8s/repo-fspin-org-ingress.yaml
```

Create the retry repo server ingress (if not already created):
```console
kubectl create -f k8s/repo-retry-fspin-org-ingress.yaml
```

Create the repo server horizontal pod autoscaler (if not already created):
```console
kubectl create -f k8s/repo-fspin-org-autoscaler.yaml
```

## Manually Running Jobs
Only do this if you need to directly test the k8s jobs. Otherwise, use Jenkins.

### Launch Fspin GCE Builder Update Job
This updates the upstream base image with the latest snapshot updates and creates the builder image.

Import upstream image (temporary until upstream adds this to the fedora-cloud resource in GCP):
```console
gcloud cloud-shell ssh
wget https://dl.fedoraproject.org/pub/fedora/linux/releases/37/Cloud/x86_64/images/Fedora-Cloud-Base-GCP-37-1.7.x86_64.tar.gz
gcloud auth login --brief
gcloud storage buckets create gs://SOME_BUCKET_VALID_NAME_THAT_IS_NEW_WITH_NO_DATA!
gcloud storage cp Fedora-Cloud-Base-GCP-37-1.7.x86_64.tar.gz gs://SOME_BUCKET_VALID_NAME_THAT_IS_NEW_WITH_NO_DATA!
gcloud compute images create fspin-fedora-cloud-base-gcp-37-1-7 --source-uri gs://SOME_BUCKET_VALID_NAME_THAT_IS_NEW_WITH_NO_DATA!/Fedora-Cloud-Base-GCP-37-1.7.x86_64.tar.gz
gcloud storage rm gs://SOME_BUCKET_VALID_NAME_THAT_IS_NEW_WITH_NO_DATA!/*
gcloud storage buckets delete gs://SOME_BUCKET_VALID_NAME_THAT_IS_NEW_WITH_NO_DATA!/
gcloud auth revoke
```

```console
kubectl create -f k8s/fspin-x86-64-update-image-job.yaml
kubectl logs -f job/fspin-x86-64-builder-update
kubectl delete job/fspin-x86-64-builder-update
```

### Creating Live Images
Create the jobs for the defined live spins:
```console
for RELEASE in 37
do
  export RELEASE="${RELEASE}"
  for TARGET in workstation xfce soas lxde lxqt cinnamon mate-compiz kde i3
    do
      export TARGET="${TARGET}"
      envsubst '${RELEASE} ${TARGET}' < "k8s/fspin-x86-64-live-spin-job.yaml" > "jobs/run-f${RELEASE}-$TARGET.yaml"
    done
done
```

For example, create a F37 soas spin:
```console
kubectl create -f jobs/run-f37-soas.yaml
kubectl logs -f job/fspin-f37-soas
kubectl delete job/fspin-f37-soas
```

For example, create a F37 workstation spin:
```console
kubectl create -f jobs/run-f37-workstation.yaml
kubectl logs -f job/fspin-f37-workstation
kubectl delete job/fspin-f37-workstation
```

### Run All
Run all defined jobs:
```console
for JOB in $(ls jobs/*)
do
  kubectl create -f $JOB
done
```

### Publishing the Results
Run the publishing job:
```console
kubectl create -f k8s/fspin-publish-job.yaml
kubectl logs -f job/fspin-publish
kubectl delete job/fspin-publish
```
