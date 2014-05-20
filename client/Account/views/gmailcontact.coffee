class GmailContactsListItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->
    options.type = "gmail"
    super options, data

    @on "InvitationSent", @bound "decorateInvitationSent"

  click: ->
    data = @getData()
    data.invite (err) =>
      return log err  if err
      @decorateInvitationSent()
      KD.mixpanel "User invite send, success"

  decorateInvitationSent: ->
    @setClass "invitation-sent"
    @getData().invited = yes

  setAvatar: ->
    hash     = md5.digest @getData().email
    fallback = "#{KD.apiUri}/a/images/defaultavatar/avatar.svg"
    uri      = "url(//gravatar.com/avatar/#{hash}?size=25&d=#{encodeURIComponent fallback})"
    @$(".avatar").css "background-image", uri
    @$(".avatar").css "-webkit-background-size", "25px 25px"
    @$(".avatar").css "-moz-background-size", "25px 25px"
    @$(".avatar").css "background-size", "25px 25px"

  viewAppended: ->
    JView::viewAppended.call this
    @setClass "already-invited" if @getData().invited
    @setAvatar()

  pistachio: ->
    {email, title} = @getData()
    """
      <div class="avatar"></div>
      <div class="contact-info">
        <span class="full-name">#{title || "Gmail Contact"}</span>
        {{ #(email)}}
      </div>
      <div class="invitation-sent-overlay">
        <span class="title">Invitation is sent to</span>
        <span class="email">#{email}</span>
      </div>
    """
