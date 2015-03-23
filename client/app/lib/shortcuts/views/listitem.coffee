kd               = require 'kd'
JView            = require 'app/jview'
KodingSwitch     = require 'app/commonviews/kodingswitch'
BindingView      = require './listitembinding'

module.exports =

class ShortcutsListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options={}, model) ->

    options.tagName or= 'div'
    options.cssClass or= 'row'

    @enabledView = new KodingSwitch
    @bindingView = new BindingView {}, model

    super options, model

    @bindingView.input.on 'blur', @bound 'hideInput'
    @bindingView.on 'KeybindingUpdated', => @setClass 'updated'


  click: -> @showInput()  unless @active


  hideInput: ->

    @bindingView.hideEditMode()
    @active = no


  showInput: ->

    @bindingView.showEditMode()
    @active = yes


  pistachio: ->
    """
    <div class=col>{{ #(description)}}</div>
    <div class=col>{{> @bindingView }}</div>
    <div class=col>{{> @enabledView }}</div>
    """
