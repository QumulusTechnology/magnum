step="enable-vault-ssh-login"
printf "Starting to run ${step}\n"

. /etc/sysconfig/heat-params

vault_ssh_enabled=$(echo $VAULT_SSH_ENABLED | tr '[:upper:]' '[:lower:]')
vault_url=$(echo $VAULT_URL | tr '[:upper:]' '[:lower:]')


if [[ "${vault_ssh_enabled}" = "true" && -n "${vault_url}" ]]; then

if [ ! -f /usr/local/bin/vault-ssh-helper ]; then
    curl -s -o /usr/local/bin/vault-ssh-helper https://qumulusglobalprod.blob.core.windows.net/public-files/vault-ssh-helper
    chmod 0755 /usr/local/bin/vault-ssh-helper
    chown root:root /usr/local/bin/vault-ssh-helper
fi

PROJECT_ID=$(curl -s http://169.254.169.254/openstack/2018-08-27/meta_data.json | awk -F'"project_id": "' '{print $2}' | awk -F'"' '{print $1}')

mkdir -p /etc/vault-ssh-helper.d/

cat << EOF > /etc/vault-ssh-helper.d/config.hcl
vault_addr = "${vault_url}"
tls_skip_verify = false
ssh_mount_point = "openstack/ssh/${PROJECT_ID}"
allowed_roles = "openstack_account_ssh_access_${PROJECT_ID}"
EOF

sed -i '/^\@include common-auth$/s/^/#/' /etc/pam.d/sshd
sed -i '/^auth       substack     password-auth$/s/^/#/' /etc/pam.d/sshd
grep -qxF 'auth requisite pam_exec.so expose_authtok log=/var/log/vault_ssh.log /usr/local/bin/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl' /etc/pam.d/sshd || echo 'auth requisite pam_exec.so expose_authtok log=/var/log/vault_ssh.log /usr/local/bin/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl' >> /etc/pam.d/sshd

NOT_SET_PASS="use_first_pass "

grep -q "CentOS Stream release 9" /etc/redhat-release 2> /dev/null && NOT_SET_PASS=""

grep -qxF 'auth optional pam_unix.so use_first_pass nodelay' /etc/pam.d/sshd || echo 'auth optional pam_unix.so use_first_pass nodelay' >> /etc/pam.d/sshd
grep -qxF "auth optional pam_unix.so ${NOT_SET_PASS}use_first_pass nodelay" /etc/pam.d/sshd || echo "auth optional pam_unix.so ${NOT_SET_PASS}use_first_pass nodelay" >> /etc/pam.d/sshd

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

SSHD_PID=$(ps -ef | grep "/usr/sbin/sshd" | grep -v grep | awk '{print $2}')
/usr/bin/kill -HUP $SSHD_PID



fi
