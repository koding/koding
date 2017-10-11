package cli

import (
	"fmt"
	"strings"
	"time"

	"koding/kites/kloud/utils/object"
	"koding/kites/metrics"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/auth"
	epcfg "koding/klientctl/endpoint/config"
	"koding/klientctl/endpoint/team"

	"github.com/spf13/cobra"
)

// WithMetrics allows to gather metrics for a given command. Command path can
// be replaced with provided aliasPath.
func WithMetrics(cli *CLI, rootCmd *cobra.Command) {
	cli.registerMiddleware("with_metrics", rootCmd)
	tail := rootCmd.RunE
	if tail == nil {
		panic("cannot insert middleware into empty function")
	}

	// If metrics are disabled, do not add any middleware.
	if cli.Metrics() == nil || cli.Metrics().Datadog == nil {
		return
	}

	// Use aliased command path when provided.
	cmdPath := strings.Split(rootCmd.CommandPath(), " ")
	if aliasPath := rootCmd.Annotations[AliasAnnotation]; len(aliasPath) != 0 {
		cmdPath = strings.Split(aliasPath, " ")
	}

	// Register command to metrics dashboard.
	metrics.RegisterCLICommand(cli.Metrics(), cmdPath...)

	rootCmd.RunE = func(cmd *cobra.Command, args []string) error {
		// rootCmd and invoked one should be the same. These values may
		// differ for persistent command handlers.
		if ccp, rcp := cmd.CommandPath(), rootCmd.CommandPath(); ccp != rcp {
			panic(fmt.Sprintf("metric command mismatch: '%s' != '%s'", ccp, rcp))
		}

		// Measure command execution time.
		start := time.Now()
		err := tail(cmd, args)
		passed := time.Since(start)

		// Generate command tags.
		tags := append(CommandPathTags(cmdPath...), ApplicationInfoTags()...)
		tags = metrics.AppendTag(tags, "success", err == nil)
		tags = metrics.AppendTag(tags, "request_type", "cli")

		// Shorten command error if it is too long.
		const maxErrMsgLength = 20
		if err != nil {
			msg := err.Error()
			if len(msg) > maxErrMsgLength {
				msg = msg[:maxErrMsgLength]
			}
			tags = metrics.AppendTag(tags, "err_message", msg)
		}

		// Send metrics to DataDog client.
		var metricName = strings.Join(cmdPath, "_")
		cli.Metrics().Datadog.Count(metricName+"_call_count", 1, tags, 1)
		cli.Metrics().Datadog.Timing(metricName+"_timing", passed, tags, 1)

		return err
	}
}

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
