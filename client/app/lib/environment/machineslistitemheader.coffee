kd           = require 'kd'
JView        = require 'app/jview'
isKoding     = require 'app/util/isKoding'


module.exports = class MachinesListItemHeader extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'machines-item header', options.cssClass

    super options, data


  pistachio: ->
    """
      <div>NAME</div>
      <div>PROVIDER</div>
      <div>TYPE</div>
      <div>OS</div>
      <div class='input-title'>ALWAYS ON</div>
      #{unless isKoding() then '<div class="input-title">SHOW IN SIDEBAR</div>' else ''}
    """
