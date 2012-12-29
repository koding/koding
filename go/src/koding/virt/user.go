package virt

import (
	"koding/tools/db"
	"koding/tools/utils"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type User struct {
	Id        int    "_id"
	Name      string "name"
	DefaultVM int    "defaultVM"
}

var Users *mgo.Collection = db.Collection("jUsers2")

func FindUser(query interface{}) (*User, error) {
	var user User
	err := Users.Find(query).One(&user)
	return &user, err
}

func FindUserById(id int) (*User, error) {
	return FindUser(bson.M{"_id": id})
}

func FindUserByName(name string) (*User, error) {
	return FindUser(bson.M{"name": name})
}

// may panic
func (user *User) GetDefaultVM() (vm *VM, needsFormat bool) {
	vm, err := FindVMById(user.DefaultVM)
	if err == nil {
		return vm, false
	}
	if err != mgo.ErrNotFound {
		panic(err)
	}

	vm = FetchUnusedVM(user)
	vm.Name = user.Name
	vm.LdapPassword = utils.RandomString()

	if err := VMs.UpdateId(vm.Id, vm); err != nil {
		panic(err)
	}
	return vm, true
}
