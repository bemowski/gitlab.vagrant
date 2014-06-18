

apt-get update

apt-get upgrade -y

apt-get -y install curl


# A Gitlab startup script for Vagrant, based on: 
#  https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md
#
#
#Administrator account created:
#login.........admin@local.host
#password......5iveL!fe


export MYSQL_ROOT_PASSWORD=toor

# Can be a fqdn, or "localhost" or an ip address... depending on how you will use GitLab
#    This will be used to send links to users to login.  
#    This will be embeded in sample commands to push/pull from the repo.
export MYHOST=gitlab.pss.asurion.com

# 1. Packages / Dependencies
apt-get -y install sudo 

sudo apt-get install -y vim
sudo update-alternatives --set editor /usr/bin/vim.basic

apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl openssh-server redis-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev logrotate python-docutils

# Postfix wants to configure some stuff during install.  disable, but this means we may need to 
# tweak postfix after install.
# I am redirecting the output of the postfix install because it buggers the install screen 
# with an inteeractive ncurses app - which is ignored anyway.
export DEBIAN_FRONTEND=noninteractive
echo "Installing Postfix non-interactive"
sudo apt-get install -y postfix 2>&1>/dev/null
echo "Done installing postfix"

# simple setup, relay for no one. Allows local GitLab to send emails.
echo "# http://www.postfix.org/STANDARD_CONFIGURATION_README.html#stand_alone">/etc/postfix/main.cf
echo "mynetworks_style = host">/etc/postfix/main.cf
echo "relay_domains =">/etc/postfix/main.cf

# 2. Ruby
apt-get -y remove ruby

mkdir /tmp/ruby && cd /tmp/ruby
curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p481.tar.gz | tar xz
cd ruby-2.0.0-p481
./configure --disable-install-rdoc
make
sudo make install

gem install bundler --no-ri --no-rdoc

# 3.System Users
adduser --disabled-login --gecos 'GitLab' git

# 4. Database 

# Opting for mysql here.   
# https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/database_mysql.md
sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
mysql --version

# set root password.
mysqladmin -u root password $MYSQL_ROOT_PASSWORD

echo "CREATE USER 'git'@'localhost' IDENTIFIED BY 'git';" > /tmp/mysql.git.create
echo "SET storage_engine=INNODB;" >> /tmp/mysql.git.create
echo "CREATE DATABASE IF NOT EXISTS gitlabhq_production DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;" >> /tmp/mysql.git.create
echo "GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON gitlabhq_production.* TO 'git'@'localhost';" >> /tmp/mysql.git.create

mysql -u root -p$MYSQL_ROOT_PASSWORD < /tmp/mysql.git.create

# 5. GitLab
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 6-9-stable gitlab
cd /home/git/gitlab


# FIXME: Sset some settings here:
cp config/gitlab.yml.example config/gitlab.yml
# set 
#       host: localhost
sed -i 's/localhost/'"$MYHOST"'/g' config/gitlab.yml

# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R git log/
sudo chown -R git tmp/
sudo chmod -R u+rwX log/
sudo chmod -R u+rwX tmp/

# Create directory for satellites
sudo -u git -H mkdir /home/git/gitlab-satellites
sudo chmod u+rwx,g=rx,o-rwx /home/git/gitlab-satellites

# Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
sudo chmod -R u+rwX tmp/pids/
sudo chmod -R u+rwX tmp/sockets/

# Make sure GitLab can write to the public/uploads/ directory
sudo chmod -R u+rwX  public/uploads

# Copy the example Unicorn config
sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb

# Enable cluster mode if you expect to have a high load instance
# Ex. change amount of workers to 3 for 2GB RAM server
#sudo -u git -H editor config/unicorn.rb

# Copy the example Rack attack config
sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb

# Configure Git global settings for git user, useful when editing via web
# Edit user.email according to what is set in gitlab.yml
sudo -u git -H git config --global user.name "GitLab"
sudo -u git -H git config --global user.email "example@example.com"
sudo -u git -H git config --global core.autocrlf input

# Configure database
#sudo -u git cp config/database.yml.mysql config/database.yml
sudo -u git sed 's/secure\ password/git/g' config/database.yml.mysql >config/database.yml
sudo -u git -H chmod o-rwx config/database.yml

# Install GEMS
cd /home/git/gitlab

sudo -u git -H bundle install --deployment --without development test postgres aws

# Install GitLab shell
# Go to the Gitlab installation folder:
cd /home/git/gitlab

# Run the installation task for gitlab-shell (replace `REDIS_URL` if needed):
sudo -u git -H bundle exec rake gitlab:shell:install[v1.9.5] REDIS_URL=redis://localhost:6379 RAILS_ENV=production

# Initialize Database and Activate Advanced Features
cd /home/git/gitlab
#sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
# stupid ineractive stuff...
echo "yes"|sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production

# Init:
cp lib/support/init.d/gitlab /etc/init.d/gitlab
update-rc.d gitlab defaults 21

# Logrotate
cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab

# compile assets
sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production

# start
/etc/init.d/gitlab restart

# 6. nginx
sudo apt-get install -y nginx
cd /home/git/gitlab
sudo cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab

# FIXME: replace YOUR_SERVER_FQDN
rm /etc/nginx/sites-enabled/default

sudo /etc/init.d/nginx restart
update-rc.d nginx defaults 21



