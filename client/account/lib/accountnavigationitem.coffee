kd = require 'kd'
KDListItemView = kd.ListItemView
module.exports = class AccountNavigationItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName    = 'a'
    options.route      = "/Account/#{data.slug}"
    options.attributes = href : options.route
    options.cssClass   = "AppModal-navItem #{data.slug.toLowerCase()}"

    super options, data

    @name = @getData().title

  partial:(data)-> data.title


  click: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute @getOption 'route'

    super event
