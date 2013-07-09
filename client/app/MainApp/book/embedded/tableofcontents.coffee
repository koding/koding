class BookTableOfContents extends JView

  pistachio:->

    tmpl = "<ul class=\"contents\">"
    for page, nr in __bookPages
      if page.parent == 0 and page.section > 0
        tmpl += "<li><a href='#'>#{page.title}</a><span>#{nr+1}</span></li>"

    return tmpl

  click:(event)->

    if $(event.target).is("a")
      nr = parseInt($(event.target).next().text(), 10)-1
      @getDelegate().fillPage nr
      no
    else
      yes
