#!/bin/sh

# Add couchbase-cli to path.
export PATH=$PATH:/Applications/Couchbase\ Server.app/Contents/Resources/couchbase-core/bin

# Constants
tag=$(git describe --tags)

# Variables.
ConfigFile=""

# ╭────────────────────────╮
# │ COUCHBASE SETUP vX.X.X │
# ╰────────────────────────╯
# Hi, I'm hardly working to setup Couchbase asap 😉 Please be patient, I'll inform you about every incoming steps UwU

printf "╭────────────────────────╮\n│\033[0;36m COUCHBASE SETUP %s\033[0m │\n╰────────────────────────╯\n" "$tag"
printf "I'm hardly working to setup Couchbase asap 😉 "
printf "Please be patient, I'll inform you about every incoming steps UwU\n\n"

CheckConfigurationFile() {
  printf "→ \033[0;33mLooking for configuration file...\033[0m"

  if [ -z "$ConfigFile" ]; then
    printf "\r\033[K😾 \033[0;31mUgu, you didn't provide any config file ! "
    printf "Please pass a path to your config.json file with "
    printf "\033[0m--config-file=\"path/to/my/configFile.json\"\033[0;31m flag.\033[0m\n"
    exit
  elif ! case "$ConfigFile" in *".json") true ;; *) false ;; esac then
    printf "\r\033[K😾 \033[0;31mSowwy, the config file must be a json file.\033[0m\n"
    exit
  elif ! [ -e "$ConfigFile" ]; then
    printf "\r\033[K😾 \033[0;31mOopsie, I couldn't find any file at \033[0m\`%s\`\033[0;31m.\033[0m\n" "$ConfigFile"
    exit
  fi
}

ReadConfigurationFile() {
  printf "\r\033[K→→ \033[0;33mReading configuration file...\033[0m"

  DBName=$(jq -re '.name // empty' <"$ConfigFile")
  Port=$(jq -re '.config.port // empty' <"$ConfigFile")
  Username=$(jq -re '.config.username // empty' <"$ConfigFile")
  Password=$(jq -re '.config.password // empty' <"$ConfigFile")
  IndexStorageSettings=$(jq -re '.config.indexStorageSettings // empty' <"$ConfigFile")
  Ttl=$(jq -re '.config.ttl // empty' <"$ConfigFile")
  RamSize=$(jq -re '.resources.ramSize // empty' <"$ConfigFile")
  FTSRamSize=$(jq -re '.resources.ftsRamSize // empty' <"$ConfigFile")
  EventRamSize=$(jq -re '.resources.eventRamSize // empty' <"$ConfigFile")
  IndexRamSize=$(jq -re '.resources.indexRamSize // empty' <"$ConfigFile")
  AnalyticsRamSize=$(jq -re '.resources.analyticsRamSize // empty' <"$ConfigFile")
  BucketsCount=$(jq -re '.resources.buckets // empty | length' <"$ConfigFile")

  Port=${Port:=8080}
  Ttl=${Ttl:=15}
  RamSize=${RamSize:=256}
  FTSRamSize=${FTSRamSize:=0}
  EventRamSize=${EventRamSize:=0}
  IndexRamSize=${IndexRamSize:=0}
  AnalyticsRamSize=${AnalyticsRamSize:=0}
  IndexStorageSettings=${IndexStorageSettings:="default"}
  BucketsCount=${BucketsCount:=0}

  Quota=$((RamSize + FTSRamSize + EventRamSize + IndexRamSize + AnalyticsRamSize + 1024))

  if [ "$DBName" = "null" ] || [ -z "$DBName" ]; then
    printf "\r\033[K😾 \033[0;31mPlease check your config file, it misses the required .name key.\033[0m\n"
    exit
  fi

  if [ "$Username" = "null" ] || [ -z "$Username" ]; then
    printf "\r\033[K😾 \033[0;31mPlease check your config file, it misses the required .config.username key.\033[0m\n"
    exit
  fi

  if [ "$Password" = "null" ] || [ -z "$Password" ]; then
    printf "\r\033[K😾 \033[0;31mPlease check your config file, it misses the required .config.password key.\033[0m\n"
    exit
  fi

  if [ $Ttl -lt 5 ]; then
    printf "\r\033[K😾 \033[0;31m.config.ttl has to be at least 5 (currently \033[0m%s\033[0;31m).\033[0m\n" "$Ttl"
    exit
  fi

  if [ $RamSize -gt 0 ] && [ $RamSize -lt 256 ]; then
    printf "\r\033[K😾 \033[0;31m.resources.ramSize has to be at least 256 (currently \033[0m%s\033[0;31m).\033[0m\n" "$RamSize"
    exit
  fi

  if [ $FTSRamSize -gt 0 ] && [ $FTSRamSize -lt 256 ]; then
    printf "\r\033[K😾 \033[0;31m.resources.ftsRamSize has to be at least 256 (currently \033[0m%s\033[0;31m).\033[0m\n" "$FTSRamSize"
    exit
  fi

  if [ $EventRamSize -gt 0 ] && [ $EventRamSize -lt 256 ]; then
    printf "\r\033[K😾 \033[0;31m.resources.eventRamSize has to be at least 256 (currently \033[0m%s\033[0;31m).\033[0m\n" "$EventRamSize"
    exit
  fi

  if [ $IndexRamSize -gt 0 ] && [ $IndexRamSize -lt 256 ]; then
    printf "\r\033[K😾 \033[0;31m.resources.indexRamSize has to be at least 256 (currently \033[0m%s\033[0;31m).\033[0m\n" "$IndexRamSize"
    exit
  fi

  if [ $AnalyticsRamSize -gt 0 ] && [ $AnalyticsRamSize -lt 256 ]; then
    printf "\r\033[K😾 \033[0;31m.resources.analyticsRamSize has to be at least 256 (currently \033[0m%s\033[0;31m).\033[0m\n" "$AnalyticsRamSize"
    exit
  fi

  printf "\r\033[K😸 \033[0;32mSuccessfully read config from \033[0m\`%s\`\033[0;32m.\033[0m\n\n" "$ConfigFile"
}

