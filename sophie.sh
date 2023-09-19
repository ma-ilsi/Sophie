#!/bin/sh

#Copyright ma-ilsi
#Sophie: A Sophisticated Copyright Linter
#Licensed under Apache 2.0 License - see LICENSE file.


#Note: double quotes (") inside filter values of the sophie.config file must be escaped

# -- Global -- #

#Config file
config="$PWD/sophie.config"

#Sophie config commands
supported_commands=" filecabinet notices compliance "

#Current config command
curr_command=""

#Current identifier being talked about
curr_identifier=""

#Name of filter to apply
filter=""

#Value of filter to filter files using
condition=""


# -- File Cabinet -- #

#List of "identifier=find command string (that represents matching files)"
file_cabinet=""

#`find` command, taken from the file cabinet, representing the list of matching files
old_files=""

#`find` command, to be inserted to the file cabinet, representing the list of matching files for the newly adjusted filters
new_files=""


# -- Notices -- #

#List of "identifier=grep command string (that represents copyright notices)"
notices=""

#`grep` command, taken from the notices folder, representing copyright notices
old_notice=""

#`grep` command, to be inserted in to the notices folder, representing copyright notices
new_notice=""


# -- Compliance -- #

#Identifier of the current compliance test
compliance_identifier=""

#Sophie identifiers divide up the file cabinet, this variable holds the current one we are testing compliance for
compliance_files_identifier=""

#Sophie identifiers divide up the notices folder, this variable holds the current one we are testing compliance for
compliance_notice_identifier=""

#Linking preposition part of compliance commands
compliance_prepostion=""

#The list of files we are testing compliance for
compliance_notice_files=""

#The copyright notice template we use to test `compliance_files` with
compliance_notice=""

#No. of passing files
success_count=0

#No. of failing files
fail_count=0



