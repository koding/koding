class TopicSearchModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass      = KD.utils.curry 'topic-search', options.cssClass
    options.title       or= 'Browse Topics on Koding'
    options.placeholder or= 'Search all topics...'
    options.noItemFound or= 'You don\'t follow any topics yet. You can search for some topics above e.g HTML, CSS, golang.'
    options.endpoints    ?=
      fetch               : KD.singletons.socialapi.channel.list
      search              : KD.singletons.socialapi.channel.searchTopics

    super options, data


  viewAppended: ->

    super

    @listController.getListView().on 'ItemShouldBeSelected', (item, event) =>

      KD.utils.stopDOMEvent event

      KD.singletons.router.handleRoute item.getOption 'route'
      @destroy()

    @addSubView new KDCustomHTMLView
      cssClass   : 'tag-description'
      partial    : "
        You can also create a new topic by making it a part of a new post. <br>
        <em>eg: I love <strong>#programming</strong></em>
      "


