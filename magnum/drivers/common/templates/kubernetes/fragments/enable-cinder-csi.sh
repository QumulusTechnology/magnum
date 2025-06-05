step="enable-cinder-csi"
printf "Starting to run ${step}\n"

. /etc/sysconfig/heat-params

volume_driver=$(echo "${VOLUME_DRIVER}" | tr '[:upper:]' '[:lower:]')
cinder_csi_enabled=$(echo $CINDER_CSI_ENABLED | tr '[:upper:]' '[:lower:]')

if [ "${volume_driver}" = "cinder" ] && [ "${cinder_csi_enabled}" = "true" ]; then
    # Generate Cinder CSI manifest file
    CINDER_CSI_DEPLOY=/srv/magnum/kubernetes/manifests/cinder-csi.yaml
    echo "Writing File: $CINDER_CSI_DEPLOY"
    mkdir -p $(dirname ${CINDER_CSI_DEPLOY})
    cat << EOF > ${CINDER_CSI_DEPLOY}
# This YAML file contains RBAC API objects and CRDs,
# which are necessary to run csi controller plugin
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    api-approved.kubernetes.io: "https://github.com/kubernetes-csi/external-snapshotter/pull/814"
    controller-gen.kubebuilder.io/version: v0.12.0
  creationTimestamp: null
  name: volumegroupsnapshotclasses.groupsnapshot.storage.k8s.io
spec:
  group: groupsnapshot.storage.k8s.io
  names:
    kind: VolumeGroupSnapshotClass
    listKind: VolumeGroupSnapshotClassList
    plural: volumegroupsnapshotclasses
    shortNames:
    - vgsclass
    - vgsclasses
    singular: volumegroupsnapshotclass
  scope: Cluster
  versions:
  - additionalPrinterColumns:
    - jsonPath: .driver
      name: Driver
      type: string
    - description: Determines whether a VolumeGroupSnapshotContent created through
        the VolumeGroupSnapshotClass should be deleted when its bound VolumeGroupSnapshot
        is deleted.
      jsonPath: .deletionPolicy
      name: DeletionPolicy
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: VolumeGroupSnapshotClass specifies parameters that a underlying
          storage system uses when creating a volume group snapshot. A specific VolumeGroupSnapshotClass
          is used by specifying its name in a VolumeGroupSnapshot object. VolumeGroupSnapshotClasses
          are non-namespaced.
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          deletionPolicy:
            description: DeletionPolicy determines whether a VolumeGroupSnapshotContent
              created through the VolumeGroupSnapshotClass should be deleted when
              its bound VolumeGroupSnapshot is deleted. Supported values are "Retain"
              and "Delete". "Retain" means that the VolumeGroupSnapshotContent and
              its physical group snapshot on underlying storage system are kept. "Delete"
              means that the VolumeGroupSnapshotContent and its physical group snapshot
              on underlying storage system are deleted. Required.
            enum:
            - Delete
            - Retain
            type: string
          driver:
            description: Driver is the name of the storage driver expected to handle
              this VolumeGroupSnapshotClass. Required.
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          parameters:
            additionalProperties:
              type: string
            description: Parameters is a key-value map with storage driver specific
              parameters for creating group snapshots. These values are opaque to
              Kubernetes and are passed directly to the driver.
            type: object
        required:
        - deletionPolicy
        - driver
        type: object
    served: true
    storage: true
    subresources: {}

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    api-approved.kubernetes.io: "https://github.com/kubernetes-csi/external-snapshotter/pull/971"
    controller-gen.kubebuilder.io/version: v0.12.0
  creationTimestamp: null
  name: volumegroupsnapshotcontents.groupsnapshot.storage.k8s.io
