kd = require 'kd'
Promise = require 'bluebird'
globals = require 'globals'
Machine = require './machine'
showError = require '../util/showError'
ComputePlansModalPaid = require './computeplansmodalpaid'
ComputePlansModalFree = require './computeplansmodalfree'
KDNotificationView = kd.NotificationView
remote = require('./remote').getInstance()


module.exports = class ComputeHelpers


  @destroyExistingMachines = (callback)->

    { computeController } = kd.singletons

    computeController.fetchMachines (err, machines)->

      return callback err  if err?

      destroyPromises = []

      machines.forEach (machine) ->
        destroyPromises.push computeController.destroy machine, yes

      Promise
        .all destroyPromises
        .timeout globals.COMPUTECONTROLLER_TIMEOUT
        .then ->
          callback null


  @handleNewMachineRequest = (callback = kd.noop)->

    cc = kd.singletons.computeController

    return  if cc._inprogress
    cc._inprogress = yes

    cc.fetchPlanCombo "koding", (err, info) ->

      if showError err
        return cc._inprogress = no

      { plan, plans, usage } = info

      limits  = plans[plan]
      options = { plan, limits, usage }

      if limits.total > 1

        new ComputePlansModalPaid options
        cc._inprogress = no

        callback()
        return

      cc.fetchMachines (err, machines)=>

        kd.warn err  if err?

        if err? or machines.length > 0
          new ComputePlansModalFree options
          cc._inprogress = no

          callback()

        else if machines.length is 0

          stack   = cc.stacks.first._id
          storage = plans[plan]?.storage or 3

          cc.create {
            provider : "koding"
            stack, storage
          }, (err, machine) ->

            cc._inprogress = no

            callback()

            unless showError err
              globals.userMachines.push machine


  # Helper method to run a specific app
  # with a specific machine
  #
  @requireMachine = (options = {}, callback = kd.noop) ->

    cc = kd.singletons.computeController
    cc.ready =>

      {app} = options
      unless app?.name?
        kd.warn message = "An app name required with options: {app: {name: 'APPNAME'}}"
        return callback { message }

      identifier = app.name
      identifier = "#{app.name}_#{app.version}"  if app.version?
      identifier = identifier.replace "\.", ""

      cc.storage.fetchValue identifier, (preferredUID)->

        if preferredUID?

          for machine in cc.machines
            if machine.uid is preferredUID \
              and machine.status.state is Machine.State.Running
                kd.info "Machine returned from previous selection."
                return callback null, machine

          kd.info """There was a preferred machine, but its
                  not available now. Asking for another one."""
          cc.storage.unsetKey identifier

        ComputeController_UI = require 'app/providers/computecontroller.ui'
        ComputeController_UI.askMachineForApp app, (err, machine, remember)->

          if not err and remember
            cc.storage.setValue identifier, machine.uid

          callback err, machine


  @reviveProvisioner = (machine, callback)->

    provisioner = machine.provisioners?.first
    return callback null  unless provisioner

    remote.api.JProvisioner.one slug: provisioner, callback

  # This method is not used in any place, I put it here until
  # we have a valid test suit for client side modular tests. ~ GG
  #
  @infoTest = (count = 5)->

    {log} = kd
    cc    = kd.singletons.computeController

    kloud = cc.getKloud()
    {now} = Date

    machine      = cc.machines.first
    machineId    = machine._id
    currentState = machine.status.state

    tester = (cb)->

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

          if i == count then cb res, failed else info()

      info()

    kloud._disableKlientInfo = no

    log "Starting to test `info` for #{count} times with klient.info enabled"
    console.time 'via klient.info'
    tester (res, failed)->
      console.timeEnd 'via klient.info'
      log 'All completed:', res, failed

      kloud._disableKlientInfo = yes

      log "Starting to test `info` for #{count} times with klient.info disabled"
      console.time 'via kloud.info'
      tester (res, failed)->
        console.timeEnd 'via kloud.info'
        log 'All completed:', res, failed

