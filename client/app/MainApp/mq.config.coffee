BONGO_MQ = do->
  options = {
    encrypted: yes
  }
  switch KD.env
    when 'beta'
      new Broker 'a19c8bf6d2cad6c7a006', options
    else
      new Broker 'a6f121a130a44c7f5325', options

# _addFlashFallback BONGO_MQ, connectionTimeout: 10000