spec:
  group: groupsnapshot.storage.k8s.io
  names:
    kind: VolumeGroupSnapshotContent
    listKind: VolumeGroupSnapshotContentList
    plural: volumegroupsnapshotcontents
    shortNames:
    - vgsc
    - vgscs
    singular: volumegroupsnapshotcontent
  scope: Cluster
  versions:
  - additionalPrinterColumns:
    - description: Indicates if all the individual snapshots in the group are ready
        to be used to restore a group of volumes.
      jsonPath: .status.readyToUse
      name: ReadyToUse
      type: boolean
    - description: Determines whether this VolumeGroupSnapshotContent and its physical
        group snapshot on the underlying storage system should be deleted when its
        bound VolumeGroupSnapshot is deleted.
      jsonPath: .spec.deletionPolicy
      name: DeletionPolicy
      type: string
    - description: Name of the CSI driver used to create the physical group snapshot
        on the underlying storage system.
      jsonPath: .spec.driver
      name: Driver
      type: string
    - description: Name of the VolumeGroupSnapshotClass from which this group snapshot
        was (or will be) created.
      jsonPath: .spec.volumeGroupSnapshotClassName
      name: VolumeGroupSnapshotClass
      type: string
    - description: Namespace of the VolumeGroupSnapshot object to which this VolumeGroupSnapshotContent
        object is bound.
      jsonPath: .spec.volumeGroupSnapshotRef.namespace
      name: VolumeGroupSnapshotNamespace
      type: string
    - description: Name of the VolumeGroupSnapshot object to which this VolumeGroupSnapshotContent
        object is bound.
      jsonPath: .spec.volumeGroupSnapshotRef.name
      name: VolumeGroupSnapshot
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: VolumeGroupSnapshotContent represents the actual "on-disk" group
          snapshot object in the underlying storage system
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: Spec defines properties of a VolumeGroupSnapshotContent created
              by the underlying storage system. Required.
            properties:
              deletionPolicy:
                description: DeletionPolicy determines whether this VolumeGroupSnapshotContent
                  and the physical group snapshot on the underlying storage system
                  should be deleted when the bound VolumeGroupSnapshot is deleted.
                  Supported values are "Retain" and "Delete". "Retain" means that
                  the VolumeGroupSnapshotContent and its physical group snapshot on
                  underlying storage system are kept. "Delete" means that the VolumeGroupSnapshotContent
                  and its physical group snapshot on underlying storage system are
                  deleted. For dynamically provisioned group snapshots, this field
                  will automatically be filled in by the CSI snapshotter sidecar with
                  the "DeletionPolicy" field defined in the corresponding VolumeGroupSnapshotClass.
                  For pre-existing snapshots, users MUST specify this field when creating
                  the VolumeGroupSnapshotContent object. Required.
                enum:
                - Delete
                - Retain
                type: string
              driver:
                description: Driver is the name of the CSI driver used to create the
                  physical group snapshot on the underlying storage system. This MUST
                  be the same as the name returned by the CSI GetPluginName() call
                  for that driver. Required.
                type: string
              source:
                description: Source specifies whether the snapshot is (or should be)
                  dynamically provisioned or already exists, and just requires a Kubernetes
                  object representation. This field is immutable after creation. Required.
                properties:
                  groupSnapshotHandles:
                    description: GroupSnapshotHandles specifies the CSI "group_snapshot_id"
                      of a pre-existing group snapshot and a list of CSI "snapshot_id"
                      of pre-existing snapshots on the underlying storage system for
                      which a Kubernetes object representation was (or should be)
                      created. This field is immutable.
                    properties:
                      volumeGroupSnapshotHandle:
                        description: VolumeGroupSnapshotHandle specifies the CSI "group_snapshot_id"
                          of a pre-existing group snapshot on the underlying storage
                          system for which a Kubernetes object representation was
                          (or should be) created. This field is immutable. Required.
                        type: string
                      volumeSnapshotHandles:
                        description: VolumeSnapshotHandles is a list of CSI "snapshot_id"
                          of pre-existing snapshots on the underlying storage system
                          for which Kubernetes objects representation were (or should
                          be) created. This field is immutable. Required.
                        items:
                          type: string
                        type: array
                    required:
                    - volumeGroupSnapshotHandle
                    - volumeSnapshotHandles
                    type: object
                  volumeHandles:
                    description: VolumeHandles is a list of volume handles on the
                      backend to be snapshotted together. It is specified for dynamic
                      provisioning of the VolumeGroupSnapshot. This field is immutable.
                    items:
                      type: string
                    type: array
                type: object
                oneOf:
                - required: ["volumeHandles"]
                - required: ["groupSnapshotHandles"]
              volumeGroupSnapshotClassName:
                description: VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass
                  from which this group snapshot was (or will be) created. Note that
                  after provisioning, the VolumeGroupSnapshotClass may be deleted
                  or recreated with different set of values, and as such, should not
                  be referenced post-snapshot creation. For dynamic provisioning,
                  this field must be set. This field may be unset for pre-provisioned
                  snapshots.
                type: string
              volumeGroupSnapshotRef:
                description: VolumeGroupSnapshotRef specifies the VolumeGroupSnapshot
                  object to which this VolumeGroupSnapshotContent object is bound.
                  VolumeGroupSnapshot.Spec.VolumeGroupSnapshotContentName field must
                  reference to this VolumeGroupSnapshotContent's name for the bidirectional
                  binding to be valid. For a pre-existing VolumeGroupSnapshotContent
                  object, name and namespace of the VolumeGroupSnapshot object MUST
                  be provided for binding to happen. This field is immutable after
                  creation. Required.
                properties:
                  apiVersion:
                    description: API version of the referent.
                    type: string
                  fieldPath:
                    description: 'If referring to a piece of an object instead of
                      an entire object, this string should contain a valid JSON/Go
                      field access statement, such as desiredState.manifest.containers[2].
                      For example, if the object reference is to a container within
                      a pod, this would take on a value like: "spec.containers{name}"
                      (where "name" refers to the name of the container that triggered
                      the event) or if no container name is specified "spec.containers[2]"
                      (container with index 2 in this pod). This syntax is chosen
                      only to have some well-defined way of referencing a part of
                      an object. TODO: this design is not final and this field is
                      subject to change in the future.'
                    type: string
                  kind:
                    description: 'Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                    type: string
                  name:
                    description: 'Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names'
                    type: string
                  namespace:
                    description: 'Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/'
                    type: string
                  resourceVersion:
                    description: 'Specific resourceVersion to which this reference
                      is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency'
                    type: string
                  uid:
                    description: 'UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids'
                    type: string
                type: object
                x-kubernetes-map-type: atomic
            required:
            - deletionPolicy
            - driver
            - source
            - volumeGroupSnapshotRef
            type: object
          status:
            description: status represents the current information of a group snapshot.
            properties:
              creationTime:
                description: CreationTime is the timestamp when the point-in-time
                  group snapshot is taken by the underlying storage system. If not
                  specified, it indicates the creation time is unknown. If not specified,
                  it means the readiness of a group snapshot is unknown. The format
                  of this field is a Unix nanoseconds time encoded as an int64. On
                  Unix, the command date +%s%N returns the current time in nanoseconds
                  since 1970-01-01 00:00:00 UTC.
                format: int64
                type: integer
              error:
                description: Error is the last observed error during group snapshot
                  creation, if any. Upon success after retry, this error field will
                  be cleared.
                properties:
                  message:
                    description: 'message is a string detailing the encountered error
                      during snapshot creation if specified. NOTE: message may be
                      logged, and it should not contain sensitive information.'
                    type: string
                  time:
                    description: time is the timestamp when the error was encountered.
                    format: date-time
                    type: string
                type: object
              readyToUse:
                description: ReadyToUse indicates if all the individual snapshots
                  in the group are ready to be used to restore a group of volumes.
                  ReadyToUse becomes true when ReadyToUse of all individual snapshots
                  become true.
                type: boolean
              volumeGroupSnapshotHandle:
                description: VolumeGroupSnapshotHandle is a unique id returned by
                  the CSI driver to identify the VolumeGroupSnapshot on the storage
                  system. If a storage system does not provide such an id, the CSI
                  driver can choose to return the VolumeGroupSnapshot name.
                type: string
              volumeSnapshotContentRefList:
                description: VolumeSnapshotContentRefList is the list of volume snapshot
                  content references for this group snapshot. The maximum number of
                  allowed snapshots in the group is 100.
                items:
                  description: "ObjectReference contains enough information to let
                    you inspect or modify the referred object. --- New uses of this
                    type are discouraged because of difficulty describing its usage
                    when embedded in APIs. 1. Ignored fields.  It includes many fields
                    which are not generally honored.  For instance, ResourceVersion
                    and FieldPath are both very rarely valid in actual usage. 2. Invalid
                    usage help.  It is impossible to add specific help for individual
                    usage.  In most embedded usages, there are particular restrictions
                    like, \"must refer only to types A and B\" or \"UID not honored\"
                    or \"name must be restricted\". Those cannot be well described
                    when embedded. 3. Inconsistent validation.  Because the usages
                    are different, the validation rules are different by usage, which
                    makes it hard for users to predict what will happen. 4. The fields
                    are both imprecise and overly precise.  Kind is not a precise
                    mapping to a URL. This can produce ambiguity during interpretation
                    and require a REST mapping.  In most cases, the dependency is
                    on the group,resource tuple and the version of the actual struct
                    is irrelevant. 5. We cannot easily change it.  Because this type
                    is embedded in many locations, updates to this type will affect
                    numerous schemas.  Don't make new APIs embed an underspecified
                    API type they do not control. \n Instead of using this type, create
                    a locally provided and used type that is well-focused on your
                    reference. For example, ServiceReferences for admission registration:
                    https://github.com/kubernetes/api/blob/release-1.17/admissionregistration/v1/types.go#L533
                    ."
                  properties:
                    apiVersion:
                      description: API version of the referent.
                      type: string
                    fieldPath:
                      description: 'If referring to a piece of an object instead of
                        an entire object, this string should contain a valid JSON/Go
                        field access statement, such as desiredState.manifest.containers[2].
                        For example, if the object reference is to a container within
                        a pod, this would take on a value like: "spec.containers{name}"
                        (where "name" refers to the name of the container that triggered
                        the event) or if no container name is specified "spec.containers[2]"
                        (container with index 2 in this pod). This syntax is chosen
                        only to have some well-defined way of referencing a part of
                        an object. TODO: this design is not final and this field is
                        subject to change in the future.'
                      type: string
                    kind:
                      description: 'Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                      type: string
                    name:
                      description: 'Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names'
                      type: string
                    namespace:
                      description: 'Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/'
                      type: string
                    resourceVersion:
                      description: 'Specific resourceVersion to which this reference
                        is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency'
                      type: string
                    uid:
                      description: 'UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids'
                      type: string
                  type: object
                  x-kubernetes-map-type: atomic
                type: array
            type: object
        required:
        - spec
        type: object
    served: true
    storage: true
    subresources:
      status: {}

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    api-approved.kubernetes.io: "https://github.com/kubernetes-csi/external-snapshotter/pull/995"
    controller-gen.kubebuilder.io/version: v0.12.0
  creationTimestamp: null
  name: volumegroupsnapshots.groupsnapshot.storage.k8s.io
