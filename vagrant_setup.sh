sudo apt-get update

# Get some basic commands
sudo apt-get install -y curl
sudo apt-get install -y build-essential
sudo apt-get install -y libpq-dev
sudo apt-get install -y git

# Use pretty colors for Git
git config --global color.ui true

# Install RVM
curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh

# Get Ruby 2.0 and Bundler
rvm install 2.0.0-p353
gem install --no-ri --no-rdoc bundler

# Get passenger
sudo gem install passenger --pre
sudo passenger-install-nginx-module


# Get docker
curl -sL https://get.docker.io/ | sh

# Get the docker image that can run submissions
sudo docker pull ulysse/polyglot

# Not yet tested: add `vagrant` to the docker group
sudo gpasswd -a vagrant docker
sudo service docker restart

# Postgres stuff ...
sudo apt-get install -y postgresql postgresql-contrib libpq-dev

# Stuff to get syntax highlighting working with Pygments ...
sudo apt-get install python-setuptools -y
sudo easy_install pygments

# Use awesome print by default (untested)
printf "require 'awesome_print'\nAwesomePrint.irb! \n" > ~/.irbrc

# The folder where the magic happens
cd /vagrant

# Install necessary gems
bundle

# When I SSH into Vagrant, I'll want to go to /vagrant automatically
echo cd /vagrant/ >> ~/.bashrc
