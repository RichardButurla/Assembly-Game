*-----------------------------------------------------------
* Title      : Endless Runner Starter Kit
* Written by : Philip Bourke
* Date       : 25/02/2023
* Description: Endless Runner Project Starter Kit
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

*-----------------------------------------------------------
* Section       : Trap Codes
* Description   : Trap Codes used throughout StarterKit
*-----------------------------------------------------------
* Trap CODES
TC_SCREEN   EQU         33          ; Screen size information trap code
TC_S_SIZE   EQU         00          ; Places 0 in D1.L to retrieve Screen width and height in D1.L
                                    ; First 16 bit Word is screen Width and Second 16 bits is screen Height
TC_KEYCODE  EQU         19          ; Check for pressed keys
TC_DBL_BUF  EQU         92          ; Double Buffer Screen Trap Code
TC_CURSR_P  EQU         11          ; Trap code cursor position

TC_EXIT     EQU         09          ; Exit Trapcode

*-----------------------------------------------------------
* Section       : Charater Setup
* Description   : Size of Player and Enemy and properties
* of these characters e.g Starting Positions and Sizes
*-----------------------------------------------------------
PLYR_W_INIT EQU         15          ; Players initial Width
PLYR_H_INIT EQU         15          ; Players initial Height

PLYR_DFLT_V EQU         00          ; Default Player Velocity
PLYR_JUMP_V EQU        -20          ; Player Jump Velocity
PLYR_DFLT_G EQU         01          ; Player Default Gravity
PLYR_MOVE_X_VEL EQU     01      ;Player X Velocity
PLYR_MOVE_Y_VEL EQU     01      ;Player X Velocity

GND_TRUE    EQU         01          ; Player on Ground True
GND_FALSE   EQU         00          ; Player on Ground False

GAME_OVER_TRUE    EQU   01

RUN_INDEX   EQU         00          ; Player Run Sound Index  
JMP_INDEX   EQU         01          ; Player Jump Sound Index  
COIN_INDEX  EQU         02          ; Player Opps Sound Index

ENMY_W_INIT EQU         08          ; Enemy initial Width
ENMY_H_INIT EQU         128          ; Enemy initial Height
ENEMY_DEFAULT_VELOCITY  EQU     -5

MAX_NUM_COINS       EQU     05
COIN_DFLT_VELOCITY  EQU     -3
COIN_W_INIT         EQU     08
COIN_H_INIT         EQU     08

MAX_BULLET_NUM      EQU     10
BULLET_DFLT_VELOCITY EQU    10   
BULLET_W_INIT       EQU     05
BULLET_H_INIT       EQU     02  
BULLET_FIRED_FALSE  EQU     00
BULLET_FIRED_TRUE  EQU      01

MAX_NUM_PLATFORMS       EQU     03
PLATFORM_DFLT_VELOCITY  EQU     -4
PLATFORM_W_INIT         EQU     120
PLATFORM_H_INIT         EQU     20

*-----------------------------------------------------------
* Section       : Game Stats
* Description   : Points
*-----------------------------------------------------------
POINTS      EQU         01          ; Points added

*-----------------------------------------------------------
* Section       : Keyboard Keys
* Description   : Spacebar and Escape or two functioning keys
* Spacebar to JUMP and Escape to Exit Game
*-----------------------------------------------------------
SPACEBAR    EQU         $20         ; Spacebar ASCII Keycode
ESCAPE      EQU         $1B         ; Escape ASCII Keycode
A_KEY       EQU         $41         ; A ASCII Keycode
W_KEY       EQU         $57         ; A ASCII Keycode
S_KEY       EQU         $53         ; A ASCII Keycode
D_KEY       EQU         $44         ; A ASCII Keycode

*-----------------------------------------------------------
* Subroutine    : Initialise
* Description   : Initialise game data into memory such as 
* sounds and screen size
*-----------------------------------------------------------
INITIALISE:
    ; Initialise Sounds
    BSR     RUN_LOAD                ; Load Run Sound into Memory
    BSR     JUMP_LOAD               ; Load Jump Sound into Memory
    BSR     COIN_LOAD               ; Load Opps (Collision) Sound into Memory

    MOVE.B #0,GAME_IS_OVER          ; False

    ; Screen Size
    MOVE.B  #TC_SCREEN, D0          ; access screen information
    MOVE.L  #TC_S_SIZE, D1          ; placing 0 in D1 triggers loading screen size information
    TRAP    #15                     ; interpret D0 and D1 for screen size
    MOVE.W  D1,         SCREEN_H    ; place screen height in memory location
    SWAP    D1                      ; Swap top and bottom word to retrive screen size
    MOVE.W  D1,         SCREEN_W    ; place screen width in memory location

    ; Place the Player at the center of the screen
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_W,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on X Axis
    MOVE.L  D1,         PLAYER_X    ; Players X Position

    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    MOVE.L  D1,         PLAYER_Y    ; Players Y Position

    ; Initialise Player Score
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  #00,        D1          ; Init Score
    MOVE.L  D1,         PLAYER_SCORE

    ; Initialise Player Velocity
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.B  #PLYR_DFLT_V,D1         ; Init Player Velocity
    MOVE.L  D1,         PLYR_VELOCITY

    ; Initialise Player Gravity
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  #PLYR_DFLT_G,D1         ; Init Player Gravity
    MOVE.L  D1,         PLYR_GRAVITY

    ; Initialize Player on Ground
    MOVE.L  #GND_TRUE,  PLYR_ON_GND ; Init Player on Ground

    ; Initial Position for Enemy
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_W,   D1          ; Place Screen width in D1
    MOVE.L  D1,         ENEMY_X     ; Enemy X Position

    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    MOVE.L  D1,         ENEMY_Y     ; Enemy Y Position

    ;initial velocity for enemy
    CLR.L D1
    MOVE.L #ENEMY_DEFAULT_VELOCITY, D1
    MOVE.L D1,      ENEMY_VELOCITY

    ;initial velocity for enemy
    CLR.L D1
    MOVE.L #COIN_DFLT_VELOCITY, D1
    MOVE.L D1,      COIN_VELOCITY

    ;Initialise coins nums
    CLR.L D0
    CLR.L D1

    MOVE.B #MAX_NUM_COINS, D1 ;Loop counter for 5 coins, We subtract 1 to get 4 since counts down to 0 and DBRA branches again leaving -1 in A1
    SUB.B #1, D1

    LEA     COIN_ARRAY_X, A1
    LEA     COIN_ARRAY_Y, A0

    MOVE.L #100,D3 ; move 20 into d3, this will be used for coins y positions
    MOVE.L #100,D2
