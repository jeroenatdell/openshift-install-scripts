#!/bin/bash
source vars/environment.ini
echo "Creating SSH Key"
ssh-keygen -t ed25519 -N '' -f ~/.ssh/ed25519
echo "Installing required packages..."
sudo dnf -y install container-tools nmstate openssl ansible-core ansible-collection-redhat-rhel_mgmt 
echo "Install yq..."
sudo wget https://github.com/mikefarah/yq/releases/download/v4.42.1/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
echo "Installing additional Ansible Galaxy Collections..."
/usr/bin/ansible-galaxy collection install ansible.posix 
/usr/bin/ansible-galaxy collection install community.general
/usr/bin/ansible-galaxy collection install community.crypto

echo "Downloading and installing OpenShift binaries..."

FILE_DOWNLOAD="${DOWNLOAD_MIRROR}/mirror-registry/latest/${MIRROR_REGISTRY}"
DOWNLOADED_FILE="${DOWNLOAD_LOCATION}/${MIRROR_REGISTRY}"
echo -n -e "\rDownloading	${MIRROR_REGISTRY}			[	In Progress	]"
if [ ! -f  ${DOWNLOADED_FILE} ]; then
	wget -q ${FILE_DOWNLOAD} -P ${DOWNLOAD_LOCATION}
fi
echo -n -e "\rDownloading	${MIRROR_REGISTRY}			[	${GREEN}Completed..${DEFAULT}	]"
echo ""
echo -n -e "\rVerifying ${MIRROR_REGISTRY}			[	Verifying	]"

DOWNLOAD_SHA=$(sha256sum ${DOWNLOADED_FILE} | awk '{print $1}')
if [ "${DOWNLOAD_SHA}" = "${MIRROR_REGISTRY_SHA256}" ]; then
	echo -n -e "\rVerifying	${MIRROR_REGISTRY}			[	${GREEN}Verified OK${DEFAULT}	]"
else
	echo -n -e "\rVerifying	${MIRROR_REGISTRY}			[	${RED}Checksum Failed${DEFAULT}	]"
	exit 1
fi
echo ""

echo -n -e "\rInstalling	${MIRROR_REGISTRY}			[	In Progress	]"
if [ ! -d /home/admin/mirror-registry ]; then
	mkdir /home/admin/mirror-registry
fi
tar -xf ${DOWNLOADED_FILE} --exclude=README.md -C /home/admin/mirror-registry
echo -n -e "\rInstalling	${MIRROR_REGISTRY}			[	${GREEN}Completed..${DEFAULT}	]"
echo ""
echo Downloading remaining files...
for TAR_FILE in "${OCP_FILES[@]}"
do
	FILE_DOWNLOAD="${DOWNLOAD_MIRROR}/ocp/${OCP_RELEASE}/${TAR_FILE}"
	DOWNLOADED_FILE="${DOWNLOAD_LOCATION}/${TAR_FILE}"
	EXPECTED_SHA=$(curl -s ${DOWNLOAD_MIRROR}/ocp/${OCP_RELEASE}/sha256sum.txt | grep ${TAR_FILE} | awk '{print $1}')

	echo -n -e "\rDownloading	${TAR_FILE}			[	In Progress	]"
	if [ ! -f  ${DOWNLOADED_FILE} ]; then
		wget -q ${FILE_DOWNLOAD} -P ${DOWNLOAD_LOCATION}
	fi
	echo -n -e "\rDownloading	${TAR_FILE}			[	${GREEN}Completed$..{DEFAULT}	]"
	sleep 2
	echo ""
	echo -n -e "\rVerifying	${TAR_FILE}			[	Verifying	]"
	DOWNLOAD_SHA=$(sha256sum ${DOWNLOADED_FILE} | awk '{print $1}')
	if [ "${DOWNLOAD_SHA}" = "${EXPECTED_SHA}" ]; then
		echo -n -e "\rVerifying	${TAR_FILE}			[	${GREEN}Verified OK${DEFAULT}	]"
	else	
		echo -n -e "\rVerifying	${TAR_FILE}		[      ${RED}Checksum Failed${DEFAULT}    ]"
		exit 1
	fi
	echo ""
	echo -n -e "\rInstalling	${TAR_FILE}			[	In Progress	]"
	if [ -f  ${DOWNLOADED_FILE} ]; then
		/usr/bin/sudo tar -xf ${DOWNLOADED_FILE} --exclude="README.md" -C /usr/local/bin
 	fi
	done
	chmod +x /usr/bin/local/oc-mirror

echo "Preparing storage location"
pushd ansible
/usr/bin/ansible-playbook create-quay-storage.yaml
sudo mkdir -p ${QUAY_ROOT}
sudo mkdir -p ${QUAY_STORAGE}
sudo mkdir -p ${QUAY_PG_STORAGE}
sudo mkdir -p ${REMOVABLE_MEDIA_PATH}
popd

