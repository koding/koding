package gather

import (
	"math/rand"
	"os"
	"path/filepath"
	"strings"
)

type Gather struct {
	BucketName string
	DestFolder string
	Exporter   Exporter
	Fetcher    Fetcher
}

func New(fetcher Fetcher) *Gather {
	return &Gather{Fetcher: fetcher, DestFolder: "/tmp/" + "gather-" + randSeq(10)}
}

func (c *Gather) RunAllScripts() error {
	scripts, err := c.GetScripts()
	if err != nil {
		return err
	}

	for _, script := range scripts {
		if err := c.Export(script.Run()); err != nil {
			return err
		}
	}

	return nil
}

func (c *Gather) GetScripts() ([]*Script, error) {
	if err := c.CreateDestFolder(); err != nil {
		return nil, err
	}

	if err := c.DownloadScripts(c.DestFolder); err != nil {
		return nil, err
	}

	tarFile := c.DestFolder + "/" + c.Fetcher.GetScriptsFile()
	if err := untarFile(tarFile, c.DestFolder); err != nil {
		return nil, err
	}

	return c.ExtractScripts(tarFile)
}

func (c *Gather) ExtractScripts(tarFile string) ([]*Script, error) {
	scripts := []*Script{}

	extractIntoScript := func(path string, f os.FileInfo, err error) error {
		if !f.IsDir() {
			script := &Script{Path: path}
			scripts = append(scripts, script)
		}

		return err
	}

	scriptsFolder := strings.Trim(tarFile, ".tar")
	if err := filepath.Walk(scriptsFolder, extractIntoScript); err != nil {
		return nil, err
	}

	return scripts, nil
}

func (c *Gather) CreateDestFolder() error {
	folderExists, err := exists(c.DestFolder)
	if err != nil {
		return err
	}

	if !folderExists {
		err = createFolder(c.DestFolder)
	}

	return err
}

func (c *Gather) DownloadScripts(folderName string) error {
	return c.Fetcher.Download(folderName)
}

func (c *Gather) Export(result Result, err error) error {
	if err != nil {
		return c.Exporter.SendError(err)
	}

	return c.Exporter.SendResult(result)
}

func (c *Gather) Cleanup() {
	c.DestFolder = ""
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