COIN_FOR_LOOP: 

    MOVE.L D3,(A0)+ ;move d3(20) into A0 and increment A0 to next coin
    ADD.L  #70,D3   ;add 20 to d3, loop will make coin y positions look like 20,40,60,etc

    MOVE.L D2,(A1)+ ;move element decimal 200 into A1 and increment A1 to next coin
    ADD.L #250,D2

    DBRA      D1,COIN_FOR_LOOP

    ;InitialiseBullets
    ;Initialise coins nums
    CLR.L D0
    CLR.L D1

    MOVE.B #MAX_BULLET_NUM, D1 ;Loop counter for 5 coins, We subtract 1 to get 4 since counts down to 0 and DBRA branches again leaving -1 in A1
    SUB.B #1, D1

    LEA     BULLET_ARRAY_X, A1
    LEA     BULLET_ARRAY_Y, A0
    LEA     BULLET_ARRAY_FIRED,A3

BULLET_FOR_LOOP: 

    MOVE.L PLAYER_Y,(A0)+ ;move d3(20) into A0 and increment A0 to next coin
    MOVE.L PLAYER_X,(A1)+ ;move element decimal 200 into A1 and increment A1 to next coin
    MOVE.L #BULLET_FIRED_FALSE,(A3)+ ;set bullets fired to false
    DBRA   D1,BULLET_FOR_LOOP

    ;initialise Platforms
    CLR.L D0
    CLR.L D1

    MOVE.L #PLATFORM_DFLT_VELOCITY, D0
    MOVE.L D0, PLATFORM_VELOCITY

    CLR.L D0
    CLR.L D1

    ; initialise the 3 positions
    MOVE.L SCREEN_H, D0
    CLR.W D0
    SWAP D0
    MOVE.L #MAX_NUM_PLATFORMS,D1
    DIVU   D1,D0
    ;Divides and puts 3 possible positions into platforms pso. ie, 300 / 3 = 100. We want 100,200,300
    MOVE.L D0, PLATFORM_Y_POS_1
    MOVE.L D0, PLATFORM_Y_POS_2
    ADD.L  D0,PLATFORM_Y_POS_2
    MOVE.L D0, PLATFORM_Y_POS_3
    ADD.L  D0,PLATFORM_Y_POS_3
    ADD.L  D0,PLATFORM_Y_POS_3
    ;Platform 3 is off screen so bring all platforms up
    MOVE.L PLATFORM_Y_POS_1, D1
    DIVU   #2, D0
    SUB.L D0, D1
    MOVE.L D1, PLATFORM_Y_POS_1    	

    MOVE.L PLATFORM_Y_POS_2, D1
    DIVU   #2, D0
    SUB.L D0, D1
    MOVE.L D1, PLATFORM_Y_POS_2  

    MOVE.L PLATFORM_Y_POS_3, D1
    DIVU   #2, D0
    SUB.L D0, D1
    MOVE.L D1, PLATFORM_Y_POS_3  

    CLR.L D0
    CLR.L D1
    CLR.L D2

    ;Set platform Positions

    MOVE.B #MAX_NUM_PLATFORMS, D0
    SUB.B #1,D0

    LEA PLATFORM_ARRAY_X, A0
    LEA PLATFORM_ARRAY_Y, A1

    MOVE.W SCREEN_W, D2
    SUB.W  #50, D2
    MOVE.L D2, (A0)+
    MOVE.L PLATFORM_Y_POS_1, D1
    MOVE.L D1, (A1)+

    SUB.W  #150, D2 ;Offset back a bit
    MOVE.L D2, (A0)+
    MOVE.L PLATFORM_Y_POS_2, D1
    MOVE.L D1, (A1)+

    SUB.W  #200, D2 ;Offset back a bit
    MOVE.L D2, (A0)
    MOVE.L PLATFORM_Y_POS_3, D1
    SUB.L #60,D1
    MOVE.L D1, (A1)


    ;Initialize Delta Time
    CLR.L D1
    MOVE.L  #4, D1
    MOVE.L D1, DELTA_TIME

    ; Enable the screen back buffer(see easy 68k help)
	MOVE.B  #TC_DBL_BUF,D0          ; 92 Enables Double Buffer
    MOVE.B  #17,        D1          ; Combine Tasks
	TRAP	#15                     ; Trap (Perform action)

    ; Clear the screen (see easy 68k help)
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W  #$FF00,     D1          ; Fill Screen Clear
	TRAP	#15                     ; Trap (Perform action)

*-----------------------------------------------------------
* Subroutine    : Game
* Description   : Game including main GameLoop. GameLoop is like
* a while loop in that it runs forever until interupted
* (Input, Update, Draw). The Enemies Run at Player Jump to Avoid
*-----------------------------------------------------------
GAME:
    BSR     PLAY_RUN                ; Play Run Wav
GAMELOOP:
    MOVE.B #8, D0
    TRAP #15
    MOVE.L D1, DELTA_TIME
    ; Main Gameloop
    BSR     INPUT                   ; Check Keyboard Input
    BSR     UPDATE                  ; Update positions and points
    BSR     DRAW                    ; Draw the Scene

DELTA_T:
    MOVE.B #8, D0
    TRAP #15
    SUB.L DELTA_TIME, D1

    CMP.L #4, D1
    BMI.S DELTA_T
    BRA GAMELOOP

*-----------------------------------------------------------
* Subroutine    : Input
* Description   : Process Keyboard Input
*-----------------------------------------------------------
INPUT:
    ; Process Input
    CLR.L   D1                      ; Clear Data Register
    MOVE.B  #TC_KEYCODE,D0          ; Listen for Keys
    MOVE.L #$20415344,  D1          ; All the inputs put in D1 WASD, in One Byte
    TRAP    #15

    CMP.L    #$FF000000, D1
    BEQ     JUMP

    CMP.L    #$0000FF00, D1
    BEQ     SHOOT

    RTS

