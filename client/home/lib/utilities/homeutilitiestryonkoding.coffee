kd             = require 'kd'
JView          = require 'app/jview'
KodingSwitch   = require 'app/commonviews/kodingswitch'


module.exports = class HomeUtilitiesTryOnKoding extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @switch  = new KodingSwitch
      cssClass: 'small'
      callback: (state) =>
        if state
          @emit 'TryOnKodingActivated'
          console.log 'TryOnKodingActivated'
        else
          @emit 'TryOnKodingDeactivated'
          console.log 'TryOnKodingDeactivated'



  pistachio: ->
    """
    <p>
    <strong>Enable “Try On Koding” Button</strong>
    Visiting users will have access to all team stack scripts
    {{> @switch}}
    </p>
    """
