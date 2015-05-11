kd = require 'kd'
KDButtonView = kd.ButtonView
DeleteModalView = require '../deletemodalview'
JView = require 'app/jview'


module.exports = class DeleteAccountView extends JView

  constructor:(options, data)->

    options.cssClass = 'delete-account-view'

    super options, data

    @button = new KDButtonView
      title      : "Delete Account"
      cssClass   : "delete-account solid red fr small"
      callback   : ->
        @disable()
        deleteModalView = new DeleteModalView
        deleteModalView.on 'KDModalViewDestroyed', @bound 'enable'

  pistachio:->
    """
    <h4 class="kdview kdheaderview"><span>Delete your account</span></h4>
    {{> @button}}
    """




