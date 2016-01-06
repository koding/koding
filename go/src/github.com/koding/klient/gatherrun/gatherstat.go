package gatherrun

type GatherError struct {
	Env        string  `json:"env"`
	Username   string  `json:"username"`
	InstanceId string  `json:"instanceId"`
	Errors     []error `json:errors`
}

type GatherStat struct {
	Env        string             `json:"env"`
	Username   string             `json:"username"`
	InstanceId string             `json:"instanceId"`
	Type       string             `json:"type"`
	Stats      []GatherSingleStat `json:"stats"`
}

type GatherSingleStat struct {
	Name  string      `json:"name"`
	Type  string      `json:"type"`
	Value interface{} `json:"value"`
}
