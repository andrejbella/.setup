#!/usr/bin/env bash

# Exit on errors and reject unset variables.
set -euo pipefail

# Close Settings before applying preferences.
# Close the current macOS Settings app.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
# Close the legacy System Preferences app on older macOS releases.
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
# Apply every system-level setting with one administrator authentication prompt.
sudo sh -eu -c '
	# Disable the startup sound.
	nvram SystemAudioVolume=" "
	# Enable Low Power Mode on battery power.
	pmset -b lowpowermode 1
	# Disable Low Power Mode while connected to a power adapter.
	pmset -c lowpowermode 0
	# Make the system Volumes folder visible in Finder.
	chflags nohidden /Volumes
'

# Show scrollbars, disable the first-open confirmation, and turn off text substitutions.
# Always show scrollbars.
defaults write NSGlobalDomain AppleShowScrollBars -string 'Always'
# Disable the first-open confirmation dialog for downloaded applications.
defaults write com.apple.LaunchServices LSQuarantine -bool false
# Disable automatic capitalization.
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable smart dashes.
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Disable automatic period insertion.
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# Disable smart quotes.
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# Disable automatic spelling correction.
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Select English ABC as the default keyboard layout without replacing the enabled input-source list.
# Set ABC as the default ASCII-capable input source.
defaults write com.apple.HIToolbox AppleDefaultAsciiInputSource -dict InputSourceKind 'Keyboard Layout' KeyboardLayoutID -int 252 KeyboardLayoutName ABC
# Set ABC as the current keyboard layout.
defaults write com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID -string 'com.apple.keylayout.ABC'

