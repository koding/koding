package main

import (
	"fmt"
	. "launchpad.net/gocheck"
	"log"
	"net/http"
)

func init() {
	log.SetPrefix("Externals test: ")
}

func (s *MySuite) TestImportingFailsIfNoClients(c *C) {
	nonExistentClientName := "x"
	nonExistentToken := Token{ServiceName: nonExistentClientName}
	err := ImportExternalToGraph(nonExistentToken)

	c.Check(err, ErrorMatches, fmt.Sprintf("Error: No client found for: '%v'", nonExistentClientName))
}

func (s *MySuite) TestImportingFailsIfNoUserInDocumentDb(c *C) {
	mongo = &EmptyUserFakeMongo{}
	defer resetMongoToDefaultTestMongo()

	token := githubTokenDataFixture(c)
	err := ImportExternalToGraph(token)

	c.Check(err, ErrorMatches, "Error: User: '4f14f9d8519ab4c62e000033' does not exist in document db")
}

func (s *MySuite) TestImportingFailsIfNoUserInExternal(c *C) {
	setupFakeFailGithubClient()
	defer resetMongoToDefaultTestMongo()

	data := githubTokenDataFixture(c)
	err := ImportExternalToGraph(data)

	c.Check(err, ErrorMatches, "Error: Failed to get user info: '4f14f9d8519ab4c62e000033' from 'github' with: does not exist")
}

func (s *MySuite) TestSavingDifferentUserRepresentations(c *C) {
	setupFakeGithubClient()
	defer resetMongoToDefaultTestMongo()

	mongo = &FakeMongo{}
	defer resetMongoToDefaultTestMongo()

	setupNeoMock()
	defer tearDownNeoMock()

	neoMux.HandleFunc("/db/data/batch", func(w http.ResponseWriter, r *http.Request) {
		req := parseBody(r)

		nodeStartUrl := fmt.Sprintf("%s/db/data/node/%s", neoTestServer.URL, "1")
		nodeEndUrl := fmt.Sprintf("%s/db/data/node/%s", neoTestServer.URL, "2")
		rltnshpUrl := fmt.Sprintf("%s/db/data/relationship/%s", neoTestServer.URL, "1")

		nodeData :=
			`[{"id":0, "body":{"self":"%v",
        "data":{"_id":"4f14f9d8519ab4c62e000033","id":"4f14f9d8519ab4c62e000033"}}},
      {"id":1, "body":{"self":"%v",
        "data":{"_id":"164864", "id":"github_164864"}}}]`

		rltnshpData := `[{"id":0, "body":[{"self":"%s", "start":"%s", "end":"%s"}]}]`

		if len(req) == 2 && req[0]["to"] == "/index/node/koding?unique" {
			fmt.Fprintf(w, nodeData, nodeStartUrl, nodeEndUrl)
		} else if req[0]["to"] == "/node/1/relationships" {
			fmt.Fprintf(w, rltnshpData, rltnshpUrl, nodeStartUrl, nodeEndUrl)
		}
	})

	data := githubTokenDataFixture(c)
	err := ImportExternalToGraph(data)

	c.Assert(err, IsNil)
}