*-----------------------------------------------------------
* Subroutine    : Update
* Description   : Main update loop update Player and Enemies
*-----------------------------------------------------------
UPDATE:
    BSR     UPDATE_PLAYER
    BSR     UPDATE_ENEMY
    BSR     UPDATE_COINS
    BSR     UPDATE_PLATFORMS
    BSR     CHECK_COIN_COLLISIONS
    BSR     CHECK_PLATFORM_COLLISIONS
    RTS                             ; Return to subroutine  



CHECK_COIN_COLLISIONS:
    LEA COIN_ARRAY_X, A1 ; Load coin X array into address register
    LEA COIN_ARRAY_Y, A2 ; Load coin Y array into address register

    MOVE.W #MAX_NUM_COINS, D0
    SUB.W #1,D0

CHECK_SINGLE_COIN_COLLISION:
    CLR.L D1
    CLR.L D2

    ; Check collision for a single coin
    ; PLAYER_X <= COIN_X + COIN_W &&
    ; PLAYER_X + PLAYER_W >= COIN_X &&
    ; PLAYER_Y <= COIN_Y + COIN_H &&
    ; PLAYER_H + PLAYER_Y >= COIN_Y
    MOVE.L  PLAYER_X, D1          ; Move player X to D1
    MOVE.L  (A1), D2              ; Move coin X to D2
    ADD.L   #COIN_W_INIT, D2      ; Add coin width to D2
    CMP.L   D1, D2                ; Check if there's overlap on X axis
    BLE     COLLISION_CHECK_DONE  ; If no overlap, skip to next coin

    MOVE.L  PLAYER_X, D1          ; Move player X to D1
    MOVE.L  (A1), D2              ; Move coin X to D2
    ADD.L   #PLYR_W_INIT, D1       ; Add player width to D1
    CMP.L   D1, D2                ; Check if there's overlap on X axis
    BGE     COLLISION_CHECK_DONE  ; If no overlap, skip to next coin

    MOVE.L  PLAYER_Y, D1          ; Move player Y to D1
    MOVE.L  (A2), D2              ; Move coin Y to D2
    ADD.L  #COIN_H_INIT, D2      ; Add coin height to D2
    CMP.L   D1, D2                ; Check if there's overlap on Y axis
    BLE     COLLISION_CHECK_DONE  ; If no overlap, skip to next coin

    MOVE.L  PLAYER_Y, D1          ; Move player Y to D1
    MOVE.L  (A2), D2              ; Move coin Y to D2
    ADD.L   #PLYR_H_INIT, D1       ; Add player height to D1
    CMP.L   D1, D2                ; Check if there's overlap on Y axis
    BGE     COLLISION_CHECK_DONE  ; If no overlap, skip to next coin

    ; There's a collision, update points
    BSR     PLAY_COIN               ; Play Opps Wav
    CLR.L D4
    ADD.L #1,PLAYER_SCORE
    MOVE.W  SCREEN_W,   D3         ; Place Screen width in D1
    MOVE.L  D3,         (A1)     ; COIN X Position


COLLISION_CHECK_DONE:
    ADD.W #4, A1 ;next coin memory address
    ADD.W #4, A2
    DBRA D0, CHECK_SINGLE_COIN_COLLISION ; Check next coin
    RTS ; Return to caller

*-----------------------------------------------------------
* Subroutine    : Update player
* Description   : Update Player
*-----------------------------------------------------------
UPDATE_PLAYER:
  
    BSR     MOVE_PLAYER
    BSR     IS_PLAYER_ON_GND        ; Check if player is on ground
    BSR     IS_PLAYER_AT_CEILING    ; Check if player hit the ceiling
    RTS
    
*-----------------------------------------------------------
* Subroutine    : Move player
* Description   : move Player
*-----------------------------------------------------------
MOVE_PLAYER:
    ; Update the Players Positon based on Velocity and Gravity
    CLR.L   D1  
    CLR.L   D2                    ; Clear contents of D1 (XOR is faster)
    MOVE.L  PLYR_VELOCITY, D1       ; Fetch Player Velocity
    MOVE.L  PLYR_GRAVITY, D2        ; Fetch Player Gravity
    ADD.L   D2,         D1          ; Add Gravity to Velocity
    MOVE.L  D1,         PLYR_VELOCITY ; Update Player Velocity
    ADD.L   PLAYER_Y,   D1          ; Add Velocity to Player
    MOVE.L  D1,         PLAYER_Y    ; Update Players Y Position 
    RTS

*-----------------------------------------------------------
* Subroutine    : Update enemy
* Description   : Update enemy
*-----------------------------------------------------------
UPDATE_ENEMY:
    BSR MOVE_ENEMY

    MOVE.L  ENEMY_X,    D1          ; Move the Enemy X Position to D1
    CMP.L   #00,        D1
    BLE     RESET_ENEMY   ; Reset Enemy if off Screen

    RTS
    
*-----------------------------------------------------------
* Subroutine    : Move enemy
* Description   : Moves enemy
*-----------------------------------------------------------
MOVE_ENEMY:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  ENEMY_VELOCITY, D1       
    ADD.L   ENEMY_X,   D1          ; Add Velocity to Enemy
    MOVE.L  D1,         ENEMY_X    ; Update Players Y Position 
    RTS

    *-----------------------------------------------------------
* Subroutine    : Reset Enemy
* Description   : Reset Enemy
*-----------------------------------------------------------
RESET_ENEMY:
    BSR RESET_ENEMY_POSITION
    RTS

    *-----------------------------------------------------------
* Subroutine    : Reset Enemy
* Description   : Reset Enemy if to passes 0 to Right of Screen
*-----------------------------------------------------------
RESET_ENEMY_POSITION:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_W,   D1          ; Place Screen width in D1
    MOVE.L  D1,         ENEMY_X     ; Enemy X Position
    RTS


*-----------------------------------------------------------
* Subroutine    : Update coins
* Description   : Update coins
*-----------------------------------------------------------
UPDATE_COINS:
    BSR MOVE_COINS
    BSR CHECK_COIN_POSITIONS
    BSR CHECK_BULLET_POSITIONS *FOR Some reason bullet checks only work here
    BSR CHECK_IF_BULLETS_FIRED
    RTS

