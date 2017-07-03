#!/bin/bash

echo "Please name the process: "
read name
echo "Please input the url to be monitored: "
read url
echo "Please input your email(s) to be alerted: "
read email
filename="${name}.generated.sh"
if [ -e "${filename}" ]; then
  rm ${filename}
fi
printf "#!/bin/bash\n\nName=\"${name}\"\nURL=\"${url}\"\nEmail=\"${email}\"\n" >> ${filename}
cat template.sh >> ${filename}
chmod 755 ${filename}
