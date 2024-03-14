#!/bin/bash
echo "Creating SSL Certificate Configs"
pushd ansible
/usr/bin/ansible-playbook ~/scripts/ansible/ca-certs.yaml
popd

echo Creating CA Private Key
openssl genrsa -out ~/ca/keys/utility.ocp.lab.key.pem
echo Creating self-signed CA Cert
openssl	req -new -x509 -nodes -sha256 -days 3650 \
	-key ~/ca/keys/utility.ocp.lab.key.pem \
	-out ~/ca/certs/utility.ocp.lab.cert.pem \
	-subj "/C=GB/ST=England/L=London/O=OpenShift Labs/CN=utility.ocp.lab"
echo Adding cert to CA Trust Store
/usr/bin/sudo cp ~/ca/certs/utility.ocp.lab.cert.pem /usr/share/pki/ca-trust-source/anchors
/usr/bin/sudo /usr/bin/update-ca-trust

for server in "registry" "api"
do
	echo "Creating Private Key for ${server}"
	openssl genrsa -out ~/ca/keys/${server}.ocp.lab.key.pem 2048
	echo "Creating CSR for ${server}"
	openssl req -new -key ~/ca/keys/${server}.ocp.lab.key.pem \
	-out ~/ca/reqs/${server}.ocp.lab.csr.pem \
	-subj "/C=GB/ST=England/L=London/O=OpenShift Labs/CN=${server}.ocp.lab"
	echo "Signing Cert for ${server}"
	openssl x509 -req -in ~/ca/reqs/${server}.ocp.lab.csr.pem \
	-CA ~/ca/certs/utility.ocp.lab.cert.pem \
	-CAkey ~/ca/keys/utility.ocp.lab.key.pem \
	-CAcreateserial \
	-out ~/ca/certs/${server}.ocp.lab.cert.pem \
	-days 720 -sha256 \
	-extfile ~/ca/cnf/${server}.ocp.lab.cnf
done

