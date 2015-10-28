package notification

import (
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"socialapi/request"

	"github.com/hashicorp/go-multierror"
	"github.com/koding/bongo"
	"github.com/koding/logging"
)

type normalizer struct {
	err             error
	usernames       []string
	log             logging.Logger
	cm              *socialapimodels.ChannelMessage
	failedUsernames []string
}

func NewNormalizer(cm *socialapimodels.ChannelMessage, usernames []string, log logging.Logger) *normalizer {
	return &normalizer{
		usernames: usernames,
		cm:        cm,
		log:       log,
	}
}

func (n *normalizer) UnifyUsernames() *normalizer {
	if n.err != nil {
		return n
	}

	n.usernames = socialapimodels.StringSliceUnique(n.usernames)
	n.log.Debug("usernames after UnifyUsernames %+v", n.usernames)
	return n
}

func (n *normalizer) UnifyAliases() *normalizer {
	if n.err != nil {
		return n
	}

	usernames := n.usernames

	cleanUsernames := make(map[string]struct{})

	for _, username := range usernames {

		for mention, aliases := range globalAliases {
			if socialapimodels.IsIn(username, aliases...) {

				if mention == "all" {
					n.usernames = []string{"all"}
					return n
				}

				cleanUsernames[mention] = struct{}{}
			} else {

				cleanUsernames[username] = struct{}{}
			}
		}
	}

	for cleaned := range cleanUsernames {
		for mention, aliases := range roleAliases {
			if socialapimodels.IsIn(cleaned, aliases...) {
				delete(cleanUsernames, cleaned)
				cleanUsernames[mention] = struct{}{}
			} else {
				cleanUsernames[cleaned] = struct{}{}
			}
		}
	}

	res := make([]string, 0)
	for username := range cleanUsernames {
		res = append(res, username)
	}

	n.usernames = res
	n.log.Debug("usernames after UnifyAliases %+v", n.usernames)

	return n
}

func (n *normalizer) ConvertAliases() *normalizer {
	if n.err != nil {
		return n
	}

	usernames := n.usernames

	normalizedUsernames := make([]string, 0)

	for alias, normalizer := range aliasNormalizers {

		for i, username := range usernames {
			if username == alias {

				usernames = append(usernames[:i], usernames[i+1:]...)

				channelUsers, err := normalizer(n.cm)
				if err != nil {
					n.err = err
					return n
				}

				normalizedUsernames = append(normalizedUsernames, channelUsers...)
			}
		}
	n.log.Debug("usernames after ConvertAliases %+v", n.usernames)
	n.log.Debug("usernames after RemoveOwner %+v", n.usernames)
	}

	channel, err := socialapimodels.Cache.Channel.ById(n.cm.InitialChannelId)
	if err != nil {
		n.err = err
		return n
	}

	for _, username := range usernames {
		acc, err := socialapimodels.Cache.Account.ByNick(username)
		if err != nil && err != bongo.RecordNotFound {
			n.err = err
			return n
		}

		if err == bongo.RecordNotFound {
			n.failedUsernames = append(n.failedUsernames, username)
			n.log.New("username", username).Debug(err.Error())
			continue
		}

		canOpen, err := channel.CanOpen(acc.Id)
		if canOpen {
			normalizedUsernames = append(normalizedUsernames, username)
		} else {
			n.failedUsernames = append(n.failedUsernames, username)
			n.log.New("username", username, "channelId", channel.Id).Debug("ignoring notification due to not sufficient access level")
		}
	}

	n.usernames = normalizedUsernames
	return n
}

func (n *normalizer) RemoveOwner() *normalizer {
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

			n.usernames = append(n.usernames[:i], n.usernames[i+1:]...)
			break
		}
	}
	n.log.Debug("usernames after FilterParticipants %+v", n.usernames)

	return n
}

func (n *normalizer) Do() ([]string, error) {
	n.UnifyUsernames().
		UnifyAliases().
		ConvertAliases().
		RemoveOwner()

	if n.err != nil {
		return nil, n.err
	}

	return n.usernames, nil
}

// fetchAllMembersOfAGroup gets the group name from the channel message and
// returns all the user's nicknames of that group
func fetchAllMembersOfAGroup(cm *socialapimodels.ChannelMessage) ([]string, error) {
	groupChannel, err := cm.FetchParentChannel() // it has internal caching
	if err != nil {
		return nil, err
	}

	return fetchChannelParticipants(groupChannel)
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

var globalAliases = map[string][]string{
	"all":     []string{"team", "all", "group"},
	"channel": []string{"channel"},
}

var roleAliases = map[string][]string{
	"admins": []string{"admins"},
}

type aliasNormalizerFunc func(*socialapimodels.ChannelMessage) ([]string, error)

var aliasNormalizers = map[string]aliasNormalizerFunc{
	"all":     fetchAllMembersOfAGroup,
	"channel": fetchAllMembersOfChannel,
	"admins":  fetchAllAdminsOfChannel,
}

// clean up removes duplicate mentions from usernames. eg: team and all
// essentially same mentions
func cleanup(usernames []string) []string {
	// do first clean up with removing duplicates
	usernames = socialapimodels.StringSliceUnique(usernames)

	// reduce aliases to their parent representation eg:@everyone->@all
	cleanUsernames := make(map[string]struct{})

	for _, username := range usernames {
		// check if the username is in global mention list first
		for mention, aliases := range globalAliases {
			if socialapimodels.IsIn(username, aliases...) {
				// Special Case - if we have "all" mention (or any other all
				// `alias`), no need for further process
				if mention == "all" {
					return []string{"all"}
				}

				// if the username is one the keywords, just use the general keyword
				cleanUsernames[mention] = struct{}{}
			} else {
				// if username is not one of the keywords, use it directly
				cleanUsernames[username] = struct{}{}
			}
		}
	}

	// then check if the username is in
	for cleaned := range cleanUsernames {
		for mention, aliases := range roleAliases {
			if socialapimodels.IsIn(cleaned, aliases...) {
				delete(cleanUsernames, cleaned)      // delete the alias from clean
				cleanUsernames[mention] = struct{}{} // set mention to clean
			} else {
				cleanUsernames[cleaned] = struct{}{}
			}
		}
	}

	// convert it to string slice
	res := make([]string, 0)
	for username := range cleanUsernames {
		res = append(res, username)
	}

	return res
}
