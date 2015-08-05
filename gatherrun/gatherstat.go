package gatherrun

type Gather struct {
	Env        string `json:"env"`
	Username   string `json:"username"`
	InstanceId string `json:"instanceId"`
}

type GatherStat struct {
	*Gather
	Stats []GatherSingleStat `json:"stats"`
}

type GatherError struct {
	*Gather
	Error string `json:error`
}

type GatherSingleStat struct {
	Name  string      `json:"name"`
	Type  string      `json:"type"`
	Value interface{} `json:"value"`
}

func NewGatherError(g *Gather, err error) *GatherError {
	return &GatherError{g, err.Error()}
}

func NewGatherStat(g *Gather, results []GatherSingleStat) *GatherStat {
	return &GatherStat{g, results}
}
