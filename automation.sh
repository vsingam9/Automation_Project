#!/bin/bash

# 1 - Basic ( Updating packages and initializing variables)

#Updating the packages
apt update -y

#Initializing variables
myname='venugopal'
s3_bucket='upgrad-venugopal'
timestamp=$(date '+%d%m%Y-%H%M%S')



# 2 - Apache2 service
#Checking for apache2, installing if not present; enabling and starting the service if required.

if [ $(dpkg --list | grep apache2 | cut -d ' ' -f 3 | head -1) == 'apache2' ]
then
	echo "Apache2 is installed...checking for its state"
	if [[ $(systemctl status apache2 | grep disabled | cut -d ';' -f 2) == ' disabled' ]];
		then
			systemctl enable apache2
			echo "Apache2 enabled now"
			systemctl start apache2
#If Apache 2 is installed then check whether it is started or not; start it Inactive. This will ensure it is started on any reboots.		
		else
			if [ $(systemctl status apache2 | grep active | cut -d ':' -f 2 | cut -d ' ' -f 2) == 'active' ]
			then
				echo "Apache2 is already running"
			else
				systemctl start apache2
				echo "Apache2 service started"
			fi
	fi
					
else
	echo "Apache2 not installed...will be installed now"
	printf 'Y\n' | apt-get install apache2
	echo "Apache2 service was installed"
	
fi

# 3 - Backing up the Log files and uploading to S3 bucket


# Making the local backup /tmp/
tar -zvcf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log


# Uploading to S3 bucket

#Optional - check for AWS CLI and install if not present / Upload the tar file of Logs to S3 bucket.

if [ $(dpkg --list | grep awscli | cut -d ' ' -f 3 | head -1) == 'awscli' ]

	then
		aws s3 \
		cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
		s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

	else
	echo "awscli is not present, installing now..."	
	printf 'Y\n' | apt install awscli
	aws s3 \
	cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
	s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

fi


# 4 - Updating the Inventory file with the latest log backup.


if [ -f "/var/www/html/inventory.html" ]; 
then
	
	printf "<p>" >> /var/www/html/inventory.html
	printf "\n\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 10 | cut -d '-' -f 2,3 | tail -1)" >> /var/www/html/inventory.html
	printf "\t\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 10 | cut -d '-' -f 4,5 | cut -d '.' -f 1 | tail -1)" >> /var/www/html/inventory.html
	printf "\t\t\t $(ls -lrth /tmp | grep httpd | cut -d ' ' -f 10 | cut -d '-' -f 4,5 | cut -d '.' -f 2 | tail -1 )" >> /var/www/html/inventory.html
	printf "\t\t\t\t$(ls -lrth /tmp/ | grep httpd | cut -d ' ' -f 6 | tail -1)" >> /var/www/html/inventory.html
	printf "</p>" >> /var/www/html/inventory.html
	
else 
	touch /var/www/html/inventory.html
	printf "<p>" >> /var/www/html/inventory.html
	printf "\tLog-Type\tDate-Created\tType\tSize" >> /var/www/html/inventory.html
	printf "</p>" >> /var/www/html/inventory.html
	printf "<p>" >> /var/www/html/inventory.html
	printf "\n\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 10 | cut -d '-' -f 2,3 | tail -1)" >> /var/www/html/inventory.html
	printf "\t\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 10 | cut -d '-' -f 4,5 | cut -d '.' -f 1 | tail -1)" >> /var/www/html/inventory.html
	printf "\t\t\t $(ls -lrth /tmp | grep httpd | cut -d ' ' -f 10 | cut -d '-' -f 4,5 | cut -d '.' -f 2 | tail -1)" >> /var/www/html/inventory.html
	printf "\t\t\t\t$(ls -lrth /tmp/ | grep httpd | cut -d ' ' -f 6 |tail -1)" >> /var/www/html/inventory.html
	printf "</p>" >> /var/www/html/inventory.html
	
fi


# 5 - Scheduling cronjob for Daily running of automation script

if [ -f "/etc/cron.d/automation" ];
then
	echo "Automation script in place for Daily 00:00 hrs"
else
	touch /etc/cron.d/automation
	printf "0 0 * * * root /root/Automation_Project/auotmation.sh" > /etc/cron.d/automation
fi
