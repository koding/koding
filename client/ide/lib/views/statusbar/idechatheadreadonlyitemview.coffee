kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KodingSwitch = require 'app/commonviews/kodingswitch'


module.exports = class IDEChatHeadReadOnlyItemView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.partial ?= 'Read only'

    super options, data

    { delegate, permission } = options

    @addSubView new KodingSwitch
      cssClass     : 'tiny'
      defaultValue : if permission is 'read' then on else off
      callback     : delegate.bound 'setReadOnlyState'
