
# Fetch version info from VERSION file
fs          = require 'fs'
nodePath    = require 'path'
versionFile = nodePath.join(__dirname, 'VERSION')
if fs.existsSync versionFile
  version = (fs.readFileSync versionFile, 'utf-8').trim()

KODING_VERSION    = version ? "0.0.1"

projects      =

  KDBackend   :
    files     : "client/Bongo/includes.coffee"
    script    : "website/a/js/bongo.#{KODING_VERSION}.js"
    sourceMapRoot : "Bongo/"

  KDMainApp   :
    files     : "client/Main/includes.coffee"
    style     : "website/a/css/__kdapp.#{KODING_VERSION}.css"
    script    : "website/a/js/__kdapp.#{KODING_VERSION}.js"
    sourceMapRoot : "Main/"

  HomeIntro   :
    files     : "client/Intro/includes.coffee"
    style     : "website/a/css/introapp.#{KODING_VERSION}.css"
    script    : "website/a/js/introapp.#{KODING_VERSION}.js"
    sourceMapRoot : "Intro/"

  Landing     :
    files     : "client/landing/includes.coffee"
    style     : "website/a/css/landingapp.#{KODING_VERSION}.css"
    script    : "website/a/js/landingapp.#{KODING_VERSION}.js"
    sourceMapRoot : "landing/"

  Activity        :
    files         : "client/Social/Activity/includes.coffee"
    style         : "website/a/css/__app.activity.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.activity.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Activity/"

  Members         :
    files         : "client/Social/Members/includes.coffee"
    style         : "website/a/css/__app.members.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.members.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Members/"

  Topics          :
    files         : "client/Social/Topics/includes.coffee"
    style         : "website/a/css/__app.topics.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.topics.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Topics/"

  Feeder          :
    files         : "client/Social/Feeder/includes.coffee"
    style         : "website/a/css/__app.feeder.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.feeder.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Feeder/"

  # Groups          :
  #   files         : "client/Groups/includes.coffee"
  #   style         : "website/a/css/__app.groups.#{KODING_VERSION}.css"
  #   script        : "website/a/js/__app.groups.#{KODING_VERSION}.js"
  #   sourceMapRoot : "Groups/"

  Account         :
    files         : "client/Account/includes.coffee"
    style         : "website/a/css/__app.account.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.account.#{KODING_VERSION}.js"
    sourceMapRoot : "Account/"

  Login           :
    files         : "client/Login/includes.coffee"
    style         : "website/a/css/__app.Login.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.Login.#{KODING_VERSION}.js"
    sourceMapRoot : "Login/"

  Apps            :
    files         : "client/Social/Apps/includes.coffee"
    style         : "website/a/css/__app.apps.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.apps.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Apps/"

  Terminal        :
    files         : "client/Terminal/includes.coffee"
    style         : "website/a/css/__app.terminal.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.terminal.#{KODING_VERSION}.js"
    sourceMapRoot : "Terminal/"

  Ace             :
    files         : "client/Ace/includes.coffee"
    style         : "website/a/css/__app.ace.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.ace.#{KODING_VERSION}.js"
    sourceMapRoot : "Ace/"

  Finder          :
    files         : "client/Finder/includes.coffee"
    style         : "website/a/css/__app.finder.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.finder.#{KODING_VERSION}.js"
    sourceMapRoot : "Finder/"

  Viewer          :
    files         : "client/Viewer/includes.coffee"
    style         : "website/a/css/__app.viewer.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.viewer.#{KODING_VERSION}.js"
    sourceMapRoot : "Viewer/"

  Workspace       :
    files         : "client/Workspace/includes.coffee"
    style         : "website/a/css/__app.workspace.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.workspace.#{KODING_VERSION}.js"
    sourceMapRoot : "Workspace/"

  CollaborativeWorkspace:
    files         : "client/CollaborativeWorkspace/includes.coffee"
    style         : "website/a/css/__app.collaborativeworkspace.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.collaborativeworkspace.#{KODING_VERSION}.js"
    sourceMapRoot : "CollaborativeWorkspace/"

  Teamwork        :
    files         : "client/Teamwork/includes.coffee"
    style         : "website/a/css/__app.teamwork.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.teamwork.#{KODING_VERSION}.js"
    sourceMapRoot : "Teamwork/"

  About           :
    files         : "client/About/includes.coffee"
    style         : "website/a/css/__app.about.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.about.#{KODING_VERSION}.js"
    sourceMapRoot : "About/"

  Business        :
    files         : "client/Business/includes.coffee"
    style         : "website/a/css/__app.business.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.business.#{KODING_VERSION}.js"
    sourceMapRoot : "Business/"

  Education       :
    files         : "client/Education/includes.coffee"
    style         : "website/a/css/__app.education.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.education.#{KODING_VERSION}.js"
    sourceMapRoot : "Education/"

  Environments    :
    files         : "client/Environments/includes.coffee"
    style         : "website/a/css/__app.environments.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.environments.#{KODING_VERSION}.js"
    sourceMapRoot : "Environments/"

  PostOperations  :
    files         : "client/PostOperations/includes.coffee"
    script        : "website/a/js/__client.post.#{KODING_VERSION}.js"

  Dashboard       :
    files         : "client/Dashboard/includes.coffee"
    style         : "website/a/css/__app.dashboard.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.dashboard.#{KODING_VERSION}.js"
    sourceMapRoot : "Dashboard/"

  Pricing         :
    files         : "client/Pricing/includes.coffee"
    style         : "website/a/css/__app.pricing.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.pricing.#{KODING_VERSION}.js"
    sourceMapRoot : "Pricing/"

  Demos           :
    files         : "client/Demos/includes.coffee"
    style         : "website/a/css/__app.demos.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.demos.#{KODING_VERSION}.js"
    sourceMapRoot : "Demos/"

  Bugs            :
    files         : "client/Social/Bugs/includes.coffee"
    style         : "website/a/css/__app.bugreport.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.bugreport.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Bugs/"

  DevTools        :
    files         : "client/DevTools/includes.coffee"
    style         : "website/a/css/__app.devtools.#{KODING_VERSION}.css"
    script        : "website/a/js/__app.devtools.#{KODING_VERSION}.js"
    sourceMapRoot : "DevTools/"

bundles           =

  Social          :
    projects      : ['Activity', 'Members', 'Topics', 'Apps', 'Bugs']
    style         : "website/a/css/__social.#{KODING_VERSION}.css"
    script        : "website/a/js/__social.#{KODING_VERSION}.js"

  Koding          :
    projects      : ['KDBackend', 'KDMainApp', 'Finder', 'Login', 'PostOperations']
    style         : "website/a/css/koding.#{KODING_VERSION}.css"
    script        : "website/a/js/koding.#{KODING_VERSION}.js"

  TeamworkBundle  :
    projects      : ['Ace', 'Terminal', 'Viewer', 'Workspace',
                     'CollaborativeWorkspace', 'Teamwork', 'DevTools']
    style         : "website/a/css/__teamwork.#{KODING_VERSION}.css"
    script        : "website/a/js/__teamwork.#{KODING_VERSION}.js"

  Payment         :
    projects      : ['Environments', 'Dashboard', 'Pricing', 'Account']
    style         : "website/a/css/__payment.#{KODING_VERSION}.css"
    script        : "website/a/js/__payment.#{KODING_VERSION}.js"

module.exports  = {projects, bundles}
