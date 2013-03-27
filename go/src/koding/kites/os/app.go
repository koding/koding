package main

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
	"launchpad.net/goamz/aws"
	"launchpad.net/goamz/s3"
	"os"
	"time"
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

var appsBucket = s3.New(
	aws.Auth{"AKIAJI6CLCXQ73BBQ2SQ", "qF8pFQ2a+gLam/pRk7QTRTUVCRuJHnKrxf6LJy9e"},
	aws.USEast,
).Bucket("koding-apps")

func registerAppMethods(k *kite.Kite) {
	k.Handle("app.install", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		bucketPath, vos, appPath, err := prepareAppRetrival(args, session)
		if err != nil {
			return nil, err
		}

		if err := vos.Mkdir(appPath, 0755); err != nil && !os.IsExist(err) {
			return nil, err
		}
		if err := downloadFile(bucketPath+"/index.js", vos, appPath+"/index.js"); err != nil {
			return nil, err
		}
		if err := downloadFile(bucketPath+"/manifest.json", vos, appPath+"/manifest.json"); err != nil {
			return nil, err
		}

		return true, nil
	})

	k.Handle("app.download", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		bucketPath, vos, appPath, err := prepareAppRetrival(args, session)
		if err != nil {
			return nil, err
		}

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

		if _, err := vos.Lstat(appPath); err == nil {
			if err := vos.Rename(appPath, appPath+time.Now().Format("_02_Jan_06_15:04:05_MST")); err != nil {
				return nil, err
			}
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

			filePath := appPath + "/" + header.Name

			switch header.Typeflag {
			case tar.TypeReg, tar.TypeRegA:
				file, err := vos.Create(filePath)
				if err != nil {
					return nil, err
				}
				if _, err := io.Copy(file, tr); err != nil {
					file.Close()
					return nil, err
				}
				file.Close()

			case tar.TypeDir:
				if err := vos.Mkdir(filePath, os.FileMode(header.Mode)); err != nil {
					return nil, err
				}

			case tar.TypeSymlink:
				if err := vos.Symlink(filePath, header.Linkname); err != nil {
					return nil, err
				}

			default:
				return nil, fmt.Errorf("Unsupported archive content.")
			}

			if err := vos.Chmod(filePath, os.FileMode(header.Mode)); err != nil {
				return nil, err
			}
			if err := vos.Chtimes(filePath, header.ModTime, header.ModTime); err != nil {
				return nil, err
			}
		}

		return true, nil
	})

	k.Handle("app.publish", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			AppPath string
		}
		if args.Unmarshal(&params) != nil || params.AppPath == "" {
			return nil, &kite.ArgumentError{Expected: "{ appPath: [string] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

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

		bucketPath := fmt.Sprintf("%s/%s/%s.tar.gz", session.Username, manifest.Identifier, manifest.Version)

		result, err := appsBucket.List(bucketPath, "", "", 1)
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
			fi, err := vos.Lstat(fullPath)
			if err != nil {
				return err
			}

			header := tar.Header{
				Name:    name,
				Mode:    int64(fi.Mode()),
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
				if _, err := io.Copy(tw, file); err != nil {
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
					if err := readPath(name + "/" + entry); err != nil {
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

		if err := appsBucket.Put(bucketPath, buf.Bytes(), "", s3.Private); err != nil {
			return nil, err
		}

		return true, nil
	})

	k.Handle("app.skeleton", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Type, AppPath string
		}
		if args.Unmarshal(&params) != nil || params.AppPath == "" {
			return nil, &kite.ArgumentError{Expected: "{ appPath: [string] }"}
		}

		if params.Type == "" {
			params.Type = "blank"
		}

		return true, nil
	})
}

func prepareAppRetrival(args *dnode.Partial, session *kite.Session) (bucketPath string, vos *virt.VOS, appPath string, err error) {
	var params struct {
		Owner, Identifier, Version, AppPath string
	}
	if args.Unmarshal(&params) != nil || params.Owner == "" || params.Identifier == "" || params.Version == "" || params.AppPath == "" {
		err = &kite.ArgumentError{Expected: "{ owner: [string], identifier: [string], version: [string], appPath: [string] }"}
		return
	}

	bucketPath = fmt.Sprintf("%s/%s/%s", params.Owner, params.Identifier, params.Version)

	user, vm := findSession(session)
	vos = vm.OS(user)
	appPath = params.AppPath
	return
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

func recursiveCopy() {

}
