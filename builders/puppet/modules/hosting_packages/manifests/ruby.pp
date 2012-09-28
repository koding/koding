# Class: hosting_packages::ruby
#
#
class hosting_packages::ruby {
    
    # modules installed from RPM
    #$ruby_modules = ["ruby-mysql","ruby-sqlite3","ruby-devel","ruby19-devel","ruby-irb","ruby19-irb","rubygems","rubygems19","ruby-rdoc","rubygem19-rdoc"]
    $ruby18 = [
        "ruby",
        "ruby-devel",
        "ruby-libs",
        "rubygems",
        "ruby-irb",
    ]
    $ruby19 = [
        "ruby19",
        "ruby19-libs",
    ]


    $devel_pkgs = [
        "sqlite-devel",
        "openssl-devel",
        "libyaml-devel",
        "libxml2-devel",
        "libxslt-devel",
        "readline-devel",
        "zlib-devel",
        "fcgi-devel",
        "augeas-devel",
    ]

    $ruby_gems = [
        'ruby-hmac',
        'addressable',
        "shadow",
        'rake',
        'mysql2',
        'rake-compiler',
        'coffee-script-source',
        'execjs',
        'coffee-script',
        'json',
        'coffee-rails',
        'jquery-rails',
        'sass',
        'sass-rails',
        'sqlite3',
        'uglifier',
        'fcgi',
        'nokogiri',
        'bundler',
        'i18n',
        'mime-types',
        'multi_json',
        'builder',
        'rack-cache',
        'rack-test',
        'tilt',
        'sprockets',
        'actionpack',
        'polyglot',
        'treetop',
        'mail',
        'actionmailer',
        'activeresource',
        'rails',
        'ruby-augeas',
    ]
    $ruby19_gems = [
        'ruby-hmac-19',
        'addressable-19',
        'rake-19',
        'mysql2-19',
        'rake-compiler-19',
        'coffee-script-source-19',
        'execjs-19',
        'coffee-script-19',
        'json-19',
        'coffee-rails-19',
        'jquery-rails-19',
        'sass-19',
        'sass-rails-19',
        'sqlite3-19',
        'uglifier-19',
        'fcgi-19',
        'nokogiri-19',
        'bundler-19',
        'i18n-19',
        'mime-types-19',
        'multi_json-19',
        'builder-19',
        'rack-cache-19',
        'rack-test-19',
        'tilt-19',
        'sprockets-19',
        'actionpack-19',
        'polyglot-19',
        'treetop-19',
        'mail-19',
        'actionmailer-19',
        'activeresource-19',
        'rails-19',
        'ruby-augeas-19',
    ]
   
    package { $ruby18:
        ensure => installed,
    }
    package { $ruby19:
        ensure => installed,
        require => Class["yumrepos::koding"],
    }


    package { $devel_pkgs:
	    ensure => installed,
    }
    
    package { $ruby_gems:
        ensure => installed,
        provider => 'gem',
        require => [ Package[$ruby18],Package[$devel_pkgs],Class["yumrepos::epel"] ],
        notify => Class["cloudlinux::cagefs_update"]
    }
    package { $ruby19_gems:
        ensure => installed,
        provider => 'gem19',
        require => [ Package[$ruby19],Package[$devel_pkgs],Class["yumrepos::epel"] ],
        notify => Class["cloudlinux::cagefs_update"]
    }

    file { '/opt/ruby19/lib64/ruby/1.9.1/fcgi.so':
       ensure => 'link',
       target => '/opt/ruby19/lib64/ruby/gems/1.9.1/gems/fcgi-0.8.8/lib/fcgi.so',
       require => Package[$ruby19_gems]
    }
    file { '/usr/bin/ruby1.9':
       ensure => 'link',
       target => '/opt/ruby19/bin/ruby1.9',
       require => Package[$ruby19]
    }

}
