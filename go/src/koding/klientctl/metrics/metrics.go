package metrics

import (
	"fmt"
	"strings"

	"koding/kites/kloud/utils/object"
	"koding/kites/metrics"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/auth"
	epcfg "koding/klientctl/endpoint/config"
	"koding/klientctl/endpoint/team"
)

// CommandPathTags generates metrics tags for a given command.
func CommandPathTags(args ...string) []string {
	if len(args) == 0 {
		return nil
	}

	tags := make([]string, 0, len(args)+1)
	tags = metrics.AppendTag(tags, "commandName", strings.Join(args, " "))
	tags = metrics.AppendTag(tags, "rootCommandName", args[0])

	// Add all subcommands names.
	for _, arg := range args[1:] {
		tags = metrics.AppendTag(tags, "subCommandName", arg)
	}

	return tags
}

var objBuilder = &object.Builder{
	Tag:           "json",
	Sep:           "_",
	Recursive:     true,
	FlatStringers: true,
}

// ApplicationInfoTags gathers application state, system data and current
// configuration info. All the data are then converted to metrics tags and
// returned to the caller.
//
// TODO: Add guest OS info.
func ApplicationInfoTags() (tags []string) {
	// Add current config.
	if configs, err := epcfg.Used(); err == nil {
		var ignoredFields = []string{
			"kiteKey",
			"kiteKeyFile",
			"environment",
			"tunnelID",
			"disableMetrics",
		}

		obj := objBuilder.Build(configs, ignoredFields...)
		for _, key := range obj.Keys() {
			val := obj[key]
			if val == nil || fmt.Sprintf("%v", val) == "" {
				continue
			}
			tags = metrics.AppendTag(tags, key, val)
		}
	}

	// Add current team info.
	if t := team.Used(); t != nil && t.Valid() == nil {
		tags = metrics.AppendTag(tags, "teamName", t.Name)
	}

	// Add user name.
	if info := auth.Used(); info != nil && info.Username != "" {
		tags = metrics.AppendTag(tags, "username", info.Username)
	}

	// Add current version.
	tags = metrics.AppendTag(tags, "version", config.VersionNum())

	return tags
}
