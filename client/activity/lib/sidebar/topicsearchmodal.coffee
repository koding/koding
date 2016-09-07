kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
SidebarSearchModal = require 'app/activity/sidebar/sidebarsearchmodal'


module.exports = class TopicSearchModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass          = kd.utils.curry 'topic-search sidebar-white-modal', options.cssClass
    options.title           or= 'Browse Topics on Koding'
    options.placeholder     or= 'Search all topics...'
    options.noItemText      or= 'There are no topics here. You can create a new topic by making it a part of a new post. <em>eg: I love <strong>#programming</strong></em>'
    options.emptySearchText or= 'Sorry, your search did not have any results'
    options.endpoints        ?=
      fetch                   : kd.singletons.socialapi.channel.list
      search                  : kd.singletons.socialapi.channel.searchTopics

    super options, data


  viewAppended: ->

    super

    @listController.getListView().on 'ItemShouldBeSelected', (item, event) =>

      kd.utils.stopDOMEvent event

      kd.singletons.router.handleRoute item.getOption 'route'
      @destroy()
