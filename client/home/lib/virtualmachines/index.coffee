kd                                   = require 'kd'
Promise                              = require 'bluebird'
HomeVirtualMachinesVirtualMachines   = require './homevirtualmachinesvirtualmachines'
HomeVirtualMachinesConnectedMachines = require './homevirtualmachinesconnectedmachines'
HomeVirtualMachinesSharedMachines    = require './homevirtualmachinessharedmachines'


SECTIONS =
  'Virtual Machines'   : HomeVirtualMachinesVirtualMachines
  'Connected Machines' : HomeVirtualMachinesConnectedMachines
  'Shared Machines'    : HomeVirtualMachinesSharedMachines

header = (title) ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    partial  : title


section = (name) ->
  new (SECTIONS[name] or kd.View)
    tagName  : 'section'
    cssClass : "HomeAppView--section #{kd.utils.slugify name}"


module.exports = class HomeVirtualMachines extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    kd.singletons.mainController.ready =>

      @wrapper.addSubView header 'Virtual Machines'
      @wrapper.addSubView section 'Virtual Machines'

      @wrapper.addSubView header 'Connected Machines'
      @wrapper.addSubView section 'Connected Machines'

      @wrapper.addSubView header 'Shared Machines'
      @wrapper.addSubView section 'Shared Machines'


