package gatherrun

import (
	"bytes"
	"encoding/json"
	"math/rand"
	"os"
	"strings"
)

type GatherRun struct {
	DestFolder string
	Exporter   Exporter
	Fetcher    Fetcher
	Output     *Gather
}

func Run(env, username string) {
	fetcher := &S3Fetcher{
		AccessKey:  "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey:  "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",
		BucketName: "gather-vm",
		FileName:   "gather.tar",
		Region:     "us-east-1",
	}

	// initialize `Exporter` to save results
	exporter := NewKodingExporter()

	opts := &Gather{
		Env:      env,
		Username: username,
	}

	// initialize `Client` to download the scripts and save the results.
	New(fetcher, exporter, opts).Run()
}

func New(fetcher Fetcher, exporter Exporter, output *Gather) *GatherRun {
	return &GatherRun{
		Fetcher:    fetcher,
		Exporter:   exporter,
		DestFolder: "/tmp/" + randSeq(10),
		Output:     output,
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
	if err := c.CreateDestFolder(); err != nil {
		return nil, err
	}

	if err := c.DownloadScripts(c.DestFolder); err != nil {
		return nil, err
	}

	tarFile := c.DestFolder + "/" + c.Fetcher.GetFileName()
	if err := untarFile(tarFile, c.DestFolder); err != nil {
		return nil, err
	}

	binaryPath := strings.TrimSuffix(tarFile, TAR_SUFFIX)
	return &GatherBinary{Path: binaryPath}, nil
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
		buf := bytes.NewBuffer(nil)
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

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func randSeq(n int) string {
	b := make([]rune, n)

	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}

	return string(b)
}
