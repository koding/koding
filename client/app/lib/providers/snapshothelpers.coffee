kd                          = require 'kd'
remote                      = require('app/remote').getInstance()

EnvironmentsProgressModal   = require './environmentsprogressmodal'
{ handleNewMachineRequest } = require './computehelpers'


###*
 * Fetch the most recent Snapshot created.
 *
 * @param {String} machineId - The JMachine ID
 * @param {Function(err:Error, snapshot:JSnapshot)} callback
###
fetchNewestSnapshot = (machineId, callback = kd.noop) ->

  {JSnapshot} = remote.api
  JSnapshot.some { machineId }, { sort: { createdAt: -1 }, limit: 1 },
    (err, snapshots) =>
      return callback err  if err
      unless snapshots
        return callback new Error 'Cannot find most recent snapshot'
      [snapshot] = snapshots
      callback null, snapshot


###*
 * Create a new vm from the given snapshotId, going directly to reinit
 * for hobbyist's, and showing the new machine modal for all other
 * users.
 *
 * @param {Machine} machine - The machine to reinit a snapshot onto, in
 *  the event that it's needed (hobbyists).
 * @param {String} snapshotId - The snapshotId to create the machine from
 * @param {Function()} callback - Called once the process has begin, *not*
 *  when the process is entirely done. (Eg, after plan confirmations have
 *  taken place, etc).
###
newVmFromSnapshot = (machine, snapshotId, callback = kd.noop) ->

  computeController = kd.getSingleton 'computeController'
  paymentController = kd.getSingleton 'paymentController'

  paymentController.subscriptions (err, subscription) =>
    return kd.error  if err
    { planTitle } = subscription

    # If the plan is hobbyist, we want to reinit with the
    # snapshotId, not create a new machine.
    if planTitle is 'hobbyist'
      computeController.reinit machine, snapshotId
      callback()
    else
      handleNewMachineRequest
        provider   : 'koding'
        snapshotId : snapshotId
        callback


###*
 * Show the snapshotting modal (EnvironmentsProgressModal)
 *
 * @param {KDView} container - A view that the Modal will overlay (usually
 *  the IDE)
 * @param {actionLabel} actionLabel - the action label used in the modal.
 * @returns {EnvironmentsProgressModal}
###
showSnapshottingModal = (machine, container) ->

  modal = new EnvironmentsProgressModal
    container          : container
    actionLabel        : 'Creating a snapshot'
    customErrorMessage : """
      <p>Snapshot creation failed.</p>
      <span>
        Please <span class="close">close this message</span> or
        <span class="contact-support">contact support</span> for
        further assistance.
      </span>
    """
    machine
  modal.show()


module.exports = {
  fetchNewestSnapshot
  newVmFromSnapshot
  showSnapshottingModal
}


