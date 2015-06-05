kd              = require 'kd'
JView           = require 'app/jview'
KDButtonView    = kd.ButtonView
DeleteModalView = require '../deletemodalview'


module.exports = class DeleteAccountView extends JView

  constructor: (options, data) ->

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
    return """
      <h4 class="kdview kdheaderview"><span>#{@getOptions().headerTitle}</span></h4>
      {{> @button}}
    """
