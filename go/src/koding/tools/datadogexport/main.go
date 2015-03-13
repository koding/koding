package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

type DatadogResp struct {
	Status       string   `json:"status"`
	ResponseType string   `json:"res_type"`
	From         float64  `json:"from_date"`
	To           float64  `json:"to_date"`
	Series       []Series `json:"series"`
}

type Series struct {
	Metric      string                 `json:"metric"`
	Attributes  map[string]interface{} `json:"attributes"`
	DisplayName string                 `json:"display_name"`
	Unit        []interface{}          `json:"unit"`
	Pointlist   [][]float64            `json:"pointlist"`
	End         float64                `json:"end"`
	Interval    float64                `json:"interval"`
	Start       float64                `json:"start"`
	Length      float64                `json:"length"`
	Aggr        string                 `json:"aggr"`
	Scope       string                 `json:"scope"`
	Expression  string                 `json:"expression"`
}

var queries = []string{
	"max:koding.monitoring.number_of_users_who_logged_in_today.gauge{*}.rollup(max,86400).as_count()",
	"max:koding.monitoring.all_daily_unique_visitor.gauge{*}.rollup(max,86400).as_count()/4",
	"max:koding.monitoring.all_monthly_unique_visitor.gauge{*}.rollup(max,86400).as_count()/2",
	"max:koding.monitoring.number_of_users_who_joined_today.gauge{*}.rollup(max,86400).as_count()",
	"max:koding.monitoring.registered_monthly_unique_visitor.gauge{*}.rollup(max,86400).as_count()*12",
	"max:koding.monitoring.number_of_messages_today.gauge{*}.rollup(max,86400).as_count()",
	"max:koding.monitoring.number_of_spun_up_vms_today.gauge{*}.as_count().rollup(max,86400)",
	"max:koding.monitoring.number_of_privatemessage_channels_today.gauge{*}.rollup(max,86400).as_count()",
	"max:koding.monitoring.number_of_running_vms_today.gauge{*}.rollup(max,86400).as_count()",
	"max:koding.monitoring.number_of_topic_channels_today.gauge{*}.rollup(max,86400).as_count()",
}

func main() {
	apiKey := *flag.String("apiKey", "6d3e00fb829d97cb6ee015f80063627c", "-apiKey <string>")
	appKey := *flag.String("appKey", "c9be251621bc75acf4cd040e3edea17fff17a13a", "-appKey <string>")
	duration := *flag.Duration("duration", time.Hour*24*30*3, "-duration <anything that time.Parse can parse>")
	flag.Parse()

	var writer *csv.Writer

	// cache the start date for using with all queries
	now := time.Now().UTC()

	for i, query := range queries {
		log.Println("Iterating over: ", query)

		csvfile, err := os.Create(strconv.Itoa(i) + ".csv")
		if err != nil {
			log.Println("Error while creating file, moving to next: ", err)
			continue
		}

		defer csvfile.Close()
		writer = csv.NewWriter(csvfile)

		// calculate the bottom date limit
		doomsDay := now.Add(-duration)

		// start from bottom, go up to current date
		for doomsDay.UnixNano() < now.UnixNano() {
			// local from
			from := doomsDay.Unix()

			// approach to current date
			doomsDay = doomsDay.Add(time.Hour * 24)

			// local from & to
			to := doomsDay.Unix()

			url := fmt.Sprintf(
				"https://app.datadoghq.com/api/v1/query?api_key=%s&application_key=%s&from=%d&to=%d&query=%s",
				apiKey,
				appKey,
				from,
				to,
				query,
			)

			resp, err := http.Get(url)
			if err != nil {
				log.Printf("er while get %s", err)
				continue
			}

			if resp.StatusCode != http.StatusOK {
				log.Printf("status code is not ok for %s", url)
				continue
			}

			ddr := &DatadogResp{}
			err = json.NewDecoder(resp.Body).Decode(ddr)
			if err != nil {
				log.Fatal(err)
			}

			if len(ddr.Series) == 0 {
				continue // no series found, just continue
			}

			for _, serie := range ddr.Series {
				for _, point := range serie.Pointlist {
					if err := writer.Write([]string{
						time.Unix(int64(point[0]/1000), 0).Format("2006-01-02T15:04:05.999Z"),
						strconv.FormatInt(int64(point[1]), 10),
					}); err != nil {
						log.Println("err while writing to csv-->", err)
					}
				}
			}
			writer.Flush()
		}
	}
}
