// sneaker is a command-line tool for securely managing secrets using Amazon Web
// Service's Key Management Service and S3.
package main

import (
	"fmt"
	"io"
	"log"
	"net/url"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/aws/aws-sdk-go/service/kms"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/codahale/sneaker"
	"github.com/docopt/docopt-go"
)

const usage = `sneaker manages secrets.

Usage:
  sneaker ls [<pattern>]
  sneaker upload <file> <path>
  sneaker download <path> <file>
  sneaker rm <path>
  sneaker pack <pattern> <file> [--key=<id>] [--context=<k1=v2,k2=v2>]
  sneaker unpack <file> <path> [--context=<k1=v2,k2=v2>]
  sneaker rotate [<pattern>]
  sneaker version

Options:
  -h --help  Show this help information.

Environment Variables:
  SNEAKER_MASTER_KEY      The KMS key to use when encrypting secrets.
  SNEAKER_MASTER_CONTEXT  The KMS encryption context to use for stored secrets.
  SNEAKER_S3_PATH         Where secrets will be stored (e.g. s3://bucket/path).
`

func main() {
	args, err := docopt.Parse(usage, nil, true, version, false)
	if err != nil {
		log.Fatal(err)
	}

	if args["version"] == true {
		fmt.Printf(
			"version: %s\ngoversion: %s\nbuildtime: %s\n",
			version, goVersion, buildTime,
		)
		return
	}

	manager := loadManager()

	if args["ls"] == true {
		// sneaker ls
		// sneaker ls *.txt,*.key

		var pattern string
		if s, ok := args["<pattern>"].(string); ok {
			pattern = s
		}

		files, err := manager.List(pattern)
		if err != nil {
			log.Fatal(err)
		}

		table := new(tabwriter.Writer)
		table.Init(os.Stdout, 2, 0, 2, ' ', 0)
		fmt.Fprintln(table, "key\tmodified\tsize\tetag")
		for _, f := range files {
			fmt.Fprintf(table, "%s\t%s\t%v\t%s\n",
				f.Path,
				f.LastModified.Format(conciseTime),
				f.Size,
				f.ETag,
			)
		}
		_ = table.Flush()

	} else if args["upload"] == true {
		file := args["<file>"].(string)
		path := args["<path>"].(string)

		log.Printf("uploading %s", file)

		f := openPath(file, os.Open, os.Stdin)
		defer f.Close()

		if err := manager.Upload(path, f); err != nil {
			log.Fatal(err)
		}
	} else if args["download"] == true {
		file := args["<file>"].(string)
		path := args["<path>"].(string)

		log.Printf("downloading %s", file)

		out := openPath(file, os.Create, os.Stdout)
		defer out.Close()

		actual, err := manager.Download([]string{path});
		if err != nil {
			log.Fatal(err)
		}
		out.Write(actual[path])
	} else if args["rm"] == true {
		path := args["<path>"].(string)

		log.Printf("deleting %s", path)

		if err := manager.Rm(path); err != nil {
			log.Fatal(err)
		}
	} else if args["pack"] == true {
		pattern := args["<pattern>"].(string)
		file := args["<file>"].(string)

		var context map[string]string
		if s, ok := args["--context"].(string); ok {
			c, err := parseContext(s)
			if err != nil {
				log.Fatal(err)
			}
			context = c
		}

		var key string
		if s, ok := args["--key"].(string); ok {
			key = s
		}

		// list files
		files, err := manager.List(pattern)
		if err != nil {
			log.Fatal(err)
		}

		paths := make([]string, 0, len(files))
		for _, f := range files {
			paths = append(paths, f.Path)
		}

		log.Printf("packing %v", paths)

		// download secrets
		secrets, err := manager.Download(paths)
		if err != nil {
			log.Fatal(err)
		}

		// write to file or STDOUT
		out := openPath(file, os.Create, os.Stdout)
		defer out.Close()

		// pack secrets
		if err := manager.Pack(secrets, context, key, out); err != nil {
			log.Fatal(err)
		}
	} else if args["unpack"] == true {
		file := args["<file>"].(string)
		path := args["<path>"].(string)
		var context map[string]string
		if s, ok := args["--context"].(string); ok {
			c, err := parseContext(s)
			if err != nil {
				log.Fatal(err)
			}
			context = c
		}

		// read from file or STDIN
		in := openPath(file, os.Open, os.Stdin)
		defer in.Close()

		// write to file or STDOUT
		out := openPath(path, os.Create, os.Stdout)
		defer out.Close()

		r, err := manager.Unpack(context, in)
		if err != nil {
			log.Fatal(err)
		}

		if _, err := io.Copy(out, r); err != nil {
			log.Fatal(err)
		}
	} else if args["rotate"] == true {
		var pattern string
		if s, ok := args["<pattern>"].(string); ok {
			pattern = s
		}

		if err := manager.Rotate(pattern, func(s string) {
			log.Printf("rotating %s", s)
		}); err != nil {
			log.Fatal(err)
		}
	} else {
		fmt.Fprintf(os.Stderr, "Unknown command: %v\n", os.Args)
	}
}

func loadManager() *sneaker.Manager {
	u, err := url.Parse(os.Getenv("SNEAKER_S3_PATH"))
	if err != nil {
		log.Fatalf("bad SNEAKER_S3_PATH: %s", err)
	}
	if u.Path != "" && u.Path[0] == '/' {
		u.Path = u.Path[1:]
	}

	ctxt, err := parseContext(os.Getenv("SNEAKER_MASTER_CONTEXT"))
	if err != nil {
		log.Fatalf("bad SNEAKER_MASTER_CONTEXT: %s", err)
	}

	return &sneaker.Manager{
		Objects: s3.New(nil),
		Envelope: sneaker.Envelope{
			KMS: kms.New(nil),
		},
		Bucket:            u.Host,
		Prefix:            u.Path,
		EncryptionContext: ctxt,
		KeyId:             os.Getenv("SNEAKER_MASTER_KEY"),
	}
}

func parseContext(s string) (map[string]string, error) {
	if s == "" {
		return nil, nil
	}

	context := map[string]string{}
	for _, v := range strings.Split(s, ",") {
		parts := strings.SplitN(v, "=", 2)
		if len(parts) != 2 {
			return nil, fmt.Errorf("unable to parse context: %q", v)
		}
		context[parts[0]] = parts[1]
	}
	return context, nil
}

func openPath(file string, o func(string) (*os.File, error), def *os.File) *os.File {
	if file == "-" {
		return def
	}
	f, err := o(file)
	if err != nil {
		log.Fatal(err)
	}
	return f
}

const (
	conciseTime = "2006-01-02T15:04"
)
