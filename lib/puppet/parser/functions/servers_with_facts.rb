begin
  require 'puppet/rails'
  require 'puppet/rails/resource'
  require 'puppet/util/log'

  require "mcollective"
  
  module Puppet::Parser::Functions
    newfunction(:servers_with_facts,
    :type => :rvalue,
    :doc => "Return all server objects with all the facts specified.
    
    servers_with_facts('hostname=new') // returns servers with hostname new
    servers_with_facts('hostname=/^new$|^old$/') // returns servers with hostname either new or old
    servers_with_facts('uptime>10', 'hostname=/lala/') // returns servers with uptime over 10 and hostname matches lala
    " ) do |facts|
      
      log "fetching servers with facts #{facts.join(' ')}"
      
      environment ||= lookupvar("::environment")

      raise Puppet::ParseError, ("servers_with_facts(): wrong number of arguments (#{facts.length}; must be >= 1)") if facts.length < 1

      begin
        config = MCollective::Config.instance
        config.loadconfig("/etc/mcollective/client.cfg") unless config.configured

        filter = MCollective::Util.empty_filter
        filter['fact'] = facts.map {|x| MCollective::Util.parse_fact_string(x)}
        filter['agent'] << 'rpcutil'

        rpcclient = MCollective::RPC::Client.new('rpcutil')
        rpcclient.filter = filter

        results = []
        rpcclient.inventory() do |result|
            results << result[:body][:data][:facts]
        end

        return results
      rescue Exception => e 
        log "servers_with_facts(): an error occurred while querying for nodes #{e.message}"
        []
      end
    end
  end
  
  
  def log(msg)
    Puppet::Util::Log.create(
      :level   => :info,
      :message => msg,
      :source  => 'servers_with_role'
    )  
  end
  
rescue NameError
  # the puppet clients don't have any activerecord. see http://projects.puppetlabs.com/issues/12594
end