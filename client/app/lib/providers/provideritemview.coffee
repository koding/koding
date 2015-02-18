kd = require 'kd'
KDListItemView = kd.ListItemView
ProviderBaseView = require './providerbaseview'
JView = require 'app/jview'

module.exports = class ProviderItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = "#{data.name}"
    super options, data

  pistachio:-> ""
