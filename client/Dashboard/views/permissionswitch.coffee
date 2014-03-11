class PermissionSwitch extends KodingSwitch

  constructor: (options={}, data)->
    super options, data

  setDomElement:(cssClass)->
    @domElement = $ "<div class='switcher' style='width: #{@options.widthForRows}px'> <div class='kdinput koding-on-off off #{cssClass}'><a href='#' class='knob' title='turn on'></a></div></div>"
