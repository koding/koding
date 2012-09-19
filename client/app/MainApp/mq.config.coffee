KD.remote = new Bongo

  getSessionToken:-> $.cookie('clientId')

  mq: do->
    {broker} = KD.config
    brokerOptions = {
      encrypted     : yes
      sockURL       : broker.sockJS
      authEndPoint  : broker.auth
    }
    new Broker broker.apiKey, brokerOptions
    # switch KD.env
    #   when 'beta'
    #     new Broker 'a19c8bf6d2cad6c7a006', brokerOptions
    #   else
    #     new Broker 'a6f121a130a44c7f5325', brokerOptions
  # _addFlashFallback BONGO_MQ, connectionTimeout: 10000
