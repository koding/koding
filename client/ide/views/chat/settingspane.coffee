class IDE.ChatSettingsPane extends KDTabPaneView

  JView.mixin @constructor

  constructor: (options = {}, data)->

    options.cssClass = 'chat-settings'

    super options, data

    channel = @getData()

    @title = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'workspace-name'
      partial  : 'My Workspace'

    @chevron = new KDCustomHTMLView
      tagName  : 'figure'
      cssClass : 'pm-title-chevron'

    @link = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'session-link'
      partial    : link = KD.utils.groupifyLink "/IDE/#{channel.id}", yes
      attributes :
        href     : '#share'

    @startSession = new KDButtonView
      title    : 'START SESSION'
      cssClass : 'solid green'
      callback : @bound 'initiateSession'

    @endSession = new KDButtonView
      title    : 'END SESSION'
      disabled : yes
      cssClass : 'solid red'
      callback : @bound 'stopSession'

    @defaultSetting = new KDSelectBox
      defaultValue  : 'edit'
      selectOptions : [
        { title : 'CAN READ', value : 'read'}
        { title : 'CAN EDIT', value : 'edit'}
      ]

    @everyone = new KDCustomHTMLView
      tagName  : 'ul'
      cssClass : 'settings everyone'


  initiateSession: ->

    @startSession.disable()
    {appManager} = KD.singletons

    appManager.tell 'IDE', 'startCollaborationSession', (err, channel) =>

      return @startSession.enable()  if err

      @endSession.enable()
      @startSession.disable()


  stopSession: ->

    @endSession.disable()
    {appManager} = KD.singletons

    appManager.tell 'IDE', 'stopCollaborationSession', (err, channel) =>

      return @endSession.enable()  if err

      @startSession.enable()
      @endSession.disable()


  viewAppended: JView::viewAppended

  setTemplate: JView::setTemplate


  pistachio: ->

    """
    <header>
    {{> @title}}{{> @chevron}}
    {{> @link}}
    <div class='buttons'>
      {{> @startSession}} {{> @endSession}}
    </div>
    </header>
    <ul class='settings default'>
      <li><label>Anyone who joins</label>{{> @defaultSetting}}</li>
    </ul>
    {{> @everyone}}
    """


