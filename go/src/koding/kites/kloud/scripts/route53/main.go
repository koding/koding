package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"time"

	"golang.org/x/net/context"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/logging"

	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/utils/res"
)

var (
	accessKey  = os.Getenv("ROUTE53_ACCESS_KEY")
	secretKey  = os.Getenv("ROUTE53_SECRET_KEY")
	hostedZone = os.Getenv("ROUTE53_HOSTED_ZONE")

	client *dnsclient.Route53
)

var Resources = res.New("route53")

func init() {
	Resources.Register(recordsResource)
}

func die(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}

func main() {
	if accessKey == "" {
		die("AWS_ACCESS_KEY is not set")
	}
	if secretKey == "" {
		die("AWS_SECRET_KEY is not set")
	}
	if hostedZone == "" {
		die("ROUTE53_HOSTED_ZONE is not set")
	}

	opts := &dnsclient.Options{
		Creds:       credentials.NewStaticCredentials(accessKey, secretKey, ""),
		HostedZone:  hostedZone,
		Log:         logging.NewCustom("dnsclient", os.Getenv("ROUTE53_DEBUG") == "1"),
		SyncTimeout: 5 * time.Minute,
	}

	if d, err := time.ParseDuration(os.Getenv("ROUTE53_TIMEOUT")); err == nil {
		opts.SyncTimeout = d
	}

	opts.Log.Debug("Options: %# v", opts)

	var err error
	client, err = dnsclient.NewRoute53Client(opts)
	if err != nil {
		die(err)
	}

	if err := Resources.Main(os.Args[1:]); err != nil {
		die(err)
	}
}

var recordsResource = &res.Resource{
	Name:        "records",
	Description: "Manage DNS records.",
	Commands: map[string]res.Command{
		"list": new(recordsList),
		"add":  new(recordsAdd),
		"rm":   new(recordsRm),
	},
}

// route53 records list

type recordsList struct {
	filter dnsclient.Record
	system bool
}

func (cmd *recordsList) list() (dnsclient.Records, error) {
	records, err := client.GetAll(cmd.filter.Name)
	if err != nil {
		return nil, err
	}
	r := dnsclient.Records(records).Filter(&cmd.filter)
	if !cmd.system {
		r = r.User()
	}
	if len(r) == 0 {
		return nil, errors.New("no records found")
	}
	return r, nil
}

func (*recordsList) Name() string {
	return "list"
}

func (cmd *recordsList) Valid() error {
	return nil
}

func (cmd *recordsList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.filter.Name, "name", "", "Filter records by name suffix.")
	f.StringVar(&cmd.filter.Type, "type", "", "Filter records by type.")
	f.StringVar(&cmd.filter.IP, "value", "", "Filter records by value.")
	f.BoolVar(&cmd.system, "system", false, "Include NS and SOA records.")
}

func (cmd *recordsList) Run(context.Context) error {
	records, err := cmd.list()
	if err != nil {
		return err
	}

	p, err := json.MarshalIndent(records, "", "\t")
	if err != nil {
		return err
	}

	fmt.Println(string(p))

	return nil
}

// route53 records add

type recordsAdd struct {
	record dnsclient.Record
}

func (*recordsAdd) Name() string {
	return "add"
}

func (cmd *recordsAdd) Valid() error {
	if cmd.record.Name == "" {
		return errors.New("empty value for -name flag")
	}
	if cmd.record.IP == "" {
		return errors.New("empty value for -value flag")
	}
	if cmd.record.Type == "" {
		cmd.record.Type = dnsclient.ParseRecord("", cmd.record.IP).Type
	}
	if cmd.record.TTL == 0 {
		cmd.record.TTL = 30
	}
	return nil
}

func (cmd *recordsAdd) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.record.Name, "name", "", "Record's name.")
	f.StringVar(&cmd.record.IP, "value", "", "Record's value.")
	f.StringVar(&cmd.record.Type, "type", "", "Record's type.")
	f.IntVar(&cmd.record.TTL, "ttl", 0, "Record's TTL.")
}

func (cmd *recordsAdd) Run(context.Context) error {
	fmt.Println("upserting record and waiting for the operation to complete...")
	err := client.UpsertRecord(&cmd.record)
	if err != nil {
		return err
	}

	rec, err := client.Get(cmd.record.Name)
	if err != nil {
		return err
	}

	fmt.Printf("added record: %# v\n", rec)
	return nil
}

// route53 records rm

type recordsRm struct {
	list recordsList
	dry  bool
}

func (*recordsRm) Name() string {
	return "rm"
}

func (cmd *recordsRm) Valid() error {
	return cmd.list.Valid()
}

func (cmd *recordsRm) RegisterFlags(f *flag.FlagSet) {
	cmd.list.RegisterFlags(f)
	f.BoolVar(&cmd.dry, "dry-run", false, "Prints planned actions only.")
}

func (cmd *recordsRm) Run(context.Context) error {
	records, err := cmd.list.list()
	if err != nil {
		return err
	}
	if len(records) == 0 {
		return errors.New("no records found")
	}

	for _, record := range records {
		if cmd.dry {
			fmt.Printf("[dry] going to remove: %v\n", record)
		} else {
			err := client.DeleteRecord(record)
			if err != nil {
				fmt.Printf("failed to remove %v: %s\n", record, err)
			} else {
				fmt.Printf("removed %v\n", record)
			}
		}
	}

	return nil
}
