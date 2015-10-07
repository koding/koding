kd                 = require 'kd'
KDCustomHTMLView   = kd.CustomHTMLView
SidebarMachineList = require './sidebarmachinelist'
curryIn            = require 'app/util/curryIn'

module.exports = class SidebarOwnMachinesList extends SidebarMachineList

  constructor: (options = {}, data) ->

    options.title      ?= 'Your VMs'
    options.hasPlusIcon = yes

    curryIn options, cssClass: 'my-machines'

    super options, data


  viewAppended: ->

    super

    @header.addSubView @unreadCount = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'count hidden'
      partial  : '1'
