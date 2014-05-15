class TeamworkShareModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-modal tw-share-modal"
    options.overlay  = yes
    options.width    = 655

    super options, data

    url = "#{location.origin}/Teamwork?sessionKey=#{@getDelegate().sessionKey}"
    message =
      """
      <div class='modalformline'>
        <p>Share the url below to invite others to your Koding teamwork/pair coding session.</p><br />
        <p>
          Be aware that makes your VM accessible to your collaborators until you close the browser tab.
        </p><br />

        <p>
          <a href="#{url}">#{url}</a>
        </p>
      </div>
      """

    modal = new KDModalView
      width            : 600
      overlay          : yes
      title            : "Collaborate in real-time"
      cssClass         : "new-kdmodal"
      content          : "<div class='modalformline'>#{message}</div>"
      buttons          :
        Close          :
          callback     : -> modal.destroy()
