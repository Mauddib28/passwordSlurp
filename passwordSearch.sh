#!/bin/bash

######
# Purpose: This script searches the host computer for a series of keywords that can function as indicators of a password being stored
#	-> Examples of places to search: /etc/netctl, /etc/wpa_supplicant, /etc/passwd, /etc/shadow
#
# TODO: Have script search for:
#	-> i) clear text passwords (for accounts, for wifi, etc.)
#	-> ii) hashes of passwords (for use with hash-based attacks)
#	-> iii) create a function to search each locaiton to create Password, SSID, Username files
######

## Configuration of Script Variables ##
dbg=0
passwordDumpFile="PasswordSlurp.txt"
ssidDumpFile="SSIDSlurp.txt"
identDumpFile="IdentitySlurp.txt"
# Declaring Arrays 
declare -a SSIDs
declare -a Passwords
declare -a Usernames
declare -a searchTerms=("ssid" "psk" "password" "identity" "ESSID")

## Function Definitions for Script ##
# -------
#  printguiltyFiles: Take in an array of files and prints them out one line at a time to stdout
#
#  Input: Array of filenames
#  Output: None
# -------
function printGuiltyFiles() {
	arr=("$@")	# Create array from the 'list'/array of inputs passed to the function
	echo "The Guilty files are..."
	printf '=%.0s' {1..100}			# Prints to a set format '=%.0s' which means it will always print a single character of '=' no matter what argument is given \
	printf '\n'				#	Note: The '{1..100}' does a bash expansion to '1 2 3 4 .. 99 100'
	printf '%s\n' "${arr[@]}"	# Prints out each file in the array on a new line (Note: Adding a \t to the front only affected the first line)
	printf '=%.0s' {1..100}			# Recreate the border around the found files
	printf '\n'
}

