class PermissionSwitch extends KodingSwitch

  constructor: (options={}, data)->
    super options, data

  setDomElement:(cssClass)->
    # TODO: Burak get width from options and set the style HERE!!!
    @domElement = $ "<div class='switcher'> <div class='kdinput koding-on-off off #{cssClass}'><a href='#' class='knob' title='turn on'></a></div></div>"
