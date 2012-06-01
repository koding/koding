class WidgetButton extends KDButtonViewWithMenu
  setTitle:(title)->
    @$('button').append("<span class='title'>#{title}</span>")

  click:(event)->
    @contextMenu event
    return no

  iconChanger:(title)->
    @$('button span.icon').destroy()

  performShowUpdateWidget: ->
    @$('button span.icon').attr "class","icon update"
    @$('button span.title').text "Status Update"
    @getDelegate().handleEvent type : "changeAddActivityWidget", tabName : "update"

  performShowQuestionWidget: ->
    return @showDisabledForBetaNotification() # disabledForBeta
    @$('button span.icon').attr "class","icon question"
    @$('button span.title').text "Ask a Question"
    @getDelegate().handleEvent type : "changeAddActivityWidget", tabName : "question"

  performShowCodesnipWidget: ->
    #return @showDisabledForBetaNotification() # disabledForBeta
    @$('button span.icon').attr "class","icon codesnip"
    @$('button span.title').text "Code Snip"
    @getDelegate().handleEvent type : "changeAddActivityWidget", tabName : "codesnip"

  performShowDiscussionWidget: ->
    return @showDisabledForBetaNotification() # disabledForBeta
    @$('button span.icon').attr "class","icon discussion"
    @$('button span.title').text "Start a Discussion"
    @getDelegate().handleEvent type : "changeAddActivityWidget", tabName : "discussion"

  performShowLinkWidget: ->
    return @showDisabledForBetaNotification() # disabledForBeta
    @$('button span.icon').attr "class","icon link"
    @$('button span.title').text "Link"
    @getDelegate().handleEvent type : "changeAddActivityWidget", tabName : "link"

  performShowTutorialWidget: ->
    return @showDisabledForBetaNotification() # disabledForBeta
    @$('button span.icon').attr "class","icon tutorial"
    @$('button span.title').text "Tutorial"
    @getDelegate().handleEvent type : "changeAddActivityWidget", tabName : "tutorial"
  
  showDisabledForBetaNotification:->
    new KDNotificationView
      title    : "This feature is currently disabled!"
      duration : 1500

class WidgetButtonForStatusSelection_ContextMenu extends KDContextMenuTreeView

class WidgetButtonForStatusSelection extends KDView
  constructor:->
    super

  viewAppended:()->
    @setClass "button-wrapper"

    widgetButton = new WidgetButton
      title        : "Status Update"
      style        : "activity-status-context"
      icon         : yes
      iconClass    : "update"
      delegate     : @
      contextClass : WidgetButtonForStatusSelection_ContextMenu
      menu         : [
        items      : [
          {
            title     : "Status Update"
            type      : "default update hoverhook"
            function  : "showUpdateWidget"
          }
          {
            title     : "Ask a Question"
            type      : "default question hoverhook disabledForBeta"
            function  : "showQuestionWidget"
          }
          {
            title     : "Code Snip"
            type      : "default codesnip hoverhook"
            function  : "showCodesnipWidget"
          }
          {
            title     : "Start a Discussion"
            type      : "default discussion hoverhook disabledForBeta"
            function  : "showDiscussionWidget"
          }
          {
            title     : "Link"
            type      : "default link hoverhook disabledForBeta"
            function  : "showLinkWidget"
          }
          {
            title     : "Tutorial"
            type      : "default tutorial hoverhook disabledForBeta"
            function  : "showTutorialWidget"
          }
        ]
      ]

      callback  : ()=>
    
    @addSubView widgetButton

    @listenTo
      KDEventTypes        : 'ActivityUpdateWidgetShouldReset'
      listenedToInstance  : @getDelegate()
      callback            : ->
        widgetButton.performShowUpdateWidget()
      