package main

import (
	"encoding/json"
	"errors"
	"fmt"
	neo "github.com/siesta/neo4j"
	"log"
)

func init() {
	log.SetPrefix("Externals: ")
	mongo = &Mongo{}
}

// Represents format of message from RabbitMQ.
//    `ServiceName` is name of external api: github, facebook etc.
//    `Value` is the oauth token used to make requests.
//    `UserId` is from document db; external info will point to this.
type Token struct {
	ServiceName string `json:"serviceName"`
	Value       string `json:"value"`
	UserId      string `json:"userId"`
}

func ImportExternalToGraph(token Token) error {
	client := getClientsForService(token)
	if client == nil {
		return logAndReturnErr("No client found for: '%v'", token.ServiceName)
	}

	internalUser, exists := mongo.GetUser(token.UserId)
	if !exists {
		return logAndReturnErr("User: '%v' does not exist in document db", token.UserId)
	}

	externalUser, err := client.FetchUserInfo()
	if err != nil {
		return logAndReturnErr("Failed to get user info: '%v' from '%v' with: %v",
			token.UserId, token.ServiceName, err)
	}

	edge, err := saveInternalAndExternalUser(internalUser, externalUser, token)
	if err != nil {
		return logAndReturnErr("Saving user: '%v' failed with: '%v'", token.UserId, err)
	}

	externalTopics, err := getExportableContent(client.FetchTags)
	if err != nil {
		return logAndReturnErr("Fetching external content from '%v' failed with '%v'",
			token.ServiceName, err)
	}

	startName := "JTag"
	matched, err := matchToInternalAndCreateEdges(externalTopics, matchTag, edge.EndNode, token, startName)
	if err != nil {
		return logAndReturnErr("Matching internal to external tag failed with '%v'", err)
	}
	log.Printf("Imported %v 'JTags' for token: '%v'", matched, token.Value)

	externalUsers, err := getExportableContent(client.FetchFriends)
	if err != nil {
		return logAndReturnErr("Fetching external content from '%v' failed with '%v'",
			token.ServiceName, err)
	}

	startName = "JUser"
	matched, err = matchToInternalAndCreateEdges(externalUsers, matchUser, edge.EndNode, token, startName)
	if err != nil {
		return logAndReturnErr("Matching internal to external user failed with '%v'", err)
	}
	fmt.Printf("Imported %v 'JUsers' for token: '%v'", matched, token.Value)

	return nil
}

func saveInternalAndExternalUser(internalUser, externalUser strToInf, token Token) (*NeoEdge, error) {
	internalUserId := token.UserId
	externalUserId := fmt.Sprintf("%v_%v", token.ServiceName, externalUser["id"].(string))
	externalUser["_id"] = externalUser["id"]
	externalUser["id"] = externalUserId

	edge := NewNeoEdge(RelationData{
		Name:      "related",
		StartId:   internalUserId,
		EndId:     externalUserId,
		StartName: "JAccount",
		EndName:   "JAccount_oAuth",
	})
	edge.StartNode = &neo.Node{Data: internalUser}
	edge.EndNode = &neo.Node{Data: externalUser}

	err := edge.CreateNodes()
	if err != nil {
		return edge, err
	}

	err = edge.CreateRelationship()

	return edge, err
}

type callFn func() (strToInf, error)

func getExportableContent(cFn callFn) (strToInf, error) {
	matched, err := cFn()
	if err != nil {
		return nil, err
	}
	if len(matched) == 0 {
		return nil, logAndReturnErr("No external found ...")
	}

	return matched, nil
}

type matcherFn func(string, string) (strToInf, error)
type strTostr map[string]string

func matchToInternalAndCreateEdges(externalItems strToInf, mFn matcherFn, oAuthNode *neo.Node, token Token, startName string) (int, error) {
	var matched int
	for key, _ := range externalItems {
		// go func() {
		internal, err := mFn(key, token.ServiceName)

		if err != nil {
			// logAndReturnErr("%v", err)
			continue
		}

		relData := strTostr{
			"relType":      fmt.Sprintf("%s_%s_%s", token.ServiceName, "followed", startName),
			"externalType": token.ServiceName,
			"startName":    "JAccount_oAuth",
			"name":         key,
		}

		if internal != nil {
			matched++
			internalNode := buildNeoNode(internal)
			err = createNodesAndRelationship(oAuthNode, internalNode, relData)
			if err != nil {
				logAndReturnErr("%v", err)
			}
		}
	}

	return matched, nil
}

func createNodesAndRelationship(startNode, endNode *neo.Node, data strTostr) error {
	edge := NewNeoEdge(RelationData{
		StartName: data["startName"],
		StartId:   startNode.Data["id"].(string),
		EndId:     endNode.Data["_id"].(string),
		EndName:   data["externalType"],
		Name:      data["relType"],
	})
	edge.StartNode = startNode
	edge.EndNode = endNode

	var err error

	if startNode.Id == "" {
		err = edge.CreateNodes()
	} else {
		_, err = edge.CreateEndNode()
	}

	if err != nil {
		return err
	}

	err = edge.CreateRelationship()
	if err != nil {
		return err
	}

	return nil
}

func matchTag(name, provider string) (strToInf, error) {
	tag, exists := mongo.GetTagByName(name, provider)
	if !exists {
		return nil, errors.New(fmt.Sprintf("No internal tag found for '%v'", name))
	}

	return tag, nil
}

func matchUser(name, provider string) (strToInf, error) {
	user, exists := mongo.GetUserByProviderId(name, provider)
	if !exists {
		return nil, errors.New(fmt.Sprintf("No internal user found for '%v'", name))
	}

	return user, nil
}

func buildNeoNode(content strToInf) *neo.Node {
	return &neo.Node{
		Data: content,
	}
}

func unmarshalToToken(data []byte) (Token, error) {
	var token Token
	err := json.Unmarshal(data, &token)
	if err != nil {
		return token, err
	}

	return token, nil
}
