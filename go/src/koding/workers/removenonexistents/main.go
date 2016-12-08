package main

import (
	"flag"
	"fmt"
	"koding/db/models"
	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"koding/tools/config"
	"koding/tools/logger"

	mgo "gopkg.in/mgo.v2"

	"github.com/koding/cache"
	"github.com/kr/pretty"
)

var log = logger.New("non existents")

var (
	conf        *config.Config
	flagProfile = flag.String("c", "prod", "Configuration profile from file")
	flagSkip    = flag.Int("s", 0, "Configuration profile from file")
	flagLimit   = flag.Int("l", 1000, "Configuration profile from file")
)

func initialize() {
	flag.Parse()
	log.SetLevel(logger.DEBUG)
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)
}

func main() {
	// init the package
	initialize()
	log.Info("Obsolete Deleter worker started")

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
	}
	fmt.Printf("resources %# v\n", pretty.Formatter(resources))
	for _, res := range resources {
		fmt.Printf("res %# v\n", pretty.Formatter(res))
		iterOptions := helpers.NewIterOptions()
		iterOptions.CollectionName = res.CollName
		iterOptions.F = res.Func
		iterOptions.Filter = res.Filter
		iterOptions.Result = res.Res
		iterOptions.Limit = *flagLimit
		iterOptions.Skip = *flagSkip
		iterOptions.Log = log

		log.Info("starting operating on ", res.CollName)
		err := helpers.Iter(helper.Mongo, iterOptions)
		if err != nil {

			log.Fatal("Error while iter", err)
		}
		log.Info("finished with ", res.CollName)
	}

	log.Info("worker done!")
}

func filter() helper.Selector {
	return helper.Selector{}
}

func deleteUser(rel interface{}) error {
	result := rel.(*models.User)
	// on error cases, treat them like they exist
	if !getAccountByNick(result.Name) {
		fmt.Printf("user %# v\n", pretty.Formatter(result.Name))
	}

	existingUserByID.Set(result.ObjectId.Hex(), struct{}{})
	existingUserByNick.Set(result.Name, result.ObjectId.Hex())
	return nil
}

func deleteAccount(res interface{}) error {
	acc := res.(*models.Account)
	// on error cases, treat them like they exist
	if !getUserByNick(acc.Profile.Nickname) {
		fmt.Printf("acc %# v\n", pretty.Formatter(acc.Profile.Nickname))
	}

	existingAccountByID.Set(acc.Id.Hex(), struct{}{})
	existingAccountByNick.Set(acc.Profile.Nickname, acc.Id.Hex())
	return nil
}

func deleteWorkspaces(res interface{}) error {
	ws := res.(*models.Workspace)

	_, err := helper.GetWorkspacesForMachine(&models.Machine{Uid: ws.MachineUID})
	if err == mgo.ErrNotFound {
		fmt.Printf("machine does not exist %# v\n", pretty.Formatter(ws.MachineUID))
	}

	if !getAccountByID(ws.Owner) {
		fmt.Printf("owner of the ws does not exit, delete it! %# v\n", pretty.Formatter(ws.Owner))
	}

	return nil
}

var (
	deletedAccountByID    = cache.NewLRU(10000)
	existingAccountByID   = cache.NewLRU(10000)
	existingAccountByNick = cache.NewLRU(10000)
	deletedAccountByNick  = cache.NewLRU(10000)

	deletedUserByID    = cache.NewLRU(10000)
	existingUserByID   = cache.NewLRU(10000)
	existingUserByNick = cache.NewLRU(10000)
	deletedUserByNick  = cache.NewLRU(10000)
)

func getAccountByNick(nick string) bool {
	if _, err := existingAccountByNick.Get(nick); err == nil {
		return true
	}

	if _, err := deletedAccountByNick.Get(nick); err == nil {
		return false
	}

	acc, err := helper.GetAccount(nick)
	if err == nil {
		id := acc.Id.Hex()
		existingAccountByID.Set(id, struct{}{})
		existingAccountByNick.Set(acc.Profile.Nickname, id)
	}

	if err == mgo.ErrNotFound {
		deletedAccountByNick.Set(nick, struct{}{})
		return false
	}

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
	if err == nil {
		id := user.ObjectId.Hex()
		existingUserByID.Set(id, struct{}{})
		existingUserByNick.Set(user.Name, id)
	}

	if err == mgo.ErrNotFound {
		deletedUserByNick.Set(nick, struct{}{})
		return false
	}

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
	if err == nil {
		existingAccountByID.Set(id, struct{}{})
		existingAccountByNick.Set(acc.Profile.Nickname, id)
	}

	if err == mgo.ErrNotFound {
		deletedAccountByID.Set(id, struct{}{})
		return false
	}

	return true
}
