# get device from mountpoint
device=$(
  mount |
    grep -w "${args[mountpoint]}" |
    awk '{print $1}' |
    cut -c1-9
)

if [[ ${args[-l]} ]]; then
  umount -l "${args[mountpoint]}"
elif [[ ${args[-f]} ]]; then
  umount -f "${args[mountpoint]}"
else
  umount "${args[mountpoint]}"
fi

rmdir "${args[mountpoint]}"

qemu-nbd -d "$device"
