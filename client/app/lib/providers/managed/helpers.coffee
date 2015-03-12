nick = require 'app/util/nick'
kd   = require 'kd'

getIp = (url)->
  _ = global.document.createElement 'a'
  _.href = url

  return _.hostname


module.exports =

  queryKites: ->

    return kd.singletons.kontrol
      .queryKites
        query         :
          username    : nick()
          environment : 'managed'
      .timeout 5000


  createMachine: (kite, callback)->

    { computeController } = kd.singletons

    stack = computeController.stacks.first._id

    { generateQueryString } = require 'app/kite/kitecache'

    computeController.create {
      provider    : 'managed'
      queryString : generateQueryString kite.kite
      ipAddress   : getIp kite.url
      stack
    }, callback
