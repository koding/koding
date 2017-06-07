package metrics

import (
	"fmt"
	"os"
	"strings"

	datadog "gopkg.in/zorkian/go-datadog-api.v2"
)

type metricStorage struct {
	name string
}

var (
	allMetrics   = make(map[string][]metricStorage)
	isCollecting = os.Getenv("GENERATE_DATADOG_DASHBOARD") != ""
)

func register(parent, name string) {
	if !isCollecting {
		return
	}

	// Prevent duplicates.
	for _, ms := range allMetrics[parent] {
		if ms.name == name {
			return
		}
	}

	allMetrics[parent] = append(allMetrics[parent], metricStorage{
		name: name,
	})
}

// CreateMetricsDash creates the dashboard for the globally registered metrics.
func CreateMetricsDash() {
	apiKey := os.Getenv("DATADOG_API_KEY")
	appKey := os.Getenv("DATADOG_APP_KEY")

	if apiKey == "" || appKey == "" {
		panic("DATADOG_API_KEY and DATADOG_APP_KEY should be set.")
	}

	client := datadog.NewClient(apiKey, appKey)

	for parent, metrics := range allMetrics {
		parentName := strings.Replace(parent, "_", "", -1)
		dd := &datadog.Dashboard{
			Description: ptrToStr("Dashboard for " + parentName),
			Title:       ptrToStr("Dashboard for " + parentName),
		}

		for _, metric := range metrics {
			metricName := strings.Replace(metric.name, "_", "", -1)

			dd.Graphs = append(dd.Graphs, datadog.Graph{
				Title: ptrToStr(strings.Title(parentName) + " " + strings.Title(metricName)),
				Definition: &datadog.GraphDefinition{
					Viz:       ptrToStr("timeseries"),
					Autoscale: ptrToBool(true),
					Requests: []datadog.GraphDefinitionRequest{
						{
							Query:      ptrToStr(fmt.Sprintf("avg:%s%s_call_count{*}.as_count()", parent, metric.name)),
							Aggregator: ptrToStr("avg"),
							Type:       ptrToStr("bars"),
						},
						{
							Query: ptrToStr(fmt.Sprintf("avg:%s%s_timing.avg{*}", parent, metric.name)),
							Type:  ptrToStr("line"),
						},
						{
							Query: ptrToStr(fmt.Sprintf("avg:%s%s_timing.max{*}", parent, metric.name)),
							Type:  ptrToStr("line"),
						},
						{
							Query: ptrToStr(fmt.Sprintf("avg:%s%s_timing.median{*}", parent, metric.name)),
							Type:  ptrToStr("line"),
						},
						{
							Query: ptrToStr(fmt.Sprintf("avg:%s%s_timing.95percentile{*}", parent, metric.name)),
							Type:  ptrToStr("line"),
						},
					},
				},
			})
		}

		dash, err := client.CreateDashboard(dd)
		if err != nil {
			fmt.Println("err while creating dasboard for ", parent, err.Error())
			return
		}
		fmt.Println("dashboard id -->", dash.GetId())
	}
}

func ptrToStr(s string) *string { return &s }
func ptrToBool(s bool) *bool    { return &s }
