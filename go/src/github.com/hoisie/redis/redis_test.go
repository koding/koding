package redis

import (
    "encoding/json"
    "fmt"
    "reflect"
    "runtime"
    "strconv"
    "strings"
    "testing"
    "time"
)

const (
    // the timeout config property in redis.conf. used to test
    // connection retrying
    serverTimeout = 5
)

var client Client

func init() {
    runtime.GOMAXPROCS(2)
    client.Addr = "127.0.0.1:6379"
    client.Db = 13
}

func TestBasic(t *testing.T) {

    var val []byte
    var err error

    err = client.Set("a", []byte("hello"))

    if err != nil {
        t.Fatal("set failed", err.Error())
    }

    if val, err = client.Get("a"); err != nil || string(val) != "hello" {
        t.Fatal("get failed")
    }

    if typ, err := client.Type("a"); err != nil || typ != "string" {
        t.Fatal("type failed", typ)
    }

    //if keys, err := client.Keys("*"); err != nil || len(keys) != 1 {
    //    t.Fatal("keys failed", keys)
    //}

    client.Del("a")

    if ok, _ := client.Exists("a"); ok {
        t.Fatal("Should be deleted")
    }
}

func setget(t *testing.T, i int) {

    s := strconv.Itoa(i)
    err := client.Set(s, []byte(s))
    if err != nil {
        t.Fatal("Concurrent set", err.Error())
    }

    s2, err := client.Get(s)

    if err != nil {
        t.Fatal("Concurrent get", err.Error())
    }

    if s != string(s2) {
        t.Fatal("Concurrent: value not the same")
    }

    client.Del(s)
}

func TestEmptyGet(t *testing.T) {
    _, err := client.Get("failerer")

    if err == nil {
        t.Fatal("Expected an error")
    }
    client.Set("a", []byte("12"))

    vals, err := client.Mget("a", "b")

    if err != nil {
        t.Fatal(err.Error())
    }
    if vals[0] == nil || vals[1] != nil {
        t.Fatal("TestEmptyGet failed")
    }
}

func TestConcurrent(t *testing.T) {
    for i := 0; i < 20; i++ {
        go setget(t, i)
    }
}

func TestSet(t *testing.T) {
    var err error

    vals := []string{"a", "b", "c", "d", "e"}

    for _, v := range vals {
        client.Sadd("s", []byte(v))
    }

    var members [][]byte

    if members, err = client.Smembers("s"); err != nil || len(members) != 5 {
        if err != nil {
            t.Fatal("Set setup failed", err.Error())
        } else {
            t.Fatalf("Expected %d members but got %d", 5, len(members))
        }
    }

    for _, v := range vals {
        if ok, err := client.Sismember("s", []byte(v)); err != nil || !ok {
            t.Fatal("Sismember test failed")
        }
    }

    for _, v := range vals {
        if ok, err := client.Srem("s", []byte(v)); err != nil || !ok {
            t.Fatal("Sismember test failed")
        }
    }

    if members, err = client.Smembers("s"); err != nil || len(members) != 0 {
        if err != nil {
            t.Fatal("Set setup failed", err.Error())
        } else {
            t.Fatalf("Expected %d members but got %d", 0, len(members))
        }
    }

    client.Del("s")

}

func TestList(t *testing.T) {
    client.Del("l")
    vals := []string{"a", "b", "c", "d", "e"}

    for _, v := range vals {
        client.Rpush("l", []byte(v))
    }

    if l, err := client.Llen("l"); err != nil || l != 5 {
        if err != nil {
            t.Fatal("Llen failed", err.Error())
        } else {
            t.Fatal("Llen failed, list wrong length", l)
        }
    }

    for i := 0; i < len(vals); i++ {
        if val, err := client.Lindex("l", i); err != nil || string(val) != vals[i] {
            if err != nil {
                t.Fatal("Lindex failed", err.Error())
            } else {
                t.Fatalf("Expected %s but got %s", vals[i], string(val))
            }
        }
    }

    for i := 0; i < len(vals); i++ {
        if err := client.Lset("l", i, []byte("a")); err != nil {
            t.Fatal("Lset failed", err.Error())
        }
    }

    for i := 0; i < len(vals); i++ {
        if val, err := client.Lindex("l", i); err != nil || string(val) != "a" {
            if err != nil {
                t.Fatal("Lindex failed", err.Error())
            } else {
                t.Fatalf("Expected %s but got %s", "a", string(val))
            }
        }
    }
    client.Del("l")
}

