# The tabs to create. Each tab can either run a command, or
# split (v)ertically/(h)orizontally and run a command in that split
set termCommands to {¬
	{command:"workon simpleloop"}, ¬
	{command:"workon simpleloop && gulp serve"}, ¬
	{splits:{¬
		{command:"postgres -D /usr/local/var/postgres", splitType:"v"}, ¬
		{command:"redis-server /usr/local/etc/redis.conf", splitType:"v"}, ¬
		{command:"rabbitmq-server", splitType:"h"} ¬
			} ¬
		} ¬
		}


# You shouldn't need to change anything below this line
# ------------------------------------------------------------

# Taken from http://stackoverflow.com/questions/13653358/how-to-log-objects-to-a-console-with-applescript
#
# Converts the specified object - which may be of any type - into a string representation for logging/debugging.
# Tries hard to find a readable representation - sadly, simple conversion with `as text` mostly doesn't work with non-primitive types.
# An attempt is made to list the properties of non-primitive types (does not always work), and the result is prefixed with the type (class) name
# and, if present, the object's name and ID.
# EXAMPLE
#       toString(path to desktop)  # -> "[alias] Macintosh HD:Users:mklement:Desktop:"
# To test this subroutine and see the various representations, use the following:
#   repeat with elem in {42, 3.14, "two", true, (current date), {"one", "two", "three"}, {one:1, two:"deux", three:false}, missing value, me,  path to desktop, front window of application (path to frontmost application as text)}
#       log my toString(contents of elem)
#   end repeat
on toString(anyObj)
	local i, txt, errMsg, orgTids, oName, oId, prefix
	set txt to ""
	repeat with i from 1 to 2
		try
			if i is 1 then
				if class of anyObj is list then
					set {orgTids, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {", "}}
					set txt to ("{" & anyObj as string) & "}"
					set AppleScript's text item delimiters to orgTids # '
				else
					set txt to anyObj as string
				end if
			else
				set txt to properties of anyObj as string
			end if
		on error errMsg
			# Trick for records and record-*like* objects:
			# We exploit the fact that the error message contains the desired string representation of the record, so we extract it from there. This (still) works as of AS 2.3 (OS X 10.9).
			try
				set txt to do shell script "egrep -o '\\{.*\\}' <<< " & quoted form of errMsg
			end try
		end try
		if txt is not "" then exit repeat
	end repeat
	set prefix to ""
	if class of anyObj is not in {text, integer, real, boolean, date, list, record} and anyObj is not missing value then
		set prefix to "[" & class of anyObj
		set oName to ""
		set oId to ""
		try
			set oName to name of anyObj
			if oName is not missing value then set prefix to prefix & " name=\"" & oName & "\""
		end try
		try
			set oId to id of anyObj
			if oId is not missing value then set prefix to prefix & " id=" & oId
		end try
		set prefix to prefix & "] "
	end if
	return prefix & txt
end toString

# Create a split to run commands in or simply run a command in a tab
on splitOrRun(aSession, commandRecord)
	#                                                    default value ----v
	set shellCmd to (command of (commandRecord & ({command:""})))
	set splitsCmds to (splits of (commandRecord & ({splits:{}})))
	
	if shellCmd is not "" then
		tell application "iTerm"
			tell aSession
				write text shellCmd
			end tell
		end tell
	else if splitsCmds is not {} then
		repeat with j from 1 to count of splitsCmds
			set splitRecord to item j of splitsCmds
			set splitType to (splitType of (splitRecord & ({splitType:""})))
			set splitCmd to (command of (splitRecord & ({command:""})))
			
			if j = 1 then
				# The tab itself doesn't need to be split.
				tell application "iTerm"
					tell aSession
						write text splitCmd
					end tell
				end tell
			else
				if splitType = "v" then
					tell application "iTerm"
						tell aSession
							set splitSession to split horizontally with default profile
							tell splitSession
								write text splitCmd
							end tell
						end tell
					end tell
				else if splitType = "h" then
					tell application "iTerm"
						tell aSession
							set splitSession to split vertically with default profile
							tell splitSession
								write text splitCmd
							end tell
						end tell
					end tell
				else
					display dialog "Invalid or no splitType defined in " & toString(splitRecord) ¬
						with icon caution
				end if
			end if
		end repeat
	else
		display dialog "We couldn't find a 'command' or 'splits' key in " & toString(commandRecord) ¬
			with icon caution
	end if
end splitOrRun


# Launch or bring to front
if application "iTerm" is running then
	tell application "iTerm"
		create window with default profile
	end tell
else
	activate application "iTerm"
end if


# Main Entry Point
tell application "iTerm"
	repeat with i from 1 to count of termCommands
		set termCommand to item i of termCommands
		
		# since a new window already has a new tab
		# the first command gets sent into this tab
		if i = 1 then
			set mySession to current session of current window
			# applescript wants to send this to iTerm, "my" cancels that.
			my splitOrRun(mySession, termCommand)
		else
			tell current window
				set termTab to create tab with default profile
				set mySession to current session of termTab
				# applescript wants to send this to iTerm, "my" cancels that.
				my splitOrRun(mySession, termCommand)
			end tell
		end if
	end repeat
end tell

