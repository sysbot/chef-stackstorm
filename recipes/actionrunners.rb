#
# Cookbook Name:: stackstorm
# Recipe:: actionrunners
#
# Copyright (C) 2015 StackStorm (info@stackstorm.com)
#

# Recipe brings up StackStorm action runner system services.
#

self.send :extend, StackstormCookbook::RecipeHelpers
return unless apply_components.include?('st2actions')

include_recipe "stackstorm::install_#{node['stackstorm']['install_method']}"
include_recipe 'stackstorm::config'

workers = Array(1..node['stackstorm']['action_runners'].to_i) << nil
service_provider = self.service_provider

# register actions
register_content(:actions)

service_bin = 'st2actionrunner'
service_bin = "#{node['stackstorm']['bin_dir']}/#{service_bin}"

workers.each do |num|
  service_name = num ? "st2actionrunner-#{num}" : "st2actionrunner"
  template_source = num ? "#{service_provider}/st2-action-runner-i.erb" :
      "#{service_provider}/st2-action-runner.erb"

  stackstorm_service service_name do
    source template_source
    variables lazy {
      Mash.new({
        service_name: service_name,
        run_user: 'root',
        run_group: 'root',
        service_bin: service_bin,
        etc_dir: node['stackstorm']['etc_dir'],
        log_dir: node['stackstorm']['log_dir'],
        config_file: node['stackstorm']['conf_path'],
        python: node['stackstorm']['python_binary']
      })
    }
  end
end
