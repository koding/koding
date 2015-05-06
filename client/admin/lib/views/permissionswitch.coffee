KodingSwitch = require 'app/commonviews/kodingswitch'
$ = require 'jquery'


module.exports = class PermissionSwitch extends KodingSwitch

  constructor: (options={}, data)->
    super options, data

  setDomElement:(cssClass)->
    @domElement = $ "<div class='switcher'> <div class='kdinput koding-on-off off #{cssClass}'><a href='#' class='knob' title='turn on'></a></div></div>"

  setOff :->
    kdSwitch = @domElement.children(".koding-on-off")

    kdSwitch.removeClass "on"
    kdSwitch.addClass "off"

    super

  setOn :->
    kdSwitch = @domElement.children(".koding-on-off")

    kdSwitch.removeClass "off"
    kdSwitch.addClass "on"

    super


