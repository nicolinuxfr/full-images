
(* INSTRUCTIONS
This script must be executed with a browser opened. 

Currently supported browers : Safari, Safari Technology Preview, Chrome and Firefox (with GUI scripting enabled).

Script tested on macOS High Sierra and macOS Mojave, should work with olders versions.
*)

-- ======================SELECT BROWSER==============================
global Chrome, Safari, SafariTP, Firefox
set Chrome to false
set Safari to false
set SafariTP to false
set Firefox to false

--tell application "Safari" to activate

tell application "System Events" to set app_name to name of the first process whose frontmost is true

if application "Safari" is running then
	if app_name is "Safari" then set Safari to true
end if

if application "Safari Technology Preview" is running then
	if app_name is "Safari Technology Preview" then set SafariTP to true
end if

if application "Google Chrome" is running then
	if app_name is "Google Chrome" then set Chrome to true
end if

if application "plugin-container" is running then
	if app_name is "Firefox" then set Firefox to true
end if

-- ======================EXTRACT URL==============================
if Safari is true then
	tell application "Safari" to set urlImage to ({URL of current tab of window 1} as string)
else if SafariTP is true then
	tell application "Safari Technology Preview" to set urlImage to ({URL of current tab of window 1} as string)
else if Chrome is true then
	tell application "Google Chrome" to set urlImage to ({get URL of active tab of first window} as string)
else if Firefox is true then
	try
		tell application "System Events"
            keystroke "l" using {command down}
		    delay 0.1
            keystroke "c" using {command down}
		    delay 0.1
            if (the clipboard as string) begins with "http" then
                set urlImage to (the clipboard as string)
            end if
        end tell
	end try
else
	return
end if

-- ======================URL PROCESSING==============================

set urlImageFull to false

if urlImage contains ".jpg?" then
	set AppleScript's text item delimiters to ".jpg?"
	set urlImageFull to text item 1 of urlImage & ".jpg"
else if urlImage contains ".png?" then
	set AppleScript's text item delimiters to ".png?"
	set urlImageFull to text item 1 of urlImage & ".png"
else if urlImage contains ".jpeg?" then
	set AppleScript's text item delimiters to ".jpeg?"
	set urlImageFull to text item 1 of urlImage & ".jpeg"
else if urlImage contains "/w_" then -- Wired
	set AppleScript's text item delimiters to ",c"
	set urlImageFull to text item 1 of urlImage & "00,c" & text item 2 of urlImage
else if urlImage contains ".medium" then -- cloudfront
	set AppleScript's text item delimiters to ".medium"
	set urlImageFull to text item 1 of urlImage
else if urlImage contains "thumbor" then -- Vox
	set AppleScript's text item delimiters to "/cdn"
	set urlImageFull to "https://cdn" & last text item of urlImage
else if urlImage contains "x0w" then -- App Store
	set AppleScript's text item delimiters to "x0w"
	set urlImageFull to text item 1 of urlImage & "00x0w" & text item 2 of urlImage
else if urlImage contains "cdn-apple.com" then -- Apple Store
	set AppleScript's text item delimiters to "wid="
	set temp to text item 1 of urlImage & "wid=3000&hei=3000&fmt"
	set AppleScript's text item delimiters to "&fmt"
	set urlImageFull to temp & text item 2 of urlImage
else if my isWordPress(urlImage) is not false then -- WordPress
	set AppleScript's text item delimiters to my isWordPress(urlImage)
	set urlImageFull to text item 1 of urlImage & text item 2 of urlImage
else
	set AppleScript's text item delimiters to ".png"
	set temp to text item 1 of urlImage & "@2x.png"
	if my verifImageFull(temp) is not false then 
		set urlImageFull to temp
	else
		set temp to text item 1 of urlImage & "_2x.png"
		if my verifImageFull(temp) is not false then 
			set urlImageFull to temp
		else
			return
		end if
	end if
end if

if my verifImageFull(urlImageFull) is not false then
	my openInBrowser(urlImageFull)
else
	return
end if

-- Does the guessed image lead to a 404 or not ?
on verifImageFull(urlImage)
	try
		set codeImageFull to do shell script "curl -s -L -o /dev/null -I -w \"%{http_code}\" " & (quoted form of urlImage)
		if codeImageFull does not begin with "20" then
			return false
		else
			return urlImage
		end if
	on error
		return urlImage
	end try
end verifImageFull


-- Open the new image in previously opened browser
on openInBrowser(urlImage)
	log urlImage
	
	if Safari is true then
		tell application "Safari"
        	close current tab of window 1
            open location urlImage
        end tell
	else if SafariTP is true then
	    tell application "Safari Technology Preview"
        	close current tab of window 1
            open location urlImage
        end tell
    else if Chrome is true then
		tell application "Google Chrome"
            delete tab (active tab index of window 1) of window 1
            open location urlImage
        end tell
	else if Firefox is true then
        tell application "System Events" to keystroke "w" using {command down}
		do shell script "/usr/bin/open -a Firefox " & urlImage
	end if
end openInBrowser

on isWordPress(imageURL)
	try
		return do shell script "echo " & quoted form of imageURL & " | grep -o '\\-[0-9]\\+x[0-9]\\+'"
	on error
		return false
	end try
end isWordPress