KillOldInstances() {
  printf "→ \033[0;33mKilling old docker instances of \033[0m%s\033[0;33m...\033[0m" "$DBName"
  docker kill "$DBName" >/dev/null 2>&1
  InstancesCount="$(docker ps -aq -f name="agora-database" | wc -l)"

  if [ "$InstancesCount" -ne 0 ]; then
    docker ps -qa -f name="${DBName}" | xargs docker stop >/dev/null 2>&1
    docker ps -qa -f name="${DBName}" | xargs docker rm >/dev/null 2>&1

    if [ "$InstancesCount" -eq 1 ]; then
      printf "\r\033[K😸 \033[0;32mSuccessfully removed \033[0m1 running instance\033[0;32m of "
      printf "\033[0m%s\033[0;32m.\033[0m\n" "$DBName"
    else
      printf "\r\033[K😸 \033[0;32mSuccessfully removed \033[0m%s running instances\033[0;32m of " "$InstancesCount"
      printf "\033[0m%s\033[0;32m.\033[0m\n" "$DBName"
    fi
  else
    printf "\r\033[K😼 \033[0;37mNo running instances of %s found.\033[0m\n" "$DBName"
  fi
}

SetupNewInstance() {
  printf "→ \033[0;33mSetting new docker with image \033[0m%s\033[0;33m...\033[0m" "$IMAGE_NAME"
  docker run -d --memory ${Quota}M --name "$DBName" \
    -p ${Port}-$((Port + 5)):8091-8096 \
    -p 11210-11211:11210-11211 \
    couchbase >/dev/null 2>&1

  ImageID=$(docker ps -aqf "name=^${DBName}$")
  printf "\r\033[K😸 \033[0;32mSuccessfully created docker image \033[0m%s\033[0;32m for \033[0m%s " "$ImageID" "$DBName"
  printf "\033[0;32mwith \033[0m%sMb\033[0;32m of RAM.\033[0m\n" "$Quota"
}

WaitForWebUI() {
  # Waiting for UI to be available, since upcoming operations cannot occur otherwise.
  printf "→ \033[0;33mWaiting for Web UI \033[0m"

  Elapsed=0
  until [ "$(curl -sL -w '%{http_code}' http://127.0.0.1:${Port}/ui/index.html -o /dev/null)" = "200" ] || [ $Elapsed -ge $Ttl ]; do
    printf '='
    Elapsed=$((Elapsed + 1))
    sleep 1
  done

  if [ $Elapsed -eq $Ttl ] && [ "$(curl -sL -w '%{http_code}' http://127.0.0.1:${Port}/ui/index.html -o /dev/null)" != "200" ]; then
    printf "\r\033[K😾 \033[0;31mTimeout error : no response from server\033[0m"
    exit
  fi

  printf "\r\033[K------------------------------------------\n"
  printf "Web UI available at \033[0;36mhttp://127.0.0.1:%s/ui/index.html\033[0m" "$Port"
  printf "\n------------------------------------------\n\n"
}

