#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

unsigned char armelf[] = {
  0x7f, 0x45, 0x4c, 0x46, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x28, 0x00, 0x01, 0x00, 0x00, 0x00,
  0x54, 0x00, 0x01, 0x00, 0x34, 0x00, 0x00, 0x00, 0x94, 0x00, 0x00, 0x00,
  0x00, 0x02, 0x00, 0x05, 0x34, 0x00, 0x20, 0x00, 0x01, 0x00, 0x28, 0x00,
  0x04, 0x00, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x60, 0x00, 0x00, 0x00,
  0x60, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00,
  0x01, 0x70, 0xa0, 0xe3, 0x00, 0x00, 0xa0, 0xe3, 0x00, 0x00, 0x00, 0xef,
  0x41, 0x11, 0x00, 0x00, 0x00, 0x61, 0x65, 0x61, 0x62, 0x69, 0x00, 0x01,
  0x07, 0x00, 0x00, 0x00, 0x08, 0x01, 0x00, 0x2e, 0x73, 0x68, 0x73, 0x74,
  0x72, 0x74, 0x61, 0x62, 0x00, 0x2e, 0x74, 0x65, 0x78, 0x74, 0x00, 0x2e,
  0x41, 0x52, 0x4d, 0x2e, 0x61, 0x74, 0x74, 0x72, 0x69, 0x62, 0x75, 0x74,
  0x65, 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0b, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x54, 0x00, 0x01, 0x00,
  0x54, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x11, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x70, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x60, 0x00, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x72, 0x00, 0x00, 0x00,
  0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};
unsigned int armelf_len = 308;

int main() {
    char tmpPath[] = "/tmp/test_armXXXXXX";
    int fd = mkstemp(tmpPath);
    if (fd < 0) {
        perror("mkstemp");
        return 0;
    }

    ssize_t written = write(fd, armelf, armelf_len);
    if (written != (ssize_t)armelf_len) {
        perror("write to tmp file");
        close(fd);
        unlink(tmpPath);
        return 0;
    }
    close(fd);

    if (chmod(tmpPath, 0700) != 0) {
        perror("chmod tmp file");
        unlink(tmpPath);
        return 0;
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        unlink(tmpPath);
        return 0;
    }
    else if (pid == 0) {
        execl(tmpPath, tmpPath, (char *)NULL);
        _exit(127);
    }

    int status;
    waitpid(pid, &status, 0);

    unlink(tmpPath);

    return (WIFEXITED(status) && (WEXITSTATUS(status) == 0)) ? 1 : 0;
}

