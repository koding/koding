package main

type Migrator struct {
	Id           string `json:"id"`
	NewId        string `json:"newId"`
	PostType     string `json:"postType"`
	Status       string `json:"status"`
	Error        string `json:"error,omitempty"`
	ErrorCount   int    `json:"errorCount,omitempty"`
	SuccessCount int    `json:"successCount,omitempty"`
	Index        int
}

var REPORT_STATUS = [2]string{
	"Complete",
	"Incomplete",
}

func (m *Migrator) Reset() {
	m.Id = ""
	m.NewId = ""
	m.PostType = ""
	m.Status = ""
	m.Error = ""
}

func (m *Migrator) AddSuccessReport() {
	m.Status = REPORT_STATUS[0]
	m.SuccessCount++
}

func (m *Migrator) AddErrorReport(err error) {
	m.Status = REPORT_STATUS[1]
	m.Error = err.Error()
	m.ErrorCount++
}

func (m *Migrator) ResetCounters() {
	m.ErrorCount = 0
	m.SuccessCount = 0
}
