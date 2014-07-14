// +build linux

package oskite

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"path"
	"strings"
	"time"

	"github.com/mitchellh/goamz/s3"
)

type Manifest struct {
	Name        string
	Version     string
	Identifier  string
	Path        string
	Homepage    string
	Author      string
	AuthorNick  string
	Repository  string
	Description string
	Category    string
}

func appInstallOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params appParams

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.Owner == "" || params.Identifier == "" || params.Version == "" || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ owner: [string], identifier: [string], version: [string], appPath: [string] }"}
	}

	return appInstall(params, vos)
}

func appDownloadOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params appParams

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.Owner == "" || params.Identifier == "" || params.Version == "" || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ owner: [string], identifier: [string], version: [string], appPath: [string] }"}
	}

	return appDownload(params, vos)
}

func appPublishOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params appParams

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ appPath: [string] }"}
	}

	return appPublish(params, vos)
}

func appSkeletonOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params appParams

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ type: [string], appPath: [string] }"}
	}

	return appSkeleton(params, vos)
}

func moveToBackup(name string, vos *virt.VOS) error {
	if _, err := vos.Stat(name); err == nil {
		if err := vos.Mkdir("Backup", 0755); err != nil && !os.IsExist(err) {
			return err
		}
		if err := vos.Rename(name, "Backup/"+path.Base(name)+time.Now().Format("_02_Jan_06_15:04:05_MST")); err != nil {
			return err
		}
	}
	return nil
}

func downloadFile(url string, vos *virt.VOS, path string) error {
	r, err := appsBucket.GetReader(url)
	if err != nil {
		return err
	}
	defer r.Close()

	file, err := vos.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = io.Copy(file, r)
	return err
}

func recursiveCopy(srcPath string, vos *virt.VOS, appPath string) error {
	fi, err := os.Stat(srcPath)
	if err != nil {
		return err
	}

	sf, err := os.Open(srcPath)
	if err != nil {
		return err
	}
	defer sf.Close()

	if fi.IsDir() {
		if err := vos.MkdirAll(appPath, fi.Mode()); err != nil {
			return err
		}
		entries, err := sf.Readdirnames(0)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			if err := recursiveCopy(srcPath+"/"+entry, vos, appPath+"/"+entry); err != nil {
				return err
			}
		}
	} else {
		df, err := vos.OpenFile(appPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
		if err != nil {
			return err
		}

		if _, err := io.Copy(df, sf); err != nil {
			return err
		}
	}

	return nil
}

///
type appParams struct {
	Type, Owner, Identifier, Version, AppPath string
}

func appInstall(params appParams, vos *virt.VOS) (interface{}, error) {
	bucketPath := fmt.Sprintf("%s/%s/%s", params.Owner, params.Identifier, params.Version)
	if err := vos.MkdirAll(params.AppPath, 0755); err != nil && !os.IsExist(err) {
		return nil, err
	}
	if err := downloadFile(bucketPath+"/index.js", vos, params.AppPath+"/index.js"); err != nil {
		return nil, err
	}
	if err := downloadFile(bucketPath+"/manifest.json", vos, params.AppPath+"/manifest.json"); err != nil {
		return nil, err
	}

	return true, nil
}

func appDownload(params appParams, vos *virt.VOS) (interface{}, error) {
	bucketPath := fmt.Sprintf("%s/%s/%s", params.Owner, params.Identifier, params.Version)
	r, err := appsBucket.GetReader(bucketPath + ".tar.gz")
	if err != nil {
		return nil, err
	}
	defer r.Close()

	gzr, err := gzip.NewReader(r)
	if err != nil {
		return nil, err
	}
	defer gzr.Close()

	if err := moveToBackup(params.AppPath, vos); err != nil {
		return nil, err
	}
	if err := vos.MkdirAll(params.AppPath, 0755); err != nil && !os.IsExist(err) {
		return nil, err
	}

	tr := tar.NewReader(gzr)
	for {
		header, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		if strings.Contains(header.Name, "/._") {
			continue // skip OS X metadata pseudo files
		}

		filePath := params.AppPath + "/" + header.Name

		switch header.Typeflag {
		case tar.TypeReg, tar.TypeRegA:
			file, err := vos.OpenFile(filePath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, os.FileMode(header.Mode))
			if err != nil {
				return nil, err
			}
			if _, err := io.Copy(file, tr); err != nil {
				file.Close()
				return nil, err
			}
			file.Close()

		case tar.TypeDir:
			if err := vos.Mkdir(filePath, os.FileMode(header.Mode)); err != nil && !os.IsExist(err) {
				return nil, err
			}

		case tar.TypeSymlink:
			if err := vos.Symlink(filePath, header.Linkname); err != nil {
				return nil, err
			}

		default:
			return nil, fmt.Errorf("Unsupported archive content.")
		}

		if err := vos.Chtimes(filePath, header.ModTime, header.ModTime); err != nil {
			return nil, err
		}
	}

	return true, nil
}

