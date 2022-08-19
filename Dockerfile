FROM ubuntu:focal

# Install cron
RUN apt-get update && apt-get -y install cron

# Copy the shell script
COPY cloudflare-template.sh /root/cloudflare-template.sh

# Give execution rights on the cron scripts
RUN chmod +x /root/cloudflare-template.sh

COPY cronfile /etc/cron.d/cronfile

RUN chmod 0644 /etc/cron.d/cronfile

RUN crontab /etc/cron.d/cronfile

# Create the cron log file
RUN touch /var/log/cron.log

# Add the cron job
RUN crontab -l | { cat; echo "*/1 * * * * /bin/bash /root/cloudflare-template.sh"; } | crontab -

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log