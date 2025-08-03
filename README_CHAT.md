# AzeriteMOP ChatFrame Module

This module provides enhanced chat functionality for AzeriteMOP, adapted from the GW2_UI chat system.

## Features

### Chat Frame Styling
- Custom chat frame appearance with fade effects
- Styled chat tabs and buttons
- Copy chat functionality
- Character count in edit box
- Mouse wheel scrolling with configurable message count

### Chat Frame Settings
The following settings can be configured via the database:

- `enabled`: Enable/disable the chat frame module
- `fade`: Enable chat frame fade effects
- `editboxHide`: Hide edit box when not in focus
- `addTimestamp`: Add timestamps to chat messages
- `numScrollMessages`: Number of messages to scroll per mouse wheel
- `scrollDownInterval`: Auto-scroll down interval (0 = disabled)
- `maxCopyLines`: Maximum number of lines to copy
- `showTimestamps`: Show timestamps on messages
- `hideEditBox`: Hide edit box when not focused
- `fadeChat`: Enable chat fade effects
- `showEmojis`: Show emoji replacements
- `showURLs`: Show clickable URLs
- `showChatBubbles`: Show chat bubbles

## Slash Commands

### Chat Commands
- `/az chat toggle` - Toggle chat frame module on/off
- `/az chat copy` - Open copy chat window
- `/az chat settings` - Show current chat frame settings
- `/az chat show` - Force show all chat frames
- `/az chat test` - Send a test message to chat
- `/az chat check` - Check chat frame status
- `/az chat refresh` - Refresh chat backgrounds

## Usage

The ChatFrame module is automatically initialized when AzeriteMOP loads. It will:

1. Style all existing chat frames
2. Add copy functionality
3. Apply fade effects
4. Set up mouse wheel scrolling
5. Configure edit box behavior

## Dependencies

- AzeriteMOP Core framework
- WoW API functions for chat handling
- Default WoW textures for styling

## Notes

- The module uses default WoW textures for styling to avoid dependency on custom texture files
- Chat frame settings are stored in the AzeriteMOP database
- The module is compatible with MoP Classic (5.4.x)
- All functionality is optional and can be disabled via settings 