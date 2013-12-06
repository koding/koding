
# Fetch version info from VERSION file
fs          = require 'fs'
nodePath    = require 'path'
versionFile = nodePath.join(__dirname, 'VERSION')
if fs.existsSync versionFile
  version = (fs.readFileSync versionFile, 'utf-8').trim()

FRAMEWORK_VERSION = version ? "0.0.1"
KODING_VERSION    = version ? "0.0.1"

projects      =

  KDFramework :
    files     : "client/Framework/includes.coffee"
    style     : "website/css/kd.#{FRAMEWORK_VERSION}.css"
    script    : "website/js/kd.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Framework/"

  KDBackend   :
    files     : "client/Bongo/includes.coffee"
    script    : "website/js/bongo.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Bongo/"

  KDMainApp   :
    files     : "client/Main/includes.coffee"
    style     : "website/css/__kdapp.#{KODING_VERSION}.css"
    script    : "website/js/__kdapp.#{KODING_VERSION}.js"
    sourceMapRoot : "Main/"

  HomeIntro   :
    files     : "client/Intro/includes.coffee"
    style     : "website/css/introapp.#{KODING_VERSION}.css"
    script    : "website/js/introapp.#{KODING_VERSION}.js"
    sourceMapRoot : "introapp/"

  Landing     :
    files     : "client/landing/includes.coffee"
    style     : "website/css/landingapp.#{KODING_VERSION}.css"
    script    : "website/js/landingapp.#{KODING_VERSION}.js"
    sourceMapRoot : "landing/"

  Activity        :
    files         : "client/Social/Activity/includes.coffee"
    style         : "website/css/__app.activity.#{KODING_VERSION}.css"
    script        : "website/js/__app.activity.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Activity/"

  Members         :
    files         : "client/Social/Members/includes.coffee"
    style         : "website/css/__app.members.#{KODING_VERSION}.css"
    script        : "website/js/__app.members.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Members/"

  Topics          :
    files         : "client/Social/Topics/includes.coffee"
    style         : "website/css/__app.topics.#{KODING_VERSION}.css"
    script        : "website/js/__app.topics.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Topics/"

  Feeder          :
    files         : "client/Social/Feeder/includes.coffee"
    style         : "website/css/__app.feeder.#{KODING_VERSION}.css"
    script        : "website/js/__app.feeder.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Feeder/"

  # Groups          :
  #   files         : "client/Groups/includes.coffee"
  #   style         : "website/css/__app.groups.#{KODING_VERSION}.css"
  #   script        : "website/js/__app.groups.#{KODING_VERSION}.js"
  #   sourceMapRoot : "Groups/"

  Account         :
    files         : "client/Account/includes.coffee"
    style         : "website/css/__app.account.#{KODING_VERSION}.css"
    script        : "website/js/__app.account.#{KODING_VERSION}.js"
    sourceMapRoot : "Account/"

  Login           :
    files         : "client/Login/includes.coffee"
    style         : "website/css/__app.Login.#{KODING_VERSION}.css"
    script        : "website/js/__app.Login.#{KODING_VERSION}.js"
    sourceMapRoot : "Login/"

  Apps            :
    files         : "client/Social/Apps/includes.coffee"
    style         : "website/css/__app.apps.#{KODING_VERSION}.css"
    script        : "website/js/__app.apps.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Apps/"

  Terminal        :
    files         : "client/Terminal/includes.coffee"
    style         : "website/css/__app.terminal.#{KODING_VERSION}.css"
    script        : "website/js/__app.terminal.#{KODING_VERSION}.js"
    sourceMapRoot : "Terminal/"

  Ace             :
    files         : "client/Ace/includes.coffee"
    style         : "website/css/__app.ace.#{KODING_VERSION}.css"
    script        : "website/js/__app.ace.#{KODING_VERSION}.js"
    sourceMapRoot : "Ace/"

  Finder          :
    files         : "client/Finder/includes.coffee"
    style         : "website/css/__app.finder.#{KODING_VERSION}.css"
    script        : "website/js/__app.finder.#{KODING_VERSION}.js"
    sourceMapRoot : "Finder/"

  Viewer          :
    files         : "client/Viewer/includes.coffee"
    style         : "website/css/__app.viewer.#{KODING_VERSION}.css"
    script        : "website/js/__app.viewer.#{KODING_VERSION}.js"
    sourceMapRoot : "Viewer/"

  Workspace       :
    files         : "client/Workspace/includes.coffee"
    style         : "website/css/__app.workspace.#{KODING_VERSION}.css"
    script        : "website/js/__app.workspace.#{KODING_VERSION}.js"
    sourceMapRoot : "Workspace/"

  CollaborativeWorkspace:
    files         : "client/CollaborativeWorkspace/includes.coffee"
    style         : "website/css/__app.collaborativeworkspace.#{KODING_VERSION}.css"
    script        : "website/js/__app.collaborativeworkspace.#{KODING_VERSION}.js"
    sourceMapRoot : "CollaborativeWorkspace/"

  Teamwork        :
    files         : "client/Teamwork/includes.coffee"
    style         : "website/css/__app.teamwork.#{KODING_VERSION}.css"
    script        : "website/js/__app.teamwork.#{KODING_VERSION}.js"
    sourceMapRoot : "Teamwork/"

  About           :
    files         : "client/About/includes.coffee"
    style         : "website/css/__app.about.#{KODING_VERSION}.css"
    script        : "website/js/__app.about.#{KODING_VERSION}.js"
    sourceMapRoot : "About/"

  Environments    :
    files         : "client/Environments/includes.coffee"
    style         : "website/css/__app.environments.#{KODING_VERSION}.css"
    script        : "website/js/__app.environments.#{KODING_VERSION}.js"
    sourceMapRoot : "Environments/"

  PostOperations  :
    files         : "client/PostOperations/includes.coffee"
    script        : "website/js/__client.post.#{KODING_VERSION}.js"

  Dashboard       :
    files         : "client/Dashboard/includes.coffee"
    style         : "website/css/__app.dashboard.#{KODING_VERSION}.css"
    script        : "website/js/__app.dashboard.#{KODING_VERSION}.js"
    sourceMapRoot : "Dashboard/"


bundles           =

  Social          :
    projects      : ['Activity', 'Members', 'Topics', 'Apps']
    style         : "website/css/__social.#{KODING_VERSION}.css"
    script        : "website/js/__social.#{KODING_VERSION}.js"

  Koding          :
    projects      : ['KDBackend', 'KDMainApp', 'Finder', 'Login', 'PostOperations']
    style         : "website/css/koding.#{KODING_VERSION}.css"
    script        : "website/js/koding.#{KODING_VERSION}.js"

  TeamworkBundle  :
    projects      : ['Ace', 'Terminal', 'Viewer', 'Workspace', 'CollaborativeWorkspace', 'Teamwork']
    style         : "website/css/__teamwork.#{KODING_VERSION}.css"
    script        : "website/js/__teamwork.#{KODING_VERSION}.js"

  Payment         :
    projects      : ['Environments', 'Dashboard']
    style         : "website/css/__payment.#{KODING_VERSION}.css"
    script        : "website/js/__payment.#{KODING_VERSION}.js"

module.exports  = {projects, bundles}