*-----------------------------------------------------------
* Subroutine    : Checks coins Positions
* Description   : Checks coins Positions
*-----------------------------------------------------------
CHECK_COIN_POSITIONS:
    CLR.L D0
    CLR.L D1
    LEA COIN_ARRAY_X, A0
    LEA COIN_ARRAY_Y, A1


    MOVE.B #MAX_NUM_COINS,D0
    SUB.B #1, D0 ;MAX_COINS - 1

CHECK_COIN_POS_LOOP:
    CMP.L   #00,     (A0)
    BLE     RESET_COIN   ; Reset Coin if off Screen

    ADD    #4,A0         ; increment A0 by 4 memory locations. The next CoinArrayX which is a Long
    ADD    #4,A1         ; increment A0 by 4 memory locations. The next CoinArrayX which is a Long
    DBRA D0,CHECK_COIN_POS_LOOP
    

    RTS

*-----------------------------------------------------------
* Subroutine    : Resets coins
* Description   : Resets coins
*-----------------------------------------------------------
RESET_COIN:
    CLR.L   D1
    MOVE.W  SCREEN_W, D1
    MOVE.L  D1, (A0)

    RTS

*-----------------------------------------------------------
* Subroutine    : Randomise Coin Y Pos
* Description   : randomises a y position for a coin
*-----------------------------------------------------------

*-----------------------------------------------------------
* Subroutine    : Move coins
* Description   : move array of coins
*-----------------------------------------------------------
MOVE_COINS:

    LEA COIN_ARRAY_X, A0

    MOVE.B #MAX_NUM_COINS,D0
    SUB.B #1, D0 ;MAX_COINS - 1

MOVE_COIN_LOOP:

    MOVE.L COIN_VELOCITY, D1
    ADD.L (A0), D1          ;Add coin x pos with velocity
    MOVE.L D1, (A0)+        ;Move new xPos to coin x position and increment pointer

    DBRA D0,MOVE_COIN_LOOP

    RTS

*-----------------------------------------------------------
* Subroutine    : Checks bullet fired status
* Description   : Checks if bullets were fired
CHECK_IF_BULLETS_FIRED:

    LEA BULLET_ARRAY_FIRED, A0
    LEA BULLET_ARRAY_X, A1
    LEA BULLET_ARRAY_Y, A2
    CLR.L D2
    CLR.L D3
    CLR.L D0

    MOVE.L #MAX_BULLET_NUM,D0
    SUB.L #1,D0

    CHECK_BULLET_FIRED:
    MOVE.L #BULLET_FIRED_TRUE,D2
    MOVE.L (A0),D3
    CMP D3,D2
    BEQ MOVE_BULLET
    CMP D3,D2
    BNE PLAYER_HOLDS_BULLET

MOVE_BULLET:
    MOVE.L #BULLET_DFLT_VELOCITY, D1
    ADD.L (A1), D1          ;Add bullet x pos with velocity
    MOVE.L D1, (A1)        ;Move new xPos to bullet x position and increment pointer   
 
BULLET_FIRED_CHECK_DONE:
    ADD    #4,A0         ; increment A0 by 4 memory locations. The next BULLET_ARRAY_X which is a Long
    ADD    #4,A1         ; increment A1 by 4 memory locations. The next BULLET_ARRAY_Y which is a Long
    ADD    #4,A2        ; increment A2 by 4 memory locations. The next Bullet_fired_array which is a Long
    DBRA D0,CHECK_BULLET_FIRED
    RTS

PLAYER_HOLDS_BULLET:
    MOVE.L PLAYER_X, D1 ;Player x position
    MOVE.L D1, (A1)        ;Move new xPos to bullet x position and increment pointer
    MOVE.L PLAYER_Y, D1 ;Player x position
    MOVE.L D1, (A2)        ;Move new xPos to bullet x position and increment pointer
    BSR BULLET_FIRED_CHECK_DONE

    RTS

*-----------------------------------------------------------

*-----------------------------------------------------------
* Subroutine    : Checks bullet Positions
* Description   : Checks bullet Positions
*-----------------------------------------------------------
CHECK_BULLET_POSITIONS:
    CLR.L D0
    CLR.L D1
    CLR.L D2
    LEA BULLET_ARRAY_X, A0
    LEA BULLET_ARRAY_Y, A1
    LEA BULLET_ARRAY_FIRED, A2


    MOVE.B #1,D0
    SUB.B #1, D0 ;MAX_COINS - 1

CHECK_BULLET_POS_LOOP:
    MOVE.L (A0),D2
    CMP   SCREEN_W,D2
    BGE     RESET_BULLET   ; Reset Coin if off right side of Screen

    ADD    #4,A0         ; increment A0 by 4 memory locations. The next BULLET_ARRAY_X which is a Long
    ADD    #4,A1         ; increment A1 by 4 memory locations. The next BULLET_ARRAY_Y which is a Long
    ADD    #4,A2        ; increment A2 by 4 memory locations. The next Bullet_fired_array which is a Long
    DBRA D0,CHECK_BULLET_POS_LOOP
    

    RTS

*-----------------------------------------------------------
* Subroutine    : Resets coins
* Description   : Resets coins
*-----------------------------------------------------------
RESET_BULLET:
    CLR.L   D1
    MOVE.L  PLAYER_X, D1
    MOVE.L  D1, (A0)
    MOVE.L #BULLET_FIRED_FALSE, BULLET_ARRAY_FIRED(A2)

    RTS

*-----------------------------------------------------------
* Subroutine    : Update platforms
* Description   : Update coins
*-----------------------------------------------------------
UPDATE_PLATFORMS:
    BSR MOVE_PLATFORMS
    BSR CHECK_PLATFORM_POSITIONS

    RTS

*-----------------------------------------------------------
* Subroutine    : Checks PLATFORMs Positions
* Description   : Checks PLATFORMs Positions
*-----------------------------------------------------------
CHECK_PLATFORM_POSITIONS:
    CLR.L D0
    CLR.L D1
    LEA PLATFORM_ARRAY_X, A0
    LEA PLATFORM_ARRAY_Y, A1


    MOVE.B #MAX_NUM_PLATFORMS,D0
    SUB.B #1, D0 ;MAX_PLATFORMS - 1

