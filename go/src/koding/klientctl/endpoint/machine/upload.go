package machine

import (
	"koding/klient/uploader"

	multierror "github.com/hashicorp/go-multierror"
)

// UploadedFile describes a file that was uploaded to
// Koding log storage.
type UploadedFile struct {
	File    string `json:"file"` // local name of the file
	Content []byte `json:"-"`
	URL     string `json:"url"`             // remote name of the file in Koding log storage
	Error   string `json:"error,omitempty"` // if upload failed, text message of the failure
}

func (u *UploadedFile) err() string {
	if u.Error != "" {
		return u.Error
	}
	return "-"
}

func (c *Client) Upload(files []*UploadedFile) error {
	return c.upload(files, false)
}

func (c *Client) UploadForce(files []*UploadedFile) error {
	return c.upload(files, true)
}

func (c *Client) upload(files []*UploadedFile, force bool) (err error) {
	for _, f := range files {
		req := &uploader.UploadRequest{}
		var resp uploader.UploadResponse

		if f.Content != nil {
			req.Key = f.File
			req.Content = f.Content
		} else {
			req.File = f.File
		}

		e := c.klient().Call("log.upload", req, &resp)
		if e != nil {
			f.Error = e.Error()
			if !force {
				return e
			} else {
				err = multierror.Append(err, e)
			}
		} else {
			f.URL = resp.URL
		}
	}

	return err
}

func Upload(files ...*UploadedFile) error      { return DefaultClient.Upload(files) }
func UploadForce(files ...*UploadedFile) error { return DefaultClient.UploadForce(files) }
