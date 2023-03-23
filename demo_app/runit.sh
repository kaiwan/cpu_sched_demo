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

PRG=sched_pthrd_rtprio_dbg
[[ ! -f ${PRG} ]] && {
  echo make ; make || exit 1
}
#--- 'Old' way: via sudo
# Allow it to only execute on core #1
#sudo taskset -c 01 ./${PRG} 20

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
if [[ ! -z ${SCHED_RT_PERIOD_US} && ! -z ${SCHED_RT_RUNTIME_US} ]]; then
	# Set the runtime value - the 'max cpu bandwidth' - to the period value,
	# so that the (soft) RT threads don't 'leak' any CPU to non-RT threads
	[[ ${CHANGE_RUNTIME_TO_PERIOD} -eq 1 && ${SCHED_RT_RUNTIME_US} != ${SCHED_RT_PERIOD_US} ]] && {
		echo "Setting runtime value to period val (so that no cpu 'leakasge' to non-RT tasks occurs)"
		sudo sh -c "echo ${SCHED_RT_PERIOD_US} > /proc/sys/kernel/sched_rt_runtime_us"
		SCHED_RT_RUNTIME_US=$(cat /proc/sys/kernel/sched_rt_runtime_us)
		echo "New values:"
		printf "sched_rt_period_us  = %7d\n" ${SCHED_RT_PERIOD_US}
		printf "sched_rt_runtime_us = %7d\n" ${SCHED_RT_RUNTIME_US}
	}
fi
echo

#--- 'New' way: via capabilities!
# There's a better approach to using sudo; we use the powerful POSIX
# Capabilities model instead! This way, the app process (and threads) get _only_
# the capabilities they require and nothing more. Helps reduce the attack surface.
# Skip adding CAP_SYS_NICE if it already has it...
getcap ./${PRG} | grep "cap_sys_nice" >/dev/null || {
  echo "[+] sudo setcap CAP_SYS_NICE+eip ./${PRG}"
  sudo setcap CAP_SYS_NICE+eip ./${PRG}
  echo "[+] getcap ./${PRG}"
  getcap ./${PRG}
} && echo "${PRG} already has the capability CAP_SYS_NICE enabled"

# Now we can run the app as a regular user...
