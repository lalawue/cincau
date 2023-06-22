/*
 * Copyright (c) 2023 lalawue
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the MIT license. See LICENSE for details.
 */

#define _XOPEN_SOURCE 500
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <semaphore.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/errno.h>
#include <dlfcn.h>
#include <signal.h>

// MARK: - outer definition

typedef int (*mnet_balancer_cb)(void *context, int afd);

/* multiprocessing accept balancer, return 0 in ac_before to disable accept */
void (*mnet_multi_accept_balancer)(void *ac_context,
                                   mnet_balancer_cb ac_before,
                                   mnet_balancer_cb ac_after);

/* multiprocessing reset event queue */
void (*mnet_multi_reset_event)(void);

// MARK: - implemention

#if defined(_WIN32) || defined(_WIN64)
void mnet_server_register(const char *npath, int listen_fd, int worker_count, int worker_restart_ms)
{
}
int mnet_server_waitpid()
{
    return 0;
}
void mnet_server_exit()
{
}
#else
typedef struct
{
    pid_t pid;        // process pid
    sem_t *sem;       // process semaphore for require accept locker
    int listen_fd;    // listen fd
    int worker_index; // worker_index > 0
    int worker_count;
    int worker_restart_ms;
    pid_t *worker_pids;
} monitor_t;

monitor_t *mon;

static int
_monitor_before_after_ac(void *ac_context, int afd)
{
    monitor_t *mon = (monitor_t *)ac_context;
    if (afd == mon->listen_fd)
    {
        // will not accept listen_fd
        return 0;
    }
    else
    {
        // accept except listen_fd
        return 1;
    }
}

static int
_worker_before_ac(void *ac_context, int afd)
{
    monitor_t *mon = (monitor_t *)ac_context;
    return (sem_trywait(mon->sem) == 0) ? 1 : 0;
}

static int
_worker_after_ac(void *ac_context, int afd)
{
    monitor_t *mon = (monitor_t *)ac_context;
    sem_post(mon->sem);
    return 0;
}

static void
_sig_term(int sig)
{
    if (mon->worker_index <= 0)
    {
        for (int i = 0; i < mon->worker_count; i++)
        {
            kill(mon->worker_pids[i], SIGTERM);
        }
    }
    exit(0);
}

/// @brief load mnet.so then register listen_fd and get worker_count
/// @param listen_fd
/// @param worker_count
void mnet_server_register(const char *npath, int listen_fd, int worker_count, int worker_restart_ms)
{
    {
        char *buf = calloc(1, 4096);
        sprintf(buf, "%s/mnet.so", npath);
        void *handle = dlopen(buf, RTLD_LAZY);
        if (!handle)
        {
            fprintf(stderr, "%s\n", dlerror());
            exit(EXIT_FAILURE);
        }
        dlerror();
        mnet_multi_accept_balancer = dlsym(handle, "mnet_multi_accept_balancer");
        mnet_multi_reset_event = dlsym(handle, "mnet_multi_reset_event");
        // printf("regiser %p, %p\n", mnet_multi_accept_balancer, mnet_multi_reset_event);
        free(buf);
    }
    {
        mon = (monitor_t *)calloc(1, sizeof(monitor_t));
        mon->worker_pids = (pid_t *)calloc(worker_count, sizeof(pid_t));
        mon->listen_fd = listen_fd;
        mon->worker_count = worker_count;
        mon->worker_restart_ms = worker_restart_ms;
        mon->pid = getpid();
        mon->sem = sem_open("mnet.server.worker", O_RDWR | O_CREAT, 0644, 1);
        // printf("register pid:%d fd:%d sem:%p\n", mon->pid, mon->listen_fd, mon->sem);
    }
    {
        signal(SIGTERM, _sig_term);
    }
}

/// @brief fork() and waitpid() for monitor and worker
/// @return =0 for monitor
/// @return <0 for worker index visit again
/// @return >0 for worker index after fork()
int mnet_server_waitpid()
{
    int status;
    int fork_count = 0;

    if (mon->worker_index)
    {
        return -mon->worker_index;
    }

    // only monitor need waitpid
    for (int i = 0; i < mon->worker_count; i++)
    {
        if ((mon->worker_pids[i] == 0) || (-1 == waitpid(mon->worker_pids[i], &status, WNOHANG)))
        {
            if (mon->worker_pids[i] > 0)
            {
                usleep(mon->worker_restart_ms);
            }

            pid_t pid = fork();
            if (pid == -1)
            {
                perror("fork()");
                exit(1);
            }
            else if (pid == 0)
            {
                mon->pid = getpid();
                mon->worker_index = i + 1;
                mnet_multi_accept_balancer(mon, _worker_before_ac, _worker_after_ac);
                mnet_multi_reset_event();
                return mon->worker_index;
            }
            else if (pid > 0)
            {
                mon->worker_pids[i] = pid;
                fork_count += 1;
            }
        }
    }

    if (fork_count > 0)
    {
        mon->pid = getpid();
        mon->worker_index = 0;
        mnet_multi_accept_balancer(mon, _monitor_before_after_ac, _monitor_before_after_ac);
        mnet_multi_reset_event();
    }

    return 0;
}

void mnet_server_exit()
{
    _sig_term(SIGTERM);
}
#endif