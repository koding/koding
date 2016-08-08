package libcontainerd

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/Sirupsen/logrus"
	containerd "github.com/docker/containerd/api/grpc/types"
	"github.com/docker/docker/pkg/idtools"
	"github.com/docker/docker/pkg/mount"
	specs "github.com/opencontainers/specs/specs-go"
	"golang.org/x/net/context"
)

type client struct {
	clientCommon

	// Platform specific properties below here.
	remote        *remote
	q             queue
	exitNotifiers map[string]*exitNotifier
	liveRestore   bool
}

func (clnt *client) AddProcess(ctx context.Context, containerID, processFriendlyName string, specp Process) error {
	clnt.lock(containerID)
	defer clnt.unlock(containerID)
	container, err := clnt.getContainer(containerID)
	if err != nil {
		return err
	}

	spec, err := container.spec()
	if err != nil {
		return err
	}
	sp := spec.Process
	sp.Args = specp.Args
	sp.Terminal = specp.Terminal
	if specp.Env != nil {
		sp.Env = specp.Env
	}
	if specp.Cwd != nil {
		sp.Cwd = *specp.Cwd
	}
	if specp.User != nil {
		sp.User = specs.User{
			UID:            specp.User.UID,
			GID:            specp.User.GID,
			AdditionalGids: specp.User.AdditionalGids,
		}
	}
	if specp.Capabilities != nil {
		sp.Capabilities = specp.Capabilities
	}

	p := container.newProcess(processFriendlyName)

	r := &containerd.AddProcessRequest{
		Args:     sp.Args,
		Cwd:      sp.Cwd,
		Terminal: sp.Terminal,
		Id:       containerID,
		Env:      sp.Env,
		User: &containerd.User{
			Uid:            sp.User.UID,
			Gid:            sp.User.GID,
			AdditionalGids: sp.User.AdditionalGids,
		},
		Pid:             processFriendlyName,
		Stdin:           p.fifo(syscall.Stdin),
		Stdout:          p.fifo(syscall.Stdout),
		Stderr:          p.fifo(syscall.Stderr),
		Capabilities:    sp.Capabilities,
		ApparmorProfile: sp.ApparmorProfile,
		SelinuxLabel:    sp.SelinuxLabel,
		NoNewPrivileges: sp.NoNewPrivileges,
		Rlimits:         convertRlimits(sp.Rlimits),
	}

	iopipe, err := p.openFifos(sp.Terminal)
	if err != nil {
		return err
	}

	if _, err := clnt.remote.apiClient.AddProcess(ctx, r); err != nil {
		p.closeFifos(iopipe)
		return err
	}

	container.processes[processFriendlyName] = p

	clnt.unlock(containerID)

	if err := clnt.backend.AttachStreams(processFriendlyName, *iopipe); err != nil {
		return err
	}
	clnt.lock(containerID)

	return nil
}

func (clnt *client) prepareBundleDir(uid, gid int) (string, error) {
	root, err := filepath.Abs(clnt.remote.stateDir)
	if err != nil {
		return "", err
	}
	if uid == 0 && gid == 0 {
		return root, nil
	}
	p := string(filepath.Separator)
	for _, d := range strings.Split(root, string(filepath.Separator))[1:] {
		p = filepath.Join(p, d)
		fi, err := os.Stat(p)
		if err != nil && !os.IsNotExist(err) {
			return "", err
		}
		if os.IsNotExist(err) || fi.Mode()&1 == 0 {
			p = fmt.Sprintf("%s.%d.%d", p, uid, gid)
			if err := idtools.MkdirAs(p, 0700, uid, gid); err != nil && !os.IsExist(err) {
				return "", err
			}
		}
	}
	return p, nil
}

