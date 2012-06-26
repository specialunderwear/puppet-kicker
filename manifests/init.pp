
# install the kicker reporting script in the location where puppet
# looks for reporting scripts.

class kicker {
    file {"/usr/lib/ruby/1.8/puppet/reports/kick.rb":
        mode     => '0444',
        owner    => 'puppet',
        group    => 'puppet',
        source  => 'puppet:///modules/kicker/kick.rb',
    }
}