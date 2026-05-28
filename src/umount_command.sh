# get device from mountpoint
device=$(
  mount |
    grep -w "${args[mountpoint]}" |
    awk '{print $1}' |
    sed 's/p[0-9]*$//'
)

if [[ ${args[-l]} ]]; then
  umount -l "${args[mountpoint]}"
elif [[ ${args[-f]} ]]; then
  umount -f "${args[mountpoint]}"
else
  umount "${args[mountpoint]}"
fi

rmdir "${args[mountpoint]}"

# in case linux image was mounted with writeable permissions, remove base view as well
base_mountpoint="${args[mountpoint]}_base"
if mountpoint -q "$base_mountpoint" 2>/dev/null; then
  # in case base image exists, device needs to be updated
  device=$(
    mount |
      grep -w "$base_mountpoint" |
      awk '{print $1}' |
      sed 's/p[0-9]*$//'
  )
  if [[ ${args[-l]} ]]; then
    umount -l "$base_mountpoint"
  elif [[ ${args[-f]} ]]; then
    umount -f "$base_mountpoint"
  else
    umount "$base_mountpoint"
  fi
  rmdir "$base_mountpoint"
fi

qemu-nbd -d "$device"
