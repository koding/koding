package messaging

type nonSubMsgType int

const (
	messageTypePublish nonSubMsgType = 1 << iota
	messageTypePAM
)

type NonSubJob struct {
	Channel         string
	NonSubURL       string
	NonSubMsgType   nonSubMsgType
	CallbackChannel chan []byte
	ErrorChannel    chan []byte
}

type NonSubWorker struct {
	Workers    chan chan NonSubJob
	JobChannel chan NonSubJob
	quit       chan bool
	id         int
}

type NonSubQueueProcessor struct {
	Workers    chan chan NonSubJob
	maxWorkers int
	Sem        chan bool
}

func NewNonSubWorker(workers chan chan NonSubJob, id int) NonSubWorker {
	return NonSubWorker{
		Workers:    workers,
		JobChannel: make(chan NonSubJob),
		id:         id,
	}
}

func (pw NonSubWorker) StartNonSubWorker(pubnub *Pubnub) {
	go func() {
		for {
			pw.Workers <- pw.JobChannel
			pubnub.infoLogger.Printf("INFO: StartNonSubWorker: Worker started", pw.id)
			select {
			case nonSubJob := <-pw.JobChannel:

				pubnub.infoLogger.Printf("INFO: StartNonSubWorker processing job FOR CHANNEL %s: Got job %s, id:%d", nonSubJob.Channel, nonSubJob.NonSubURL, pw.id)
				pn := pubnub
				value, responseCode, err := pn.nonSubHTTPRequest(nonSubJob.NonSubURL)
				if nonSubJob.NonSubMsgType == messageTypePublish {
					pubnub.readPublishResponseAndCallSendResponse(nonSubJob.Channel, value, responseCode, err, nonSubJob.CallbackChannel, nonSubJob.ErrorChannel)
				} else if nonSubJob.NonSubMsgType == messageTypePAM {
					pubnub.handlePAMResponse(nonSubJob.Channel, value, responseCode, err, nonSubJob.CallbackChannel, nonSubJob.ErrorChannel)
				}
			}
		}
	}()
}

func (pubnub *Pubnub) newNonSubQueueProcessor(maxWorkers int) *NonSubQueueProcessor {
	//logic 1
	workers := make(chan chan NonSubJob, maxWorkers)
	//end logic 1

	//logic 2
	//sem := make(chan bool, maxWorkers)
	//end logic 2

	pubnub.infoLogger.Printf("INFO: Init NonSubQueueProcessor: workers %d", maxWorkers)

	p := &NonSubQueueProcessor{
		//logic 1
		Workers: workers,
		//end logic 1
		maxWorkers: maxWorkers,
		//logic 2
		//Sem: sem,
		//end logic 2
	}
	p.Run(pubnub)
	return p
}

func (p *NonSubQueueProcessor) Run(pubnub *Pubnub) {
	pubnub.infoLogger.Printf("INFO: NonSubQueueProcessor: Running with workers %d", p.maxWorkers)
	//logic 1
	for i := 0; i < p.maxWorkers; i++ {
		pubnub.infoLogger.Printf("INFO: NonSubQueueProcessor: StartNonSubWorker %d", i)
		nonSubWorker := NewNonSubWorker(p.Workers, i)
		nonSubWorker.StartNonSubWorker(pubnub)
	}
	//end logic 1
	go p.process(pubnub)
}

func (p *NonSubQueueProcessor) process(pubnub *Pubnub) {
	for {
		select {
		case nonSubJob := <-pubnub.nonSubJobQueue:
			pubnub.infoLogger.Printf("INFO: NonSubQueueProcessor process: Got job for channel %s %s", nonSubJob.Channel, nonSubJob.NonSubURL)
			//logic 2
			//p.Sem <- true
			//end logic 2
			go func(nonSubJob NonSubJob) {
				//logic 1
				jobChannel := <-p.Workers

				jobChannel <- nonSubJob
				//end logic 1

				//logic 2
				/*defer func() {
					pubnub.infoLogger.Printf("INFO: StartNonSubWorker processing job: Defer job %d", nonSubJob.NonSubURL)
					b := <-p.Sem
					pubnub.infoLogger.Printf("INFO: StartNonSubWorker processing job: After Defer job %d", b)
				}()

				pubnub.infoLogger.Printf("INFO: StartNonSubWorker processing job FOR CHANNEL %s: Got job %d", nonSubJob.Channel, nonSubJob.NonSubURL)
				pn := pubnub
				value, responseCode, err := pn.nonSubHTTPRequest(nonSubJob.NonSubURL)
				pubnub.readPublishResponseAndCallSendResponse(nonSubJob.Channel, value, responseCode, err, nonSubJob.CallbackChannel, nonSubJob.ErrorChannel)
				*/
				//end logic 2

			}(nonSubJob)
		}
	}
}

func (p *NonSubQueueProcessor) Close() {
	close(p.Workers)
}
