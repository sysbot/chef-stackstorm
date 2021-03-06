include_recipe 'build-essential::default'
include_recipe 'git::default'
include_recipe 'stackstorm::_python'

[
  node['stackstorm']['home'],
  node['stackstorm']['etc_dir']
].each do |path|
  directory "creating st2 directory #{path}" do
    path path
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
end

# Create default user and group to run unprivileged StackStorm services.
user 'st2' do
  home '/home/st2'
  supports manage_home: true
  action :create
end

# Fix localhost in hosts, somehow missing on Fedora 20
hostsfile_entry '127.0.0.1' do
  hostname  'localhost'
  comment   'Appended by st2 cookbook'
  action    :append
end
