package notification

import (
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"socialapi/request"

	"github.com/hashicorp/go-multierror"
	"github.com/koding/bongo"
	"github.com/koding/logging"
)

const (
	allAlias    = "all"
	adminsAlias = "admins"
)

var (
	globalAliases = map[string]bool{
		"all":     true,
		"channel": true,
		"team":    true,
		"group":   true,
	}
	roleAliases = map[string]bool{
		"admins": true,
	}

	aliasNormalizers = map[string]aliasNormalizerFunc{
		allAlias:    fetchAllMembersOfChannel,
		adminsAlias: fetchAllAdminsOfChannel,
	}
)

type mentionExtractor struct {
	err             error
	usernames       []string
	log             logging.Logger
	cm              *socialapimodels.ChannelMessage
	failedUsernames []string
}

type aliasNormalizerFunc func(*socialapimodels.ChannelMessage) ([]string, error)

// NewMentionExtractor extracts mentioned usernames from a channel message
func NewMentionExtractor(cm *socialapimodels.ChannelMessage, log logging.Logger) *mentionExtractor {
	usernames := cm.GetMentionedUsernames()
	log.Debug("usernames before extracts %+v", usernames)

	return &mentionExtractor{
		usernames: usernames,
		cm:        cm,
		log:       log,
	}
}

// UnifyUsernames removes duplicate mentions from the username
func (n *mentionExtractor) UnifyUsernames() *mentionExtractor {
	if n.err != nil {
		return n
	}

	n.usernames = socialapimodels.StringSliceUnique(n.usernames)
	n.log.Debug("usernames after UnifyUsernames %+v", n.usernames)
	return n
}

// UnifyAliases changes alias usernames to their respective usernames
func (n *mentionExtractor) UnifyAliases() *mentionExtractor {
	n.err = n.afterChecks(func() error {
		n.usernames = unifyAliases(n.usernames)
		n.log.Debug("usernames after UnifyAliases %+v", n.usernames)
		return nil
	})

	return n
}

// ConvertAliases replaces the aliases with their actual usernames, removes the
// alias from username list
func (n *mentionExtractor) ConvertAliases() *mentionExtractor {
	n.err = n.afterChecks(func() error {
		normalizedUsernames := make([]string, 0)
		for _, username := range n.usernames {
			found := false
			for alias, normalizer := range aliasNormalizers {
				if username == alias {
					found = true

					channelUsers, err := normalizer(n.cm)
					if err != nil {
						return err
					}

					normalizedUsernames = append(normalizedUsernames, channelUsers...)
				}
			}

			// if this is not a alias, put it back to normalized users
			if !found {
				normalizedUsernames = append(normalizedUsernames, username)
			}
		}

		n.usernames = normalizedUsernames
		n.log.Debug("usernames after ConvertAliases %+v", n.usernames)
		return nil
	})

	return n
}

// RemoveOwner removes the owner from mention list
func (n *mentionExtractor) RemoveOwner() *mentionExtractor {
	if n.err != nil {
		return n
	}

	owner, err := socialapimodels.Cache.Account.ById(n.cm.AccountId)
	if err != nil {
		n.err = err
		return n
	}

	for i, username := range n.usernames {
		if username == owner.Nick {
			// delete username from the list
			n.usernames = append(n.usernames[:i], n.usernames[i+1:]...)
			break
		}
	}

	n.log.Debug("usernames after RemoveOwner %+v", n.usernames)
	return n
}

