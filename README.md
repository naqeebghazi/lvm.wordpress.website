# lvm.wordpress.website

Implementing WordPress Website with LVM Storage Management on AWS EC2 Ubuntu

A typical 3-tier architecture (3TA) consists of:
- Presentation tier: What you see and interact with in your web browser or application (e.g. via a personal laptop, phone, tablet)
- Application tier: Backend of the application/website that processes all the input/outputs and any other computational requirements
- Data tier: Data storage and data access. Database server e.g. FTP server and NFS server

Simplified outline of a 3TA:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/gen3tierarchitecture.png?raw=true)

Example outline of a 3TA in AWS:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/aws3tierarchitecture.png?raw=true)

We will be focusing on the Application and Data tiers as thats where our DevOps skills are more emphasised. The presentation tier is more web design focused. 
So, our project will be to:
  1. Data tier: Setup of storage for both Web and Database servers
  2. Application tier: WordPress installation onto a Webserver which is connected to a seperate MySQL database server

## Part 1: Create a Webserver EC2 instance using a RedHat image (free tier) and ensure you attach 3 gp2/gp3 EBS volumes to the instance. 

SSH into the instance and update the system:

    $ sudo yum -y update

Check that volumes are attached:

    $ lsblk 

![lsblk](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblk.png?raw=true)

The volumes you added are xvdb, xvdc, xvdd. These corresspond to Vol1, Vol2 and Vol3 respectiively in the AWS console:

![Vol123](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/Vol123.png?raw=true)

To see all the mounted volumes and free space on your server:

    $ df -h

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h.png?raw=true)

Use gdisk to create a single partition on each of the 3 disks:

    sudo gdisk /dev/xvdb
    sudo gdisk /dev/xvdc
    sudo gdisk /dev/xvdd

  After each gdisk command above, follow these steps:
  Once inside gdisk, you can create partitions using the following steps:
  
  - Press n to create a new partition.
  - Choose the partition number.
  - Set the starting sector and ending sector for the partition. If you want to use the entire disk, you can press Enter to accept the default values.
  - Choose the partition type. You can press Enter to accept the default if you're unsure.
  - Optionally, you can set a name for the partition.
  - Repeat these steps to create additional partitions if needed.

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h.png?raw=true)
  
  Review Changes:
  After creating partitions, use the p command to review the changes.
  
  Write Changes to Disk:
  If you're satisfied with the changes, press Y to write the changes to the disk.

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/wY.png?raw=true)

Check Partition with lsblk command:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblkcheckPartition.png?raw=true)

Install lvm:

    sudo yum -y install lvm2


Lvm helps us to manage the partitioned disks. Run LVM disk scan:

    sudo lvmdiskscan

Output:
![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvmdiskscan.png?raw=true)

The pvcreate command in LVM (Logical Volume Manager) is used to initialize a physical volume, preparing it for use in an LVM volume group. When you add a new hard disk or a partition to an LVM setup, you need to run pvcreate on that device to make it available for use in LVM. 
Run pvcreate on each disk:

    $ sudo pvcreate /dev/xvdb1
    $ sudo pvcreate /dev/xvdc1
    $ sudo pvcreate /dev/xvdd1

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/pvcreate_partioneddisks.png?raw=true)

This creates physical volumes with a new name = original disk name + number (e.g. xvda -> xvda1)

Then verfiy the above commands worked by running:

    $ sudo pvs

Result of above:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/pvcreate.png?raw=true)


Use vgcreate utility to add all 3 PVs to a volume group (vg) called webdata-vg:

    $ sudo vgcreate webdata-vg /dev/xvdb1 /dev/xvdc1 /dev/xvdd1

  Then verify the above:

      $ sudo vgs

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vg-create.png?raw=true)

The lvcreate command is part of the Logical Volume Manager (LVM) system in Linux. It is used to create logical volumes within a volume group. Logical volumes are similar to partitions in traditional disk partitioning schemes but offer more flexibility and features. 