CHECK_PLATFORM_POS_LOOP:
    CMP.L   #00,     (A0)
    BLE     RESET_PLATFORM   ; Reset PLATFORM if off Screen

    ADD    #4,A0         ; increment A0 by 4 memory locations. The next PLATFORMArrayX which is a Long
    ADD    #4,A1         ; increment A0 by 4 memory locations. The next PLATFORMArrayX which is a Long
    DBRA D0,CHECK_PLATFORM_POS_LOOP
    

    RTS

*-----------------------------------------------------------
* Subroutine    : Resets PLATFORMS
* Description   : Resets PLATFORMS
*-----------------------------------------------------------
RESET_PLATFORM:
    CLR.L   D1
    MOVE.W  SCREEN_W, D1
    MOVE.L  D1, (A0)

    RTS

*-----------------------------------------------------------
* Subroutine    : Randomise PLATFORM Y Pos
* Description   : randomises a y position for a PLATFORM
*-----------------------------------------------------------

*-----------------------------------------------------------
* Subroutine    : Move PLATFORMS
* Description   : move array of PLATFORMS
*-----------------------------------------------------------
MOVE_PLATFORMS:

    LEA PLATFORM_ARRAY_X, A0
    CLR.L D0

    MOVE.B #MAX_NUM_PLATFORMS,D0
    SUB.B #1, D0 ;MAX_PLATFORMS - 1

MOVE_PLATFORM_LOOP:

    MOVE.L PLATFORM_VELOCITY, D1
    ADD.L (A0), D1          ;Add PLATFORM x pos with velocity
    MOVE.L D1, (A0)+        ;Move new xPos to PLATFORM x position and increment pointer

    DBRA D0,MOVE_PLATFORM_LOOP

    RTS


*-----------------------------------------------------------
* Subroutine    : Check Platform Collisions
* Description   : Check Collisions between player and platform to correctly place player
*-----------------------------------------------------------
CHECK_PLATFORM_COLLISIONS:
    CLR.L D0
    CLR.L D1
    CLR.L D2
    CLR.L D3
    LEA PLATFORM_ARRAY_X, A1
    LEA PLATFORM_ARRAY_Y, A2            
    MOVE.L #MAX_NUM_PLATFORMS, D3
    SUB.L #1, D3

CHECK_SINGLE_PLATFORM_COLLISION:

    
    ;check if players y verlocity is going down
    MOVE.L PLYR_VELOCITY,D0
    CMP #0,D0
    BGT CHECK_ABOVE_COLLISION

    BSR CHECK_BELOW_COLLISION
    ;if less than 1 check collision

    RTS

CHECK_ABOVE_COLLISION:

    MOVE.L  PLAYER_X, D1          ; Move player X to D1
    MOVE.L  (A1), D2              ; Move platform X to D2
    ADD.L   #PLATFORM_W_INIT, D2      ; Add platform width to D2
    CMP.L   D1, D2                ; Check if there's overlap on X axis
    BLE     PLATFORM_COLLISION_CHECK_DONE  ; If no overlap, skip to next platform

    MOVE.L  PLAYER_X, D1          ; Move player X to D1
    MOVE.L  (A1), D2              ; Move platform X to D2
    ADD.L   #PLYR_W_INIT, D1       ; Add player width to D1
    CMP.L   D1, D2                ; Check if there's overlap on X axis
    BGE     PLATFORM_COLLISION_CHECK_DONE  ; If no overlap, skip to next platform
;if player y + height < platform y check next overlap,
    MOVE.L PLAYER_Y, D1
    ADD.L #PLYR_H_INIT,D1
    MOVE.L (A2), D2
    CMP D2, D1
    BLE PLATFORM_COLLISION_CHECK_DONE ;If player y + h is less than platform y, there is no collision

    ;check next overlap
    MOVE.L PLAYER_Y, D1
    MOVE.L (A2), D2
    ADD.L #PLATFORM_H_INIT,D2
    CMP D2, D1
    BGE PLATFORM_COLLISION_CHECK_DONE ;If coin y + h is less than player y, there is no collision

    ;Collision happened
    ;set player vel y to 0 and reposition
    MOVE.L #0,PLYR_VELOCITY ;;Player Yvel = 0
    MOVE.L (A2), D1 ;player y pos == platform y Pos
    SUB.L #PLYR_H_INIT, D1 ; offset player above platform
    MOVE.L D1, PLAYER_Y

PLATFORM_COLLISION_CHECK_DONE:
    ADD.W #4, A1 ;next platform memory address
    ADD.W #4, A2
    DBRA D3, CHECK_SINGLE_PLATFORM_COLLISION
    RTS ; Return to caller

CHECK_BELOW_COLLISION:
    MOVE.L  PLAYER_X, D1          ; Move player X to D1
    MOVE.L  (A1), D2              ; Move platform X to D2
    ADD.L   #PLATFORM_W_INIT, D2      ; Add platform width to D2
    CMP.L   D1, D2                ; Check if there's overlap on X axis
    BLE     PLATFORM_COLLISION_CHECK_DONE  ; If no overlap, skip to next platform

    MOVE.L  PLAYER_X, D1          ; Move player X to D1
    MOVE.L  (A1), D2              ; Move platform X to D2
    ADD.L   #PLYR_W_INIT, D1       ; Add player width to D1
    CMP.L   D1, D2                ; Check if there's overlap on X axis
    BGE     PLATFORM_COLLISION_CHECK_DONE  ; If no overlap, skip to next platform
;if player y + height < platform y check next overlap,
    MOVE.L PLAYER_Y, D1
    ADD.L #PLYR_H_INIT,D1
    MOVE.L (A2), D2
    CMP D2, D1
    BLE PLATFORM_COLLISION_CHECK_DONE ;If player y + h is less than platform y, there is no collision

    ;check next overlap
    MOVE.L PLAYER_Y, D1
    MOVE.L (A2), D2
    ADD.L #PLATFORM_H_INIT,D2
    CMP D2, D1
    BGE PLATFORM_COLLISION_CHECK_DONE ;If coin y + h is less than player y, there is no collision

    ;Collision happened
    ;set player vel y to 0 and reposition
    MOVE.L #1,PLYR_VELOCITY ;;Player Yvel = 1
    MOVE.L (A2), D1 ;player y pos == platform y Pos
    ADD.L #PLYR_H_INIT, D1 ; offset player below 
    ADD.L #PLATFORM_H_INIT, D1 ; offset player below platform
    MOVE.L D1, PLAYER_Y
    BSR PLATFORM_COLLISION_CHECK_DONE

    RTS


