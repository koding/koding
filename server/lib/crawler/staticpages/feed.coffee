{argv}                  = require 'optimist'
{uri}                   = require('koding-config-manager').load("main.#{argv.c}")
{daisy}                 = require "bongo"
{Relationship}          = require 'jraphical'
encoder                 = require 'htmlencode'
{createActivityContent, decorateComment} = require '../helpers'

ITEMSPERPAGE = 20

module.exports = (bongo, page, contentType, callback)=>
  {JName, JAccount, JNewStatusUpdate, JTag} = bongo.models
  skip = 0
  if page > 0
    skip = (page - 1) * ITEMSPERPAGE

  options = {
    limit : ITEMSPERPAGE
    skip  : skip
    sort: 'meta.createdAt': -1
  }

  if contentType is "Activity"
    model = JNewStatusUpdate
  else if contentType is "Topics"
    model = JTag
  else
    return callback new Error "Unknown content type.", null

  pageContent = ""
  selector = group : "koding"
  model.count selector, (error, count)=>
    return callback error, null  if error
    return callback null, getEmptyPage contentType  if count is 0
    model.some selector, options, (err, contents)=>
      return callback err, null  if err
      return callback null, getEmptyPage contentType  if count is 0
      queue = [0...contents.length].map (index)=>=>
        queue.pageContent or= ""

        content = contents[index]

        if contentType is "Activity"
          createFullHTML = no
          putBody = yes
          createActivityContent JAccount, content, {}, createFullHTML, putBody, (error, content)=>
            return queue.next()  if error or not content
            queue.pageContent = queue.pageContent + content
            queue.next()
        else if contentType is "Topics"
          appendDecoratedTopic content, queue
        else queue.next()
      queue.push =>
        schemaorgTagsOpening = getSchemaOpeningTags contentType
        schemaorgTagsClosing = getSchemaClosingTags contentType

        content = schemaorgTagsOpening + queue.pageContent + schemaorgTagsClosing

        pagination = getPagination page, count, contentType
        fullPage = putContentIntoFullPage content, pagination, contentType
        return callback null, fullPage
      daisy queue

getPagination = (currentPage, numberOfItems, contentType)->
  # This is the number of adjacent link around current page.
  # E.g. let current page be 9, then pagination will look like this:
  # First Prev ... 4 5 6 7 8 9 10 11 12 13 14 ... Next Last
  # (Except 3-dots, they are useless for bots.)
  PAGERWINDOW = 4

  numberOfPages = Math.ceil(numberOfItems / ITEMSPERPAGE)
  firstLink = prevLink = nextLink = lastLink = ""

  if currentPage > 1
    firstLink = getSinglePageLink 1, contentType, "First"
    prevLink  = getSinglePageLink (currentPage - 1), contentType, "Prev"

  if currentPage < numberOfPages
    lastLink  = getSinglePageLink numberOfPages, contentType, "Last"
    nextLink  = getSinglePageLink (currentPage + 1), contentType, "Next"

  pagination = firstLink + prevLink

  start = 1
  end = numberOfPages

  start = currentPage - PAGERWINDOW  if currentPage > PAGERWINDOW

  if currentPage + PAGERWINDOW < numberOfPages
    end   = currentPage + PAGERWINDOW

  if start > 1
    pagination += getNoHrefLink " ... "

  [start..end].map (pageNumber)=>
    pagination += getSinglePageLink pageNumber, contentType

  if end < numberOfPages
    pagination += getNoHrefLink " ... "

  pagination += nextLink
  pagination += lastLink

  return pagination

getNoHrefLink = (linkText)->
  "<a href='#'>#{linkText}  </a>"

getSinglePageLink = (pageNumber, contentType, linkText=pageNumber)->
  link = "<a href='#{uri.address}/#{contentType}?page=#{pageNumber}'>#{linkText}  </a>"
  return link

appendDecoratedTopic = (tag, queue)=>
  queue.pageContent += createTagNode tag
  queue.next()

