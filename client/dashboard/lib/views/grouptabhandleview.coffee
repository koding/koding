kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDTabHandleView = kd.TabHandleView
JView = require 'app/jview'


module.exports = class GroupTabHandleView extends KDTabHandleView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.cssClass = kd.utils.curry 'grouptabhandle', options.cssClass

    super options, data

    @isDirty      = no
    @currentCount = 0

  viewAppended:->
    @newCount = new KDCustomHTMLView
      tagName : 'span'
      cssClass: 'new'
    @newCount.hide()

    @pendingCount = new KDCustomHTMLView
      tagName : 'span'
      cssClass: 'pending'
    @pendingCount.hide()

    JView::viewAppended.call this

  updatePendingCount:(pendingCount)->
    if pendingCount
      @setClass 'has-pending'
      @pendingCount.updatePartial pendingCount
      @pendingCount.show()
    else
      @unsetClass 'has-pending'
      @pendingCount.updatePartial ''
      @pendingCount.hide()

  markDirty:(@isDirty=yes)->
    if @isDirty
      @setClass 'dirty'  unless @currentCount++
      @newCount.updatePartial @currentCount
      @newCount.show()
      @pendingCount.hide()
    else
      @currentCount = 0
      @unsetClass 'dirty'
      @newCount.updatePartial ''
      @newCount.hide()
      @pendingCount.show()  if @pendingCount.hasClass 'has-pending'

  pistachio:->
    "#{@getOptions().title} {{> @newCount}}{{> @pendingCount}}"


