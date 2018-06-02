# Fspin k8s Based Infrastructure
![Architecture](docs/architecture.png)

* TODO: Write Jenkins jobs and create pipeline.
* TODO: Automate pipeline based on SCM events.
* TODO: Automate k8s.fspin.org DNS management.
* TODO: Automate TLS provisioning for Jenkins.
* TODO: Connect Jenkins to FAS.
* TODO: Automate openqa testing.
* TODO: Write user docs.
* TODO: Write contributor docs.
* TODO: Re-org docs to specific specialties.
* TODO: Make everything more generic.
* TODO: A lot.

## fspin Sysadmin Quickstart
Instructions for standing up a full system from the ground up.
These are very specific to the fspin project.

### Install Tools
Install tools for working with this infrastructure:
```console
$ sudo dnf install docker kubernetes-client git
```

Install gcloud sdk:
```console
$ sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo < EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
$ sudo dnf install google-cloud-sdk
```

Install helm (yes, this is nasty):
```console
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
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

### Setup k8s Environment
Login to project and set config defaults:
```console
$ gcloud init
$ gcloud config set project fspin-199819
$ gcloud config set compute/zone us-central1-f
$ gcloud auth configure-docker
$ gcloud container clusters list
```

Create the service account for the cluster nodes:
```console
$ gcloud iam service-accounts create fspin-k8s-nodes --display-name "Fspin GKE Nodes"
$ gcloud projects add-iam-policy-binding fspin-199819 \
  --member serviceAccount:fspin-k8s-nodes@fspin-199819.iam.gserviceaccount.com \
  --role roles/editor
$ gcloud projects add-iam-policy-binding fspin-199819 \
  --member serviceAccount:fspin-k8s-nodes@fspin-199819.iam.gserviceaccount.com \
  --role roles/compute.instanceAdmin.v1
```

Create the k8s cluster:
```console
$ gcloud container clusters create fspin --zone=us-central1-f \
 --node-locations=us-central1-f --cluster-version=1.10.2-gke.3 \
 --enable-autoscaling --num-nodes=1 --min-nodes=1 --max-nodes=10 \
 --disk-size=50 --enable-autorepair \
 --service-account=fspin-k8s-nodes@fspin-199819.iam.gserviceaccount.com
```

Get credentials for the cluster:
```console
$ gcloud container clusters get-credentials fspin
```

Verify cluster is correctly configured:
```console
$ kubectl get all --namespace kube-system
```

### Install Tiller
Create the tiller service account:
```console
$ kubectl create -f k8s/tiller-rbac-config.yaml
serviceaccount "tiller" created
clusterrolebinding.rbac.authorization.k8s.io "tiller" created
```

Install helm using the tiller service account:
```console
$ helm init --service-account tiller
```

### Install Jenkins
Build the Jenkins runner container that has kubectl included:
```console
$ docker build -t gcr.io/fspin-199819/fspin-jenkins-runner jenkins-runner
$ docker push gcr.io/fspin-199819/fspin-jenkins-runner
```

Create the fspin-jenkins service account:
```console
$ kubectl create -f k8s/jenkins-rbac-config.yaml
serviceaccount "fspin-jenkins" created
clusterrolebinding.rbac.authorization.k8s.io "fspin-jenkins" created
```

Install Jenkins using helm:
```console
$ helm install --name fspin-jenkins stable/jenkins \
  --set rbac.install=true,Agent.Image=gcr.io/fspin-199819/fspin-jenkins-runner
