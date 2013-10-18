class GmailContactsListItem extends KDListItemView
  constructor: (options = {}, data) ->
    options.type = "gmail"
    super options, data

    @isSelected = no

    @on "InvitationSent", @bound "invitationSent"

  click: ->
    @toggleClass "send-invitation"
    @isSelected        = !@isSelected

  invitationSent: ->
    @setClass "invitation-sent"
    @getData().invited = yes

  setAvatar: ->
    hash     = md5.digest @getData().email
    fallback = "#{KD.apiUri}/images/defaultavatar/default.avatar.25.png"
    uri      = "url(//gravatar.com/avatar/#{hash}?size=25&d=#{encodeURIComponent fallback})"
    @$(".avatar").css "background-image", uri

  viewAppended: ->
    JView::viewAppended.call this
    @setClass "already-invited" if @getData().invited
    @setAvatar()

  pistachio: ->
    """
      <div class="avatar"></div>
      <div class="contact-info">
        <span class="full-name">#{@getData().title || "Gmail Contact"}</span>
        {{ #(email)}}
      </div>
      <div class="checkmark"><span>&#10004;</span></div>
      <div class="invitation-sent-overlay">
        <span class="checkmark"></span>Invitation is sent
      </div>
    """
