kd = require 'kd'


###*
 * get an IDEAppController based on the machine.
 *
 * @param {Machine} machine - The machine of the IDE you want.
 * @param {Function(err:Error, ide:IDEAppController)} callback
###
module.exports = getIdeByMachine = (machine) ->
  machineId          = machine._id
  { appControllers } = kd.getSingleton 'appManager'
  ideInstances       = appControllers.IDE?.instances ? []
  for ideController in ideInstances
    if ideController.mountedMachine._id is machineId
      return ideController
  return


