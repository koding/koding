KD.remote = new Bongo

  getSessionToken:-> $.cookie('clientId')

  mq: do->
    {broker} = KD.config
    brokerOptions = {
      encrypted     : yes
      sockURL       : broker.sockJS
      authEndPoint  : broker.auth
      vhost         : broker.vhost
      autoReconnect : yes
    }
    broker = new Broker broker.apiKey, brokerOptions