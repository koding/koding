class GmailContactsListItem extends KDListItemView
  constructor: (options = {}, data) ->
    options.type = "gmail"
    super options, data

    @on "InvitationSent", @bound "decorateInvitationSent"

  click: ->
    data = @getData()
    data.invite (err) =>
      return log err  if err
      @decorateInvitationSent()
      KD.kdMixpanel.track "User Sent Invitation", $user: KD.nick(), count: 1

  decorateInvitationSent: ->
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
      <div class="invitation-sent-overlay">
        <span class="checkmark"></span>Invitation is sent
      </div>
    """
