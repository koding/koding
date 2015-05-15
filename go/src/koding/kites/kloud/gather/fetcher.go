package gather

import (
	"bufio"
	"io"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/s3"
)

const (
	CONTENT_TYPE_TAR       = "application/tar"
	DEFAULT_BUCKET_NAME    = "gather-vm-metrics"
	DEFAULT_SCRIPTS_FOLDER = "scripts"
)

type Fetcher interface {
	Download(string) error
}

type S3Fetcher struct {
	AccessKey, SecretKey    string
	BucketName, ScriptsFile string
}

func (s *S3Fetcher) Bucket() *s3.Bucket {
	auth := aws.Auth{
		AccessKey: s.AccessKey,
		SecretKey: s.SecretKey,
	}

	return s3.New(auth, aws.USEast).Bucket(s.BucketName)
}

// Download downloads scripts from S3 bucket into specified folder.
func (s *S3Fetcher) Download(folderName string) error {
	// prefix, delim, marker, max
	l, err := s.Bucket().List(s.ScriptsFile, "", "", 1)
	if err != nil {
		return err
	}

	contents := l.Contents
	if len(contents) == 0 {
		return ErrScriptsFileNotFound
	}

	key := contents[0].Key
	rc, err := s.Bucket().GetReader(key)
	if err != nil {
		return err
	}
	defer rc.Close()

	w, err := os.Create(filepath.Join(folderName, key))
	if err != nil {
		return err
	}
	defer w.Close()

	_, err = io.Copy(w, rc)

	return err
}

// Upload tars folder and uploads to s3 bucket.
func (s *S3Fetcher) Upload(folderName string) error {
	tarFile := folderName + ".tar"
	if err := tarFolder(folderName, tarFile); err != nil {
		return err
	}

	file, err := os.Open(tarFile)
	if err != nil {
		return err
	}

	fileInfo, err := file.Stat()
	if err != nil {
		return err
	}

	return s.Bucket().PutReader(
		tarFile, bufio.NewReader(file), fileInfo.Size(), CONTENT_TYPE_TAR, s3.Private,
	)
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func tarFolder(folderName, outputFileName string) error {
	if err := exists(folderName); err != nil {
		return err
	}

	_, err := exec.Command("tar", "-cvf", outputFileName, folderName).Output()
	return err
}

func exists(name string) error {
	var err error
	if _, err = os.Stat(name); os.IsNotExist(err) {
		return ErrFolderNotFound
	}

	return err
}
