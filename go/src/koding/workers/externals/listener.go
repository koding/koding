package main

import (
	"koding/tools/dnode"
	"koding/tools/kite"
	"log"
)

// k = KD.getSingleton("kiteController").run({kiteName:"externals", method:"import", withArgs:{value:"7b010664e515af5f46c8f1e2ad124a7b30676929", serviceName:"github", userId:KD.whoami().getId()}}, console.log.bind(console))

func main() {
	log.Println("Starting worker...")

	externals := kite.New("externals", false)
	externals.Handle("import", false, func(args *dnode.Partial, channel *kite.Channel) (interface{}, error) {
		var token Token
		err := args.Unmarshal(&token)
		if err != nil {
			return nil, logAndReturnErr("%v", err)
		}
		if token.ServiceName == "" || token.UserId == "" || token.Value == "" {
			return nil, logAndReturnErr("Empty field in Token: %v", token)
		}

		log.Printf("Started import of '%v' with token value: %v", token.ServiceName, token.Value)

		err = ImportExternalToGraph(token)
		if err != nil {
			return nil, err
		}

		return true, nil
	})
	externals.Run()
}
