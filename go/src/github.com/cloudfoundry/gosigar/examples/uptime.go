// Copyright (c) 2012 VMware, Inc.

package main

import (
	"fmt"
	"github.com/cloudfoundry/gosigar"
	"os"
	"time"
)

func main() {
	uptime := sigar.Uptime{}
	uptime.Get()
	avg := sigar.LoadAverage{}
	avg.Get()

	fmt.Fprintf(os.Stdout, " %s up %s load average: %.2f, %.2f, %.2f\n",
		time.Now().Format("15:04:05"),
		uptime.Format(),
		avg.One, avg.Five, avg.Fifteen)
}