func (clnt *client) Create(containerID string, spec Spec, options ...CreateOption) (err error) {
	clnt.lock(containerID)
	defer clnt.unlock(containerID)

	if ctr, err := clnt.getContainer(containerID); err == nil {
		if ctr.restarting {
			ctr.restartManager.Cancel()
			ctr.clean()
		} else {
			return fmt.Errorf("Container %s is already active", containerID)
		}
	}

	uid, gid, err := getRootIDs(specs.Spec(spec))
	if err != nil {
		return err
	}
	dir, err := clnt.prepareBundleDir(uid, gid)
	if err != nil {
		return err
	}

	container := clnt.newContainer(filepath.Join(dir, containerID), options...)
	if err := container.clean(); err != nil {
		return err
	}

	defer func() {
		if err != nil {
			container.clean()
			clnt.deleteContainer(containerID)
		}
	}()

	if err := idtools.MkdirAllAs(container.dir, 0700, uid, gid); err != nil && !os.IsExist(err) {
		return err
	}

	f, err := os.Create(filepath.Join(container.dir, configFilename))
	if err != nil {
		return err
	}
	defer f.Close()
	if err := json.NewEncoder(f).Encode(spec); err != nil {
		return err
	}

	return container.start()
}

func (clnt *client) Signal(containerID string, sig int) error {
	clnt.lock(containerID)
	defer clnt.unlock(containerID)
	_, err := clnt.remote.apiClient.Signal(context.Background(), &containerd.SignalRequest{
		Id:     containerID,
		Pid:    InitFriendlyName,
		Signal: uint32(sig),
	})
	return err
}

func (clnt *client) SignalProcess(containerID string, pid string, sig int) error {
	clnt.lock(containerID)
	defer clnt.unlock(containerID)
	_, err := clnt.remote.apiClient.Signal(context.Background(), &containerd.SignalRequest{
		Id:     containerID,
		Pid:    pid,
		Signal: uint32(sig),
	})
	return err
}

func (clnt *client) Resize(containerID, processFriendlyName string, width, height int) error {
	clnt.lock(containerID)
	defer clnt.unlock(containerID)
	if _, err := clnt.getContainer(containerID); err != nil {
		return err
	}
	_, err := clnt.remote.apiClient.UpdateProcess(context.Background(), &containerd.UpdateProcessRequest{
		Id:     containerID,
		Pid:    processFriendlyName,
		Width:  uint32(width),
		Height: uint32(height),
	})
	return err
}

func (clnt *client) Pause(containerID string) error {
	return clnt.setState(containerID, StatePause)
}

func (clnt *client) setState(containerID, state string) error {
	clnt.lock(containerID)
	container, err := clnt.getContainer(containerID)
	if err != nil {
		clnt.unlock(containerID)
		return err
	}
	if container.systemPid == 0 {
		clnt.unlock(containerID)
		return fmt.Errorf("No active process for container %s", containerID)
	}
	st := "running"
	if state == StatePause {
		st = "paused"
	}
	chstate := make(chan struct{})
	_, err = clnt.remote.apiClient.UpdateContainer(context.Background(), &containerd.UpdateContainerRequest{
		Id:     containerID,
		Pid:    InitFriendlyName,
		Status: st,
	})
	if err != nil {
		clnt.unlock(containerID)
		return err
	}
	container.pauseMonitor.append(state, chstate)
	clnt.unlock(containerID)
	<-chstate
	return nil
}

func (clnt *client) Resume(containerID string) error {
	return clnt.setState(containerID, StateResume)
}

func (clnt *client) Stats(containerID string) (*Stats, error) {
	resp, err := clnt.remote.apiClient.Stats(context.Background(), &containerd.StatsRequest{containerID})
	if err != nil {
		return nil, err
	}
	return (*Stats)(resp), nil
}

// Take care of the old 1.11.0 behavior in case the version upgrade
// happened without a clean daemon shutdown
func (clnt *client) cleanupOldRootfs(containerID string) {
	// Unmount and delete the bundle folder
	if mts, err := mount.GetMounts(); err == nil {
		for _, mts := range mts {
			if strings.HasSuffix(mts.Mountpoint, containerID+"/rootfs") {
				if err := syscall.Unmount(mts.Mountpoint, syscall.MNT_DETACH); err == nil {
					os.RemoveAll(strings.TrimSuffix(mts.Mountpoint, "/rootfs"))
				}
				break
			}
		}
	}
}

func (clnt *client) setExited(containerID string, exitCode uint32) error {
	clnt.lock(containerID)
	defer clnt.unlock(containerID)

	err := clnt.backend.StateChanged(containerID, StateInfo{
		CommonStateInfo: CommonStateInfo{
			State:    StateExit,
			ExitCode: exitCode,
		}})

	clnt.cleanupOldRootfs(containerID)

	return err
}

