#!/usr/bin/env ruby

## unable to umount the mounted ssd from the node within a pod
## the daemonset approach reachs a deadend

require 'pp'

def modprobe(module)
  unless system("lsmod | grep -q #{module}")
    cmd = "modprobe #{module}"
    puts cmd
  end
end

devices = `blkid | grep '/dev/sd' | grep -v sda | sed 's/ //g' | awk -F'[ :=]' '{OFS="|"} {gsub(/"/, "", $NF); print $1,$NF}'`.split("\n")

devices.each do |d|
  disk, fs = d.split('|')
  unless fs =~ /LVM/
    puts disk
  end
end
