kd                     = require 'kd'
JView                  = require 'app/jview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView


module.exports = class TopicItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data
    
    @typeLabel = new KDCustomHTMLView
      cssClass : 'role'
      partial  : "Type <span class='settings-icon'></span>"
      click    : =>
        @settings.toggleClass  'hidden'
        @typeLabel.toggleClass 'active'
    
    @createSettingsView()

  createSettingsView: ->

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'

    @settings.addSubView linkButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'LINK CHANNEL'

    @settings.addSubView removeButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'REMOVE LINK'

    @settings.addSubView deleteButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'DELETE CHANNEL'

  pistachio: ->
    data     = @getData()
    type     = 'Type'
    
    return """
      <div class="details">
        <p class="nickname">#{data.name}</p>
      </div>
      {{> @typeLabel}}
      <div class='clear'></div>
      {{> @settings}}

    """