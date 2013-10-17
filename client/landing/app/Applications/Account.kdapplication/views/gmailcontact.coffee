class GmailContactsListItem extends KDListItemView
  constructor: (options = {}, data) ->
    options.type     = "gmail"
    data.invited    ?= no

    super options, data

    @isSelected = no

    @on "InvitationSent", @bound "sentInvitation"

  click:->
    @toggleClass "send-invitation"
    @isSelected        = !@isSelected

  sentInvitation: ->
    @setClass "invitation-sent"
    @getData().invited = yes

  setAvatar: ->
    hash     = md5.digest @getData().email
    fallback = "#{KD.apiUri}/images/defaultavatar/default.avatar.#{25}.png"
    uri      = "url(//gravatar.com/avatar/#{hash}?size=25&d=#{encodeURIComponent fallback})"
    @$(".avatar").css "background-image", uri

  viewAppended:->
    uber = JView::viewAppended.bind @
    @setClass "already-invited" if @getData().invited
    uber()

    @setAvatar()

  partial:->

  pistachio:->
    """
      <div class="avatar"></div>
      <div class="contact-info">
        <span class="full-name">#{@getData().title || "Gmail Contact"}</span>
        {{ #(email)}}
      </div>
      <div class="checkmark"><span>&#10004;</span></div>
      <div class="invitation-sent-overlay">
        <span class="checkmark"></span>Invitation is Sent
      </div>
    """
