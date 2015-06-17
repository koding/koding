package webhook

type IntegrationContainer struct {
	Integration         *Integration         `json:"integration"`
	ChannelIntegrations []ChannelIntegration `json:"channelIntegrations"`
}

func NewIntegrationContainer() *IntegrationContainer {
	return &IntegrationContainer{
		ChannelIntegrations: make([]ChannelIntegration, 0),
	}
}

func (ic *IntegrationContainer) PushChannelIntegration(ci ChannelIntegration) {
	ic.ChannelIntegrations = append(ic.ChannelIntegrations, ci)
}

type IntegrationContainers []IntegrationContainer

func NewIntegrationContainers() *IntegrationContainers {
	return &IntegrationContainers{}
}

func (ics *IntegrationContainers) PushIntegrationContainer(i IntegrationContainer) {
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
	for _, channelIntegration := range channelIntegrations {
		integration, ok := containers[channelIntegration.IntegrationId]
		if !ok {
			integration = NewIntegrationContainer()
			containers[channelIntegration.IntegrationId] = integration
		}
		integration.PushChannelIntegration(channelIntegration)
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

	for _, integration := range ints {
		ic := containers[integration.Id]
		ic.Integration = &integration
		ics.PushIntegrationContainer(*ic)
	}

	return nil
}
