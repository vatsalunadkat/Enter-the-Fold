[Definitions of severity levels: 
	Critical: Prevents playing or causes crashes
	Major: Broken core gameplay features.
	Minor: Deviates from standards without impacting usability 
	Cosmetic: Affects only appearance]


### BUG-001: Pause does not stop machine timer
- **Screen/Area:** Pause screen during gameplay 
- **Steps to reproduce:**
  1. Press Play
  2. Select a Level
  3. Accept dirty laundry from customer by inputting/solving word prompt
  4. Pause the game while machine is washing laundry 
  5. Wait for 10 seconds
- **Expected:** All aspects/elements of game play are freezed
- **Actual:** The washing machine timer continues ticking down while paused, once it hits 0 - a new word prompt appears
- **Severity:** Major
- **Screenshot:** screenshots/TimerActiveAfterPause.png


### BUG-002: Background music pauses when game is paused
- **Screen/Area:** Gameplay (Pause Menu)
- **Steps to reproduce:**
  1. Start any level
  2. Wait until background music starts playing
  3. Press the pause button
- **Expected:** Background music should continue playing during pause
- **Actual:** Background music stops when the game is paused
- **Severity:** Cosmetic
- **Screenshot:** <>



### BUG-003: Non-alphabetic input (mouse/Esc/etc.) triggers Unicode parsing error
- **Screen/Area:** Gameplay (Pause Menu / Input Handling)
- **Steps to reproduce:**
  1. Start any level
  2. Press the pause button (or press Esc)
  3. Alternatively, click the mouse or press non-alphabetic keys (e.g., Enter, Ctrl, Shift etc)
  4. Observe the console output
- **Expected:** Non-alphabetic inputs (Esc, Enter, Ctrl, Shift, etc.) should be handled correctly or ignored without errors
- **Actual:** Console displays error: "ERROR: Unicode parsing error, some characters were replaced with � (U+FFFD): Unexpected NUL character"
- **Severity:** Minor
- **Screenshot:** <>


### BUG-004: Music setting not applied on startup, only after opening Settings
- **Screen/Area:** Main Menu / Settings (Audio)
- **Steps to reproduce:**
  1. Launch the game
  2. Go to Settings
  3. Set music volume to 0 (mute)
  4. Exit the game
  5. Relaunch the game
  6. Observe music playback
  7. Open Settings again
- **Expected:** Music should remain muted on startup if it was muted in the previous session
- **Actual:** Music plays on startup despite being muted previously; it only mutes after opening the Settings menu
- **Severity:** Minor
- **Screenshot:** <>


### BUG-005: Title overlaps Start button and exceeds screen bounds in portrait resolution
- **Screen/Area:** Main Menu (Home Screen)
- **Steps to reproduce:**
  1. Launch the game in portrait resolution (e.g., 550x977)
  2. Observe the title text ("Enter the fold") on the home screen
- **Expected:** Title should be fully visible within screen bounds and not overlap with UI elements such as the Start button
- **Actual:** Title overlaps the Start button, and parts of the text extend beyond the screen bounds
- **Severity:** Cosmetic
- **Screenshot:** screenshots/GameTitleOutOfBound.png


### BUG-006: No accessible pause button during gameplay
- **Screen/Area:** Gameplay (All Levels)
- **Steps to reproduce:**
  1. Start any level
  2. Attempt to pause the game using on-screen controls
- **Expected:** A visible and accessible pause button should be available on-screen (especially for mobile, where Esc key is unavailable)
- **Actual:** No pause button is visible; the game can only be paused using the Esc key
- **Severity:** Major
- **Screenshot:** <>


### BUG-007: Settings/music control not accessible during gameplay
- **Screen/Area:** Gameplay (Pause menu / In-game UI)
- **Steps to reproduce:**
  1. Start any level
  2. Attempt to access settings (e.g., audio controls) during gameplay or via pause menu
- **Expected:** Settings should be accessible during gameplay (e.g., via pause menu)
- **Actual:** No settings option is available during gameplay, have to exit gameplay and go back to the main menu. 
- **Severity:** Minor
- **Screenshot:** <>


### BUG-008: Day does not end at 8pm if customers or laundry remain
- **Screen/Area:** Gameplay (Day Cycle / End-of-Day Logic)
- **Steps to reproduce:**
  1. Start a level
  2. Continue gameplay until the in-game clock reaches 8pm
  3. Ensure there are active customers or laundry in progress
- **Expected:** The day should end immediately at 8pm regardless of remaining customers or laundry
- **Actual:** The clock stops at 8pm, but the game continues until all customers are served and laundry is completed
- **Severity:** Major
- **Screenshot:** screenshots/LaundryOpenPast8pm.png


### BUG-009: No direct option to continue to next day after Endless mode day ends
- **Screen/Area:** Endless Mode (End-of-Day Screen)
- **Steps to reproduce:**
  1. Start Endless mode
  2. Play until the in-game clock reaches 8pm
  3. Observe the end-of-day screen options
- **Expected:** An option (e.g., "Continue to next day") should be available to proceed directly to the next day without visiting the store
- **Actual:** Only "Go to store" and "Go back to main menu" options are available; continuing to the next day requires entering the store first
- **Severity:** Minor
- **Screenshot:** screenshots/EndlessMode.png
