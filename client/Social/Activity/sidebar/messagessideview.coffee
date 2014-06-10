class MessagesSideView extends ActivitySideView

  constructor: (options = {}, data) ->

    super options, data


    @header?.destroy()

    @header = new KDCustomHTMLView
      tagName : 'h3'
      partial : @getOption 'title'

    @newLink = new CustomLinkView
      title : 'NEW'
      href  : KD.utils.groupifyLink '/Activity/Message/New'

    @header.addSubView @newLink


  pistachio: ->
    """
    {{> @header}}
    {{> @listView}}
    """
