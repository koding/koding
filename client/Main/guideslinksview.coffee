class GuidesLinksView extends KDView

  Links      =
    'ssh'    : 'http://learn.koding.com/guides/ssh-into-your-vm/'
    'sudo'   : 'http://learn.koding.com/faq/what-is-my-sudo-password/'
    'mySQL'  : 'http://learn.koding.com/guides/installing-mysql/'
    'NodeJS' : 'http://learn.koding.com/guides/getting-started-nodejs/'
    'apache' : 'http://learn.koding.com/categories/apache/'

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'guides-links', options.cssClass

    unless options.partial?

      partial = ""
      for title, link of Links
        partial += "<a href='#{link}' title='#{title}' target='_blank'>#{title}</a>, "
      partial = partial[...-2]

      options.partial = partial

    super options, data
