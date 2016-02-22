package kontrol

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
)

// GetKodingKitesResult mirrors the Kite GetKitesResult protocol.
type GetKodingKitesResult struct {
	Kites []*KodingKiteWithToken `json:"kites"`
}

// KodingKiteWithToken mirrors the Kite library KiteWithToken with a handful of
// additional fields pertaining to Koding itself. Such as Machine Label, and
// Teams information.
type KodingKiteWithToken struct {
	// These fields match protocol.KiteWithToken
	Kite  protocol.Kite `json:"kite"`
	URL   string        `json:"url"`
	KeyID string        `json:"keyId,omitempty"`
	Token string        `json:"token"`

	// The machine label, as seen from the Koding UI
	MachineLabel string `json:"machineLabel"`

	// The team names, if any.
	Teams []string `json:"teams"`
}

// HandleGetKodingKites implements GetKites with additional Koding specific response
// data.
func HandleGetKodingKites(handleGetKites kite.HandlerFunc) kite.HandlerFunc {
	return func(req *kite.Request) (interface{}, error) {
		// getKitesResponse is an interface, not the actual GetKitesResult value.
		getKitesResponse, err := handleGetKites(req)
		if err != nil {
			req.LocalKite.Log.Error("GetKitesHandler returned an error: %s", err)
			return nil, err
		}

		getKitesResult, ok := getKitesResponse.(*protocol.GetKitesResult)
		if !ok {
			return nil, errors.New("GetKites returned unexpected protocol result")
		}

		// Get all machines for the given user.
		machines, err := modelhelper.GetMachineFieldsByUsername(req.Username, []string{
			"queryString", "label", "groups",
		})
		if err != nil {
			return nil, err
		}

		// A map of GroupId a slice of all KodingKiteWithToken that contain that group.
		kitesByGroupID := map[string][]*KodingKiteWithToken{}

		// Create our slice of unique group ids that we will use to query all the
		// groups that we need.
		uniqueGroups := []string{}

		// Because we are using the Kite's queryString as a means to identify the machine,
		// we are sorting the machines by queryString so that we can easily look them up.
		machinesByQuery := map[string]*models.Machine{}
		for _, m := range machines {
			if m.QueryString != "" {
				machinesByQuery[m.QueryString] = m
			}
		}

		// Create our KodingKitesResult which will be returned after being populated.
		result := &GetKodingKitesResult{
			Kites: make([]*KodingKiteWithToken, len(getKitesResult.Kites)),
		}

		// Populate the koding kites
		for i, kiteWithToken := range getKitesResult.Kites {
			kite := &KodingKiteWithToken{
				Kite:  kiteWithToken.Kite,
				URL:   kiteWithToken.URL,
				KeyID: kiteWithToken.KeyID,
				Token: kiteWithToken.Token,
			}

			// Populate the result kite regardless of if we can get Label/Team/etc
			// information about it. This is needed because many kites might not have
			// jMachine documents.
			result.Kites[i] = kite

			// JMachine.QueryString is composed of only the Kite.ID, so to form a
			// queryString that we can match to the stored queryString in Mongo, String
			// the Kite protocol with just the ID. Example:
			//
			//     ///////b38da9f0-9acf-4c41-bdfe-6ef3c9b8de56
			queryString := protocol.Kite{ID: kite.Kite.ID}.String()

			// With a valid queryString, get the koding specific information such as Label
			// or Team names and apply it to each KodingKiteWithToken
			if machine, ok := machinesByQuery[queryString]; ok {
				kite.MachineLabel = machine.Label

				for _, g := range machine.Groups {
					id := g.Id.Hex()

					// Get all of the kites (not including this one) which have
					// a reference to this kite, so we can append this kite to them.
					kites, ok := kitesByGroupID[id]

					// If the id is *not* in the kites map yet, it is unique.
					// Store the group id in the unique slice, so we can query for the groups.
					if !ok {
						uniqueGroups = append(uniqueGroups, id)
					}

					// kites could be a nil map, but that's okay as append will resolve
					// that issue.
					//
					// Note that if a Machine somehow has two entries for the same group,
					// this will be appended twice, but should not cause a problem.
					kitesByGroupID[id] = append(kites, kite)
				}
			}
		}

		// Now that we have all of our group ids that we want to query, get our Groups
		// from that.
		groups, err := modelhelper.GetGroupFieldsByIds(uniqueGroups, []string{"title"})
		if err != nil {
			return nil, err
		}

		// Now that we have the groups, go through our KodingKiteWithToken slice and
		// assign the team names.
		for _, group := range groups {
			id := group.Id.Hex()

			kites, ok := kitesByGroupID[id]

			// This shouldn't happen, so log a warning to aid in identifying a problem,
			// and continue.
			if !ok {
				req.LocalKite.Log.Warning(
					"Queried GroupId not present in KodingKitesWithToken by GroupId map. This is unexpected, and may represent a problem. [id:%s, ids:%s]",
					id, uniqueGroups,
				)
				continue
			}

			// Append this groups team title to the KodingKiteWithToken Teams slice.
			for _, kite := range kites {
				kite.Teams = append(kite.Teams, group.Title)
			}
		}

		return result, nil
	}
}
