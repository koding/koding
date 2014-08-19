package main

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"flag"
	"fmt"
	"io"
	"koding/virt"
	"net/http"
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
	Secret   = "0Z/V3rlxm4xULMnSrPPxLMq~Li/J2mNXkeHRIWWCY2GB5QKIBnlXd8j!8TNcN9T0uiESXfMynR0sxfnXUlLQmS9JrLd6LGkw2VYM"
	log      = logging.NewLogger("useroverlay")
	mode     = flag.String("mode", "serve", "mode can be serve or token")
	certFile = flag.String("cert", "certs/user_file_exporter_self_signed_cert.pem", "TLS cert file")
	keyFile  = flag.String("key", "certs/user_file_exporter_self_signed_key.pem", "TLS key file")
	vm       = flag.String("vm", "", "the vm id")
	username = flag.String("username", "", "the username")
)

func main() {
	flag.Parse()
	switch *mode {
	case "serve":
		serve()
	case "token":
		createToken()
	}
}

func serve() {
	r := mux.NewRouter()
	r.HandleFunc("/export-files", exportFiles).Methods("POST")
	http.Handle("/", basicAuth(r))
	if err := http.ListenAndServeTLS(":3000", *certFile, *keyFile, nil); err != nil {
		log.Error(err.Error())
	}
}

func basicAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if ok, err := checkAuth(w, r); !ok {
			if err != nil {
				log.Error(err.Error())
			}
			respond(w, 403, "Access denied")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func checkAuth(w http.ResponseWriter, r *http.Request) (bool, error) {
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

	// validate the password:
	if pair[1] == stringToken(pair[0], r.PostFormValue("vm")) {
		return true, nil
	}
	return false, nil
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
	id := r.PostFormValue("vm")
	if !bson.IsObjectIdHex(id) {
		return nil, 400, "Bad input", nil
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

func commandError(message string, err error, out []byte) error {
	return fmt.Errorf("%s\n%s\n%s", message, err.Error(), string(out))
}

func createToken() {
	fmt.Println(stringToken(*username, *vm))
}

func stringToken(username, vm string) string {
	hasher := sha256.New()
	hasher.Write([]byte(Secret + username + vm))
	cs := hex.EncodeToString(hasher.Sum(nil))
	return cs
}
