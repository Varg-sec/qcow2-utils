# load nbd kernel module with Number of partitions per device set to 8
modprobe nbd max_part=8

available_devices=$(ls /dev/nbd*)

for device in $available_devices; do
  if ! nbd-client -c "$device" &> /dev/null; then
    break
  fi
done

if [[ "${args[--snapshot]}" ]]; then
  # external snapshots might be named <vm_name>.<snapshot_name> or
  # <vm_name>.<UNIX_timestamp>, and are located next to the original vm image
  # The latter is currently not supported. Provide the timestamp as snapshot and it
  # will work, e.g. '--snapshot 1770027429' mounts win11.1770027429 snapshot
  if [[ -e "${args[image]::-6}.${args[--snapshot]}" ]]; then
    qemu-nbd --connect="$device" "${args[image]::-6}.${args[--snapshot]}"
  else
    # haven't found external snapshot, assuming it's an internal one
    qemu-nbd --connect="$device" --load-snapshot=snapshot.name="${args[--snapshot]}" "${args[image]}"
  fi
else
  qemu-nbd --connect="$device" "${args[image]}"
fi



if [[ -z "${args[--partition]}" ]]; then
  # get largest device
  device_to_mount=$(
    fdisk -l "$device" |
      tail -n +8 |
      awk '{print $1, $5}' |
      sort -hr -k2 |
      head -n 1 |
      awk '{print $1}'
  )
else
  device_to_mount="${device}p${args[--partition]}"
  if [ ! -f "$device_to_mount" ]; then
    red "Device '$device_to_mount' does not exist"
  fi
fi

mkdir "${args[mountpoint]}"

mount -o ro "$device_to_mount" "${args[mountpoint]}"
