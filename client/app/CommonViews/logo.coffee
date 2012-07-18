class LogoView extends KDView
  constructor:(options,data)->
    options = $.extend
      bind      : "click"
      cssClass  : "logo-holder"
    ,options
    super options,data
    @setHeight "auto"
    @setPartial @partial()

  partial:()->
    $ "<span id='koding-logo'>Koding</span>"
  
  click:(event)->
    if $(event.target).is "#koding-logo"
      appManager.openApplication "Activity"
  
  dblClick:(event)->
    if $(event.target).is "#koding-logo"
      appManager.openApplication "Home"
    