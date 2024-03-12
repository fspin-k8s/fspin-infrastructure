pipelineJob("snapshot-pipeline") {
  description("Pipeline to create a new repository snapshot.")
  displayName("1) Create Snapshot")
  parameters {
    choiceParam("Release Version", [39, 40], "Fedora release version.")
    stringParam("Snapshot Count", "5", "Number of snapshots to keep on mirror storage.")
    stringParam("Mirror Host", "ohioix.mm.fcix.net", "Mirror to sync from for initial pass. Always checks upstream main mirror after first pass.")
    stringParam("Mirror Path", "fedora-enchilada/linux", "Base Fedora path on the mirror.")
    stringParam("Mirror Exclude", "debug/*", "Pathspec in the mirror to not pull down.")
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url "https://github.com/fspin-k8s/fspin-infrastructure.git"
          }
          branch("main")
        }
      }
      scriptPath("jenkins-jobs/snapshot-pipeline")
    }
  }
}
pipelineJob("builder-pipeline") {
  description("Update the GCE build machine VM image to the latest snapshot.")
  displayName("2) Update Build VM Image")
  parameters {
    choiceParam("Release Version", [39, 40], "Fedora release version.")
    booleanParam("Enable Updates Testing", false, "FIXME: Enable the updates-testing repository for the builder update.  Does not affect repository contents.")
    stringParam("Image Count", "5", "Number of machine images to keep in GCE.")
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url "https://github.com/fspin-k8s/fspin-infrastructure.git"
          }
          branch("main")
        }
      }
      scriptPath("jenkins-jobs/buildvm-pipeline")
    }
  }
}
pipelineJob("spin-pipeline") {
  description("Run a specific re-spin for the requested spin flavor.")
  displayName("3) Run Individual Spin")
  parameters {
    choiceParam("Release Version", [39, 40], "Fedora release version.")
    choiceParam("Spin Flavor", ["workstation", "xfce", "soas", "lxde", "lxqt", "cinnamon", "mate-compiz", "kde", "i3"], "The spin flavor to re-spin.  Must be defined in the https://pagure.io/fedora-kickstarts/ repository.")
    booleanParam("Enable Updates Testing", false, "FIXME: Enable the updates-testing repository for the re-spin.  Does not affect repository contents.")
    stringParam("Project Name", "fspin-ba0660e7cf", "GCP project name. FIXME: Factor out.")
    stringParam("Zone", "us-central1-f", "Compute zone to launch the VM.")
    stringParam("Machine Type", "n1-standard-4", "Compute machine type for the VM.")
    booleanParam("Preemptable", true, "FIXME: Use preemptible compute. (Always enabled.)")
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url "https://github.com/fspin-k8s/fspin-infrastructure.git"
          }
          branch("main")
        }
      }
      scriptPath("jenkins-jobs/spin-pipeline")
    }
  }
}
