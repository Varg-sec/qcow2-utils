# load nbd kernel module with Number of partitions per device set to 8
modprobe nbd max_part=8

available_devices=$(ls /dev/nbd*)

for device in $available_devices; do
  if ! nbd-client -c "$device" &> /dev/null; then
    break
  fi
done

echo Connect to local NBD device "$device"

if [[ -v "${args[--snapshot]}" ]]; then
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
    fdisk -l "$device" -o Device,Sectors |
      grep '^/dev/' |
      sort -k2 -n -r |
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

if [[ ${args[--read-only]} ]]; then
  mount -r "$device_to_mount" "${args[mountpoint]}" >&2
else
  mount -w "$device_to_mount" "${args[mountpoint]}" >&2
  # fail, if image cannot be mounted with write permissions
  if ! mount | grep "$device_to_mount" | grep -E '(\(rw\)|,rw|rw,)' > /dev/null; then
    exit 1
  fi
fi

echo Mount "$device_to_mount" to "${args[mountpoint]}"
