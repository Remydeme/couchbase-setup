# Couchbase JSON configurator

A shell utility for UNIX systems to quickly configure a couchbase docker instance
from a JSON file.

> This tool is mainly intended for local development. It allows to quickly setup
> multiple instances of Couchbase running on different ports within the same local
> machine.

## Prerequisites

You need a UNIX machine, with [Docker](https://www.docker.com/products/docker-desktop) installed.

Once you have Docker running, download and execute the installer.

```cgo
curl https://raw.githubusercontent.com/a-novel/couchbase-setup/master/install.sh -L -O && \
sh install.sh && \
rm install.sh
```

## How to use

```cgo
$ couchbase-jc --config-file="/path/to/config.json"
```

## Config file

### .name

The name will be used for your docker container. It has to be unique since every
container with the same name will be removed on setup.

### .config

For more detail on some flags, please visit [couchbase-cli documentation](https://docs.couchbase.com/server/current/cli/cbcli/couchbase-cli-cluster-init.html).

| Key | Type | Default | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| password | string | - | true | Username to connect to web UI (and other Couchbase Services). |
| username | string | - | true | Password to connect to web UI (and other Couchbase Services). |
| port | number | 8091 | - | Connection port. You can then connect via `localhost:Port`. |
| ttl | number | 15, > 5 | - | Their is a lag between the moment when the Docker image gets created and the moment we can actually operate on it with couchbase-cli. Thus, the script has to wait for the web UI to be available to start feeding the cluster.<br/>Ttl determines the maximum time to wait for the web UI before throwing a timeout error. This value is in seconds, and should be at least 5s. |
| indexStorageSettings | "default" or "memopt" | "default" | - | Equivalent of `couchbase-cli cluster-init --index-storage-setting value`. |

### .resources

For more detail on some flags, please visit [couchbase-cli documentation](https://docs.couchbase.com/server/current/cli/cbcli/couchbase-cli-cluster-init.html).

| Key | Type | Default | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| ramSize | number | 256 | - | Amount of RAM to allocate for the data storage. Must be greater than or equal to 100Mb. |
| indexRamSize | number | - | - | Amount of RAM to allocate for the data indexing. Must be greater than or equal to 100Mb. Set to 0 to disable index service. |
| ftsRamSize | number | - | - | Amount of RAM to allocate for the full text search index. Must be greater than or equal to 100Mb. Set to 0 to disable fts service. |
| eventRamSize | number | - | - | Amount of RAM to allocate for the data eventing. Must be greater than or equal to 100Mb. Set to 0 to disable eventing service. |
| analyticsRamSize | number | - | - | Amount of RAM to allocate for the analytics. Must be greater than or equal to 100Mb. Set to 0 to disable analytics service. |
| buckets | object | - | - | See below section. |

#### .resources.buckets

An optional list of buckets to setup within the cluster.

This key is an object (pair of key-value). Each sub-key is a bucket name, and has to
be of type objects for bucket parameters.

```json
{
  "resources": {
    "bucket1": {...opts},
    "bucket2": {...opts},
    ...
  }
}
```

Below is a list of every available key for options.
For more detail on some flags, please visit [couchbase-cli documentation](https://docs.couchbase.com/server/current/cli/cbcli/couchbase-cli-bucket-create.html).

| Key | Type | Default | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| size | number | - | true | Define the bucket size in percent of the total available size (as defined in .resources.ramSize).<br/> Be careful your bucket MUST NOT have a size under 100Mb. So if, for example, you stick with the default 256Mb, and you define a bucket with 10% = 26Mb, bucket will not be created. |
| type | string | couchbase | - | Equivalent of `couchbase-cli bucket-create --bucket-type value`. |
| flush | 1 or 0 | 0 | - | Equivalent of `couchbase-cli bucket-create --enable-flush value`. |
| conflictResolution | string | sequence | - | Equivalent of `couchbase-cli bucket-create --conflict-resolution value`. |
| databaseFragmentationThresholdPercentage | number | 100 | - | Equivalent of `couchbase-cli bucket-create --database-fragmentation-threshold-percentage value`. |
| databaseFragmentationThresholdSize | number | 256 | - | Equivalent of `couchbase-cli bucket-create --database-fragmentation-threshold-size value`. |
| viewFragmentationThresholdPercentage | number | 100 | - | Equivalent of `couchbase-cli bucket-create --view-fragmentation-threshold-percentage value`. |
| viewFragmentationThresholdSize | number | 256 | - | Equivalent of `couchbase-cli bucket-create --view-fragmentation-threshold-size value`. |
| storageBackend | string | couchstore | - | Equivalent of `couchbase-cli bucket-create --storage-backend value`. |
| indexReplica | number | 0 | - | Equivalent of `couchbase-cli bucket-create --enable-index-replica value`. |
| replica | number | 0 | - | Equivalent of `couchbase-cli bucket-create --bucket-replica value`. |
| priority | "low" or "high" | "low" | - | Equivalent of `couchbase-cli bucket-create --bucket-priority value`. |
| evictionPolicy | string | "valueOnly" or "noEviction" | - | Equivalent of `couchbase-cli bucket-create --bucket-eviction-policy value`. |
| maxTtl | number | - | - | Equivalent of `couchbase-cli bucket-create --max-ttl value`. |
| compressionMode | string | - | - | Equivalent of `couchbase-cli bucket-create --compression-mode value`. |

## Config example

```json
{
  "name": "my-database",
  "config": {
    "username": "Administrator",
    "password": "password"
  },
  "resources": {
    "ramSize": 1024,
    "ftsRamSize": 1024,
    "eventRamSize": 512,
    "indexRamSize": 1024,
    "buckets": {
      "users": {
        "size": 33
      },
      "posts": {
        "size": 33
      },
      "posts_tags": {
        "size": 10
      }
    }
  }
}
```

## Copyright

2020, A-Novel [MIT Licence](https://github.com/a-novel/couchbase-setup/blob/master/LICENSE).