spec:
  group: groupsnapshot.storage.k8s.io
  names:
    kind: VolumeGroupSnapshot
    listKind: VolumeGroupSnapshotList
    plural: volumegroupsnapshots
    shortNames:
    - vgs
    singular: volumegroupsnapshot
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: Indicates if all the individual snapshots in the group are ready
        to be used to restore a group of volumes.
      jsonPath: .status.readyToUse
      name: ReadyToUse
      type: boolean
    - description: The name of the VolumeGroupSnapshotClass requested by the VolumeGroupSnapshot.
      jsonPath: .spec.volumeGroupSnapshotClassName
      name: VolumeGroupSnapshotClass
      type: string
    - description: Name of the VolumeGroupSnapshotContent object to which the VolumeGroupSnapshot
        object intends to bind to. Please note that verification of binding actually
        requires checking both VolumeGroupSnapshot and VolumeGroupSnapshotContent
        to ensure both are pointing at each other. Binding MUST be verified prior
        to usage of this object.
      jsonPath: .status.boundVolumeGroupSnapshotContentName
      name: VolumeGroupSnapshotContent
      type: string
    - description: Timestamp when the point-in-time group snapshot was taken by the
        underlying storage system.
      jsonPath: .status.creationTime
      name: CreationTime
      type: date
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: VolumeGroupSnapshot is a user's request for creating either a
          point-in-time group snapshot or binding to a pre-existing group snapshot.
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: Spec defines the desired characteristics of a group snapshot
              requested by a user. Required.
            properties:
              source:
                description: Source specifies where a group snapshot will be created
                  from. This field is immutable after creation. Required.
                properties:
                  selector:
                    description: Selector is a label query over persistent volume
                      claims that are to be grouped together for snapshotting. This
                      labelSelector will be used to match the label added to a PVC.
                      If the label is added or removed to a volume after a group snapshot
                      is created, the existing group snapshots won't be modified.
                      Once a VolumeGroupSnapshotContent is created and the sidecar
                      starts to process it, the volume list will not change with retries.
                    properties:
                      matchExpressions:
                        description: matchExpressions is a list of label selector
                          requirements. The requirements are ANDed.
                        items:
                          description: A label selector requirement is a selector
                            that contains values, a key, and an operator that relates
                            the key and values.
                          properties:
                            key:
                              description: key is the label key that the selector
                                applies to.
                              type: string
                            operator:
                              description: operator represents a key's relationship
                                to a set of values. Valid operators are In, NotIn,
                                Exists and DoesNotExist.
                              type: string
                            values:
                              description: values is an array of string values. If
                                the operator is In or NotIn, the values array must
                                be non-empty. If the operator is Exists or DoesNotExist,
                                the values array must be empty. This array is replaced
                                during a strategic merge patch.
                              items:
                                type: string
                              type: array
                          required:
                          - key
                          - operator
                          type: object
                        type: array
                      matchLabels:
                        additionalProperties:
                          type: string
                        description: matchLabels is a map of {key,value} pairs. A
                          single {key,value} in the matchLabels map is equivalent
                          to an element of matchExpressions, whose key field is "key",
                          the operator is "In", and the values array contains only
                          "value". The requirements are ANDed.
                        type: object
                    type: object
                    x-kubernetes-map-type: atomic
                  volumeGroupSnapshotContentName:
                    description: VolumeGroupSnapshotContentName specifies the name
                      of a pre-existing VolumeGroupSnapshotContent object representing
                      an existing volume group snapshot. This field should be set
                      if the volume group snapshot already exists and only needs a
                      representation in Kubernetes. This field is immutable.
                    type: string
                type: object
              volumeGroupSnapshotClassName:
                description: VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass
                  requested by the VolumeGroupSnapshot. VolumeGroupSnapshotClassName
                  may be left nil to indicate that the default class will be used.
                  Empty string is not allowed for this field.
                type: string
            required:
            - source
            type: object
          status:
            description: Status represents the current information of a group snapshot.
              Consumers must verify binding between VolumeGroupSnapshot and VolumeGroupSnapshotContent
              objects is successful (by validating that both VolumeGroupSnapshot and
              VolumeGroupSnapshotContent point to each other) before using this object.
            properties:
              boundVolumeGroupSnapshotContentName:
                description: 'BoundVolumeGroupSnapshotContentName is the name of the
                  VolumeGroupSnapshotContent object to which this VolumeGroupSnapshot
                  object intends to bind to. If not specified, it indicates that the
                  VolumeGroupSnapshot object has not been successfully bound to a
                  VolumeGroupSnapshotContent object yet. NOTE: To avoid possible security
                  issues, consumers must verify binding between VolumeGroupSnapshot
                  and VolumeGroupSnapshotContent objects is successful (by validating
                  that both VolumeGroupSnapshot and VolumeGroupSnapshotContent point
                  at each other) before using this object.'
                type: string
              creationTime:
                description: CreationTime is the timestamp when the point-in-time
                  group snapshot is taken by the underlying storage system. If not
                  specified, it may indicate that the creation time of the group snapshot
                  is unknown. The format of this field is a Unix nanoseconds time
                  encoded as an int64. On Unix, the command date +%s%N returns the
                  current time in nanoseconds since 1970-01-01 00:00:00 UTC.
                format: date-time
                type: string
              error:
                description: Error is the last observed error during group snapshot
                  creation, if any. This field could be helpful to upper level controllers
                  (i.e., application controller) to decide whether they should continue
                  on waiting for the group snapshot to be created based on the type
                  of error reported. The snapshot controller will keep retrying when
                  an error occurs during the group snapshot creation. Upon success,
                  this error field will be cleared.
                properties:
                  message:
                    description: 'message is a string detailing the encountered error
                      during snapshot creation if specified. NOTE: message may be
                      logged, and it should not contain sensitive information.'
                    type: string
                  time:
                    description: time is the timestamp when the error was encountered.
                    format: date-time
                    type: string
                type: object
              readyToUse:
                description: ReadyToUse indicates if all the individual snapshots
                  in the group are ready to be used to restore a group of volumes.
                  ReadyToUse becomes true when ReadyToUse of all individual snapshots
                  become true. If not specified, it means the readiness of a group
                  snapshot is unknown.
                type: boolean
              volumeSnapshotRefList:
                description: VolumeSnapshotRefList is the list of volume snapshot
                  references for this group snapshot. The maximum number of allowed
                  snapshots in the group is 100.
                items:
                  description: "ObjectReference contains enough information to let
                    you inspect or modify the referred object. --- New uses of this
                    type are discouraged because of difficulty describing its usage
                    when embedded in APIs. 1. Ignored fields.  It includes many fields
                    which are not generally honored.  For instance, ResourceVersion
                    and FieldPath are both very rarely valid in actual usage. 2. Invalid
                    usage help.  It is impossible to add specific help for individual
                    usage.  In most embedded usages, there are particular restrictions
                    like, \"must refer only to types A and B\" or \"UID not honored\"
                    or \"name must be restricted\". Those cannot be well described
                    when embedded. 3. Inconsistent validation.  Because the usages
                    are different, the validation rules are different by usage, which
                    makes it hard for users to predict what will happen. 4. The fields
                    are both imprecise and overly precise.  Kind is not a precise
                    mapping to a URL. This can produce ambiguity during interpretation
                    and require a REST mapping.  In most cases, the dependency is
                    on the group,resource tuple and the version of the actual struct
                    is irrelevant. 5. We cannot easily change it.  Because this type
                    is embedded in many locations, updates to this type will affect
                    numerous schemas.  Don't make new APIs embed an underspecified
                    API type they do not control. \n Instead of using this type, create
                    a locally provided and used type that is well-focused on your
                    reference. For example, ServiceReferences for admission registration:
                    https://github.com/kubernetes/api/blob/release-1.17/admissionregistration/v1/types.go#L533
                    ."
                  properties:
                    apiVersion:
                      description: API version of the referent.
                      type: string
                    fieldPath:
                      description: 'If referring to a piece of an object instead of
                        an entire object, this string should contain a valid JSON/Go
                        field access statement, such as desiredState.manifest.containers[2].
                        For example, if the object reference is to a container within
                        a pod, this would take on a value like: "spec.containers{name}"
                        (where "name" refers to the name of the container that triggered
                        the event) or if no container name is specified "spec.containers[2]"
                        (container with index 2 in this pod). This syntax is chosen
                        only to have some well-defined way of referencing a part of
                        an object. TODO: this design is not final and this field is
                        subject to change in the future.'
                      type: string
                    kind:
                      description: 'Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                      type: string
                    name:
                      description: 'Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names'
                      type: string
                    namespace:
                      description: 'Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/'
                      type: string
                    resourceVersion:
                      description: 'Specific resourceVersion to which this reference
                        is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency'
                      type: string
                    uid:
                      description: 'UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids'
                      type: string
                  type: object
                  x-kubernetes-map-type: atomic
                type: array
            type: object
        required:
        - spec
        type: object
    served: true
    storage: true
    subresources:
      status: {}

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    api-approved.kubernetes.io: "https://github.com/kubernetes-csi/external-snapshotter/pull/814"
    controller-gen.kubebuilder.io/version: v0.12.0
  creationTimestamp: null
  name: volumesnapshotclasses.snapshot.storage.k8s.io
