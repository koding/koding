package main

import "fmt"

func GetMigrationCompletedReport(m *Migrator) {
	result := fmt.Sprintf("Migration Completed for \"%s\"", m.PostType)
	result = fmt.Sprintf("%s with %d success", result, m.SuccessCount)
	result = fmt.Sprintf("%s and %d error", result, m.ErrorCount)
	totalCount := m.ErrorCount + m.SuccessCount
	result = fmt.Sprintf("%s with total of %d documents", result, totalCount)
	log.Notice(result)
	m.ResetCounters()
}

func ReportSuccess(m *Migrator) {
	log.Info("%d. %s Post Migrated", m.Index, m.Id)
	m.AddSuccessReport()
	if err := publish(*m); err != nil {
		log.Error(err.Error())
	}
}

func ReportError(m *Migrator, err error) {
	log.Error("%d. %s received error: %s", m.Index, m.Id, err.Error())
	m.AddErrorReport(err)
	// do not send already migrated post info to queue
	if err == ErrAlreadyMigrated {
		return
	}
	if err := publish(*m); err != nil {
		log.Error(err.Error())
	}
}
