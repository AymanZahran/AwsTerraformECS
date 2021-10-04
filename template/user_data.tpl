#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
yum update -y
yum install -y httpd
#sed -i 's/80/443/g' /etc/httpd/conf/httpd.conf
cat <<'EOF' >> /var/www/html/index.html
<html>
<head>
<title>Success!</title>
<style>
body {
background-image: url('https://ce-test-bg-image-onica.s3-us-west-2.amazonaws.com/onica.jpg');
background-repeat: no-repeat;
background-attachment: fixed;
background-position: center;
</style>
</head>
<body>
<h1>Hello Onica!</h1>
</body>
</html>
EOF
systemctl start httpd
systemctl enable httpd

cat <<'EOF' >> /home/ec2-user/upload_access_logs.sh
DATE_SLASHED="`date | awk '{ print $3"/"$2"/"$6 }'`"
DATE_CONCATE="`date | awk '{ print $3$2$6 }'`"
ACCESS_LOGS_PATH="/var/log/httpd/access_log"
SRC="$ACCESS_LOGS_PATH$DATE_CONCATE"
DST="s3://access-logs-azahran-account246176637906/acces_log$DATE_CONCATE.tar.gz"
cat $ACCESS_LOGS_PATH | grep -i $DATE_SLASHED > $SRC
tar -czvf $SRC.tar.gz $SRC
aws s3 cp $SRC $DST
rm -f $SRC*
EOF
chmod +x /home/ec2-user/upload_access_logs.sh
touch /var/spool/cron/ec2-user
echo "1 0 * * * sudo ./upload_access_logs.sh" > /var/spool/cron/ec2-user

