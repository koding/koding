kd      = require 'kd'
JView   = require 'app/jview'


module.exports = class LogsItemView extends kd.ListItemView

  JView.mixin @prototype

  messageParser = /^(\[(\w+)\:(\w+)\]?)(.*)/

  constructor: (options = {}, data) ->

    [ raw, tag, scope, group, message ] = messageParser.exec data.message

    data.message     = message
    options.type   or= 'log'
    options.cssClass = scope

    super options, data


  pistachio: ->

    '{{#(message)}}{span.time{#(createdAt)}}'
