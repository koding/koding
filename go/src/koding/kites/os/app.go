package main

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"net/http"
	"os"
	"time"
)

func registerAppMethods(k *kite.Kite) {
	k.Handle("app.install", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		appUrl, vos, dstPath, err := prepareAppRetrival(args, session)
		if err != nil {
			return nil, err
		}

		if err := vos.Mkdir(dstPath, 0755); err != nil && !os.IsExist(err) {
			return nil, err
		}
		if err := downloadFile(appUrl+"/index.js", vos, dstPath+"/index.js"); err != nil {
			return nil, err
		}
		if err := downloadFile(appUrl+"/.manifest", vos, dstPath+"/.manifest"); err != nil {
			return nil, err
		}

		return true, nil
	})

	k.Handle("app.download", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		appUrl, vos, dstPath, err := prepareAppRetrival(args, session)
		if err != nil {
			return nil, err
		}

		resp, err := http.Get(appUrl + ".tar.gz")
		if err != nil {
			return nil, err
		}

		gzr, err := gzip.NewReader(resp.Body)
		if err != nil {
			return nil, err
		}
		defer gzr.Close()

		if _, err := vos.Lstat(dstPath); err == nil {
			if err := vos.Rename(dstPath, dstPath+time.Now().Format("_02_Jan_06_15:04:05_MST")); err != nil {
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

			filePath := dstPath + "/" + header.Name

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
				if err := vos.Link(filePath, header.Linkname); err != nil {
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
}

func prepareAppRetrival(args *dnode.Partial, session *kite.Session) (appUrl string, vos *virt.VOS, dstPath string, err error) {
	var params struct {
		Owner, Name, Version, DstPath string
	}
	if args.Unmarshal(&params) != nil || params.Owner == "" || params.Name == "" || params.DstPath == "" {
		err = &kite.ArgumentError{Expected: "{ owner: [string], name: [string], version: [string], dstPath: [string] }"}
		return
	}

	if params.Version == "" {
		params.Version = "latest"
	}
	appUrl = fmt.Sprintf("https://app.koding.com/%s/%s/%s", params.Owner, params.Name, params.Version)

	user, vm := findSession(session)
	vos = vm.OS(user)
	dstPath = params.DstPath
	return
}

func downloadFile(url string, vos *virt.VOS, path string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}

	file, err := vos.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = io.Copy(file, resp.Body)
	return err
}