spec:
  group: snapshot.storage.k8s.io
  names:
    kind: VolumeSnapshotClass
    listKind: VolumeSnapshotClassList
    plural: volumesnapshotclasses
    shortNames:
    - vsclass
    - vsclasses
    singular: volumesnapshotclass
  scope: Cluster
  versions:
  - additionalPrinterColumns:
    - jsonPath: .driver
      name: Driver
      type: string
    - description: Determines whether a VolumeSnapshotContent created through the
        VolumeSnapshotClass should be deleted when its bound VolumeSnapshot is deleted.
      jsonPath: .deletionPolicy
      name: DeletionPolicy
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1
    schema:
      openAPIV3Schema:
        description: VolumeSnapshotClass specifies parameters that a underlying storage
          system uses when creating a volume snapshot. A specific VolumeSnapshotClass
          is used by specifying its name in a VolumeSnapshot object. VolumeSnapshotClasses
          are non-namespaced
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          deletionPolicy:
            description: deletionPolicy determines whether a VolumeSnapshotContent
              created through the VolumeSnapshotClass should be deleted when its bound
              VolumeSnapshot is deleted. Supported values are "Retain" and "Delete".
              "Retain" means that the VolumeSnapshotContent and its physical snapshot
              on underlying storage system are kept. "Delete" means that the VolumeSnapshotContent
              and its physical snapshot on underlying storage system are deleted.
              Required.
            enum:
            - Delete
            - Retain
            type: string
          driver:
            description: driver is the name of the storage driver that handles this
              VolumeSnapshotClass. Required.
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          parameters:
            additionalProperties:
              type: string
            description: parameters is a key-value map with storage driver specific
              parameters for creating snapshots. These values are opaque to Kubernetes.
            type: object
        required:
        - deletionPolicy
        - driver
        type: object
    served: true
    storage: true
    subresources: {}
  - additionalPrinterColumns:
    - jsonPath: .driver
      name: Driver
      type: string
    - description: Determines whether a VolumeSnapshotContent created through the VolumeSnapshotClass should be deleted when its bound VolumeSnapshot is deleted.
      jsonPath: .deletionPolicy
      name: DeletionPolicy
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1beta1
    # This indicates the v1beta1 version of the custom resource is deprecated.
    # API requests to this version receive a warning in the server response.
    deprecated: true
    # This overrides the default warning returned to clients making v1beta1 API requests.
    deprecationWarning: "snapshot.storage.k8s.io/v1beta1 VolumeSnapshotClass is deprecated; use snapshot.storage.k8s.io/v1 VolumeSnapshotClass"
    schema:
      openAPIV3Schema:
        description: VolumeSnapshotClass specifies parameters that a underlying storage system uses when creating a volume snapshot. A specific VolumeSnapshotClass is used by specifying its name in a VolumeSnapshot object. VolumeSnapshotClasses are non-namespaced
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          deletionPolicy:
            description: deletionPolicy determines whether a VolumeSnapshotContent created through the VolumeSnapshotClass should be deleted when its bound VolumeSnapshot is deleted. Supported values are "Retain" and "Delete". "Retain" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept. "Delete" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted. Required.
            enum:
            - Delete
            - Retain
            type: string
          driver:
            description: driver is the name of the storage driver that handles this VolumeSnapshotClass. Required.
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          parameters:
            additionalProperties:
              type: string
            description: parameters is a key-value map with storage driver specific parameters for creating snapshots. These values are opaque to Kubernetes.
            type: object
        required:
        - deletionPolicy
        - driver
        type: object
    served: false
    storage: false
    subresources: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    api-approved.kubernetes.io: "https://github.com/kubernetes-csi/external-snapshotter/pull/955"
    controller-gen.kubebuilder.io/version: v0.12.0
  creationTimestamp: null
  name: volumesnapshotcontents.snapshot.storage.k8s.io