# -------
#  testGuiltyGranb: Take in an array of files and prints out the structure to test all is formatted correctly
#
#  Input: Array of filenames
#  Output: None
# -------
function testGuiltyGrab() {
	arr=("$@")	# Create array from the 'list'/array of inputs passed to the function
	lengthArr=${#arr[@]}
	echo "Printing the contents of 'guiltyFiles'..."
	echo ${arr[@]}
	echo -e "\tLooping through filenames"
	for (( i=0; i<${lengthArr}; i++ )); do
		echo -e "\t\t($i) ${arr[$i]}"
	done
}

# -------
#  grabGuiltyFiles: Take in a directory space and search that directory for sensitive information (using the set 'searchTerms')
#
#  Input: Directory to search, (Optional) Array variable to save result in
#  Output: List of filenames that contain sensitive informaiton strings (e.g. 'searchTerms')
# -------
function grabGuiltyFiles() {
	local __searchDir=$1	# Grab the first passed variable to be the directory to be searched
	local __saveArr=$2	# Grab the second passed variable to be the variable array to have the result stored to
	# Check that the directory to be search actually exists
	if [ ! -d "$__searchDir" ]; then	# If the directory does NOT exist
		# Function returns 0 if there was no folder to search
		return 0	# What to do if the directory does NOT exist
	else				# If the directory does exist
		# Note: Important information is sotred is fields:
		#	-> i) 'ssid'
		#	-> ii) 'psk'
		#	-> iii) 'password'
		#	-> iv) 'identity' (e.g. username)
		#	-> v) 'ESSID'
		# Nota Bene: Some will have 'key_mgmt=NONE' meaning that it is an open wireless
		# Capture ALL variabltions of files, THEN create a unique list
		# TODO: Turn this section of code to use local variables
		guiltyFiles=()		# Clear back out the guiltyFiles array
		## Forcing OIFS/IFS setting before this loop to not cause issues with spaces being translated as separator
		OIFS="$IFS"				# Stores the old Internal Field Seperator
		IFS=$'\n'				# Sets the new Internal Field Separator to a '\n' (newline) character
		for i in "${searchTerms[@]}"		# Loop through the elements of the array (e.g. search terms for grep)
		do
			guiltyGrab=($(grep -rnwl "$__searchDir" -e "$i" | uniq))	# Prints list of files that has passwords in it	| ~!~ TEST: Could be due to OIFS/IFS
			guiltyFiles=( "${guiltyFiles[@]}" "${guiltyGrab[@]}" )
		done
		IFS="$OIFS"				# Resets the Internal Field Separator back to the old (stored) one
		# Note: The use of outer '(..)' to create and array and not a single object with a list of files
		## Check that a list was created and returned something
#		if [[ "$guiltyFiles" ]]; then 	# Check that the variable exists/has something
#			eval $__saveArr="'${guiltyFiles[@]}'"		# Write to the local variable (variable given to function for storing array)
#		else
#			echo "No variable was given"
#			echo "${guiltyFiles[@]}"			# Simply print out the file to stdout
#		fi
	fi
}

# -------
#  searchGuiltyFiles: Take in a list of files and populate the password/username/SSID lists
#
#  Input: List of files to examine
#  Output: None/Populated lists of SSIDs/Passwords/Usernames
# -------
function searchGuiltyFiles() {
	arr=("$@")
	lengthArr=${#arr[@]}
	# Set of local function variables
	local __tmpSSID
	local __tmpESSID
	local __tmpPSK
	local __tmpPass
	local __tmpIden
	for (( i=0; i<${lengthGF}; i++ )); do
		if [ "$dbg" -ne 0 ]; then
			echo "File location: ${guiltyFiles[$i]}"
		fi
		__tmpSSID=$(grep -rnw "${guiltyFiles[$i]}" -e 'ssid' | cut -d'=' -f 2)
		__tmpESSID=$(grep -rnw "${guiltyFiles[$i]}" -e 'ESSID' | cut -d'=' -f 2)
		__tmpPSK=$(grep -rnw "${guiltyFiles[$i]}" -e 'psk' | cut -d'=' -f 2)
		__tmpPass=$(grep -rnw "${guiltyFiles[$i]}" -e 'password' | cut -d'=' -f 2)
		__tmpIden=$(grep -rnw "${guiltyFiles[$i]}" -e 'identity' | cut -d'=' -f 2)
		if [ "$dbg" -ne 0 ]; then
			echo -e "-=====-\n\tSSID: $__tmpSSID\n\tESSID: $__tmpESSID\n\tPSK: $__tmpPSK\n\tPassword: $__tmpPass\n\tIdentity: $__tmpIden\n-====-"
		fi
		# Nota Bene: Two methods of collection here
		#	-> I) General Collection - No Regard to Pairing of Information
		#	-> II) Paired Collection - Maintain Pairing of Information
		## Doing general collection
		if [ "$__tmpSSID" != "$__tmpESSID" ]; then		# Check if SSID and ESSID are NOT the same value
			SSIDs=( "${SSIDs[@]}" "$__tmpSSID" "$__tmpESSID" )			# Add both the seen SSID and ESSID
		else
			SSIDs=( "${SSIDs[@]}" "$__tmpSSID" )				# Add only the ESSID; should be same as the SSID value
		fi
		if [ "$__tmpPass" != "$__tmpPSK" ]; then		# Check if Password and PSK are NOT the same value
			Passwords=( "${Passwords[@]}" "$__tmpPass" "$__tmpPSK" )
		else
			Passwords=( "${Passwords[@]}" "$__tmpPass" )
		fi
		## Dump the found data into local files
		echo "$tmpSSID" >> $ssidDumpFile
		echo "$tmpPass" >> $passwordDumpFile
		echo "$tmpIden" >> $identDumpFile
	done
}

## Main Operational Code of the Script ##
echo "Welcome to the 'passwordSearch.sh' script tool"
echo -e "\tThis is the splash screen for the start-up of the tool"

# Cleaning up the space that this script will run in
echo -e "\tCleaning the space for code running..."
if [ -f "$ssidDumpFile" ]; then
	rm $ssidDumpFile
fi
if [ -f "$passwordDumpFile" ]; then
	rm $passwordDumpFile
fi
echo -e "\tFinished cleaning script space"

# Search through /etc/netctl for file containing the phrase "Key"
# Grep breakdown:
#	-> i) '-r' or '-R' is recursive
#	-> ii) '-n' is line number
#	-> iii)	'-w' stands for match the whole word
#	-> iv) '-l' (lower-case L) can be added to just give the file name of matching files
#	-> v) '-i' ignores case
#	-> vi) '-Z'  will output NULL terminated filenames
echo -e "Searching through the /etc/netctl/ directory....\n\tNote: Will need root account"
#grep -rnw '/etc/netctl/' -e 'Key'	# Searches for the 'Key" phrase in /etc/netctl
OIFS="$IFS"				# Stores the old Internal Field Seperator
IFS=$'\n'				# Sets the new Internal Field Separator to a '\n' (newline) character
#guiltyFiles=($(grep -rnwl '/etc/netctl/' -e 'Key' | uniq))	# Prints list of files that has passwords in it
# Note: The use of outer '(..)' to create and array and not a single object with a list of files
grabGuiltyFiles '/etc/netctl/'		# Works to call search function on a given directory
IFS="$OIFS"				# Resets the Internal Field Separator back to the old (stored) one

guiltyFiles=($(printf "%s\n" "${guiltyFiles[@]}" | sort | uniq))	# Note: Do NOT use the array append technique to create an interable list of filenames (e.g. do ($(...)) instead)
printGuiltyFiles "${guiltyFiles[@]}"
lengthGF=${#guiltyFiles[@]}

# Testing file grab for completeness (e.g. complete file name, including spaces, are captured)
if [ "$dbg" -ne 0 ]; then
	testGuiltyGrab "${guiltyFiles[@]}"
fi

# Collect a set of SSIDs and Passwords for each file
## Collecting the SSIDs and Passwords
# Collect from /etc/netctl
searchGuiltyFiles "${guiltyFiles[@]}"
echo -e "Number of ESSIDs Collected: ${#SSIDs[@]}"
echo -e "Number of Passwords Collected: ${#Passwords[@]}"

OIFS="$IFS"				# Stores the old Internal Field Seperator
IFS=$'\n'				# Sets the new Internal Field Separator to a '\n' (newline) character
grabGuiltyFiles '/etc/wpa_supplicant/'	# Works to call search function on a given directory
IFS="$OIFS"				# Resets the Internal Field Separator back to the old (stored) one

# Print by line, sort, and remove duplicates from collected filenames
guiltyFiles=($(printf "%s\n" "${guiltyFiles[@]}" | sort | uniq))	# Note: Do NOT use the array append technique to create an interable list of filenames (e.g. do ($(...)) instead)
printGuiltyFiles "${guiltyFiles[@]}"
lengthGF=${#guiltyFiles[@]}

# Testing file grab for completeness (e.g. complete file name, including spaces, are captured)
if [ "$dbg" -ne 0 ]; then
	testGuiltyGrab "${guiltyFiles[@]}"
fi

## Collecting the SSIDs, Passwords, and Usernames
# Collect from /etc/wpa_supplicant
searchGuiltyFiles "${guiltyFiles[@]}"
echo -e "Number of ESSIDs Collected: ${#SSIDs[@]}"
echo -e "Number of Passwords Collected: ${#Passwords[@]}"
