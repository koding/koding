class AppView extends KDView

  constructor:->

    super

    app = @getData()

    @followButton = new KDToggleButton
      style           : "kdwhitebtn"
      dataPath        : "followee"
      states          : [
        "Follow", (callback)->
          callback? null
        "Unfollow", (callback)->
          callback? null
      ]
    , app

    @likeButton = new KDToggleButton
      style           : "kdwhitebtn"
      dataPath        : "followee"
      states          : [
        "Like", (callback)->
          callback? null
        "Unlike", (callback)->
          callback? null
      ]
    , app

    @installButton = new KDButtonView
      title     : "Install Now"
      style     : "cupid-green"
      callback  : =>
        modalOptions = @sanitizeInstallModalOptions()
        modal = new KDModalViewWithForms
          title         : "Application configuration"
          width         : 500
          height        : "auto"
          overlay       : yes
          tabs          :
            navigable   : yes
            callback    : (formOutput)=>
              @createBashScript formOutput,app
              modal.destroy()
            forms       : modalOptions


  createBashScript:(formOutput,app)->
    bashScript = Encoder.htmlDecode app.attachments[0].content
    for key,value of formOutput
      bashScript = bashScript.replace "$#{key}","\"#{value}\""

    log bashScript

  sanitizeInstallModalOptions:->
    app     = @getData()
    reqs    = app.attachments[1].content
    modalOptions = JSON.parse Encoder.htmlDecode reqs
    count   = 0
    for tabName,options of modalOptions
      unless Object.keys(modalOptions).length - 1 is count
        options.buttons =
          Next    :
            title : "Next"
            style : "modal-clean-gray"
            type  : "submit"
      else
        options.buttons =
          Install :
            title : "INSTALL THE APP!"
            style : "cupid-green"
            type  : "submit"
      count++
    modalOptions

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  putThumb:(thumbnails = [])->
    if thumbnails.length > 0
      thumb = "<img src='/images/uploads/#{thumbnails[0].appThumb}'/>"
    else
      ""

  pistachio:->
    """
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{ @putThumb #(thumbnails)}}</a>
      </span>
    </div>
    <section class="right-overflow">
      {h3.profilename{#(title)}}
      <div class="installerbar clearfix">
        {{> @installButton}}
        <div class="versionstats updateddate">Version ---<p>Updated: ---</p></div>
        <div class="versionscorecard">
          <div class="versionstats">{{#(counts.installed)}}<p>INSTALLS</p></div>
          <div class="versionstats">0{{#(counts.likes)}}<p>Likes</p></div>
          <div class="versionstats">{{#(counts.followers)}}<p>Followers</p></div>
        </div>
        <div class="appfollowlike">
          {{> @followButton}}
          {{> @likeButton}}
        </div>
      </div>
    </section>
    """
