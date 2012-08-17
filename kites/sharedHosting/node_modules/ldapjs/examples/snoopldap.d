#!/usr/sbin/dtrace -s

#pragma D option quiet

BEGIN
{
    printf("%-8s %-8s %-16s %-15s %-15s %s\n",
        "LATENCY", "OPTYPE", "REMOTE IP", "BIND DN", "REQ DN",
        "STATUS");
}

ldapjs*:::server-*-start
{
    starts[arg0] = timestamp;
}

ldapjs*:::server-*-done
/starts[arg0]/
{
    printf("%6dms %-8s %-16s %-15s %-15s %d\n",
        (timestamp - starts[arg0]) / 1000000, strtok(probename + 7, "-"),
        copyinstr(arg1), copyinstr(arg2), copyinstr(arg3), arg4); 
    starts[arg0] = 0;
}
