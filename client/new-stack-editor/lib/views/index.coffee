kd = require 'kd'
bowser = require 'bowser'
BaseView = require './baseview'
FlexSplit = require './flexsplit'


module.exports = class StackEditor extends kd.View

  constructor: (options = {}, data) ->

    super options, data

  viewAppended: ->

    toolbar = new kd.View
      cssClass: 'toolbar'

    editor = new BaseView
      cssClass: 'editor'

    logs = new BaseView
      cssClass: 'logs'
      title: 'Logs'

    leftColumn = new FlexSplit
      views    : [editor, logs]
      sizes    : [90, 10]


    variables = new BaseView
      cssClass: 'variables'
      title: 'Custom Variables'

    readme = new BaseView
      cssClass: 'readme'
      title: 'Readme'

    rightColumn = new FlexSplit
      sizes    : [50, 50]
      views    : [variables, readme]

    contentView = new FlexSplit
      cssClass : 'content'
      views    : [leftColumn, rightColumn]
      sizes    : [55, 45]
      type     : FlexSplit.VERTICAL

    contentView.setClass 'safari-fix'  if bowser.safari

    statusbar = new kd.View
      cssClass: 'statusbar'

    mainsplit   = new FlexSplit
      views     : [contentView, statusbar]
      resizable : no

    @addSubView mainView = new FlexSplit
      cssClass  : 'mainview'
      views     : [toolbar, mainsplit]
      resizable : no
