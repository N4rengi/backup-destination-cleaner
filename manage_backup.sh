#!/bin/bash

# Function to get the correct WHM API command for deleting a backup destination
function find_correct_command() {
    echo "Fetching available WHM API commands..."
    correct_command=$(whmapi1 --list | grep -E '^ *backup_destination_delete$' | awk '{print $1}')
    
    if [ -z "$correct_command" ]; then
        echo "Error: Could not find the correct WHM API command for deleting backup destinations."
        exit 1
    fi
    
    echo "Correct WHM API command found: $correct_command"
    echo "$correct_command"
}

# Function to list backup destinations
function list_backup_destinations() {
    echo "Fetching backup destinations..."
    whmapi1 backup_destination_list | grep -E 'name:|id:' | sed 's/^/  /'
}

# Function to delete a backup destination
function delete_backup_destination() {
    local destination_id=$1
    local command=$(find_correct_command)
    
    echo "Attempting to delete backup destination with ID: $destination_id"
    whmapi1 "$command" id="$destination_id"
    
    if [ $? -eq 0 ]; then
        echo "Backup destination with ID $destination_id deleted successfully."
    else
        echo "Failed to delete backup destination with ID $destination_id."
    fi
}

# Function to kill running backup-related processes
function kill_backup_processes() {
    echo "Searching for running backup-related processes..."
    ps aux | grep -E 'backup|validate' | grep -v grep
    local pids=$(ps aux | grep -E 'backup|validate' | grep -v grep | awk '{print $2}')
    
    if [ -z "$pids" ]; then
        echo "No backup-related processes found."
    else
        echo "Killing the following processes: $pids"
        for pid in $pids; do
            kill -9 "$pid"
            if [ $? -eq 0 ]; then
                echo "Process $pid killed successfully."
            else
                echo "Failed to kill process $pid."
            fi
        done
    fi
}

# Main script starts here
echo "Backup Management Script"

# Step 1: List available backup destinations
echo "Step 1: Listing backup destinations..."
list_backup_destinations

# Step 2: Prompt user to enter the ID of the backup destination to delete
echo ""
read -p "Enter the ID of the backup destination to delete (or press Enter to skip): " backup_id

# Step 3: Attempt to delete the selected backup destination if provided
if [ -n "$backup_id" ]; then
    echo "Deleting backup destination..."
    delete_backup_destination "$backup_id"
else
    echo "Skipping backup destination deletion."
fi

# Step 4: Check for running processes and kill them if necessary
echo "Step 4: Checking for and killing running processes..."
kill_backup_processes

# Step 5: Confirm cleanup
echo "Step 5: Final confirmation of backup destinations..."
list_backup_destinations

echo "Script execution completed."
