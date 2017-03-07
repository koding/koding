package main

import (
	"flag"
	"fmt"
	"koding/db/models"
	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"os"
	"strings"
	"time"

	mgo "gopkg.in/mgo.v2"

	"github.com/koding/cache"
)

var (
	flagMongoConn       = flag.String("mongo", "", "mongo connection string")
	flagSkip            = flag.Int("s", 0, "Configuration profile from file")
	flagLimit           = flag.Int("l", 1000, "Configuration profile from file")
	flagDry             = flag.Bool("dry", false, "dry run")
	flagColls           = flag.String("colls", "jUsers,jAccounts,jGroups,jWorkspaces,jNames,jComputeStacks,jCombinedAppStorages,relationships", "collections to clean up")
	deletedGroupBySlug  = cache.NewLRU(10000)
	existingGroupBySlug = cache.NewLRU(10000)

	deletedAccountByID    = cache.NewLRU(10000)
	existingAccountByID   = cache.NewLRU(10000)
	existingAccountByNick = cache.NewLRU(10000)
	deletedAccountByNick  = cache.NewLRU(10000)

	existingUserByID   = cache.NewLRU(10000)
	existingUserByNick = cache.NewLRU(10000)
	deletedUserByNick  = cache.NewLRU(10000)
	deadline           = time.Date(2016, time.January, 1, 0, 0, 0, 0, time.UTC)
)

