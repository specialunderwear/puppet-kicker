require 'puppet/rails'
require 'puppet/util/log'
require 'puppet/reports'

require 'kicker/utils'
require 'facter'

$env = nil
env_fact = Facter["environment"]
if env_fact
    $env = env_fact.value()
end

# Reporting class which will trigger puppet runs on dependent servers.
# any server can trigger a run of another server by including:
#
# notify{"kick -> role":}
# 
# in it's puppet config
# 
# WATCH OUT THAT YOU ARE NOT CREATING CYCLES OF DEPENDENT SERVERS, WHICH LEADS
# TO INFINITE PUPPET RUNS

Puppet::Reports.register_report(:kick) do
  desc "kick dependent services."

  def process
    if not $env
        $env = self.environment
    end
    log "Kicker post processing for #{self.host} in environment #{$env}"

    # find all statusses of type Notify which matches the "kick ->" pattern
    changes = self.resource_statuses.find_all do |status|
      name, status = status
      status.changed? and status.resource_type == "Notify" and status.title =~ /^kick ->/
    end

    # find all the servers with the role defined in the "kick -> role" pattern
    # and run 'puppet kick' to trigger a puppet run.
    changes.each do |name, status|
      log "Status changed: #{name} #{status} #{status.title} #{status.resource_type}"
      log "kick role name: #{status.title[8..-1]}"
      puppetd = Kicker::Utils.get_rpc_client('puppetd', ["role=#{status.title[8..-1]}"], $env)
      puppetd.runonce()
    end
  end

  def log(msg)
    Puppet::Util::Log.create(
      :level   => :info,
      :message => msg,
      :source  => self.host
    )
  end

end
