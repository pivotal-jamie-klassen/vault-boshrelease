#!/bin/bash

echo 'export VAULT_CACERT=/var/vcap/jobs/vault/config/ca.crt' >> /home/vcap/.bashrc
echo 'export PATH=/var/vcap/packages/vault:$PATH' >> /home/vcap/.bashrc
export VAULT_CACERT=/var/vcap/jobs/vault/config/ca.crt
export PATH=/var/vcap/packages/vault:$PATH

function unseal_keys {
  cat /home/vcap/init_results | sed -n 's/.*Unseal Key [0-9]*: \(.*\)$/\1/p' | head -n3
}

function root_token {
  cat /home/vcap/init_results | sed -n 's/^Initial Root Token: \(.*\)$/\1/p'
}

# TODO: write this to lastpass, not VM filesystem
vault init > /home/vcap/init_results
for key in $(unseal_keys); do vault unseal $key; done
vault auth $(root_token)
vault mount -path=concourse generic
vault auth-enable cert
echo 'path "concourse/*" { policy = "read" }' | vault policy-write concourse -
pushd /var/vcap/jobs/vault/config/ && vault write auth/cert/certs/concourse policies=concourse certificate=@concourse.crt && popd
