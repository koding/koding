package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/migrators/useroverlay/token"
	"strings"
	"text/template"

	"github.com/pkg/sftp"
)

var (
	migrationTemplate = template.Must(template.New("script").Parse(migrationScript))
	migrationScript   = `#!/bin/bash
username={{ .Username }}
credentials=({{ .PasswordsStr }})
vm_names=({{ .VmNames }})
vm_ids=({{ .VmIds }})
count=$((${#credentials[@]} - 1))
counter=0
echo
echo "We've upgraded your VM! Please follow the instructions below to transfer files from your old VM."
echo
echo "VMs:"
echo
for vm in "${vm_names[@]}"; do
  echo " - [$counter] $vm"
  let counter=counter+1
done
echo
index=''
while [[ ! $index =~ ^[0-9]+$ || $index -ge $counter ]]; do
  echo -n "Which vm would you like to migrate? (0-$count) "
  read index
done
vm_name="${vm_names[$index]}"
echo
echo "Downloading files from $vm_name..."
echo
archive="${vm_names[$index]}.tgz"
echo "-XPOST -u $username:${credentials[$index]} -d vm=${vm_ids[$index]} --insecure https://kontainer12.sj.koding.com:3000/export-files" | xargs curl > $archive
echo
echo "Extracting your files to directory $(pwd)/$vm_name..."
mkdir $vm_name > /dev/null 2>&1
tar -xzvf $archive -C $vm_name --strip-components 1 > /dev/null 2>&1
rm $archive
echo
echo "Done."

`
)

func (k *KodingDeploy) setupMigrateScript(client *sftp.Client, username string) error {
	vms, err := modelhelper.GetUserVMs(username)
	if err != nil {
		return err
	}
	if len(vms) == 0 {
		return nil
	}

	passwords := make([]string, len(vms))
	vmIds := make([]string, len(vms))
	vmNames := make([]string, len(vms))

	for _, vm := range vms {
		id := vm.Id.Hex()
		passwords = append(passwords, token.StringToken(username, id))
		vmIds = append(vmIds, id)
		vmNames = append(vmNames, vm.HostnameAlias)
	}

	data := struct {
		Username     string
		PasswordsStr string
		VmIds        string
		VmNames      string
	}{
		Username:     username,
		PasswordsStr: strings.Join(passwords, " "),
		VmIds:        strings.Join(vmIds, " "),
		VmNames:      strings.Join(vmNames, " "),
	}

	scriptPath := "/home/" + username + "/migrate.sh"

	f, err := client.Create(scriptPath)
	if err != nil {
		return err
	}

	if err = client.Chmod(scriptPath, 0755); err != nil {
		return err
	}

	return migrationTemplate.Execute(f, data)
}
