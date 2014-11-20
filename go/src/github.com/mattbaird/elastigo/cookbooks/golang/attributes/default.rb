default[:golang] = {
  # can be "stable" or "tip"
  :version => "stable",
  :multi => {
    :versions => %w(go1.0.3 go1.1.1),
    :default_version  => "go1.1.1",
    :aliases => {
      "go1" => "go1.1.1"
    }
  }
}
