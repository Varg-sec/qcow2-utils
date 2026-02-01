# load nbd kernel module with Number of partitions per device set to 8
modprobe nbd max_part=8

available_devices=$(ls /dev/nbd*)

for device in $available_devices; do
  nbd-client -c "$device" &> /dev/null

  if [[ $? -ne 0 ]]; then
    echo "$device"
    break
  fi
done

# TODO: add --load-snapshot=snapshot.name=<name> to access snapshot
qemu-nbd --connect="$device" "$1"

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
  if [ ! -f $device_to_mount ]; then
    red "Device '$device_to_mount' does not exist"
  fi
fi


mkdir "${args[mountpoint]}"

mount -o ro "$device_to_mount" "${args[mountpoint]}"