func initialize() {
	flag.Parse()
	if *flagMongoConn == "" {
		fmt.Printf("Please specify mongo conn string.")
		os.Exit(1)
	}

	helper.Initialize(*flagMongoConn)
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
		{ // delete all groups that does not have any members JAccount
			CollName: "jGroups",
			Func:     deleteGroups,
			Filter:   filter(),
			Res:      &models.Group{},
		},
		{ // delete koding provided jMachines
			CollName: "jMachines",
			Func:     deleteMachines,
			Filter:   filter(),
			Res:      &models.Machine{},
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

	_, err := helper.GetMachineByUid(ws.MachineUID)
	if err == mgo.ErrNotFound {
		fmt.Printf("deleting WS with UID (corresponding machine does not exist) %q\n", ws.ObjectId.Hex())
		if !*flagDry {
			return helper.RemoveWorkspace(ws.ObjectId)
		}
	}

	if !getAccountByID(ws.OriginId.Hex()) {
		fmt.Printf("deleting WS with owner (corresponding acc does not exist) %q\n", ws.ObjectId.Hex())
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
			if getGroupBySlug(slug.Slug) {
				continue
			}
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

	if cs.Group != "koding" && getAccountByID(cs.OriginId.Hex()) && getGroupBySlug(cs.Group) {
		return nil
	}

	fmt.Printf("deleting jComputeStack %q\n", cs.Id.Hex())
	if !*flagDry {
		return helper.DeleteComputeStack(cs.Id.Hex())
	}

	return nil
}

func deleteGroups(res interface{}) error {
	g := res.(*models.Group)
	if isIn(g.Slug, "koding", "guests", "team") {
		return nil
	}

	admins, err := helper.FetchAdminAccounts(g.Slug)
	// if we have any admin, no need to delete
	if len(admins) > 0 {
		existingGroupBySlug.Set(g.Slug, struct{}{})
		return nil
	}

	// if we have error other than not found, it is better not to delete
	if err != mgo.ErrNotFound {
		return nil
	}

	fmt.Printf("deleting jGroup %q\n", g.Slug)
	if !*flagDry {
		return helper.RemoveGroup(g.Id)
	}

	return nil
}

func deleteMachines(res interface{}) error {
	m := res.(*models.Machine)
	if m.Provider != "koding" {
		return nil
	}

	if len(m.Groups) > 1 {
		return nil
	}

	fmt.Printf("deleting jMachine %q\n", m.ObjectId.Hex())
	if !*flagDry {
		return helper.DeleteMachine(m.ObjectId)
	}

	return nil
}

func deleteCombinedAppStorages(res interface{}) error {
	cs := res.(*models.CombinedAppStorage)

	if getAccountByID(cs.AccountId.Hex()) {
		storages, err := helper.GetAllCombinedAppStorageByAccountId(cs.AccountId)
		if err != nil {
			return err
		}
		if len(storages) > 1 {
			mergedStorage := mergeCombinedAppStorageData(storages)
			_, err := combineWithDeletion(mergedStorage, storages)
			if err != nil {
				return err
			}
		}
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

	if !r.Id.Valid() {
		fmt.Printf("could not delete rel because id is not valid: %q \n", r)
		return nil
	}

	if !r.TargetId.Valid() || !r.SourceId.Valid() {
		fmt.Printf("deleted because of target id or source id is not valid: id: %q target: %q source: %q\n", r.Id.Hex(), r.TargetId, r.SourceId)
		if !*flagDry {
			return helper.DeleteRelationship(r.Id)
		}
		return nil
	}

	var data interface{}
	targetCollectionName := helper.GetCollectionName(r.TargetName)
	if err := helper.Mongo.One(targetCollectionName, r.TargetId.Hex(), &data); err == mgo.ErrNotFound {
		fmt.Printf("deleted because of target: id: %q from: %q name: %q\n", r.Id.Hex(), targetCollectionName, r.TargetName)
		if !*flagDry {
			return helper.DeleteRelationship(r.Id)
		}
		return nil
	}

	sourceCollectionName := helper.GetCollectionName(r.SourceName)
	if err := helper.Mongo.One(sourceCollectionName, r.SourceId.Hex(), &data); err == mgo.ErrNotFound {
		fmt.Printf("deleting because of source: id: %q from: %q name: %q\n", r.Id.Hex(), sourceCollectionName, r.SourceName)
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

func getGroupBySlug(slug string) bool {
	if isIn(slug, "koding", "guests", "team") {
		return true
	}

	if _, err := existingGroupBySlug.Get(slug); err == nil {
		return true
	}

	if _, err := deletedGroupBySlug.Get(slug); err == nil {
		return false
	}

	_, err := helper.GetGroup(slug)
	if err == mgo.ErrNotFound {
		deletedGroupBySlug.Set(slug, struct{}{})
		return false
	}

	// treat them as existing on random errors
	if err != nil {
		fmt.Printf("err while getting group by slug %q, %s\n", slug, err)
		return true
	}

	existingGroupBySlug.Set(slug, struct{}{})

	return true
}

func mergeCombinedAppStorageData(storages []models.CombinedAppStorage) models.CombinedAppStorage {
	var updatedAppStorage models.CombinedAppStorage
	// init CombinedAppStorage bucket
	updatedAppStorage.Bucket = make(map[string]map[string]map[string]interface{})

	for _, storage := range storages {
		for appName, bucket := range storage.Bucket {
			// if app does not have any data, remove it by ignoring.
			if _, ok := bucket["data"]; !ok || len(bucket["data"]) == 0 {
				continue
			}

			// if we dont have the app in the new app storage, assign it.
			if _, ok := updatedAppStorage.Bucket[appName]; !ok {
				updatedAppStorage.Bucket[appName] = bucket
				continue
			}

			// if we have the app in the merged one, only fill non-existing keys.
			for key, value := range bucket["data"] {
				if _, ok := updatedAppStorage.Bucket[appName]["data"][key]; !ok {
					updatedAppStorage.Bucket[appName]["data"][key] = value
				}
			}
		}
	}

	return updatedAppStorage
}

// combineWithDeletion updates the first CombinedAppStorage with new merged
// bucket and deletes other CombinedAppStorages
func combineWithDeletion(mergedStorage models.CombinedAppStorage, storages []models.CombinedAppStorage) (*models.CombinedAppStorage, error) {
	for i := 0; i < len(storages); i++ {
		if i == 0 {
			// UPDATE CombinedAppStorage with its new Bucket data
			storages[i].Bucket = mergedStorage.Bucket
			if err := helper.UpdateCombinedAppStorage(&storages[i]); err != nil {
				return nil, err
			}
		} else {
			// DELETE CombinedAppStorages in this block
			if err := helper.RemoveCombinedAppStorage(storages[i].Id); err != nil {
				return nil, err
			}
		}
	}

	return &storages[0], nil
}

func isIn(s string, ts ...string) bool {
	for _, t := range ts {
		if t == s {
			return true
		}
	}

	return false
}
