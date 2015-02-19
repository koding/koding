isChannelCollaborative = require '../../util/isChannelCollaborative'
kd = require 'kd'
SidebarMessageItem = require './sidebarmessageitem'
SidebarSearchModal = require './sidebarsearchmodal'


module.exports = class ChatSearchModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass      = kd.utils.curry 'chat-search sidebar-white-modal', options.cssClass
    options.title       or= 'Other Messages:'
    options.placeholder or= 'Search'
    options.noItemText  or= 'You don\'t have any other chats.'
    options.itemClass   or= SidebarMessageItem
    options.endpoints    ?=
      fetch               : kd.singletons.socialapi.message.fetchPrivateMessages
      search              : kd.singletons.socialapi.message.search

    super options, data


  populate: (items, options) ->

    nonCollaborativeItems = items
      .filter (channel) -> not isChannelCollaborative channel

    super nonCollaborativeItems, options
