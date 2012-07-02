puppet-kicker: cross server puppet notifications
================================================

puppet-kicker requires exported resources to be enabled!

Puppet-kicker runs ``puppet kick`` on dependent servers. Suppose we've got a
loadbalancer and some nodes that need to be balanced. With puppet-kicker that
pattern looks like this;

on the node::

    # export the server info as a resource
    # 'node' is the server's *role*
    @@server {"node":
        fqdn => $fqdn,
        hostname => $hostname,
        ipaddress => $ipaddress,
    }
    
    # kick haproxy so it rebuilds it config.
    notify {"kick -> haproxy":}

on the server::

    # collect all the servers with *role* `node`.
    $nodes = servers_with_role('node')
    
    # render a template in wich we use these servers.
    $configfile = template('path-to-template/configfile.erb')
    
    package {"haproxy":
        ensure => installed,
    }
    
    file {"/etc/haproxy/haproxy.cfg":
        content => $configfile
        notify => Service['haproxy'],
        require => Package['haproxy'],
    }
    
    service {"haproxy":
        ensure => running,
    }
    
    # export the server so we can find it for kicking.
    @@server {"haproxy":
        fqdn => $fqdn,
        hostname => $hostname,
        ipaddress => $ipaddress,
    }

and the configfile would look like this::
    
    global 
          maxconn 4096 
          pidfile /var/run/haproxy.pid 
          daemon 

    defaults 
          mode http 
          retries 3 
          option redispatch 
          maxconn 2000 
          contimeout 5000 
          clitimeout 50000 
          srvtimeout 50000 

    listen <%= @hostname -%>
          bind 0.0.0.0:80
          mode tcp 
          balance roundrobin
          <% nodes.each do node %>
          server <% = node['hostname'] -%> <% node['ipaddress'] -%>:8080 check inter 2000
          <% end -%>

So puppet kicker gives you:

a resource type called ``server`` that should be exported for servers you want
to collect with ``servers_with_role``.

To enable the kicker, you should add the ``kick`` to your reports in puppet.conf::

    reports=log, kick

cloudstack
----------

Because we use this with cloudstack, we added
`Jason Hancock <http://geek.jasonhancock.com>`_ his userdata-to-puppetfact
script so we can make the role available on each server as a puppet fact.
doing this allows us to use that fact as a node classifier instead of an
external node classifier. In practice that means we actually export our
``server`` resources like this::

    @@server {$role:
        fqdn => $fqdn,
        hostname => $hostname,
        ipaddress => $ipaddress,
    }

and in nodes.pp we use the role to classify the node like this::

    case $role {
        'haproxy': {
            include haproxy
        }

        'node': {
            include node
        }
    }

caveats
-------

There is no cycle detection built into the kicker. So you've got to be careful
not to introduce cylclic kicks.

in node.pp::

    notify {"kick -> haproxy":}

in haproxy.pp::

    notify {"kick -> node":}

That will keep your puppet agents running forever.
