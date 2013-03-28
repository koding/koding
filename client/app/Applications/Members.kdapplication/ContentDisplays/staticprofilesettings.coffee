class StaticProfileSettingsModalView extends KDModalView
  constructor:(options={},data)->
    options.title ?= 'Public Profile Settings'
    options.content ?= 'Public Profile Settings live here'

    options.buttons ?= {}
    options.buttons["Save Changes"] ?=
      cssClass : 'modal-clean-gray'
      callback :=>
        @saveSettings =>
          @destroy()
    options.buttons["Cancel"] ?=
      cssClass : 'modal-cancel'
      callback :=>
        @destroy()

    super options,data

  saveSettings:(callback)->
    callback()


class StaticProfileTooltip extends KDView
  constructor:(options,data)->
    super options,data
    @setClass 'static-profile-tooltip'

    @staticPageSwitch = new KDOnOffSwitch
      size          : 'tiny'
      title         : 'Enable Public Page'
      cssClass      : 'static-page-switch'
      tooltip:
        title : 'Enabling Public Page will expose your profile to the internet. Non-Koding users will be able to read your content, depending on your settings.'
      defaultValue  : @getData().profile.staticPage?.show
      callback:(state)=>
        @getData().setStaticPageVisibility state, =>
          # log 'done', arguments

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    {nickname}=@getData().profile
    """
    <div class="tooltip-formline">
    {{> @staticPageSwitch}}
    </div>
    <div class="tooltip-formline">
    <a class="user-profile-link" href="/#{nickname}" target="_blank">Visit your Public Page</a>
    </div>
    """