InitCluster() {
  printf "→ \033[0;33mSetting Cluster on port \033[0m%s\033[0;33m...\033[0m" "$Port"

  CParams=""
  Services="--services data,query"
  Output=$(printf "\t-\033[0;36mquery\033[0m\n\t-\033[0;36mdata \033[0m\t\t%sMb" "$RamSize")

  if [ $FTSRamSize -gt 0 ]; then
    CParams="$CParams --cluster-fts-ramsize $FTSRamSize"
    Services="$Services,fts"
    Output=$(printf "%s\n\t-\033[0;36mfts \033[0m\t\t%sMb" "$Output" "$FTSRamSize")
  fi

  if [ $IndexRamSize -gt 0 ]; then
    CParams="$CParams --cluster-index-ramsize $IndexRamSize"
    Services="$Services,index"
    Output=$(printf "%s\n\t-\033[0;36mindex \033[0m\t\t%sMb" "$Output" "$IndexRamSize")
  fi

  if [ $EventRamSize -gt 0 ]; then
    CParams="$CParams --cluster-eventing-ramsize $EventRamSize"
    Services="$Services,eventing"
    Output=$(printf "%s\n\t-\033[0;36meventing \033[0m\t%sMb" "$Output" "$EventRamSize")
  fi

  if [ $AnalyticsRamSize -gt 0 ]; then
    CParams="$CParams --cluster-analytics-ramsize $AnalyticsRamSize"
    Services="$Services,analytics"
    Output=$(printf "%s\n\t-\033[0;36manalytics \033[0m\t%sMb" "$Output" "$AnalyticsRamSize")
  fi

  couchbase-cli cluster-init -c 127.0.0.1:${Port} \
    --cluster-username "$Username" \
    --cluster-password "$Password" \
    --cluster-ramsize "$RamSize" \
    --index-storage-setting "$IndexStorageSettings" \
    $CParams $Services >/dev/null 2>&1

  printf "\r\033[K😸 \033[0;32mSuccessfully configured cluster on port \033[0m%s\033[0;32m.\033[0m\n" "$Port"
  printf "%s\n\n" "$Output"
}