spec:
  group: snapshot.storage.k8s.io
  names:
    kind: VolumeSnapshotContent
    listKind: VolumeSnapshotContentList
    plural: volumesnapshotcontents
    shortNames:
    - vsc
    - vscs
    singular: volumesnapshotcontent
  scope: Cluster
  versions:
  - additionalPrinterColumns:
    - description: Indicates if the snapshot is ready to be used to restore a volume.
      jsonPath: .status.readyToUse
      name: ReadyToUse
      type: boolean
    - description: Represents the complete size of the snapshot in bytes
      jsonPath: .status.restoreSize
      name: RestoreSize
      type: integer
    - description: Determines whether this VolumeSnapshotContent and its physical
        snapshot on the underlying storage system should be deleted when its bound
        VolumeSnapshot is deleted.
      jsonPath: .spec.deletionPolicy
      name: DeletionPolicy
      type: string
    - description: Name of the CSI driver used to create the physical snapshot on
        the underlying storage system.
      jsonPath: .spec.driver
      name: Driver
      type: string
    - description: Name of the VolumeSnapshotClass to which this snapshot belongs.
      jsonPath: .spec.volumeSnapshotClassName
      name: VolumeSnapshotClass
      type: string
    - description: Name of the VolumeSnapshot object to which this VolumeSnapshotContent
        object is bound.
      jsonPath: .spec.volumeSnapshotRef.name
      name: VolumeSnapshot
      type: string
    - description: Namespace of the VolumeSnapshot object to which this VolumeSnapshotContent object is bound.
      jsonPath: .spec.volumeSnapshotRef.namespace
      name: VolumeSnapshotNamespace
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1
    schema:
      openAPIV3Schema:
        description: VolumeSnapshotContent represents the actual "on-disk" snapshot
          object in the underlying storage system
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: spec defines properties of a VolumeSnapshotContent created
              by the underlying storage system. Required.
            properties:
              deletionPolicy:
                description: deletionPolicy determines whether this VolumeSnapshotContent
                  and its physical snapshot on the underlying storage system should
                  be deleted when its bound VolumeSnapshot is deleted. Supported values
                  are "Retain" and "Delete". "Retain" means that the VolumeSnapshotContent
                  and its physical snapshot on underlying storage system are kept.
                  "Delete" means that the VolumeSnapshotContent and its physical snapshot
                  on underlying storage system are deleted. For dynamically provisioned
                  snapshots, this field will automatically be filled in by the CSI
                  snapshotter sidecar with the "DeletionPolicy" field defined in the
                  corresponding VolumeSnapshotClass. For pre-existing snapshots, users
                  MUST specify this field when creating the VolumeSnapshotContent
                  object. Required.
                enum:
                - Delete
                - Retain
                type: string
              driver:
                description: driver is the name of the CSI driver used to create the
                  physical snapshot on the underlying storage system. This MUST be
                  the same as the name returned by the CSI GetPluginName() call for
                  that driver. Required.
                type: string
              source:
                description: source specifies whether the snapshot is (or should be)
                  dynamically provisioned or already exists, and just requires a Kubernetes
                  object representation. This field is immutable after creation. Required.
                properties:
                  snapshotHandle:
                    description: snapshotHandle specifies the CSI "snapshot_id" of
                      a pre-existing snapshot on the underlying storage system for
                      which a Kubernetes object representation was (or should be)
                      created. This field is immutable.
                    type: string
                  volumeHandle:
                    description: volumeHandle specifies the CSI "volume_id" of the
                      volume from which a snapshot should be dynamically taken from.
                      This field is immutable.
                    type: string
                type: object
                oneOf:
                - required: ["snapshotHandle"]
                - required: ["volumeHandle"]
              sourceVolumeMode:
                description: SourceVolumeMode is the mode of the volume whose snapshot
                  is taken. Can be either “Filesystem” or “Block”. If not specified,
                  it indicates the source volume's mode is unknown. This field is
                  immutable. This field is an alpha field.
                type: string
              volumeSnapshotClassName:
                description: name of the VolumeSnapshotClass from which this snapshot
                  was (or will be) created. Note that after provisioning, the VolumeSnapshotClass
                  may be deleted or recreated with different set of values, and as
                  such, should not be referenced post-snapshot creation.
                type: string
              volumeSnapshotRef:
                description: volumeSnapshotRef specifies the VolumeSnapshot object
                  to which this VolumeSnapshotContent object is bound. VolumeSnapshot.Spec.VolumeSnapshotContentName
                  field must reference to this VolumeSnapshotContent's name for the
                  bidirectional binding to be valid. For a pre-existing VolumeSnapshotContent
                  object, name and namespace of the VolumeSnapshot object MUST be
                  provided for binding to happen. This field is immutable after creation.
                  Required.
                properties:
                  apiVersion:
                    description: API version of the referent.
                    type: string
                  fieldPath:
                    description: 'If referring to a piece of an object instead of
                      an entire object, this string should contain a valid JSON/Go
                      field access statement, such as desiredState.manifest.containers[2].
                      For example, if the object reference is to a container within
                      a pod, this would take on a value like: "spec.containers{name}"
                      (where "name" refers to the name of the container that triggered
                      the event) or if no container name is specified "spec.containers[2]"
                      (container with index 2 in this pod). This syntax is chosen
                      only to have some well-defined way of referencing a part of
                      an object. TODO: this design is not final and this field is
                      subject to change in the future.'
                    type: string
                  kind:
                    description: 'Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                    type: string
                  name:
                    description: 'Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names'
                    type: string
                  namespace:
                    description: 'Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/'
                    type: string
                  resourceVersion:
                    description: 'Specific resourceVersion to which this reference
                      is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency'
                    type: string
                  uid:
                    description: 'UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids'
                    type: string
                type: object
                x-kubernetes-map-type: atomic
            required:
            - deletionPolicy
            - driver
            - source
            - volumeSnapshotRef
            type: object
          status:
            description: status represents the current information of a snapshot.
            properties:
              creationTime:
                description: creationTime is the timestamp when the point-in-time
                  snapshot is taken by the underlying storage system. In dynamic snapshot
                  creation case, this field will be filled in by the CSI snapshotter
                  sidecar with the "creation_time" value returned from CSI "CreateSnapshot"
                  gRPC call. For a pre-existing snapshot, this field will be filled
                  with the "creation_time" value returned from the CSI "ListSnapshots"
                  gRPC call if the driver supports it. If not specified, it indicates
                  the creation time is unknown. The format of this field is a Unix
                  nanoseconds time encoded as an int64. On Unix, the command `date
                  +%s%N` returns the current time in nanoseconds since 1970-01-01
                  00:00:00 UTC.
                format: int64
                type: integer
              error:
                description: error is the last observed error during snapshot creation,
                  if any. Upon success after retry, this error field will be cleared.
                properties:
                  message:
                    description: 'message is a string detailing the encountered error
                      during snapshot creation if specified. NOTE: message may be
                      logged, and it should not contain sensitive information.'
                    type: string
                  time:
                    description: time is the timestamp when the error was encountered.
                    format: date-time
                    type: string
                type: object
              readyToUse:
                description: readyToUse indicates if a snapshot is ready to be used
                  to restore a volume. In dynamic snapshot creation case, this field
                  will be filled in by the CSI snapshotter sidecar with the "ready_to_use"
                  value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing
                  snapshot, this field will be filled with the "ready_to_use" value
                  returned from the CSI "ListSnapshots" gRPC call if the driver supports
                  it, otherwise, this field will be set to "True". If not specified,
                  it means the readiness of a snapshot is unknown.
                type: boolean
              restoreSize:
                description: restoreSize represents the complete size of the snapshot
                  in bytes. In dynamic snapshot creation case, this field will be
                  filled in by the CSI snapshotter sidecar with the "size_bytes" value
                  returned from CSI "CreateSnapshot" gRPC call. For a pre-existing
                  snapshot, this field will be filled with the "size_bytes" value
                  returned from the CSI "ListSnapshots" gRPC call if the driver supports
                  it. When restoring a volume from this snapshot, the size of the
                  volume MUST NOT be smaller than the restoreSize if it is specified,
                  otherwise the restoration will fail. If not specified, it indicates
                  that the size is unknown.
                format: int64
                minimum: 0
                type: integer
              snapshotHandle:
                description: snapshotHandle is the CSI "snapshot_id" of a snapshot
                  on the underlying storage system. If not specified, it indicates
                  that dynamic snapshot creation has either failed or it is still
                  in progress.
                type: string
              volumeGroupSnapshotHandle:
                description: VolumeGroupSnapshotHandle is the CSI "group_snapshot_id"
                  of a group snapshot on the underlying storage system.
                type: string
            type: object
        required:
        - spec
        type: object
    served: true
    storage: true
    subresources:
      status: {}
  - additionalPrinterColumns:
    - description: Indicates if the snapshot is ready to be used to restore a volume.
      jsonPath: .status.readyToUse
      name: ReadyToUse
      type: boolean
    - description: Represents the complete size of the snapshot in bytes
      jsonPath: .status.restoreSize
      name: RestoreSize
      type: integer
    - description: Determines whether this VolumeSnapshotContent and its physical snapshot on the underlying storage system should be deleted when its bound VolumeSnapshot is deleted.
      jsonPath: .spec.deletionPolicy
      name: DeletionPolicy
      type: string
    - description: Name of the CSI driver used to create the physical snapshot on the underlying storage system.
      jsonPath: .spec.driver
      name: Driver
      type: string
    - description: Name of the VolumeSnapshotClass to which this snapshot belongs.
      jsonPath: .spec.volumeSnapshotClassName
      name: VolumeSnapshotClass
      type: string
    - description: Name of the VolumeSnapshot object to which this VolumeSnapshotContent object is bound.
      jsonPath: .spec.volumeSnapshotRef.name
      name: VolumeSnapshot
      type: string
    - description: Namespace of the VolumeSnapshot object to which this VolumeSnapshotContent object is bound.
      jsonPath: .spec.volumeSnapshotRef.namespace
      name: VolumeSnapshotNamespace
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1beta1
    # This indicates the v1beta1 version of the custom resource is deprecated.
    # API requests to this version receive a warning in the server response.
    deprecated: true
    # This overrides the default warning returned to clients making v1beta1 API requests.
    deprecationWarning: "snapshot.storage.k8s.io/v1beta1 VolumeSnapshotContent is deprecated; use snapshot.storage.k8s.io/v1 VolumeSnapshotContent"
    schema:
      openAPIV3Schema:
        description: VolumeSnapshotContent represents the actual "on-disk" snapshot object in the underlying storage system
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          spec:
            description: spec defines properties of a VolumeSnapshotContent created by the underlying storage system. Required.
            properties:
              deletionPolicy:
                description: deletionPolicy determines whether this VolumeSnapshotContent and its physical snapshot on the underlying storage system should be deleted when its bound VolumeSnapshot is deleted. Supported values are "Retain" and "Delete". "Retain" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept. "Delete" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted. For dynamically provisioned snapshots, this field will automatically be filled in by the CSI snapshotter sidecar with the "DeletionPolicy" field defined in the corresponding VolumeSnapshotClass. For pre-existing snapshots, users MUST specify this field when creating the  VolumeSnapshotContent object. Required.
                enum:
                - Delete
                - Retain
                type: string
              driver:
                description: driver is the name of the CSI driver used to create the physical snapshot on the underlying storage system. This MUST be the same as the name returned by the CSI GetPluginName() call for that driver. Required.
                type: string
              source:
                description: source specifies whether the snapshot is (or should be) dynamically provisioned or already exists, and just requires a Kubernetes object representation. This field is immutable after creation. Required.
                properties:
                  snapshotHandle:
                    description: snapshotHandle specifies the CSI "snapshot_id" of a pre-existing snapshot on the underlying storage system for which a Kubernetes object representation was (or should be) created. This field is immutable.
                    type: string
                  volumeHandle:
                    description: volumeHandle specifies the CSI "volume_id" of the volume from which a snapshot should be dynamically taken from. This field is immutable.
                    type: string
                type: object
              volumeSnapshotClassName:
                description: name of the VolumeSnapshotClass from which this snapshot was (or will be) created. Note that after provisioning, the VolumeSnapshotClass may be deleted or recreated with different set of values, and as such, should not be referenced post-snapshot creation.
                type: string
              volumeSnapshotRef:
                description: volumeSnapshotRef specifies the VolumeSnapshot object to which this VolumeSnapshotContent object is bound. VolumeSnapshot.Spec.VolumeSnapshotContentName field must reference to this VolumeSnapshotContent's name for the bidirectional binding to be valid. For a pre-existing VolumeSnapshotContent object, name and namespace of the VolumeSnapshot object MUST be provided for binding to happen. This field is immutable after creation. Required.
                properties:
                  apiVersion:
                    description: API version of the referent.
                    type: string
                  fieldPath:
                    description: 'If referring to a piece of an object instead of an entire object, this string should contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2]. For example, if the object reference is to a container within a pod, this would take on a value like: "spec.containers{name}" (where "name" refers to the name of the container that triggered the event) or if no container name is specified "spec.containers[2]" (container with index 2 in this pod). This syntax is chosen only to have some well-defined way of referencing a part of an object. TODO: this design is not final and this field is subject to change in the future.'
                    type: string
                  kind:
                    description: 'Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                    type: string
                  name:
                    description: 'Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names'
                    type: string
                  namespace:
                    description: 'Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/'
                    type: string
                  resourceVersion:
                    description: 'Specific resourceVersion to which this reference is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency'
                    type: string
                  uid:
                    description: 'UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids'
                    type: string
                type: object
            required:
            - deletionPolicy
            - driver
            - source
            - volumeSnapshotRef
            type: object
          status:
            description: status represents the current information of a snapshot.
            properties:
              creationTime:
                description: creationTime is the timestamp when the point-in-time snapshot is taken by the underlying storage system. In dynamic snapshot creation case, this field will be filled in by the CSI snapshotter sidecar with the "creation_time" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "creation_time" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. If not specified, it indicates the creation time is unknown. The format of this field is a Unix nanoseconds time encoded as an int64. On Unix, the command `date +%s%N` returns the current time in nanoseconds since 1970-01-01 00:00:00 UTC.
                format: int64
                type: integer
              error:
                description: error is the last observed error during snapshot creation, if any. Upon success after retry, this error field will be cleared.
                properties:
                  message:
                    description: 'message is a string detailing the encountered error during snapshot creation if specified. NOTE: message may be logged, and it should not contain sensitive information.'
                    type: string
                  time:
                    description: time is the timestamp when the error was encountered.
                    format: date-time
                    type: string
                type: object
              readyToUse:
                description: readyToUse indicates if a snapshot is ready to be used to restore a volume. In dynamic snapshot creation case, this field will be filled in by the CSI snapshotter sidecar with the "ready_to_use" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "ready_to_use" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it, otherwise, this field will be set to "True". If not specified, it means the readiness of a snapshot is unknown.
                type: boolean
              restoreSize:
                description: restoreSize represents the complete size of the snapshot in bytes. In dynamic snapshot creation case, this field will be filled in by the CSI snapshotter sidecar with the "size_bytes" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "size_bytes" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. When restoring a volume from this snapshot, the size of the volume MUST NOT be smaller than the restoreSize if it is specified, otherwise the restoration will fail. If not specified, it indicates that the size is unknown.
                format: int64
                minimum: 0
                type: integer
              snapshotHandle:
                description: snapshotHandle is the CSI "snapshot_id" of a snapshot on the underlying storage system. If not specified, it indicates that dynamic snapshot creation has either failed or it is still in progress.
                type: string
            type: object
        required:
        - spec
        type: object
    served: false
    storage: false
    subresources:
      status: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    api-approved.kubernetes.io: "https://github.com/kubernetes-csi/external-snapshotter/pull/814"
    controller-gen.kubebuilder.io/version: v0.12.0
  creationTimestamp: null
  name: volumesnapshots.snapshot.storage.k8s.io
