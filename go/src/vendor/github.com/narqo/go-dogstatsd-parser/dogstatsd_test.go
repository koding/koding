package dogstatsd_test

import (
	"reflect"
	"testing"

	"github.com/narqo/go-dogstatsd-parser"
)

type MetricTest struct {
	in  string
	out *dogstatsd.Metric
}

var parseMetricsTests = []MetricTest{
	// increment the page.views counter
	{
		"page.views:1|c",
		&dogstatsd.Metric{
			Name: "page.views",
			Value: int64(1),
			Type: dogstatsd.Counter,
			Rate: 1,
		},
	},
	// record the fuel tank is half-empty
	{
		"fuel.level:0.5|g",
		&dogstatsd.Metric{
			Name: "fuel.level",
			Value: float64(0.5),
			Type: dogstatsd.Gauge,
			Rate: 1,
		},
	},
	// amount of time used to get data
	{
		"data.get.time:102|ms",
		&dogstatsd.Metric{
			Name: "data.get.time",
			Value: float64(102),
			Type: dogstatsd.Timer,
			Rate: 1,
		},
	},
	// sample a the song length histogram half of the time
	{
		"song.length:240|h|@0.5",
		&dogstatsd.Metric{
			Name: "song.length",
			Value: float64(240),
			Type: dogstatsd.Histogram,
			Rate: 0.5,
		},
	},
	// track a unique visitor to the site.
	{
		"users.uniques:1234|s",
		&dogstatsd.Metric{
			Name: "users.uniques",
			Value: "1234",
			Type: dogstatsd.Set,
			Rate: 1,
		},
	},
	// increment the users online counter tagged by country of origin
	{
		"users.online:1|c|#country:china",
		&dogstatsd.Metric{
			Name: "users.online",
			Value: int64(1),
			Type: dogstatsd.Counter,
			Rate: 1,
			Tags: map[string]string{
				"country": "china",
			},
		},
	},
	// putting it all together
	{
		"users.online:1|c|@0.5|#country:china,city:beijing,cur",
		&dogstatsd.Metric{
			Name: "users.online",
			Value: int64(1),
			Type: dogstatsd.Counter,
			Rate: 0.5,
			Tags: map[string]string{
				"country": "china",
				"city": "beijing",
				"cur": "",
			},
		},
	},
	// various degradation cases
	{
		"a.key.with-0.dash:4|c",
		&dogstatsd.Metric{
			Name: "a.key.with-0.dash",
			Value: int64(4),
			Type: dogstatsd.Counter,
			Rate: 1,
		},
	},
	{
		"gossip:0.008994|ms",
		&dogstatsd.Metric{
			Name: "gossip",
			Value: float64(0.008994),
			Type: dogstatsd.Timer,
			Rate: 1,
		},
	},
	{
		"udp.sent:61.000000|c",
		&dogstatsd.Metric{
			Name: "udp.sent",
			Value: int64(61),
			Type: dogstatsd.Counter,
			Rate: 1,
		},
	},
	{
		"queue.Intent:0.000000|ms",
		&dogstatsd.Metric{
			Name: "queue.Intent",
			Value: float64(0.0),
			Type: dogstatsd.Timer,
			Rate: 1,
		},
	},
	{
		"runtime.alloc_bytes:1780136.000000|g",
		&dogstatsd.Metric{
			Name: "runtime.alloc_bytes",
			Value: float64(1780136),
			Type: dogstatsd.Gauge,
			Rate: 1,
		},
	},
	{
		"users.logged_in:42.000000|m",
		&dogstatsd.Metric{
			Name: "users.logged_in",
			Value: int64(42),
			Type: dogstatsd.Meter,
			Rate: 1,
		},
	},
}

func TestParse(t *testing.T) {
	for _, tt := range parseMetricsTests {
		m, err := dogstatsd.Parse(tt.in)
		if err != nil {
			t.Errorf("Parse(%q) returned error %s", tt.in, err)
			continue
		}
		if !reflect.DeepEqual(m, tt.out) {
			t.Errorf("Parse(%q):\n\thave %+v\n\twant %+v\n", tt.in, m, tt.out)
		}
	}
}
