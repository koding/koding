projects =

  KDBackend       :
    path          : "client/Bongo"
    script        : "website/a/js/bongo.js"
    sourceMapRoot : "Bongo/"

  KDMainApp       :
    path          : "client/Main"
    style         : "website/a/css/__kdapp.css"
    script        : "website/a/js/__kdapp.js"
    sourceMapRoot : "Main/"

  Activity        :
    path          : "client/Social/Activity"
    style         : "website/a/css/__app.activity.css"
    script        : "website/a/js/__app.activity.js"
    sourceMapRoot : "Social/Activity/"

  Members         :
    path          : "client/Social/Members"
    style         : "website/a/css/__app.members.css"
    script        : "website/a/js/__app.members.js"
    sourceMapRoot : "Social/Members/"

  Feeder          :
    path          : "client/Social/Feeder"
    style         : "website/a/css/__app.feeder.css"
    script        : "website/a/js/__app.feeder.js"
    sourceMapRoot : "Social/Feeder/"

  Account         :
    path          : "client/Account"
    style         : "website/a/css/__app.account.css"
    script        : "website/a/js/__app.account.js"
    sourceMapRoot : "Account/"

  Login           :
    path          : "client/Login"
    style         : "website/a/css/__app.Login.css"
    script        : "website/a/js/__app.Login.js"
    sourceMapRoot : "Login/"

  Apps            :
    path          : "client/Social/Apps"
    style         : "website/a/css/__app.apps.css"
    script        : "website/a/js/__app.apps.js"
    sourceMapRoot : "Social/Apps/"

  Kites           :
    path          : "client/Social/Kites"
    style         : "website/a/css/__app.kites.css"
    script        : "website/a/js/__app.kites.js"
    sourceMapRoot : "Social/Kites/"

  Terminal        :
    path          : "client/Terminal"
    style         : "website/a/css/__app.terminal.css"
    script        : "website/a/js/__app.terminal.js"
    sourceMapRoot : "Terminal/"

  Ace             :
    path          : "client/Ace"
    style         : "website/a/css/__app.ace.css"
    script        : "website/a/js/__app.ace.js"
    sourceMapRoot : "Ace/"

  Finder          :
    path          : "client/Finder"
    style         : "website/a/css/__app.finder.css"
    script        : "website/a/js/__app.finder.js"
    sourceMapRoot : "Finder/"

  Viewer          :
    path          : "client/Viewer"
    style         : "website/a/css/__app.viewer.css"
    script        : "website/a/js/__app.viewer.js"
    sourceMapRoot : "Viewer/"

  Teamwork        :
    path          : "client/Teamwork"
    style         : "website/a/css/__app.teamwork.css"
    script        : "website/a/js/__app.teamwork.js"
    sourceMapRoot : "Teamwork/"

  IDE             :
    path          : "client/IDE"
    style         : "website/a/css/__app.ide.css"
    script        : "website/a/js/__app.ide.js"
    sourceMapRoot : "IDE/"

  About           :
    path          : "client/About"
    style         : "website/a/css/__app.about.css"
    script        : "website/a/js/__app.about.js"
    sourceMapRoot : "About/"

  Home            :
    path          : "client/Home"
    style         : "website/a/css/__app.home.css"
    script        : "website/a/js/__app.home.js"
    sourceMapRoot : "Home/"

  Business        :
    path          : "client/Business"
    style         : "website/a/css/__app.business.css"
    script        : "website/a/js/__app.business.js"
    sourceMapRoot : "Business/"

  Education       :
    path          : "client/Education"
    style         : "website/a/css/__app.education.css"
    script        : "website/a/js/__app.education.js"
    sourceMapRoot : "Education/"

  Environments    :
    path          : "client/Environments"
    style         : "website/a/css/__app.environments.css"
    script        : "website/a/js/__app.environments.js"
    sourceMapRoot : "Environments/"

  PostOperations  :
    path          : "client/PostOperations"
    script        : "website/a/js/__client.post.js"

  Dashboard       :
    path          : "client/Dashboard"
    style         : "website/a/css/__app.dashboard.css"
    script        : "website/a/js/__app.dashboard.js"
    sourceMapRoot : "Dashboard/"

  Pricing         :
    path          : "client/Pricing"
    style         : "website/a/css/__app.pricing.css"
    script        : "website/a/js/__app.pricing.js"
    sourceMapRoot : "Pricing/"

  Bugs            :
    path          : "client/Social/Bugs"
    style         : "website/a/css/__app.bugreport.css"
    script        : "website/a/js/__app.bugreport.js"
    sourceMapRoot : "Social/Bugs/"

  DevTools        :
    path          : "client/DevTools"
    style         : "website/a/css/__app.devtools.css"
    script        : "website/a/js/__app.devtools.js"
    sourceMapRoot : "DevTools/"

bundles           =

  Koding          :
    projects      : [
                     'KDBackend'
                     'KDMainApp'
                     'Login'
                     'PostOperations'
                    ]

    style         : "website/a/css/koding.css"
    script        : "website/a/js/koding.js"

  TeamworkBundle  :
    projects      : ['Viewer', 'Teamwork', 'DevTools']
    style         : "website/a/css/__teamwork.css"
    script        : "website/a/js/__teamwork.js"

  IDEBundle       :
    projects      : ['Ace', 'Terminal', 'Viewer', 'IDE']
    style         : "website/a/css/__ide.css"
    script        : "website/a/js/__ide.js"

module.exports  = {projects, bundles}
