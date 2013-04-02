
# install the kicker reporting script in the location where puppet
# looks for reporting scripts.

class kicker {
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $ruby_lib_path = "/usr/lib/ruby/vendor_ruby"
        }
        'CentOS','Fedora': {
            $ruby_lib_path = "/usr/lib/ruby/site_ruby/1.8"
        }
    }
    file {"$ruby_lib_path/puppet/reports/kick.rb":
        mode     => '0444',
        owner    => 'puppet',
        group    => 'puppet',
        source  => 'puppet:///modules/kicker/kick.rb',
    }
}
