exports.workspace =

  title: 'Workspace'
  description:
    """
      <p>Following list provides key-bindings that are available in your <b>VM Workspaces.</b></p>
      <p>These include key combinations for easily <b>navigating</b> between split panes, quickly <b>opening/closing</b> documents and applications, <b>finding files</b> on your VM, and etc.</p>
    """
  data: require './workspace'


exports.activity =

  title: 'Activity'
  description:
    """
      <p>Following list provides key-bindings that are available in your <b>Activity Feeds.</b></p>
    """
  data: require './activity'


exports.editor =

  title: 'Editor'
  description:
    """
      <p>Following list provides key-bindings that are available in <b>Editor.</b>
    """
  data: require './editor'