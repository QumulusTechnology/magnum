step="enable-nfs-subdir-provisioner"
printf "Starting to run ${step}\n"

set +x
. /etc/sysconfig/heat-params
set -ex

CHART_NAME="nfs-subdir-external-provisioner"

ssh_cmd="ssh -F /srv/magnum/.ssh/config root@localhost"

nfs_subdir_external_provisioner_enabled=$(echo $NFS_SUBDIR_EXTERNAL_PROVISIONER_ENABLED | tr '[:upper:]' '[:lower:]')

if [ "${nfs_subdir_external_provisioner_enabled}" = "true" ] && [ -n "${NFS_SERVER}" ] && [ -n "${NFS_MOUNT_POINT}" ]; then

  mkdir -p /tmp/$CLUSTER_UUID

  $ssh_cmd mount -t nfs -o soft,timeo=5,retry=5 $NFS_SERVER:$NFS_MOUNT_POINT /tmp/$CLUSTER_UUID

  $ssh_cmd mkdir -p /tmp/$CLUSTER_UUID/$CLUSTER_UUID

  $ssh_cmd umount /tmp/$CLUSTER_UUID

  kubectl delete storageclass cinder

  echo "Writing ${CHART_NAME} config"

  HELM_CHART_DIR="/srv/magnum/kubernetes/helm/magnum"
  mkdir -p ${HELM_CHART_DIR}

  cat << EOF >> ${HELM_CHART_DIR}/requirements.yaml
- name: ${CHART_NAME}
  version: 4.0.18
  repository: https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
EOF

    cat << EOF >> ${HELM_CHART_DIR}/values.yaml
nfs-subdir-external-provisioner:
  nfs:
    server: $NFS_SERVER
    path: ${NFS_MOUNT_POINT}/${CLUSTER_UUID}
  storageClass:
    create: true
    defaultClass: true
    name: nfs
EOF
fi
