#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/sysinfo.h>

#ifndef PATH_MAX
#define PATH_MAX 1024
#endif

#define STARTSWITH(A, B) (strncmp(A, B, strlen(B)) == 0)

typedef struct {
    char **aliases;
    int thread_id;
    int num_threads;
} modprobe_t;

static void *modprobe_fn(void *arg) {
    const modprobe_t *m = (modprobe_t *)arg;
    for (size_t i = m->thread_id; m->aliases[i]; i += m->num_threads) {
        pid_t pid = fork();
        if (pid < 0) {
            perror("fork failed");
            continue;
        }
        if (pid == 0) {  // Child process
            char *args[] = {"modprobe", "-ab", m->aliases[i], NULL};
            FILE* nlerr = freopen("/dev/null", "w", stderr);
            FILE* nlout = freopen("/dev/null", "w", stdout);
            (void)nlerr; (void)nlout;
            execvp(args[0], args);
            perror("execvp failed");
            exit(1);
        }
        // Parent process: wait for the child to finish
        int status;
        waitpid(pid, &status, 0);
    }
    return NULL;
}

void modprobe() {
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork failed");
        return;
    }
    if (pid == 0) {  // Child process
            char *args[] = {"depmod", "-a", NULL};
            execvp(args[0], args);
            perror("execvp failed");
            exit(1);
    }
    int status;
    waitpid(pid, &status, 0);

    DIR *dir;
    const struct dirent *entry;
    size_t alias_size = 512;
    size_t alias_count = 0;
    char **aliases = malloc(alias_size * sizeof(char *));
    if (!aliases) {
        perror("Memory allocation failed");
        return;
    }

    dir = opendir("/sys/bus");
    if (!dir) {
        perror("opendir");
        free(aliases);
        return;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        char filepath[PATH_MAX];
        snprintf(filepath, sizeof(filepath), "/sys/bus/%s/devices/", entry->d_name);
        DIR *dir2 = opendir(filepath);
        if (!dir2) continue;

        const struct dirent *entry2;
        while ((entry2 = readdir(dir2)) != NULL) {
            if (strcmp(entry2->d_name, ".") == 0 || strcmp(entry2->d_name, "..") == 0) {
                continue;
            }
            snprintf(filepath, sizeof(filepath), "/sys/bus/%s/devices/%s/uevent", entry->d_name, entry2->d_name);
            FILE *file = fopen(filepath, "r");
            if (!file) continue;

            char line[1024];
            while (fgets(line, sizeof(line), file)) {
                if (STARTSWITH(line, "MODALIAS=")) {
                    char *mod = line + strlen("MODALIAS=");
                    mod[strcspn(mod, "\n")] = 0;
                    if (strlen(mod) > 0) {
                        if (alias_count >= alias_size) {
                            alias_size += 512;
                            char** tmp = realloc(aliases, alias_size * sizeof(char *));
                            if(tmp){
                                aliases = tmp;
                            }
                            if (!aliases) {
                                perror("Memory reallocation failed");
                                fclose(file);
                                closedir(dir2);
                                closedir(dir);
                                return;
                            }
                        }
                        aliases[alias_count] = strdup(mod);
                        alias_count++;
                    }
                }
            }
            fclose(file);
        }
        closedir(dir2);
    }
    closedir(dir);

    aliases[alias_count] = NULL;  // Null-terminate the aliases array

    size_t NUM_THREADS = get_nprocs();
    if(NUM_THREADS < 1){
        NUM_THREADS = 1;
    }
    pthread_t threads[NUM_THREADS];
    modprobe_t m[NUM_THREADS];

    for (size_t i = 0; i < NUM_THREADS; i++) {
        m[i].aliases = aliases;
        m[i].thread_id = i;
        m[i].num_threads = NUM_THREADS;

        if (pthread_create(&threads[i], NULL, modprobe_fn, &(m[i]))) {
            fprintf(stderr, "Error creating thread %zu\n", i);
            free(aliases);
            return;
        }
    }

    for (size_t i = 0; i < NUM_THREADS; i++) {
        if (pthread_join(threads[i], NULL)) {
            fprintf(stderr, "Error joining thread %zu\n", i);
        }
    }

    // Free allocated memory
    for (size_t i = 0; i < alias_count; i++) {
        free(aliases[i]);
    }
    free(aliases);
}

