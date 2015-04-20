kd              = require 'kd'
_               = require 'lodash'
AvatarView      = require 'app/commonviews/avatarviews/avatarview'
ProfileTextView = require 'app/commonviews/linkviews/profiletextview'

###*
 * A view to show given people list when clicked. It works as a toggle button,
 * meaning that it toggles the participant list rather than showing it everytime
 * it is clicked.
 *
 * @class
###
module.exports = class MoreParticipantsButton extends kd.ButtonViewWithMenu

  constructor: (options = {}, data) ->

    options = _.assign {},
      title         : "+#{options.participantList.size}"
      cssClass      : 'ParticipantHeads-button ParticipantHeads-button--more MoreParticipantsButton'
      style         : 'resurrection ParticipantHeads-moreList' # context-menu css classes.
      moreListTitle : 'Other Participants'
    , options

    super options, data


  ###*
   * Override the default behavior to allow it to work as toggle the list.
   *
   * @param {DOMEvent} event
  ####
  click: do (skipNextClick = no) -> (event) ->

    kd.utils.stopDOMEvent event

    return skipNextClick = no  if skipNextClick

    @contextMenu event

    @setClass 'is-moreListActive'

    # with this we make the button works like a toggle.
    # TODO: in KDFramework, we need to forward the 'ReceievedClickElsewhere'
    # method from buttonMenu's treeController view, and use it here, rather
    # than knowing that much of the internals of KDContextMenu component. ~Umut
    @buttonMenu.treeController.getView().once 'ReceivedClickElsewhere', (e) =>
      skipNextClick = yes  if e.target is getButtonElement this
      @unsetClass 'is-moreListActive'

    return no


  ###*
   * It creates context menu with given DOM click event.
   *
   * @param {DOMEvent} event - event that comes from click handler.
  ###
  createContextMenu: (event) ->

    options = @getOptions()
    @buttonMenu = new kd.JButtonMenu
      cssClass : options.style
      ghost    : @$('.chevron').clone()
      event    : event
      delegate : this
    , options.menu()

    @buttonMenu.on "ContextMenuItemReceivedClick", => @buttonMenu.destroy()


  ###*
   * Override the default dom element of kd.ButtonWithMenu, we don't need
   * chevron, chevron-separator and any other extra css class or dom elements
   * for this one.
   *
   * @param {string} cssClass
  ###
  setDomElement:(cssClass = '') ->
    $ = require 'jquery'
    @domElement = $ """
      <div class='kdbuttonwithmenu-wrapper MoreParticipantsButton-wrapper'>
        <button class='kdbutton #{cssClass}' id='#{@getId()}'>
        </button>
      </div>
      """
    @$button = @$('button').first()

    return @domElement

###*
 * Helper function to get button element of given view.
 *
 * @param {KDButtonWithMenu} view
###
getButtonElement = (view) -> view.getElement().querySelector 'button'


###*
 * Create an object to be used as context menu items map from given accounts.
 *
 * @param {Immutable.OrderedMap<string, JAccount>} accounts
 * @return {object} list
###
createMoreListFromAccounts = (accounts) ->

  createAvatar = (acc) ->
    k 'div', 'moreList-singleItemAvatar', [
      new AvatarView { size: { width: 25, height: 25 } }, acc
    ]
  createName = (acc) ->
    k 'div', 'moreList-singleItemText', [
      new ProfileTextView {}, acc
    ]

  list = accounts.toJS().reduce (items, account) ->
    items[account.profile.nickname] =
      type : 'customView'
      view : k 'div', 'moreList-singleItem', [
        createAvatar account
        createName account
      ]
    return items
  , {}

  return list


###*
 * Create a KDView with given tag, css class, and subviews.
 *
 * @param {string} tagName
 * @param {string} cssClass
 * @param {Array.<(KDView|string)>} subviews
###
k = (tagName, cssClass, subviews = []) ->

  view = new kd.CustomHTMLView { tagName, cssClass }

  for subview in subviews
    if 'string' is typeof subview
    then view.setPartial subview
    else view.addSubView subview

  return view


