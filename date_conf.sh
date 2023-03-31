#!/bin/bash
# Create the initial HTML file with a div element
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
  <head>
    <title>My Website</title>
  </head>
  <body>
    <div id="datetime"></div>
  </body>
</html>
EOF
# Add a cronjob to update the HTML file every 30 seconds
# Save current crontab to a file
#crontab -l > mycron
# Add a new cronjob to the file that updates the HTML file
sed -i "s#<div id=\"datetime\"></div>#<div id=\"datetime\">$(date '+%Y-%m-%d %H:%M:%S')</div>#g" /var/www/html/index.html















