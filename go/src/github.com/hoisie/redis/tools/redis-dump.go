package main

import (
    "fmt"
    "io"
    "os"
    "redis"
    "strconv"
)

func dump_db(port int, db int, output io.Writer) {
    var client redis.Client

    if port != 0 {
        client.Addr = "127.0.0.1:" + strconv.Itoa(port)
    }

    if db != 0 {
        client.Db = db
    }

    fmt.Fprintf(output, "FLUSHDB\r\n")

    keys, err := client.Keys("*")

    if err != nil {
        println("Redis-dump failed", err.String())
        return
    }

    for _, key := range keys {
        typ, _ := client.Type(key)

        if typ == "string" {
            data, _ := client.Get(key)
            fmt.Fprintf(output, "SET %s %d\r\n%s\r\n", key, len(data), data)
        } else if typ == "list" {
            llen, _ := client.Llen(key)
            for i := 0; i < llen; i++ {
                data, _ := client.Lindex(key, i)
                fmt.Fprintf(output, "RPUSH %s %d\r\n%s\r\n", key, len(data), data)
            }
        } else if typ == "set" {
            members, _ := client.Smembers(key)
            for _, data := range members {
                fmt.Fprintf(output, "SADD %s %d\r\n%s\r\n", key, len(data), data)
            }
        }
    }

}

func usage() { println("redis-dump [-p port] [-db num]") }

func main() {

    var err os.Error

    db := 0
    port := 6379

    args := os.Args[1:]

    for i := 0; i < len(args); i++ {
        arg := args[i]
        if arg == "-p" && i < len(args)-1 {
            if port, err = strconv.Atoi(args[i+1]); err != nil {
                println(err.String())
                return
            }
            i += 1
            continue
        } else if arg == "-db" && i < len(args)-1 {
            if db, err = strconv.Atoi(args[i+1]); err != nil {
                println(err.String())
                return
            }
            i += 1
            continue
        } else {
            println("Invalid argument: ", arg)
            usage()
            return
        }
    }

    dump_db(port, db, os.Stdout)
}
