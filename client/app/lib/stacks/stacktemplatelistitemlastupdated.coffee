kd                = require 'kd'
timeago           = require 'timeago'
JView             = require 'app/jview'
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class StackTemplateListItemLastUpdated extends KDCustomHTMLView

  JView.mixin @prototype

  pistachio: ->

    { meta } = @getData()

    """
    <cite>Last updated #{timeago meta.modifiedAt}</cite>
    """
