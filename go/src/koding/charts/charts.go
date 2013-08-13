package main

import (
	"html/template"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"os"
	"time"
)

const week = time.Duration(int64(time.Hour) * 24 * 7)

func main() {
	session, err := mgo.Dial("dev:k9lc4G1k32nyD72@kmongodb1.in.koding.com:27017")
	if err != nil {
		panic(err)
	}

	start := time.Date(2012, 4, 2, 0, 0, 0, 0, time.UTC)
	end := time.Now()
	values := make([]int, end.Sub(start)/week+1)

	var user struct {
		RegisteredAt time.Time `bson:"registeredAt"`
	}
	iter := session.DB("koding").C("jUsers").Find(bson.M{"username": bson.M{"$not": bson.RegEx{Pattern: "^guest-"}}}).Select(bson.M{"registeredAt": 1}).Iter()
	for iter.Next(&user) {
		index := user.RegisteredAt.Sub(start) / week
		if index < 0 {
			index = 0
		}
		values[index] += 1
	}
	if err := iter.Close(); err != nil {
		panic(err)
	}

	labels := make([]string, len(values))
	total := 0
	for i, v := range values {
		total += v
		values[i] = total

		if i%5 == 0 {
			labels[i] = start.Add(time.Duration(i) * week).Format("2006-01-02")
		}
	}

	f, err := os.Create("charts.html")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	t, err := template.ParseFiles("templates/charts/template.html")
	if err != nil {
		panic(err)
	}
	if err := t.Execute(f, map[string]interface{}{"labels": labels, "values": values}); err != nil {
		panic(err)
	}
}
