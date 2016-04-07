package common

import (
	"github.com/cihangir/gene/utils"
)

// Output holds response data for a plugin request.
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
			if _, err := utils.ReadFile(file.Path); err == nil {
				continue
			}
		}

		if file.DoNotFormat {
			if err := utils.Write(file.Path, file.Content); err != nil {
				return err
			}
		} else {
			if err := utils.WriteFormattedFile(file.Path, file.Content); err != nil {
				return err
			}
		}
	}

	return nil
}
