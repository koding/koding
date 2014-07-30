package main

import (
	"encoding/base64"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"koding/virt"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/koding/logging"
	"labix.org/v2/mgo/bson"
)

var (
	log      = logging.NewLogger("useroverlay")
	username = flag.String("username", "guest", "basic auth username")
	password = flag.String("password", "guest", "basic auth password")
	certFile = flag.String("cert", "certs/user_file_exporter_self_signed_cert.pem", "TLS cert file")
	keyFile  = flag.String("key", "certs/user_file_exporter_self_signed_key.pem", "TLS key file")
)

func main() {
	flag.Parse()
	r := mux.NewRouter()
	r.HandleFunc("/export-files", exportFiles).Methods("POST")
	http.Handle("/", basicAuth(r, *username, *password))
	if err := http.ListenAndServeTLS(":3000", *certFile, *keyFile, nil); err != nil {
		log.Error(err.Error())
	}
}

func basicAuth(next http.Handler, u, p string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if ok, err := checkAuth(w, r, u, p); !ok {
			if err != nil {
				log.Error(err.Error())
			}
			respond(w, 403, "Access denied")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func checkAuth(w http.ResponseWriter, r *http.Request, u, p string) (bool, error) {
	auth := r.Header.Get("Authorization")
	s := strings.SplitN(auth, " ", 2)
	if len(s) != 2 {
		return false, fmt.Errorf("Invalid authorization header: '%v'", auth)
	}

	b, err := base64.StdEncoding.DecodeString(s[1])
	if err != nil {
		return false, err
	}

	pair := strings.SplitN(string(b), ":", 2)
	if len(pair) != 2 {
		return false, fmt.Errorf("Invalid authorization header: '%v'", auth)
	}

	return pair[0] == u && pair[1] == p, nil
}

func exportFiles(w http.ResponseWriter, r *http.Request) {
	vm, status, message, err := validateRequest(w, r)
	if err != nil {
		log.Error(err.Error())
	}

	if status != 200 {
		respond(w, status, message)
		return
	}

	archive, err := exportUserFiles(vm)
	if err != nil {
		respond(w, 500, err.Error())
		return
	}
	w.Header().Set("Content-type", "application/octet-stream")
	if _, err := io.Copy(w, archive); err != nil {
		log.Error(err.Error())
	}
}

func validateRequest(w http.ResponseWriter, r *http.Request) (*virt.VM, int, string, error) {
	body, err := readBody(r.Body)
	if err != nil {
		return nil, 500, "Couldn't read POST data", err
	}

	id, err := getVmId(body)
	if err != nil || !bson.IsObjectIdHex(id) {
		return nil, 400, "Bad input", err
	}
	vm := &virt.VM{Id: bson.ObjectIdHex(id)}

	exists, err := vm.ExistsRBD()
	if err != nil {
		return vm, 500, "Internal error", err
	}
	if !exists {
		return vm, 404, "Not found", nil
	}
	if err := vm.LockRBD(); err != nil {
		return vm, 412, "RBD cannot be locked", err
	}
	defer func() {
		if err := vm.UnlockRBD(); err != nil {
			log.Error(err.Error())
		}
	}()
	return vm, 200, "", nil
}

func exportUserFiles(vm *virt.VM) (io.Reader, error) {
	// map the RBD:
	if out, err := exec.Command("/usr/bin/rbd", "map", "--pool", virt.VMPool, "--image", vm.String()).CombinedOutput(); err != nil {
		return nil, commandError("rbd map failed.", err, out)
	}
	defer func() {
		if out, err := exec.Command("/usr/bin/rbd", "unmap", "/dev/rbd/"+virt.VMPool+"/"+vm.String()).CombinedOutput(); err != nil {
			log.Error(commandError("rbd unmap failed.", err, out).Error())
		}
	}()
	// generate a timestamp for uniqueness:
	timestamp := strconv.FormatInt(time.Now().Local().Unix(), 10)
	baseName := "export-" + vm.String() + "-" + timestamp
	dirName := "/tmp/" + baseName
	archiveName := dirName + ".tgz"
	// make a blank directory to export to:
	if err := os.Mkdir(dirName, os.ModeDir); err != nil {
		return nil, err
	}
	defer func() {
		// remove the working directory:
		if err := os.RemoveAll(dirName); err != nil {
			log.Error(err.Error())
		}
	}()
	// mount the rbd over an empty rootfs:
	if out, err := exec.Command("/bin/mount", "-o", "ro", "-t", "ext4", "/dev/rbd/vms/"+vm.String(), dirName).CombinedOutput(); err != nil {
		return nil, commandError("mount failed.", err, out)
	}
	defer func() {
		// unmount the rbd:
		if out, err := exec.Command("/bin/umount", dirName).CombinedOutput(); err != nil {
			log.Error(commandError("umount failed.", err, out).Error())
		}
	}()
	// tar the resulting directory structure:
	if out, err := exec.Command("/bin/tar", "--directory", "/tmp", "-czf", archiveName, baseName).CombinedOutput(); err != nil {
		return nil, commandError("tar failed.", err, out)
	}
	defer func() {
		// remove the archive:
		if err := os.Remove(archiveName); err != nil {
			log.Error(err.Error())
		}
	}()

	return os.Open(archiveName)
}

func respond(w http.ResponseWriter, code int, body string) {
	w.WriteHeader(code)
	io.WriteString(w, body)
}

func readBody(b io.ReadCloser) (string, error) {
	body, err := ioutil.ReadAll(b)
	if err != nil {
		return "", err
	}

	defer b.Close()

	return string(body), nil
}

func getVmId(q string) (string, error) {
	query, err := url.ParseQuery(q)
	if err != nil {
		return "", err
	}
	if len(query["vm"]) > 0 {
		return query["vm"][0], nil
	}
	return "", fmt.Errorf("VM id not provided: '%v'", q)
}

func commandError(message string, err error, out []byte) error {
	return fmt.Errorf("%s\n%s\n%s", message, err.Error(), string(out))
}
