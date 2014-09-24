class TopicSearchModal extends YourTopicsModal

  constructor: (options = {}, data) ->

    options.title    or= 'Browse Topics on Koding'
    options.cssClass or= 'your-topics'
    options.endpoints ?=
      fetch            : KD.singletons.socialapi.channel.list
      search           : KD.singletons.socialapi.channel.searchTopics

    super options, data


  viewAppended: ->

    super

    @addSubView new KDCustomHTMLView
      cssClass   : 'tag-description'
      partial    : "
        You can also create a new topic by making it a part of <br>
        a new post. <em>eg: I love #koding</em>
      "