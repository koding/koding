package common

import (
	"encoding/xml"
	"fmt"
	"os"
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
	n := fmt.Sprintf("%s.xml", fileName)

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
