#!/usr/bin/env sh
set -eu

# Appearance
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleAccentColor -int 6
defaults write NSGlobalDomain AppleHighlightColor -string "1.000000 0.749020 0.823529 Pink"
defaults write NSGlobalDomain AppleReduceDesktopTinting -bool true

# Keyboard and text input
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 30
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false

# Locale
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
defaults write NSGlobalDomain AppleLanguages -array "en-GB" "ru-CA"
defaults write NSGlobalDomain AppleLocale -string "en_GB@rg=cazzzz"
defaults write NSGlobalDomain AppleFirstWeekday -dict gregorian -int 2

# Input devices and sound
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.5
defaults write NSGlobalDomain com.apple.sound.beep.volume -float 0
defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool false

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.finder FXPreferredGroupBy -string "Date Added"
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 63
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-bl-corner -int 1
defaults write com.apple.dock wvous-br-corner -int 14

# Screenshots
defaults write com.apple.screencapture location -string "~/Downloads"
defaults write com.apple.screencapture target -string "file"
defaults write com.apple.screencapture style -string "selection"

# Desktop services
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Menu bar clock
defaults write com.apple.menuextra.clock ShowDate -bool false
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowAMPM -bool true

killall Finder >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