Use lvcreate to make to logical volumes from the webdata-vg volume group:

    $ sudo lvcreate -n apps-lv -L 14G webdata-vg
    $ sudo lvcreate -n logs-lv -L 14G webdata-vg

![lvcreate](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvcreate_apps.logs.png?raw=true)

Validate entire setup:

    $ sudo vgdisplay -v #view complete setup - VG, PV, LV
    $ sudo lsblk

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vgdisplay.png?raw=true)

&

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblk_2.png?raw=true)

Format the new logical volumes you created with the ext4 filesystem:

    $ sudo mkfs -t ext4 /dev/webdata-vg/apps-lv
    $ sudo mkfs -t ext4 /dev/webdata-vg/logs-lv

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/mkfs_ext4.png?raw=true)

## Part 2: Setting up your logical volumes as part of a webserver

Create /var/www/html directory to store website files

    $ sudo mkdir -p /var/www/html

Create /home/recovery/logs to store backup of log data:

    $ sudo mkdir -p /home/recovery/logs

The mount command tells us what storage devices are mounted on our system:

    $ mount  | grep xvd

We can use grep to narrow down the output for our devices

Mount the html directory on the apps-lv logical volume:

    $ sudo mount /dev/webdata-vg/apps-lv /var/www/html/

Backup all the files in the /var/log directory into the /home/recovery/logs

    $ sudo rsync -av /var/log/. /home/recovery/logs/

Mount the /var/log directory on the log-lv logivcal volume. 

    $ sudo mount /dev/webdata-vg/logs-lv /var/log

Restore log files back into /var/log directory:

    $ sudo rsync -av /home/recovery/logs/. /var/log

Update /etc/fstab. This persists the mount configuration even after restart. 

    $ sudo blkid 

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/sudoblkid.png?raw=true)

These two sections from the above command are important. Take the UUIDs and copy to clipboard as instructued below. 
/dev/mapper/webdata--vg-apps--lv: UUID="0c34dba8-4698-46f5-8ac6-b290574fe73b" TYPE="ext4"
/dev/mapper/webdata--vg-logs--lv: UUID="d4dc2e72-a8c0-4439-abd1-fd941ca853dd" TYPE="ext4"


Edit /etc/fstab and replace the UUID in it with the UUIDs of the /dev/mapper/ UUIDs (removing the quotation marks):

    $ sudo vi /etc/fstab

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vifstab.png?raw=true)

Ensure formatting is the same as above, especially the columns next to the UUIDs. 
Save the file with :wq!

Test new configuration and reload the file:

    $ sudo mount -a
    $ sudo systemctl daemon-reload

Validate setup

    $ df -h

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/daemon-reload.png?raw=true)

###################################################################################################################################################################################################

## Part 3: Installing Wrodpress and MySQL configuration

### Preapring the database server

Create a new EC2 instance for the Dayabase server by following all the same steps as above, with the following difference:

    Instead of apps-lv, make db-lv and mount it to /db instead of /var/www/html

All steps repeated below but for the database:

SH into the instance and update the system:

    $ sudo yum update

Check that volumes are attached:

    $ lsblk 

![lsblk](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblk.png?raw=true)

The volumes you added are xvdb, xvdc, xvdd. These corresspond to Vol1, Vol2 and Vol3 respectiively in the AWS console:

![Vol123](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/Vol123.png?raw=true)

To see all the mounted volumes and free space on your server:

    $ df -h

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h.png?raw=true)

Use gdisk to create a single partition on each of the 3 disks:

    $ sudo gdisk /dev/xvdb
    $ sudo gdisk /dev/xvdc
    $ sudo gdisk /dev/xvdd

  After each gdisk command above, follow these steps:
  Once inside gdisk, you can create partitions using the following steps:
  
  - Press n to create a new partition.
  - Choose the partition number.
  - Set the starting sector and ending sector for the partition. If you want to use the entire disk, you can press Enter to accept the default values.
  - Choose the partition type. You can press Enter to accept the default if you're unsure.
  - Optionally, you can set a name for the partition.
  - Repeat these steps to create additional partitions if needed.

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h.png?raw=true)
  
  Review Changes:
  After creating partitions, use the p command to review the changes.
  
  Write Changes to Disk:
  If you're satisfied with the changes, press Y to write the changes to the disk.

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/wY.png?raw=true)

