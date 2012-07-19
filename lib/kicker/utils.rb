begin
    require 'mcollective'
    
    module Kicker
        module Utils
            def get_rpc_client(agent, facts)
                config = MCollective::Config.instance
                config.loadconfig(MCollective::Util.config_file_for_user) unless config.configured
                options = {
                    :disctimeout => 2,
                    :timeout => 5,
                    :verbose => false,
                    :filter => MCollective::Util.empty_filter,
                    :config => "/etc/mcollective/client.cfg",
                    :progress_bar => false,
                    :mcollective_limit_targets => false,
                    #        :batch_size => nil,
                    #        :batch_sleep_time => 1,
                }

                rpcclient = MCollective::RPC::Client.new(agent, :options => options)
                rpcclient.filter['fact'] = facts.map {|x| MCollective::Util.parse_fact_string(x)}
                rpcclient.filter['agent'] << agent
                return rpcclient
            end

            module_function :get_rpc_client
        end    
    end
rescue NameError
    # mcollective could be not installed yet. see http://projects.puppetlabs.com/issues/12594
end
