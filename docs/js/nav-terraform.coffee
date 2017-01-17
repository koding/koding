---
---

do ->

  MAIN_UL = $ '#terraform-docs'
  docsMap = {}
  pageUrl = PAGE_URL

  # expandParents = (el) ->
  #   parent = el.closest('ul').show()
  #   expandParents parent  if parent.closest('ul').length
  getTitle = (raw) ->
    if /\:\s/.test raw
    then raw.split(': ').pop()
    else raw

  createSubNavItems = (doc, parent, prop) ->

    if index = doc.index
      isActive = pageUrl is index.url
      parent.append "<li class='title#{ if isActive then ' active' else ''}'><a href='{{ site.url }}#{index.url}'>#{getTitle index.title}</a></li>"
    else if prop is 'd'
      parent.append "<li class='title separator'><a href='#'>Data Sources</a></li>"
    else if prop is 'r'
      parent.append "<li class='title separator'><a href='#'>Resources</a></li>"

    if doc.title
      unless /index\.html\/?/.test doc.url
        isActive = pageUrl is doc.url
        parent.append "<li #{ if isActive then 'class=\'active\'' else ''}><a href='{{ site.url }}#{doc.url}'>#{getTitle doc.title}</a></li>"

    else

      ul = $ '<ul/>'
      sortedKeys = (key for own key, value of doc).sort()
      createSubNavItems doc[key], ul, key  for key in sortedKeys
      parent.find('li').last().append ul

    return ul

  return  unless TERRAFORM_DOCS

  TERRAFORM_DOCS.forEach (doc) ->
    id = doc.url.replace('/docs/terraform/', '').split '/'
    id.pop()
    path = id.join '.'
    path = path.replace /\.html?/, ''
    lodash_set docsMap, path, doc

  docsMap.index.title = 'Stack Documentation'

  window.TERRAFORM_DOCS_MAP = docsMap

  createSubNavItems docsMap, MAIN_UL

  if pageUrl is '/docs/home'
    $('aside li ul ul ul').hide()
  else
    $('aside li ul').hide()

  $('li.active > ul').show()
  $('li.active > ul > li.separator > ul').show()
  $('li.active').parents('ul').show()


  $('li a[href="#"]').on 'click', (event) ->
    event.preventDefault()
    $(this).parent().find('> ul').show()
