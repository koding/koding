package uploader

import (
	"bytes"
	"errors"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"time"

	"koding/kites/keygen"
	"koding/klient/storage"
	"koding/logrotate"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	"github.com/koding/logging"
)

var defaultLog = logging.NewCustom("uploader", false)

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}

// Options represents arguments required to create a Uploader value.
type Options struct {
	KeygenURL string      // required
	Kite      *kite.Kite  // required
	Bucket    string      // required
	Region    string      // required
	DB        *bolt.DB    // optional; in-memory store if nil
	Log       kite.Logger // optional; defaultLog if nil
}

// Uploader is a kite handler for "log.upload" method.
type Uploader struct {
	cfg    *Options
	rotate *logrotate.Uploader
	req    chan *request
	close  chan struct{}
}

// New gives new uploader built from the given options.
func New(cfg *Options) *Uploader {
	log := defaultLog
	if l, ok := cfg.Log.(logging.Logger); ok {
		log = l
	}

	up := &Uploader{
		cfg: cfg,
		rotate: &logrotate.Uploader{
			UserBucket: keygen.NewUserBucket(&keygen.Config{
				ServerURL: cfg.KeygenURL,
				Kite:      cfg.Kite,
				Bucket:    cfg.Bucket,
				Region:    cfg.Region,
				Log:       log,
			}),
			MetaStore: storage.NewEncodingStorage(cfg.DB, []byte("uploader.metadata")),
		},
		req:   make(chan *request),
		close: make(chan struct{}),
	}

	go up.process()

	return up
}

// UploadRequest represents a request of the "log.upload" kite method.
type UploadRequest struct {
	// File is a path to a file to upload.
	// File path is also used as a S3 key.
	File string `json:"file"`

	// Interval makes the uploader stream the File at the given interval.
	// By default File is not streamed.
	//
	// Ignored when File is empty and Content is used instead.
	// Minimal interval is 15m.
	Interval time.Duration `json:"interval"`

	// Content is a one-time log content to upload, requires key to be non-empty.
	// Superseded by File, if non-empty.
	Content []byte `json:"content"`

	// Key is required when Content is set.
	Key string `json:"key"`
}

// Valid validates the request.
func (req *UploadRequest) Valid() error {
	if req.File == "" && req.Key == "" {
		if len(req.Content) != 0 {
			return errors.New("missing key")
		} else {
			return errors.New("missing file")
		}
	}

	if req.File != "" {
		if _, err := os.Stat(req.File); err != nil {
			return err
		}

		req.File = filepath.ToSlash(filepath.Clean(req.File))
	}

	return nil
}

// UploadResponse represents a response of the "log.upload" kite method.
type UploadResponse struct {
	URL string `json:"url"`
}

// UploadFile uploads the given file to the S3.
//
// If interval is > 0 then the given file is uploaded to S3 at the given interval.
func (up *Uploader) UploadFile(file string, interval time.Duration) (*url.URL, error) {
	req := &UploadRequest{
		File:     file,
		Interval: interval,
	}

	return up.upload(req)
}

// Upload is a kite handler for the "log.upload" method.
func (up *Uploader) Upload(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, errors.New("missing argument")
	}

	var req UploadRequest
	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	url, err := up.upload(&req)
	if err != nil {
		return nil, err
	}

	return &UploadResponse{
		URL: url.String(),
	}, nil
}

// Close stops uploading logs to the S3.
func (up *Uploader) Close() error {
	if up.close != nil {
		close(up.close)
		up.close = nil
	}

	return nil
}

func (up *Uploader) upload(req *UploadRequest) (*url.URL, error) {
	if err := req.Valid(); err != nil {
		return nil, err
	}

	respC := make(chan *response, 1)

	up.req <- &request{
		UploadRequest: req,
		respC:         respC,
	}

	select {
	case <-up.close:
		return nil, errors.New("Uploader was closed")
	case r := <-respC:
		up.log().Debug("upload result: %+v", r)

		return r.url, r.err
	}
}

func (up *Uploader) log() kite.Logger {
	if up.cfg.Log != nil {
		return up.cfg.Log
	}

	return defaultLog
}

type request struct {
	*UploadRequest
	respC chan<- *response
}

type response struct {
	url *url.URL
	err error
}

// process is a worker goroutine that serializes access
// to up.rotate; the MetaStore used in default implementation
// is not goroutine safe - trying to upload the same file
// in two concurrent goroutines could corrupt BoltDB database.
//
// TODO(rjeczalik): To increase throughput process could spawn
// multiple goroutines ensuring there's at most one concurrent
// upload per unique key.
func (up *Uploader) process() {
	watched := make(map[string]struct{})
	prefix := up.cfg.Kite.Config.Id

	for {
		select {
		case <-up.close:
			return

		case req := <-up.req:
			// Upload file at the given interval, if the file
			// is requested to be watched.
			if req.Interval > 0 && req.File != "" {
				if req.Interval < 15*time.Minute {
					req.Interval = 15 * time.Minute
				}

				if _, ok := watched[req.File]; !ok {
					go func(file string) {
						t := time.NewTicker(req.Interval)
						defer t.Stop()

						for {
							select {
							case <-up.close:
								return
							case <-t.C:
								up.req <- &request{
									UploadRequest: &UploadRequest{
										File: file,
									},
								}
							}
						}
					}(req.File)
				}
			}

			var r response

			if req.File != "" {
				r.url, r.err = up.rotate.UploadFile(prefix, req.File)
			} else {
				r.url, r.err = up.rotate.Upload(path.Clean(prefix+"/"+req.Key), bytes.NewReader(req.Content))
			}

			if req.respC != nil {
				select {
				case req.respC <- &r:
				default:
				}
			}

			switch {
			case r.err == nil:
				up.log().Debug("%s: uploaded successfully", req.File)
			case logrotate.IsNop(r.err):
				up.log().Debug("%s: nothing to upload", req.File)
			case os.IsNotExist(r.err):
				up.log().Debug("%s: file does not exist", req.File)
			default:
				up.log().Debug("%s: failed to upload: %s", req.File, r.err)
			}
		}
	}
}
