// SPDX-License-Identifier: GPL-2.0
// A user's service manager exits its whole session on SIGTERM, and every orphan it runs lists it as parent,
// so `kill` on a looked-up parent pid ends everything the user runs: systemd(1), "Signals".
#include <stdbool.h>
#include <linux/bpf.h>
#include <linux/errno.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

struct kernel_siginfo;
struct cred;

struct task_struct {
	int tgid;
	struct task_struct *real_parent;
	char comm[16];
} __attribute__((preserve_access_index));

static const char service_manager[] = "systemd";
static const int SYSTEM_MANAGER = 1;
static const __u32 ROOT = 0;

static bool is_a_users_service_manager(struct task_struct *task)
{
	char name[sizeof(task->comm)];

	if (task->real_parent->tgid != SYSTEM_MANAGER)
		return false;

	bpf_probe_read_kernel_str(name, sizeof(name), task->comm);
	return bpf_strncmp(name, sizeof(name), service_manager) == 0;
}

SEC("lsm/task_kill")
int BPF_PROG(only_root_signals_a_users_service_manager, struct task_struct *target,
	     struct kernel_siginfo *info, int signal, const struct cred *cred, int refused_already)
{
	__u32 sender = bpf_get_current_pid_tgid() >> 32;
	__u32 senders_user = bpf_get_current_uid_gid();

	if (refused_already)
		return refused_already;

	if (senders_user == ROOT || sender == target->tgid || !is_a_users_service_manager(target))
		return 0;

	return -EPERM;
}

char LICENSE[] SEC("license") = "GPL";