func appPublish(params appParams, vos *virt.VOS) (interface{}, error) {
	manifestFile, err := vos.Open(params.AppPath + "/manifest.json")
	if err != nil {
		return nil, err
	}
	defer manifestFile.Close()

	dec := json.NewDecoder(manifestFile)
	var manifest Manifest
	if err := dec.Decode(&manifest); err != nil {
		return nil, err
	}

	if manifest.AuthorNick != vos.User.Name {
		return nil, fmt.Errorf("The authorNick in manifest.json must be your nickname.")
	}

	bucketPath := fmt.Sprintf("%s/%s/%s", vos.User.Name, manifest.Identifier, manifest.Version)

	result, err := appsBucket.List(bucketPath+".tar.gz", "", "", 1)
	if err != nil {
		return nil, err
	}
	if len(result.Contents) != 0 {
		return nil, fmt.Errorf("Version is already published, change version and try again.")
	}

	buf := bytes.NewBuffer(nil)
	gzw := gzip.NewWriter(buf)
	tw := tar.NewWriter(gzw)

	var readPath func(name string) error
	readPath = func(name string) error {
		fullPath := params.AppPath + "/" + name
		fi, err := vos.Stat(fullPath)
		if err != nil {
			return err
		}

		header := tar.Header{
			Name:    name,
			Mode:    int64(fi.Mode() & os.ModePerm),
			ModTime: fi.ModTime(),
		}

		isDir := fi.Mode()&os.ModeDir != 0
		isSymlink := fi.Mode()&os.ModeSymlink != 0

		if isDir {
			header.Typeflag = tar.TypeDir
		} else if isSymlink {
			header.Typeflag = tar.TypeSymlink
			header.Linkname, err = vos.Readlink(fullPath)
			if err != nil {
				return err
			}
		} else {
			header.Typeflag = tar.TypeReg
			header.Size = fi.Size()
		}

		if tw.WriteHeader(&header); err != nil {
			return err
		}

		if !isDir && !isSymlink {
			file, err := vos.Open(fullPath)
			if err != nil {
				return err
			}
			defer file.Close()

			teeReader := io.TeeReader(file, tw) // write to tar and S3 at once
			if err := appsBucket.PutReader(bucketPath+"/"+name, teeReader, fi.Size(), "", s3.Private); err != nil {
				return err
			}
		} else {
			if _, err := tw.Write([]byte{}); err != nil {
				return err
			}
		}

		if isDir {
			dir, err := vos.Open(fullPath)
			if err != nil {
				return err
			}
			defer dir.Close()
			entries, err := dir.Readdirnames(0)
			if err != nil {
				return err
			}
			for _, entry := range entries {
				entryPath := name + "/" + entry
				if name == "." {
					entryPath = entry
				}
				if err := readPath(entryPath); err != nil {
					return err
				}
			}
		}

		return nil
	}

	err = readPath(".")
	tw.Close()
	gzw.Close()
	if err != nil {
		return nil, err
	}

	if err := appsBucket.Put(bucketPath+".tar.gz", buf.Bytes(), "", s3.Private); err != nil {
		return nil, err
	}

	return true, nil

}

func appSkeleton(params appParams, vos *virt.VOS) (interface{}, error) {
	if params.Type == "" {
		params.Type = "blank"
	}

	if err := moveToBackup(params.AppPath, vos); err != nil {
		return nil, err
	}
	if err := recursiveCopy(templateDir+"/app/"+params.Type, vos, params.AppPath); err != nil {
		return nil, err
	}

	return true, nil
}