func (clnt *client) GetPidsForContainer(containerID string) ([]int, error) {
	cont, err := clnt.getContainerdContainer(containerID)
	if err != nil {
		return nil, err
	}
	pids := make([]int, len(cont.Pids))
	for i, p := range cont.Pids {
		pids[i] = int(p)
	}
	return pids, nil
}

// Summary returns a summary of the processes running in a container.
// This is a no-op on Linux.
func (clnt *client) Summary(containerID string) ([]Summary, error) {
	return nil, nil
}

func (clnt *client) getContainerdContainer(containerID string) (*containerd.Container, error) {
	resp, err := clnt.remote.apiClient.State(context.Background(), &containerd.StateRequest{Id: containerID})
	if err != nil {
		return nil, err
	}
	for _, cont := range resp.Containers {
		if cont.Id == containerID {
			return cont, nil
		}
	}
	return nil, fmt.Errorf("invalid state response")
}

func (clnt *client) newContainer(dir string, options ...CreateOption) *container {
	container := &container{
		containerCommon: containerCommon{
			process: process{
				dir: dir,
				processCommon: processCommon{
					containerID:  filepath.Base(dir),
					client:       clnt,
					friendlyName: InitFriendlyName,
				},
			},
			processes: make(map[string]*process),
		},
	}
	for _, option := range options {
		if err := option.Apply(container); err != nil {
			logrus.Error(err)
		}
	}
	return container
}

func (clnt *client) UpdateResources(containerID string, resources Resources) error {
	clnt.lock(containerID)
	defer clnt.unlock(containerID)
	container, err := clnt.getContainer(containerID)
	if err != nil {
		return err
	}
	if container.systemPid == 0 {
		return fmt.Errorf("No active process for container %s", containerID)
	}
	_, err = clnt.remote.apiClient.UpdateContainer(context.Background(), &containerd.UpdateContainerRequest{
		Id:        containerID,
		Pid:       InitFriendlyName,
		Resources: (*containerd.UpdateResource)(&resources),
	})
	if err != nil {
		return err
	}
	return nil
}

func (clnt *client) getExitNotifier(containerID string) *exitNotifier {
	clnt.mapMutex.RLock()
	defer clnt.mapMutex.RUnlock()
	return clnt.exitNotifiers[containerID]
}

func (clnt *client) getOrCreateExitNotifier(containerID string) *exitNotifier {
	clnt.mapMutex.Lock()
	w, ok := clnt.exitNotifiers[containerID]
	defer clnt.mapMutex.Unlock()
	if !ok {
		w = &exitNotifier{c: make(chan struct{}), client: clnt}
		clnt.exitNotifiers[containerID] = w
	}
	return w
}

func (clnt *client) restore(cont *containerd.Container, lastEvent *containerd.Event, options ...CreateOption) (err error) {
	clnt.lock(cont.Id)
	defer clnt.unlock(cont.Id)

	logrus.Debugf("restore container %s state %s", cont.Id, cont.Status)

	containerID := cont.Id
	if _, err := clnt.getContainer(containerID); err == nil {
		return fmt.Errorf("container %s is already active", containerID)
	}

	defer func() {
		if err != nil {
			clnt.deleteContainer(cont.Id)
		}
	}()

	container := clnt.newContainer(cont.BundlePath, options...)
	container.systemPid = systemPid(cont)

	var terminal bool
	for _, p := range cont.Processes {
		if p.Pid == InitFriendlyName {
			terminal = p.Terminal
		}
	}

	iopipe, err := container.openFifos(terminal)
	if err != nil {
		return err
	}

	if err := clnt.backend.AttachStreams(containerID, *iopipe); err != nil {
		return err
	}

	clnt.appendContainer(container)

	err = clnt.backend.StateChanged(containerID, StateInfo{
		CommonStateInfo: CommonStateInfo{
			State: StateRestore,
			Pid:   container.systemPid,
		}})

	if err != nil {
		return err
	}

	if lastEvent != nil {
		// This should only be a pause or resume event
		if lastEvent.Type == StatePause || lastEvent.Type == StateResume {
			return clnt.backend.StateChanged(containerID, StateInfo{
				CommonStateInfo: CommonStateInfo{
					State: lastEvent.Type,
					Pid:   container.systemPid,
				}})
		}

		logrus.Warnf("unexpected backlog event: %#v", lastEvent)
	}

	return nil
}

