#!/bin/bash

######
# Purpose: This script searches the host computer for a series of keywords that can function as indicators of a password being stored
#	-> Examples of places to search: /etc/netctl, /etc/wpa_supplicant, /etc/passwd, /etc/shadow
#
# TODO: Have script search for:
#	-> i) clear text passwords (for accounts, for wifi, etc.)
#	-> ii) hashes of passwords (for use with hash-based attacks)
######

dbg=0
passwordDumpFile="PasswordSlurp.txt"
ssidDumpFile="SSIDSlurp.txt"

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

echo "The Guilty files are..."
printf '=%.0s' {1..100}			# Prints to a set format '=%.0s' which means it will always print a single character of '=' no matter what argument is given \
printf '\n'				#	Note: The '{1..100}' does a bash expansion to '1 2 3 4 .. 99 100'
printf '%s\n' "${guiltyFiles[@]}"	# Prints out each file in the array on a new line (Note: Adding a \t to the front only affected the first line)
printf '=%.0s' {1..100}			# Recreate the border around the found files
printf '\n'

# Collect a set of SSIDs and Passwords for each file
declare -a SSIDs
declare -a Passwords
lengthGF=${#guiltyFiles[@]}

# Testing file grab for completeness (e.g. complete file name, including spaces, are captured)
if [ "$dbg" -ne 0 ]; then
	echo "Printing the contents of 'guiltyFiles'..."
	echo ${guiltyFiles[@]}
	echo -e "\tLooping through filenames"
	for (( i=0; i<${lengthGF}; i++ )); do
		echo -e "\t\t($i) ${guiltyFiles[$i]}"
	done
fi

# Collecting the SSIDs and Passwords
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