// RemoveNonParticipants removes non participants people from username list
func (n *mentionExtractor) RemoveNonParticipants() *mentionExtractor {
	n.err = n.afterChecks(func() error {
		channel, err := socialapimodels.Cache.Channel.ById(n.cm.InitialChannelId)
		if err != nil {
			return err
		}

		participants := make([]string, 0)

		for _, username := range n.usernames {
			acc, err := socialapimodels.Cache.Account.ByNick(username)
			if err != nil && err != bongo.RecordNotFound {
				return err
			}

			if err == bongo.RecordNotFound {
				n.failedUsernames = append(n.failedUsernames, username)
				n.log.New("username", username).Debug(err.Error())
				continue
			}

			canOpen, err := channel.IsParticipant(acc.Id)
			if canOpen {
				participants = append(participants, username)
			} else {
				n.failedUsernames = append(n.failedUsernames, username)
				n.log.New("username", username, "channelId", channel.Id).Debug("ignoring notification due to not sufficient access level")
			}
		}

		n.usernames = participants
		n.log.Debug("usernames after RemoveNonParticipants %+v", n.usernames)
		return nil
	})

	return n
}

// Do operates the required filterings on username list
func (n *mentionExtractor) Do() ([]string, error) {
	n.UnifyUsernames().
		UnifyAliases().
		ConvertAliases().
		RemoveOwner().
		RemoveNonParticipants()

	if n.err != nil {
		return nil, n.err
	}

	return n.usernames, nil
}

// afterChecks does the required validation and check, if successful, runs the given function
func (n *mentionExtractor) afterChecks(f func() error) error {
	if n.err != nil {
		return n.err
	}

	channel, err := socialapimodels.Cache.Channel.ById(n.cm.InitialChannelId)
	if err != nil {
		return err
	}

	// do not operate for koding group
	if channel.GroupName == socialapimodels.Channel_KODING_NAME {
		return nil
	}

	return f()
}

// fetchAllMembersOfChannel gets the channel id from ChannelMessage and fetches
// all the participants of that channel, returns only the usernames
func fetchAllMembersOfChannel(cm *socialapimodels.ChannelMessage) ([]string, error) {
	c, err := socialapimodels.Cache.Channel.ById(cm.InitialChannelId)
	if err != nil {
		return nil, err
	}

	return fetchChannelParticipants(c)
}

// fetchAllAdminsOfChannel fetches all the admins of a group and return their
// usernames
func fetchAllAdminsOfChannel(cm *socialapimodels.ChannelMessage) ([]string, error) {
	c, err := socialapimodels.Cache.Channel.ById(cm.InitialChannelId)
	if err != nil {
		return nil, err
	}

	admins, err := modelhelper.FetchAdminAccounts(c.GroupName)
	if err != nil {
		return nil, err
	}

	adminNicknames := make([]string, len(admins))
	for i, admin := range admins {
		adminNicknames[i] = admin.Profile.Nickname
	}

	return adminNicknames, nil
}

// fetchChannelParticipants fetches all the participants of the given channel,
// returns only the usernames of the account
func fetchChannelParticipants(c *socialapimodels.Channel) ([]string, error) {
	q := request.NewQuery()
	ids, err := c.FetchParticipantIds(q)
	if err != nil {
		return nil, err
	}

	var errs *multierror.Error

	usernames := make([]string, 0)
	for _, id := range ids {
		acc, err := socialapimodels.Cache.Account.ById(id)
		if err != nil {
			errs = multierror.Append(errs, err)
		}

		usernames = append(usernames, acc.Nick)
	}

	if errs.ErrorOrNil() != nil {
		return nil, errs
	}

	return usernames, nil
}

// unifyAliases removes duplicate mentions from usernames. eg: team and all
// essentially same mentions
func unifyAliases(usernames []string) []string {
	cleaned := make(map[string]struct{})

	for _, user := range usernames {
		if globalAliases[user] {
			return []string{allAlias} // shortcut
		}

		// if it's one of the role aliases, set it to "admins" directly. This
		// will also clean up duplicates and there will be only one role.
		if roleAliases[user] {
			cleaned[adminsAlias] = struct{}{}
		} else {
			cleaned[user] = struct{}{}
		}
	}

	// convert it to string slice
	res := make([]string, 0)
	for username := range cleaned {
		res = append(res, username)
	}
	return res
}
