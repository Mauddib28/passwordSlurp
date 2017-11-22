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
#  Input: Directory to search
#  Output: List of filenames that contain sensitive informaiton strings (e.g. 'searchTerms')
# -------
function grabGuiltyFiles() {
	searchDir=$1	# Grab the first passed variable to be the directory to be searched
	# Check that the directory to be search actually exists
	if [ ! -d "$searchDir" ]; then	# If the directory does NOT exist
		# Function returns 0 if there was no folder to search
		return 0	# What to do if the directory does NOT exist
	else				# If the directory does exist
		echo "Fuck dis shit YO!"
	fi
}

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
guiltyFiles=($(grep -rnwl '/etc/netctl/' -e 'Key' | uniq))	# Prints list of files that has passwords in it
# Note: The use of outer '(..)' to create and array and not a single object with a list of files
IFS="$OIFS"				# Resets the Internal Field Separator back to the old (stored) one

printGuiltyFiles "${guiltyFiles[@]}"

# Collect a set of SSIDs and Passwords for each file
lengthGF=${#guiltyFiles[@]}

# Testing file grab for completeness (e.g. complete file name, including spaces, are captured)
if [ "$dbg" -ne 0 ]; then
	testGuiltyGrab "${guiltyFiles[@]}"
fi

## Collecting the SSIDs and Passwords
# Collect from /etc/netctl
for (( i=0; i<${lengthGF}; i++ )); do
#for i in "${guiltyFiles[@]}"; do	# Attempt to interate through the contents of the array | Note: Gives issue to not being able to handle filename with spaces
	if [ "$dbg" -ne 0 ]; then
		echo "File location: ${guiltyFiles[$i]}"
	fi
	tmpSSID=$(grep -rnw "${guiltyFiles[$i]}" -e 'ESSID' | cut -d'=' -f 2)	# Grab line with ESSID, retain the parts after 'ESSID='
	tmpPass=$(grep -rnw "${guiltyFiles[$i]}" -e 'Key' | cut -d'=' -f 2)	# Grab line with Key (i.e. Password), retain the parts after 'Key='
	if [ "$dbg" -ne 0 ]; then
		echo -e "\tESSID: $tmpSSID"
		echo -e "\tKey: $tmpPass"
	fi
	SSIDs=( "${SSIDs[@]}" "$tmpSSID" )					# Adds the new SSID to the SSIDs array | Note: Could have used 'SSIDs+=( "$tmpSSID" )'
	Passwords=( "${Passwords[@]}" "$tmpPass" )				# Adds the new Password to the Passwords array
	# Save the collected SSIDs and Passwords into the hard coded files
	echo "$tmpSSID" >> $ssidDumpFile
	echo "$tmpPass" >> $passwordDumpFile
done
echo -e "Number of ESSIDs Collected: ${#SSIDs[@]}"
echo -e "Number of Passwords Collected: ${#Passwords[@]}"

# Note: Important information is sotred is fields:
#	-> i) 'ssid'
#	-> ii) 'psk'
#	-> iii) 'password'
#	-> iv) 'identity' (e.g. username)
#	-> v) 'ESSID'
# Nota Bene: Some will have 'key_mgmt=NONE' meaning that it is an open wireless
OIFS="$IFS"				# Stores the old Internal Field Seperator
IFS=$'\n'				# Sets the new Internal Field Separator to a '\n' (newline) character
# Capture ALL variabltions of files, THEN create a unique list
# TODO: Turn this section of code into a function
guiltyFiles=()	# Clear back out the guiltyFiles array
for i in "${searchTerms[@]}"		# Loop through the elements of the array (e.g. search terms for grep)
do
	guiltyGrab=($(grep -rnwl '/etc/wpa_supplicant/' -e "$i" | uniq))	# Prints list of files that has passwords in it	| ~!~ TEST: Could be due to OIFS/IFS
	guiltyFiles=( "${guiltyFiles[@]}" "${guiltyGrab[@]}" )
done
# Note: The use of outer '(..)' to create and array and not a single object with a list of files
IFS="$OIFS"				# Resets the Internal Field Separator back to the old (stored) one

grabGuiltyFiles '/etc/wpa_supplicant/'	# Works to call search function on a given directory

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
for (( i=0; i<${lengthGF}; i++ )); do
	if [ "$dbg" -ne 0 ]; then
		echo "File location: ${guiltyFiles[$i]}"
	fi
	tmpSSID=$(grep -rnw "${guiltyFiles[$i]}" -e 'ssid' | cut -d'=' -f 2)
	tmpESSID=$(grep -rnw "${guiltyFiles[$i]}" -e 'ESSID' | cut -d'=' -f 2)
	tmpPSK=$(grep -rnw "${guiltyFiles[$i]}" -e 'psk' | cut -d'=' -f 2)
	tmpPass=$(grep -rnw "${guiltyFiles[$i]}" -e 'password' | cut -d'=' -f 2)
	tmpIden=$(grep -rnw "${guiltyFiles[$i]}" -e 'identity' | cut -d'=' -f 2)
	if [ "$dbg" -ne 0 ]; then
		echo -e "-=====-\n\tSSID: $tmpSSID\n\tESSID: $tmpESSID\n\tPSK: $tmpPSK\n\tPassword: $tmpPass\n\tIdentity: $tmpIden\n-====-"
	fi
	# Nota Bene: Two methods of collection here
	#	-> I) General Collection - No Regard to Pairing of Information
	#	-> II) Paired Collection - Maintain Pairing of Information
done
