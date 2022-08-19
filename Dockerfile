FROM ubuntu:focal

# Install cron
RUN apt-get update && apt-get -y install cron

# Copy the shell script
COPY cloudflare-template.sh /root/cloudflare-template.sh

RUN touch /var/log/cron.log

# Give execution rights on the cron scripts
RUN chmod +x /root/cloudflare-template.sh

RUN crontab -l | { cat; echo "* * * * * /bin/bash /root/cloudflare-template.sh"; } | crontab -

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log