package redis

import (
	"fmt"
	"testing"
	"time"

	"github.com/garyburd/redigo/redis"
)

var (
	session *RedisSession
	prefix  string
)

func init() {
	var err error
	conf := &RedisConf{Server: "localhost:6379"}
	session, err = NewRedisSession(conf)
	if err != nil {
		panic(fmt.Sprintf("Could not start redis: %s", err))
	}
	prefix = "testing"
	// defer session.Close()
}

func TestPrefix(t *testing.T) {
	session.SetPrefix(prefix)
	key := session.AddPrefix("muppets")
	if key != "testing:muppets" {
		t.Errorf("Key must be formed correctly")
	}
}

func TestServerConnection(t *testing.T) {
	reply, err := session.Do("PING")
	if err != nil {
		panic(fmt.Sprintf("No response from redis: %s", err))
	}

	response, _ := session.String(reply)
	if response != "PONG" {
		t.Errorf("Wrong server response: %s", response)
	}
}

func TestKeyValue(t *testing.T) {
	err := session.Set("gonzo", "the great")
	if err != nil {
		t.Errorf("Could not set value of key: %s", err)
	}

	response, err := session.Get("gonzo")
	if err != nil {
		t.Errorf("Could not get value of key ", err)
	}
	if response != "the great" {
		t.Error("Value did not match")
	}
}

func TestKeyIntValue(t *testing.T) {
	err := session.Set("bertsfavouritenumber", "6")
	if err != nil {
		t.Errorf("Could not set value of key: %s", err)
	}
	response, err := session.GetInt("bertsfavouritenumber")
	if err != nil {
		t.Errorf("Could not get value of key: %s", err)
	}
	if response != 6 {
		t.Error("Value did not match: %s received", response)
	}

	err = session.Set("bertsfavouriteletter", "a")
	if err != nil {
		t.Errorf("Could not set value of key: %s", err)
	}

	response, err = session.GetInt("bertsfavouriteletter")
	if err == nil {
		t.Errorf("Error was expected: %s", err)
	}
	if response != 0 {
		t.Error("0 was expected as response, but got %d", response)
	}

	session.Del("bertsfavouriteletter")
}

func TestDeleteKey(t *testing.T) {
	response, err := session.Del("gonzo")
	if err != nil {
		t.Errorf("Could not delete key: %s", err)
	}
	if response == 0 {
		t.Errorf("Key not found")
		return
	}
	if response != 1 {
		t.Errorf("Deleted key count is not correct")
	}
}

func TestIncrement(t *testing.T) {
	response, err := session.Incr("bertsfavouritenumber")
	if err != nil {
		t.Errorf("Could not increment value of the key: %s", err)
	}
	if response != 7 {
		t.Errorf("Could not increment value correctly")
	}
}

func TestExpire(t *testing.T) {
	err := session.Expire("bertsfavouritenumber", 100*time.Millisecond)
	if err != nil {
		t.Errorf("Could not set expire date of the key: %s", err)
	}
	time.Sleep(100 * time.Millisecond)
	_, err = session.Get("bertsfavouritenumber")
	if err != nil && err != redis.ErrNil {
		t.Errorf("Could not get value of the key: %s", err)
	}
}

func TestTTL(t *testing.T) {
	key := "rainbow"
	_, err := session.TTL(key)
	if err == nil {
		t.Errorf("Expected %s error but got nil", ErrTTLNotSet)
	}

	err = session.Set(key, "connection")
	if err != nil {
		t.Errorf("Could not set value of key: %s", err)
		t.FailNow()
	}
	defer session.Del(key)

	err = session.Expire(key, 1*time.Second)
	if err != nil {
		t.Errorf("Could not set expire date of the key: %s", err)
		t.FailNow()
	}

	ttl, err := session.TTL(key)
	if err != nil {
		t.Errorf("Could not get TTL value of the key: %s", err)
		t.FailNow()
	}

	if ttl.Seconds() > 1 || ttl.Seconds() < 0 {
		t.Errorf("Expected TTL between 0 and 1 but got: %d", ttl.Seconds())
	}
}

func TestSetWithExpire(t *testing.T) {
	err := session.Setex("swedish", 1*time.Second, "chef")
	if err != nil {
		t.Errorf("Could not set key with expire date: %s", err)
	}
	time.Sleep(1 * time.Second)
	_, err = session.Get("swedish")
	if err != nil && err != redis.ErrNil {
		t.Errorf("Could not get value of the key: %s", err)
	}
}

