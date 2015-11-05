package gatherrun

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"
)

var (
	abuseInterval     = time.Minute * 15
	analyticsInterval = time.Hour * 24
	envVarName        = "GATHER"
)

type GatherRun struct {
	DestFolder string
	Exporter   Exporter
	Fetcher    Fetcher
	Env        string
	Username   string
	ScriptType string
}

func Run(env, username string) {
	fetcher := &S3Fetcher{
		BucketName: "koding-gather",
		FileName:   "koding-kernel-1.tar",
		Region:     "us-east-1",
	}

	exporter := NewKodingExporter()

	abuseTimer := time.NewTimer(abuseInterval)
	analyticsTimer := time.NewTimer(analyticsInterval)

	// run analytics in initial since free vms turn off in <1 hr
	// we sleep a slight time to make sure this doesn't disrupt klient updates
	go func() {
		time.Sleep(10 * time.Minute)
		New(fetcher, exporter, env, username, "analytics").Run()
	}()

	for {
		select {
		case <-abuseTimer.C:
			New(fetcher, exporter, env, username, "abuse").Run()
		case <-analyticsTimer.C:
			New(fetcher, exporter, env, username, "analytics").Run()
		}
	}
}

func New(fetcher Fetcher, exporter Exporter, env, username, scriptType string) *GatherRun {
	tmpDir, err := ioutil.TempDir("/tmp", "koding-kernel")
	if err != nil {
		// TODO: how to deal with errs
	}

	return &GatherRun{
		Fetcher:    fetcher,
		Exporter:   exporter,
		DestFolder: tmpDir,
		Env:        env,
		Username:   username,
		ScriptType: scriptType,
	}
}

func (c *GatherRun) Run() (err error) {
	defer func() { err = c.Cleanup() }()

	binary, err := c.GetGatherBinary()
	if err != nil {
		return err
	}

	if err = c.Export(binary.Run()); err != nil {
		return err
	}

	return nil
}

func (c *GatherRun) GetGatherBinary() (*GatherBinary, error) {
	if err := os.MkdirAll(c.DestFolder, 0777); err != nil {
		return nil, err
	}

	if err := c.DownloadScripts(c.DestFolder); err != nil {
		return nil, err
	}

	tarFile := filepath.Join(c.DestFolder, c.Fetcher.GetFileName())
	if err := untar(tarFile, c.DestFolder); err != nil {
		return nil, err
	}

	binaryPath := strings.TrimSuffix(tarFile, tarSuffix)
	return &GatherBinary{Path: binaryPath, ScriptType: c.ScriptType}, nil
}

func (c *GatherRun) DownloadScripts(folderName string) error {
	return c.Fetcher.Download(folderName)
}

func (c *GatherRun) Export(raw []interface{}, err error) error {
	if err != nil {
		return c.sendErrors(err)
	}

	var stats = []GatherSingleStat{}
	var errors = []error{}

	for _, r := range raw {
		buf := new(bytes.Buffer)
		if err := json.NewEncoder(buf).Encode(r); err != nil {
			errors = append(errors, err)
			continue
		}

		var stat GatherSingleStat
		if err := json.NewDecoder(buf).Decode(&stat); err != nil {
			errors = append(errors, err)
			continue
		}

		stats = append(stats, stat)
	}

	if len(errors) > 0 {
		c.sendErrors(errors...)
	}

	if len(stats) > 0 {
		gStat := &GatherStat{
			Env: c.Env, Username: c.Username, Stats: stats, Type: c.ScriptType,
		}
		return c.Exporter.SendStats(gStat)
	}

	return nil
}

func (c *GatherRun) Cleanup() error {
	return os.RemoveAll(c.DestFolder)
}

func (c *GatherRun) sendErrors(errs ...error) error {
	gErr := &GatherError{
		Env: c.Env, Username: c.Username, Errors: errs,
	}

	return c.Exporter.SendError(gErr)
}