spec:
  group: snapshot.storage.k8s.io
  names:
    kind: VolumeSnapshot
    listKind: VolumeSnapshotList
    plural: volumesnapshots
    shortNames:
    - vs
    singular: volumesnapshot
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: Indicates if the snapshot is ready to be used to restore a volume.
      jsonPath: .status.readyToUse
      name: ReadyToUse
      type: boolean
    - description: If a new snapshot needs to be created, this contains the name of
        the source PVC from which this snapshot was (or will be) created.
      jsonPath: .spec.source.persistentVolumeClaimName
      name: SourcePVC
      type: string
    - description: If a snapshot already exists, this contains the name of the existing
        VolumeSnapshotContent object representing the existing snapshot.
      jsonPath: .spec.source.volumeSnapshotContentName
      name: SourceSnapshotContent
      type: string
    - description: Represents the minimum size of volume required to rehydrate from
        this snapshot.
      jsonPath: .status.restoreSize
      name: RestoreSize
      type: string
    - description: The name of the VolumeSnapshotClass requested by the VolumeSnapshot.
      jsonPath: .spec.volumeSnapshotClassName
      name: SnapshotClass
      type: string
    - description: Name of the VolumeSnapshotContent object to which the VolumeSnapshot
        object intends to bind to. Please note that verification of binding actually
        requires checking both VolumeSnapshot and VolumeSnapshotContent to ensure
        both are pointing at each other. Binding MUST be verified prior to usage of
        this object.
      jsonPath: .status.boundVolumeSnapshotContentName
      name: SnapshotContent
      type: string
    - description: Timestamp when the point-in-time snapshot was taken by the underlying
        storage system.
      jsonPath: .status.creationTime
      name: CreationTime
      type: date
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1
    schema:
      openAPIV3Schema:
        description: VolumeSnapshot is a user's request for either creating a point-in-time
          snapshot of a persistent volume, or binding to a pre-existing snapshot.
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: 'spec defines the desired characteristics of a snapshot requested
              by a user. More info: https://kubernetes.io/docs/concepts/storage/volume-snapshots#volumesnapshots
              Required.'
            properties:
              source:
                description: source specifies where a snapshot will be created from.
                  This field is immutable after creation. Required.
                properties:
                  persistentVolumeClaimName:
                    description: persistentVolumeClaimName specifies the name of the
                      PersistentVolumeClaim object representing the volume from which
                      a snapshot should be created. This PVC is assumed to be in the
                      same namespace as the VolumeSnapshot object. This field should
                      be set if the snapshot does not exists, and needs to be created.
                      This field is immutable.
                    type: string
                  volumeSnapshotContentName:
                    description: volumeSnapshotContentName specifies the name of a
                      pre-existing VolumeSnapshotContent object representing an existing
                      volume snapshot. This field should be set if the snapshot already
                      exists and only needs a representation in Kubernetes. This field
                      is immutable.
                    type: string
                type: object
                oneOf:
                - required: ["persistentVolumeClaimName"]
                - required: ["volumeSnapshotContentName"]
              volumeSnapshotClassName:
                description: 'VolumeSnapshotClassName is the name of the VolumeSnapshotClass
                  requested by the VolumeSnapshot. VolumeSnapshotClassName may be
                  left nil to indicate that the default SnapshotClass should be used.
                  A given cluster may have multiple default Volume SnapshotClasses:
                  one default per CSI Driver. If a VolumeSnapshot does not specify
                  a SnapshotClass, VolumeSnapshotSource will be checked to figure
                  out what the associated CSI Driver is, and the default VolumeSnapshotClass
                  associated with that CSI Driver will be used. If more than one VolumeSnapshotClass
                  exist for a given CSI Driver and more than one have been marked
                  as default, CreateSnapshot will fail and generate an event. Empty
                  string is not allowed for this field.'
                type: string
            required:
            - source
            type: object
          status:
            description: status represents the current information of a snapshot.
              Consumers must verify binding between VolumeSnapshot and VolumeSnapshotContent
              objects is successful (by validating that both VolumeSnapshot and VolumeSnapshotContent
              point at each other) before using this object.
            properties:
              boundVolumeSnapshotContentName:
                description: 'boundVolumeSnapshotContentName is the name of the VolumeSnapshotContent
                  object to which this VolumeSnapshot object intends to bind to. If
                  not specified, it indicates that the VolumeSnapshot object has not
                  been successfully bound to a VolumeSnapshotContent object yet. NOTE:
                  To avoid possible security issues, consumers must verify binding
                  between VolumeSnapshot and VolumeSnapshotContent objects is successful
                  (by validating that both VolumeSnapshot and VolumeSnapshotContent
                  point at each other) before using this object.'
                type: string
              creationTime:
                description: creationTime is the timestamp when the point-in-time
                  snapshot is taken by the underlying storage system. In dynamic snapshot
                  creation case, this field will be filled in by the snapshot controller
                  with the "creation_time" value returned from CSI "CreateSnapshot"
                  gRPC call. For a pre-existing snapshot, this field will be filled
                  with the "creation_time" value returned from the CSI "ListSnapshots"
                  gRPC call if the driver supports it. If not specified, it may indicate
                  that the creation time of the snapshot is unknown.
                format: date-time
                type: string
              error:
                description: error is the last observed error during snapshot creation,
                  if any. This field could be helpful to upper level controllers(i.e.,
                  application controller) to decide whether they should continue on
                  waiting for the snapshot to be created based on the type of error
                  reported. The snapshot controller will keep retrying when an error
                  occurs during the snapshot creation. Upon success, this error field
                  will be cleared.
                properties:
                  message:
                    description: 'message is a string detailing the encountered error
                      during snapshot creation if specified. NOTE: message may be
                      logged, and it should not contain sensitive information.'
                    type: string
                  time:
                    description: time is the timestamp when the error was encountered.
                    format: date-time
                    type: string
                type: object
              readyToUse:
                description: readyToUse indicates if the snapshot is ready to be used
                  to restore a volume. In dynamic snapshot creation case, this field
                  will be filled in by the snapshot controller with the "ready_to_use"
                  value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing
                  snapshot, this field will be filled with the "ready_to_use" value
                  returned from the CSI "ListSnapshots" gRPC call if the driver supports
                  it, otherwise, this field will be set to "True". If not specified,
                  it means the readiness of a snapshot is unknown.
                type: boolean
              restoreSize:
                type: string
                description: restoreSize represents the minimum size of volume required
                  to create a volume from this snapshot. In dynamic snapshot creation
                  case, this field will be filled in by the snapshot controller with
                  the "size_bytes" value returned from CSI "CreateSnapshot" gRPC call.
                  For a pre-existing snapshot, this field will be filled with the
                  "size_bytes" value returned from the CSI "ListSnapshots" gRPC call
                  if the driver supports it. When restoring a volume from this snapshot,
                  the size of the volume MUST NOT be smaller than the restoreSize
                  if it is specified, otherwise the restoration will fail. If not
                  specified, it indicates that the size is unknown.
                pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                x-kubernetes-int-or-string: true
              volumeGroupSnapshotName:
                description: VolumeGroupSnapshotName is the name of the VolumeGroupSnapshot
                  of which this VolumeSnapshot is a part of.
                type: string
            type: object
        required:
        - spec
        type: object
    served: true
    storage: true
    subresources:
      status: {}
  - additionalPrinterColumns:
    - description: Indicates if the snapshot is ready to be used to restore a volume.
      jsonPath: .status.readyToUse
      name: ReadyToUse
      type: boolean
    - description: If a new snapshot needs to be created, this contains the name of the source PVC from which this snapshot was (or will be) created.
      jsonPath: .spec.source.persistentVolumeClaimName
      name: SourcePVC
      type: string
    - description: If a snapshot already exists, this contains the name of the existing VolumeSnapshotContent object representing the existing snapshot.
      jsonPath: .spec.source.volumeSnapshotContentName
      name: SourceSnapshotContent
      type: string
    - description: Represents the minimum size of volume required to rehydrate from this snapshot.
      jsonPath: .status.restoreSize
      name: RestoreSize
      type: string
    - description: The name of the VolumeSnapshotClass requested by the VolumeSnapshot.
      jsonPath: .spec.volumeSnapshotClassName
      name: SnapshotClass
      type: string
    - description: Name of the VolumeSnapshotContent object to which the VolumeSnapshot object intends to bind to. Please note that verification of binding actually requires checking both VolumeSnapshot and VolumeSnapshotContent to ensure both are pointing at each other. Binding MUST be verified prior to usage of this object.
      jsonPath: .status.boundVolumeSnapshotContentName
      name: SnapshotContent
      type: string
    - description: Timestamp when the point-in-time snapshot was taken by the underlying storage system.
      jsonPath: .status.creationTime
      name: CreationTime
      type: date
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1beta1
    # This indicates the v1beta1 version of the custom resource is deprecated.
    # API requests to this version receive a warning in the server response.
    deprecated: true
    # This overrides the default warning returned to clients making v1beta1 API requests.
    deprecationWarning: "snapshot.storage.k8s.io/v1beta1 VolumeSnapshot is deprecated; use snapshot.storage.k8s.io/v1 VolumeSnapshot"
    schema:
      openAPIV3Schema:
        description: VolumeSnapshot is a user's request for either creating a point-in-time snapshot of a persistent volume, or binding to a pre-existing snapshot.
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          spec:
            description: 'spec defines the desired characteristics of a snapshot requested by a user. More info: https://kubernetes.io/docs/concepts/storage/volume-snapshots#volumesnapshots Required.'
            properties:
              source:
                description: source specifies where a snapshot will be created from. This field is immutable after creation. Required.
                properties:
                  persistentVolumeClaimName:
                    description: persistentVolumeClaimName specifies the name of the PersistentVolumeClaim object representing the volume from which a snapshot should be created. This PVC is assumed to be in the same namespace as the VolumeSnapshot object. This field should be set if the snapshot does not exists, and needs to be created. This field is immutable.
                    type: string
                  volumeSnapshotContentName:
                    description: volumeSnapshotContentName specifies the name of a pre-existing VolumeSnapshotContent object representing an existing volume snapshot. This field should be set if the snapshot already exists and only needs a representation in Kubernetes. This field is immutable.
                    type: string
                type: object
              volumeSnapshotClassName:
                description: 'VolumeSnapshotClassName is the name of the VolumeSnapshotClass requested by the VolumeSnapshot. VolumeSnapshotClassName may be left nil to indicate that the default SnapshotClass should be used. A given cluster may have multiple default Volume SnapshotClasses: one default per CSI Driver. If a VolumeSnapshot does not specify a SnapshotClass, VolumeSnapshotSource will be checked to figure out what the associated CSI Driver is, and the default VolumeSnapshotClass associated with that CSI Driver will be used. If more than one VolumeSnapshotClass exist for a given CSI Driver and more than one have been marked as default, CreateSnapshot will fail and generate an event. Empty string is not allowed for this field.'
                type: string
            required:
            - source
            type: object
          status:
            description: status represents the current information of a snapshot. Consumers must verify binding between VolumeSnapshot and VolumeSnapshotContent objects is successful (by validating that both VolumeSnapshot and VolumeSnapshotContent point at each other) before using this object.
            properties:
              boundVolumeSnapshotContentName:
                description: 'boundVolumeSnapshotContentName is the name of the VolumeSnapshotContent object to which this VolumeSnapshot object intends to bind to. If not specified, it indicates that the VolumeSnapshot object has not been successfully bound to a VolumeSnapshotContent object yet. NOTE: To avoid possible security issues, consumers must verify binding between VolumeSnapshot and VolumeSnapshotContent objects is successful (by validating that both VolumeSnapshot and VolumeSnapshotContent point at each other) before using this object.'
                type: string
              creationTime:
                description: creationTime is the timestamp when the point-in-time snapshot is taken by the underlying storage system. In dynamic snapshot creation case, this field will be filled in by the snapshot controller with the "creation_time" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "creation_time" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. If not specified, it may indicate that the creation time of the snapshot is unknown.
                format: date-time
                type: string
              error:
                description: error is the last observed error during snapshot creation, if any. This field could be helpful to upper level controllers(i.e., application controller) to decide whether they should continue on waiting for the snapshot to be created based on the type of error reported. The snapshot controller will keep retrying when an error occurs during the snapshot creation. Upon success, this error field will be cleared.
                properties:
                  message:
                    description: 'message is a string detailing the encountered error during snapshot creation if specified. NOTE: message may be logged, and it should not contain sensitive information.'
                    type: string
                  time:
                    description: time is the timestamp when the error was encountered.
                    format: date-time
                    type: string
                type: object
              readyToUse:
                description: readyToUse indicates if the snapshot is ready to be used to restore a volume. In dynamic snapshot creation case, this field will be filled in by the snapshot controller with the "ready_to_use" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "ready_to_use" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it, otherwise, this field will be set to "True". If not specified, it means the readiness of a snapshot is unknown.
                type: boolean
              restoreSize:
                type: string
                description: restoreSize represents the minimum size of volume required to create a volume from this snapshot. In dynamic snapshot creation case, this field will be filled in by the snapshot controller with the "size_bytes" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "size_bytes" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. When restoring a volume from this snapshot, the size of the volume MUST NOT be smaller than the restoreSize if it is specified, otherwise the restoration will fail. If not specified, it indicates that the size is unknown.
                pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                x-kubernetes-int-or-string: true
            type: object
        required:
        - spec
        type: object
    served: false
    storage: false
    subresources:
      status: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []

