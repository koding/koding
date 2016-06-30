# Events from GitLab System Hooks
# Extracted from http://docs.gitlab.com/ee/system_hooks/system_hooks.html

module.exports = KNOWN_EVENTS = [
  'project_create'
  'project_destroy'
  'project_rename'
  'project_transfer'
  # 'user_add_to_group'
  # 'user_remove_from_group'
  # 'user_add_to_team'
  # 'user_remove_from_team'
  # 'user_create'
  # 'user_destroy'
  'key_create'
  'key_destroy'
  'group_create'
  'group_destroy'
  'tag_push'
  'push'
]

SCOPE = {

  _common: [ 'created_at', 'updated_at' ]

  project: {
    create: [
      'name'
      'owner_email'
      'path_with_namespace'
      'project_visibility'
    ]
    destroy: [
      'name'
      'owner_email'
      'path_with_namespace'
      'project_visibility'
    ]
    rename: [
      'name'
      'owner_email'
      'path_with_namespace'
      'old_path_with_namespace'
      'project_visibility'
    ]
    transfer: [
      'name'
      'owner_email'
      'path_with_namespace'
      'old_path_with_namespace'
      'project_visibility'
    ]
  }

  user: {
    create: [
      'username'
      'email'
      'name'
    ]
    destroy: [
      'username'
      'email'
      'name'
    ]
    add_to_team: [
      'project_path_with_namespace'
      'user_username'
      'user_email'
    ]
    remove_from_team: [
      'project_path_with_namespace'
      'user_username'
      'user_email'
    ]
    add_to_group: [
      'group_path'
      'group_access'
      'user_name'
      'user_email'
      'user_username'
    ]
    remove_from_group: [
      'group_path'
      'group_access'
      'user_name'
      'user_email'
      'user_username'
    ]
  }

  key: {
    create: [
      'username'
      'key'
    ]
    destroy: [
      'username'
      'key'
    ]
  }

  group: {
    create: [
      'name'
      'path'
      'owner_email'
      'owner_name'
    ]
    destroy: [
      'name'
      'path'
      'owner_email'
      'owner_name'
    ]
  }

  tag: {
    push: [
      'ref'
      'user_email'
      'checkout_sha'
      'project: { name: project_name }'
      'project: { path_with_namespace: project_path_with_namespace }'
      'project: { commits: project_commits }'
    ]
  }

  push: {
    main: [
      'ref'
      'user_email'
      'checkout_sha'
      'project: { name: project_name }'
      'project: { path_with_namespace: project_path_with_namespace }'
      'project: { commits: project_commits }'
    ]
  }

}
