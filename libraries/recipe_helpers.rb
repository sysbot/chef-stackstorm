module StackstormCookbook
  module RecipeHelpers

    def stackstorm_service(service_name, &block)
      init_path = service_init_path(service_name)
      service_provider = self.service_provider

      template "#{recipe_name} :create init template for #{service_name}" do
        path init_path
        source "#{service_provider}/st2-init.erb"
        cookbook 'stackstorm'
        action :create
        case service_provider
        when :debian, :redhat
          mode '0755'
        end
      end.instance_eval(&block)

      service "#{recipe_name} enable and start StackStorm service #{service_name}" do
        service_name service_name
        provider Chef::Provider::Service.const_get(service_provider.to_s.capitalize)
        action [ :enable, :start ]
      end
    end

    # Service provider mapping
    def service_provider
      @service_provider ||= begin
        klass = Chef::Platform.find_provider(node.platform,
                                  node.platform_version, :service)
        svcprovider = klass.name.split('::').last.downcase.to_sym
        supported = [ :upstart, :debian, :systemd ]
        case node.platform
        when 'ubuntu'
          :upstart
        when 'debian'
          :debian
        else
          if supported.include?(svcprovider)
            svcprovider
          else
            NotImplementedError.new("platform #{node[:platform]} " <<
                        "#{node[:platform_version]} not supported")
          end
        end
      end
    end

    def service_init_path(svc_name)
      case service_provider
      when :upstart
        "/etc/init/#{svc_name}.conf"
      when :systemd
        "/usr/lib/systemd/system/#{svc_name}.service"
      when :debian
        "/etc/init.d/#{svc_name}"
      end
    end

    def register_content(opt_list)
      content = Array(opt_list).map {|s| "--register-#{s}"}.join(' ')
      python_pack = self.python_pack
      conf_path = node['stackstorm']['conf_path']

      if !content.empty?
        execute "#{recipe_name} register st2 content with: #{content}" do
          command("python #{python_pack}/st2common/bin/registercontent.py " <<
                                      "#{content} --config-file #{conf_path}")
        end
      end
    end

    def python_pack
      # get python version, ex. 2.7 for 2.7.6
      pv = node['languages']['python']['version'].to_f
      case node.platform_family
      when 'debian'
        "/usr/lib/python#{pv}/dist-packages"
      when 'rhel', 'fedora'
        "/usr/lib/python#{pv}/site-packages"
      end
    end

    # Retrive list of enabled components, and populate attribute.
    def apply_components
      at = node['stackstorm']['roles']
      components = (%w(st2common) + node['stackstorm']['components']).uniq

      # mind order, services are brought acorrding to the given sequence
      at.include?('controller') and
            components += %w(st2common st2api st2reactor st2auth)
      at.include?('worker') and
            components += %w(st2common st2actions)
      at.include?('client') and
            components += %w(st2common st2client)

      node.default['stackstorm']['components'] = components.uniq
    end

  end
end
