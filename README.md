# Fspin k8s Based Infrastructure
![Architecture](docs/architecture.png)

* TODO: Automate pipeline based on SCM events.
* TODO: Automate openqa testing.
* TODO: Make everything more generic.
* TODO: A lot.

## Creating a Respin - SIG Members
Details on how to use Jenkins to create a respin and interact with the results.

### Install Tools
Install gcloud sdk to make interacting with [GCS](https://cloud.google.com/storage/) easy via `gsutil`.

Install gcloud SDK using snap:
```console
$ sudo dnf install snapd
$ sudo snap install google-cloud-sdk --classic
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
To download the results browse to the [build-results](http://build-results.fspin.org) and construct a download url manually to fetch files. Alternatively, use `gsutil` for easy access to this content.

List what releases are available:
```console
$ gsutil ls gs://build-results.fspin.org/releases/
```

Download a published spin into httpd hosting:
```console
$ gsutil -m cp -r gs://build-results.fspin.org/releases/YYYY-MM-DD/ /var/www/html/
```
*Note: Current user needs to be able to write to destination.*

## Developer Quickstart
These are very specific to the fspin project.

### Install Tools
Install tools for working with this infrastructure:
```console
$ sudo dnf install docker git snapd
```

Install gcloud SDK using snap:
```console
$ sudo snap install google-cloud-sdk --classic
```

Install helm using snap:
```console
$ sudo snap install helm --classic
```

Install kubectl using snap:
```console
$ sudo snap install kubectl --classic
```

### Clone the Git Repo
Clone the git repo read/write:
```console
$ git clone git@github.com:fspin-k8s/fspin-infrastructure.git
```

### Setup Docker Environment
*https://developer.fedoraproject.org/tools/docker/docker-installation.html*
Allow your user to use docker without sudo:
```console
$ sudo groupadd docker && sudo gpasswd -a ${USER} docker && sudo systemctl restart docker
$ newgrp docker
```

### Setup GCP Environment
Login to project and set config defaults:
```console
$ gcloud init
$ gcloud config set project fspin-265404
$ gcloud config set compute/zone us-west2-a
$ gcloud auth configure-docker
$ gcloud container clusters list
```

Get credentials for the cluster:
```console
$ gcloud container clusters get-credentials fspin
```

Verify cluster is correctly configured on the client:
```console
$ kubectl get all --namespace kube-system
```

### Build Docker Layers and Push to [GCR](https://cloud.google.com/container-registry/)
This will build the layers locally and publish them as `latest` to GCR where the cluster pulls images from to run the containers. Please note that whatever is pushed last is considered `latest` even if it's an old version so be sure to know what you are pushing. This only needs to be done if you are changing the layers or they don't already exist in the registry.

Start docker, if needed:
```console
$ sudo systemctl start docker
```

Make sure you are working with all of the latest layers. Clean up your local docker and start fresh:
```console
$ docker system prune -a
```

Build the Jenkins runner image that has kubectl included and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-jenkins-runner jenkins-runner
$ docker push gcr.io/fspin-265404/fspin-jenkins-runner
```

Create the image to update the repo/snapshot and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-repo-update repo-update
$ docker push gcr.io/fspin-265404/fspin-repo-update
```

Create the image to serve the repo and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-repo-server repo-server
$ docker push gcr.io/fspin-265404/fspin-repo-server
```

Create the image that imports the upstream image and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-cloud-image-import cloud-image-import
$ docker push gcr.io/fspin-265404/fspin-cloud-image-import
```

Create the image to build the updated GCE image and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-x86-64-builder-update builder-update
$ docker push gcr.io/fspin-265404/fspin-x86-64-builder-update
```

Create the image that spins live images and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-x86-64-livemedia-creator lmc-create-spin
$ docker push gcr.io/fspin-265404/fspin-x86-64-livemedia-creator
```

Create the image that creates source ISOs and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-x86-64-pungi pungi-create-source
$ docker push gcr.io/fspin-265404/fspin-x86-64-pungi
```

Create the image that publishes content and push to GCR:
```console
$ docker build --no-cache -t gcr.io/fspin-265404/fspin-publish publisher
$ docker push gcr.io/fspin-265404/fspin-publish
```

## Initial Cluster Setup
This only needs to be done if the cluster is not already setup.

Create the service account for the cluster nodes, if not already created:
```console
$ gcloud iam service-accounts create fspin-k8s-nodes --display-name "Fspin GKE Nodes"
$ gcloud projects add-iam-policy-binding fspin-265404 \
  --member serviceAccount:fspin-k8s-nodes@fspin-265404.iam.gserviceaccount.com \
  --role roles/editor
$ gcloud projects add-iam-policy-binding fspin-265404 \
  --member serviceAccount:fspin-k8s-nodes@fspin-265404.iam.gserviceaccount.com \
  --role roles/compute.instanceAdmin.v1
$ gcloud projects add-iam-policy-binding fspin-265404 \
  --member serviceAccount:fspin-k8s-nodes@fspin-265404.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountUser
```

Create the k8s cluster:
```console
$ gcloud beta container clusters create fspin --zone=us-west2-a \
 --node-locations=us-west2-a --release-channel rapid \
 --enable-autoscaling --num-nodes=1 --min-nodes=1 --max-nodes=10 --machine-type e2-medium \
 --enable-vertical-pod-autoscaling --enable-autoupgrade \
 --enable-autorepair --no-enable-basic-auth --no-issue-client-certificate --enable-ip-alias \
 --enable-shielded-nodes \
 --service-account=fspin-k8s-nodes@fspin-265404.iam.gserviceaccount.com \
 --metadata disable-legacy-endpoints=true
```

Get credentials for the cluster:
```console
$ gcloud container clusters get-credentials fspin
```

Verify cluster is correctly configured on the client:
```console
$ kubectl get all --namespace kube-system
```

### Deploy Automatic DNS Management
Create the fspin-dns service account:
```
$ kubectl create -f k8s/external-dns-rbac-config.yaml
```

Install external-dns using helm:
```console
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm repo update
$ helm install fspin-dns -f helm/external-dns-values.yaml bitnami/external-dns
```

### Deploy NGINX Ingress Controller
Install [NGINX](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/) using helm:
```console
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
$ helm repo update
$ helm install fspin-ingress -f helm/ingress-nginx-values.yaml ingress-nginx/ingress-nginx
```

Ensure that DNS is resolving before proceeding or [ACME](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment) challenges will fail:
```console
$ watch dig +short ingress.k8s.fspin.org
```

### Deploy cert-manager for Automatic TLS
Install [cert-manager](https://cert-manager.io/) using helm:
```console
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update
$ helm install fspin-tls jetstack/cert-manager \
  --set installCRDs=true \
  --set ingressShim.defaultIssuerName=letsencrypt-prod \
  --set ingressShim.defaultIssuerKind=ClusterIssuer \
  --set ingressShim.defaultIssuerGroup=cert-manager.io
```

Install the ClusterIssuer once cert-manager has successfully started:
```console
$ kubectl create -f k8s/cert-manager-cluster-issuer.yaml
```

### Install Jenkins
Make sure you have already created the `jenkins-runner` docker image before running this step.

Create the fspin-jenkins service account:
```console
$ kubectl create -f k8s/jenkins-rbac-config.yaml
```

Install Jenkins using helm:
```console
$ helm repo update
$ helm install --name fspin-jenkins -f helm/jenkins-values.yaml stable/jenkins
```

Setup the SSO for FAS users in the [Jenkins Global Security](https://jenkins.fspin.org/configureSecurity) settings:

*Do not do unless TLS is working.*

* Configure Global Security -> Authentication -> Security Realm -> OpenID SSO -> Provider URL: `https://id.fedoraproject.org`
* Configure Global Security -> Authorization -> Authorization -> Matrix-based security -> Add user or group: `respins-sig`
* Configure Global Security -> Authorization -> Authorization -> Matrix-based security -> Set "Administer" for "respins-sig"

### Install Jenkins Jobs
TODO: Automate adding of Jenkins jobs. For now, manually create the pipeline jobs with the jobs defined in [jenkins-jobs](jenkins-jobs)

### Create Repo Storage, If Needed
Create the network disk:
```console
$ gcloud compute disks create --size=300GB --zone=us-west2-a fspin-mirror-storage-release
```

Create the filesystem on the disk:
```console
$ gcloud compute instances create format-storage --zone us-west2-a --disk name=fspin-mirror-storage-release
$ gcloud compute ssh format-storage --zone us-west2-a --command 'sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb'
$ gcloud compute ssh format-storage --zone us-west2-a --command 'sudo mount /dev/sdb /mnt && sudo chmod a+w /mnt'
$ gcloud compute instances delete format-storage --zone us-west2-a --quiet
```

### Create/Update Repo
Make sure you have already created the `repo-update` and `repo-server` docker images before running this step.

If repo already deployed, delete repo hosting (does not delete repo data):
```console
$ kubectl delete deploy repo-fspin-org-deployment
```

Run the repo update/snapshot job:
```console
$ kubectl create -f k8s/fspin-update-repo-job.yaml
$ kubectl logs -f job/fspin-repo-update
$ kubectl delete job/fspin-repo-update
```

Create the repo server deployment:
```console
$ kubectl create -f k8s/repo-fspin-org-deployment.yaml
```

Create the repo server service (if not already created):
```console
$ kubectl create -f k8s/repo-fspin-org-service.yaml
```

Create the repo server ingress (if not already created):
```console
$ kubectl create -f k8s/repo-fspin-org-ingress.yaml
```

Create the retry repo server ingress (if not already created):
```console
$ kubectl create -f k8s/repo-retry-fspin-org-ingress.yaml
```

Create the repo server horizontal pod autoscaler (if not already created):
```console
$ kubectl create -f k8s/repo-fspin-org-autoscaler.yaml
```

## Manually Running Jobs
Only do this if you need to directly test the k8s jobs. Otherwise, use Jenkins.

### Launch Upstream Image GCE Import Job, If Needed
This only needs to be done once or when updating the base image from an upstream release.

*You will also need to enable [Service Usage API](https://console.developers.google.com/apis/api/serviceusage.googleapis.com/overview) to be able to import.*

Add IAM management role to the service account:
```console
$ gcloud projects add-iam-policy-binding fspin-265404 \
  --member serviceAccount:fspin-k8s-nodes@fspin-265404.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectIamAdmin
```

Run the import:
```console
$ kubectl create -f k8s/fspin-cloud-image-import.yaml
$ kubectl logs -f job/fspin-cloud-image-import
$ kubectl delete job/fspin-cloud-image-import
```

Remove IAM management role from the service account:
```console
$ gcloud projects remove-iam-policy-binding fspin-265404 \
  --member serviceAccount:fspin-k8s-nodes@fspin-265404.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectIamAdmin
```

### Launch Fspin GCE Builder Update Job
This updates the upstream base image with the latest snapshot updates and creates the builder image.
```console
$ kubectl create -f k8s/fspin-x86-64-update-image-job.yaml
$ kubectl logs -f job/fspin-x86-64-builder-update
$ kubectl delete job/fspin-x86-64-builder-update
```

### Creating Live Images
Create the jobs for the defined live spins:
```console
$ for RELEASE in 32
do
  export RELEASE="${RELEASE}"
  for TARGET in workstation xfce soas lxde lxqt cinnamon mate-compiz kde
    do
      export TARGET="${TARGET}"
      envsubst '${RELEASE} ${TARGET}' < "k8s/fspin-x86-64-live-spin-job.yaml" > "jobs/run-f${RELEASE}-$TARGET.yaml"
    done
done
```

For example, create a F32 soas spin:
```console
$ kubectl create -f jobs/run-f32-soas.yaml
$ kubectl logs -f job/fspin-f32-soas
$ kubectl delete job/fspin-f32-soas
```

For example, create a F32 workstation spin:
```console
$ kubectl create -f jobs/run-f32-workstation.yaml
$ kubectl logs -f job/fspin-f32-workstation
$ kubectl delete job/fspin-f32-workstation
```

### Creating Source Images
Create the jobs for the defined releases:
```console
$ for RELEASE in 32
do
  export RELEASE="${RELEASE}"
  envsubst '${RELEASE}' < "k8s/fspin-x86-64-source-spin-job.yaml" > "jobs/run-f${RELEASE}-source.yaml"
done
```

For example, run pungi to create the source ISO for the F32 spins:
```console
$ kubectl create -f jobs/run-f32-source.yaml
$ kubectl logs -f job/fspin-f32-source
$ kubectl delete job/fspin-f32-source
```

### Run All
Run all defined jobs:
```console
$ for JOB in $(ls jobs/*)
do
  kubectl create -f $JOB
done
```

### Publishing the Results
Run the publishing job:
```console
$ kubectl create -f k8s/fspin-publish-job.yaml
$ kubectl logs -f job/fspin-publish
$ kubectl delete job/fspin-publish
```
