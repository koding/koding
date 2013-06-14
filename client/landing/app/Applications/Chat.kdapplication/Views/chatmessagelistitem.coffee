class ChatMessageListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curryCssClass "message", data.cssClass
    options.tagName  = "li"
    data.message     = Encoder.XSSEncode data.message
    super options, data

    @timeWidget = new KDTimeAgoView
      cssClass : 'time-widget'
    , new Date

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
       {{>@timeWidget}}
       <strong>{{ #(sender) }}</strong><hr/>
       {{ #(message) }}
    """

  addMessage:(message)->
    @data.message += "<br/>#{Encoder.XSSEncode message}"
    @render()
