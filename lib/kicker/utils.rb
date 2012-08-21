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
rescue NameError, LoadError
    # mcollective could be not installed yet. see http://projects.puppetlabs.com/issues/12594
    # in that case return a replacement that always returns an empty array
    module Kicker
        class Utils
            def self.get_rpc_client(agent, facts)
                return self.new
            end

            def method_missing(m, *args, &block)
                return []
            end
        end
    end
    
end
