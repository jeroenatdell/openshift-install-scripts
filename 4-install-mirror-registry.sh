#!/bin/bash
source vars/environment.ini
echo "Installing Quay Registry...."
pushd ~/mirror-registry
/usr/bin/sudo /home/admin/mirror-registry/mirror-registry install \
--quayHostname ${QUAY_HOSTNAME} --quayRoot ${QUAY_ROOT} \
--pgStorage ${QUAY_PG_STORAGE} --quayStorage ${QUAY_STORAGE} \
--initUser ${QUAY_USER} --initPassword ${QUAY_PASSWORD} \
--sslCert ${QUAY_SSL_CERT} --sslKey ${QUAY_SSL_KEY} --ssh-key ${SSH_KEY}
popd
echo "Updating Pull Secret with registry credentials..."
/usr/bin/podman login -u ${QUAY_USER} -p ${QUAY_PASSWORD} ${QUAY_HOSTNAME}:8443 --authfile ${LOCAL_SECRET_JSON}
echo "Removing credentials for Red Hat Insight Monitoring from Pull Secret"
cat ${LOCAL_SECRET_JSON} | jq -c 'del(.auths."cloud.openshift.com")' > ${LOCAL_SECRET_JSON}


