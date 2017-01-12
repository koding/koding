package algoliasearch

type getLogsRes struct {
	Logs []LogRes `json:"logs"`
}

type LogRes struct {
	Answer           string `json:"answer"`
	AnswerCode       string `json:"answer_code"`
	IP               string `json:"ip"`
	Method           string `json:"method"`
	NbAPICalls       string `json:"nb_api_calls"`
	ProcessingTimeMs string `json:"processing_time_ms"`
	QueryBody        string `json:"query_body"`
	QueryHeaders     string `json:"query_headers"`
	QueryNbHits      string `json:":query_nb_hits"`
	SHA1             string `json:"sha1"`
	Timestamp        string `json:"timestamp"`
	URL              string `json:"url"`
}
