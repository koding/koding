package gatherrun

import (
	"archive/tar"
	"io"
	"os"
	"strings"
)

func untarFile(tarFile string) error {
	var outputFile = strings.TrimSuffix(tarFile, tarSuffix)

	reader, err := os.Open(tarFile)
	if err != nil {
		return err
	}

	tarBallReader := tar.NewReader(reader)

	_, err = tarBallReader.Next()
	if err != nil && err != io.EOF {
		return err
	}

	writer, err := os.Create(outputFile)
	if err != nil {
		return err
	}

	if err := writer.Chmod(os.ModePerm); err != nil {
		return err
	}

	_, err = io.Copy(writer, tarBallReader)
	return err
}