```

### Create Repo Storage
Create the network disk:
```console
$ gcloud compute disks create --size=400GB --zone=us-central1-f fspin-mirror-storage-release
```

Create the filesystem on the disk:
```console
$ gcloud compute instances create format-storage --zone us-central1-f --disk name=fspin-mirror-storage-release
$ gcloud compute ssh format-storage --zone us-central1-f --command 'sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb'
$ gcloud compute ssh format-storage --zone us-central1-f --command 'sudo mount /dev/sdb /mnt && sudo chmod a+w /mnt'
$ gcloud compute instances delete format-storage --zone us-central1-f --quiet
```

### Create Repo
Create the container to update the repo/snapshot and push to GCR:
```console
$ docker build -t gcr.io/fspin-199819/fspin-repo-update repo-update
$ docker push gcr.io/fspin-199819/fspin-repo-update
```

If repo already deployed, delete repo hosting (does not delete repo data):
```console
$ kubectl delete deploy repo-fspin-org
```

Run the repo update/snapshot job:
```console
$ kubectl create -f k8s/fspin-update-repo-job.yaml
$ kubectl logs -f job/fspin-repo-update
$ kubectl delete job/fspin-repo-update
```

### Launch the Repo Server
Create the container to serve the repo and push to GCR:
```console
$ docker build -t gcr.io/fspin-199819/fspin-repo-server repo-server
$ docker push gcr.io/fspin-199819/fspin-repo-server
```

Create the repo server deployment:
```console
$ kubectl create -f k8s/repo-fspin-org-deployment.yaml
```

Create the repo server horizontal pod autoscaler (if not already created):
```console
$ kubectl create -f k8s/repo-fspin-org-autoscaler.yaml
```

Create the repo server ingress (if not already created):
```console
$ kubectl create -f k8s/repo-fspin-org-service.yaml
```

### Create the GCE Image Creation Containers
Create the container that imports the upstream image and push to GCR:
```console
$ docker build -t gcr.io/fspin-199819/fspin-cloud-image-import cloud-image-import
$ docker push gcr.io/fspin-199819/fspin-cloud-image-import
```

Create the container to build the updated GCE image and push to GCR:
```console
$ docker build --build-arg snapshot=$(curl -s http://repo.fspin.org/latest_snapshot) \
    -t gcr.io/fspin-199819/fspin-x86-64-builder-update builder-update
$ docker push gcr.io/fspin-199819/fspin-x86-64-builder-update
```

### Create the livemedia-creator fspin Container
Create the container that spins live images and push to GCR:
```console
$ docker build -t gcr.io/fspin-199819/fspin-x86-64-livemedia-creator lmc-create-spin
$ docker push gcr.io/fspin-199819/fspin-x86-64-livemedia-creator
```

### Create the pungi fspin Container
Create the container that creates source ISOs and push to GCR:
```console
$ docker build -t gcr.io/fspin-199819/fspin-x86-64-pungi pungi-create-source
$ docker push gcr.io/fspin-199819/fspin-x86-64-pungi
```

### Launch Upstream Image GCE Import Job, If Needed
This only needs to be done once or when updating the base image from an upstream release.
```console
$ kubectl create -f k8s/fspin-cloud-image-import.yaml
$ kubectl logs -f job/fspin-cloud-image-import
$ kubectl delete job/fspin-cloud-image-import
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
$ for RELEASE in 28
do
  export RELEASE="${RELEASE}"
  for TARGET in workstation xfce soas lxde lxqt cinnamon mate-compiz kde
    do
      export TARGET="${TARGET}"
      envsubst '${RELEASE} ${TARGET}' < "k8s/fspin-x86-64-live-spin-job.yaml" > "jobs/run-f${RELEASE}-x86-64-$TARGET.yaml"
    done
done
```

For example, create a F28 soas spin:
```console
$ kubectl create -f jobs/run-f28-x86-64-soas.yaml
$ kubectl logs -f job/fspin-28-lmc-soas
$ kubectl delete job/fspin-28-lmc-soas
```

For example, create a F28 workstation spin:
```console
$ kubectl create -f jobs/run-f28-x86-64-workstation.yaml
$ kubectl logs -f job/fspin-28-lmc-workstation
$ kubectl delete job/fspin-28-lmc-workstation
```

### Creating Source Images
Create the jobs for the defined releases:
```console
$ for RELEASE in 28
do
  export RELEASE="${RELEASE}"
  envsubst '${RELEASE}' < "k8s/fspin-x86-64-source-spin-job.yaml" > "jobs/run-f${RELEASE}-x86-64-source.yaml"
done
```

For example, run pungi to create the source ISO for the F28 spins:
```console
$ kubectl create -f jobs/run-f28-x86-64-source.yaml
$ kubectl logs -f job/fspin-28-pungi
$ kubectl delete job/fspin-28-pungi
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
Create the publisher container and push to GCR:
*Change the release arg manually if needed.*
```
$ docker build --build-arg release=$(date --utc +%F) \
    -t gcr.io/fspin-199819/fspin-publish publisher
$ docker push gcr.io/fspin-199819/fspin-publish
```

Run the publishing job:
```
$ kubectl create -f k8s/fspin-publish-job.yaml
$ kubectl logs -f job/fspin-publish
$ kubectl delete job/fspin-publish
```
