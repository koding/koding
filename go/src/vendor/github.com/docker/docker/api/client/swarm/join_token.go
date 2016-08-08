package swarm

import (
	"errors"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/docker/docker/api/client"
	"github.com/docker/docker/cli"
	"github.com/docker/engine-api/types/swarm"
	"golang.org/x/net/context"
)

const (
	flagRotate = "rotate"
	flagQuiet  = "quiet"
)

func newJoinTokenCommand(dockerCli *client.DockerCli) *cobra.Command {
	var rotate, quiet bool

	cmd := &cobra.Command{
		Use:   "join-token [-q] [--rotate] (worker|manager)",
		Short: "Manage join tokens",
		Args:  cli.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			if args[0] != "worker" && args[0] != "manager" {
				return errors.New("unknown role " + args[0])
			}

			client := dockerCli.Client()
			ctx := context.Background()

			if rotate {
				var flags swarm.UpdateFlags

				swarm, err := client.SwarmInspect(ctx)
				if err != nil {
					return err
				}

				if args[0] == "worker" {
					flags.RotateWorkerToken = true
				} else if args[0] == "manager" {
					flags.RotateManagerToken = true
				}

				err = client.SwarmUpdate(ctx, swarm.Version, swarm.Spec, flags)
				if err != nil {
					return err
				}
			}

			swarm, err := client.SwarmInspect(ctx)
			if err != nil {
				return err
			}

			if quiet {
				if args[0] == "worker" {
					fmt.Fprintln(dockerCli.Out(), swarm.JoinTokens.Worker)
				} else if args[0] == "manager" {
					fmt.Fprintln(dockerCli.Out(), swarm.JoinTokens.Manager)
				}
			} else {
				info, err := client.Info(ctx)
				if err != nil {
					return err
				}
				return printJoinCommand(ctx, dockerCli, info.Swarm.NodeID, args[0] == "worker", args[0] == "manager")
			}
			return nil
		},
	}

	flags := cmd.Flags()
	flags.BoolVar(&rotate, flagRotate, false, "Rotate join token")
	flags.BoolVarP(&quiet, flagQuiet, "q", false, "Only display token")

	return cmd
}

func printJoinCommand(ctx context.Context, dockerCli *client.DockerCli, nodeID string, worker bool, manager bool) error {
	client := dockerCli.Client()

	swarm, err := client.SwarmInspect(ctx)
	if err != nil {
		return err
	}

	node, _, err := client.NodeInspectWithRaw(ctx, nodeID)
	if err != nil {
		return err
	}

	if node.ManagerStatus != nil {
		if worker {
			fmt.Fprintf(dockerCli.Out(), "To add a worker to this swarm, run the following command:\n    docker swarm join \\\n    --token %s \\\n    %s\n", swarm.JoinTokens.Worker, node.ManagerStatus.Addr)
		}
		if manager {
			if worker {
				fmt.Fprintln(dockerCli.Out())
			}
			fmt.Fprintf(dockerCli.Out(), "To add a manager to this swarm, run the following command:\n    docker swarm join \\\n    --token %s \\\n    %s\n", swarm.JoinTokens.Manager, node.ManagerStatus.Addr)
		}
	}

	return nil
}
