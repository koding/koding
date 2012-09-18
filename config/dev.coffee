module.exports =
  webPort   : 3000
  mongo     : 'dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect'
  mq        :
    host    : 'localhost'
    login   : 'guest'
    password: 'guest'
    # host    : "web0.beta.system.aws.koding.com"
    # login     : "guest"
    # password  : "x1srTA7!%Vb}$n|S"
  email     :
    host    : 'localhost'
    protocol: 'http:'
    defaultFromAddress: 'hello@koding.com'
  guestCleanup:
     # define this to limit the number of guset accounts
     # to be cleaned up per collection cycle.
    batchSize: undefined
    cron    : '*/10 * * * * *'
  # host      : "localhost"
  # login     : "guest"
  # password  : "guest"