getSchemaOpeningTags = (contentType)=>
  openingTags = ""
  if contentType is "Activity"
    openingTags =
      """
        <article itemscope itemtype="http://schema.org/BlogPosting">
          <div itemscope itemtype="http://schema.org/ItemList">
            <meta itemprop="mainContentOfPage" content="true"/>
            <h2 itemprop="name" class="invisible">Latest activities</h2><br>
            <meta itemprop="itemListOrder" content="Descending" />
      """
  else if contentType is "Topics"
    openingTags =
      """
        <div itemscope itemtype="http://schema.org/ItemList">
          <meta itemprop="mainContentOfPage" content="true"/>
          <h2 itemprop="name" class='invisible'>Latest topics</h2><br>
          <meta itemprop="itemListOrder" content="Descending" />
          <div></div>
      """
  return openingTags

getSchemaClosingTags = (contentType)=>
  closingTags = ""
  if contentType is "Activity"
    closingTags = "</div></article>"
  else if contentType is "Topics"
    closingTags = "</div>"
  return closingTags

createTagNode = (tag)->
  tagContent = ""
  return tagContent  unless tag.title
  """
  <div class="kdview kdlistitemview kdlistitemview-topics topic-item">
    <header>
      <h3 class="subview">
        <a href="#{uri.address}/Activity?tagged=#{tag.slug}">
          <span itemprop="itemListElement">#{tag.title}</span>
        </a>
      </h3>
    </header>
    <div class="stats">
      <a href="#"><span>#{tag.counts?.post ? 0}</span> Posts</a>
      <a href="#"><span>#{tag.counts?.followers ? 0}</span> Followers</a>
    </div>
    <article>#{encoder.XSSEncode(tag.body) ? ''}</article>
  </div>
  """

createFollowersCount = (numberOfFollowers)->
  return "<span>#{numberOfFollowers}</span> followers"

createUserInteractionMeta = (numberOfFollowers)->
  userInteractionMeta = "<meta itemprop=\"interactionCount\" content=\"UserComments:#{numberOfFollowers}\"/>"
  return userInteractionMeta

getDock = ->
  """
  <header id="main-header" class="kdview">
      <div class="inner-container">
          <a id="koding-logo" href="/">
              <cite></cite>
          </a>
          <div id="dock" class="">
              <div id="main-nav" class="kdview kdlistview kdlistview-navigation">
                  <a class="kdview kdlistitemview kdlistitemview-main-nav activity kddraggable running" href="/Activity" style="left: 0px;">
                      <span class="icon"></span>
                      <cite>Activity</cite>
                  </a>
                  <a class="kdview kdlistitemview kdlistitemview-main-nav teamwork kddraggable" href="/Teamwork" style="left: 55px;">
                      <span class="icon"></span>
                      <cite>Teamwork</cite>
                  </a>
                  <a class="kdview kdlistitemview kdlistitemview-main-nav terminal kddraggable" href="/Terminal" style="left: 110px;">
                      <span class="icon"></span>
                      <cite>Terminal</cite>
                  </a>
                  <a class="kdview kdlistitemview kdlistitemview-main-nav editor kddraggable" href="/Ace" style="left: 165px;">
                      <span class="icon"></span>
                      <cite>Editor</cite>
                  </a>
                  <a class="kdview kdlistitemview kdlistitemview-main-nav apps kddraggable" href="/Apps" style="left: 220px;">
                      <span class="icon"></span>
                      <cite>Apps</cite>
                  </a>
              </div>
          </div>
          <div class="account-area">
            <a class="custom-link-view header-sign-in" href="/Register">create an account</a>
            <a class="custom-link-view header-sign-in" href="/Login">login</a>
          </div>
      </div>
  </header>
  """
getEmptyPage = (contentType) ->
  putContentIntoFullPage "There is no activity yet", "", contentType

