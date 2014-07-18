package reporting

import (
	"encoding/json"
	"fmt"
	"runtime"
	"strings"

	"github.com/smartystreets/goconvey/convey/gotest"
)

////////////////// ScopeReport ////////////////////

type ScopeReport struct {
	Title string
	ID    string
	File  string
	Line  int
}

func NewScopeReport(title, name string) *ScopeReport {
	file, line, _ := gotest.ResolveExternalCaller()
	self := new(ScopeReport)
	self.Title = title
	self.ID = fmt.Sprintf("%s|%s", title, name)
	self.File = file
	self.Line = line
	return self
}

////////////////// ScopeResult ////////////////////

type ScopeResult struct {
	Title      string
	File       string
	Line       int
	Depth      int
	Assertions []*AssertionResult
	Output     string
}

func newScopeResult(title string, depth int, file string, line int) *ScopeResult {
	self := new(ScopeResult)
	self.Title = title
	self.Depth = depth
	self.File = file
	self.Line = line
	self.Assertions = []*AssertionResult{}
	return self
}

/////////////////// StoryReport /////////////////////

type StoryReport struct {
	Test T
	Name string
	File string
	Line int
}

func NewStoryReport(test T) *StoryReport {
	file, line, name := gotest.ResolveExternalCaller()
	name = removePackagePath(name)
	self := new(StoryReport)
	self.Test = test
	self.Name = name
	self.File = file
	self.Line = line
	return self
}

// name comes in looking like "github.com/smartystreets/goconvey/examples.TestName".
// We only want the stuff after the last '.', which is the name of the test function.
func removePackagePath(name string) string {
	parts := strings.Split(name, ".")
	return parts[len(parts)-1]
}

/////////////////// FailureView ////////////////////////

type FailureView struct {
	Message  string
	Expected string
	Actual   string
}

////////////////////AssertionResult //////////////////////

type AssertionResult struct {
	File       string
	Line       int
	Expected   string
	Actual     string
	Failure    string
	Error      interface{}
	StackTrace string
	Skipped    bool
}

func NewFailureReport(failure string) *AssertionResult {
	report := new(AssertionResult)
	report.File, report.Line = caller()
	report.StackTrace = stackTrace()
	parseFailure(failure, report)
	return report
}
func parseFailure(failure string, report *AssertionResult) {
	view := new(FailureView)
	err := json.Unmarshal([]byte(failure), view)
	if err == nil {
		report.Failure = view.Message
		report.Expected = view.Expected
		report.Actual = view.Actual
	} else {
		report.Failure = failure
	}
}
func NewErrorReport(err interface{}) *AssertionResult {
	report := new(AssertionResult)
	report.File, report.Line = caller()
	report.StackTrace = fullStackTrace()
	report.Error = fmt.Sprintf("%v", err)
	return report
}
func NewSuccessReport() *AssertionResult {
	return new(AssertionResult)
}
func NewSkipReport() *AssertionResult {
	report := new(AssertionResult)
	report.File, report.Line = caller()
	report.StackTrace = fullStackTrace()
	report.Skipped = true
	return report
}

func caller() (file string, line int) {
	file, line, _ = gotest.ResolveExternalCaller()
	return
}

func stackTrace() string {
	buffer := make([]byte, 1024*64)
	n := runtime.Stack(buffer, false)
	return removeInternalEntries(string(buffer[:n]))
}
func fullStackTrace() string {
	buffer := make([]byte, 1024*64)
	n := runtime.Stack(buffer, true)
	return removeInternalEntries(string(buffer[:n]))
}
func removeInternalEntries(stack string) string {
	lines := strings.Split(stack, newline)
	filtered := []string{}
	for _, line := range lines {
		if !isExternal(line) {
			filtered = append(filtered, line)
		}
	}
	return strings.Join(filtered, newline)
}
func isExternal(line string) bool {
	for _, p := range internalPackages {
		if strings.Contains(line, p) {
			return true
		}
	}
	return false
}

// NOTE: any new packages that host goconvey packages will need to be added here!
// An alternative is to scan the goconvey directory and then exclude stuff like
// the examples package but that's nasty too.
var internalPackages = []string{
	"goconvey/assertions",
	"goconvey/convey",
	"goconvey/execution",
	"goconvey/gotest",
	"goconvey/reporting",
}
