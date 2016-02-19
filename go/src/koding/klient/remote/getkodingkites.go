package remote

import (
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
)

// GetKodingKitesResult is a Koding specific GetKitesResult.
// For more information, see the KodingKite.GetKodingKites() docstring.
type GetKodingKitesResult struct {
	Kites []*KodingKiteWithToken `json:"kites"`
}

// KodingKiteWithToken is a Koding specific KiteWithToken returning
// additional, Koding specific information.
type KodingKiteWithToken struct {
	Kite  protocol.Kite `json:"kite"`
	URL   string        `json:"url"`
	KeyID string        `json:"keyId,omitempty"`
	Token string        `json:"token"`

	// The machine label of the machine hosting this kite, as seen from the Koding UI.
	MachineLabel string `json:"machineLabel"`

	// The team names of the machine hosting this kite, if any.
	Teams []string `json:"teams"`
}

// KodingClient contains a normal kite.Client with additional fields returned
// from the KodingKiteWithToken fields.
type KodingClient struct {
	*kite.Client

	// The machine label of the machine hosting this kite, as seen from the Koding UI.
	MachineLabel string

	// The team names of the machine hosting this kite, if any.
	Teams []string
}

// KodingKite is a struct that implements GetKodingKites ontop of a Kite.
//
// TODO: Move this to a more generic klient location, perhaps?
type KodingKite struct {
	*kite.Kite
}

// GetKodingKites is a custom implementation of GetKites which calls Kontrol's
// getKodingKites method and returns KodingClients based on the response.
//
// For the most part, GetKodingKites and all components of it mirror their
// official library siblings (GetKites, GetKitesResponse, etc), additional Koding
// specific data is all that separates this method from GetKites.
func (k *KodingKite) GetKodingKites(args *protocol.KontrolQuery) ([]*KodingClient, error) {
	response, err := k.TellKontrolWithTimeout(
		"getKodingKites",
		4*time.Second,
		protocol.GetKitesArgs{
			Query: args,
		},
	)
	if err != nil {
		return nil, err
	}

	result := new(GetKodingKitesResult)
	if err = response.Unmarshal(&result); err != nil {
		return nil, err
	}

	// If there are no kites available, return ErrNoKitesAvailable. This matches
	// GetKites behavior.
	if len(result.Kites) == 0 {
		return nil, kite.ErrNoKitesAvailable
	}

	clients := make([]*KodingClient, len(result.Kites))
	for i, kodingKite := range result.Kites {
		auth := &kite.Auth{
			Type: "token",
			Key:  kodingKite.Token,
		}

		clients[i] = &KodingClient{
			Client:       k.NewClient(kodingKite.URL),
			MachineLabel: kodingKite.MachineLabel,
			Teams:        kodingKite.Teams,
		}
		// These are part of the embedded client value, and cannot be assigned as fields
		// above.
		clients[i].Kite = kodingKite.Kite
		clients[i].Auth = auth
	}

	// Renew tokens
	for _, client := range clients {
		token, err := kite.NewTokenRenewer(client.Client, k.Kite)
		if err != nil {
			k.Log.Error("Error in token. Token will not be renewed when it expires: %s", err.Error())
			continue
		}
		token.RenewWhenExpires()
	}

	return clients, nil
}
