kd              = require 'kd'
getIdeByMachine = require '../util/getIdeByMachine'
IDEAppController = require '../../../ide/lib'


###*
 * fetch an IDEAppController based on the machine. If the IDE is not
 * already loaded, the route is directed to the IDE to cause it to load.
 * Once everything is ready, and the IDE is tested to prove that to be
 * owned by the requested Machine, callback.
 *
 * @param {Machine} machine - The machine of the IDE you want.
 * @param {Function(err:Error, ide:IDEAppController)} callback
###
module.exports = fetchIdeByMachine = (machine, callback) ->

  # First, try to get the already loaded IDE. If it exists, we
  # don't need to redirect the user.
  ideController = getIdeByMachine machine
  return callback null, ideController  if ideController

  router     = kd.getSingleton 'router'
  appManager = kd.getSingleton 'appManager'
  machineId  = machine._id

  # The IDE is not loaded, so we need to load it. Currently,
  # it seems that loading it via a route is the most reliable method.
  # To do this, we're subscribing to appManager to listen for when the
  # app is created.
  #
  # Note that it might be possible to have a sort of race condition here,
  # where a user changes apps and AppCreated is emitted right when this
  # subscribes. Ie, the event emitted is not the event we triggered.
  #
  # As a fallback, we may want to subscribe to this event, and only listen
  # for a maximum of X times, until the proper controller is found.
  appManager.once 'AppCreated', (controller) ->

    unless controller instanceof IDEAppController
      return callback new Error 'App being shown is not IDEAppController'

    # When the app is first created, it has no mounted machine. We
    # need the mounted machine, to compare with the `machine` given to
    # fetchIdeByMachine.
    #
    # TODO: Find a way to check if the controller is already, ready.
    # Otherwise we risk waiting for a ready event, on something that's
    # already ready.
    #
    # TODO: A timeout is also needed. If for whatever reason `ready`
    # will not be fired, the timeout will ensure that the callback
    # doesn't hang in nomans land.
    controller.once 'ready', ->
      unless controller.mountedMachine?._id is machineId
        return callback new Error 'IDEApp being shown does not belong to
          requested machine'

      return callback null, controller

  # And now that we have subscribed to the event, fire the route.
  router.handleRoute "/IDE/#{machine.slug}"



