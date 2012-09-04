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

    $devel_pkgs = [
        "sqlite-devel",
        "openssl-devel",
        "libyaml-devel",
        "libxml2-devel",
        "libxslt-devel",
        "readline-devel",
        "zlib-devel",
        "fcgi-devel",
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
    ]
    
    package { $ruby18:
        ensure => installed,
    }

    package { $devel_pkgs:
	ensure => installed,
    }
    
    package { $ruby_gems:
        ensure => installed,
        provider => 'gem',
        require => [ Package[$ruby18],Package[$devel_pkgs] ],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
