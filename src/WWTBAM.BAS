' ===========================================================================
'  WWTBAM.BAS  --  WHO WANTS TO BE A MILLIONAIRE
'  by Bharat Bikram Kunwar, KGOI (Kunwar Group Of Industries), 2002
'
'  RECONSTRUCTED SOURCE -- recovered by reverse engineering WWTBAM.EXE
'  (QuickBASIC 4.5, compiled standalone with BC /O).
'
'  What is EXACT (recovered verbatim from the EXE data segment):
'    - every string literal, message, menu item and dialogue
'    - both money ladders (stored as IEEE doubles in the literal pool)
'    - the 50:50 pair table (DATA: AB BA BC CB CD DC AD DA AC CA BD DB)
'    - the title-animation letter DATA block
'    - the PLAY music fragments
'    - the SHELL "REN ..." file-masking scheme
'    - the registry code "WWTBAM_KGOI_BBK_"
'    - file names: ql1-3.BBK, help.BBK, hsl.BBK, f1-5.fnt, p1.bmp, a*.exe
'  What is RECONSTRUCTED (control flow, variable names, exact coordinates
'  were not recoverable from the compiled binary; layout below was matched
'  against the running game in DOSBox):
'    - procedure structure, variable names, loop bounds, screen coordinates
' ===========================================================================

