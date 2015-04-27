kd                     = require 'kd'
AvatarView             = require 'app/commonviews/avatarviews/avatarview'
MoreParticipantsButton = require './moreparticipantsbutton'

###*
 * A view to list participants of a SocialChannel. Especially for
 * PrivateMessages and Collaboration Channels. It has 3 containers:
 *
 *     - `previewContainer` - contains the avatar list.
 *     - `extrasContainer` - contains views for showing extra people
 *     - `newButtonContainer` - contains views for adding people.
 *
 * Biggest difference of this view, it works stateless. There is no saved
 * avatars, participants or anything. This class basically takes participants,
 * and renders them, you can pass an object to follow the same semantics of
 * result of the `ChannelParticipants::getList` method to
 * `ParticipantHeads::updateParticipants` method, it will destroy everything and
 * re-render with given participants. See `ParticipantHeads::updateParticipants
 * for detailed info.
 *
 * @class
###
module.exports = class ParticipantHeads extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass      = 'ParticipantHeads clearfix'
    options.moreListTitle = 'Other participants'

    super options, data

    @moreListView = null

    @previewContainer = k 'div', 'ParticipantHeads-previewContainer clearfix'
    @actionsContainer = k 'div', 'ParticipantHeads-actionsContainer clearfix', [
      @extrasContainer    = k 'div', 'ParticipantHeads-extrasContainer clearfix'
      @newButtonContainer = k 'div', 'ParticipantHeads-newButtonContainer clearfix'
    ]

    @newButtonContainer.addSubView @newParticipantButton = new kd.ButtonView
      cssClass : 'ParticipantHeads-button ParticipantHeads-button--new'
      iconOnly : yes
      callback : @bound 'onNewParticipantClick'

    @addSubView @previewContainer
    @addSubView @actionsContainer


  ###*
   * Click handler for new participant button.
  ###
  onNewParticipantClick: ->

    @newParticipantButton.toggleClass 'active'
    @actionsContainer.toggleClass 'is-newButtonActive'
    @emit 'NewParticipantButtonClicked'


  ###*
   * Resets new participant button's state.
  ###
  resetNewButtonState: ->

    @newParticipantButton.unsetClass 'active'
    @actionsContainer.unsetClass 'is-newButtonActive'


  ###*
   * Whenever a change happens this method needs to be triggered with
   * participant map that follows the signature of
   * `ChannelParticipants::getLists` method, which is an object with 3
   * properties:
   *
   *     - `preview` - participants for preview container.
   *     - `hidden` - participants for extras container.
   *     - `all` - all participants for this channel.
   *
   * Those object's properties are all instances of `immutable.OrderedMap`
   *
   * @param {object} participantsMap
   * @param {Immutable.OrderedMap} participantsMap.preview
   * @param {Immutable.OrderedMap} participantsMap.hidden
  ###
  updateParticipants: (participantsMap) ->

    @updatePreviewAvatars participantsMap.preview
    @updateExtras participantsMap.hidden


  ###*
   * Destroy all avatars, then re-add avatars for given participant map.
   *
   * @param {Immutable.OrderedMap} participants
  ###
  updatePreviewAvatars: (participants) ->

    avatars = participants.toJS().map (participant) ->
      options = { size: { width: 25, height: 25 } }
      new AvatarView options, participant

    @previewContainer.destroySubViews()
    @previewContainer.addSubView avatar  for avatar in avatars


  ###*
   * Destroy all subviews of extras container, and re-add the views back for
   * given participant map.
   *
   * @param {Immutable.OrderedMap} participants
  ###
  updateExtras: (participants) ->

    return  @extrasContainer.hide()  unless count = participants.size

    moreButton = new MoreParticipantsButton
      participantList : participants
      moreListTitle   : @options.moreListTitle

    @forwardEvent moreButton, 'ParticipantSelected'

    @extrasContainer.destroySubViews()
    @extrasContainer.addSubView moreButton
    @extrasContainer.show()


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


