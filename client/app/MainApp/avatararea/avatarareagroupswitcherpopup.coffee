class AvatarPopupGroupSwitcher extends AvatarPopup

  viewAppended:->

    super

    @_popupList = new PopupList
      itemClass  : PopupGroupListItem

    @listController = new KDListViewController
      view                : @_popupList
      startWithLazyLoader : yes

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'


    @avatarPopupContent.addSubView switchToTitle = new KDView
      height   : "auto"
      cssClass : "sublink top"
      partial  : "Switch to:"

    switchToTitle.addSubView new KDCustomHTMLView
      tagName    : 'span'
      cssClass   : 'icon help'
      tooltip    :
        title    : "Here you'll find the groups that you are a member of, clicking one of them will take you to a new browser tab."

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all groups...</a>"
      click    : =>
        appManager.openApplication "Groups"
        @hide()

  accountChanged:->
    @listController.removeAllItems()

  populateGroups:->
    @listController.removeAllItems()
    @listController.showLazyLoader()
#    KD.remote.api.JGroup.streamModels {},{}, (err, res)=>
    KD.whoami().fetchGroups (err, groups)=>
      if err then warn err
      else if groups?
        @listController.hideLazyLoader()
        @listController.addItem group  for group in groups

  show:->
    super
    @populateGroups()

class PopupGroupListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName or= "li"

    super

    {group:{title, avatar, slug}, roles} = @getData()
  
    roleClasses = roles.map((role)-> "role-#{role}").join ' '
   
    @setClass "role #{roleClasses}"
  
    @avatar = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatar-image'
      attributes :
        src      : avatar or "http://lorempixel.com/20/20?#{@utils.getRandomNumber()}"

    @switchLink = new CustomLinkView
      title       : title
      href        : "/#{slug}"
      target      : slug
      icon        :
        cssClass  : 'new-page'
        placement : 'right'
        tooltip   :
          title   : "Opens in a new browser window."
          delayIn : 300

  viewAppended:->
    JView::viewAppended.call this
    
    {group:{slug}, roles} = @getData()
    
    dashboardHref = "/#{slug}/Dashboard"
    
    if 'admin' in roles
      @addSubView new KDCustomHTMLView
        title     : 'Admin dashboard'
        href      : dashboardHref
        click     : (event)->
          event.preventDefault()
          KD.getSingleton('router').handleRoute dashboardHref

  pistachio: ->
    {roles} = @getData()
    """
    <span class='avatar'>{{> @avatar}}</span>
    <div class='right-overflow'>
      {{> @switchLink}}<span class="roles">#{roles.join ', '}</span>
    </div>
    """


