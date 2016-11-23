package metrics

// Collector is the interface that collects data, either by running
// a bash command or a script and returns data of value.
type Collector interface {
	Run() ([]byte, error)
}
