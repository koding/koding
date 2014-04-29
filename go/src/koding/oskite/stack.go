package oskite

import (
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"os/exec"
	"path/filepath"
)

const customTemplate = `touch hello.txt
echo "fatih" >> hello.txt
echo $DENEME
`

type Templater interface {
	Create() error
}

type createParamsOld struct {
	OnProgress dnode.Callback
}

func (c *createParamsOld) Enabled() bool      { return c.OnProgress != nil }
func (c *createParamsOld) Call(v interface{}) { c.OnProgress(v) }

func vmCreateOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	params := new(createParamsOld)
	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	return vmCreate(params, vos)
}

func vmCreate(params progresser, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return executeScript(customTemplate, vos)

	return progress(vos, "vm.create "+vos.VM.HostnameAlias, params, func() error {
		results := make(chan *virt.Step)
		go prepareProgress(results, vos)

		for step := range results {
			if params.Enabled() {
				params.Call(step)
			}

			if step.Err != nil {
				return step.Err
			}
		}

		executeScript(customTemplate, vos)

		return nil
	})
}

// executeScript invokes the given script as root in the corresponding vos vm
// and returns the output
func executeScript(initScript string, vos *virt.VOS) (interface{}, error) {
	file, err := vos.TempFile("oskite-stack")
	if err != nil {
		return nil, err
	}
	defer file.Close()
	defer os.Remove(file.Name())

	file.WriteString(initScript)

	fileName := filepath.Join("/tmp", filepath.Base(file.Name()))
	args := []string{"--name", vos.VM.String(), "--", "/bin/bash", fileName}
	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	cmd.Env = []string{"TERM=xterm-256color"}
	cmd.Env = append(cmd.Env, "DENEME=fatih")

	return newOutput(cmd)
}
