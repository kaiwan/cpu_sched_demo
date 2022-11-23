#!/bin/bash
# runit.sh
# Run the demo sched_pthrd MT app (that spwans off SCHED_FIFO threads)
# License: MIT
# (c) kaiwanTECH
[ ! -f sched_pthrd_rtprio_dbg ] && {
  echo make ; make || exit 1
}
#--- 'Old' way: via sudo
# Allow it to only execute on core #1
#sudo taskset -c 01 ./sched_pthrd_rtprio_dbg 20

echo "FYI: sched_rt_period_us and sched_rt_runtime_us values:"
cat /proc/sys/kernel/sched_rt_period_us /proc/sys/kernel/sched_rt_runtime_us
echo


#--- 'New' way: via capabilities!
# There's a better approach to using sudo; we use the powerful POSIX
# Capabilities model instead! This way, the process (and threads) get _only_
# the capabilities they require and nothing more. Reduces the attack surface.
# Skip adding CAP_SYS_NICE if it already has it...
getcap ./sched_pthrd_rtprio_dbg | grep -q "cap_sys_nice" || {
  echo "[+] sudo setcap CAP_SYS_NICE+eip ./sched_pthrd_rtprio_dbg"
  sudo setcap CAP_SYS_NICE+eip ./sched_pthrd_rtprio_dbg
  echo "[+] getcap ./sched_pthrd_rtprio_dbg"
  getcap ./sched_pthrd_rtprio_dbg
} && echo "sched_pthrd_rtprio_dbg already has the capability CAP_SYS_NICE enabled"

# Now we can run the app as a regular user...
# Still have to run it on exactly one core though!!
echo "[+] taskset -c 01 ./sched_pthrd_rtprio_dbg 20"
taskset -c 01 ./sched_pthrd_rtprio_dbg 20
