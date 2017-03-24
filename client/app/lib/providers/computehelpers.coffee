kd = require 'kd'


module.exports = class ComputeHelpers


  # This method is not used in any place, I put it here until
  # we have a valid test suit for client side modular tests. ~ GG
  #
  @infoTest = (machine) ->

    { log } = kd
    cc      = kd.singletons.computeController

    count   = 5
    kloud   = cc.getKloud()
    { now } = Date

    machine     ?= (cc.storage.machines.get()).first
    machineId    = machine._id
    currentState = machine.status.state

    tester = (cb) ->

      i      = 0
      res    = {}
      failed = 0

      info   = ->

        console.time "kl_#{i}"
        res[i] = {}
        kloud.info { machineId, currentState }

        .then (r) ->
          res[i]['failed'] = no
          res[i]['result'] = r

        .timeout 5000

        .catch ->
          res[i]['failed'] = yes
          failed++

        .finally ->

          console.timeEnd "kl_#{i}"
          i++

          if i is count then cb res, failed else info()

      info()

    kloud._disableKlientInfo = no

    log "Starting to test `info` for #{count} times with klient.info enabled"
    console.time 'via klient.info'
    tester (res, failed) ->
      console.timeEnd 'via klient.info'
      log 'All completed:', res, failed

      kloud._disableKlientInfo = yes

      log "Starting to test `info` for #{count} times with klient.info disabled"
      console.time 'via kloud.info'
      tester (res, failed) ->
        console.timeEnd 'via kloud.info'
        log 'All completed:', res, failed
