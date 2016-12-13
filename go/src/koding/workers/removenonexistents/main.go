package main

import (
	"flag"
	"fmt"
	"koding/db/models"
	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"koding/tools/config"
	"os"
	"strings"
	"time"

	mgo "gopkg.in/mgo.v2"

	"github.com/koding/cache"
)

var (
	conf        *config.Config
	flagProfile = flag.String("c", "prod", "Configuration profile from file")
	flagSkip    = flag.Int("s", 0, "Configuration profile from file")
	flagLimit   = flag.Int("l", 1000, "Configuration profile from file")
	flagDry     = flag.Bool("dry", false, "dry run")
	flagColls   = flag.String("colls", "jUsers,jAccounts,jWorkspaces,jNames,jComputeStacks,jCombinedAppStorages,relationships", "collections to clean up")

	deletedAccountByID    = cache.NewLRU(10000)
	existingAccountByID   = cache.NewLRU(10000)
	existingAccountByNick = cache.NewLRU(10000)
	deletedAccountByNick  = cache.NewLRU(10000)

	deletedUserByID    = cache.NewLRU(10000)
	existingUserByID   = cache.NewLRU(10000)
	existingUserByNick = cache.NewLRU(10000)
	deletedUserByNick  = cache.NewLRU(10000)
	deadline           = time.Date(2016, time.January, 1, 0, 0, 0, 0, time.UTC)
)

func initialize() {
	flag.Parse()
	if *flagProfile == "" {
		fmt.Printf("Please specify profile via -c. Aborting.")
		os.Exit(1)
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)
}

func main() {
	// init the package
	initialize()
	fmt.Println("Non existent deleter started")

	resources := []struct {
		CollName string
		Func     func(interface{}) error
		Filter   helper.Selector
		Res      interface{}
	}{
		{ // Delete JUsers that does not have JAccount
			CollName: "jUsers",
			Func:     deleteUser,
			Filter:   filter(),
			Res:      &models.User{},
		},
		{ // Delete JAccounts that does not have JUser
			CollName: "jAccounts",
			Func:     deleteAccount,
			Filter:   filter(),
			Res:      &models.Account{},
		},
		{ // delete JWorkspaces that does not have JMachine.
			CollName: "jWorkspaces",
			Func:     deleteWorkspaces,
			Filter:   filter(),
			Res:      &models.Workspace{},
		},
		{ // delete jNames that have invalid collectionName.
			CollName: "jNames",
			Func:     deleteNames,
			Filter:   filter(),
			Res:      &models.Name{},
		},
		{ // delete jComputeStacks that does not have the account.
			CollName: "jComputeStacks",
			Func:     deleteComputeStacks,
			Filter:   filter(),
			Res:      &models.ComputeStack{},
		},
		{ // delete all jCombinedAppStorages which "accountId" does not exist in JAccount
			CollName: "jCombinedAppStorages",
			Func:     deleteCombinedAppStorages,
			Filter:   filter(),
			Res:      &models.CombinedAppStorage{},
		},
		{ // delete all rels that does not have source or target
			CollName: "relationships",
			Func:     deleteRels,
			Filter:   filter(),
			Res:      &models.Relationship{},
		},
	}
	collsToClean := strings.Split(*flagColls, ",")
	fmt.Printf("will clean up following %q\n", collsToClean)

	for _, res := range resources {
		if !isIn(res.CollName, collsToClean...) {
			fmt.Printf("skipping %q it is not in op list\n", res.CollName)
			continue
		}

		iterOptions := helpers.NewIterOptions()
		iterOptions.CollectionName = res.CollName
		iterOptions.F = res.Func
		iterOptions.Filter = res.Filter
		iterOptions.Result = res.Res
		iterOptions.Limit = *flagLimit
		iterOptions.Skip = *flagSkip

		fmt.Printf("starting operating on %q\n", res.CollName)
		err := helpers.Iter(helper.Mongo, iterOptions)
		if err != nil {
			fmt.Printf("Error while iter %s\n", err)
			os.Exit(1)
		}
		fmt.Printf("finished with %s\n", res.CollName)
	}

	fmt.Println("worker done!")
}

func filter() helper.Selector {
	return helper.Selector{}
}

func deleteUser(rel interface{}) error {
	result := rel.(*models.User)
	if getAccountByNick(result.Name) && result.LastLoginDate.After(deadline) && result.Status != "deleted" {
		return nil
	}

	fmt.Printf("deleting user %q\n", result.Name)
	if !*flagDry {
		return helper.RemoveUser(result.Name)
	}

	return nil
}

func deleteAccount(res interface{}) error {
	acc := res.(*models.Account)
	if getUserByNick(acc.Profile.Nickname) {
		return nil
	}

	fmt.Printf("deleting acc %q\n", acc.Profile.Nickname)
	if !*flagDry {
		return helper.RemoveAccount(acc.Id)
	}

	return nil
}

func deleteWorkspaces(res interface{}) error {
	ws := res.(*models.Workspace)

	_, err := helper.GetWorkspacesForMachine(&models.Machine{Uid: ws.MachineUID})
	if err == mgo.ErrNotFound {
		fmt.Printf("deleting WS with UID (corresponding machine does not exist) %q\n", ws.MachineUID)
		if !*flagDry {
			return helper.RemoveWorkspace(ws.ObjectId)
		}
	}

	if !getAccountByID(ws.Owner) {
		fmt.Printf("deleting WS with owner %q (corresponding acc does not exist)\n", ws.Owner)
		if !*flagDry {
			return helper.RemoveWorkspace(ws.ObjectId)
		}
	}

	return nil
}

