kd = require 'kd'
Events = require '../events'
BaseView = require './baseview'
FlexSplit = require './flexsplit'


module.exports = class SideView extends BaseView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'side-view hidden', options.cssClass
    options.pinnable = yes
    options.closable = yes

    super options, data

    @on FlexSplit.EVENT_EXPAND,   @lazyBound 'setClass',   'expanded'
    @on FlexSplit.EVENT_COLLAPSE, @lazyBound 'unsetClass', 'expanded'
    @on FlexSplit.EVENT_HIDE,     @bound 'hide'
