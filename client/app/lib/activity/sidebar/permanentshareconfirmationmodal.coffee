kd = require 'kd'
KDModalView = kd.ModalView
KDCustomHTMLView = kd.CustomHTMLView
KDView = kd.View
AvatarView = require 'app/commonviews/avatarviews/avatarview'
showError = require 'app/util/showError'
remote = require('app/remote').getInstance()


module.exports = class PermanentShareConfirmationModal extends KDModalView


  constructor: (options = {}, data) ->

    options.width    = 250
    options.height   = 'auto'
    options.cssClass = 'activity-modal approve-modal'

    super options, data

    @createArrow()
    @createElements()

    kd.getSingleton('windowController').addLayer this
    @on 'ReceivedClickElsewhere', @bound 'destroy'


  createArrow: ->

    _addSubview = KDView::addSubView.bind this

    _addSubview new KDCustomHTMLView
      cssClass  : 'modal-arrow'
      position  : top : 20


  createElements: ->

    owner = @getData().getOwner()

    @addSubView new KDCustomHTMLView
      tagName   : 'p'
      cssClass  : 'title'
      partial   : 'Shared with you by'


    @addSubView new AvatarView
      origin    : owner
      size      : width: 30, height: 30


    @addSubView userDetails = new KDCustomHTMLView
      cssClass  : 'user-details'


    remote.cacheable owner, (err, accounts) =>

      return showError err  if err

      { nickname, firstName, lastName } = accounts.first.profile

      userDetails.updatePartial "
        <div class='fullname'>#{firstName} #{lastName}</div>
        <div class='nickname'>@#{nickname}</div>
      "
