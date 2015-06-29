package webhook

type IntegrationContainer struct {
	Integration         *Integration                  `json:"integration"`
	ChannelIntegrations []ChannelIntegrationContainer `json:"channelIntegrations"`
}

func NewIntegrationContainer() *IntegrationContainer {
	return &IntegrationContainer{
		ChannelIntegrations: make([]ChannelIntegrationContainer, 0),
	}
}

func (ic *IntegrationContainer) Push(ci ChannelIntegrationContainer) {
	ic.ChannelIntegrations = append(ic.ChannelIntegrations, ci)
}

type IntegrationContainers []IntegrationContainer

func NewIntegrationContainers() *IntegrationContainers {
	return &IntegrationContainers{}
}

func (ics *IntegrationContainers) Push(i IntegrationContainer) {
	*ics = append(*ics, i)
}

func (ics *IntegrationContainers) Populate(groupName string) error {
	// fetch channel containers with given group name
	ci := NewChannelIntegration()
	channelIntegrations, err := ci.ByGroupName(groupName)
	if err != nil {
		return err
	}

	// group channel integrations by integration id
	containers := make(map[int64]*IntegrationContainer)
	for k := range channelIntegrations {
		channelIntegration := channelIntegrations[k]
		cic := NewChannelIntegrationContainer(&channelIntegration)
		if err := cic.Populate(); err != nil {
			return err
		}

		integration, ok := containers[channelIntegration.IntegrationId]
		if !ok {
			integration = NewIntegrationContainer()
			containers[channelIntegration.IntegrationId] = integration
		}
		integration.Push(*cic)
	}

	// fetch related integrations
	integrationIds := make([]int64, 0)
	for k, _ := range containers {
		integrationIds = append(integrationIds, k)
	}

	ints, err := NewIntegration().FetchByIds(integrationIds)
	if err != nil {
		return err
	}

	for k := range ints {
		integration := ints[k]
		ic := containers[integration.Id]
		ic.Integration = &integration
		ics.Push(*ic)
	}

	return nil
}
