# System control and usages

## CPU

cpu frequency for all cores

> $ `watch -n.1 "cat /proc/cpuinfo | grep \"^[c]pu MHz\""`

Disable turbo

> $ echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

Set usage of cpu in procent

> $ echo "80" | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct

## Use the GPU

For a second monitor

> $ xrandr --setprovideroutputsource 1 0

If the above doesn't work try

> $ xrandr --output eDP-1 --primary --mode 1920x1080 --rotate normal --output
> HDMI-1-0 --mode 1920x1080 --rotate normal --right-of eDP-1

To start applications with nvidia card

> $ __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia %command%

## BATTERY

> $ upower -i /org/freedesktop/UPower/devices/battery_BAT0

## Unblock a partition

> $ udisksctl mount --block-device /dev/dm-10

## Npm sandbox error

> $ sysctl kernel.unprivileged_userns_clone=1

## Run an android emulator

> $ __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia ~/Android/Sdk/
> emulator/emulator -avd Pixel_3a_API_30_x86

## How to use gpg

for using with a passphrase for backup

> $ gpg -c --no-symkey-cache --cipher-algo AES256 filename

for decrypting

> $ gpg filename

## Sort apps on gnome

> $ gsettings reset org.gnome.shell app-picker-layout

and after ALT+F2 and r and Enter
