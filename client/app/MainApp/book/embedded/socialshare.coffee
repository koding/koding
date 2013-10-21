class SocialShare extends JView

  constructor: ->
    super
    @facebook = new KDCustomHTMLView
      tagName       : "iframe"
      attributes    :
        width       : 90
        height      : 20
        frameborder : 0
        scrolling   : "no"
        allowtransparency: "true"
        src         : "http://www.facebook.com/plugins/like.php?href=https%3A%2F%2Fkoding.com&width=40&height=21&colorscheme=light&layout=button_count&action=like&show_faces=false&send=false"

    @twitter = new KDCustomHTMLView
      tagName       : "a"
      cssClass      : "twitter-follow-button"
      href          : "https://twitter.com/koding"
      partial       : ""

    @twitter.on "viewAppended", =>
      protocol = if /^http:/.test document.location then 'http' else 'https'
      require ["#{protocol}://platform.twitter.com/widgets.js"], =>
        twttr.widgets.createFollowButton(
          'koding'
          @twitter.getElement()
          noop
        )

  pistachio: ->
    """
    {{> @facebook}}
    {{> @twitter}}
    """