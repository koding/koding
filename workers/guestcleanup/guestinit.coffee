getWorker =(config)->
  Bongo = require 'bongo'
  {mongo} = config
  console.log __dirname
  worker = new Bongo {
    mongo
    root: __dirname
    models: [
      '../social/lib/social/models/guest.coffee'
    ]
  }

module.exports =
  dropGuests:(configFile)->
    worker = getWorker require configFile
    worker.models.JGuest.drop ->
      console.log 'the guests are dropped'

  resetGuests:(configFile)->
    config = require configFile
    worker = getWorker config
    worker.models.JGuest._resetAllGuests config.guests.poolSize, ->
      console.log 'done creating the guests'

