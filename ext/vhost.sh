#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, use sudo sh $0"
    exit 1
fi

if [ "$1" != "--help" ]; then

# Directories
SRCDIR=`dirname $(readlink -f $0)`

  domain=""
  echo "Please input domain:"
  read -p domain
  if [ "$domain" = "" ]; then
    echo "Please enter a domain name"
    exit 1
  fi
  if [ ! -f "/etc/nginx/sites-available/$domain" ]; then
  echo "==========================="
  echo "domain=$domain"
  echo "==========================="
  else
  echo "==========================="
  echo "$domain already exist!"
  echo "==========================="
  fi

  echo "Do you want to add more domain names? (y/n)"
  read add_more_domainame

  if [ "$add_more_domainame" = 'y' ]; then

    echo "Enter additional domain:"
    read moredomain
          echo "==========================="
          echo domain list="$moredomain"
          echo "==========================="
    moredomainame=" $moredomain"
  fi

  vhostdir="/var/www/$domain"
  echo "Please input the directory for the domain:$domain :"
  read -p "(Default directory: /var/www/$domain):" vhostdir
  if [ "$vhostdir" = "" ]; then
    vhostdir="/var/www/$domain"
  fi
  echo "==========================="
  echo Virtual Host Directory="$vhostdir"
  echo "==========================="

  echo "==========================="
  echo "Allow Rewrite rule? (y/n)"
  echo "==========================="
  read allow_rewrite

  if [ "$allow_rewrite" = 'n' ]; then
    rewrite="none"
  else
    echo "Please choose your rewrite system"
    echo "wordpress, drupal, php, html"
    read -p "Rewrite:" rewrite
    if [ "$rewrite" = "" ]; then
      rewrite="none"
    fi
  fi
  echo "==========================="
  echo You chose $rewrite
  echo "==========================="

  echo "Do you want to rewrite non-www to www? (y/n)"
  read rewrite_www

  get_char()
  {
  SAVEDSTTY=`stty -g`
  stty -echo
  stty cbreak
  dd if=/dev/tty bs=1 count=1 2> /dev/null
  stty -raw
  stty echo
  stty $SAVEDSTTY
  }
  echo ""
  echo "Press any key to start create virtul host..."
  char=`get_char`


  if [ ! -d /etc/nginx/sites-available ]; then
    mkdir /etc/nginx/sites-available
  fi

  echo "Create Virtul Host directory......"
  mkdir -p $vhostdir
  mkdir -p /var/wwwlogs
  echo "Set permissions of Virtual Host directory......"
  chmod -R 755 $vhostdir
  chown -R deploy:www-data $vhostdir

  if [ ! -d /etc/nginx/conf ]; then
    mkdir /etc/nginx/conf
  fi

cat >/etc/nginx/sites-available/$domain<<eof
  if ["$rewrite_www"]; then
    server {
      listen [::]:80 ipv6only=on;
      listen 80;
      server_name $domain;
      return 301 $scheme://www.$domain$request_uri;
    }
  fi
  server {
    listen [::]:80 ipv6only=on;
    listen 80;
    server_name $domain $moredomainame;
    index index.html index.php;
    root  $vhostdir;

    include /etc/nginx/conf/drop.conf;
    include /etc/nginx/conf/html;
    include /etc/nginx/conf/php.conf;
    include /etc/nginx/conf/$rewrite;
    include /etc/nginx/conf/cache.conf;

    location ~* /index {
      internal;
      error_page 404 =301 $scheme://www.$domain/;
    }
  }
eof

  echo "==========================="
  read -p "Enable site? (y/n): " enable
  echo "==========================="
  if [ "$enable" = 'n' ]; then
    echo "$domain will not be enabled"; continue
  else
    if [ -f /etc/nginx/sites-enabled/$domain ]; then
    echo "$domain is already enabled"; continue
    fi
  # Check if file exists
    if [ -f /etc/nginx/sites-available/$domain ]; then
      echo "Enabling $domain"
      ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain
    else
      echo "no such file: /etc/nginx/sites-available/$domain"
    fi
  fi


  echo "Test Nginx configure file......"
  /opt/nginx/sbin/nginx -t
  echo ""
  echo "Restart Nginx......"
  /opt/nginx/sbin/nginx -s reload

  echo "Your domain: $domain"
  echo "Directory of $domain: $vhostdir"
  echo ""
  echo "========================================================================="
fi
