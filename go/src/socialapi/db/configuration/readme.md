## Set SHMAX var
The SHMMAX variable controls the maximum amount of memory to be allocated for shared memory use. If you try to assign high values for e.g. the shared_buffers GUC in PostgreSQL without adjusting SHMMAX, you might see an error message in Postgres' log like " ... Failed system call was shmget ... usually means that PostgreSQL's request for a shared memory segment exceeded your kernel's SHMMAX parameter", and you'll have to adjust SHMMAX upward accordingly.

#Set shared memory max limit to 16GB
sysctl -w kernel.shmmax=17179869184
#Set shared memory min limit to 4MB
sysctl -w kernel.shmall=4194304


ps: make sure to add them to `/etc/sysctl.conf`
kernel.shmmax = 1073741824
kernel.shmall = 536870912


## Set Max open file descriptor
cat /proc/sys/fs/file-max
be sure it has more than 90K
as of writing it is
root@postgre0:~# cat /proc/sys/fs/file-max
2438914

#Set max open file descriptor
sysctl -w fs.file-max = 2438914

to set permenantly add it to `/etc/sysctl.conf`
fs.file-max = 2438914


# benchmarking
postgres@postgre0.sj.koding.com: /root$ pgbench -S -c 64 -j 8 -T 60 koding_social
starting vacuum...end.
transaction type: SELECT only
scaling factor: 1
query mode: simple
number of clients: 64
number of threads: 8
duration: 60 s
number of transactions actually processed: 3401530
tps = 56673.062177 (including connections establishing)
tps = 56747.809904 (excluding connections establishing)

-c should not be greater than the -s
-c should be multiple of -j
pgbench -c 16 -j 8 -r -s 32 -l -T 120  koding_social