*-----------------------------------------------------------
* Subroutine    : Draw
* Description   : Draw Screen
*-----------------------------------------------------------
DRAW: 
    ; Enable back buffer
    MOVE.B  #94,        D0
    TRAP    #15

    ; Clear the screen
    MOVE.B	#TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W	#$FF00,     D1          ; Clear contents
	TRAP    #15                     ; Trap (Perform action)
    
    CLR.L D1
    CLR.L D2
    MOVE.B GAME_IS_OVER,D1
    MOVE.B #GAME_OVER_TRUE,D2
    CMP D1,D2
    BNE DRAW_IN_GAME
    
    BSR DRAW_GAME_OVER_DATA
    RTS

DRAW_IN_GAME:
    BSR     DRAW_PLYR_DATA          ; Draw Draw Score, HUD, Player X and Y
    BSR     DRAW_ENEMY
    BSR     DRAW_COINS
    BSR     DRAW_PLATFORMS
    BSR     DRAW_PLAYER             ; Draw Player
    BSR     DRAW_BULLETS

    
    RTS                             ; Return to subroutine

    *-----------------------------------------------------------
* Subroutine    : Draw Game Over Data
* Description   : Draw Game over text and final score text + score
*-----------------------------------------------------------
DRAW_GAME_OVER_DATA:
    ; Game Over Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$2210,     D1          ; Col 20, Row 20
    TRAP    #15                     ; Trap (Perform action)
    LEA     GAME_OVER_MESSAGE,  A1          ; Score Message
    MOVE    #13,        D0          ; No Line feed
    TRAP    #15                     ; Trap (Perform action

    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$2212,     D1          ; Col 20, Row 20
    TRAP    #15                     ; Trap (Perform action)
    LEA     FINAL_SCORE_MESSAGE,  A1          ; Score Message
    MOVE    #13,        D0          ; No Line feed
    TRAP    #15                     ; Trap (Perform action

    ; Player Score Value
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$2912,     D1          ; Col 09, Row 01
    TRAP    #15                     ; Trap (Perform action)
    MOVE.B  #03,        D0          ; Display number at D1.L
    MOVE.L  PLAYER_SCORE,D1         ; Move Score to D1.L
    TRAP    #15   

*-----------------------------------------------------------
* Subroutine    : Draw Player Data
* Description   : Draw Player X, Y, Velocity, Gravity and OnGround
*-----------------------------------------------------------
DRAW_PLYR_DATA:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)

    ; Player Score Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$0201,     D1          ; Col 02, Row 01
    TRAP    #15                     ; Trap (Perform action)
    LEA     SCORE_MSG,  A1          ; Score Message
    MOVE    #13,        D0          ; No Line feed
    TRAP    #15                     ; Trap (Perform action)

    ; Player Score Value
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$0901,     D1          ; Col 09, Row 01
    TRAP    #15                     ; Trap (Perform action)
    MOVE.B  #03,        D0          ; Display number at D1.L
    MOVE.L  PLAYER_SCORE,D1         ; Move Score to D1.L
    TRAP    #15                     ; Trap (Perform action)

    RTS  
    
*-----------------------------------------------------------
* Subroutine    : Player is on Ground
* Description   : Check if the Player is on or off Ground
*-----------------------------------------------------------
IS_PLAYER_ON_GND:
    ; Check if Player is on Ground
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    CLR.L   D2                      ; Clear contents of D2 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen height in D1
    ;DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    SUB.L   #10, D1
    MOVE.L  PLAYER_Y,   D2          ; Player Y Position
    CMP     D1,         D2          ; Compare bottom of Screen with Players Y Position 
    BGE     SET_ON_GROUND           ; The Player is on the Ground Plane
    BLT     SET_OFF_GROUND          ; The Player is off the Ground
    RTS                             ; Return to subroutine


*-----------------------------------------------------------
* Subroutine    : On Ground
* Description   : Set the Player On Ground
*-----------------------------------------------------------
SET_ON_GROUND:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    ;DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    SUB.L   #10, D1
    MOVE.L  D1,         PLAYER_Y    ; Reset the Player Y Position
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  #00,        D1          ; Player Velocity
    MOVE.L  D1,         PLYR_VELOCITY ; Set Player Velocity
    MOVE.L  #GND_TRUE,  PLYR_ON_GND ; Player is on Ground
    MOVE.B  #GAME_OVER_TRUE,GAME_IS_OVER
    RTS

*-----------------------------------------------------------
* Subroutine    : Player is at the ceiling
* Description   : Set the Player at ceiling
*-----------------------------------------------------------
IS_PLAYER_AT_CEILING:
    CLR.L D1
    CLR.L D2
    MOVE.W #5,  D1
    MOVE.L PLAYER_Y, D2
    CMP D1,     D2
    BLT SET_AT_CEILING
    RTS

*-----------------------------------------------------------
* Subroutine    : Player is at the ceiling
* Description   : Set the Player at ceiling
*-----------------------------------------------------------
SET_AT_CEILING:
    CLR.L D1
    MOVE.L #00,     D1
    MOVE.L  D1,         PLYR_VELOCITY ; Set Player Velocity
    CLR.L D1
    MOVE.L  #5,          D1
    MOVE.L  D1,         PLAYER_Y
    RTS    
*-----------------------------------------------------------
* Subroutine    : Off Ground
* Description   : Set the Player Off Ground
*-----------------------------------------------------------
SET_OFF_GROUND:
    MOVE.L  #GND_FALSE, PLYR_ON_GND ; Player if off Ground
    RTS                             ; Return to subroutine


*-----------------------------------------------------------
* Subroutine    : Jump
* Description   : Perform a Jump
*-----------------------------------------------------------
JUMP:
    BSR     PERFORM_JUMP            ; Do Jump
PERFORM_JUMP:
    ;BSR     PLAY_JUMP               ; Play jump sound
    MOVE.L  #PLYR_JUMP_V,PLYR_VELOCITY ; Set the players velocity to true
    RTS                             ; Return to subroutine


