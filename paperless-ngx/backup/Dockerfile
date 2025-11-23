# Take alpine for a lightweigt imnage
FROM alpine:latest

# Install pgdump tool
RUN apk add --no-cache postgresql17-client

# Copy the command file and make it executable
COPY backup.sh /backup/backup.sh
RUN chmod +x /backup/backup.sh

# Write the cron job file
RUN echo "0 6 * * * /backup/backup.sh >> /backup/backup.log 2>&1" > /etc/crontabs/root

# Start cron in foreground with debug level 8
CMD ["crond", "-f", "-d", "8"]