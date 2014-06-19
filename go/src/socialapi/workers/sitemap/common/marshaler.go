package common

import (
	"encoding/xml"
	"fmt"
	"os"
	"path"
	"socialapi/config"
)

func XML(i interface{}, fileName string) error {
	header := []byte(xml.Header)
	res, err := xml.Marshal(i)
	if err != nil {
		return err
	}
	// append header to xml file
	res = append(header, res...)

	MustWrite(res, fileName)

	return nil
}

func MustWrite(input []byte, fileName string) {
	wd, err := os.Getwd()
	if err != nil {
		panic(err)
	}

	root := config.Get().Sitemap.XMLRoot
	n := fmt.Sprintf("%s.xml", fileName)
	n = path.Join(wd, root, n)

	output, err := os.Create(n)
	if err != nil {
		panic(err)
	}
	defer func() {
		if err := output.Close(); err != nil {
			panic(err)
		}
	}()
	if _, err := output.Write(input); err != nil {
		panic(err)
	}

}
