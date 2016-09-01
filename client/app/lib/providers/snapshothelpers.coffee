kd                          = require 'kd'
remote                      = require 'app/remote'

EnvironmentsProgressModal   = require './environmentsprogressmodal'
{ handleNewMachineRequest } = require './computehelpers'


###*
 * Fetch the most recent Snapshot created.
 *
 * @param {String} machineId - The JMachine ID
 * @param {Function(err:Error, snapshot:JSnapshot)} callback
###
fetchNewestSnapshot = (machineId, callback = kd.noop) ->

  { JSnapshot } = remote.api
  JSnapshot.some { machineId }, { sort: { createdAt: -1 }, limit: 1 },
    (err, snapshots) ->
      return callback err  if err
      unless snapshots
        return callback new Error 'Cannot find most recent snapshot'
      [snapshot] = snapshots
      callback null, snapshot


###*
 * Based on the given list of labels, return a unique label. If the
 * label is not unique, it is returned in the format of "label index".
 *
 * @params {String} label - The source label.
 * @params {Array.<String>} labels - The labels to avoid.
 * @returns {String} label - A formatted label, not in the labels list.
###
getUniqueLabel = (label, labels = []) ->

  # If label is already unique, return it.
  return label  if labels.indexOf(label) is -1

  count = 1
  while labels.indexOf("#{label} #{count}") isnt -1
    count++
  return "#{label} #{count}"



###*
 * Create a new vm from the given snapshotId, going directly to reinit
 * for hobbyist's, and showing the new machine modal for all other
 * users.
 *
 * @param {Object} snapshot - An object, containing required `region` and
 *  `snapshotId` fields.
 * @param {String} snapshot.region - The region that the vm will be
 *  created in.
 * @param {String} snapshot.snapshotId - The snapshotId to create the
 *  machine from.
 * @param {Machine} machine - The machine to reinit a snapshot onto, in
 *  the event that it's needed (hobbyists).
 * @param {Function()} callback - Called once the process has begin, *not*
 *  when the process is entirely done. (Eg, after plan confirmations have
 *  taken place, etc).
###
newVmFromSnapshot = (snapshot, machine, callback = kd.noop) ->

  { region, snapshotId } = snapshot

  unless region
    return kd.error 'newVmFromSnapshot: snapshot.region is required'
  unless snapshotId
    return kd.error 'newVmFromSnapshot: snapshot.snapshotId is required'

  computeController = kd.getSingleton 'computeController'
  paymentController = kd.getSingleton 'paymentController'

  paymentController.subscriptions (err, subscription) ->
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
        region     : region
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
    customErrorMessage : '''
      <p>Snapshot creation failed.</p>
      <span>
        Please <span class="close">close this message</span> or
        <span class="contact-support">contact support</span> for
        further assistance.
      </span>
    '''
    machine
  modal.show()


module.exports = {
  fetchNewestSnapshot
  getUniqueLabel
  newVmFromSnapshot
  showSnapshottingModal
}
