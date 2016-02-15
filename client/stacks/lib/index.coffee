kd                         = require 'kd'
AdminAppController         = require 'admin/index'
StackCatalogModalView      = require './views/customviews/stackcatalogmodalview'

YourStacksView             = require 'app/environment/yourstacksview'
MyStackTemplatesView       = require './views/stacks/my/mystacktemplatesview'
GroupStackTemplatesView    = require './views/stacks/group/groupstacktemplatesview'


require('./routehandler')()

module.exports = class StacksAppController extends AdminAppController

  @options     =
    name       : 'Stacks'
    background : yes

  NAV_ITEMS    =
    teams      :
      title    : 'Stack Catalog'
      items    : [
        { slug : 'My-Stacks',               title : 'My Stacks',              viewClass : YourStacksView }
        { slug : 'My-Stack-Templates',      title : 'My Stack Templates',     viewClass : MyStackTemplatesView }
        { slug : 'Group-Stack-Templates',   title : 'Group Stack Templates',  viewClass : GroupStackTemplatesView }
      ]


  constructor: (options = {}, data) ->

    data          ?= kd.singletons.groupsController.getCurrentGroup()
    options.view   = new StackCatalogModalView
      title        : 'Stack Catalog'
      cssClass     : 'AppModal AppModal--admin StackCatalogModal team-settings'
      width        : 1000
      height       : '90%'
      overlay      : yes
      overlayClick : no
      tabData      : NAV_ITEMS
    , data

    super options, data


  checkRoute: (route) -> /^\/Stacks.*/.test route


  toggleFullscreen: ->

    if @isFullscreen then @exitFullscreen() else @fullscreen()


  fullscreen: ->

    @getOptions().view.setClass 'fullscreen'
    @isFullscreen = yes


  exitFullscreen: ->

    { view } = @getOptions()

    view.unsetClass 'fullscreen'
    kd.utils.wait 733, -> view._windowDidResize()
    @isFullscreen = no
