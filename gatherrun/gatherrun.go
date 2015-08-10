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
	abuseInterval     = time.Minute * 30
	analyticsInterval = time.Hour * 24
)

type GatherRun struct {
	DestFolder string
	Exporter   Exporter
	Fetcher    Fetcher
	Output     *Gather
	ScriptType string
}

func Run(env, username string) {
	fetcher := &S3Fetcher{
		AccessKey:  "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey:  "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",
		BucketName: "gather-vm",
		FileName:   "gather.tar",
		Region:     "us-east-1",
	}

	exporter := NewKodingExporter()

	opts := &Gather{Env: env, Username: username}

	go func() {
		New(fetcher, exporter, opts, "abuse").Run()
		New(fetcher, exporter, opts, "analytics").Run()
	}()

	abuseTimer := time.NewTimer(abuseInterval)
	analyticsTimer := time.NewTimer(analyticsInterval)

	for {
		select {
		case <-abuseTimer.C:
			New(fetcher, exporter, opts, "abuse").Run()
		case <-analyticsTimer.C:
			New(fetcher, exporter, opts, "analytics").Run()
		}
	}
}

func New(fetcher Fetcher, exporter Exporter, output *Gather, scriptType string) *GatherRun {
	tmpDir, err := ioutil.TempDir("/tmp", "gather")
	if err != nil {
		// TODO: how to deal with errs
	}

	return &GatherRun{
		Fetcher:    fetcher,
		Exporter:   exporter,
		DestFolder: tmpDir,
		Output:     output,
		ScriptType: scriptType,
	}
}

func (c *GatherRun) Run() error {
	defer c.Cleanup()

	binary, err := c.GetGatherBinary()
	if err != nil {
		return err
	}

	if err := c.Export(binary.Run()); err != nil {
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
	if err := untarFile(tarFile, c.DestFolder); err != nil {
		return nil, err
	}

	binaryPath := strings.TrimSuffix(tarFile, tarSuffix)
	return &GatherBinary{Path: binaryPath, ScriptType: c.ScriptType}, nil
}

func (c *GatherRun) CreateDestFolder() error {
	folderExists, err := exists(c.DestFolder)
	if err != nil {
		return err
	}

	if !folderExists {
		err = os.Mkdir(c.DestFolder, 0777)
	}

	return err
}

func (c *GatherRun) DownloadScripts(folderName string) error {
	return c.Fetcher.Download(folderName)
}

func (c *GatherRun) Export(raw []interface{}, err error) error {
	if err != nil {
		output := NewGatherError(c.Output, err)
		return c.Exporter.SendError(output)
	}

	results := []GatherSingleStat{}

	for _, r := range raw {
		buf := new(bytes.Buffer)
		if err := json.NewEncoder(buf).Encode(r); err != nil {
			continue
		}

		var stat GatherSingleStat
		if err := json.NewDecoder(buf).Decode(&stat); err != nil {
			continue
		}

		results = append(results, stat)
	}

	output := NewGatherStat(c.Output, results)
	return c.Exporter.SendResult(output)
}

func (c *GatherRun) Cleanup() error {
	return os.RemoveAll(c.DestFolder)
}
