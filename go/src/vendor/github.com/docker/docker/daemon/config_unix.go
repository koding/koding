// +build linux freebsd

package daemon

import (
	"fmt"
	"net"

	"github.com/docker/docker/opts"
	flag "github.com/docker/docker/pkg/mflag"
	runconfigopts "github.com/docker/docker/runconfig/opts"
	"github.com/docker/engine-api/types"
	"github.com/docker/go-units"
)

var (
	defaultPidFile  = "/var/run/docker.pid"
	defaultGraph    = "/var/lib/docker"
	defaultExecRoot = "/var/run/docker"
)

// Config defines the configuration of a docker daemon.
// It includes json tags to deserialize configuration from a file
// using the same names that the flags in the command line uses.
type Config struct {
	CommonConfig

	// Fields below here are platform specific.
	CgroupParent         string                   `json:"cgroup-parent,omitempty"`
	ContainerdAddr       string                   `json:"containerd,omitempty"`
	EnableSelinuxSupport bool                     `json:"selinux-enabled,omitempty"`
	ExecRoot             string                   `json:"exec-root,omitempty"`
	RemappedRoot         string                   `json:"userns-remap,omitempty"`
	Ulimits              map[string]*units.Ulimit `json:"default-ulimits,omitempty"`
	Runtimes             map[string]types.Runtime `json:"runtimes,omitempty"`
	DefaultRuntime       string                   `json:"default-runtime,omitempty"`
	OOMScoreAdjust       int                      `json:"oom-score-adjust,omitempty"`
}

// bridgeConfig stores all the bridge driver specific
// configuration.
type bridgeConfig struct {
	commonBridgeConfig

	// Fields below here are platform specific.
	EnableIPv6                  bool   `json:"ipv6,omitempty"`
	EnableIPTables              bool   `json:"iptables,omitempty"`
	EnableIPForward             bool   `json:"ip-forward,omitempty"`
	EnableIPMasq                bool   `json:"ip-masq,omitempty"`
	EnableUserlandProxy         bool   `json:"userland-proxy,omitempty"`
	DefaultIP                   net.IP `json:"ip,omitempty"`
	IP                          string `json:"bip,omitempty"`
	FixedCIDRv6                 string `json:"fixed-cidr-v6,omitempty"`
	DefaultGatewayIPv4          net.IP `json:"default-gateway,omitempty"`
	DefaultGatewayIPv6          net.IP `json:"default-gateway-v6,omitempty"`
	InterContainerCommunication bool   `json:"icc,omitempty"`
}

