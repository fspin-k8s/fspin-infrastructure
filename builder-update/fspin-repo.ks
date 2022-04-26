repo --name=fspin-release-${SNAPSHOT_ID} --cost 1 --baseurl=https://repo.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/$basearch/os/
repo --name=fspin-updates-${SNAPSHOT_ID} --cost 1 --baseurl=https://repo.fspin.org/${SNAPSHOT_ID}/updates/$releasever/$basearch/
repo --name=fspin-release-${SNAPSHOT_ID}-retry --cost 2 --baseurl=https://repo-retry.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/$basearch/os/
repo --name=fspin-updates-${SNAPSHOT_ID}-retry --cost 2 --baseurl=https://repo-retry.fspin.org/${SNAPSHOT_ID}/updates/$releasever/$basearch/
url --url=https://repo.fspin.org/${SNAPSHOT_ID}/releases/$releasever/Everything/$basearch/os/
