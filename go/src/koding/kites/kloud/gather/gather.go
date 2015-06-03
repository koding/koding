package gather

import (
	"bytes"
	"encoding/json"
	"koding/db/models"
	"math/rand"
	"os"
	"strings"
)

type Gather struct {
	DestFolder string
	Exporter   Exporter
	Fetcher    Fetcher
	Output     *models.Gather
}

func New(fetcher Fetcher, exporter Exporter, output *models.Gather) *Gather {
	return &Gather{
		Fetcher:    fetcher,
		Exporter:   exporter,
		DestFolder: "/tmp/" + randSeq(10),
		Output:     output,
	}
}

func (c *Gather) Run() error {
	defer c.Cleanup()

	binary, err := c.GetCheckerBinary()
	if err != nil {
		return err
	}

	if err := c.Export(binary.Run()); err != nil {
		return err
	}

	return nil
}

func (c *Gather) GetCheckerBinary() (*CheckerBinary, error) {
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

	binaryPath := strings.Trim(tarFile, TAR_SUFFIX)
	return &CheckerBinary{Path: binaryPath}, nil
}

func (c *Gather) CreateDestFolder() error {
	folderExists, err := exists(c.DestFolder)
	if err != nil {
		return err
	}

	if !folderExists {
		err = os.Mkdir(c.DestFolder, 0777)
	}

	return err
}

func (c *Gather) DownloadScripts(folderName string) error {
	return c.Fetcher.Download(folderName)
}

func (c *Gather) Export(raw []interface{}, err error) error {
	if err != nil {
		output := models.NewGatherError(c.Output, err)
		return c.Exporter.SendError(output)
	}

	results := []models.GatherSingleStat{}

	for _, r := range raw {
		buf := bytes.NewBuffer(nil)
		if err := json.NewEncoder(buf).Encode(r); err != nil {
			continue
		}

		var stat models.GatherSingleStat
		if err := json.NewDecoder(buf).Decode(&stat); err != nil {
			continue
		}

		results = append(results, stat)
	}

	output := models.NewGatherStat(c.Output, results)
	return c.Exporter.SendResult(output)
}

func (c *Gather) Cleanup() error {
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