addBuckets() {
  CurrentlyAdded=0
  DisplayStatus=""
  TotalPercent=0

  printf "→ \033[0;33mAdding buckets (\033[0m%s/%s\033[0;33m)...\033[0m" "$CurrentlyAdded" "$BucketsCount"

  for BucketName in $(jq -re '.resources.buckets | keys | join(" ")' <"config.json"); do
    Extra=""

    BucketType=$(jq -re ".resources.buckets.${BucketName}.type // empty" <"$ConfigFile")
    BucketRamSizeCoeff=$(jq -re ".resources.buckets.${BucketName}.size // empty" <"$ConfigFile")
    BucketFlush=$(jq -re ".resources.buckets.${BucketName}.flush // empty" <"$ConfigFile")
    BucketConflictResolution=$(jq -re ".resources.buckets.${BucketName}.conflictResolution // empty" <"$ConfigFile")
    BucketFragmentationThresholdPercentage=$(jq -re ".resources.buckets.${BucketName}.databaseFragmentationThresholdPercentage // empty" <"$ConfigFile")
    BucketFragmentationThresholdSize=$(jq -re ".resources.buckets.${BucketName}.databaseFragmentationThresholdSize // empty" <"$ConfigFile")
    BucketViewFragmentationThresholdPercentage=$(jq -re ".resources.buckets.${BucketName}.viewFragmentationThresholdPercentage // empty" <"$ConfigFile")
    BucketViewFragmentationThresholdSize=$(jq -re ".resources.buckets.${BucketName}.viewFragmentationThresholdSize // empty" <"$ConfigFile")

    BucketType=${BucketType:="couchbase"}
    BucketFlush=${BucketFlush:=0}
    BucketConflictResolution=${BucketConflictResolution:="sequence"}
    BucketFragmentationThresholdPercentage=${BucketFragmentationThresholdPercentage:=100}
    BucketFragmentationThresholdSize=${BucketFragmentationThresholdSize:=256}
    BucketViewFragmentationThresholdPercentage=${BucketViewFragmentationThresholdPercentage:=100}
    BucketViewFragmentationThresholdSize=${BucketViewFragmentationThresholdSize:=256}

    if [ "$BucketRamSizeCoeff" -le 0 ]; then
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31msize is too low (\033[0m%s033[0;31m). Please set it to 1 at least.\033[0m" "$DisplayStatus" "$BucketName" "$BucketRamSizeCoeff")
      continue
    fi

    if [ "$BucketRamSizeCoeff" -gt 100 ]; then
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31msize is too high (\033[0m%s033[0;31m). Please set it lower or equal to 100.\033[0m" "$DisplayStatus" "$BucketName" "$BucketRamSizeCoeff")
      continue
    fi

    TotalPercent=$((TotalPercent + BucketRamSizeCoeff))

    if [ "$TotalPercent" -gt 100 ]; then
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mtotal buckets size exceed the 100%s limit. Please ensure the total size of all your buckets is lower or equal to 100.\033[0m" "$DisplayStatus" "$BucketName" "%")
      continue
    fi

    MbSize=$((RamSize * BucketRamSizeCoeff / 100))

    if [ "$MbSize" -lt 100 ]; then
      TotalPercent=$((TotalPercent - BucketRamSizeCoeff))
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mcomputed bucket size (\033[0m%sMb\033[0;31m) is lower than the Couchbase 100Mb limit. Please change either your bucket size, or level up your .resources.ramSize.\033[0m" "$DisplayStatus" "$BucketName" "$MbSize")
      continue
    fi

    if [ $BucketType = "couchbase" ]; then
      BucketStorageBackend=$(jq -re ".resources.buckets.${BucketName}.storageBackend // empty" <"$ConfigFile")
      BucketIndexReplica=$(jq -re ".resources.buckets.${BucketName}.indexReplica // empty" <"$ConfigFile")
      BucketStorageBackend=${BucketStorageBackend:="couchstore"}
      BucketIndexReplica=${BucketIndexReplica:=0}
      Extra="$Extra --storage-backend $BucketStorageBackend --enable-index-replica $BucketIndexReplica"
    fi

    if [ $BucketType = "couchbase" ] || [ $BucketType = "ephemeral" ]; then
      BucketReplica=$(jq -re ".resources.buckets.${BucketName}.replica // empty" <"$ConfigFile")
      BucketPriority=$(jq -re ".resources.buckets.${BucketName}.priority // empty" <"$ConfigFile")
      BucketEvictionPolicy=$(jq -re ".resources.buckets.${BucketName}.evictionPolicy // empty" <"$ConfigFile")
      BucketReplica=${BucketReplica:=0}
      BucketPriority=${BucketPriority:="low"}
      if [ $BucketType = "couchbase" ]; then
        BucketEvictionPolicy=${BucketEvictionPolicy:="valueOnly"}
      else
        BucketEvictionPolicy=${BucketEvictionPolicy:="noEviction"}
      fi

      EnterpriseEditionOnly=""

      BucketMaxTtl=$(jq -re ".resources.buckets.${BucketName}.maxTtl // empty" <"$ConfigFile")
      if [ -n "$BucketMaxTtl" ] && [ "$BucketMaxTtl" -gt 0 ]; then
        EnterpriseEditionOnly="$EnterpriseEditionOnly --max-ttl $BucketMaxTtl"
      fi

      BucketCompressionMode=$(jq -re ".resources.buckets.${BucketName}.compressionMode // empty" <"$ConfigFile")
      if [ -n "$BucketCompressionMode" ]; then
        EnterpriseEditionOnly="$EnterpriseEditionOnly --compression-mode $BucketCompressionMode"
      fi

      Extra="$Extra --bucket-replica $BucketReplica --bucket-priority $BucketPriority --bucket-eviction-policy $BucketEvictionPolicy $EnterpriseEditionOnly"
    fi

    if [ "$BucketFragmentationThresholdPercentage" -lt 2 ]; then
      TotalPercent=$((TotalPercent - BucketRamSizeCoeff))
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mbucket fragmentation threshold percentage (\033[0m%sMb\033[0;31m) is lower than the Couchbase 2 limit.\033[0m" "$DisplayStatus" "$BucketName" "$BucketFragmentationThresholdPercentage")
      continue
    elif [ "$BucketFragmentationThresholdPercentage" -gt 100 ]; then
      TotalPercent=$((TotalPercent - BucketRamSizeCoeff))
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mbucket fragmentation threshold percentage (\033[0m%sMb\033[0;31m) is greater than the Couchbase 100 limit.\033[0m" "$DisplayStatus" "$BucketName" "$BucketFragmentationThresholdPercentage")
      continue
    fi

    if [ "$BucketFragmentationThresholdSize" -lt 1 ]; then
      TotalPercent=$((TotalPercent - BucketRamSizeCoeff))
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mbucket fragmentation threshold size (\033[0m%sMb\033[0;31m) is lower than the Couchbase 1 limit.\033[0m" "$DisplayStatus" "$BucketName" "$BucketFragmentationThresholdSize")
      continue
    fi

    if [ "$BucketViewFragmentationThresholdPercentage" -lt 2 ]; then
      TotalPercent=$((TotalPercent - BucketRamSizeCoeff))
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mbucket view fragmentation threshold percentage (\033[0m%sMb\033[0;31m) is lower than the Couchbase 2 limit.\033[0m" "$DisplayStatus" "$BucketName" "$BucketViewFragmentationThresholdPercentage")
      continue
    elif [ "$BucketViewFragmentationThresholdPercentage" -gt 100 ]; then
      TotalPercent=$((TotalPercent - BucketRamSizeCoeff))
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mbucket view fragmentation threshold percentage (\033[0m%sMb\033[0;31m) is greater than the Couchbase 100 limit.\033[0m" "$DisplayStatus" "$BucketName" "$BucketViewFragmentationThresholdPercentage")
      continue
    fi

    if [ "$BucketViewFragmentationThresholdSize" -lt 1 ]; then
      TotalPercent=$((TotalPercent - BucketRamSizeCoeff))
      DisplayStatus=$(printf "%s\n\t-%s \033[0;31mbucket view fragmentation threshold size (\033[0m%sMb\033[0;31m) is lower than the Couchbase 1 limit.\033[0m" "$DisplayStatus" "$BucketName" "$BucketViewFragmentationThresholdSize")
      continue
    fi

    couchbase-cli bucket-create -c 127.0.0.1:${Port} \
      --username "$Username" \
      --password "$Password" \
      --bucket "$BucketName" \
      --bucket-type "$BucketType" \
      --bucket-ramsize "$MbSize" \
      --enable-flush "$BucketFlush" \
      --conflict-resolution "$BucketConflictResolution" \
      --database-fragmentation-threshold-percentage "$BucketFragmentationThresholdPercentage" \
      --database-fragmentation-threshold-size "$BucketFragmentationThresholdSize" \
      --view-fragmentation-threshold-percentage "$BucketViewFragmentationThresholdPercentage" \
      --view-fragmentation-threshold-size "$BucketViewFragmentationThresholdSize" \
      $Extra \
      --wait >/dev/null 2>&1

    CurrentlyAdded=$((CurrentlyAdded + 1))
    printf "\r\033[K→ \033[0;33mAdding buckets (\033[0m%s/%s\033[0;33m)...\033[0m" "$CurrentlyAdded" "$BucketsCount"

    DisplayStatus=$(printf "%s\n\t- \033[1;36m" "$DisplayStatus")
    i=0
    while [ "$i" -lt "$BucketRamSizeCoeff" ]; do
      DisplayStatus=$(printf "%s█" "$DisplayStatus")
      i=$((i + 5))
    done

    DisplayStatus=$(printf "%s\033[0;37m" "$DisplayStatus")

    while [ "$i" -le 100 ]; do
      DisplayStatus=$(printf "%s█" "$DisplayStatus")
      i=$((i + 5))
    done

    DisplayStatus=$(printf "%s\033[0m %s \033[0;33m(%s%s, %sMb)\033[0m" "$DisplayStatus" "$BucketName" "$BucketRamSizeCoeff" "%" "$MbSize")
  done

  printf "\r\033[K😸 \033[0;32mSuccessfully configured \033[0m%s\033[0;32m buckets.\033[0m%s\n" "$BucketsCount" "$DisplayStatus"
  printf "\t- \033[0;33m"

  i=0
  while [ "$i" -lt "$TotalPercent" ]; do
    printf "█"
    i=$((i + 5))
  done

  printf "\033[0;37m"

  while [ "$i" -le 100 ]; do
    printf "█"
    i=$((i + 5))
  done

  printf " \033[0m%s%s of total \033[0;32m(%sMb  available)\033[0m\n" "$TotalPercent" "%" "$(( (100-TotalPercent)*RamSize/100 ))"
}

# Parse command-line arguments.
for ARGUMENT in "$@"; do
  KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
  VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

  case "$KEY" in
  --config-file) ConfigFile=${VALUE} ;;
  *) ;;
  esac
done

CheckConfigurationFile
ReadConfigurationFile

KillOldInstances
SetupNewInstance

WaitForWebUI
InitCluster

if [ "$BucketsCount" -gt 0 ]; then
  addBuckets
fi

printf "\nSetup complete ! 😸😸😸\n"