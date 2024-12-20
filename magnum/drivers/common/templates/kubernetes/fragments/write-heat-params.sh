echo "START: write-heat-params"

arch=$(uname -m)

case "$arch" in
    aarch64)
        ARCH=arm64
        ;;
    x86_64)
        ARCH=amd64
        ;;
    *)
        ARCH=$arch
        ;;
esac

HEAT_PARAMS=/etc/sysconfig/heat-params
[ -f ${HEAT_PARAMS} ] || {
    echo "Writing File: $HEAT_PARAMS"
    mkdir -p "$(dirname ${HEAT_PARAMS})"
    cat > ${HEAT_PARAMS} <<EOF
DOCKERHUB_REPO_PATH="$DOCKERHUB_REPO_PATH"
QUAY_REPO_PATH="$QUAY_REPO_PATH"
GCR_REPO_PATH="$GCR_REPO_PATH"
K8S_REPO_PATH="$K8S_REPO_PATH"
VAULT_SSH_ENABLED="$VAULT_SSH_ENABLED"
VAULT_URL="$VAULT_URL"
VAULT_MOUNT_POINT="$VAULT_MOUNT_POINT"
VAULT_ALLOWED_ROLES="$VAULT_ALLOWED_ROLES"
NFS_SUBDIR_EXTERNAL_PROVISIONER_ENABLED="$NFS_SUBDIR_EXTERNAL_PROVISIONER_ENABLED"
NFS_SERVER="$NFS_SERVER"
NFS_MOUNT_POINT="$NFS_MOUNT_POINT"
ARCH="$ARCH"
INSTANCE_NAME="$INSTANCE_NAME"
HEAPSTER_ENABLED="$HEAPSTER_ENABLED"
METRICS_SERVER_ENABLED="$METRICS_SERVER_ENABLED"
METRICS_SERVER_TAG="$METRICS_SERVER_TAG"
PROMETHEUS_MONITORING="$PROMETHEUS_MONITORING"
KUBE_ALLOW_PRIV="$KUBE_ALLOW_PRIV"
KUBE_MASTER_IP="$KUBE_MASTER_IP"
KUBE_API_PORT="$KUBE_API_PORT"
KUBE_NODE_PUBLIC_IP="$KUBE_NODE_PUBLIC_IP"
KUBE_NODE_IP="$KUBE_NODE_IP"
ETCD_SERVER_IP="$ETCD_SERVER_IP"
ENABLE_CINDER="$ENABLE_CINDER"
DOCKER_VOLUME="$DOCKER_VOLUME"
DOCKER_VOLUME_SIZE="$DOCKER_VOLUME_SIZE"
DOCKER_STORAGE_DRIVER="$DOCKER_STORAGE_DRIVER"
CGROUP_DRIVER="$CGROUP_DRIVER"
NETWORK_DRIVER="$NETWORK_DRIVER"
REGISTRY_ENABLED="$REGISTRY_ENABLED"
REGISTRY_PORT="$REGISTRY_PORT"
SWIFT_REGION="$SWIFT_REGION"
REGISTRY_CONTAINER="$REGISTRY_CONTAINER"
REGISTRY_INSECURE="$REGISTRY_INSECURE"
REGISTRY_CHUNKSIZE="$REGISTRY_CHUNKSIZE"
TLS_DISABLED="$TLS_DISABLED"
VERIFY_CA="$VERIFY_CA"
CLUSTER_UUID="$CLUSTER_UUID"
MAGNUM_URL="$MAGNUM_URL"
AUTH_URL="$AUTH_URL"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
VOLUME_DRIVER="$VOLUME_DRIVER"
REGION_NAME="$REGION_NAME"
HTTP_PROXY="$HTTP_PROXY"
HTTPS_PROXY="$HTTPS_PROXY"
NO_PROXY="$NO_PROXY"
WAIT_CURL="$WAIT_CURL"
HYPERKUBE_PREFIX="$HYPERKUBE_PREFIX"
KUBE_TAG="$KUBE_TAG"
FLANNEL_NETWORK_CIDR="$FLANNEL_NETWORK_CIDR"
PODS_NETWORK_CIDR="$PODS_NETWORK_CIDR"
KUBE_VERSION="$KUBE_VERSION"
TRUSTEE_USER_ID="$TRUSTEE_USER_ID"
TRUSTEE_USERNAME="$TRUSTEE_USERNAME"
TRUSTEE_PASSWORD="$TRUSTEE_PASSWORD"
TRUSTEE_DOMAIN_ID="$TRUSTEE_DOMAIN_ID"
TRUST_ID="$TRUST_ID"
CLOUD_PROVIDER_ENABLED="$CLOUD_PROVIDER_ENABLED"
INSECURE_REGISTRY_URL="$INSECURE_REGISTRY_URL"
CONTAINER_INFRA_PREFIX="$CONTAINER_INFRA_PREFIX"
DNS_SERVICE_IP="$DNS_SERVICE_IP"
DNS_CLUSTER_DOMAIN="$DNS_CLUSTER_DOMAIN"
KUBELET_OPTIONS="$KUBELET_OPTIONS"
KUBEPROXY_OPTIONS="$KUBEPROXY_OPTIONS"
OCTAVIA_ENABLED="$OCTAVIA_ENABLED"
OCTAVIA_PROVIDER="$OCTAVIA_PROVIDER"
OCTAVIA_LB_ALGORITHM=$OCTAVIA_LB_ALGORITHM
OCTAVIA_LB_HEALTHCHECK=$OCTAVIA_LB_HEALTHCHECK
HEAT_CONTAINER_AGENT_TAG="$HEAT_CONTAINER_AGENT_TAG"
AUTO_HEALING_ENABLED="$AUTO_HEALING_ENABLED"
AUTO_HEALING_CONTROLLER="$AUTO_HEALING_CONTROLLER"
NODEGROUP_ROLE="$NODEGROUP_ROLE"
NODEGROUP_NAME="$NODEGROUP_NAME"
USE_PODMAN="$USE_PODMAN"
CONTAINER_RUNTIME="$CONTAINER_RUNTIME"
CONTAINERD_VERSION="$CONTAINERD_VERSION"
CONTAINERD_TARBALL_URL="$CONTAINERD_TARBALL_URL"
CONTAINERD_TARBALL_SHA256="$CONTAINERD_TARBALL_SHA256"
EOF
}

chown root:root "${HEAT_PARAMS}"
chmod 600 "${HEAT_PARAMS}"

echo "END: write-heat-params"
