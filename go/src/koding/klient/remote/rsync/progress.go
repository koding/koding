package rsync

import (
	"bufio"
	"errors"
	"io"
	"regexp"
	"strconv"
)

var (
	progressLineReg = regexp.MustCompile(`^\s*(\d+)\s+\d+%`)

	NotProgressableErr = errors.New("Unable to parse for progress")
	EndOfProgressErr   = errors.New("End of progress")
)

func ParseProgress(r io.Reader) <-chan int {
	scanner := bufio.NewScanner(r)
	scanner.Split(ScanRSyncProgress)
	ch := make(chan int, 2)
	go parseProgress(ch, scanner)
	return ch
}

func parseProgress(ch chan<- int, scanner *bufio.Scanner) {
	// To avoid duplication of progress sends, we track the state here
	var lastSent int
	// Keep track of the total downloaded, among all files
	total := 0
	// Keep track of the size of the current file being downloaded.
	currentProgress := 0

	for scanner.Scan() {
		p, err := ParseProgressLine(scanner.Text())
		// With every line printed from rsync, there is an implicit state for tracking
		// progress that boils down to one of three possible cases.
		//
		// 1. There were no problems parsing the progress number from the given line.
		//   This means that we know the total amount downloaded *so far*, so we simply
		//   need to record this value and wait for the next line.
		// 2. There was a problem parsing the progress number, and the *previous* line
		//   succeeded in parsing. This means that the previous file is no longer
		//   being shown progress for - so combined that file's total and the overall
		//   total.
		// 3. There was a problem parsing the progress number, and the last line did
		//   *not* succeed. This simply means that we're reading status messages.
		//
		// As a general rule of thumb, if currentProgress != 0, the last read was
		// success.
		switch {
		case err == nil:
			// Case #1
			currentProgress = p
		case err != nil && currentProgress != 0:
			// Case #2
			total += currentProgress
			currentProgress = 0
		case err != nil && currentProgress == 0:
			// Case #3, nothing to do.
		}

		if lastSent != total+currentProgress {
			lastSent = total + currentProgress
			ch <- lastSent
		}
	}

	close(ch)
}

func ParseProgressLine(line string) (int, error) {
	result := progressLineReg.FindStringSubmatch(line)

	if result == nil {
		return 0, NotProgressableErr
	}

	i, err := strconv.Atoi(result[1])

	// If there is any error converting the int, it's not a proper int and
	// not formatted as we expect.
	if err != nil {
		return 0, NotProgressableErr
	}

	return i, nil
}

// ScanRSyncProgress is a Scanner SplitFunc for splitting RSync Progress output based
// on either the CLI escape/update char or newlines.
func ScanRSyncProgress(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if atEOF && len(data) == 0 {
		return 0, nil, nil
	}

	for i, b := range data {
		switch b {
		case '\n', '':
			return i + 1, data[:i], nil
		}
	}

	// If we didn't find a token from the above, and we're at EOF, return
	// what we have.
	if atEOF {
		return len(data), data, nil
	}

	// If we're not at EOF, but we didn't find any of the characters we want,
	// request a larger dataset.
	return 0, nil, nil
}
