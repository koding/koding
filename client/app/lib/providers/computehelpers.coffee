kd                    = require 'kd'
KDNotificationView    = kd.NotificationView

globals               = require 'globals'
Promise               = require 'bluebird'

nick                  = require 'app/util/nick'
showError             = require 'app/util/showError'

Machine               = require './machine'
AddManagedVMModal     = require './managed/addmanagedvmmodal'
ComputePlansModalPaid = require './computeplansmodalpaid'
ComputePlansModalFree = require './computeplansmodalfree'


module.exports = class ComputeHelpers


  @destroyExistingMachines = (callback = kd.noop(), waitForCompleteDeletion = no)->

    { computeController } = kd.singletons

    computeController.fetchMachines (err, machines)->

      return callback err  if err?

      destroyPromises = []

      machines.forEach (machine) ->
        if waitForCompleteDeletion
          destroyPromise = new Promise (resolve) ->
            computeController.on "destroy-#{machine._id}", (event) ->
              resolve()  if event.status is Machine.State.Terminated
        actionPromise = computeController.destroy machine, yes
        destroyPromise ?= actionPromise
        destroyPromises.push destroyPromise

      result = Promise
        .all destroyPromises
        .then ->
          callback null
      result.timeout globals.COMPUTECONTROLLER_TIMEOUT  unless waitForCompleteDeletion
      return result


  @handleNewMachineRequest = (options = {}, callback = kd.noop)->

    cc = kd.singletons.computeController
    redirectAfterCreation = options.redirectAfterCreation ? yes

    return  if cc._inprogress

    if options.provider is 'managed'
      return callback new AddManagedVMModal

    cc._inprogress = yes

    cc.fetchPlanCombo "koding", (err, info) ->

      if showError err
        return cc._inprogress = no

      { plan, plans, usage } = info
      { snapshotId, region } = options

      limits  = plans[plan]
      options = { plan, limits, usage, snapshotId, region }

      if limits.total > 1

        new ComputePlansModalPaid options
        cc._inprogress = no

        callback()
        return

      query        =
        provider   : 'koding'
        credential : nick()

      cc.queryMachines query, (err, machines) ->

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

              kd.singletons.router.handleRoute "/IDE/#{machine.slug}"  if redirectAfterCreation


  @reviveProvisioner = (machine, callback)->

    provisioner = machine.provisioners?.first
    return callback null  unless provisioner

    remote = require('app/remote').getInstance()
    remote.api.JProvisioner.one slug: provisioner, callback


  @runInitScript = (machine, inTerminal = yes)->

    { status: { state } } = machine
    unless state is Machine.State.Running
      return new KDNotificationView
        title : "Machine is not running."

    envVariables = ""
    for key, value of machine.stack?.config or {}
      envVariables += """export #{key}="#{value}"\n"""

    @reviveProvisioner machine, (err, provisioner)=>

      if err
        return new KDNotificationView
          title : "Failed to fetch build script."
      else if not provisioner
        return new KDNotificationView
          title : "Provision script is not set."

      {content: {script}} = provisioner

      htmlencode = require 'htmlencode'
      script = htmlencode.htmlDecode script

      path = provisioner.slug.replace "/", "-"
      path = "/tmp/init-#{path}"
      machine.fs.create { path }, (err, file)=>

        if err or not file
          return new KDNotificationView
            title : "Failed to upload build script."

        script  = "#{envVariables}\n\n#{script}\n"
        script += "\necho $?|kdevent;rm -f #{path};exit"

        file.save script, (err)->
          return if showError err

          command = "bash #{path};exit"

          if not inTerminal

            new KDNotificationView
              title: "Init script running in background..."

            machine.getBaseKite().exec { command }
              .then (res)->

                new KDNotificationView
                  title: "Init script executed"

                kd.info  "Init script executed : ", res.stdout  if res.stdout
                kd.error "Init script failed   : ", res.stderr  if res.stderr

              .catch (err)->

                new KDNotificationView
                  title: "Init script executed successfully"
                kd.error "Init script failed:", err

            return

          TerminalModal = require '../terminal/terminalmodal'

          modal = new TerminalModal {
            title         : "Running init script for #{machine.getName()}..."
            command       : command
            readOnly      : yes
            destroyOnExit : no
            machine
          }

          modal.once "terminal.event", (data)->

            if data is "0"
              title   = "Installed successfully!"
              content = "You can now safely close this Terminal."
            else
              title   = "An error occurred."
              content = """Something went wrong while running build script.
                           Please try again."""

            new KDNotificationView {
              title, content
              type          : "tray"
              duration      : 0
              container     : modal
              closeManually : no
            }


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
