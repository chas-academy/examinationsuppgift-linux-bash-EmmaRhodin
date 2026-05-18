#!/bin/bash


# Checks current users UID
# If UID is not 0 (ROOT), exit with an error message
if ! [ "$EUID" = 0 ] ; then
   echo "Program must be run as root!"
   exit 1 # Exit program
fi

# Array for storing the users we have successfully created
# Used by create_welcome_message
declare -a CREATED_USERNAMES=()

# Array for storing the directories we want to create for each user
declare -a DIRECTORY_ARRAY=("Documents" "Downloads" "Work")



# Create a user with home-directory
create_user() {
	echo "Creating user $username"
	# Create a new user with home-directory using the passed parameter $username
	if ! (sudo useradd -m $username) ; then
		return 1 # Exit as error, echo handled elsewhere
	fi
}

# Create directories to new users home-directory
create_directory() {
	# Loop through each element in the DIRECTORY_ARRAY array
	for index in "${DIRECTORY_ARRAY[@]}" ; do
		# Create the directory currently indexed using $index and passed parameter $username
		if ! (sudo -u $username mkdir -p -m 700 /home/$username/$index) ; then
			echo "Error: create_directory $index failed!"
		fi
	done
}

# Create and format a welcome.txt textfile in the users home-directory
create_welcome_message() {
	# Loop through each element in the CREATED_USERNAMES array
	for user in "${CREATED_USERNAMES[@]}" ; do
		WELCOME_FILEPATH="/home/$user/welcome.txt" # Declare filepath as variable
		# Create the welcome.txt file and populate it with a greeting and userlist
		if ! (echo -e "Välkommen $user\n\nSamtliga användare:\n" > $WELCOME_FILEPATH && # Create the welcome.txt file and add the greeting
			cat /etc/passwd | # Output user account entries
			grep '/home' | # Filter to only include regular user account that have a /home directory
			cut -d: -f1 >> $WELCOME_FILEPATH) ; then # Filter to print only the username, and then adds it to welcome.txt

				echo "Error: create_welcome_message for $user failed!" # Error handling
		fi
	done
}


# For-Loop through each argument
for username in $@ ; do
	# Create user passing the username argument as parameter
	# If user creation is not successful then don't create a directory or add their name to welcome.txt
	if create_user "$username" ; then
		create_directory "$username" # Create directories for current username
		CREATED_USERNAMES+=("$username") # Add current username to an array to be used for create_welcome_message
	else
		echo "Error: create_user $username failed!" # Error handling of create_user
	fi

done

# Create the welcome.txt file in the user home directory and populates it
create_welcome_message
