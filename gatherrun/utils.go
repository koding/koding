package gatherrun

import (
	"archive/tar"
	"io"
	"os"
	"path/filepath"
)

func untar(tarFilePath, outputFolder string) error {
	tarFileReader, err := os.Open(tarFilePath)
	if err != nil {
		return err
	}

	tarBallReader := tar.NewReader(tarFileReader)

	for {
		header, err := tarBallReader.Next()
		if err != nil && err != io.EOF {
			return err
		}

		if err == io.EOF {
			return nil
		}

		fullPath := filepath.Join(outputFolder, header.Name)

		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(fullPath, os.FileMode(header.Mode)); err != nil {
				return err
			}
		case tar.TypeReg:
			fh, err := os.Create(fullPath)
			if fh != nil {
				defer fh.Close()
			}

			if err != nil {
				return err
			}

			if _, err := io.Copy(fh, tarBallReader); err != nil {
				return err
			}

			if err := os.Chmod(fh.Name(), os.FileMode(header.Mode)); err != nil {
				return err
			}
		}
	}

	return nil
}
