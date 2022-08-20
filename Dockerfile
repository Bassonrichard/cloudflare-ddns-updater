FROM ubuntu:focal

# Install cron
RUN apt-get update && apt-get -y install cron curl

# Copy the shell script
COPY cloudflare-template.sh ./root

RUN touch /var/log/cron.log

# Give execution rights on the cron scripts
RUN chmod +x /root/cloudflare-template.sh

RUN crontab -l | { cat; echo "*/1 * * * * bash /root/cloudflare-template.sh >>/var/log/cron.log 2>&1"; } | crontab -

# Run the command on container startup
CMD printenv | sed 's/^\(.*\)$/export \1/g' > /etc/environment && cron && tail -f /var/log/cron.log 