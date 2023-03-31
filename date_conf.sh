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

sed -i "s#<div id=\"datetime\"></div>#<div id=\"datetime\">$(date '+%Y-%m-%d %H:%M:%S')</div>#g" /var/www/html/index.html















