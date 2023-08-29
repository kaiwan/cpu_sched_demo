#!/bin/bash
# runit.sh
# Run the demo sched_pthrd MT app (that spawns off SCHED_FIFO threads)
# License: MIT
# (c) kaiwanTECH

# Turn on unofficial Bash 'strict mode'! V useful
# "Convert many kinds of hidden, intermittent, or subtle bugs into immediate, glaringly obvious errors"
# ref: http://redsymbol.net/articles/unofficial-bash-strict-mode/ 
set -euo pipefail
name=$(basename $0)

usage()
{
echo "Usage: ${name} [RT-throttling]
RT-throttling (on by default):
 Set to 0 to ensure that the (soft) RT threads do NOT 'leak' any CPU to non-RT threads
 Set to 1 to ensure that the (soft) RT threads do 'leak' some CPU (5% by default) to non-RT threads
  (this is the default).
-h  : show this help screen"
}


#--- 'main'
[[ $# -eq 1 && "$1" = "-h" ]] && {
	usage
	exit 0
}
RT_THROTTLING=1
[[ $# -eq 1 && $1 -eq 0 ]] && RT_THROTTLING=0

PRG=sched_pthrd_rtprio_dbg
[[ ! -f ${PRG} ]] && {
  echo make ; make || exit 1
}

#--- Show and adjust sched runtime tunables as required
echo "FYI: lets lookup a couple of kernel sched-related tunables:"
[[ -f /proc/sys/kernel/sched_rt_period_us ]] && {
	SCHED_RT_PERIOD_US=$(cat /proc/sys/kernel/sched_rt_period_us)
	printf "sched_rt_period_us  = %7d\n" ${SCHED_RT_PERIOD_US}
}
[[ -f /proc/sys/kernel/sched_rt_runtime_us ]] && {
	SCHED_RT_RUNTIME_US=$(cat /proc/sys/kernel/sched_rt_runtime_us)
	printf "sched_rt_runtime_us = %7d\n" ${SCHED_RT_RUNTIME_US}
}
[[ ${RT_THROTTLING} -eq 0 ]] && {
	echo "Setting sched_rt_runtime_us to -1 (turns RT throttling off; no cpu 'leakage' to non-RT tasks occur)"
	sudo sh -c "echo -1 > /proc/sys/kernel/sched_rt_runtime_us"
}
echo

#--- 'New' way: via capabilities!
# There's a better approach to using sudo; we use the powerful POSIX
# Capabilities model instead! This way, the app process (and threads) get _only_
# the capabilities they require and nothing more. Helps reduce the attack surface.
# Follows the 'principle of least privilege'.
# Skip adding CAP_SYS_NICE if it already has it...
getcap ./${PRG} | grep "cap_sys_nice" >/dev/null || {
  echo "[+] sudo setcap CAP_SYS_NICE+eip ./${PRG}"
  sudo setcap CAP_SYS_NICE+eip ./${PRG}
  echo "[+] getcap ./${PRG}"
  getcap ./${PRG}
} && echo "${PRG} already has the capability CAP_SYS_NICE enabled"

# Now we can run the app as a regular user...
# Still have to run it on exactly one cpu core though!!
echo "[+] taskset -c 01 ./${PRG} 20"
taskset -c 01 ./${PRG} 20
exit 0
