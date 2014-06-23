package common

import (
	"encoding/xml"
	"fmt"
	"os"
	"path"
	"socialapi/config"
	"socialapi/workers/helper"
)

func XML(i interface{}, fileName string) error {
	res, err := Marshal(i)
	if err != nil {
		return err
	}

	if err := Write(res, fileName); err != nil {
		return err
	}

	return nil
}

func Write(input []byte, fileName string) error {
	wd, err := os.Getwd()
	if err != nil {
		return err
	}

	root := config.Get().Sitemap.XMLRoot
	n := fmt.Sprintf("%s.xml", fileName)
	n = path.Join(wd, root, n)

	output, err := os.Create(n)
	if err != nil {
		return err
	}
	defer func() {
		if err := output.Close(); err != nil {
			helper.MustGetLogger().Critical("Could not close sitemap file %s: %s", err)
		}
	}()
	if _, err := output.Write(input); err != nil {
		return err
	}

	return nil
}

func Marshal(i interface{}) ([]byte, error) {
	header := []byte(xml.Header)
	res, err := xml.Marshal(i)
	if err != nil {
		return nil, err
	}
	// append header to xml file
	return append(header, res...), nil
}
