package metadata

import (
	"bytes"
	"errors"
	"fmt"
	"koding/kites/kloud/utils/object"
	"strconv"

	yaml "gopkg.in/yaml.v2"
)

var header = []byte("#cloud-config\n")

// ErrNotCloudInit is returned by ParseCloudInit method, when the
// given content does not look like a cloud-init file.
//
// NOTE(rjeczalik): The content is not verified against
// valid cloud-init syntax, meaning any correctly encoded
// YAML file may give false-positives. This bases on an assumption,
// that YAML-encoded non-cloud-init file cannot be used
// in user_data attribute of kloud provider's instance definition.
var ErrNotCloudInit = errors.New("not a cloud-init content")

// MergeError is returned by Merge function on conflict
// during merging two cloud-init contents.
type MergeError struct {
	Path []string    // object path starting at cloud-init root of conflicting element
	In   interface{} // conflicting element in user's cloud-init
	Out  interface{} // conflicting element in kloud's cloud-init
}

// Error implements the builtin error interface.
func (me *MergeError) Error() string {
	return fmt.Sprintf("unable to merge incompatible values for %v key: in=%T, out=%T", me.Path, me.In, me.Out)
}

// Merge merges two cloud-inits into one.
//
// The in cloud-init is merged into the out one. Merge walks over in and if the keys
// do not conflict - it assignes the value under the same key in out cloud-init.
//
// The only conflict that is allowed are list values that are allowed to exist
// in both cloud-inits. With one exception though, the merged list elements
// must not have conflicts on neither "name" nor "path" keys. This is to prevent
// overwriting users are write_files resources.
//
// If during merge any conflict is encountered, Merge fails with non-nil
// error that is of *MergeError type, which describes details of the conflict.
func Merge(in, out CloudInit) error {
	return merge(in, out)
}

func merge(in, out map[string]interface{}) error {
	type iter struct {
		path []string
		in   map[string]interface{}
		out  map[string]interface{}
	}

	i, stack := iter{}, []iter{{nil, in, out}}

	for len(stack) != 0 {
		i, stack = stack[0], stack[1:]

		for k, v := range i.in {
			switch in := v.(type) {
			case map[string]interface{}:
				switch out := i.out[k].(type) {
				case nil:
					i.out[k] = in
				case map[string]interface{}:
					stack = append(stack, iter{
						path: append(i.path, k),
						in:   in,
						out:  out,
					})
				default:
					return &MergeError{
						Path: append(i.path, k),
						In:   in,
						Out:  out,
					}
				}
			case []interface{}:
				switch out := i.out[k].(type) {
				case nil:
				case []interface{}:
					var err error
					in, err = mergeList(in, out, append(i.path, k))
					if err != nil {
						return err
					}
				default:
					return &MergeError{
						Path: append(i.path, k),
						In:   in,
						Out:  out,
					}
				}

				i.out[k] = in
			default:
				if out, ok := i.out[k]; ok {
					return &MergeError{
						Path: append(i.path, k),
						In:   in,
						Out:  out,
					}
				}

				i.out[k] = in
			}
		}
	}

	return nil
}

var (
	conflictKeys = []string{"path"}
	mergeKeys    = []string{"name"}
)

func mergeList(in, out []interface{}, path []string) ([]interface{}, error) {
	// uniq holds all "path" and "name" keys, assumed to be distinct per elm
	uniq := make(map[string]struct{})

	for _, elm := range out {
		if obj, ok := elm.(map[string]interface{}); ok {
			for _, key := range conflictKeys {
				if val, ok := obj[key].(string); ok && val != "" {
					uniq[val] = struct{}{}
				}
			}
		}
	}

	for i, elm := range in {
		var merged bool

		if obj, ok := elm.(map[string]interface{}); ok {
			// Check for conflicting items.
			for _, key := range conflictKeys {
				val, ok := obj[key].(string)
				if !ok || val == "" {
					continue
				}

				if _, ok := uniq[val]; ok {
					return nil, &MergeError{
						Path: append(path, strconv.Itoa(i), key),
						In:   in,
						Out:  out,
					}
				}
			}

			// Check whether it's possible to merge-in
			// the item.
			for _, key := range mergeKeys {
				val, ok := obj[key].(string)
				if !ok || val == "" {
					continue
				}

				var matching map[string]interface{}

				for i := range out {
					orig, ok := out[i].(map[string]interface{})
					if !ok {
						continue
					}

					if origVal, ok := orig[key].(string); ok && origVal == val {
						matching = orig
						break
					}
				}

				if matching != nil {
					if err := merge(shallowCopy(obj, key), matching); err != nil {
						return nil, err
					}

					out[i] = matching
					merged = true
					break
				}
			}
		}

		if !merged {
			out = append(out, elm)
		}
	}

	return out, nil
}