func deleteNames(res interface{}) error {
	name := res.(*models.Name)

	for _, slug := range name.Slugs {
		if slug.ConstructorName == "JGroup" {
			continue
		}

		if slug.ConstructorName == "JUser" {
			// if we have the user in db, do not delete, but if not continue,
			// following code will remove it eventually
			if getAccountByNick(slug.Slug) { // slug is username
				continue
			}
		}

		fmt.Printf("deleting jname %q\n", name.ID)
		if !*flagDry {
			return helper.RemoveName(name.ID)
		}
	}

	return nil
}

// * delete all jComputeStacks which "originId" does not exist in JAccount
// * delete alljComputeStacks which { group:koding }
func deleteComputeStacks(res interface{}) error {
	cs := res.(*models.ComputeStack)

	if getAccountByID(cs.OriginId.Hex()) && cs.Group != "koding" {
		return nil
	}

	fmt.Printf("deleting jComputeStack %q\n", cs.Id.Hex())
	if !*flagDry {
		return helper.DeleteComputeStack(cs.Id.Hex())
	}

	return nil
}

func deleteCombinedAppStorages(res interface{}) error {
	cs := res.(*models.CombinedAppStorage)

	if getAccountByID(cs.AccountId.Hex()) {
		return nil
	}

	fmt.Printf("deleting CombinedAppStorage %q\n", cs.Id)
	if !*flagDry {
		return helper.RemoveCombinedAppStorage(cs.Id)
	}
	return nil
}

func deleteRels(res interface{}) error {
	r := res.(*models.Relationship)

	var data interface{}
	targetCollectionName := helper.GetCollectionName(r.TargetName)
	if err := helper.Mongo.One(targetCollectionName, r.TargetId.Hex(), &data); err != nil {
		fmt.Printf("deleted because of target: id %q from %q name %q\n", r.TargetId.Hex(), targetCollectionName, r.TargetName)
		if !*flagDry {
			return helper.DeleteRelationship(r.Id)
		}
	}

	sourceCollectionName := helper.GetCollectionName(r.SourceName)
	if err := helper.Mongo.One(sourceCollectionName, r.SourceId.Hex(), &data); err != nil {
		fmt.Printf("deleting because of source: id %q from %q name %q\n", r.SourceId.Hex(), sourceCollectionName, r.SourceName)
		if !*flagDry {
			return helper.DeleteRelationship(r.Id)
		}
	}

	return nil
}

func getAccountByNick(nick string) bool {
	if _, err := existingAccountByNick.Get(nick); err == nil {
		return true
	}

	if _, err := deletedAccountByNick.Get(nick); err == nil {
		return false
	}

	acc, err := helper.GetAccount(nick)
	if err == mgo.ErrNotFound {
		deletedAccountByNick.Set(nick, struct{}{})
		return false
	}

	// treat them as existing on random errors
	if err != nil {
		fmt.Printf("err while getting acc by nick %q, %s\n", nick, err.Error())
		return true
	}

	id := acc.Id.Hex()
	if acc.Type == "deleted" {
		deletedAccountByID.Set(id, struct{}{})
		deletedAccountByNick.Set(acc.Profile.Nickname, struct{}{})
		return false
	}

	existingAccountByID.Set(id, struct{}{})
	existingAccountByNick.Set(acc.Profile.Nickname, id)

	return true
}

func getUserByNick(nick string) bool {
	if _, err := existingUserByNick.Get(nick); err == nil {
		return true
	}

	if _, err := deletedUserByNick.Get(nick); err == nil {
		return false
	}

	user, err := helper.GetUser(nick)
	if err == mgo.ErrNotFound {
		deletedUserByNick.Set(nick, struct{}{})
		return false
	}

	// treat them as existing on random errors
	if err != nil {
		fmt.Printf("err while getting user by nick %q, %s\n", nick, err.Error())
		return true
	}

	if user.Status == "deleted" {
		deletedUserByNick.Set(nick, struct{}{})
		return false
	}

	id := user.ObjectId.Hex()
	existingUserByID.Set(id, struct{}{})
	existingUserByNick.Set(user.Name, id)

	return true
}

func getAccountByID(id string) bool {
	if _, err := existingAccountByID.Get(id); err == nil {
		return true
	}

	if _, err := deletedAccountByID.Get(id); err == nil {
		return false
	}

	acc, err := helper.GetAccountById(id)
	if err == mgo.ErrNotFound {
		deletedAccountByID.Set(id, struct{}{})
		return false
	}

	// treat them as existing on random errors
	if err != nil {
		fmt.Printf("err while getting acc by id %q, %s\n", id, err.Error())
		return true
	}

	if acc.Type == "deleted" {
		deletedAccountByID.Set(id, struct{}{})
		deletedAccountByNick.Set(acc.Profile.Nickname, struct{}{})
		return false
	}

	existingAccountByID.Set(id, struct{}{})
	existingAccountByNick.Set(acc.Profile.Nickname, id)

	return true
}

func isIn(s string, ts ...string) bool {
	for _, t := range ts {
		if t == s {
			return true
		}
	}

	return false
}
