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
      bind       : "mouseenter"
      mouseenter : do ->
        times = 0
        ->
          switch times
            when 0 then @setTitle "Are you sure?!"
            when 1 then @setTitle "OK, go ahead :)"
            else
              kd.utils.wait 5000, =>
                times = 0
                @setTitle "Delete Account"
              return
          @toggleClass 'escape'
          times++
      callback   : -> new DeleteModalView

  pistachio:->
    """
    <h4 class="kdview kdheaderview"><span>Delete your account</span></h4>
    {{> @button}}
    """




