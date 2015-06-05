DeleteAccountView = require './deleteaccountview'
LeaveGroupModal   = require './leavegroupmodal'


module.exports = class LeaveGroupView extends DeleteAccountView

  constructor: (options, data) ->

    options.headerTitle = 'Leave from your group'
    options.buttonTitle = 'Leave Group'
    options.modalClass  =  LeaveGroupModal

    super options, data