cat "$config" | while read line; do

		if [ -z "$line" ]; then
			continue
		fi

		if printf "%s" "$supported_commands" | grep -q -F " $line "; then
			curr_command=$line
			continue
		fi


		if [ "$curr_command" = "filecabinet" ]; then

			#Identifier
			cut_count=`expr "$line" : "[^\[]*\["`
			curr_identifier=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/\[$//"`
			(( ++cut_count ))
			line=`printf "%s" "$line" | cut -c"$cut_count"-`

			while [ "$line" != "]" ]; do

				#Remove any whitespace at the beginning
				line=`printf "%s" "$line" | sed "s/^[ ]*//"`

				#Filter
				cut_count=`expr "$line" : ".*=\""`
				filter=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/=\"//"`
				(( ++cut_count ))
				line=`printf "%s" "$line" | cut -c"$cut_count"-`


				#Filter condition
				cut_count=`expr "$line" : ".*[^\]\";"`
				condition=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/\";//"`
				(( ++cut_count ))
				line=`printf "%s" "$line" | cut -c"$cut_count"-`

				#Apply filter after fetching old filter condition

				if printf "%s" "$file_cabinet" | grep -q -F "__SOPHIE_IDENTIFIER$curr_identifier="; then
					old_files=`printf "%s" "$file_cabinet" | grep -F "__SOPHIE_IDENTIFIER$curr_identifier="`
					old_files=`printf "%s" "$file_cabinet" | sed "s/__SOPHIE_IDENTIFIER$curr_identifier=//"`
				else
					old_files="find . -type f"
				fi

				if [ "$filter" = "pattern" ]; then

					new_files=`printf "%s%s%s" "$old_files" " __SOPHIE_MARKER " "-regex $condition"`

					#Remove old
					file_cabinet=`printf "%s" "$file_cabinet" | sed "s/__SOPHIE_IDENTIFIER$curr_identifier=.*//"`
					#Put new
					file_cabinet=`printf "%s\n%s" "$file_cabinet" "__SOPHIE_IDENTIFIER$curr_identifier=$new_files"`

					#This filter is done
					filter="" 

				fi
				
			done

			continue
		fi


		if [ "$curr_command" = "notices" ]; then

			#Identifier
			cut_count=`expr "$line" : ".*\["`
			curr_identifier=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/\[$//"`
			(( ++cut_count ))
			line=`printf "%s" "$line" | cut -c"$cut_count"-`

			while [ "$line" != "]" ]; do

				#Remove any whitespace at the beginning
				line=`printf "%s" "$line" | sed "s/^[ ]*//"`

				#Filter
				cut_count=`expr "$line" : ".*=\""`
				filter=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/=\"//"`
				(( ++cut_count ))
				line=`printf "%s" "$line" | cut -c"$cut_count"-`

				#Filter condition
				cut_count=`expr "$line" : ".*[^\\]\";"`
				condition=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/\";//"`
				(( ++cut_count ))
				line=`printf "%s" "$line" | cut -c"$cut_count"-`

				#Apply filter after fetching old filter condition

				if printf "%s" "$notices" | grep -q "$curr_identifier"; then
					old_notice=`printf "%s" "$notices" | grep -F "__SOPHIE_IDENTIFIER$curr_identifier="`
				else
					old_notice="grep -q"
				fi


				if [ "$filter" = "literal" ]; then

					new_notice=`printf "%s%s%s" "$old_notice" " __SOPHIE_MARKER " "-F \"$condition\""`

					#Remove old
					notices=`printf "%s" "$notices" | sed "s/__SOPHIE_IDENTIFIER$curr_identifier=.*//"`
					#Put new
					notices=`printf "%s\n%s" "$notices" "__SOPHIE_IDENTIFIER$curr_identifier=$new_notice"`

					#This filter is done
					filter=""

				fi


				#if [ "$filter" = "pattern" ]; then

					#TODO

				#fi


				#if [ "$filter" = "location" ]; then

					#TODO

				#fi

			done

			continue
		fi


		if [ "$curr_command" = "compliance" ]; then

			#Hardcoded to only support the `in` preposition. Prepositions can be extended easily without breaking configs.

			#Identifier
			cut_count=`expr "$line" : ".*\["`
			curr_identifier=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/\[$//"`
			(( cut_count += 2 ))
			line=`printf "%s" "$line" | cut -c"$cut_count"-`

			compliance_identifier=$curr_identifier

			cut_count=`expr "$line" : "[^ ]*"`
			compliance_notice_identifier=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/ //"`
			(( ++cut_count ))
			line=`printf "%s" "$line" | cut -c"$cut_count"-`

			cut_count=`expr "$line" : ".* "`
			compliance_preposition=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/ //"`
			(( ++cut_count ))
			line=`printf "%s" "$line" | cut -c"$cut_count"-`

			cut_count=`expr "$line" : ".*[^\\]\";"`
			compliance_files_identifier=`printf "%s" "$line" | cut -c1-"$cut_count" | sed "s/\";//"`
			(( ++cut_count ))
			line=`printf "%s" "$line" | cut -c"$cut_count"-`

			if [ -n "$compliance_files_identifier" ]; then

				if  [ -n "$compliance_notice_identifier" ]; then

					if [ -n "$compliance_preposition" ]; then

						compliance_files=`printf "%s" "$file_cabinet" | grep -F "__SOPHIE_IDENTIFIER$compliance_files_identifier="`
						compliance_files=`printf "%s" "$compliance_files" | sed "s/__SOPHIE_IDENTIFIER$compliance_files_identifier=//"`

						compliance_files=`printf "%s" "$compliance_files" | sed "s/ __SOPHIE_MARKER / /g"`

						compliance_files=`$compliance_files`

						compliance_notice=`printf "%s" "$notices" | grep -F "__SOPHIE_IDENTIFIER$compliance_notice_identifier="`

						compliance_notice=`printf "%s" "$notices" | sed "s/__SOPHIE_IDENTIFIER$compliance_notice_identifier=//"`

						compliance_notice=`printf "%s" "$compliance_notice" | sed "s/ __SOPHIE_MARKER / /g"`

					fi

				fi

			fi

			if [ "$line" = "]" ]; then

				#This identifier's value is done being manipulated
				curr_identifier=""

				printf "\nCompliance Check Begins For: %s\n" "$compliance_identifier"

				success_count=0
				fail_count=0

				for file in $compliance_files; do

					if eval "$compliance_notice" "$file"; then
						printf "Success: %s\n" "$file"
						(( ++success_count ))
					else
						printf "Fail: %s\n" "$file"
						(( ++fail_count ))

					fi

				done

				(( fail_count+=$success_count ))

				printf "Compliance Results For %s: %s/%s files passed.\n" "$compliance_identifier" "$success_count" "$fail_count"

			fi

			continue

		fi


done

printf "\n"
