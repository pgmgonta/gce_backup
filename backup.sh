#!/bin/bash

print_log() {
  local timestamp=$(date '+%Y/%m/%d %H:%M:%S')
  local msg=$1
  echo "${timestamp} ${msg}"
}

without_dquote() {
  sed -e "s/\"//g"
}

PJ_LIST=$(cat ./pj_list)
for pj in $PJ_LIST
do
  # 既存のスナップショットの削除
  print_log "Start to delete snapshots in ${pj}"
  snapshots=$(gcloud --project ${pj} --format=json compute snapshots list | jq -r ".[].name")
  for snapshot in $snapshots
  do
    echo "Start to delete snapshot ${pj} ${snapshot}"
    gcloud --project ${pj} -q --format=json compute snapshots delete ${snapshot}
    echo "Deleted snapshot ${pj} ${snapshot} "
  done
  print_log "Deleted all snapshots in ${pj}"

  # スナップショットの生成
  print_log "Start to create GCE Instance Snapshots in ${pj}"
  disks=$(gcloud --project $pj --format=json compute disks list | jq -r ".[] | {name: .name, zone: .zone} | [.name, .zone] | @csv")

  printf '%s\n' "$disks" |
  while IFS=, read -r diskname zone 
  do
    diskname=$(echo ${diskname} | without_dquote)
    zone=$(echo ${zone##*/} | without_dquote)
    print_log "Start to create snapshot: ${pj} ${diskname} ${zone}"
    gcloud --project $pj compute disks snapshot $diskname --zone=$zone
    print_log "Created snapshot: ${pj} ${disk}"
  done
done

