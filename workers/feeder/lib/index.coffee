Broker = require 'broker'
Feeder = require './feeder'

Object.defineProperty global, 'KONFIG', value: require './config'
{mq, mongo, queueName, exchangePrefix} = KONFIG

# JAccount = require '../../social/lib/social/models/account'
# JAccount.setClient dbUrl

broker = new Broker mq

feeder = new Feeder
  mq            : broker
  queueName     : queueName
  exchangePrefix: exchangePrefix