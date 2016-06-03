package eventexporter

type MultiExporter []Exporter

// NewMultiExporter inits the exporter services like; segment, datadog etc..
// and implements Exporter interface with Send and Close functions
func NewMultiExporter(e ...Exporter) MultiExporter {
	return MultiExporter(e)
}

func (m MultiExporter) Send(event *Event) error {
	for _, e := range m {
		if err := e.Send(event); err != nil {
			return err
		}
	}

	return nil
}

func (m MultiExporter) Close() error {
	for _, e := range m {
		if err := e.Close(); err != nil {
			return err
		}
	}

	return nil
}