# Set maximum key repeat, turn the keyboard backlight off after 10 seconds, and disable Mission Control and Spotlight shortcuts.
# Set the keyboard repeat rate to macOS's maximum value.
defaults write -g KeyRepeat -int 2
# Enable automatic keyboard backlight dimming.
defaults write com.apple.BezelServices kDim -bool true
# Turn the keyboard backlight off after 10 seconds of inactivity.
defaults write com.apple.BezelServices kDimTime -int 10
# Locate the symbolic keyboard shortcut preference file.
preference_file="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
# Disable Mission Control, space navigation, Spotlight, and Finder search shortcuts when present.
for hotkey_id in 32 33 34 64 65 79 80 81 82 83 84 85 86 87 88 89 90 91; do
	# Update only shortcut entries that exist on this macOS version.
	if /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:${hotkey_id}" "$preference_file" >/dev/null 2>&1; then
		# Preserve the entry's Boolean or integer value type while disabling the shortcut.
		if [[ "$(/usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:${hotkey_id}:enabled" "$preference_file")" =~ ^[0-9]+$ ]]; then
			/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${hotkey_id}:enabled 0" "$preference_file"
		else
			/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${hotkey_id}:enabled false" "$preference_file"
		fi
	fi
done

# Enable natural scrolling, tap to click, bottom-right secondary click, and dragging without drag lock.
# Enable natural scrolling.
defaults write -g com.apple.swipescrolldirection -bool true
# Apply the trackpad settings to built-in and Bluetooth trackpads.
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
	# Enable tap to click.
	defaults write "$domain" Clicking -bool true
	# Enable a secondary click.
	defaults write "$domain" TrackpadRightClick -bool true
	# Use the bottom-right corner for the secondary click.
	defaults write "$domain" TrackpadCornerSecondaryClick -int 2
	# Enable dragging.
	defaults write "$domain" Dragging -bool true
	# Disable drag lock.
	defaults write "$domain" DragLock -bool false
done
# Enable tap to click for the current hardware profile.
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1

# Use the dark appearance and jump directly to clicked positions in scroll bars.
# Use Dark appearance.
defaults write -g AppleInterfaceStyle -string 'Dark'
# Prevent automatic switching between Light and Dark appearances.
defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false
# Use dark icons and widgets.
defaults write -g AppleIconAppearance -string 'Dark'
# Jump directly to the clicked position in scroll bars.
defaults write -g AppleScrollerPagingBehavior -bool true

# Configure Dock animation, title-bar behavior, recent apps, and Mission Control grouping.
# Use the scale minimize animation.
defaults write com.apple.dock mineffect -string 'scale'
# Fill the window when its title bar is double-clicked.
defaults write -g AppleActionOnDoubleClick -string 'Maximize'
# Minimize windows into their application icons.
defaults write com.apple.dock minimize-to-application -bool true
# Disable application opening animations.
defaults write com.apple.dock launchanim -bool false
# Hide suggested and recent applications from the Dock.
defaults write com.apple.dock show-recents -bool false
# Group Mission Control windows by application.
defaults write com.apple.dock expose-group-apps -bool true

# Configure Finder views, mounted-volume behavior, and .DS_Store file creation.
# Show hidden files by default.
# defaults write com.apple.finder AppleShowAllFiles -bool true
# Show all filename extensions.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show Finder's status bar.
defaults write com.apple.finder ShowStatusBar -bool true
# Show Finder's path bar.
defaults write com.apple.finder ShowPathbar -bool true
# Keep folders first when sorting by name.
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search the current folder by default.
defaults write com.apple.finder FXDefaultSearchScope -string 'SCcf'
# Disable the warning displayed before changing a filename extension.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Open a Finder window when a read-only disk image is mounted.
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
# Open a Finder window when a writable disk image is mounted.
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
# Open a Finder window when removable media is mounted.
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
# Do not create .DS_Store files on network volumes.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Do not create .DS_Store files on USB volumes.
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Configure Finder icon views when their preference dictionaries already exist.
# Locate the Finder preference file.
finder_preferences="$HOME/Library/Preferences/com.apple.finder.plist"
# Update the available Finder icon-view preference dictionaries.
for finder_setting in \
	'Set :DesktopViewSettings:IconViewSettings:showItemInfo true' \
	'Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true' \
	'Set :StandardViewSettings:IconViewSettings:showItemInfo true' \
	'Set :DesktopViewSettings:IconViewSettings:labelOnBottom false' \
	'Set :DesktopViewSettings:IconViewSettings:arrangeBy grid' \
	'Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid' \
	'Set :StandardViewSettings:IconViewSettings:arrangeBy grid'; do
	# Skip any icon-view dictionary that has not been created by Finder yet.
	/usr/libexec/PlistBuddy -c "$finder_setting" "$finder_preferences" 2>/dev/null || true
done

# Show the user Library and system Volumes folders.
# Make the user Library folder visible in Finder.
chflags nohidden "$HOME/Library"
# Remove Finder's hidden attribute from the user Library folder.
xattr -d com.apple.FinderInfo "$HOME/Library" 2>/dev/null || true
# Show the date but not the weekday, and hide the requested menu bar items.
# Show the date in the menu bar clock.
defaults write com.apple.menuextra.clock ShowDate -int 1
# Hide the weekday in the menu bar clock.
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool false
# Hide Spotlight from the menu bar.
defaults write com.apple.Spotlight MenuItemHidden -int 1
# Hide the requested Control Center items from the menu bar.
for item in AirDrop UserSwitcher TimeMachine KeyboardBrightness Weather; do
	# Hide this Control Center item from the menu bar.
	defaults write com.apple.controlcenter "NSStatusItem Visible ${item}" -bool false
done

# Restart the processes that cache the changed settings.
# Restart the preferences cache daemon.
killall cfprefsd 2>/dev/null || true
# Restart the Dock to apply Dock and Mission Control settings.
killall Dock 2>/dev/null || true
# Restart the menu bar service to apply menu bar settings.
killall SystemUIServer 2>/dev/null || true

# Explain the display setting that must be configured manually.
printf 'Done. Set Displays > Built-in Display > More Space manually: macOS has no stable hardware-independent command-line interface for that control.\n'
# Explain when a session restart may be necessary.
printf 'Log out and back in if the ABC input source or shortcut changes do not appear immediately.\n'