func shallowCopy(v map[string]interface{}, ignored ...string) map[string]interface{} {
	vCopy := make(map[string]interface{}, len(v))

loop:
	for k, v := range v {
		for _, skip := range ignored {
			if k == skip {
				continue loop
			}
		}

		vCopy[k] = v
	}

	return vCopy
}

// CloudInit is a convenience wrapper for a cloud-init unmarshalled value.
type CloudInit map[string]interface{}

// Bytes encodes cloud-init back to YAML with a proper header,
// suitable for writing it to a file.
func (ci CloudInit) Bytes() []byte {
	p, err := yaml.Marshal(ci)
	if err != nil {
		return nil
	}

	return append(header, p...)
}

// String encodes cloud-init back to YAML with a proper header,
// suitable for writing it to a file.
func (ci CloudInit) String() string {
	return string(ci.Bytes())
}

// CloudConfig describes a configuration for creating
// a kloud's cloud-init that is used to deploy
// a klient service on a remote instance.
type CloudConfig struct {
	Metadata string
	Userdata string
}

// NewCloudInit creates new cloud-init content from
// the given configuration.
func NewCloudInit(cfg *CloudConfig) CloudInit {
	var files, cmd []interface{}

	files = append(files, map[string]interface{}{
		"path":        "/var/lib/koding/provision.sh",
		"permissions": "0755",
		"content":     provision,
	})

	cmd = append(cmd, "/var/lib/koding/provision.sh")

	if cfg.Metadata != "" {
		files = append(files, map[string]interface{}{
			"path":        "/var/lib/koding/metadata.json",
			"content":     cfg.Metadata,
			"permissions": "0644",
		})
	}

	if cfg.Userdata != "" {
		files = append(files, map[string]interface{}{
			"path":        "/var/lib/koding/user-data.sh",
			"permissions": "0755",
			"content":     cfg.Userdata,
		})
	}

	return CloudInit{
		"output": map[string]interface{}{
			"all": "| tee -a /var/log/cloud-init-output.log",
		},
		"hostname": "${var.koding_account_profile_nickname}",
		"users": []interface{}{
			"default",
			map[string]interface{}{
				"name":        "${var.koding_account_profile_nickname}",
				"lock_passwd": bool(true),
				"gecos":       "Koding",
				"groups":      []interface{}{"sudo"},
				"sudo":        []interface{}{"ALL=(ALL) NOPASSWD:ALL"}, // TODO(rjeczalik): limit to only screen + klient
				"shell":       "/bin/bash",
			},
		},
		"write_files":   files,
		"runcmd":        cmd,
		"final_message": "_KD_DONE_",
	}
}

// ParseCloudInit tries to parse the given content
// to a cloud-init representation.
//
// If p does not look like cloud-init content,
// the function returns the ErrNotCloudInit error.
func ParseCloudInit(p []byte) (CloudInit, error) {
	if !bytes.HasPrefix(bytes.TrimSpace(p), header) {
		return nil, ErrNotCloudInit
	}

	var ci map[string]interface{}

	if err := yaml.Unmarshal(p, &ci); err != nil {
		return nil, err
	}

	return CloudInit(object.FixYAML(ci).(map[string]interface{})), nil
}