// InstallFlags adds command-line options to the top-level flag parser for
// the current process.
// Subsequent calls to `flag.Parse` will populate config with values parsed
// from the command-line.
func (config *Config) InstallFlags(cmd *flag.FlagSet, usageFn func(string) string) {
	// First handle install flags which are consistent cross-platform
	config.InstallCommonFlags(cmd, usageFn)

	// Then platform-specific install flags
	cmd.BoolVar(&config.EnableSelinuxSupport, []string{"-selinux-enabled"}, false, usageFn("Enable selinux support"))
	cmd.StringVar(&config.SocketGroup, []string{"G", "-group"}, "docker", usageFn("Group for the unix socket"))
	config.Ulimits = make(map[string]*units.Ulimit)
	cmd.Var(runconfigopts.NewUlimitOpt(&config.Ulimits), []string{"-default-ulimit"}, usageFn("Default ulimits for containers"))
	cmd.BoolVar(&config.bridgeConfig.EnableIPTables, []string{"#iptables", "-iptables"}, true, usageFn("Enable addition of iptables rules"))
	cmd.BoolVar(&config.bridgeConfig.EnableIPForward, []string{"#ip-forward", "-ip-forward"}, true, usageFn("Enable net.ipv4.ip_forward"))
	cmd.BoolVar(&config.bridgeConfig.EnableIPMasq, []string{"-ip-masq"}, true, usageFn("Enable IP masquerading"))
	cmd.BoolVar(&config.bridgeConfig.EnableIPv6, []string{"-ipv6"}, false, usageFn("Enable IPv6 networking"))
	cmd.StringVar(&config.ExecRoot, []string{"-exec-root"}, defaultExecRoot, usageFn("Root directory for execution state files"))
	cmd.StringVar(&config.bridgeConfig.IP, []string{"#bip", "-bip"}, "", usageFn("Specify network bridge IP"))
	cmd.StringVar(&config.bridgeConfig.Iface, []string{"b", "-bridge"}, "", usageFn("Attach containers to a network bridge"))
	cmd.StringVar(&config.bridgeConfig.FixedCIDR, []string{"-fixed-cidr"}, "", usageFn("IPv4 subnet for fixed IPs"))
	cmd.StringVar(&config.bridgeConfig.FixedCIDRv6, []string{"-fixed-cidr-v6"}, "", usageFn("IPv6 subnet for fixed IPs"))
	cmd.Var(opts.NewIPOpt(&config.bridgeConfig.DefaultGatewayIPv4, ""), []string{"-default-gateway"}, usageFn("Container default gateway IPv4 address"))
	cmd.Var(opts.NewIPOpt(&config.bridgeConfig.DefaultGatewayIPv6, ""), []string{"-default-gateway-v6"}, usageFn("Container default gateway IPv6 address"))
	cmd.BoolVar(&config.bridgeConfig.InterContainerCommunication, []string{"#icc", "-icc"}, true, usageFn("Enable inter-container communication"))
	cmd.Var(opts.NewIPOpt(&config.bridgeConfig.DefaultIP, "0.0.0.0"), []string{"#ip", "-ip"}, usageFn("Default IP when binding container ports"))
	cmd.BoolVar(&config.bridgeConfig.EnableUserlandProxy, []string{"-userland-proxy"}, true, usageFn("Use userland proxy for loopback traffic"))
	cmd.BoolVar(&config.EnableCors, []string{"#api-enable-cors", "#-api-enable-cors"}, false, usageFn("Enable CORS headers in the remote API, this is deprecated by --api-cors-header"))
	cmd.StringVar(&config.CgroupParent, []string{"-cgroup-parent"}, "", usageFn("Set parent cgroup for all containers"))
	cmd.StringVar(&config.RemappedRoot, []string{"-userns-remap"}, "", usageFn("User/Group setting for user namespaces"))
	cmd.StringVar(&config.ContainerdAddr, []string{"-containerd"}, "", usageFn("Path to containerd socket"))
	cmd.BoolVar(&config.LiveRestore, []string{"-live-restore"}, false, usageFn("Enable live restore of docker when containers are still running"))
	config.Runtimes = make(map[string]types.Runtime)
	cmd.Var(runconfigopts.NewNamedRuntimeOpt("runtimes", &config.Runtimes, stockRuntimeName), []string{"-add-runtime"}, usageFn("Register an additional OCI compatible runtime"))
	cmd.StringVar(&config.DefaultRuntime, []string{"-default-runtime"}, stockRuntimeName, usageFn("Default OCI runtime for containers"))
	cmd.IntVar(&config.OOMScoreAdjust, []string{"-oom-score-adjust"}, -500, usageFn("Set the oom_score_adj for the daemon"))

	config.attachExperimentalFlags(cmd, usageFn)
}

// GetRuntime returns the runtime path and arguments for a given
// runtime name
func (config *Config) GetRuntime(name string) *types.Runtime {
	config.reloadLock.Lock()
	defer config.reloadLock.Unlock()
	if rt, ok := config.Runtimes[name]; ok {
		return &rt
	}
	return nil
}

// GetDefaultRuntimeName returns the current default runtime
func (config *Config) GetDefaultRuntimeName() string {
	config.reloadLock.Lock()
	rt := config.DefaultRuntime
	config.reloadLock.Unlock()

	return rt
}

// GetAllRuntimes returns a copy of the runtimes map
func (config *Config) GetAllRuntimes() map[string]types.Runtime {
	config.reloadLock.Lock()
	rts := config.Runtimes
	config.reloadLock.Unlock()
	return rts
}

func (config *Config) isSwarmCompatible() error {
	if config.ClusterStore != "" || config.ClusterAdvertise != "" {
		return fmt.Errorf("--cluster-store and --cluster-advertise daemon configurations are incompatible with swarm mode")
	}
	if config.LiveRestore {
		return fmt.Errorf("--live-restore daemon configuration is incompatible with swarm mode")
	}
	return nil
}