Check Partition with lsblk command:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblkcheckPartition.png?raw=true)

Install lvm:

    $ sudo yum install lvm2

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvm2install.png?raw=true)

Lvm helps us to manage the disks. Run LVM disk scan:

    $ sudo pvcreate /dev/xvdb

Output:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvmdiskscan.png?raw=true)

The pvcreate command in LVM (Logical Volume Manager) is used to initialize a physical volume, preparing it for use in an LVM volume group. When you add a new hard disk or a partition to an LVM setup, you need to run pvcreate on that device to make it available for use in LVM. 
Run pvcreate on each disk:

    $ sudo pvcreate /dev/xvdb1
    $ sudo pvcreate /dev/xvdc1
    $ sudo pvcreate /dev/xvdd1

This creates physical volumes with a new name = original disk name + number (e.g. xvda -> xvda1 

Then verfiy the above commands worked by running:

    $ sudo pvs

Result of above:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/pvcreate.png?raw=true)


Use vgcreate utility to add all 3 PVs to a volume group (vg) called dbdata-vg:

    $ sudo vgcreate dbdata-vg /dev/xvdb1 /dev/xvdc1 /dev/xvdd1

  Then verify the above:

      $ sudo vgs

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vg-create.png?raw=true)

The lvcreate command is part of the Logical Volume Manager (LVM) system in Linux. It is used to create logical volumes within a volume group. Logical volumes are similar to partitions in traditional disk partitioning schemes but offer more flexibility and features. 

Use lvcreate to make to logical volumes from the dbdata-vg volume group:

    $ sudo lvcreate -n db-lv -L 14G dbdata-vg
    $ sudo lvcreate -n logs-lv -L 14G dbdata-vg

Validate with lvs which lists the logical volumes

    $ sudo lvs

![lvcreate](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/db_lvs.png?raw=true)

Validate entire setup:

    $ sudo vgdisplay -v #view complete setup - VG, PV, LV
    $ sudo lsblk

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/db-validateALL.png?raw=true)

&

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/db_lsblk.png?raw=true)

Format the new logical volumes you created with the ext4 filesystem:

    $ sudo mkfs -t ext4 /dev/dbdata-vg/db-lv
    $ sudo mkfs -t ext4 /dev/dbdata-vg/logs-lv

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/dbdata_format_ext4.png?raw=true)

## Part 2: Setting up your logical volumes as part of a webserver

Create /var/www/html directory to store website files

    $ sudo mkdir -p /db

Create /home/recovery/logs to store backup of log data:

    $ sudo mkdir -p /home/recovery/logs

Mount the html directory on the db-lv logical volume:

    $ sudo mount /dev/dbdata-vg/db-lv /db

Backup all the files in the /var/log directory into the /home/recovery/logs

    $ sudo rsync -av /var/log/. /home/recovery/logs

Mount the /var/log directory on the log-lv logivcal volume. 

    $ sudo mount /dev/dbdata-vg/logs-lv /var/log

Restore log files back into /var/log directory:

    $ sudo rsync -av /home/recovery/logs/. /var/log

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/sudoRsync_forDB.png?raw=true)

Update /etc/fstab. This persists the mount configuration even after restart. 

    $ sudo blkid 

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/sudoblkid.png?raw=true)

These two sections from the above command are important. Take the UUIDs and copy to clipboard as instructued below:
/dev/mapper/db--vg-db--lv: UUID="86c93a31-63a5-49ed-ae25-e7444833f735" TYPE="ext4"
/dev/mapper/db--vg-logs--lv: UUID="1b076527-6214-4e7e-8068-7335ee8d9672" TYPE="ext4"

Edit /etc/fstab and replace the UUID in it with the UUIDs of the /dev/mapper/ UUIDs (removing the quotation marks):

    $ sudo vi /etc/fstab

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/database-fstab.png?raw=true)

