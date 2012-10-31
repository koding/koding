KD.remote = new Bongo

  getUserArea:-> KD.getSingleton('mainController').getUserArea()

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