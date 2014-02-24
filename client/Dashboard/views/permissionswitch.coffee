class PermissionSwitch extends KodingSwitch

  setDomElement:(cssClass)->
    @domElement = $ "<div class='switcher'> <div class='kdinput koding-on-off off #{cssClass}'><a href='#' class='knob' title='turn on'></a></div></div>"