Ensure formatting is the same as above, especially the columns next to the UUIDs. 
Save the file with :wq!

Test new configuration and reload the file:

    $ sudo mount -a
    $ sudo systemctl daemon-reload

Validate setup

    $ df -h

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h_db.png?raw=true)

#############################################################################################################################################################################

## Part 4: Install Wordpress on WebServer

Update the pkg manager and install apache and php

    sudo yum update -y
    sudo yum -y install wget httpd php php-mysqlnd php-fpm php-json

Start Apache:

    sudo systemctl enable httpd
    sudo systemctl start httpd

Install PHP and dependencies:

    sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo yum install yum-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm --skip-broken
    sudo yum module list php
    sudo yum module reset php
    sudo yum module enable php:remi-7.4
    sudo yum install php php-opcache php-gd php-curl php-mysqlnd
    sudo systemctl start php-fpm
    sudo systemctl enable php-fpm
    setsebool -P httpd_execmem 1

Restart Apache:

    sudo systemctl restart httpd

Download Wordpress and copy Wordpress to /var/www/html

    sudo mkdir wordpress
    cd wordpress
    sudo wget http://wordpress.org/latest.tar.gz
    sudo tar xzvf latest.tar.gz
    sudo rm -rf latest.tar.gz
    sudo cp wordpress/wp-config-sample.php wordpress/wp-config.php
    sudo cp -R wordpress /var/www/html/

Edit the wp-config.php file:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/wp-configimage.png?raw=true)

Configure SELinux policies (ownership):

     sudo chown -R apache:apache /var/www/html/wordpress/wp-content
     sudo chcon -t httpd_sys_rw_content_t /var/www/html/wordpress/wp-content -R
     sudo setsebool -P httpd_can_network_connect=1


## Part 5: Install MySQL on your DB Server EC2

    sudo yum -y update
    sudo yum -y install mysql-server

Verify mysql is running

    sudo systemctl status mysqld

If note, restart it

    sudo systemctl restart mysqld
    sudo systemctl enable mysqld

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/enablehttpd.png?raw=true)

Configure the DB to work with Wordpress

    sudo mysql
    CREATE DATABASE wordpress;
    CREATE USER `myuser`@`<Web-Server-Private-IP-Address>` IDENTIFIED BY 'mypass';
    GRANT ALL ON wordpress.* TO 'myuser'@'<Web-Server-Private-IP-Address>';
    FLUSH PRIVILEGES;
    SHOW DATABASES;
    exit

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/db-mysql%20setup.png?raw=true)

Configure Wordpress to connect to remote DB.
Open MySQL port 3306 on DB server via your security groups. Only allow access to DB server via your Webserver's IP address. In the inbound rules configuration of the SG, specify source as /32

Install MySQL client on the Webserver and see if you can connect your Webserver to the DB by using the mysql-client:

    sudo yum -y install mysql
    sudo mysql -u myuser -p -h 172.31.37.94

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/WS-DB.mysqlcxn.png?raw=true)

Security groups should be as follows:

  Web Server:
    Outbound rules: All Traffic 
    Inbound rules: All Traffic
  
  MySQL DB Server:
    Outbound rules: None required
    Inbound rules: MySQL/Aurora, port 3306, IPv4, IP Address of WebServer

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/dbserverSecGrpconfig.png?raw=true)

RedHat apache server online via web broswer and public IP:
![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/Screenshot%202023-11-29%20at%2017.30.02.png?raw=true)

Verify you can successfully execute SHOW DATABASES; to see list of databases

Enable TCP port80 inbound rules for WebServer (enable from everywhere 0.0.0.0/0 or from your own IP address)

Try accessing from your browser: http://<web-server-publicIP>/wordpress

Successful Wordpress access via web browser:
![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/wordpressInBrowser.png?raw=true)

Post-installation of Wordpress in browser:
![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images2/wp_loginSuccess.png?raw=true)



    















    
    
