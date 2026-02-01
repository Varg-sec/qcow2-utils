# get device from mountpoint
device=$(
    mount |
    grep "${args[mountpoint]}" |
    awk '{print $1}' |
    cut -c1-9
)
echo $device

umount "${args[mountpoint]}"
rmdir "${args[mountpoint]}"

qemu-nbd -d "$device"