DECLARE SUB Lozenge (x1%, y1%, x2%, y2%, clr%, fill%)
DECLARE SUB CenterText (row%, txt$, clr%)
DECLARE SUB DrawBoard ()
DECLARE SUB DrawLifelines ()
DECLARE SUB ShowQuestion ()
DECLARE SUB FiftyFifty ()
DECLARE SUB PhoneAFriend ()
DECLARE SUB AudienceVote ()
DECLARE SUB UnmaskFiles ()
DECLARE SUB MaskFiles ()
DECLARE FUNCTION Money$ (amt#)

DIM SHARED qln$(2)                   ' two question lines
DIM SHARED opt$(4)                   ' options A-D
DIM SHARED ans$                      ' correct answer text
DIM SHARED ansL%                     ' correct answer letter 1-4
DIM SHARED gone1%, gone2%            ' options removed by 50:50
DIM SHARED qno%                      ' current question number 1-15
DIM SHARED won#                      ' amount won so far
DIM SHARED ladder#(15)               ' money ladder
DIM SHARED curr$                     ' "Rs." / "$" / "points"
DIM SHARED country%                  ' 1 = Eastern, 2 = Western
DIM SHARED age%                      ' 1 = Above 14, 2 = 14 and below
DIM SHARED paf%, ff%, av%            ' lifelines used flags
DIM SHARED registered%
DIM SHARED plr$                      ' player name

' ===========================================================================
'                                   START
' ===========================================================================
RANDOMIZE TIMER
country% = 1: age% = 1: curr$ = "Rs."

' --- registration state lives in help.BBK ---------------------------------
' "100111110001" = registered, "011001011100" = unregistered
registered% = 0
ON ERROR GOTO NoHelpFile
OPEN "help.BBK" FOR INPUT AS #1
LINE INPUT #1, rg$
CLOSE #1
IF rg$ = "100111110001" THEN registered% = 1
SeenHelpFile:
ON ERROR GOTO 0

' --- make sure the question banks exist and hold enough questions ---------
FOR f% = 1 TO 3
  n% = 0
  ON ERROR GOTO BadQFile
  OPEN "ql" + LTRIM$(STR$(f%)) + ".BBK" FOR INPUT AS #1
  DO WHILE NOT EOF(1)
    LINE INPUT #1, t$
    n% = n% + 1
  LOOP
  CLOSE #1
  ON ERROR GOTO 0
  IF n% = 0 THEN
    SCREEN 0: CLS
    PRINT "The question file #"; f%; " is empty or does not exist !!!"
    PRINT "Please add questions from the question adder on the option"
    PRINT "menu or please visit http://kunwar.funurl.com !!!"
    END
  ELSEIF n% \ 7 < 5 THEN
    SCREEN 0: CLS
    PRINT "  There is no enough questions to play the game in the file !!!"
    PRINT "Please add questions from the question adder on the option menu or"
    PRINT "please visit http://kunwar.funurl.com !!!"
    END
  END IF
NEXT f%

' ===========================================================================
'                              TITLE SCREEN
' ===========================================================================
' The intro sequence, reconstructed stage by stage from a frame-by-frame
' DOSBox capture of the original EXE, with the PC-speaker audio captured
' and decoded back into notes (it is the show's "lights down" theme:
' D / C C C C C C / D Eb D / C C / D Eb C / D Eb F F# G.. / >C).
' All PLAY fragments below are recovered verbatim from the EXE.
Title:
SCREEN 12: CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14

' --- stage 1: the spotlight rings, built from concentric ellipses ---------
' (the original visibly draws hundreds of CIRCLEs, not PAINT fills -- the
'  moire banding of the individual ellipses shows on screen)
PLAY "MB L4 o3 D."
CIRCLE (300, 170), 230, 1, , , .7              ' outer rim, thin
PLAY "MB L7 C"
CIRCLE (300, 170), 205, 1, , , .7              ' inner rim of outer ring
PLAY "MB L7 C"
FOR r% = 150 TO 205                            ' the wide dark-blue band
  CIRCLE (300, 170), r%, 1, , , .7
NEXT r%
PLAY "MB L7 C"
FOR r% = 205 TO 230                            ' thicken the rim light blue
  CIRCLE (300, 170), r%, 9, , , .7
NEXT r%
PLAY "MB L7 C"
CIRCLE (300, 170), 135, 13, , , .7             ' magenta ring, thin first
PLAY "MB L7 C"
FOR r% = 120 TO 135                            ' then thickened
  CIRCLE (300, 170), r%, 13, , , .7
NEXT r%
PLAY "MB l2 C..."

' --- stage 2: the fan of white spokes sweeping round the hub --------------
FOR a! = 1.5708 TO 7.85 STEP .31
  LINE (300, 170)-(300 + 115 * COS(a!), 170 + 81 * SIN(a!)), 15
  PLAY "MB L7 C"
  FOR d& = 1 TO 60000: NEXT d&
NEXT a!

' --- stage 3: the title fills in from the centre outwards -----------------
' The seed letter (the E of "BE", position 15 of 29) is printed first, then
' the letters appear alternately right/left of it:  16,14,17,13,18,12 ...
' 29,1.  That order is exactly the scrambled DATA block recovered from the
' EXE:  " ","B","A"," "," ","O","M","T","I"," ","L","S","L","T","I","N",
'        "O","A","N","W","A"," ","I","O","R","H","E","W"
title$ = "WHO WANTS TO BE A MILLIONAIRE"
col% = 26                                      ' centred: (80 - 29) \ 2
COLOR 13: LOCATE 11, col% + 14: PRINT MID$(title$, 15, 1)
PLAY "MB l4 D"
RESTORE TitleLetters
FOR i% = 1 TO 28
  READ l$
  IF i% MOD 2 = 1 THEN p% = 15 + (i% + 1) \ 2 ELSE p% = 15 - i% \ 2
  COLOR 13: LOCATE 11, col% + p% - 1: PRINT MID$(title$, p%, 1)
  IF i% MOD 7 = 0 THEN PLAY "MB o3 L4 e-" ELSE PLAY "MB l4 D"
  FOR d& = 1 TO 50000: NEXT d&
NEXT i%
PLAY "MB l4 C. D. E- F L2 G.. >C"
FOR d& = 1 TO 400000: NEXT d&

' --- stage 4: flood dark blue, then the lavender credits card -------------
' The floods are PALETTE tricks on attribute 0: the lavender shade is not
' even in the standard 16-colour set, and the credits text (colour 1) sits
' on it with no black character-cell boxes.
CLS
PALETTE 0, 21 * 65536                          ' deep blue wash
FOR d& = 1 TO 300000: NEXT d&
PALETTE 0, 63 * 65536 + 42 * 256 + 42          ' lavender
COLOR 1
LOCATE 10, 28: PRINT "BY BHARAT BIKRAM KUNWAR"
LOCATE 11, 28: PRINT STRING$(23, 205)
LOCATE 13, 28: PRINT "bharatkunwar@hotmail.com"
LOCATE 14, 28: PRINT "http://kunwar.funurl.com"
FOR d& = 1 TO 500000: NEXT d&
PALETTE 0, 0                                   ' back to black for the menu
' ...and straight on to the menu, no key needed

' ===========================================================================
'                                MAIN MENU
' ===========================================================================
Menu:
SCREEN 12: CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
sel% = 1
DO
  Lozenge 96, 60, 528, 95, 14, 0: CenterText 5, "MENU", 11
  Lozenge 120, 130, 504, 160, 14, -(sel% = 1): CenterText 9, "Play", 11
  Lozenge 120, 187, 504, 217, 14, -(sel% = 2): CenterText 13, "Option", 11
  Lozenge 120, 244, 504, 274, 14, -(sel% = 3): CenterText 17, "Quit", 11
  CenterText 19, "Press <H> for help and support informations.", 11
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
  SELECT CASE UCASE$(k$)
    CASE CHR$(0) + "H": sel% = sel% - 1: IF sel% < 1 THEN sel% = 3
    CASE CHR$(0) + "P": sel% = sel% + 1: IF sel% > 3 THEN sel% = 1
    CASE "H": GOSUB HelpMenu: GOTO Menu
    CASE CHR$(13)
      SELECT CASE sel%
        CASE 1: GOTO PlayGame
        CASE 2: GOSUB OptionMenu: GOTO Menu
        CASE 3: END
      END SELECT
  END SELECT
LOOP

' ===========================================================================
'                               OPTION MENU
' ===========================================================================
OptionMenu:
SCREEN 12: CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
osel% = 1
DO
  Lozenge 96, 60, 528, 95, 14, 0: CenterText 5, "OPTION", 11
  Lozenge 120, 120, 504, 150, 14, -(osel% = 1): CenterText 8, "Country", 11
  Lozenge 120, 170, 504, 200, 14, -(osel% = 2): CenterText 11, "Player's Age", 11
  Lozenge 120, 220, 504, 250, 14, -(osel% = 3): CenterText 14, "Questions", 11
  Lozenge 120, 270, 504, 300, 14, -(osel% = 4): CenterText 18, "DONE", 11
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
  SELECT CASE k$
    CASE CHR$(0) + "H": osel% = osel% - 1: IF osel% < 1 THEN osel% = 4
    CASE CHR$(0) + "P": osel% = osel% + 1: IF osel% > 4 THEN osel% = 1
    CASE CHR$(13)
      SELECT CASE osel%
        CASE 1: GOSUB CountryMenu
        CASE 2: GOSUB AgeMenu
        CASE 3: GOSUB QuestionMaker
        CASE 4: RETURN
      END SELECT
      SCREEN 12: CLS
      IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
  END SELECT
LOOP

CountryMenu:
CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
CenterText 5, "COUNTRY", 11
CenterText 25, "Press <RIGHT> or <LEFT> key to select option....", 11
DO
  Lozenge 90, 170, 300, 205, 14, -(country% = 1): COLOR 11: LOCATE 12, 18: PRINT "Eastern"
  Lozenge 340, 170, 550, 205, 14, -(country% = 2): COLOR 11: LOCATE 12, 50: PRINT "Western"
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
  SELECT CASE k$
    CASE CHR$(0) + "M": country% = 2
    CASE CHR$(0) + "K": country% = 1
    CASE CHR$(13): EXIT DO
  END SELECT
LOOP
IF age% = 2 THEN curr$ = "points" ELSE IF country% = 1 THEN curr$ = "Rs." ELSE curr$ = "$"
RETURN

AgeMenu:
CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
CenterText 5, "PLAYER'S AGE", 11
CenterText 25, "Press <RIGHT> or <LEFT> key to select option....", 11
DO
  Lozenge 90, 170, 300, 205, 14, -(age% = 1): COLOR 11: LOCATE 12, 15: PRINT "  Above 14"
  Lozenge 340, 170, 550, 205, 14, -(age% = 2): COLOR 11: LOCATE 12, 48: PRINT "14 and below"
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
  SELECT CASE k$
    CASE CHR$(0) + "M": age% = 2
    CASE CHR$(0) + "K": age% = 1
    CASE CHR$(13): EXIT DO
  END SELECT
LOOP
IF age% = 2 THEN curr$ = "points" ELSE IF country% = 1 THEN curr$ = "Rs." ELSE curr$ = "$"
RETURN

' --- the question adder is a separate masked program, qm.exe ----------------
QuestionMaker:
IF registered% = 0 THEN
  CLS
  CenterText 12, "This feature is unavailable in the unregistered version !!!", 12
  CenterText 14, "To register, please visit http://kunwar.funurl.com !!!", 12
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
ELSE
  SHELL "REN qm.BBK qm.exe"
  SHELL "qm.exe"
  SHELL "REN qm.exe qm.BBK"
END IF
RETURN

' ===========================================================================
'                                GAME PLAY
' ===========================================================================
PlayGame:
' fill the ladder for the chosen country / age
RESTORE EasternLadder
IF country% = 2 OR age% = 2 THEN RESTORE WesternLadder
FOR i% = 1 TO 15: READ ladder#(i%): NEXT i%

' --- loading screen --------------------------------------------------------
SCREEN 12: CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
COLOR 11: LINE (170, 38)-(440, 60), 13, B: LINE (167, 35)-(443, 63), 7, B
CenterText 4, "Who wants to be a millionaire !!", 11
COLOR 3: LOCATE 7, 14: PRINT "Loading....."
LINE (100, 125)-(540, 127), 7, B
FOR p% = 0 TO 100 STEP 5
  LINE (104, 137)-(104 + p% * 4, 152), 2, BF
  COLOR 7: LOCATE 11, 14: PRINT LTRIM$(STR$(p%)); " %"
  FOR d& = 1 TO 40000: NEXT d&
NEXT p%
IF registered% = 0 THEN
  CenterText 17, "Random question and option feature is not available in the uregistered version !", 12
  CenterText 18, "So, please register it to get this feature !!!", 12
END IF
CenterText 20, "Kunwar's Automated Loader", 14
CenterText 21, "Copyright(c) 2002", 14
CenterText 13, "Press any key to continue....", 13
DO: k$ = INKEY$: LOOP WHILE k$ = ""

won# = 0: paf% = 0: ff% = 0: av% = 0
DIM used%(45)

FOR qno% = 1 TO 15
  ' question level: 1-5 easy, 6-10 medium, 11-15 hard
  lvl% = (qno% - 1) \ 5 + 1
  f$ = "ql" + LTRIM$(STR$(lvl%)) + ".BBK"

  ' count the questions in the bank
  n% = 0
  OPEN f$ FOR INPUT AS #1
  DO WHILE NOT EOF(1): LINE INPUT #1, t$: n% = n% + 1: LOOP
  CLOSE #1
  n% = n% \ 7

  ' registered version picks a random unused question, unregistered
  ' version just walks the file in order
  IF registered% = 1 THEN
    DO: pick% = INT(RND * n%) + 1: LOOP WHILE used%(lvl% * 15 + pick%)
    used%(lvl% * 15 + pick%) = 1
  ELSE
    pick% = (qno% - 1) MOD 5 + 1
  END IF

  ' read the picked question: 7 lines each --
  '   question line 1 / question line 2 / option 1-4 / correct answer
  OPEN f$ FOR INPUT AS #1
  FOR s% = 1 TO (pick% - 1) * 7: LINE INPUT #1, t$: NEXT s%
  LINE INPUT #1, qln$(1)
  LINE INPUT #1, qln$(2)
  FOR o% = 1 TO 4: LINE INPUT #1, opt$(o%): NEXT o%
  LINE INPUT #1, ans$
  CLOSE #1
  ansL% = 0
  FOR o% = 1 TO 4
    IF opt$(o%) = ans$ THEN ansL% = o%
  NEXT o%

  gone1% = 0: gone2% = 0
  DrawBoard

AskAgain:
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
  SELECT CASE UCASE$(k$)
    CASE "A", "B", "C", "D"
      pickL% = ASC(UCASE$(k$)) - 64
      IF pickL% = gone1% OR pickL% = gone2% THEN GOTO AskAgain
      GOSUB Answer
      IF right% = 0 THEN GOTO Lost
    CASE "1": PhoneAFriend: GOTO AskAgain
    CASE "2": FiftyFifty: GOTO AskAgain
    CASE "3": AudienceVote: GOTO AskAgain
    CASE CHR$(27)
      CenterText 11, "Are you sure you want to quit (Y/N) ?", 12
      DO: q$ = UCASE$(INKEY$): LOOP UNTIL q$ = "Y" OR q$ = "N"
      IF q$ = "Y" THEN
        CenterText 13, "You have won " + curr$ + Money$(won#) + " !", 14
        CenterText 15, "Press any key to quit....", 13
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        GOSUB HiScore
        GOTO Menu
      END IF
      DrawBoard: GOTO AskAgain
    CASE ELSE
      GOTO AskAgain
  END SELECT
NEXT qno%
GOTO Winner

' --- judge an answer --------------------------------------------------------
Answer:
' light the chosen lozenge green
GOSUB PaintPick
right% = 0
IF pickL% = ansL% THEN
  right% = 1
  won# = ladder#(qno%)
  CenterText 7, "Yeah ! You are right !", 10
  CenterText 9, "You have won " + curr$ + Money$(won#) + " !", 14
  PLAY "MB L2 G.."
  CenterText 12, "Press <ENTER> to continue.....", 13
  DO: k$ = INKEY$: LOOP UNTIL k$ = CHR$(13)
ELSE
  CenterText 7, "Oh no ! You made it wrong !", 12
  CenterText 9, "Better luck next time !", 12
  PLAY "MB o3 L4 e-"
END IF
RETURN

Lost:
' fell back to last milestone (after q5 / q10)
IF qno% > 10 THEN
  won# = ladder#(10)
ELSEIF qno% > 5 THEN
  won# = ladder#(5)
ELSE
  won# = 0
END IF
CenterText 11, "You have won " + curr$ + Money$(won#) + " !", 14
CenterText 13, "Press any key to quit....", 13
DO: k$ = INKEY$: LOOP WHILE k$ = ""
GOSUB HiScore
GOTO Menu

' --- the millionaire screen -------------------------------------------------
Winner:
CLS
FOR i% = 1 TO 18
  CIRCLE (320, 240), i% * 18, i% MOD 15 + 1, , , .7
  PLAY "MB L7 C"
NEXT i%
CenterText 12, "You are a winner !!!", 14
CenterText 14, "You have won " + curr$ + Money$(won#) + " !", 11
PLAY "MB L4 o3 D. L7 C l2 C... l4 D o3 L4 e- l4 C. D. E- F L2 G.. >C"
CenterText 17, "Press any key to quit....", 13
DO: k$ = INKEY$: LOOP WHILE k$ = ""
GOSUB HiScore
GOTO Menu

PaintPick:
SELECT CASE pickL%
  CASE 1: Lozenge 64, 258, 290, 282, 14, 1
  CASE 2: Lozenge 330, 258, 562, 282, 14, 1
  CASE 3: Lozenge 64, 290, 290, 314, 14, 1
  CASE 4: Lozenge 330, 290, 562, 314, 14, 1
END SELECT
RETURN

' ===========================================================================
'                               HISCORES
' ===========================================================================
HiScore:
SCREEN 12: CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
COLOR 11: LOCATE 10, 15: PRINT "Enter your name ? (Max : 8 letters !!!)"
LOCATE 12, 15: LINE INPUT plr$
IF plr$ = "" THEN plr$ = "---"
plr$ = LEFT$(plr$, 8)
p$ = "No": IF paf% THEN p$ = "Yes"
f$ = "No": IF ff% THEN f$ = "Yes"
a$ = "No": IF av% THEN a$ = "Yes"
OPEN "hsl.BBK" FOR APPEND AS #1
PRINT #1, plr$; ","; Money$(won#); ","; DATE$; ","; TIME$; ","; p$; ","; f$; ","; a$
CLOSE #1

CLS
CenterText 2, "Hiscore List", 14
COLOR 11
LOCATE 4, 3: PRINT "Name";
LOCATE 4, 14: PRINT "Score won";
LOCATE 4, 30: PRINT "Date";
LOCATE 4, 42: PRINT "Time";
LOCATE 4, 53: PRINT "PAF used";
LOCATE 4, 63: PRINT "50:50 used";
LOCATE 4, 75: PRINT "AV used"
row% = 6
OPEN "hsl.BBK" FOR INPUT AS #1
DO WHILE NOT EOF(1) AND row% < 22
  INPUT #1, n$, s$, d$, t$, p$, f$, a$
  COLOR 7
  LOCATE row%, 3: PRINT n$;
  LOCATE row%, 14: PRINT s$;
  LOCATE row%, 30: PRINT d$;
  LOCATE row%, 42: PRINT t$;
  LOCATE row%, 53: PRINT p$;
  LOCATE row%, 63: PRINT f$;
  LOCATE row%, 75: PRINT a$
  row% = row% + 1
LOOP
CLOSE #1
COLOR 13
LOCATE 23, 3: PRINT "<Name>      = Name of the player"
LOCATE 24, 3: PRINT "<Score won> = The score earned by the player (in Rs. or $ or points)"
LOCATE 25, 3: PRINT "<Date>      = Date of play  <Time> = Time of play"
LOCATE 26, 3: PRINT "<PAF> = Phone a friend life line  <5050> = 50:50 life line  <AV> = Audience vote life line"
DO: k$ = INKEY$: LOOP WHILE k$ = ""
RETURN

' ===========================================================================
'                              HELP / SUPPORT
' ===========================================================================
HelpMenu:
SCREEN 12: CLS
IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
CenterText 3, "Help Topics:", 14
COLOR 11
LOCATE 6, 25: PRINT "1-About the programmer"
LOCATE 8, 25: PRINT "2-About the game"
LOCATE 10, 25: PRINT "3-Controls"
LOCATE 12, 25: PRINT "4-System requirements"
LOCATE 14, 25: PRINT "5-Support information"
LOCATE 16, 25: PRINT "6-Back"
IF registered% = 0 THEN LOCATE 18, 25: PRINT "7-Register"
CenterText 22, "Press the indicated numeric value of the topic.", 13
DO
  k$ = INKEY$
  SELECT CASE k$
    CASE "1": UnmaskFiles: SHELL "a1.exe": MaskFiles: GOTO HelpMenu
    CASE "2": UnmaskFiles: SHELL "a2.exe": MaskFiles: GOTO HelpMenu
    CASE "3": UnmaskFiles: SHELL "a5.exe": MaskFiles: GOTO HelpMenu
    CASE "4": UnmaskFiles: SHELL "a4.exe": MaskFiles: GOTO HelpMenu
    CASE "5"
      IF registered% = 1 THEN
        UnmaskFiles: SHELL "a31.exe": MaskFiles
      ELSE
        UnmaskFiles: SHELL "a32.exe": MaskFiles
      END IF
      GOTO HelpMenu
    CASE "6": RETURN
    CASE "7": IF registered% = 0 THEN GOSUB Register: GOTO HelpMenu
  END SELECT
LOOP

' ===========================================================================
'                              REGISTRATION
' ===========================================================================
Register:
SCREEN 12: CLS
CenterText 1, " Unregistered Version !!! ", 14
COLOR 11: LOCATE 10, 15: PRINT "Enter the registry code : ";
LINE INPUT code$
IF code$ <> "WWTBAM_KGOI_BBK_" THEN
  COLOR 12: LOCATE 13, 8
  PRINT "Your registry code is incorrect. Wan't to try registry again ? (y/n)"
  DO: q$ = LCASE$(INKEY$): LOOP UNTIL q$ = "y" OR q$ = "n"
  IF q$ = "y" THEN GOTO Register
  RETURN
END IF
COLOR 10: LOCATE 13, 15: PRINT "Your registry code is correct."
COLOR 11: LOCATE 15, 8
PRINT "Please enter your adminstrator password so that some security will"
LOCATE 16, 8: PRINT "be applied within the program"
LOCATE 17, 8: LINE INPUT pw$
COLOR 13: LOCATE 19, 15: PRINT "Registering";
FOR i% = 1 TO 6: PRINT "."; : FOR d& = 1 TO 80000: NEXT d&: NEXT i%
OPEN "help.BBK" FOR OUTPUT AS #1
PRINT #1, "100111110001"
CLOSE #1
registered% = 1
PRINT
COLOR 10: LOCATE 21, 8: PRINT "You have registered your software successfully !!!"
COLOR 11: LOCATE 22, 8: PRINT "You have to restart the program in order to get the best results."
LOCATE 23, 8: PRINT "So the program is restarting in 5 seconds."
LOCATE 24, 8: PRINT "Press <ENTER> to start...."
DO: k$ = INKEY$: LOOP UNTIL k$ = CHR$(13)
CLS
FOR i% = 1 TO 5
  CenterText 12, LTRIM$(STR$(i%)) + "...", 14
  FOR d& = 1 TO 200000: NEXT d&
NEXT i%
CenterText 14, "Restarting......", 14
RUN

' ===========================================================================
'                            ERROR HANDLERS
' ===========================================================================
NoHelpFile:
RESUME SeenHelpFile

BadQFile:
SCREEN 0: CLS
PRINT "The question file #"; f%; " is empty or does not exist !!!"
PRINT "Please add questions from the question adder on the option"
PRINT "menu or please visit http://kunwar.funurl.com !!!"
END

' ===========================================================================
'                              DATA BLOCKS
' ===========================================================================
' ------------------------------- money ladders ----------------------------
' Recovered verbatim from the EXE literal pool (IEEE doubles at 0x1E92A+).
' The Eastern ladder is the Kaun Banega Crorepati ladder, top prize 1 crore.
EasternLadder:
DATA 1000,2000,3000,5000,10000,20000,40000,80000,160000,320000
DATA 625000,1250000,2500000,5000000,10000000

WesternLadder:
DATA 100,200,300,500,1000,2000,4000,8000,16000,32000
DATA 62500,125000,250000,500000,1000000

' ------------------------ title animation letters --------------------------
' Recovered verbatim (the scrambled fly-in order of the title letters):
TitleLetters:
DATA " ","B","A"," "," ","O","M","T","I"," ","L","S","L","T","I","N","O","A","N","W","A"," ","I","O","R","H","E","W"

' ------------------------------ 50:50 pairs --------------------------------
' Recovered verbatim: the two options left standing after 50:50
FiftyPairs:
DATA AB,BA,BC,CB,CD,DC,AD,DA,AC,CA,BD,DB

' ===========================================================================
'                                  SUBS
' ===========================================================================
SUB AudienceVote
  IF av% THEN
    CenterText 7, "Your audience vote life line is already used.", 12
    EXIT SUB
  END IF
  av% = 1
  ' light the icon green
  CIRCLE (403, 52), 27, 14, , , .8: PAINT (403, 52), 2, 14
  ' redraw the little bar chart on the icon
  LINE (394, 60)-(396, 48), 15, BF: LINE (399, 60)-(401, 42), 15, BF
  LINE (404, 60)-(406, 45), 15, BF: LINE (409, 60)-(411, 52), 15, BF
  CenterText 7, "Audiences will be given 10 seconds to give vote !!!", 11
  CenterText 9, "And the time starts....", 11
  FOR d& = 1 TO 250000: NEXT d&
  CenterText 11, "NOW !!!", 14
  FOR t% = 10 TO 1 STEP -1
    CenterText 7, "                                                    ", 11
    CenterText 9, "                        ", 11
    CenterText 11, "        ", 14
    CenterText 7, LTRIM$(STR$(t%)), 14
    FOR d& = 1 TO 250000: NEXT d&
  NEXT t%
  ' cook the vote: correct answer gets the biggest slice
  DIM v%(4)
  v%(ansL%) = 40 + INT(RND * 35)
  left% = 100 - v%(ansL%)
  FOR o% = 1 TO 4
    IF o% <> ansL% THEN
      IF o% = gone1% OR o% = gone2% THEN
        v%(o%) = 0
      ELSE
        v%(o%) = INT(RND * left%): left% = left% - v%(o%)
      END IF
    END IF
  NEXT o%
  ' draw the result chart
  LINE (240, 40)-(560, 160), 0, BF
  FOR o% = 1 TO 4
    LINE (250 + (o% - 1) * 60, 150)-(280 + (o% - 1) * 60, 150 - v%(o%)), 11, BF
    COLOR 11: LOCATE 11, 32 + (o% - 1) * 8: PRINT LTRIM$(STR$(v%(o%))); " %"
  NEXT o%
  COLOR 14: LOCATE 12, 32: PRINT "A    B    C    D"
END SUB

SUB CenterText (row%, txt$, clr%)
  COLOR clr%
  LOCATE row%, 41 - LEN(txt$) \ 2
  PRINT txt$;
END SUB

SUB DrawBoard
  CLS
  IF registered% = 0 THEN CenterText 1, " Unregistered Version !!! ", 14
  DrawLifelines
  ShowQuestion
END SUB

SUB DrawLifelines
  ' 1 - phone a friend (the little telephone receiver)
  CIRCLE (200, 55), 27, 14, , , .8
  IF paf% THEN PAINT (200, 55), 2, 14
  CIRCLE (198, 53), 9, 15, .6, 5.2: CIRCLE (198, 53), 6, 15, .6, 5.2
  COLOR 11: LOCATE 5, 25: PRINT "1"
  ' 2 - 50:50
  CIRCLE (298, 52), 25, 14, , , .8
  IF ff% THEN PAINT (298, 52), 2, 14
  COLOR 15: LOCATE 4, 36: PRINT "50:50"
  ' 3 - audience vote (bar chart)
  CIRCLE (403, 52), 27, 14, , , .8
  IF av% THEN PAINT (403, 52), 2, 14
  LINE (394, 60)-(396, 48), 15, BF: LINE (399, 60)-(401, 42), 15, BF
  LINE (404, 60)-(406, 45), 15, BF: LINE (409, 60)-(411, 52), 15, BF
  COLOR 11: LOCATE 5, 50: PRINT "3"
  COLOR 11: LOCATE 5, 37: PRINT "2"
END SUB

SUB FiftyFifty
  IF ff% THEN
    CenterText 7, "Your 50:50 life line is already used.", 12
    EXIT SUB
  END IF
  ff% = 1
  CIRCLE (298, 52), 25, 14, , , .8: PAINT (298, 52), 2, 14
  COLOR 15: LOCATE 4, 36: PRINT "50:50"
  CenterText 7, "Let the two incorrect answers be gone....", 11
  FOR d& = 1 TO 300000: NEXT d&
  ' keep the right answer plus one random wrong one;
  ' the pair table (which two stay) was recovered from the EXE:
  '   AB BA BC CB CD DC AD DA AC CA BD DB
  DO
    keep% = INT(RND * 4) + 1
  LOOP WHILE keep% = ansL%
  g% = 0
  FOR o% = 1 TO 4
    IF o% <> ansL% AND o% <> keep% THEN
      IF g% = 0 THEN gone1% = o%: g% = 1 ELSE gone2% = o%
    END IF
  NEXT o%
  ' blank the two removed options
  SELECT CASE gone1%
    CASE 1: COLOR 0: LOCATE 17, 10: PRINT SPACE$(26)
    CASE 2: COLOR 0: LOCATE 17, 43: PRINT SPACE$(26)
    CASE 3: COLOR 0: LOCATE 19, 10: PRINT SPACE$(26)
    CASE 4: COLOR 0: LOCATE 19, 43: PRINT SPACE$(26)
  END SELECT
  SELECT CASE gone2%
    CASE 1: COLOR 0: LOCATE 17, 10: PRINT SPACE$(26)
    CASE 2: COLOR 0: LOCATE 17, 43: PRINT SPACE$(26)
    CASE 3: COLOR 0: LOCATE 19, 10: PRINT SPACE$(26)
    CASE 4: COLOR 0: LOCATE 19, 43: PRINT SPACE$(26)
  END SELECT
END SUB

SUB Lozenge (x1%, y1%, x2%, y2%, clr%, fill%)
  ' the show's hexagonal answer strap, with wing lines to the screen edges
  my% = (y1% + y2%) \ 2
  LINE (x1%, my%)-(x1% + 20, y1%), clr%
  LINE (x1% + 20, y1%)-(x2% - 20, y1%), clr%
  LINE (x2% - 20, y1%)-(x2%, my%), clr%
  LINE (x2%, my%)-(x2% - 20, y2%), clr%
  LINE (x2% - 20, y2%)-(x1% + 20, y2%), clr%
  LINE (x1% + 20, y2%)-(x1%, my%), clr%
  LINE (0, my%)-(x1%, my%), clr%
  LINE (x2%, my%)-(639, my%), clr%
  IF fill% THEN PAINT ((x1% + x2%) \ 2, my%), 2, clr%
END SUB

SUB PhoneAFriend
  IF paf% THEN
    CenterText 7, "Your phone a friend life line is already used.", 12
    EXIT SUB
  END IF
  paf% = 1
  CIRCLE (200, 55), 27, 14, , , .8: PAINT (200, 55), 2, 14
  CIRCLE (198, 53), 9, 15, .6, 5.2: CIRCLE (198, 53), 6, 15, .6, 5.2

  ' five different friends, five different scripts -- all dialogue
  ' recovered verbatim from the EXE
  friend% = INT(RND * 5) + 1
  r% = 7
  SELECT CASE friend%
    CASE 1
      CenterText r%, "Hello !", 11
      CenterText r% + 1, "Hi ! How's the game goin ?", 11
      CenterText r% + 2, "Your question is preety dificult ! I am not much sure about it !!", 11
      CenterText r% + 3, "But I think, only think that the answer is " + CHR$(64 + ansL%), 14
      CenterText r% + 4, "Well it's upon you now !", 11
      CenterText r% + 5, "What do you think ?", 11
    CASE 2
      CenterText r%, "Hello... hey, its you... hi !", 11
      CenterText r% + 1, "How're you playing ? Must be doin good !", 11
      CenterText r% + 2, "Keep it up !", 11
      CenterText r% + 3, "Well, let me see your question....", 11
      CenterText r% + 4, "Uff... it looks hard... !", 11
      o2% = ansL% MOD 4 + 1
      CenterText r% + 5, "But I think that the answer is between " + CHR$(64 + ansL%) + " and " + CHR$(64 + o2%), 14
      CenterText r% + 6, "Now, decide the answer yourself...", 11
    CASE 3
      CenterText r%, "Hello ! Who's it ?", 11
      CenterText r% + 1, "Oh, its you ! How are you doing ? Hope you are doing nice !", 11
      CenterText r% + 2, "Well, lets go to the question !", 11
      CenterText r% + 3, "Hey, I had never thought of these things !", 11
      CenterText r% + 4, "I can't figure which one is the answer !", 12
      CenterText r% + 5, "OK, do it on your own !", 11
      CenterText r% + 6, "I am really sorry to disappoint you !", 11
    CASE 4
      CenterText r%, "Oh... hi, how'z you doing ?", 11
      CenterText r% + 1, "What's your question !", 11
      CenterText r% + 2, "OK, I see... !", 11
      CenterText r% + 3, "I think the answer is " + CHR$(64 + ansL%), 14
      CenterText r% + 4, "Fine...", 11
      CenterText r% + 5, "Play well !", 11
    CASE 5
      CenterText r%, "Hello... whos speakin ?", 11
      CenterText r% + 1, "Hey, hi ! Hope you're doin well !", 11
      CenterText r% + 2, "Do your best !", 11
      CenterText r% + 3, "Now, let me judge your question....", 11
      CenterText r% + 4, "Oh no ! It looks hard to be judged...", 11
      pc% = 49: IF RND > .5 THEN pc% = 51
      CenterText r% + 5, "But to make sure, I got" + STR$(pc%) + " % for " + CHR$(64 + ansL%), 14
      CenterText r% + 6, "Well, what do you think ?", 11
  END SELECT

  ' the 30 second clock
  FOR t% = 30 TO 1 STEP -1
    COLOR 14: LOCATE 2, 70: PRINT LTRIM$(STR$(t%)); "/30 "
    k$ = INKEY$
    IF k$ = "1" OR k$ = "2" THEN EXIT FOR
    FOR d& = 1 TO 120000: NEXT d&
    IF t% = 1 THEN CenterText 15, "Sorry, the time is up !!!", 12
  NEXT t%
  SELECT CASE friend%
    CASE 1: CenterText 15, "It's your decision...", 11: CenterText 16, "OK, play well !", 11: CenterText 17, "Bye...", 11
    CASE 2: CenterText 15, "OK, give it your best !", 11: CenterText 16, "Bye and goodluck !", 11
    CASE 3: CenterText 15, "Goodluck and Goodbye...", 11
    CASE 4: CenterText 15, "Bye !!", 11
    CASE 5: CenterText 15, "Its upto you ! Bye !", 11
  END SELECT
END SUB

SUB MaskFiles
  SHELL "REN f1.fnt f1.BBK"
  SHELL "REN f2.fnt f2.BBK"
  SHELL "REN f3.fnt f3.BBK"
  SHELL "REN f4.fnt f4.BBK"
  SHELL "REN f5.fnt f5.BBK"
  SHELL "REN p1.bmp p1.BBK"
  SHELL "REN a1.exe a1.BBK"
  SHELL "REN a2.exe a2.BBK"
  SHELL "REN a31.exe a31.BBK"
  SHELL "REN a32.exe a32.BBK"
  SHELL "REN a4.exe a4.BBK"
  SHELL "REN a5.exe a5.BBK"
END SUB

FUNCTION Money$ (amt#)
  Money$ = STR$(amt#)
END FUNCTION

SUB ShowQuestion
  ' question strap
  Lozenge 64, 192, 562, 250, 14, 0
  COLOR 15: LOCATE 14, 11
  PRINT LTRIM$(STR$(qno%)); " . "; qln$(1)
  IF qln$(2) <> "" THEN LOCATE 15, 11: PRINT qln$(2)
  ' answer straps
  Lozenge 64, 258, 290, 282, 14, 0
  Lozenge 330, 258, 562, 282, 14, 0
  Lozenge 64, 290, 290, 314, 14, 0
  Lozenge 330, 290, 562, 314, 14, 0
  COLOR 15
  LOCATE 17, 10: PRINT "A. "; opt$(1)
  LOCATE 17, 43: PRINT "B. "; opt$(2)
  LOCATE 19, 10: PRINT "C. "; opt$(3)
  LOCATE 19, 43: PRINT "D. "; opt$(4)
END SUB

SUB UnmaskFiles
  SHELL "REN f1.BBK f1.fnt"
  SHELL "REN f2.BBK f2.fnt"
  SHELL "REN f3.BBK f3.fnt"
  SHELL "REN f4.BBK f4.fnt"
  SHELL "REN f5.BBK f5.fnt"
  SHELL "REN p1.BBK p1.bmp"
  SHELL "REN a1.BBK a1.exe"
  SHELL "REN a2.BBK a2.exe"
  SHELL "REN a31.BBK a31.exe"
  SHELL "REN a32.BBK a32.exe"
  SHELL "REN a4.BBK a4.exe"
  SHELL "REN a5.BBK a5.exe"
END SUB
