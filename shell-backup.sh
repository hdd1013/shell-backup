#!/bin/bash
# Version 1.0

# Configurations
backup_name=project
src_dir=/target/directory
dest_dir=/backup
# Define the backup threshold (days)
backup_threshold=90

# ================================
# Do not edit below this line
# ================================

# Define the backup filename with timestamp
date_day=$(date +%Y-%m-%d)
date_time=$(date +%H:%M:%S)
backup_file=backup\_\_$backup_name\_\_$date_day\_$date_time.tar.gz
backup_path=$dest_dir/$backup_file

# Calculate the total size of data to be backed up
total_size=$(du -s $src_dir | awk '{print $1}')

echo \[$date_day $date_time\]::$backup_name
echo Backing up as $backup_path
echo Total size is $(($total_size / 1024)) Megabytes \($total_size Bytes\)

# Create a compressed tarball of target folder
# Use pv if the package is installed to show the progress bar
# Otherwise, remove pv and the pipe
if command -v pv > /dev/null 2>&1; then
    tar -cf - $src_dir \
        | pv -s $(du -sb $src_dir | awk '{print $1}') \
        | gzip > $backup_path
else
    tar -czf $backup_path $src_dir
fi

# Remove backups older than $backup_threshold and include the list of deleted files in the notification body
# deleted_files=$(find $dest_dir -name "backup\_\_$backup_name\_\_*.tar.gz" -type f -mtime +$backup_threshold -print -delete)
# 1. List all the files that match the backup filename pattern
# 2. Filter the files that are older than the threshold (Parse the date using the filename)
# 3. Delete the files that are older than the threshold
# 4. Add the deleted files to the notification body

existing_backups=$(find "$dest_dir/" -name "backup__${backup_name}__*.tar.gz" -type f)
deleted_files=""
for file in $existing_backups; do
    # Parse the file date
    file_date=$(echo $file | awk -F'__' '{print $3}')
    file_date=$(echo $file_date | awk -F'.' '{print $1}')
    file_date=$(echo $file_date | awk -F'_' '{print $1" "$2}')
    file_date=$(date -d "$file_date" +%s)

    threshold_date=$(date -d "-$backup_threshold days" +%s)
    if [ $file_date -lt $threshold_date ]; then
        deleted_files="$deleted_files\n$file"
        rm $file
    fi
done

# Remove the first newline character
deleted_files=$(echo -e "$deleted_files" | sed '1d')

if [ -n "$deleted_files" ]; then
    message_body="\n\nThe following backup files were deleted:\n$deleted_files\n"
    echo -e The following backup files were deleted:
    echo -e "$deleted_files"
else
    message_body=""
fi

# Calculate the size of the backup file
backup_size=$(stat -c%s $backup_path)
backup_size_kb=$(($backup_size / 1024))
backup_size_mb=$(($backup_size_kb / 1024))

# Print the backup completion message. Use the appropriate size unit
backup_size_message="The size of the backup file is "
if [ $backup_size_kb -gt 1024 ]; then
    backup_size_message="$backup_size_message $backup_size_mb Megabytes."
else
    backup_size_message="$backup_size_message $backup_size_kb Kilobytes."
fi
echo -e "Backup Completed. $backup_size_message"
echo
