class VideoPopup extends KDView

# THIS NEEDS A DELEGATE

  constructor:(options,data)->
    super options,data
    @setClass "hidden invisible"
    @videoPopup = @getSingleton("windowController").videoPopup
    @embedData = data


  openVideoPopup:->
    h=@getDelegate().getHeight()
    w=@getDelegate().getWidth()
    t=@getDelegate().$().offset()
    unless @videoPopup? and @videoPopup?.top isnt null

      @videoPopup = window.open "http://localhost:3000/1.0/video-container.html", "KodingVideo", "menubar=no,resizable=yes,scrollbars=no,status=no,height=#{h},width=#{w},left=#{t.left+window.screenX},top=#{window.screenY+t.top+(window.outerHeight - window.innerHeight)}"
      @getSingleton("windowController").videoPopup = @videoPopup

    else

      @videoPopup.resizeTo w,(h+@videoPopup.outerHeight-@videoPopup.innerHeight)
      @videoPopup.moveTo t.left+window.screenX, window.screenY+t.top+(window.outerHeight - window.innerHeight)
      @videoPopup.focus()

    @utils.wait 1500, =>          # give the popup some time to open

      window.onfocus = =>         # once the user returns to the main view

        @utils.wait 500, =>       # user maybe just closed the popup

          if @videoPopup.length isnt 0

            window.onfocus = noop # reset the onfocus
            userChoice = no       # default selection is "Close the window"

            secondsToAutoClose = 10

            modal           = new KDModalView
              title         : "Do you want to keep the video running?"
              content       : "<p class='modal-video-close'>Your video will automatically end in <span class='countdown'>#{secondsToAutoClose}</span> seconds unless you click the 'Yes'-Button below.</p>"
              overlay       : yes
              buttons       :
                "Yes, keep it running" :
                  title     : "Yes, keep it running"
                  cssClass  : "modal-clean-gray"
                  callback  : =>
                    modal.destroy()
                    userChoice = yes
                "No, close it" :
                  title     : "No, close it"
                  cssClass  : "modal-clean-red"
                  callback  : =>
                    @videoPopup?.close()
                    modal.destroy()

            currentSeconds = secondsToAutoClose-1
            countdownInterval = window.setInterval =>
              modal.$("span.countdown").text currentSeconds--
            , 1000

            @utils.wait 1000*secondsToAutoClose, =>

              window.clearInterval countdownInterval

              unless userChoice
                @videoPopup?.close()
                modal.destroy()

      embed = @embedData

      if embed and @videoPopup
        @videoPopup.postMessage embed, "*"
      else @videoPopup?.close()