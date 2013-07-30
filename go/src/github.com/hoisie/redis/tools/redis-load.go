package main

import "bufio"
import "fmt"
import "net"
import "os"
import "strconv"

func load_db(port int, db int, reader *bufio.Reader) {
    addr := "127.0.0.1:6379"

    if port != 0 {
        addr = "127.0.0.1:" + strconv.Itoa(port)
    }

    c, err := net.Dial("tcp", "", addr)

    if err != nil {
        println(err.String())
        return
    }

    if db != 0 {
        fmt.Fprintf(c, "SELECT %d\r\n", db)
    }

    for {
        line, err := reader.ReadBytes('\n')
        if err == os.EOF {
            break
        }
        println(string(line))
        c.Write(line)
    }
    c.Write([]byte("QUIT\r\n"))
    buf := make([]byte, 512)

    for {
        n, err := c.Read(buf)
        if err != nil {
            break
        }
        println(string(buf[0:n]))
    }
}

func usage() { println("redis-load [-p port] [-db num]") }

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
    println("port", port, db)
    load_db(port, db, bufio.NewReader(os.Stdin))

}
