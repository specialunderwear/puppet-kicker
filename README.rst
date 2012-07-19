puppet-kicker: cross server puppet notifications
================================================

puppet-kicker requires
`mcollective <http://marionette-collective.org/>`_
with the
`puppetd plugin <http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/AgentPuppetd>`_
for querying and notifying servers. Be sure to export all your facter/puppet
facts to mcollective.
(`FactsFacterYAML <http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/FactsFacterYAML>`_ for example)

*Puppet-kicker triggers runs of* ``puppet agent`` *on dependent servers.*

Suppose we've got a
loadbalancer and some nodes that need to be balanced. With puppet-kicker that
pattern looks like this;

On the node, you've got to make sure a fact is available with the name ``role``.
See :ref:`cloudstack` for an example of how to achive this for
`cloudstack <http://www.cloudstack.org/>`_. After that all it takes is

::

    # kick haproxy so it rebuilds it config.
    notify {"kick -> haproxy":}

on the server the ``role`` fact should also be defined and set to 'haproxy'

::

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
    
and the configfile would look like this

::
    
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

To enable the kicker, you should add the ``kick`` to your reports in puppet.conf::

    reports=log, kick

.. _cloudstack:

Available functions
-------------------

These functions alwats return a list of dictionaries containing all the server
facts.

- servers_with_role: Return all server objects with a certain role:
    servers_with_role('frontend', 'production)
- servers_with_facts:     Return all server objects with all the facts specified.
    servers_with_facts('hostname=new') // returns servers with hostname new
    servers_with_facts('hostname=/^new$|^old$/') // returns servers with hostname either new or old
    servers_with_facts('uptime>10', 'hostname=/lala/') // returns servers with uptime over 10 and hostname matches lala

cloudstack
----------

Because we use this with cloudstack, we added
`Jason Hancock <http://geek.jasonhancock.com>`_ his userdata-to-puppetfact
script so we can make the ``role`` userdata available on each server as a puppet fact.
doing this allows us to use that fact as a node classifier instead of an
external node classifier.

In nodes.pp we use the role to classify the node like this::

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
not to introduce cyclic kicks.

in node.pp::

    notify {"kick -> haproxy":}

in haproxy.pp::

    notify {"kick -> node":}

That will keep your puppet agents running forever.

We need cycle detection though, so stay tuned for an update.
