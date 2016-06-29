module.exports = {

  'project_create'           : {
    'created_at'             : '2012-07-21T07:30:54Z'
    'updated_at'             : '2012-07-21T07:38:22Z'
    'event_name'             : 'project_create'
    'name'                   : 'StoreCloud'
    'owner_email'            : 'johnsmith@gmail.com'
    'owner_name'             : 'John Smith'
    'path'                   : 'storecloud'
    'path_with_namespace'    : 'jsmith/storecloud'
    'project_id'             : 74
    'project_visibility'     : 'private'
  }

  'project_destroy'          : {
    'created_at'             : '2012-07-21T07:30:58Z'
    'updated_at'             : '2012-07-21T07:38:22Z'
    'event_name'             : 'project_destroy'
    'name'                   : 'Underscore'
    'owner_email'            : 'johnsmith@gmail.com'
    'owner_name'             : 'John Smith'
    'path'                   : 'underscore'
    'path_with_namespace'    : 'jsmith/underscore'
    'project_id'             : 73
    'project_visibility'     : 'internal'
  }

  'project_rename'           : {
    'created_at'             : '2012-07-21T07:30:58Z'
    'updated_at'             : '2012-07-21T07:38:22Z'
    'event_name'             : 'project_rename'
    'name'                   : 'Underscore'
    'path'                   : 'underscore'
    'path_with_namespace'    : 'jsmith/underscore'
    'project_id'             : 73
    'owner_name'             : 'John Smith'
    'owner_email'            : 'johnsmith@gmail.com'
    'project_visibility'     : 'internal'
    'old_path_with_namespace': 'jsmith/overscore'
  }

  'project_transfer'         : {
    'created_at'             : '2012-07-21T07:30:58Z'
    'updated_at'             : '2012-07-21T07:38:22Z'
    'event_name'             : 'project_transfer'
    'name'                   : 'Underscore'
    'path'                   : 'underscore'
    'path_with_namespace'    : 'scores/underscore'
    'project_id'             : 73
    'owner_name'             : 'John Smith'
    'owner_email'            : 'johnsmith@gmail.com'
    'project_visibility'     : 'internal'
    'old_path_with_namespace': 'jsmith/overscore'
  }

  # ----------------

  'user_add_to_team'              : {
    'created_at'                  : '2012-07-21T07:30:56Z'
    'updated_at'                  : '2012-07-21T07:38:22Z'
    'event_name'                  : 'user_add_to_team'
    'project_access'              : 'Master'
    'project_id'                  : 74
    'project_name'                : 'StoreCloud'
    'project_path'                : 'storecloud'
    'project_path_with_namespace' : 'jsmith/storecloud'
    'user_email'                  : 'johnsmith@gmail.com'
    'user_name'                   : 'John Smith'
    'user_username'               : 'johnsmith'
    'user_id'                     : 41
    'project_visibility'          : 'private'
  }


  # ----------------

  'tag_push'                 : {
    'event_name'             : 'tag_push'
    'before'                 : '0000000000000000000000000000000000000000'
    'after'                  : '82b3d5ae55f7080f1e6022629cdb57bfae7cccc7'
    'ref'                    : 'refs/tags/v1.0.0'
    'checkout_sha'           : '5937ac0a7beb003549fc5fd26fc247adbce4a52e'
    'user_id'                : 1
    'user_name'              : 'John Smith'
    'user_avatar'            : 'https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80'
    'project_id'             : 1
    'project'                : {
      'name'                 : 'Example'
      'description'          : ''
      'web_url'              : 'http://example.com/jsmith/example'
      'avatar_url'           : null
      'git_ssh_url'          : 'git@example.com:jsmith/example.git'
      'git_http_url'         : 'http://example.com/jsmith/example.git'
      'namespace'            : 'Jsmith'
      'visibility_level'     : 0
      'path_with_namespace'  : 'jsmith/example'
      'default_branch'       : 'master'
      'homepage'             : 'http://example.com/jsmith/example'
      'url'                  : 'git@example.com:jsmith/example.git'
      'ssh_url'              : 'git@example.com:jsmith/example.git'
      'http_url'             : 'http://example.com/jsmith/example.git'
    }
    'repository'             : {
      'name'                 : 'Example'
      'url'                  : 'ssh://git@example.com/jsmith/example.git'
      'description'          : ''
      'homepage'             : 'http://example.com/jsmith/example'
      'git_http_url'         : 'http://example.com/jsmith/example.git'
      'git_ssh_url'          : 'git@example.com:jsmith/example.git'
      'visibility_level'     : 0
    }
    'commits'                : []
    'total_commits_count'    : 0
  }

  # --------------

  'push'                     : {
    'event_name'             : 'push'
    'before'                 : '95790bf891e76fee5e1747ab589903a6a1f80f22'
    'after'                  : 'da1560886d4f094c3e6c9ef40349f7d38b5d27d7'
    'ref'                    : 'refs/heads/master'
    'checkout_sha'           : 'da1560886d4f094c3e6c9ef40349f7d38b5d27d7'
    'user_id'                : 4
    'user_name'              : 'John Smith'
    'user_email'             : 'john@example.com'
    'user_avatar'            : 'https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80'
    'project_id'             : 15
    'project'                : {
      'name'                 : 'Diaspora'
      'description'          : 'diaspora description'
      'web_url'              : 'http://example.com/mike/diaspora'
      'avatar_url'           : null
      'git_ssh_url'          : 'git@example.com:mike/diaspora.git'
      'git_http_url'         : 'http://example.com/mike/diaspora.git'
      'namespace'            : 'Mike'
      'visibility_level'     : 0
      'path_with_namespace'  : 'mike/diaspora'
      'default_branch'       : 'master'
      'homepage'             : 'http://example.com/mike/diaspora'
      'url'                  : 'git@example.com:mike/diaspora.git'
      'ssh_url'              : 'git@example.com:mike/diaspora.git'
      'http_url'             : 'http://example.com/mike/diaspora.git'
    }
    'repository'             : {
      'name'                 : 'Diaspora'
      'url'                  : 'git@example.com:mike/diaspora.git'
      'description'          : 'diaspora description'
      'homepage'             : 'http://example.com/mike/diaspora'
      'git_http_url'         : 'http://example.com/mike/diaspora.git'
      'git_ssh_url'          : 'git@example.com:mike/diaspora.git'
      'visibility_level'     : 0
    }
    'commits'                : []
    'total_commits_count'    : 0
  }
}