func TestLrem(t *testing.T) {
    client.Del("l")
    vals := []string{"a", "b", "a"}

    for _, v := range vals {
        client.Rpush("l", []byte(v))
    }

    num, err := client.Lrem("l", 2, []byte("a"))

    if err != nil {
        t.Fatal("Lrem failed %v", err.Error())
    } else if num != 2 {
        t.Fatal("Lrem failed, got %d, expected 2", num)
    }

    length, err := client.Llen("l")
    if err != nil {
        t.Fatal("Llen failed", err.Error())
    } else if length != 1 {
        t.Fatal("Llen failed, got %v, expected 1", length)
    }
    client.Del("l")
}

func TestBrpop(t *testing.T) {
    go func() {
        time.Sleep(100 * 1000)
        if err := client.Lpush("l", []byte("a")); err != nil {
            t.Fatal("Lpush failed", err.Error())
        }
    }()
    key, value, err := client.Brpop([]string{"l"}, 1)
    if err != nil {
        t.Fatal("Brpop failed", err.Error())
    }
    if *key != "l" {
        t.Fatalf("Expected %s but got %s", "l", *key)
    }
    if string(value) != "a" {
        t.Fatalf("Expected %s but got %s", "a", string(value))
    }
}

func TestBlpop(t *testing.T) {
    go func() {
        time.Sleep(100 * 1000)
        if err := client.Lpush("l", []byte("a")); err != nil {
            t.Fatal("Lpush failed", err.Error())
        }
    }()
    key, value, err := client.Blpop([]string{"l"}, 1)
    if err != nil {
        t.Fatal("Blpop failed", err.Error())
    }
    if *key != "l" {
        t.Fatalf("Expected %s but got %s", "l", *key)
    }
    if string(value) != "a" {
        t.Fatalf("Expected %s but got %s", "a", string(value))
    }
}

func TestBrpopTimeout(t *testing.T) {
    key, value, err := client.Brpop([]string{"l"}, 1)
    if err != nil {
        t.Fatal("BrpopTimeout failed", err.Error())
    }
    if key != nil {
        t.Fatalf("Expected nil but got '%s'", *key)
    }
    if value != nil {
        t.Fatalf("Expected nil but got '%s'", value)
    }
}

func TestBlpopTimeout(t *testing.T) {
    key, value, err := client.Blpop([]string{"l"}, 1)
    if err != nil {
        t.Fatal("BlpopTimeout failed", err.Error())
    }
    if key != nil {
        t.Fatalf("Expected nil but got '%s'", *key)
    }
    if value != nil {
        t.Fatalf("Expected nil but got '%s'", value)
    }
}