SHOOT:


    *-----------------------------------------------------------
* Subroutine    : Move
* Description   : Move player
*-----------------------------------------------------------
MOVE_PLAYER_LEFT:
    SUB.L #PLYR_MOVE_X_VEL, PLAYER_X
    RTS                                  ; Return to subroutine
MOVE_PLAYER_RIGHT:
    ADD.L #PLYR_MOVE_X_VEL, PLAYER_X
    RTS                                  ; Return to subroutine
MOVE_PLAYER_UP:
    SUB.L #PLYR_MOVE_Y_VEL, PLAYER_Y
    RTS                                  ; Return to subroutine
MOVE_PLAYER_DOWN:
    ADD.L #PLYR_MOVE_Y_VEL, PLAYER_Y
    RTS                                  ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Idle
* Description   : Perform a Idle
*----------------------------------------------------------- 
IDLE:
    BSR     PLAY_RUN                ; Play Run Wav
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutines   : Sound Load and Play
* Description   : Initialise game sounds into memory 
* Current Sounds are RUN, JUMP and Opps for Collision
*-----------------------------------------------------------
RUN_LOAD:
    LEA     RUN_WAV,    A1          ; Load Wav File into A1
    MOVE    #RUN_INDEX, D1          ; Assign it INDEX
    MOVE    #71,        D0          ; Load into memory
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

PLAY_RUN:
    MOVE    #RUN_INDEX, D1          ; Load Sound INDEX
    MOVE    #72,        D0          ; Play Sound
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

JUMP_LOAD:
    LEA     JUMP_WAV,   A1          ; Load Wav File into A1
    MOVE    #JMP_INDEX, D1          ; Assign it INDEX
    MOVE    #71,        D0          ; Load into memory
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

PLAY_JUMP:
    MOVE    #JMP_INDEX, D1          ; Load Sound INDEX
    MOVE    #72,        D0          ; Play Sound
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

COIN_LOAD:
    LEA     COIN_WAV,   A1          ; Load Wav File into A1
    MOVE    #COIN_INDEX,D1          ; Assign it INDEX
    MOVE    #71,        D0          ; Load into memory
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

PLAY_COIN:
    MOVE    #COIN_INDEX,D1          ; Load Sound INDEX
    MOVE    #72,        D0          ; Play Sound
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Draw Player
* Description   : Draw Player Square
*-----------------------------------------------------------
DRAW_PLAYER:
    ; Set Pixel Colors
    MOVE.L  #WHITE,     D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height
    MOVE.L  PLAYER_X,   D1          ; X
    MOVE.L  PLAYER_Y,   D2          ; Y
    MOVE.L  PLAYER_X,   D3
    ADD.L   #PLYR_W_INIT,   D3      ; Width
    MOVE.L  PLAYER_Y,   D4 
    ADD.L   #PLYR_H_INIT,   D4      ; Height
    
    ; Draw Player
    MOVE.B  #87,        D0          ; Draw Player
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Draw Coins
* Description   : Draw Coin Squares
*-----------------------------------------------------------
DRAW_COINS:

    ; Set Pixel Colors
    MOVE.L  #YELLOW,     D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    CLR.L D0
    CLR.L D1
    CLR.L D2
    CLR.L D3
    CLR.L D4
    CLR.L D5

    ; Set X, Y, Width and Height
    LEA     COIN_ARRAY_X, A0
    LEA     COIN_ARRAY_Y, A1

    MOVE.B #MAX_NUM_COINS, D5
    SUB.B #1,D5     ;Our index which is MAX_COINS - 1

DRAW_COIN_LOOP:
    MOVE.L (A0), D1     ;Coin X Pos
    MOVE.L (A1), D2     ;Coin Y Pos
    MOVE.L (A0)+, D3     ;Coin X Pos that we will add width onto and increment pointer
    ADD.L #COIN_W_INIT, D3
    MOVE.L (A1)+, D4     ;Coin Y Pos that we will add height onto and increment pointer
    ADD.L #COIN_H_INIT, D4

    ; Draw Coin
    MOVE.B  #88,        D0          ; Draw Player
    TRAP    #15                     ; Trap (Perform action)

    DBRA D5,DRAW_COIN_LOOP

    RTS


    *-----------------------------------------------------------
* Subroutine    : Draw Platforms
* Description   : Draw Platform Rectangles
*-----------------------------------------------------------
DRAW_PLATFORMS:

    ; Set Pixel Colors
    MOVE.L  #GREEN,     D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    CLR.L D0
    CLR.L D1
    CLR.L D2
    CLR.L D3
    CLR.L D4
    CLR.L D5

    ; Set X, Y, Width and Height
    LEA     PLATFORM_ARRAY_X, A0
    LEA     PLATFORM_ARRAY_Y, A1

    MOVE.B #MAX_NUM_PLATFORMS, D5
    SUB.B #1,D5     ;Our index which is MAX_PLATFORMS - 1

DRAW_PLATFORM_LOOP:
    MOVE.L (A0), D1     ;Platform X Pos
    MOVE.L (A1), D2     ;Paltform Y Pos
    MOVE.L (A0)+, D3     ;Platform X Pos that we will add width onto and increment pointer
    ADD.L #PLATFORM_W_INIT, D3
    MOVE.L (A1)+, D4     ;Platform Y Pos that we will add height onto and increment pointer
    ADD.L #PLATFORM_H_INIT, D4

    ; Draw Platform
    MOVE.B  #87,        D0          ; Draw Platform
    TRAP    #15                     ; Trap (Perform action)

    DBRA D5,DRAW_PLATFORM_LOOP

    RTS

*-----------------------------------------------------------
* Subroutine    : Draw Bullets
* Description   : Draw Bullet Circles
*-----------------------------------------------------------
DRAW_BULLETS:

    ; Set Pixel Colors
    MOVE.L  #YELLOW,     D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    CLR.L D0
    CLR.L D1
    CLR.L D2
    CLR.L D3
    CLR.L D4
    CLR.L D5

    ; Set X, Y, Width and Height
    LEA     BULLET_ARRAY_X, A0
    LEA     BULLET_ARRAY_Y, A1

    MOVE.B #MAX_BULLET_NUM, D5
    SUB.B #1,D5     ;Our index which is MAX_BULLETS - 1

