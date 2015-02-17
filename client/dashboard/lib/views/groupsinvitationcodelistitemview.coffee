kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDInputView = kd.InputView
KDListItemView = kd.ListItemView
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView
remote = require('app/remote').getInstance()
showError = require 'app/util/showError'
defaultSlug = require 'app/util/defaultSlug'
JView = require 'app/jview'


module.exports = class GroupsInvitationCodeListItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.cssClass = 'formline clearfix'
    options.type     = 'invitation-request invitation-code'

    super options, data

    @editButton = new KDButtonView
      style       : 'solid medium'
      title       : 'Edit'
      callback    : @bound 'showEditModal'

    @shareButton = new KDButtonView
      style       : 'solid medium green'
      title       : 'Share'
      callback    : @bound 'showShareModal'

    @deleteButton = new KDButtonView
      style       : 'solid medium red'
      title       : 'Delete'
      callback    : @bound 'deleteInvitation'

    @statusText    = new KDCustomHTMLView
      partial     : '<span class="icon"></span>'
      cssClass    : 'status hidden'

  showEditModal:->
    {maxUses, memo} = @getData()
    modal = new KDModalViewWithForms
      cssClass                : 'invitation-share-modal'
      title                   : 'Share Invitation Code'
      overlay                 : yes
      width                   : 640
      height                  : 'auto'
      tabs                    :
        forms                 :
          invite              :
            callback          : (formData)=>
              @getData().modifyMultiuse formData, (err)=>
                showError err
                new KDNotificationView
                  title      : 'Invitation code updated!'
                  duration   : 2000
                modal.destroy()
            buttons           :
              Save            :
                itemClass     : KDButtonView
                style         : 'solid green medium'
                type          : 'submit'
                loader        :
                  color       : '#444444'
              # Disable         :
              #   itemClass     : KDButtonView
              #   style         : 'solid red medium'
              #   loader        :
              #     color       : '#ffffff'
              #     diameter    : 12
              #   callback      : -> log 'deactivated'
              Cancel          :
                style         : 'solid light-gray medium'
                callback      : -> modal.destroy()
            fields            :
              maxUses         :
                itemClass     : KDInputView
                label         : 'Maximum Uses'
                defaultValue  : maxUses
                validate      :
                  rules       :
                    regExp    : /\d+/i
                  messages    :
                    regExp    : 'numbers only please'
              memo            :
                label         : "Memo"
                itemClass     : KDInputView
                name          : "memo"
                defaultValue  : memo
                placeholder   : "(optional)"

  showShareModal:->
    modal = new KDModalViewWithForms
      cssClass               : 'invitation-share-modal'
      title                  : 'Share Invitation Code'
      overlay                : yes
      width                  : 640
      height                 : 'auto'
      tabs                   :
        forms                :
          invite             :
            buttons          :
              Close          :
                itemClass    : KDButtonView
                style        : 'solid green medium'
                loader       :
                  color      : '#444444'
                callback     : -> modal.destroy()
            fields           :
              link           :
                itemClass    : KDInputView
                label        : 'Invitation Link'
                defaultValue : @getInvitationUrl()

  getInvitationUrl:->
    {group, code} = @getData()
    slug  = if group and group isnt defaultSlug then "#{group}/" else ''
    "https://#{global.location.host}/#{slug}Invitation/#{code}"

  markDeleted:->
    @statusText.setClass 'deleted'
    @statusText.$('span.title').html 'Deleted'
    @statusText.unsetClass 'hidden'
    @editButton.hide()
    @shareButton.hide()

  deleteInvitation:->
    {group, code} = @getData()
    remote.api.JInvitation.byCode code, (err, invitation) =>
      return showError err if err

      modal                  = new KDModalViewWithForms
        cssClass             : 'invitation-remove-modal'
        title                : "Remove Invitation Code #{code}"
        overlay              : yes
        tabs                 :
          forms              :
            Remove           :
              buttons        :
                Confirm      :
                  itemClass  : KDButtonView
                  style      : 'solid green medium'
                  loader     :
                    color    : '#444444'
                  callback   : =>
                    invitation.remove (err) =>
                      return showError err if err
                      modal.destroy()
                      @destroy()

  pistachio:->
    {code, maxUses, uses, memo} = @getData()
    codeSuffix = if memo then " (#{memo})" else ''
    """
    <section>
      <div class="buttons">{{> @deleteButton}} {{> @shareButton}} {{> @editButton}}</div>
      {{> @statusText}}
      <div class="details">
        <div class="code">#{code}#{codeSuffix}</div>
        <div class="usage">#{uses} of #{maxUses} used</div>
      </div>
    </section>
    """


