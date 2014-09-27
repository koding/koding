projects =

  KDBackend       :
    path          : "client/Bongo"
    script        : "website/a/js/bongo.js"
    sourceMapRoot : "Bongo/"

  Core            :
    path          : 'client/Core'
    style         : 'website/a/css/__core.css'
    script        : 'website/a/js/__core.js'
    sourceMapRoot : 'Core/'

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

  IDE             :
    path          : "client/IDE"
    style         : "website/a/css/__app.ide.css"
    script        : "website/a/js/__app.ide.js"
    sourceMapRoot : "IDE/"

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

  Features        :
    path          : "client/Features"
    style         : "website/a/css/__app.features.css"
    script        : "website/a/js/__app.features.js"
    sourceMapRoot : "Features/"

bundles           =

  KodingIn        :
    projects      : [
                     'KDBackend'
                     'Core'
                     'KDMainApp'
                     'Activity'
                     'PostOperations'
                    ]

    style         : "website/a/css/koding.css"
    script        : "website/a/js/koding.js"

  IDEBundle       :
    projects      : ['Ace', 'Terminal', 'Finder', 'Viewer', 'IDE']
    style         : "website/a/css/__ide.css"
    script        : "website/a/js/__ide.js"

module.exports  = {projects, bundles}