/*

func TestSubscribe(t *testing.T) {
    subscribe := make(chan string, 0)
    unsubscribe := make(chan string, 0)
    psubscribe := make(chan string, 0)
    punsubscribe := make(chan string, 0)
    messages := make(chan Message, 0)

    defer func() {
        close(subscribe)
        close(unsubscribe)
        close(psubscribe)
        close(punsubscribe)
        close(messages)
    }()
    go func() {
        if err := client.Subscribe(subscribe, unsubscribe, psubscribe, punsubscribe, messages); err != nil {
            t.Fatal("Subscribed failed", err.String())
        }
    }()
    subscribe <- "ccc"

    data := []byte("foo")
    quit := make(chan bool, 0)
    defer close(quit)
    go func() {
        tick := time.Tick(10 * 1000 * 1000)     // 10ms
        timeout := time.Tick(100 * 1000 * 1000) // 100ms

        for {
            select {
            case <-quit:
                return
            case <-timeout:
                t.Fatal("TestSubscribe timeout")
            case <-tick:
                if err := client.Publish("ccc", data); err != nil {
                    t.Fatal("Pubish failed", err.String())
                }
            }
        }
    }()

    msg := <-messages
    quit <- true
    if msg.Channel != "ccc" {
        t.Fatal("Unexpected channel name")
    }
    if string(msg.Message) != string(data) {
        t.Fatalf("Expected %s but got %s", string(data), string(msg.Message))
    }
    close(subscribe)
}

func TestSimpleSubscribe(t *testing.T) {
    sub := make(chan string, 1)
    messages := make(chan Message, 0)
    go client.Subscribe(sub, nil, nil, nil, messages)

    sub <- "foo"
    time.Sleep(10 * 1000 * 1000) // 10ms
    data := "bar"
    client.Publish("foo", []byte(data))

    msg := <-messages
    if string(msg.Message) != data {
        t.Fatalf("Expected %s but got %s", data, string(msg.Message))
    }

    close(sub)
    close(messages)
}

func TestUnsubscribe(t *testing.T) {
    subscribe := make(chan string, 0)
    unsubscribe := make(chan string, 0)
    psubscribe := make(chan string, 0)
    punsubscribe := make(chan string, 0)
    messages := make(chan Message, 0)

    defer func() {
        close(subscribe)
        close(unsubscribe)
        close(psubscribe)
        close(punsubscribe)
        close(messages)
    }()
    go func() {
        if err := client.Subscribe(subscribe, unsubscribe, psubscribe, punsubscribe, messages); err != nil {
            t.Fatal("Subscribed failed", err.String())
        }
    }()
    subscribe <- "ccc"

    data := []byte("foo")
    quit := make(chan bool, 0)
    defer close(quit)
    go func() {
        tick := time.Tick(10 * 1000 * 1000) // 10ms

        for i := 0; i < 10; i++ {
            <-tick
            if err := client.Publish("ccc", data); err != nil {
                t.Fatal("Pubish failed", err.String())
            }
        }
        quit <- true
    }()

    msgs := 0
    for {
        select {
        case msg := <-messages:
            if string(msg.Message) != string(data) {
                t.Fatalf("Expected %s but got %s", string(data), string(msg.Message))
            }

            // Unsubscribe after first message
            if msgs == 0 {
                unsubscribe <- "ccc"
            }
            msgs++
        case <-quit:
            // Allow for a little delay and extra async messages getting through
            if msgs > 3 {
                t.Fatalf("Expected to have unsubscribed after 1 message but received %d", msgs)
            }
            return
        }
    }
}


func TestPSubscribe(t *testing.T) {
    subscribe := make(chan string, 0)
    unsubscribe := make(chan string, 0)
    psubscribe := make(chan string, 0)
    punsubscribe := make(chan string, 0)
    messages := make(chan Message, 0)

    defer func() {
        close(subscribe)
        close(unsubscribe)
        close(psubscribe)
        close(punsubscribe)
        close(messages)
    }()
    go func() {
        if err := client.Subscribe(subscribe, unsubscribe, psubscribe, punsubscribe, messages); err != nil {
            t.Fatal("Subscribed failed", err.String())
        }
    }()
    psubscribe <- "ccc.*"

    data := []byte("foo")
    quit := make(chan bool, 0)
    defer close(quit)
    go func() {
        tick := time.Tick(10 * 1000 * 1000)     // 10ms
        timeout := time.Tick(100 * 1000 * 1000) // 100ms

        for {
            select {
            case <-quit:
                return
            case <-timeout:
                t.Fatal("TestSubscribe timeout")
            case <-tick:
                if err := client.Publish("ccc.foo", data); err != nil {
                    t.Fatal("Pubish failed", err.String())
                }
            }
        }
    }()

    msg := <-messages
    quit <- true
    if msg.Channel != "ccc.foo" {
        t.Fatal("Unexpected channel name")
    }
    if msg.ChannelMatched != "ccc.*" {
        t.Fatal("Unexpected channel name")
    }
    if string(msg.Message) != string(data) {
        t.Fatalf("Expected %s but got %s", string(data), string(msg.Message))
    }
    close(subscribe)
}
*/
func verifyHash(t *testing.T, key string, expected map[string][]byte) {
    //test Hget
    m1 := make(map[string][]byte)
    for k := range expected {
        actual, err := client.Hget(key, k)
        if err != nil {
            t.Fatal("verifyHash Hget failed", err.Error())
        }
        m1[k] = actual
    }
    if !reflect.DeepEqual(m1, expected) {
        t.Fatal("verifyHash Hget failed")
    }

    //test Hkeys
    keys, err := client.Hkeys(key)
    if err != nil {
        t.Fatal("verifyHash Hkeys failed", err.Error())
    }
    if len(keys) != len(expected) {
        fmt.Printf("%v\n", keys)
        t.Fatal("verifyHash Hkeys failed - length not equal")
    }
    for _, key := range keys {
        if expected[key] == nil {
            t.Fatal("verifyHash Hkeys failed missing key", key)
        }
    }

    //test Hvals
    vals, err := client.Hvals(key)
    if err != nil {
        t.Fatal("verifyHash Hvals failed", err.Error())
    }
    if len(vals) != len(expected) {
        t.Fatal("verifyHash Hvals failed")
    }

    m2 := map[string][]byte{}
    //test Hgetall
    err = client.Hgetall(key, m2)
    if err != nil {
        t.Fatal("verifyHash Hgetall failed", err.Error())
    }
    if !reflect.DeepEqual(m2, expected) {
        t.Fatal("verifyHash Hgetall failed")
    }
}