putContentIntoFullPage = (content, pagination, contentType)->
  getGraphMeta  = require './graphmeta'
  analytics     = require './analytics'

  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>Koding | A New Way For Developers To Work</title>
    #{getGraphMeta()}
  </head>
  <body itemscope itemtype="http://schema.org/WebPage" class="super activity">
    <div id="kdmaincontainer" class="kdview">
      #{getDock()}
        <div id="content-page-activity" class="kdview kdscrollview content-page activity">
          <main class="kdview kdscrollview static-feed kdtabview">

            <!-- .kdlistitemview-activity is a single activity item -->

            <div class="kdview kdlistitemview kdlistitemview-activity activity-item status">
              <div class="activity-content-wrapper static-feed">
                <a class="avatarview author-avatar" href="/sinan" style="background-image: none; background-size: 42px;">
                  <img class="" width="42" height="42" src="//gravatar.com/avatar/fb9edfce4f54230c890431a97db6c99e?size=42&amp;d=https://koding-cdn.s3.amazonaws.com/images/default.avatar.42.png&amp;r=g" style="opacity: 1;">
                </a>
                <div class="meta">
                  <a href="/sinan" class="profile">
                    <span>Sinan Yasar</span>
                  </a>
                  <time class="kdview">4 days ago</time>
                  <span class="location">San Francisco</span>
                </div>
                <article>
                  <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse
                  sem orci, porttitor ut mollis non, vehicula eu purus. Pellentesque massa
                  odio, tempus cursus eros nec, lacinia aliquam risus. Mauris dignissim,
                  metus quis aliquam pretium, lectus libero consequat quam, sed congue nulla
                  arcu ac leo.</p>
                </article>
                <div class="kdview like-summary">
                  <a href="/sinan" class="profile"><span>Sinan Yasar</span></a>
                  <span> liked this.</span>
                </div>
              </div>
              <div class="kdview comment-container fixed-height active-comment commented">
                <div class="kdview kdlistview kdlistview-comments">

                  <!-- .kdlistitemview-comment is a single comment item -->

                  <div class="kdview kdlistitemview kdlistitemview-comment">
                    <a class="avatarview" href="/sinan" style="background-image: none; background-size: 42px;">
                      <img width="42" height="42" src="//gravatar.com/avatar/fb9edfce4f54230c890431a97db6c99e?size=42&amp;d=https://koding-cdn.s3.amazonaws.com/images/default.avatar.42.png&amp;r=g" style="opacity: 1;">
                    </a>
                    <div class="comment-contents clearfix">
                      <a href="/sinan" class="profile">Sinan Yasar</a>
                      <div class="comment-body-container">
                        <p>HULAHOP</p>
                      </div>
                    </div>
                  </div>

                  <!-- .kdlistitemview-comment ends here -->

                </div>
              </div>
            </div>

            <!-- .kdlistitemview-activity ends here -->

          </main>
        </div>
    </div>
    #{analytics()}
  </body>
  </html>
  """

# putContentIntoFullPage = (content, pagination, contentType)->
#   getGraphMeta  = require './graphmeta'
#   analytics     = require './analytics'

#   """
#     <!DOCTYPE html>
#     <html lang="en">
#     <head>
#       <title>Koding | A New Way For Developers To Work</title>
#       #{getGraphMeta()}
#     </head>
#     <body itemscope itemtype="http://schema.org/WebPage" class="super activity">
#       <div id="kdmaincontainer" class="kdview">
#         #{getDock()}
#         <section id="main-panel-wrapper" class="kdview">
#           <div id="main-tab-view" class="kdview kdscrollview kdtabview">
#             <div class="kdview kdtabpaneview activity clearfix content-area-pane active">

#               <div id="content-page-#{contentType.toLowerCase()}" class="kdview kdscrollview content-page #{contentType.toLowerCase()} loggedin">
#                 <main class="">
#                   <div class="kdview activity-content feeder-tabs">
#                     <div class="kdview listview-wrapper">
#                       <div class="kdview kdscrollview">
#                         <div class="kdview kdlistview kdlistview-default activity-related">
#                           #{content}
#                         </div>
#                       </div>
#                     </div>
#                     <nav class="crawler-pagination clearfix">
#                       #{pagination}
#                     </nav>
#                   </div>
#                 </main>
#               </div>
#             </div>
#           </div>
#         </section>
#       </div>
#       #{analytics()}
#     </body>
#     </html>
#   """
