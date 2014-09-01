class GuidesLinksView extends JView
  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'guides-links', options.cssClass

    super options, data

    @createLinks()

  createLinks: ->

    @ssh = new CustomLinkView
      title    : 'ssh'
      href     : 'http://learn.koding.com/guides/ssh-into-your-vm/'
      target   : '_blank'

    @sudo = new CustomLinkView
      title    : 'sudo'
      href     : 'http://learn.koding.com/faq/what-is-my-sudo-password/'
      target   : '_blank'

    @mySQL = new CustomLinkView
      title    : 'mySQL'
      href     : 'http://learn.koding.com/guides/installing-mysql/'
      target   : '_blank'

    @nodeJS = new CustomLinkView
      title    : 'NodeJS'
      href: 'http://learn.koding.com/guides/getting-started-nodejs/'
      target   : '_blank'

    @apache = new CustomLinkView
      title    : 'apache'
      href     : 'http://learn.koding.com/categories/apache/'
      target   : '_blank'


  pistachio: ->
    """
    {{> @ssh}}, {{> @sudo}}, {{> @mySQL}}, {{> @nodeJS}}, {{> @apache}}
    """


