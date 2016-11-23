package scripts

import "koding/gather/metrics"

var (
	MongoInstalled = &metrics.Metric{
		Name:      "mongo_installed",
		Collector: metrics.NewScriptCmd("scripts/bash/mongo_installed.sh"),
		Output:    singleNumberIntoBool(),
	}

	MysqlInstalled = &metrics.Metric{
		Name:      "mysql_installed",
		Collector: metrics.NewScriptCmd("scripts/bash/mysql_installed.sh"),
		Output:    singleNumber(),
	}

	PsqlInstalled = &metrics.Metric{
		Name:      "psql_installed",
		Collector: metrics.NewScriptCmd("scripts/bash/psql_installed.sh"),
		Output:    singleNumber(),
	}

	SqliteInstalled = &metrics.Metric{
		Name:      "sqlite_installed",
		Collector: metrics.NewScriptCmd("scripts/bash/sqlite_installed.sh"),
		Output:    singleNumber(),
	}
)
