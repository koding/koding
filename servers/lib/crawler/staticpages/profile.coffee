{ getProfile }             = require '../helpers'
{ getAvatarImageUrl }      = require './activity'
{ getSidebar }             = require './feed'

module.exports = (account, statusUpdates)=>
  getGraphMeta = require './graphmeta'
  analytics    = require './analytics'

  {profile:{nickname}} = account  if account

  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>#{nickname} - Koding</title>
    <style>body, html {height: 100%}</style>
    #{getGraphMeta()}
  </head>
  <body itemscope itemtype="http://schema.org/WebPage" class="super profile">
    <div id="kdmaincontainer" class="kdview with-sidebar">
      #{getSidebar()}
      #{putContent(account, statusUpdates)}
    </div>
    #{analytics()}
    <script>
      (function(d) {
        var config = {
          kitId: 'rbd0tum',
          scriptTimeout: 3000
        },
        h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
      })(document);
    </script>
  </body>
  </html>
  """

  # """
  # <!DOCTYPE html>
  # <html lang="en">
  # <head>
  #   <title>#{nickname} - Koding</title>
  #   #{getGraphMeta()}
  # </head>
  #   <body class='koding profile' itemscope itemtype="http://schema.org/WebPage">
  #     #{putContent(account, statusUpdates)}
  #     #{analytics()}
  #   </body>
  # </html>
  # """

putContent = (account, statusUpdates)=>
  profile      = getProfile account

  if statusUpdates is ""
    statusUpdates = """<div class="lazy-loader">#{profile.fullName} has not shared any posts yet.</div>"""

  numberOfLikes     = if account?.counts?.likes     then account.counts.likes     else "0"
  numberOfFollowers = if account?.counts?.followers then account.counts.followers else "0"
  numberOfFollowing = if account?.counts?.following then account.counts.following else "0"

  imgURL  = getAvatarImageUrl profile.hash, profile.avatar, 143
  content = """
  <section id="main-panel-wrapper">
    <div class='kdview kdtabpaneview content-display clearfix content-display-wrapper content-page active'>
      <div class="kdview member content-display">
        <aside class="kdview app-sidebar clearfix">
          <main itemscope itemtype="http://schema.org/Person">
            <a class="avatarview" href="/#{profile.nickname}" style="background-image: none; background-size: 143px 143px;">
              <img class="" width="143" height="143" src="#{imgURL}" style="opacity: 1;">
            </a>
            <h3 class="full-name">
              <span class="kdview kdcontenteditableview firstName">#{profile.firstName}</span>
              <span class="kdview kdcontenteditableview lastName">#{profile.lastName}</span>
            </h3>
          </main>
        </aside>
        <nav class="member-tabs"><a class="active" href="#">Posts</a></nav>
        <div class="app-content">
          <div class="kdview kdtabpaneview statuses clearfix active">
            <div class="kdview kdlistview kdlistview-default activity-related" itemscope itemtype="http://schema.org/UserComments">
              #{statusUpdates}
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
  """
  # content  =
  #   """
  #   <div id="kdmaincontainer" class="kdview">
  #     <section id="main-panel-wrapper" class="kdview">
  #       <div id="main-tab-view" class="kdview kdscrollview kdtabview">
  #         <div class="kdview kdtabpaneview content-display clearfix content-display-wrapper content-page active">
  #           <div class="kdview member content-display" style="min-height: 735px;">
  #             <div class="kdview profilearea clearfix">
  #               <div class="users-profile clearfix" itemscope itemtype="http://schema.org/Person">
  #                 <span class="avatarview" href="/#{profile.nickname}" style="width: 81px; height: 81px; background-size: 81px; background-image: none;">
  #                   <img class="" width="81" height="81" src="#{imgURL}" style="opacity: 1;" itemprop="image">
  #                 </span>
  #                 <h3 class="full-name">
  #                   <span class="kdview kdcontenteditableview firstName" itemprop="givenName">#{profile.firstName}</span>
  #                   <span class="kdview kdcontenteditableview lastName" itemprop="familyName">#{profile.lastName}</span>
  #                 </h3>
  #                 <div class="kdview kdcontenteditableview bio">
  #                   #{profile.about}
  #                 </div>
  #                 <div class="profilestats">
  #                   <a class="kdview" href="/#">
  #                     <span>#{numberOfFollowers}</span>Followers
  #                   </a>
  #                   <a class="kdview" href="/#">
  #                     <span>#{numberOfFollowing}</span>Following
  #                   </a>
  #                   <a class="kdview" href="/#">
  #                     <meta itemprop="interactionCount" content="UserLikes:#{numberOfLikes}"/>
  #                     <span>#{numberOfLikes}</span>Likes
  #                   </a>
  #                 </div>
  #               </div>
  #             </div>
  #             <div class="extra-wide">
  #               <div class="kdview kdtabview feeder-tabs">
  #                 <div class="kdview kdtabpaneview statuses clearfix active">
  #                   <div class="kdview kdlistview kdlistview-statuses activity-related">
  #                     <div class="kdview kdlistitemview kdlistitemview-activity" itemscope itemtype="http://schema.org/UserComments">
  #                       #{statusUpdates}
  #                     </div>
  #                   </div>
  #                 </div>
  #               </div>
  #             </div>
  #           </div>
  #         </div>
  #       </div>
  #     </section>
  #   </div>
  #   """

