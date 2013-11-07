// Copyright © 2013, S.Çağlar Onur
// Use of this source code is governed by a LGPLv2.1 licence
// license that can be found in the LICENSE file.
//
// Authors:
// S.Çağlar Onur <caglar@10ur.org>

extern bool lxc_container_clear_config_item(struct lxc_container *, char *);
extern bool lxc_container_create(struct lxc_container *, char *, char **);
extern bool lxc_container_defined(struct lxc_container *);
extern bool lxc_container_destroy(struct lxc_container *);
extern bool lxc_container_freeze(struct lxc_container *);
extern bool lxc_container_load_config(struct lxc_container *, char *);
extern bool lxc_container_running(struct lxc_container *);
extern bool lxc_container_save_config(struct lxc_container *, char *);
extern bool lxc_container_set_cgroup_item(struct lxc_container *, char *key, char *);
extern bool lxc_container_set_config_item(struct lxc_container *, char *, char *);
extern bool lxc_container_set_config_path(struct lxc_container *, char *);
extern bool lxc_container_shutdown(struct lxc_container *, int);
extern bool lxc_container_start(struct lxc_container *, int, char **);
extern bool lxc_container_stop(struct lxc_container *);
extern bool lxc_container_unfreeze(struct lxc_container *);
extern bool lxc_container_wait(struct lxc_container *, char *, int);
extern char* lxc_container_config_file_name(struct lxc_container *);
extern char* lxc_container_get_cgroup_item(struct lxc_container *, char *);
extern char* lxc_container_get_config_item(struct lxc_container *, char *);
extern char* lxc_container_get_keys(struct lxc_container *, char *);
extern const char* lxc_container_get_config_path(struct lxc_container *);
extern const char* lxc_container_state(struct lxc_container *);
extern pid_t lxc_container_init_pid(struct lxc_container *);
extern void lxc_container_want_daemonize(struct lxc_container *);
