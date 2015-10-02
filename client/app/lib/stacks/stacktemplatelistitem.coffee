kd                        = require 'kd'
KDButtonViewWithMenu      = kd.ButtonViewWithMenu
ActivityItemMenuItem      = require 'activity/views/activityitemmenuitem'
BaseStackTemplateListItem = require './basestacktemplatelistitem'


module.exports = class StackTemplateListItem extends BaseStackTemplateListItem

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "stacktemplate-item clearfix", options.cssClass
    super options, data

    { inuse } = @getData()

    @inuseView = new kd.CustomHTMLView
      cssClass : 'inuse-tag'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This group currently using this template'

    @inuseView.hide()  unless inuse


  updateStackTemplate: ->
    @getDelegate().emit 'ItemSelected', @getData()


  pistachio: ->
    """
    <div class='stacktemplate-info clearfix'>
      {div.title{#(title)}} {{> @inuseView}}
    </div>
    <div class='buttons'>{{> @settings}}</div>
    """
