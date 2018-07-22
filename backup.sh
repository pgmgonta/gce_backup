#!/bin/bash -e

# スナップショットの有効期限
SNAPSHOT_EXPIRATION=$1

print_log() {
  local timestamp=$(date '+%Y/%m/%d %H:%M:%S')
  local msg=$1
  echo "${timestamp} ${msg}"
}

CURRENT_TIME=$(date '+%Y%m%d%H%M%S')
PJ_LIST=$(cat ./pj_list)

for pj in $PJ_LIST
do
  # スナップショットの生成
  print_log "Start to create GCE Instance Snapshots in ${pj}"
  gcloud --project $pj --format=json compute disks list --format='value(name,zone)'| while read diskname zone; do 
    print_log "Start to create snapshot: ${pj} ${diskname} ${zone}"
    gcloud --project $pj compute disks snapshot $diskname --snapshot-names auto-bk-${diskname}-${CURRENT_TIME} --zone=$zone
    print_log "Created snapshot: ${pj} ${disk}"
  done

  #  有効期限が切れたスナップショットの削除
  print_log "Start to delete snapshots in ${pj}"
  from_date=$(date -d "${SNAPSHOT_EXPIRATION} day ago" '+%Y-%m-%d')
  gcloud --project $pj compute snapshots list --format='value(name,creationTimestamp)' --filter="creationTimestamp <= $from_date AND name ~ '^auto-bk-*'" | while read snapshot creationTimestamp; do
    echo "Start to delete snapshot ${pj} ${snapshot}"
    gcloud --project ${pj} -q --format=json compute snapshots delete ${snapshot} 
    echo "Deleted snapshot ${pj} ${snapshot} "
  done
  print_log "Completed to delete snapshots in ${pj}"

done