func (clnt *client) getContainerLastEvent(containerID string) (*containerd.Event, error) {
	er := &containerd.EventsRequest{
		Timestamp:  clnt.remote.restoreFromTimestamp,
		StoredOnly: true,
		Id:         containerID,
	}
	events, err := clnt.remote.apiClient.Events(context.Background(), er)
	if err != nil {
		logrus.Errorf("libcontainerd: failed to get container events stream for %s: %q", er.Id, err)
		return nil, err
	}

	var ev *containerd.Event
	for {
		e, err := events.Recv()
		if err != nil {
			if err.Error() == "EOF" {
				break
			}
			logrus.Errorf("libcontainerd: failed to get container event for %s: %q", containerID, err)
			return nil, err
		}

		logrus.Debugf("libcontainerd: received past event %#v", e)

		switch e.Type {
		case StateExit, StatePause, StateResume:
			ev = e
		}
	}

	return ev, nil
}

func (clnt *client) Restore(containerID string, options ...CreateOption) error {
	// Synchronize with live events
	clnt.remote.Lock()
	defer clnt.remote.Unlock()
	// Check that containerd still knows this container.
	//
	// In the unlikely event that Restore for this container process
	// the its past event before the main loop, the event will be
	// processed twice. However, this is not an issue as all those
	// events will do is change the state of the container to be
	// exactly the same.
	cont, err := clnt.getContainerdContainer(containerID)
	// Get its last event
	ev, eerr := clnt.getContainerLastEvent(containerID)
	if err != nil || cont.Status == "Stopped" {
		if err != nil && !strings.Contains(err.Error(), "container not found") {
			// Legitimate error
			return err
		}

		// If ev is nil, then we already consumed all the event of the
		// container, included the "exit" one.
		// Thus we return to avoid overriding the Exit Code.
		if ev == nil {
			logrus.Warnf("libcontainerd: restore was called on a fully synced container (%s)", containerID)
			return nil
		}

		// get the exit status for this container
		ec := uint32(0)
		if eerr == nil && ev.Type == StateExit {
			ec = ev.Status
		}
		clnt.setExited(containerID, ec)

		return nil
	}

	// container is still alive
	if clnt.liveRestore {
		if err := clnt.restore(cont, ev, options...); err != nil {
			logrus.Errorf("error restoring %s: %v", containerID, err)
		}
		return nil
	}

	// Kill the container if liveRestore == false
	w := clnt.getOrCreateExitNotifier(containerID)
	clnt.lock(cont.Id)
	container := clnt.newContainer(cont.BundlePath)
	container.systemPid = systemPid(cont)
	clnt.appendContainer(container)
	clnt.unlock(cont.Id)

	container.discardFifos()

	if err := clnt.Signal(containerID, int(syscall.SIGTERM)); err != nil {
		logrus.Errorf("error sending sigterm to %v: %v", containerID, err)
	}
	select {
	case <-time.After(10 * time.Second):
		if err := clnt.Signal(containerID, int(syscall.SIGKILL)); err != nil {
			logrus.Errorf("error sending sigkill to %v: %v", containerID, err)
		}
		select {
		case <-time.After(2 * time.Second):
		case <-w.wait():
			return nil
		}
	case <-w.wait():
		return nil
	}

	clnt.deleteContainer(containerID)

	return clnt.setExited(containerID, uint32(255))
}

type exitNotifier struct {
	id     string
	client *client
	c      chan struct{}
	once   sync.Once
}

func (en *exitNotifier) close() {
	en.once.Do(func() {
		close(en.c)
		en.client.mapMutex.Lock()
		if en == en.client.exitNotifiers[en.id] {
			delete(en.client.exitNotifiers, en.id)
		}
		en.client.mapMutex.Unlock()
	})
}
func (en *exitNotifier) wait() <-chan struct{} {
	return en.c
}
