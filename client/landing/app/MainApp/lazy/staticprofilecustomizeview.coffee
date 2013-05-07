class StaticProfileCustomizeView extends StaticPageCustomizeView

  constructor:(options,data)->
    super options,data
    @staticController = @getSingleton('staticProfileController')
    @setClass 'profile-customize-view'

    user = @getData()

    if user.profile.staticPage
      {show} = user.profile.staticPage
    else show = yes

    @visibilityView = new KDOnOffSwitch
      size                  : 'tiny'
      defaultValue          : show
      callback              : (value)=>
        if value is false
          modal           = new KDModalView
            cssClass      : 'disable-static-page-modal'
            title         : 'Do you really want to disable your Public Page?'
            content       : """
              <div class="modalformline">
                <p>Disabling this feature will disable other people
                from publicly viewing your profile. You will still be
                able to access the page yourself.</p>
                <p>Do you want to continue?</p>
              </div>
              """
            buttons       :
              "Disable the Public Page" :
                cssClass  : 'modal-clean-red'
                callback  : =>
                  modal.destroy()
                  user.setStaticPageVisibility no, (err,res)=>
                    if err then log err
              Cancel      :
                cssClass  : 'modal-cancel'
                callback  : =>
                  @visibilityView.setValue off
                  modal.destroy()
        else
          user.setStaticPageVisibility yes, (err,res)=>
            if err then log err



  addSettingsButton:->

  fetchStaticPageData:(callback =->)->
    @group = @getData()
    callback @group

  pistachio:->
    """
    {{> @backButton}}
    <h1 class="customize-title">Customize this Profile page
    </h1>
    <div class='visible-switch'>Make this page Public   {{> @visibilityView}}</div>
    {{> @bgSelectView}}
    {{> @bgColorView}}
    {{> @saveButton}}
    """

class StaticGroupCustomizeView extends StaticPageCustomizeView

  constructor:(options,data)->
    super options,data

  # fetchStaticPageData:(callback =->)->
  #   KD.remote.cacheable @getDelegate().entryPoint.slug, (err,[group],name)=>
  #     @group = group
  #     callback group
