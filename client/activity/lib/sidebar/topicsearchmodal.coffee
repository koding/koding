kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
SidebarSearchModal = require 'app/activity/sidebar/sidebarsearchmodal'


module.exports = class TopicSearchModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass          = kd.utils.curry 'topic-search sidebar-white-modal', options.cssClass
    options.title           or= 'Browse Topics on Koding'
    options.placeholder     or= 'Search all topics...'
    options.noItemText      or= 'You don\'t follow any topics yet. You can search for some topics above e.g HTML, CSS, golang.'
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

    @addSubView new KDCustomHTMLView
      cssClass   : 'tag-description'
      partial    : "
        You can also create a new topic by making it a part of a new post. <br>
        <em>eg: I love <strong>#programming</strong></em>
      "