func TestSortedSet(t *testing.T) {
    svals := []string{"a", "b", "c", "d", "e"}
    ranks := []float64{0.0, 1.0, 2.0, 3.0, 4.0}
    vals := make([][]byte, len(svals))
    for i := 0; i < len(svals); i++ {
        vals[i] = []byte(svals[i])
        _, err := client.Zadd("zs", vals[i], ranks[i])
        if err != nil {
            t.Fatal("zdd failed" + err.Error())
        }
        score, err := client.Zscore("zs", vals[i])
        if err != nil {
            t.Fatal("zscore failed" + err.Error())
        }
        if score != ranks[i] {
            t.Fatal("zscore failed")
        }
    }

    card, err := client.Zcard("zs")
    if err != nil {
        t.Fatal("zcard failed" + err.Error())
    }
    if card != 5 {
        t.Fatal("zcard failed", card)
    }
    for i := 0; i <= 4; i++ {
        data, _ := client.Zrange("zs", 0, i)
        if !reflect.DeepEqual(data, vals[0:i+1]) {
            t.Fatal("zrange failed")
        }
    }
    for i := 0; i <= 4; i++ {
        data, _ := client.Zrangebyscore("zs", 0, float64(i))
        if !reflect.DeepEqual(data, vals[0:i+1]) {
            t.Fatal("zrangebyscore failed")
        }
    }
    //incremement
    for i := 0; i <= 4; i++ {
        client.Zincrby("zs", vals[i], 1)

        score, err := client.Zscore("zs", vals[i])
        if err != nil {
            t.Fatal("zscore failed" + err.Error())
        }
        if score != ranks[i]+1 {
            t.Fatal("zscore failed")
        }
    }

    for i := 0; i <= 4; i++ {
        client.Zincrby("zs", vals[i], -1)
    }

    //clean up
    _, err = client.Zrem("zs", []byte("a"))
    if err != nil {
        t.Fatal("zrem failed" + err.Error())
    }

    _, err = client.Zremrangebyrank("zs", 0, 1)
    if err != nil {
        t.Fatal("zremrangebynrank failed" + err.Error())
    }

    _, err = client.Zremrangebyscore("zs", 3, 4)
    if err != nil {
        t.Fatal("zremrangebyscore failed" + err.Error())
    }

    card, err = client.Zcard("zs")
    if err != nil {
        t.Fatal("zcard failed" + err.Error())
    }
    if card != 0 {
        t.Fatal("zcard failed", card)
    }

    client.Del("zs")
}

type tt struct {
    A, B, C, D, E string
}

func TestHash(t *testing.T) {
    //test cast
    keys := []string{"a", "b", "c", "d", "e"}
    test := make(map[string][]byte)
    for _, v := range keys {
        test[v] = []byte(strings.Repeat(v, 5))
    }

    //set with hset
    for k, v := range test {
        client.Hset("h", k, []byte(v))
    }
    //test hset
    verifyHash(t, "h", test)

    //set with hmset
    client.Hmset("h2", test)
    //test hset
    verifyHash(t, "h2", test)

    test3 := tt{"aaaaa", "bbbbb", "ccccc", "ddddd", "eeeee"}

    client.Hmset("h3", test3)
    //verifyHash(t, "h3", test)

    var test4 tt
    //test Hgetall
    err := client.Hgetall("h3", &test4)
    if err != nil {
        t.Fatal("verifyHash Hgetall failed", err.Error())
    }
    if !reflect.DeepEqual(test4, test3) {
        t.Fatal("verifyHash Hgetall failed")
    }

    //text extraneous fields
    client.Hset("h3", "f", []byte("ffffff"))
    var test5 tt
    err = client.Hgetall("h3", &test5)
    if err != nil {
        t.Fatal("verifyHash Hgetall failed", err.Error())
    }
    if !reflect.DeepEqual(test5, test3) {
        t.Fatal("verifyHash Hgetall failed")
    }

    err = client.Hgetall("hdne", &test5)
    if err == nil {
        t.Fatal("should be an error")
    }

    test6 := make(map[string]interface{})
    for _, v := range keys {
        test6[v] = []byte(strings.Repeat(v, 5))
    }
    client.Hmset("h4", test6)

    //test Hgetall
    test7 := make(map[string]interface{})
    err = client.Hgetall("h4", &test7)
    if err != nil {
        t.Fatal("verifyHash Hgetall failed", err.Error())
    }
    if !reflect.DeepEqual(test6, test7) {
        t.Fatal("verifyHash Hgetall failed")
    }

    client.Del("h")
    client.Del("h2")
    client.Del("h3")
    client.Del("h4")
}

