repo --name=fspin-release-${SNAPSHOT_ID} --cost 1 --baseurl=http://repo.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/$basearch/os/
repo --name=fspin-release-source-${SNAPSHOT_ID} --cost 1 --baseurl=http://repo.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/source/tree/
repo --name=fspin-updates-${SNAPSHOT_ID} --cost 1 --baseurl=http://repo.fspin.org/${SNAPSHOT_ID}/updates/$releasever/$basearch/
repo --name=fspin-updates-source-${SNAPSHOT_ID} --cost 1 --baseurl=http://repo.fspin.org/${SNAPSHOT_ID}/updates/$releasever/SRPMS/
repo --name=fspin-release-${SNAPSHOT_ID}-retry --cost 2 --baseurl=http://repo-retry.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/$basearch/os/
repo --name=fspin-release-source-${SNAPSHOT_ID}-retry --cost 2 --baseurl=http://repo-retry.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/source/tree/
repo --name=fspin-updates-${SNAPSHOT_ID}-retry --cost 2 --baseurl=http://repo-retry.fspin.org/${SNAPSHOT_ID}/updates/$releasever/$basearch/
repo --name=fspin-updates-source-${SNAPSHOT_ID}-retry --cost 2 --baseurl=http://repo-retry.fspin.org/${SNAPSHOT_ID}/updates/$releasever/SRPMS/
url --url=http://repo.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/$basearch/os/
