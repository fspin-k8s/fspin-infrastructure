pipelineJob("snapshot-pipeline") {
	description("""Pipeline to create a new repository snapshot.""")
	displayName("Create Snapshot")
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
		       				url 'https://github.com/fspin-k8s/fspin-infrastructure.git'
					}
					branch('main')
				}
			}
			scriptPath('jenkins-jobs/snapshot-pipeline')
		}
	}
}
pipelineJob("builder-pipeline") {
	description("Update the GCE build machine image to the latest snapshot.")
	displayName("Update Build VM Image")
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
		       				url 'https://github.com/fspin-k8s/fspin-infrastructure.git'
					}
					branch('main')
				}
			}
			scriptPath('jenkins-jobs/buildvm-pipeline')
		}
	}
}