func TestHmset(t *testing.T) {
    m := make(map[string][]byte)
    m["foo"] = []byte("1")
    client.Hmset("f", m)
    data,err := client.Hmget("f", "foo")
    if err != nil {
        t.Fatal("Hmset failed", err.Error())
    }
    if string(data[0][0]) != "1" {
        t.Fatalf("Expected 1, got %s", string(data[0][0]));
    }
    client.Del("foo")
}

func BenchmarkMultipleGet(b *testing.B) {
    client.Set("bmg", []byte("hi"))
    for i := 0; i < b.N; i++ {
        client.Get("bmg")
    }
    client.Del("bmg")
}

func BenchmarkMGet(b *testing.B) {
    client.Set("bmg", []byte("hi"))
    var vals []string
    for i := 0; i < b.N; i++ {
        vals = append(vals, "bmg")
    }
    client.Mget(vals...)
    client.Del("bmg")
}

type testType struct {
    A, B, C string
    D, E, F int64
}

var testObj = testType{"A", "B", "C", 1, 2, 3}

func BenchmarkJsonSet(b *testing.B) {
    for i := 0; i < b.N; i++ {
        data, _ := json.Marshal(testObj)
        client.Set("tjs", data)
    }
    client.Del("tjs")
}

func BenchmarkHmset(b *testing.B) {
    for i := 0; i < b.N; i++ {
        client.Hmset("tjs", testObj)
    }
    client.Del("tjs")
}

func BenchmarkJsonGet(b *testing.B) {
    data, _ := json.Marshal(testObj)
    client.Set("tjs", data)

    for i := 0; i < b.N; i++ {
        var tt testType
        data, _ := client.Get("tjs")
        json.Unmarshal(data, &tt)
    }
    client.Del("tjs")
}

func BenchmarkHgetall(b *testing.B) {
    client.Hmset("tjs", testObj)
    for i := 0; i < b.N; i++ {
        var tt testType
        client.Hgetall("tjs", &tt)
    }
    client.Del("tjs")
}

func BenchmarkJsonMget(b *testing.B) {
    od, _ := json.Marshal(testObj)
    client.Set("tjs", od)

    var vals []string
    for i := 0; i < b.N; i++ {
        vals = append(vals, "tjs")
    }

    data, _ := client.Mget(vals...)
    for _, val := range data {
        var tt testType
        json.Unmarshal(val, &tt)
    }

    client.Del("tjs")
}

func BenchmarkHset(b *testing.B) {
    client.Hmset("tjs", testObj)
    for i := 0; i < b.N; i++ {
        client.Hset("tjs", "a", []byte("z"))
    }
    client.Del("tjs")
}

func BenchmarkJsonFieldSet(b *testing.B) {
    data, _ := json.Marshal(testObj)
    client.Set("tjs", data)

    for i := 0; i < b.N; i++ {
        var tt testType
        data, _ := client.Get("tjs")
        json.Unmarshal(data, &tt)
        tt.A = "z"
        data, _ = json.Marshal(tt)
        client.Set("tjs", data)
    }
    client.Del("tjs")
}

func BenchmarkZadd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        client.Zadd("zrs", []byte("hi"+strconv.Itoa(i)), float64(i))
    }
    client.Del("zrs")
}

func BenchmarkRpush(b *testing.B) {
    for i := 0; i < b.N; i++ {
        client.Rpush("zrs", []byte("hi"+strconv.Itoa(i)))
    }
    client.Del("zrs")
}

/*
func TestTimeout(t *testing.T) {
    client.Set("a", []byte("hello world"))

	time.Sleep((serverTimeout+10) * 1e9)
    val, err := client.Get("a")

    if err != nil {
        t.Fatal(err.String())
    }

    println(string(val))
}
*/
