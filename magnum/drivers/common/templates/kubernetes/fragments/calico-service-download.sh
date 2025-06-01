step="calico-service"
printf "Starting to run ${step}\n"

set -e
# Source heat parameters to get CALICO_TAG, CONTAINER_INFRA_PREFIX, etc.
if [ -f /etc/sysconfig/heat-params ]; then
    . /etc/sysconfig/heat-params
else
    echo "Warning: /etc/sysconfig/heat-params not found. Using default CALICO_TAG if not set."
    CALICO_TAG=${CALICO_TAG:-v3.30.1} # Default if not set by heat-params
fi
set -x # Ensures commands are logged for debugging

if [ "$NETWORK_DRIVER" = "calico" ]; then
    # _prefix is derived from CONTAINER_INFRA_PREFIX (from heat-params) or defaults to quay.io/calico/
    # CALICO_TAG is also from heat-params (or defaulted above)
    _prefix=${CONTAINER_INFRA_PREFIX:-quay.io/calico/}

    CALICO_DEPLOY_DIR="/srv/magnum/kubernetes/manifests"
    CALICO_DEPLOY="${CALICO_DEPLOY_DIR}/calico-deploy.yaml"

    echo "Preparing Calico manifest directory: ${CALICO_DEPLOY_DIR}"
    mkdir -p "${CALICO_DEPLOY_DIR}"

    CALICO_MANIFEST_URL="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_TAG}/manifests/calico.yaml"
    echo "Downloading Calico manifest (version ${CALICO_TAG}) from ${CALICO_MANIFEST_URL} to ${CALICO_DEPLOY}..."

    # Using curl with options for robustness:
    # -f: Fail silently (no HTML output) on server errors.
    # -s: Silent or quiet mode. Don't show progress meter or error messages.
    # -S: Show error. If -s is used, -S will make curl show an error message if it fails.
    # -L: Follow redirects.
    # --retry 3: Retry up to 3 times.
    # --retry-delay 5: Wait 5 seconds between retries.
    # --connect-timeout 10: Max 10 seconds for connection.
    # --max-time 60: Max 60 seconds for the whole operation.
    curl -fsSL --retry 3 --retry-delay 5 --connect-timeout 10 --max-time 60 \
         "${CALICO_MANIFEST_URL}" \
         -o "${CALICO_DEPLOY}"
    CURL_EXIT_CODE=$?

    if [ ${CURL_EXIT_CODE} -ne 0 ]; then
        echo "Error: Failed to download Calico manifest from ${CALICO_MANIFEST_URL} (curl exit code: ${CURL_EXIT_CODE})."
        if [ -f "${CALICO_DEPLOY}" ]; then
            rm -f "${CALICO_DEPLOY}" # Clean up partially downloaded file
        fi
        exit 1
    fi

    # Verify that the downloaded file is not empty
    if [ ! -s "${CALICO_DEPLOY}" ]; then
        echo "Error: Downloaded Calico manifest is empty. Source: ${CALICO_MANIFEST_URL}"
        rm -f "${CALICO_DEPLOY}"
        exit 1
    fi
    echo "Calico manifest downloaded successfully."

    echo "Customizing image paths in ${CALICO_DEPLOY}..."
    # Escape _prefix for sed, as it might contain characters like '/' which are delimiters in sed.
    # Using '#' as sed delimiter to avoid issues if _prefix contains '/'.
    ESCAPED_PREFIX=$(echo "${_prefix}" | sed 's#[\#&/]#\\&#g')

    # The regex for version matching (v[0-9.]\+[A-Za-z0-9.-]*) should match tags like v3.20.0, v3.20.0-alpha.1, v3.20.0-rancher1.
    # It matches 'v' followed by digits/dots, then alphanumeric, dot, or hyphen characters.
    # This ensures that the full original tag from the upstream manifest is replaced.
    # Using a temp file for sed to avoid issues with in-place editing on some systems/versions of sed, then rename.
    TMP_SED_FILE="${CALICO_DEPLOY}.tmp"

    sed -e "s#image: docker\.io/calico/cni:v[0-9.]\+[A-Za-z0-9.-]*#image: ${ESCAPED_PREFIX}cni:${CALICO_TAG}#g" \
        -e "s#image: docker\.io/calico/node:v[0-9.]\+[A-Za-z0-9.-]*#image: ${ESCAPED_PREFIX}node:${CALICO_TAG}#g" \
        -e "s#image: docker\.io/calico/kube-controllers:v[0-9.]\+[A-Za-z0-9.-]*#image: ${ESCAPED_PREFIX}kube-controllers:${CALICO_TAG}#g" \
        -e "s#image: docker\.io/calico/typha:v[0-9.]\+[A-Za-z0-9.-]*#image: ${ESCAPED_PREFIX}typha:${CALICO_TAG}#g" \
        "${CALICO_DEPLOY}" > "${TMP_SED_FILE}"

    if [ $? -ne 0 ]; then
        echo "Error: sed command failed to customize image paths."
        rm -f "${TMP_SED_FILE}" # Clean up temp file
        exit 1
    fi
    mv "${TMP_SED_FILE}" "${CALICO_DEPLOY}"
    if [ $? -ne 0 ]; then
        echo "Error: mv command failed to replace original manifest with customized version."
        exit 1
    fi
    echo "Image paths customized in ${CALICO_DEPLOY}."

    # Wait for Kubernetes API to be healthy
    echo "Waiting for Kubernetes API server to be healthy..."
    API_RETRY_COUNT=0
    MAX_API_RETRIES=24 # Wait for up to 2 minutes (24 * 5 seconds)
    until kubectl get --raw='/healthz' &> /dev/null && [ "$(kubectl get --raw='/healthz' 2>/dev/null)" = "ok" ]
    do
        API_RETRY_COUNT=$((API_RETRY_COUNT+1))
        if [ ${API_RETRY_COUNT} -gt ${MAX_API_RETRIES} ]; then
            echo "Error: Kubernetes API server did not become healthy after ${MAX_API_RETRIES} retries."
            exit 1
        fi
        echo "Kubernetes API not yet healthy (attempt ${API_RETRY_COUNT}/${MAX_API_RETRIES}), retrying in 5 seconds..."
        sleep 5
    done
    echo "Kubernetes API is healthy."

    echo "Applying Calico manifest: ${CALICO_DEPLOY}"
    /usr/bin/kubectl apply -f "${CALICO_DEPLOY}" --namespace=kube-system
    if [ $? -ne 0 ]; then
        echo "Error: Failed to apply Calico manifest."
        # Consider dumping some logs or status from Calico pods if apply fails.
        # kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
        # kubectl logs -n kube-system -l k8s-app=calico-node --tail=50
        exit 1
    fi
    echo "Calico manifest applied successfully."
fi

printf "Finished running ${step}\n"
