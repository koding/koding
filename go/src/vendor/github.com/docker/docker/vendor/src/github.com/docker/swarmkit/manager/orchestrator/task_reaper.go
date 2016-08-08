package orchestrator

import (
	"sort"
	"time"

	"github.com/docker/go-events"
	"github.com/docker/swarmkit/api"
	"github.com/docker/swarmkit/manager/state"
	"github.com/docker/swarmkit/manager/state/store"
)

const (
	// maxDirty is the size threshold for running a task pruning operation.
	maxDirty = 1000
)

type instanceTuple struct {
	instance  uint64 // unset for global tasks
	serviceID string
	nodeID    string // unset for replicated tasks
}

// A TaskReaper deletes old tasks when more than TaskHistoryRetentionLimit tasks
// exist for the same service/instance or service/nodeid combination.
type TaskReaper struct {
	store *store.MemoryStore
	// taskHistory is the number of tasks to keep
	taskHistory int64
	dirty       map[instanceTuple]struct{}
	watcher     chan events.Event
	cancelWatch func()
	stopChan    chan struct{}
	doneChan    chan struct{}
}

// NewTaskReaper creates a new TaskReaper.
func NewTaskReaper(store *store.MemoryStore) *TaskReaper {
	watcher, cancel := state.Watch(store.WatchQueue(), state.EventCreateTask{}, state.EventUpdateCluster{})

	return &TaskReaper{
		store:       store,
		watcher:     watcher,
		cancelWatch: cancel,
		dirty:       make(map[instanceTuple]struct{}),
		stopChan:    make(chan struct{}),
		doneChan:    make(chan struct{}),
	}
}

// Run is the TaskReaper's main loop.
func (tr *TaskReaper) Run() {
	defer close(tr.doneChan)

	tr.store.View(func(readTx store.ReadTx) {
		clusters, err := store.FindClusters(readTx, store.ByName(store.DefaultClusterName))
		if err == nil && len(clusters) == 1 {
			tr.taskHistory = clusters[0].Spec.Orchestration.TaskHistoryRetentionLimit
		}
	})

	ticker := time.NewTicker(250 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case event := <-tr.watcher:
			switch v := event.(type) {
			case state.EventCreateTask:
				t := v.Task
				tr.dirty[instanceTuple{
					instance:  t.Slot,
					serviceID: t.ServiceID,
					nodeID:    t.NodeID,
				}] = struct{}{}
				if len(tr.dirty) > maxDirty {
					tr.tick()
				}
			case state.EventUpdateCluster:
				tr.taskHistory = v.Cluster.Spec.Orchestration.TaskHistoryRetentionLimit
			}
		case <-ticker.C:
			tr.tick()
		case <-tr.stopChan:
			return
		}
	}
}

func (tr *TaskReaper) tick() {
	if len(tr.dirty) == 0 {
		return
	}

	defer func() {
		tr.dirty = make(map[instanceTuple]struct{})
	}()

	var deleteTasks []string

	tr.store.View(func(tx store.ReadTx) {
		for dirty := range tr.dirty {
			service := store.GetService(tx, dirty.serviceID)
			if service == nil {
				continue
			}

			taskHistory := tr.taskHistory

			if taskHistory < 0 {
				continue
			}

			var historicTasks []*api.Task

			switch service.Spec.GetMode().(type) {
			case *api.ServiceSpec_Replicated:
				var err error
				historicTasks, err = store.FindTasks(tx, store.BySlot(dirty.serviceID, dirty.instance))
				if err != nil {
					continue
				}

			case *api.ServiceSpec_Global:
				tasksByNode, err := store.FindTasks(tx, store.ByNodeID(dirty.nodeID))
				if err != nil {
					continue
				}

				for _, t := range tasksByNode {
					if t.ServiceID == dirty.serviceID {
						historicTasks = append(historicTasks, t)
					}
				}
			}

			if int64(len(historicTasks)) <= taskHistory {
				continue
			}

			// TODO(aaronl): This could filter for non-running tasks and use quickselect
			// instead of sorting the whole slice.
			sort.Sort(tasksByTimestamp(historicTasks))

			for _, t := range historicTasks {
				if t.DesiredState <= api.TaskStateRunning {
					// Don't delete running tasks
					continue
				}

				deleteTasks = append(deleteTasks, t.ID)

				taskHistory++
				if int64(len(historicTasks)) <= taskHistory {
					break
				}
			}

		}
	})

	if len(deleteTasks) > 0 {
		tr.store.Batch(func(batch *store.Batch) error {
			for _, taskID := range deleteTasks {
				batch.Update(func(tx store.Tx) error {
					return store.DeleteTask(tx, taskID)
				})
			}
			return nil
		})
	}
}

// Stop stops the TaskReaper and waits for the main loop to exit.
func (tr *TaskReaper) Stop() {
	tr.cancelWatch()
	close(tr.stopChan)
	<-tr.doneChan
}

type tasksByTimestamp []*api.Task

func (t tasksByTimestamp) Len() int {
	return len(t)
}
func (t tasksByTimestamp) Swap(i, j int) {
	t[i], t[j] = t[j], t[i]
}
func (t tasksByTimestamp) Less(i, j int) bool {
	if t[i].Status.Timestamp == nil {
		return true
	}
	if t[j].Status.Timestamp == nil {
		return false
	}
	if t[i].Status.Timestamp.Seconds < t[j].Status.Timestamp.Seconds {
		return true
	}
	if t[i].Status.Timestamp.Seconds > t[j].Status.Timestamp.Seconds {
		return false
	}
	return t[i].Status.Timestamp.Nanos < t[j].Status.Timestamp.Nanos
}
