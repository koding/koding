KD.remote = new Bongo
  mq: do->

    brokerOptions = {
      encrypted: yes
      sockURL: 'http://localhost:8008/subscribe'
      authEndPoint: 'http://localhost:3000/auth'
    }
    switch KD.env
      when 'beta'
        new Broker 'a19c8bf6d2cad6c7a006', brokerOptions
      else
        new Broker 'a6f121a130a44c7f5325', brokerOptions
  # _addFlashFallback BONGO_MQ, connectionTimeout: 10000
