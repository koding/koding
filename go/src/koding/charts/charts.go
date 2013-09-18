package main

import (
	"html/template"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"os"
	"time"
)

const interval = time.Duration(int64(time.Hour) * 24 * 7)

func main() {
	start := time.Date(2012, 4, 2, 0, 0, 0, 0, time.UTC)
	end := time.Now()
	data := make([]int, end.Sub(start)/interval)

	var user struct {
		RegisteredAt time.Time `bson:"registeredAt"`
	}

	iter := new(mgo.Iter)
	query := func(c *mgo.Collection) error {
		iter = c.Find(bson.M{"username": bson.M{"$not": bson.RegEx{Pattern: "^guest-"}}}).Select(bson.M{"registeredAt": 1}).Iter()
		return nil
	}
	mongodb.Run("jUsers", query)

	for iter.Next(&user) {
		index := int(user.RegisteredAt.Sub(start) / interval)
		if index < 0 {
			index = 0
		}
		if index >= len(data) {
			continue
		}
		data[index] += 1
	}
	if err := iter.Close(); err != nil {
		panic(err)
	}

	values := make([]int, len(data))
	labels := make([]string, len(data))
	total := 0
	for i := range data {
		total += data[i]
		values[i] = total
		// if i > 2 {
		// 	values[i] = data[i] - data[i-1]
		// }

		if i%5 == 0 {
			labels[i] = start.Add(time.Duration(i) * interval).Format("2006-01-02")
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
