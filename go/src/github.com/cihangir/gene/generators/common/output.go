package common

import (
	"github.com/cihangir/gene/helpers"
	"github.com/cihangir/gene/writers"
)

type Output struct {
	Content       []byte
	Path          string
	DoNotFormat   bool
	DoNotOverride bool
}

// WriteOutput writes output slice
func WriteOutput(output []Output) error {
	for _, file := range output {
		// do not write empty files
		if len(file.Content) == 0 {
			continue
		}

		if file.DoNotOverride {
			// if file exists, just skip this operation
			if _, err := helpers.ReadFile(file.Path); err == nil {
				continue
			}
		}

		if file.DoNotFormat {
			if err := writers.Write(file.Path, file.Content); err != nil {
				return err
			}
		} else {
			if err := writers.WriteFormattedFile(file.Path, file.Content); err != nil {
				return err
			}
		}
	}

	return nil
}
