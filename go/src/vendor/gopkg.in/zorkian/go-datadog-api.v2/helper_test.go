/*
 * Datadog API for Go
 *
 * Please see the included LICENSE file for licensing information.
 *
 * Copyright 2017 by authors and contributors.
 */

package datadog_test

import (
	"testing"

	"encoding/json"
	"github.com/stretchr/testify/assert"
	"github.com/zorkian/go-datadog-api"
)

func TestHelperGetBoolSet(t *testing.T) {
	// Assert that we were able to get the boolean from a pointer field
	m := getTestMonitor()

	if attr, ok := datadog.GetBool(m.Options.NotifyNoData); ok {
		assert.Equal(t, true, attr)
	}
}

func TestHelperGetBoolNotSet(t *testing.T) {
	// Assert GetBool returned false for an unset value
	m := getTestMonitor()

	_, ok := datadog.GetBool(m.Options.NotifyAudit)
	assert.Equal(t, false, ok)
}

func TestHelperStringSet(t *testing.T) {
	// Assert that we were able to get the string from a pointer field
	m := getTestMonitor()

	if attr, ok := datadog.GetStringOk(m.Name); ok {
		assert.Equal(t, "Test monitor", attr)
	}
}

func TestHelperStringNotSet(t *testing.T) {
	// Assert GetString returned false for an unset value
	m := getTestMonitor()

	_, ok := datadog.GetStringOk(m.Message)
	assert.Equal(t, false, ok)
}

func TestHelperIntSet(t *testing.T) {
	// Assert that we were able to get the integer from a pointer field
	m := getTestMonitor()

	if attr, ok := datadog.GetIntOk(m.Id); ok {
		assert.Equal(t, 1, attr)
	}
}

func TestHelperIntNotSet(t *testing.T) {
	// Assert GetInt returned false for an unset value
	m := getTestMonitor()

	_, ok := datadog.GetIntOk(m.Options.RenotifyInterval)
	assert.Equal(t, false, ok)
}

func TestHelperGetJsonNumberSet(t *testing.T) {
	// Assert that we were able to get a JSON Number from a pointer field
	m := getTestMonitor()

	if attr, ok := datadog.GetJsonNumberOk(m.Options.Thresholds.Ok); ok {
		assert.Equal(t, json.Number(2), attr)
	}
}

func TestHelperGetJsonNumberNotSet(t *testing.T) {
	// Assert GetJsonNumber returned false for an unset value
	m := getTestMonitor()

	_, ok := datadog.GetJsonNumberOk(m.Options.Thresholds.Warning)

	assert.Equal(t, false, ok)
}

func getTestMonitor() *datadog.Monitor {

	o := &datadog.Options{
		NotifyNoData:    datadog.Bool(true),
		Locked:          datadog.Bool(false),
		NoDataTimeframe: 60,
		Silenced:        map[string]int{},
		Thresholds: &datadog.ThresholdCount{
			Ok: datadog.JsonNumber(json.Number(2)),
		},
	}

	return &datadog.Monitor{
		Query:   datadog.String("avg(last_15m):avg:system.disk.in_use{*} by {host,device} > 0.8"),
		Name:    datadog.String("Test monitor"),
		Id:      datadog.Int(1),
		Options: o,
		Type:    datadog.String("metric alert"),
		Tags:    make([]string, 0),
	}
}