---
# This YAML file contains RBAC API objects,
# which are necessary to run csi controller plugin

apiVersion: v1
kind: ServiceAccount
metadata:
  name: csi-cinder-controller-sa
  namespace: kube-system

---
# external attacher
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-attacher-role
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["csinodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments/status"]
    verbs: ["patch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "watch", "list", "delete", "update", "create"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-attacher-binding
subjects:
  - kind: ServiceAccount
    name: csi-cinder-controller-sa
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: csi-attacher-role
  apiGroup: rbac.authorization.k8s.io

---
# external Provisioner
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-provisioner-role
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["csinodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshots"]
    verbs: ["get", "list"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotcontents"]
    verbs: ["get", "list"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "watch", "list", "delete", "update", "create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-provisioner-binding
subjects:
  - kind: ServiceAccount
    name: csi-cinder-controller-sa
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: csi-provisioner-role
  apiGroup: rbac.authorization.k8s.io

---
# external snapshotter
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-snapshotter-role
rules:
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
  # Secret permission is optional.
  # Enable it if your driver needs secret.
  # For example, csi.storage.k8s.io/snapshotter-secret-name is set in VolumeSnapshotClass.
  # See https://kubernetes-csi.github.io/docs/secrets-and-credentials.html for more details.
  #  - apiGroups: [""]
  #    resources: ["secrets"]
  #    verbs: ["get", "list"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotcontents"]
    verbs: ["create", "get", "list", "watch", "update", "delete", "patch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotcontents/status"]
    verbs: ["update", "patch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "watch", "list", "delete", "update", "create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-snapshotter-binding
subjects:
  - kind: ServiceAccount
    name: csi-cinder-controller-sa
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: csi-snapshotter-role
  apiGroup: rbac.authorization.k8s.io
---

# External Resizer
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-resizer-role
rules:
  # The following rule should be uncommented for plugins that require secrets
  # for provisioning.
  # - apiGroups: [""]
  #   resources: ["secrets"]
  #   verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims/status"]
    verbs: ["patch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "watch", "list", "delete", "update", "create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-resizer-binding
subjects:
  - kind: ServiceAccount
    name: csi-cinder-controller-sa
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: csi-resizer-role
  apiGroup: rbac.authorization.k8s.io

---
# This YAML file contains CSI Controller Plugin Sidecars
# external-attacher, external-provisioner, external-snapshotter
# external-resize, liveness-probe

kind: Deployment
apiVersion: apps/v1
metadata:
  name: csi-cinder-controllerplugin
  namespace: kube-system
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: csi-cinder-controllerplugin
  template:
    metadata:
      labels:
        app: csi-cinder-controllerplugin
    spec:
      serviceAccount: csi-cinder-controller-sa
      containers:
        - name: csi-attacher
          image: ${CONTAINER_INFRA_PREFIX:-k8s.gcr.io/sig-storage/}csi-attacher:${CSI_ATTACHER_TAG}
          args:
            - "--csi-address=\$(ADDRESS)"
            - "--timeout=3m"
            - "--leader-election=true"
            - "--default-fstype=ext4"
          env:
            - name: ADDRESS
              value: /var/lib/csi/sockets/pluginproxy/csi.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /var/lib/csi/sockets/pluginproxy/
        - name: csi-provisioner
          image: ${CONTAINER_INFRA_PREFIX:-k8s.gcr.io/sig-storage/}csi-provisioner:${CSI_PROVISIONER_TAG}
          args:
            - "--csi-address=\$(ADDRESS)"
            - "--timeout=3m"
            - "--default-fstype=ext4"
            - "--feature-gates=Topology=true"
            - "--extra-create-metadata"
            - "--leader-election=true"
          env:
            - name: ADDRESS
              value: /var/lib/csi/sockets/pluginproxy/csi.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /var/lib/csi/sockets/pluginproxy/
        - name: csi-snapshotter
          image: ${CONTAINER_INFRA_PREFIX:-k8s.gcr.io/sig-storage/}csi-snapshotter:${CSI_SNAPSHOTTER_TAG}
          args:
            - "--csi-address=\$(ADDRESS)"
            - "--timeout=3m"
            - "--extra-create-metadata"
            - "--leader-election=true"
          env:
            - name: ADDRESS
              value: /var/lib/csi/sockets/pluginproxy/csi.sock
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /var/lib/csi/sockets/pluginproxy/
              name: socket-dir
        - name: csi-resizer
          image: ${CONTAINER_INFRA_PREFIX:-k8s.gcr.io/sig-storage/}csi-resizer:${CSI_RESIZER_TAG}
          args:
            - "--csi-address=\$(ADDRESS)"
            - "--timeout=3m"
            - "--handle-volume-inuse-error=false"
            - "--leader-election=true"
          env:
            - name: ADDRESS
              value: /var/lib/csi/sockets/pluginproxy/csi.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /var/lib/csi/sockets/pluginproxy/
        - name: liveness-probe
          image: ${CONTAINER_INFRA_PREFIX:-k8s.gcr.io/sig-storage/}livenessprobe:${CSI_LIVENESS_PROBE_TAG}
          args:
            - "--csi-address=\$(ADDRESS)"
          env:
            - name: ADDRESS
              value: /var/lib/csi/sockets/pluginproxy/csi.sock
          volumeMounts:
            - mountPath: /var/lib/csi/sockets/pluginproxy/
              name: socket-dir
        - name: cinder-csi-plugin
          image: ${CONTAINER_INFRA_PREFIX:-registry.k8s.io/provider-os/}cinder-csi-plugin:${CINDER_CSI_PLUGIN_TAG}
          args:
            - /bin/cinder-csi-plugin
            - "--endpoint=\$(CSI_ENDPOINT)"
            - "--cloud-config=\$(CLOUD_CONFIG)"
            - "--cluster=\$(CLUSTER_NAME)"
            - "--v=1"
          env:
            - name: CSI_ENDPOINT
              value: unix://csi/csi.sock
            - name: CLOUD_CONFIG
              value: /etc/config/cloud-config
            - name: CLUSTER_NAME
              value: kubernetes
          imagePullPolicy: "IfNotPresent"
          ports:
            - containerPort: 9808
              name: healthz
              protocol: TCP
          # The probe
          livenessProbe:
            failureThreshold: 5
            httpGet:
              path: /healthz
              port: healthz
            initialDelaySeconds: 10
            timeoutSeconds: 10
            periodSeconds: 60
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
            - name: secret-cinderplugin
              mountPath: /etc/config
              readOnly: true
            - name: cacert
              mountPath: /etc/kubernetes
              readOnly: true
      volumes:
        - name: socket-dir
          emptyDir:
        - name: secret-cinderplugin
          secret:
            secretName: cinder-csi-cloud-config
        - name: cacert
          secret:
            defaultMode: 420
            secretName: ca-bundle
---
# This YAML defines all API objects to create RBAC roles for csi node plugin.

apiVersion: v1
kind: ServiceAccount
metadata:
  name: csi-cinder-node-sa
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-nodeplugin-role
rules:
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: csi-nodeplugin-binding
subjects:
  - kind: ServiceAccount
    name: csi-cinder-node-sa
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: csi-nodeplugin-role
  apiGroup: rbac.authorization.k8s.io

---
# This YAML file contains driver-registrar & csi driver nodeplugin API objects,
# which are necessary to run csi nodeplugin for cinder.

kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: csi-cinder-nodeplugin
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: csi-cinder-nodeplugin
  template:
    metadata:
      labels:
        app: csi-cinder-nodeplugin
    spec:
      tolerations:
        - operator: Exists
      serviceAccount: csi-cinder-node-sa
      hostNetwork: true
      containers:
        - name: node-driver-registrar
          image: ${CONTAINER_INFRA_PREFIX:-k8s.gcr.io/sig-storage/}csi-node-driver-registrar:${CSI_NODE_DRIVER_REGISTRAR_TAG}
          args:
            - "--csi-address=\$(ADDRESS)"
            - "--kubelet-registration-path=\$(DRIVER_REG_SOCK_PATH)"
          env:
            - name: ADDRESS
              value: /csi/csi.sock
            - name: DRIVER_REG_SOCK_PATH
              value: /var/lib/kubelet/plugins/cinder.csi.openstack.org/csi.sock
            - name: KUBE_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
            - name: registration-dir
              mountPath: /registration
        - name: liveness-probe
          image: ${CONTAINER_INFRA_PREFIX:-k8s.gcr.io/sig-storage/}livenessprobe:${CSI_LIVENESS_PROBE_TAG}
          args:
            - --csi-address=/csi/csi.sock
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
        - name: cinder-csi-plugin
          securityContext:
            privileged: true
            capabilities:
              add: ["SYS_ADMIN"]
            allowPrivilegeEscalation: true
          image: ${CONTAINER_INFRA_PREFIX:-registry.k8s.io/provider-os/}cinder-csi-plugin:${CINDER_CSI_PLUGIN_TAG}
          args:
            - /bin/cinder-csi-plugin
            - "--endpoint=\$(CSI_ENDPOINT)"
            - "--cloud-config=\$(CLOUD_CONFIG)"
            - "--v=1"
          env:
            - name: CSI_ENDPOINT
              value: unix://csi/csi.sock
            - name: CLOUD_CONFIG
              value: /etc/config/cloud-config
          imagePullPolicy: "IfNotPresent"
          ports:
            - containerPort: 9808
              name: healthz
              protocol: TCP
          # The probe
          livenessProbe:
            failureThreshold: 5
            httpGet:
              path: /healthz
              port: healthz
            initialDelaySeconds: 10
            timeoutSeconds: 3
            periodSeconds: 10
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
            - name: kubelet-dir
              mountPath: /var/lib/kubelet
              mountPropagation: "Bidirectional"
            - name: pods-probe-dir
              mountPath: /dev
              mountPropagation: "HostToContainer"
            - name: secret-cinderplugin
              mountPath: /etc/config
              readOnly: true
            - name: cacert
              mountPath: /etc/kubernetes
              readOnly: true
      volumes:
        - name: socket-dir
          hostPath:
            path: /var/lib/kubelet/plugins/cinder.csi.openstack.org
            type: DirectoryOrCreate
        - name: registration-dir
          hostPath:
            path: /var/lib/kubelet/plugins_registry/
            type: Directory
        - name: kubelet-dir
          hostPath:
            path: /var/lib/kubelet
            type: Directory
        - name: pods-probe-dir
          hostPath:
            path: /dev
            type: Directory
        - name: secret-cinderplugin
          secret:
            secretName: cinder-csi-cloud-config
        - name: cacert
          secret:
            defaultMode: 420
            secretName: ca-bundle

---
apiVersion: storage.k8s.io/v1
kind: CSIDriver
metadata:
  name: cinder.csi.openstack.org
spec:
  attachRequired: true
  podInfoOnMount: true
  volumeLifecycleModes:
  - Persistent
  - Ephemeral

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: cinder
allowVolumeExpansion: true
provisioner: kubernetes.io/cinder
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

    echo "Waiting for Kubernetes API..."
    until  [ "ok" = "$(kubectl get --raw='/healthz')" ]
    do
        sleep 5
    done

    cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: cinder-csi-cloud-config
  namespace: kube-system
type: Opaque
stringData:
  cloud-config: |-
    [Global]
    auth-url=$AUTH_URL
    user-id=$TRUSTEE_USER_ID
    password=$TRUSTEE_PASSWORD
    trust-id=$TRUST_ID
    region=$REGION_NAME
    ca-file=/etc/kubernetes/ca-bundle.crt
EOF

    kubectl apply -f ${CINDER_CSI_DEPLOY}
fi
printf "Finished running ${step}\n"
