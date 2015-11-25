package kontrol

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net"
	"net/url"

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
			"ipAddress", "label", "groups",
		})
		if err != nil {
			return nil, err
		}

		// A map of GroupId a slice of all KodingKiteWithToken that contain that group.
		kkwtsByGroupID := map[string][]*KodingKiteWithToken{}

		// Create our slice of unique group ids that we will use to query all the
		// groups that we need.
		uniqueGroups := []string{}

		// Because we are using the Kite's IP as a means to identify the machine,
		// we are sorting the machines by IP so that we can easily look them up.
		machinesByIP := map[string]*models.Machine{}
		for _, m := range machines {
			if m.IpAddress != "" {
				machinesByIP[m.IpAddress] = m
			}
		}

		// Create our KodingKitesResult which will be returned after being populated.
		kodingKitesResult := &GetKodingKitesResult{
			Kites: make([]*KodingKiteWithToken, len(getKitesResult.Kites)),
		}

		// Populate the koding kites
		for i, kwt := range getKitesResult.Kites {
			kkwt := &KodingKiteWithToken{
				Kite:  kwt.Kite,
				URL:   kwt.URL,
				KeyID: kwt.KeyID,
				Token: kwt.Token,
			}
			kodingKitesResult.Kites[i] = kkwt

			host, err := hostFromURL(kwt.URL)
			if err != nil {
				req.LocalKite.Log.Warning(
					"Kite with badly formed URL, unable to extract host. Koding data will not be provided for this Kite. [username:%s, kiteId:%s, host:%s]",
					kwt.Kite.Username,
					kwt.Kite.ID,
					kwt.URL,
				)
				continue
			}

			// With a valid host, get the koding specific information such as Label
			// or Team names and apply it to each KodingKiteWithToken
			if machine, ok := machinesByIP[host]; ok {
				kkwt.MachineLabel = machine.Label

				for _, g := range machine.Groups {
					id := g.Id.Hex()

					// Get all of the kites (not including this one) which have
					// a reference to this kite, so we can append this kite to them.
					kkwts, ok := kkwtsByGroupID[id]

					// If the id is *not* in the kkwts map yet, it is unique.
					// Store the group id in the unique slice, so we can query for the groups.
					if !ok {
						uniqueGroups = append(uniqueGroups, id)
					}

					// kkwts could be a nil map, but that's okay as append will resolve
					// that issue.
					//
					// Note that if a Machine somehow has two entries for the same group,
					// this will be appended twice, but should not cause a problem.
					kkwtsByGroupID[id] = append(kkwts, kkwt)
				}
			}
		}

		// Now that we have all of our group ids that we want to query, get our Groups
		// from that.
		groups, err := modelhelper.GetGroupFieldsByIds(uniqueGroups, []string{"title"})
		if err != nil {
			req.LocalKite.Log.Error(
				"Error returned when querying Team Names. [groupIds:%s, err:%s",
				uniqueGroups, err.Error(),
			)
		}

		// Now that we have the groups, go through our KodingKiteWithToken slice and
		// assign the team names.
		for _, group := range groups {
			id := group.Id.Hex()

			kkwts, ok := kkwtsByGroupID[id]

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
			for _, kkwt := range kkwts {
				kkwt.Teams = append(kkwt.Teams, group.Title)
			}
		}

		return kodingKitesResult, nil
	}
}

// hostFromURL parses the given string, extracting the host (ip/domain) from the
// given string. Ignoring other data such as Port or Url Parameters.
func hostFromURL(s string) (string, error) {
	u, err := url.Parse(s)
	if err != nil {
		return "", err
	}

	host, _, err := net.SplitHostPort(u.Host)
	if err != nil {
		return "", err
	}

	return host, nil
}
