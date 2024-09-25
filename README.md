# shell-backup
Shell script that backs up a src directory as a tarball. Also deletes old archives.

Just a simple backup script with not much going on.
Set the name, source, dest, threshold. You can use crontab to automate the backup.

Chrontab example:
<!-- At 04:00, every day -->
0 4 * * * /docker/shell-backup.sh >> /backup/backup.log 1>&1
