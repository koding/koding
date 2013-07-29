package main

// Client is an interface to get info from external apis.
//
// Currently we import three types of structures from external apis:
// users, tags and groups. It's upto the client to decide which
// external structure matches Koding's internal one. Ex: Github client
// matches Github's Organizations to Koding's groups.
//
// Methods with `Fetch` prefix indicate, they'll return info from
// external source.
type Client interface {

	// Fetches profile info about user, to be stored in an alias node.
	// This node will have a relationship to the original user node with
	// type `related` and weight 1. Any node created with info from
	// this external source will point to this alias node only.
	FetchUserInfo() (strToInf, error)

	// Fetches other users, this user has a close connection to.
	FetchFriends() (strToInf, error)

	// Fetches tags which the user has interacted with.
	FetchTags() (strToInf, error)

	// Fetches groups of individual users who are connected to the user
	// in a formalized way and each other as defined by the external source.
	//FetchGroups() (strToInf, error)
}

// Helper type; key is client name, value is constructor for that client.
//
// Ex:
//    {"clientName" : NewServiceClient}
type listOfClients map[string]clientConstructor

// Helper type; all client constructors must've this signature.
type clientConstructor func(Token) Client

// Stores list of clients & its constructor.
var (
	clients = listOfClients{
		"github": NewGithubClient,
	}
)

func getClientsForService(token Token) Client {
	client := clients[token.ServiceName]
	if client == nil {
		return nil
	}

	return client(token)
}
