kd                = require 'kd'
JView             = require 'app/jview'
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class StackTemplateListItemTitle extends KDCustomHTMLView

  JView.mixin @prototype

  pistachio: ->

    """
    {div.title{#(title)}}
    """