# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["PORT"] ||= "3000"

$provision = <<SCRIPT

cd /vagrant # This is where the host folder/repo is mounted

# Add the yarn repo + yarn repo keys
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
sudo apt-add-repository 'deb https://dl.yarnpkg.com/debian/ stable main'

# Add repo for NodeJS
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -

# Add firewall rule to redirect 80 to PORT and save
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port #{ENV["PORT"]}
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get install iptables-persistent -y

# Add packages to build and run Mastodon
sudo apt-get install \
  git-core \
  g++ \
  libpq-dev \
  libxml2-dev \
  libxslt1-dev \
  imagemagick \
  nodejs \
  redis-server \
  redis-tools \
  postgresql \
  postgresql-contrib \
  yarn \
  libicu-dev \
  libidn11-dev \
  libreadline-dev \
  libpam0g-dev \
  -y

# Install rvm
read RUBY_VERSION < .ruby-version

curl -sSL https://rvm.io/mpapis.asc | gpg --import
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import

curl -sSL https://raw.githubusercontent.com/rvm/rvm/stable/binscripts/rvm-installer | bash -s stable --ruby=$RUBY_VERSION
source /home/vagrant/.rvm/scripts/rvm

# Install Ruby
rvm reinstall ruby-$RUBY_VERSION --disable-binary

# Configure database
sudo -u postgres createuser -U postgres vagrant -s
sudo -u postgres createdb -U postgres mastodon_development

# Install gems and node modules
gem install bundler foreman
bundle install
yarn install

# Build Mastodon
export RAILS_ENV=development 
export $(cat ".env.vagrant" | xargs)
bundle exec rails db:setup

# Configure automatic loading of environment variable
echo 'export RAILS_ENV=development' >> ~/.bash_profile
echo 'export $(cat "/vagrant/.env.vagrant" | xargs)' >> ~/.bash_profile

SCRIPT

$start = <<SCRIPT

echo 'To start server'
echo '  $ vagrant ssh -c "cd /vagrant && foreman start"'

SCRIPT

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "generic/ubuntu1804"

  config.vm.provider :virtualbox do |vb|
    vb.name = "deadinside"
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    # Increase the number of CPUs. Uncomment and adjust to
    # increase performance
    vb.customize ["modifyvm", :id, "--cpus", "16"]

    # Disable VirtualBox DNS proxy to skip long-delay IPv6 resolutions.
    # https://github.com/mitchellh/vagrant/issues/1172
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]

    # Use "virtio" network interfaces for better performance.
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]

  end

  config.vm.provider :libvirt do |libvirt| 
    libvirt.cpus = 16
    libvirt.memory = 4192
  end

  # This uses the vagrant-hostsupdater plugin, and lets you
  # access the development site at http://mastodon.local.
  # If you change it, also change it in .env.vagrant before provisioning
  # the vagrant server to update the development build.
  #
  # To install:
  #   $ vagrant plugin install vagrant-hostsupdater
  config.vm.hostname = "mastodon.local"

  if defined?(VagrantPlugins::HostsUpdater)
    config.vm.network :private_network, ip: "192.168.42.42", nictype: "virtio"
    config.hostsupdater.remove_on_suspend = false
  end

  if config.vm.networks.any? { |type, options| type == :private_network }
    config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ['rw', 'vers=3', 'tcp', 'actimeo=1']
  else
    config.vm.synced_folder ".", "/vagrant", type: "sshfs"
  end

  # Otherwise, you can access the site at http://localhost:3000 and http://localhost:4000 , http://localhost:8080
  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.network :forwarded_port, guest: 4000, host: 4000
  config.vm.network :forwarded_port, guest: 8080, host: 8080

  # Full provisioning script, only runs on first 'vagrant up' or with 'vagrant provision'
  config.vm.provision :shell, inline: $provision, privileged: false

  # Start up script, runs on every 'vagrant up'
  config.vm.provision :shell, inline: $start, run: 'always', privileged: false

end
