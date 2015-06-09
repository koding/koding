DeleteAccountView = require './deleteaccountview'
LeaveGroupModal   = require './leavegroupmodal'


module.exports = class LeaveGroupView extends DeleteAccountView

  constructor: (options, data) ->

    options.headerTitle = 'Leave from your team'
    options.buttonTitle = 'Leave team'
    options.modalClass  =  LeaveGroupModal

    super options, data