func TestKeyExistence(t *testing.T) {
	response := session.Exists("oscar")
	if response {
		t.Errorf("Key must not exist")
	}
	err := session.Set("oscar", "the grouch")
	if err != nil {
		t.Errorf("Could not set value of key: %s", err)
	}

	response = session.Exists("oscar")
	if !response {
		t.Errorf("Key must exist")
	}
	session.Del("oscar")
}

func TestPing(t *testing.T) {
	if err := session.Ping(); err != nil {
		t.Errorf("Server did not respond: %s", err)
	}
}

func TestAddSetMember(t *testing.T) {
	members := []interface{}{"janice", "floyd", "animal", "drteeth", "zoot"}
	response, err := session.AddSetMembers("electricmayhem", members...)
	if err != nil {
		t.Errorf("Could not add set members: %s", err)
	}
	if response != 5 {
		t.Errorf("Wrong set member return count: %d", response)
	}
}

func TestGetSetMember(t *testing.T) {
	members, err := session.GetSetMembers("electricmayhem")
	if err != nil {
		t.Errorf("Could not get set members: %s", err)
	}
	if len(members) != 5 {
		t.Errorf("Wrong set member count: %d", len(members))
	}
	found := false
	for i := range members {
		member, _ := session.String(members[i])
		if member == "janice" {
			found = true
			break
		}
	}

	if !found {
		t.Errorf("Member not found")
	}
}

func TestSetMemberCount(t *testing.T) {
	count, err := session.Scard("electricmayhem")
	if err != nil {
		t.Errorf("Could not get set member count: %s", err)
	}
	if count != 5 {
		t.Errorf("Wrong member count: %d", count)
	}
}

func TestRemoveSetMembers(t *testing.T) {
	response, err := session.RemoveSetMembers("electricmayhem", "janice")
	if err != nil {
		t.Errorf("Could not remove element from set: %s", err)
	}
	if response != 1 {
		t.Errorf("Wrong set member count: %d", response)
	}
	members, _ := session.GetSetMembers("electricmayhem")
	if len(members) != 4 {
		t.Errorf("Wrong remaining member count: %d", len(members))
	}
}

func TestIsSetMember(t *testing.T) {
	response, err := session.IsSetMember("electricmayhem", "statler")
	if err != nil {
		t.Errorf("Could not check member existence: %s", err)
	}
	if response != 0 {
		t.Errorf("Expected 0 but got %d", response)
	}

	response, err = session.IsSetMember("electricmayhem", "animal")
	if err != nil {
		t.Errorf("Could not check member existence: %s", err)
	}
	if response != 1 {
		t.Errorf("Expected 1 but got %d", response)
	}
}

