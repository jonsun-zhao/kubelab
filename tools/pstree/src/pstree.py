#!/usr/bin/env python
#
# IMPORTANT: run this as global root to have access to ns_ids.  Without global
# root otherwise pid_ns_id=ns_unknown cgroup_ns_id=cg_ns_unknown.  All other
# data, esp cgroup path (aka pod id), will be logged.
#
# This program dumps process info to stdout in json format.  Every 5 seconds a
# new record is printed.
#
# To get per cgroup path clustering of processes from a single record:
#   $ sudo ./pstree.py | head -1 > o
#   $ cat o \
#     | python2.7 -c 'import json; import sys; print "\n".join(json.loads(sys.stdin.read())["procs"].keys())' \
#     | awk '{print $NF}' | sort | uniq -c | sort -n
# Sample output:
#     4 /,/user.slice,/user.slice/user-104648.slice/session-c64.scope
#   101 /,/user.slice,/user.slice/user-104648.slice/session-c2.scope
#   154 /,/system.slice/cron.service
#   183 /
#
# Including thread counts per pid namespace:
#   $ cat > dump.py <<EOF
#   import json
#   import sys
#   for k,v in json.loads(sys.stdin.read())["procs"].iteritems():
#      print k.split()[-1], v
#   EOF
#   $ python2.7 dump.py < o | awk '{s[$1]+=$2} END {for (i in s) print s[i], i}' | sort -n
#   250 /,/user.slice,/user.slice/user-104648.slice/session-c2.scope
#   378 /,/system.slice/srcfs.service

import json
import os
import sys
import time


def proc_pid_ns(pid):
    try:
        return os.readlink("/proc/%d/ns/pid" % pid)
    except:
        return "ns_unknown"


def proc_cgroup_ns(pid):
    try:
        return os.readlink("/proc/%d/ns/cgroup" % pid)
    except:
        return "cg_ns_unknown"


def proc_cgroups(pid):
    try:
        with open("/proc/%d/cgroup" % pid) as cg:
            ret = {}
            for line in cg.readlines():
                ret[line.strip().split(":")[2]] = True
            return ",".join(sorted(ret.keys()))
    except:
        return "cg_unknown"


def proc_name(pid):
    try:
        with open("/proc/%d/stat" % pid) as f:
            words = f.read().split()
            if len(words) < 2:
                return "pn_short"
            return words[1]
    except:
        return "pn_error"

# returns total_n_thread, proc_details


def pstree():
    n_thread = 0
    procs = {}  # "pid (comm) pid_ns_id cgroup_ns_id" => n_threads
    for n in os.listdir("/proc"):
        try:
            pid = int(n)
            threads = 0
            for t in os.listdir("/proc/%d/task" % pid):
                threads += 1
            n_thread += threads
            procs["%d %s %s %s %s" % (pid, proc_name(pid), proc_pid_ns(
                pid), proc_cgroup_ns(pid), proc_cgroups(pid))] = threads
        except:
            pass
    return n_thread, procs


while True:
    n_thread, procs = pstree()
    data = {
        "time": time.ctime(),
        "n_procs": len(procs),
        "n_threads": n_thread,
        "procs": procs,
    }
    sys.stdout.write(json.dumps(data)+"\n")
    time.sleep(5)
