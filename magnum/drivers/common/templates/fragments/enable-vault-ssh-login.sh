step="enable-vault-ssh-login"
printf "Starting to run ${step}\n"

. /etc/sysconfig/heat-params

ssh_cmd="ssh -F /srv/magnum/.ssh/config root@localhost"

vault_ssh_enabled=$(echo $VAULT_SSH_ENABLED | tr '[:upper:]' '[:lower:]')
vault_url=$(echo $VAULT_URL | tr '[:upper:]' '[:lower:]')
vault_mount_point="${VAULT_MOUNT_POINT}"
vault_allowed_roles="${VAULT_ALLOWED_ROLES}"

if [ "${vault_ssh_enabled}" = "true" ] && [ -n "${vault_url}" ] && [ -n "${vault_mount_point}" ]; then

mkdir -p /etc/vault-ssh-helper.d/

if [ ! -f /usr/local/bin/vault-ssh-helper ]; then
    curl -s -o /etc/vault-ssh-helper.d/vault-ssh-helper https://qumulusglobalprod.blob.core.windows.net/public-files/vault-ssh-helper
    chmod 0755 /etc/vault-ssh-helper.d/vault-ssh-helper
    chown root:root /etc/vault-ssh-helper.d/vault-ssh-helper
fi

if [ -z "${vault_allowed_roles}" ]; then
    vault_allowed_roles="*"
fi

cat << EOF > /etc/vault-ssh-helper.d/config.hcl
vault_addr = "${vault_url}"
tls_skip_verify = false
ssh_mount_point = "${vault_mount_point}"
allowed_roles = "${vault_allowed_roles}"
EOF

sed -i '/^\@include common-auth$/s/^/#/' /etc/pam.d/sshd
sed -i '/^auth       substack     password-auth$/s/^/#/' /etc/pam.d/sshd
grep -qxF 'auth requisite pam_exec.so expose_authtok log=/var/log/vault_ssh.log /etc/vault-ssh-helper.d/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl' /etc/pam.d/sshd || echo 'auth requisite pam_exec.so expose_authtok log=/var/log/vault_ssh.log /etc/vault-ssh-helper.d/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl' >> /etc/pam.d/sshd
grep -qxF "auth optional pam_unix.so not_set_pass use_first_pass nodelay" /etc/pam.d/sshd || echo "auth optional pam_unix.so not_set_pass use_first_pass nodelay" >> /etc/pam.d/sshd

change_line_sshd() {
    PARAMETER=$1
    VALUE=$2
    if grep -q $PARAMETER /etc/ssh/sshd_config; then
        sed -i "/.*$PARAMETER.*/d" /etc/ssh/sshd_config
    fi
    sed -i "1s/^/$PARAMETER $VALUE\n/" /etc/ssh/sshd_config
}

change_line_sshd ChallengeResponseAuthentication yes
change_line_sshd PasswordAuthentication no
change_line_sshd UsePAM yes
change_line_sshd MaxAuthTries 15
change_line_sshd PermitRootLogin yes

$ssh_cmd systemctl reload sshd

sleep 5



fi