func TestPopSetMember(t *testing.T) {
	response, err := session.PopSetMember("electricmayhem")
	if err != nil {
		t.Errorf("Could not pop element from set: %s", err)
	}
	members := []string{"floyd", "animal", "drteeth", "zoot"}
	found := false
	for i := range members {
		if members[i] == response {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Popped element does not belong to the set: %s", response)
	}
}

func TestKeys(t *testing.T) {
	keys, err := session.Keys("*")
	if err != nil {
		t.Errorf("Could not fetch keys: %s", err)
	}

	if len(keys) != 1 {
		t.Errorf("Wrong key count: %d", len(keys))
		session.Del("electricmayhem")
		return
	}

	key, _ := session.String(keys[0])
	if key != "testing:electricmayhem" {
		t.Errorf("Wrong key: %s", key)
	}

	session.Del("electricmayhem")
}

func TestHashSet(t *testing.T) {
	_, err := session.HashSet("mayhem", "janice", "guitar")
	if err != nil {
		t.Errorf("Could create hash set: %v", err)
		return
	}
	defer session.Del("mayhem")

	reply, err := session.GetHashSetField("mayhem", "janice")
	if err != nil {
		t.Errorf("Could not get hash set length: %v", err)
		return
	}

	if reply != "guitar" {
		t.Errorf("Wrong hashset value of the element: %s", reply)
	}
}

func TestHashMultipleSet(t *testing.T) {
	item := map[string]interface{}{
		"janice":  "guitar",
		"floyd":   "bass",
		"drteeth": "keyboard",
		"animal":  "drums",
		"zoot":    "sax",
	}
	err := session.HashMultipleSet("mayhem", item)
	if err != nil {
		t.Errorf("Could create hash set: %s", err)
		return
	}
	defer session.Del("mayhem")

	length, err := session.GetHashLength("mayhem")
	if err != nil {
		t.Errorf("Could not get hash set length: %s", err)
		return
	}

	if length != len(item) {
		t.Errorf("Expected %d but got %d as hash length: ", len(item), length)
	}

	reply, err := session.GetHashMultipleSet("mayhem", "zoot")
	if err != nil {
		t.Errorf("Could not get hash set: %s", err)
		return
	}

	if len(reply) != 1 {
		t.Errorf("Wrong return value count: %d", len(reply))
		return
	}

	response, _ := session.String(reply[0])
	if response != "sax" {
		t.Errorf("Wrong hashset value of the element: %s", response)
	}

	value, err := session.GetHashSetField("mayhem", "zoot")
	if err != nil {
		t.Errorf("Could not get hash set field value: %s", err)
	}

	if value != "sax" {
		t.Errorf("Wrong hashset field value: %s", err)
	}

	result, err := session.HashSetIfNotExists("mayhem", "janice", "ukulele")
	if err != nil {
		t.Errorf("Could not set hash field: %s", err)
	}

	if result != false {
		t.Error("Expected false from hash set but got true")
	}

	result, err = session.HashSetIfNotExists("mayhem", "kermit", "frog")
	if err != nil {
		t.Errorf("Could not set hash field: %s", err)
	}

	if result != true {
		t.Error("Expected true from hash set but got false")
	}

	deleteCount, err := session.DeleteHashSetField("mayhem", "kermit")
	if err != nil {
		t.Errorf("Could not delete hash field: %s", err)
	}

	if deleteCount != 1 {
		t.Errorf("Expected 1 but got %d from hash set field deletion", deleteCount)
	}

	length, err = session.GetHashLength("mayhem")
	if err != nil {
		t.Errorf("Could not get hash set length: %s", err)
	}

	if length != len(item) {
		t.Errorf("Expected %d but got %d as hash length: ", len(item), length)
	}
}

func TestSortedSet(t *testing.T) {
	set1Key, set2Key, destination := "set1", "set2", "combined-set"

	defer func() {
		session.Del(set1Key)
		session.Del(set2Key)
		session.Del(destination)
	}()

	_, err := session.SortedSetIncrBy(set1Key, 1, "item1")
	if err != nil {
		t.Fatalf("Error creating set1", err)
	}

	_, err = session.SortedSetIncrBy(set2Key, 1, "item2")
	if err != nil {
		t.Fatalf("Error creating set2", err)
	}

	keys := []string{set1Key, set2Key}
	weights := []interface{}{1, 1}

	reply, err := session.SortedSetsUnion(destination, keys, weights, "SUM")
	if err != nil {
		t.Fatalf("Error creating combined sets", err)
	}

	if reply < 2 {
		t.Fatalf("Wrong number of elements added to combined set", err, reply)
	}

	score, err := session.SortedSetScore(destination, "item1")
	if err != nil {
		t.Fatalf("Couldn't get score of item from sorted set: %s", err)
	}

	if score != 1 {
		t.Fatalf("Wrong number of elements added to combined set", err, reply)
	}

	_, err = session.SortedSetRem(destination, "item1")
	if err != nil {
		t.Fatalf("Couldn't remove item from sorted set: %s", err)
	}

	_, err = session.SortedSetScore(destination, "item1")
	if err == nil {
		t.Fatalf("Didn't remove item from sorted set")
	}

	err = session.SortedSetAddSingle(destination, "item1", 1)
	if err != nil {
		t.Fatalf("Couldn't remove item from sorted set: %s", err)
	}

	score, err = session.SortedSetScore(destination, "item1")
	if err != nil {
		t.Fatal(err)
	}

	if score != 1 {
		t.Fatalf("Didn't set score for item in sorted set")
	}

	scores, err := session.SortedSetRangebyScore(destination, NegativeInf, PositiveInf)
	if err != nil {
		t.Fatal(err)
	}

	if len(scores) != 2 {
		t.Fatalf("Wrong length of results when ranging by scores in sorted set")
	}
}