DRAW_BULLET_LOOP:
    MOVE.L (A0), D1     ;Bullet X Pos
    MOVE.L (A1), D2     ;Bullet Y Pos
    MOVE.L (A0)+, D3     ;Bullet X Pos that we will add width onto and increment pointer
    ADD.L #BULLET_W_INIT, D3
    MOVE.L (A1)+, D4     ;Bullet Y Pos that we will add height onto and increment pointer
    ADD.L #BULLET_W_INIT, D4

    ; Draw Bullet
    MOVE.B  #88,        D0          ; Draw bullet
    TRAP    #15                     ; Trap (Perform action)

    DBRA D5,DRAW_BULLET_LOOP

    RTS


*-----------------------------------------------------------
* Subroutine    : Draw Enemy
* Description   : Draw Enemy Square
*-----------------------------------------------------------
DRAW_ENEMY:
    ; Set Pixel Colors
    MOVE.L  #RED,       D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height
    MOVE.L  ENEMY_X,    D1          ; X
    MOVE.L  ENEMY_Y,    D2          ; Y
    MOVE.L  ENEMY_X,    D3
    ADD.L   #ENMY_W_INIT,   D3      ; Width
    MOVE.L  ENEMY_Y,    D4 
    ADD.L   #ENMY_H_INIT,   D4      ; Height
    
    ; Draw Enemy    
    MOVE.B  #87,        D0          ; Draw Enemy
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine
*-----------------------------------------------------------
* Subroutine    : EXIT
* Description   : Exit message and End Game
*-----------------------------------------------------------
EXIT:
    ; Show if Exiting is Running
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$4004,     D1          ; Col 40, Row 1
    TRAP    #15                     ; Trap (Perform action)
    LEA     EXIT_MSG,   A1          ; Exit
    MOVE    #13,        D0          ; No Line feed
    TRAP    #15                     ; Trap (Perform action)
    MOVE.B  #TC_EXIT,   D0          ; Exit Code
    TRAP    #15                     ; Trap (Perform action)
    SIMHALT

*-----------------------------------------------------------
* Section       : Messages
* Description   : Messages to Print on Console, names should be
* self documenting
*-----------------------------------------------------------
SCORE_MSG       DC.B    'Score : ', 0       ; Score Message
KEYCODE_MSG     DC.B    'KeyCode : ', 0     ; Keycode Message
JUMP_MSG        DC.B    'Jump....', 0       ; Jump Message
GAME_OVER_MESSAGE       DC.B    'GAME OVER!',0       ; Score Message
FINAL_SCORE_MESSAGE       DC.B    'FINAL SCORE: ',0       ; Score Message

EXIT_MSG        DC.B    'Exiting....', 0    ; Exit Message

*-----------------------------------------------------------
* Section       : Graphic Colors
* Description   : Screen Pixel Color
*-----------------------------------------------------------
WHITE           EQU     $00FFFFFF
RED             EQU     $000000FF
YELLOW          EQU     $0000FFFF
GREEN           EQU     $00FF00FF

*-----------------------------------------------------------
* Section       : Screen Size
* Description   : Screen Width and Height
*-----------------------------------------------------------
SCREEN_W        DS.W    01  ; Reserve Space for Screen Width
SCREEN_H        DS.W    01  ; Reserve Space for Screen Height

*-----------------------------------------------------------
* Section       : Keyboard Input
* Description   : Used for storing Keypresses
*-----------------------------------------------------------
CURRENT_KEY     DS.L    01  ; Reserve Space for Current Key Pressed

*-----------------------------------------------------------
* Section       : Character Positions
* Description   : Player and Enemy Position Memory Locations
*-----------------------------------------------------------
PLAYER_X        DS.L    01  ; Reserve Space for Player X Position
PLAYER_Y        DS.L    01  ; Reserve Space for Player Y Position
PLAYER_SCORE    DS.L    01  ; Reserve Space for Player Score

ENEMY_X         DS.L    01
ENEMY_Y         DS.L    01
ENEMY_VELOCITY  DS.L    01

COIN_ARRAY_X    DC.L   01,01,01,01,01 ;Reserve space for 5 coins xPos
COIN_ARRAY_Y    DC.L   01,01,01,01,01  ;Reserve space for 5 coins yPos
COIN_VELOCITY   DS.L    01

BULLET_ARRAY_X     DC.L   01,01,01,01,01,01,01,01,01,01 ;Reserve space for 10 bullets xPos
BULLET_ARRAY_Y     DC.L   01,01,01,01,01,01,01,01,01,01  ;Reserve space for 10 bullets yPos
BULLET_ARRAY_FIRED DC.L   01,01,01,01,01,01,01,01,01,01  ;Reserve space for 10 bullets yPos
BULLET_VELOCITY    DS.L    01

PLATFORM_ARRAY_X    DC.L   01,01,01 ;Reserve space for 3 platforms xPos
PLATFORM_ARRAY_Y    DC.L   01,01,01  ;Reserve space for 3 platforms yPos
PLATFORM_VELOCITY   DS.L   01
PLATFORM_Y_POS_1      DS.L   01
PLATFORM_Y_POS_2      DS.L   01
PLATFORM_Y_POS_3      DS.L   01

PLYR_VELOCITY   DS.L    01  ; Reserve Space for Player Velocity
PLYR_GRAVITY    DS.L    01  ; Reserve Space for Player Gravity
PLYR_ON_GND     DS.L    01  ; Reserve Space for Player on Ground

GAME_IS_OVER    DS.L    01  ;Reserve space for game over bool


DELTA_TIME      DS.L    01  ; Reserve Space for Delta Time

*-----------------------------------------------------------
* Section       : Sounds
* Description   : Sound files, which are then loaded and given
* an address in memory, they take a longtime to process and play
* so keep the files small. Used https://voicemaker.in/ to 
* generate and Audacity to convert MP3 to WAV
*-----------------------------------------------------------
JUMP_WAV        DC.B    'jump.wav',0        ; Jump Sound
RUN_WAV         DC.B    'run.wav',0         ; Run Sound
COIN_WAV        DC.B    'coin.wav',0        ; Collision Opps

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
