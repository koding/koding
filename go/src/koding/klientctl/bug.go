package main

import (
	"bytes"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"time"

	"koding/kites/config"
	"koding/klient/uploader"
	konfig "koding/klientctl/config"
	"koding/klientctl/endpoint/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
	"github.com/skratchdot/open-golang/open"
)

type BugMetadata struct {
	KiteID      string                  `json:"kiteID"`
	Konfig      *config.Konfig          `json:"konfig"`
	Version     int                     `json:"version"`
	Environment string                  `json:"environment"`
	Files       []*machine.UploadedFile `json:"files"`
	CreatedAt   time.Time               `json:"createdAt"`
}

func (bm *BugMetadata) ToFile() *machine.UploadedFile {
	p, err := jsonMarshal(bm)
	if err != nil {
		panic(err)
	}

	hash := sha1.Sum(p)

	return &machine.UploadedFile{
		File:    "bug/" + hex.EncodeToString(hash[:]) + ".json",
		Content: p,
	}
}

func Bug(_ *cli.Context, log logging.Logger, _ string) (int, error) {
	meta := metadata()

	resp, err := machine.ListMount(&machine.ListMountOptions{})
	if err != nil {
		return 1, err
	}

	for id, mounts := range resp {
		for _, m := range mounts {
			opts := &machine.InspectMountOptions{
				Identifier: string(m.ID),
				Sync:       true,
				Log:        log.New("bug"),
			}

			records, err := machine.InspectMount(opts)
			if err != nil {
				return 1, err
			}

			if len(records.Sync) > 0 {
				p, err := json.Marshal(records.Sync)
				if err != nil {
					return 1, err
				}

				meta.Files = append(meta.Files, &machine.UploadedFile{
					File:    "sync/" + id + "/" + string(m.ID) + ".json",
					Content: p,
				})
			}
		}
	}

	// Best-effort attempt of uploading system files
	// for troubleshooting.
	_ = machine.UploadForce(meta.Files...)

	report := meta.ToFile()

	if err := machine.Upload(report); err != nil {
		return 1, err
	}

	s := signature(report.URL)
	t := fmt.Sprintf(issueBody, s)

	if err := open.Start("https://github.com/koding/koding/issues/new?body=" + url.QueryEscape(t)); err != nil {
		return 1, err
	}

	fmt.Println(s)

	return 0, nil
}

func metadata() *BugMetadata {
	// Strip KiteKey from config.
	cfg := *konfig.Konfig
	cfg.KiteKey = ""

	return &BugMetadata{
		KiteID:      konfig.Konfig.KiteConfig().Id,
		Konfig:      &cfg,
		Version:     konfig.VersionNum(),
		Environment: konfig.Environment,
		Files:       systemFiles(),
		CreatedAt:   time.Now(),
	}
}

func systemFiles() (files []*machine.UploadedFile) {
	for _, log := range uploader.LogFiles {
		if _, err := os.Stat(log); os.IsNotExist(err) {
			continue
		}

		files = append(files, &machine.UploadedFile{
			File: log,
		})
	}

	return files
}

func jsonMarshal(v interface{}) ([]byte, error) {
	var buf bytes.Buffer

	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)

	if err := enc.Encode(v); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func signature(uri string) string {
	u, err := url.Parse(uri)
	if err != nil {
		panic(err)
	}

	return hex.EncodeToString([]byte(u.Path))
}

const issueBody = `<!--- Provide a general summary of the issue in the Title above -->

## Signature
` + "```\n%s\n```" + `

## Expected Behavior
<!--- If you're describing a bug, tell us what should happen -->
<!--- If you're suggesting a change/improvement, tell us how it should work -->

## Current Behavior
<!--- If describing a bug, tell us what happens instead of the expected behavior -->
<!--- If suggesting a change/improvement, explain the difference from current behavior -->

## Possible Solution
<!--- Not obligatory, but suggest a fix/reason for the bug, -->
<!--- or ideas how to implement the addition or change -->

## Steps to Reproduce (for bugs)
<!--- Provide a link to a live example, or an unambiguous set of steps to -->
<!--- reproduce this bug. Include code to reproduce, if relevant -->
1.
2.
3.
4.

## Context
<!--- How has this issue affected you? What are you trying to accomplish? -->
<!--- Providing context helps us come up with a solution that is most useful in the real world -->
`
