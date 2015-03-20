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

  pistachio: ->
    """
    <div class=col>{span{#(description)}}</div>
    <div class=col>{span{> @bindingView }}</div>
    <div class=col>{span{> @enabledView }}</div>
    """
