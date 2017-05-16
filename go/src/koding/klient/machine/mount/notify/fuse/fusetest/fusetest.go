package fusetest

import (
	"bytes"
	"context"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"sync"

	"koding/klient/machine/index"
	"koding/klient/machine/mount/notify"
)

type BindCache struct {
	loc  string
	tmp  string
	idx  *index.Index
	ch   chan change
	done chan struct{}
	once sync.Once
	wg   sync.WaitGroup
}

var _ notify.Cache = (*BindCache)(nil)

func NewBindCache(loc, tmp string) (*BindCache, error) {
	idx, err := index.NewIndexFiles(loc, nil)
	if err != nil {
		return nil, err
	}

	bc := &BindCache{
		loc:  loc,
		tmp:  tmp,
		idx:  idx,
		ch:   make(chan change),
		done: make(chan struct{}),
	}

	go bc.process()

	return bc, nil
}

func (bc *BindCache) Commit(change *index.Change) context.Context {
	ctx, cancel := context.WithCancel(context.Background())

	go bc.commit(change, cancel)

	return ctx
}

func (bc *BindCache) Index() *index.Index {
	return bc.idx
}

func (bc *BindCache) Close() error {
	bc.once.Do(bc.stop)
	return nil
}

func (bc *BindCache) stop() {
	// Ensure all bc.commit goroutines are stopped.
	close(bc.done)
	bc.wg.Wait()

	close(bc.ch)
}

type change struct {
	*index.Change

	cancel func()
}

func (bc *BindCache) commit(c *index.Change, cancel func()) {
	bc.wg.Add(1)

	select {
	case <-bc.done:
	case bc.ch <- change{
		Change: c,
		cancel: cancel,
	}:
	}

	bc.wg.Done()
}

func (bc *BindCache) process() {
	for change := range bc.ch {
		isRemoteSrc := change.Meta()&index.ChangeMetaRemote != 0

		var src, dst string
		var err error

		if isRemoteSrc {
			base := change.Path()

			if filepath.IsAbs(base) {
				if base, err = filepath.Rel(bc.tmp, base); err != nil {
					log.Printf("BindCache: failed to preprare files for sync: %s", err)
				}
			}

			// bind-mount dir source (remote) -> cache dir (local)
			src = filepath.Join(bc.loc, base)
			dst = filepath.Join(bc.tmp, base)
		} else {
			base := change.Path()

			if filepath.IsAbs(base) {
				if base, err = filepath.Rel(bc.tmp, base); err != nil {
					log.Printf("BindCache: failed to preprare files for sync: %s", err)
				}
			}

			// cache dir (local) -> bind-mount dir source (remote)
			src = filepath.Join(bc.tmp, base)
			dst = filepath.Join(bc.loc, base)
		}

		switch {
		case change.Meta()&(index.ChangeMetaAdd|index.ChangeMetaUpdate) != 0:
			err = copyFilesRecursively(src, dst)
		case change.Meta()&index.ChangeMetaRemove != 0:
			err = os.RemoveAll(dst)
		}

		if err != nil {
			log.Printf("BindCache: failed to sync files: %s", err)
		}

		// Update remote index.
		if !isRemoteSrc {
			// BUG(rjeczalik): Use when index respects promise ops.
			// bc.idx.Apply(bc.loc, bc.idx.CompareBranch(change.Path(), bc.loc))
		}

		change.cancel()
	}
}

type CopyError []*FileError

func (ce CopyError) Error() string {
	var buf bytes.Buffer

	for _, e := range ce {
		buf.WriteString(e.Error())
		buf.WriteRune('\n')
	}

	return buf.String()
}

type FileError struct {
	Path string
	Err  error
}

func fe(path string, err error) *FileError {
	return &FileError{
		Path: path,
		Err:  err,
	}
}

func (fe *FileError) Error() string {
	return fe.Path + ": " + fe.Err.Error()
}

func copyFile(src, dst string) error {
	fsrc, err := os.Open(src)
	if err != nil {
		return fe(src, err)
	}
	defer fsrc.Close()

	fi, err := fsrc.Stat()
	if err != nil {
		return err
	}

	if err := os.MkdirAll(filepath.Dir(dst), 0755); err != nil {
		return err
	}

	tmp, err := ioutil.TempFile(filepath.Split(dst))
	if err != nil {
		return fe(dst, err)
	}

	_, err = io.Copy(tmp, fsrc)

	if err = nonil(err, tmp.Chmod(fi.Mode()), tmp.Close()); err != nil {
		return nonil(fe(tmp.Name(), err), os.Remove(tmp.Name()))
	}

	if err = os.Rename(tmp.Name(), dst); err != nil {
		return nonil(fe(dst, err), os.Remove(tmp.Name()))
	}

	return os.Chtimes(dst, fi.ModTime(), fi.ModTime())
}

func copyFilesRecursively(src, dst string) error {
	fi, err := os.Stat(src)
	if err != nil {
		return err
	}

	if !fi.IsDir() {
		return copyFile(src, dst)
	}

	var ce CopyError

	filepath.Walk(src, func(path string, fi os.FileInfo, err error) error {
		if err != nil {
			ce = append(ce, fe(path, err))
			return nil
		}

		if fi.IsDir() {
			return nil
		}

		key, err := filepath.Rel(src, path)
		if err != nil {
			ce = append(ce, fe(path, err))
			return nil
		}

		dst := filepath.Join(dst, key)
		dir := filepath.Dir(dst)

		if err := os.MkdirAll(dir, 0755); err != nil {
			ce = append(ce, fe(dir, err))
			return nil
		}

		if fe, ok := copyFile(path, dst).(*FileError); ok {
			ce = append(ce, fe)
		}

		return nil
	})

	if len(ce) != 0 {
		return ce
	}

	return nil
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
