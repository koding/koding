kd              = require 'kd'
KDAutoComplete  = kd.AutoComplete


module.exports = class PrivateMessageAutoComplete extends KDAutoComplete


  constructor: (options = {}, data) ->

    super options, data

    @$input().on 'click', @bound 'setFocus'
