


function flappybird
    



% 0.1 = fast; 1 = normal;  10 = slow;
RUN.playSpeed = 1;         
RUN.fis = 'FuzzyControl108';






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONTROL EXTENSION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





% Command keys.
FuzzyFly_Key = {'uparrow'};
Restart_Key = {'r'};
GameSpeedUp_Key = {'add'};
GameSpeedDown_Key = {'subtract'};
PlotData_Key = {'p'};


% Setup
SET.colision = 0;       % enable colision
SET.scanVisu = 4;       % Visualize the scanned values of CMDENV - 0, 1, 2
SET.YTubeOffsetRange = 105;     % max     = 105
SET.XTubeOffsetRange = 0;      % default = 0
SET.XTubeOffsetMin = 90;        % default = 90 

% Visu
DOT.CData = [];                 % rgb
DOT.Alpha = [];                 % filled circle mask
DOT.R = 2;                      % original radius, with scale = 1
DOT.Count = 30;                 % n of initialized elements
RECT.CData = [];                % rgb
RECT.Alpha = [];                % filled rectangle mask
RECT.Alpha2 = [];               % hollow rectangle mask
RECT.Count = 30;                % n of initialized elements line + rects
RECT.RectIdx = RECT.Count - 5;  % index from which rects start
RECT.W = 0.3;                   % width of the line

% Initalize the circles, rectangles and lines.
function IMG_initShape()
    size = 77;       
    DOT.CData = uint8(zeros(size,size,3));
    DOT.CData(:,:,1) = uint8(DOT.CData(:,:,1)+255);
    DOT.Alpha = logical(ones(size));
    for x=1:size
        for y=1:size
            c=ceil(size/2);
            d = sqrt((c-x)^2 + (c-y)^2);
            DOT.Alpha(x,y) = d < c;           
        end
    end  
    RECT.CData = uint8(zeros(size,size,3));
    RECT.CData(:,:,1) = uint8(DOT.CData(:,:,1)+150);
    RECT.CData(:,:,3) = uint8(DOT.CData(:,:,3)+150);
    RECT.Alpha = logical(ones(size));
    RECT.Alpha2 = logical(ones(size));
    w = 5;
    RECT.Alpha2(w:size-w+1, w:size-w+1) = 0;
end

% Initilaize visu element n many times. (Without shape info.)
function IMG_initVisu()
    if SET.scanVisu > 0
        DotsHdl = zeros(1,DOT.Count);
        for i = 1:DOT.Count
            DotsHdl(i) = image([0 DOT.R], [0 DOT.R], [],...
            'Parent', MainAxesHdl,...
            'Visible', 'on');        
        end
        LinesHdl = zeros(1,RECT.Count);
        for i = 1:RECT.Count
            LinesHdl(i) = image([0 RECT.W], [3 3+RECT.W], [],...
            'Parent', MainAxesHdl,...
            'Visible', 'on');
        end  
    end
end

% Set the shape infos off all of the initialized elements.
function IMG_initVisuElements()  
    if SET.scanVisu > 0
        for i = 1:DOT.Count
            set(DotsHdl(i),'CData',DOT.CData, 'AlphaData',DOT.Alpha);
        end
        for i = 1:RECT.Count
            if i < RECT.RectIdx 
                set(LinesHdl(i),'CData',RECT.CData, 'AlphaData',RECT.Alpha);
            else
                set(LinesHdl(i),'CData',RECT.CData, 'AlphaData',RECT.Alpha2);
            end
        end
    end
end

% Place a dot on canvas. (i is the instanciation index)
function [i] = IMG_dot(i, x, y, scale)
    set(DotsHdl(i), 'XData', [x-DOT.R*scale x+DOT.R*scale], 'YData', [y-DOT.R*scale y+DOT.R*scale]);    
    i = i + 1;
end

% Place a line or rect on canvas.
function [i] = IMG_line(i, x, y, s, len, direction)
    d.all = 0;
    d.(direction) = len;
    d.U = d.all;
    d.D = d.all;
    d.R = d.all;
    d.L = d.all;
    d.(direction) = len;
    set(LinesHdl(i), 'XData', [x-RECT.W*s-d.L x+RECT.W*s+d.R], 'YData', [y-RECT.W*s-d.U y+RECT.W*s+d.D]);    
    i = i + 1;    
end

% Gui texts.
TEXT.th1 = [];
TEXT.th2 = [];
TEXT.counts = [5, 20];

% Initalize texts.
function PRINT_print_init()
    x = 5;
    y = 0;
    dy = 9;
    for ii=1:TEXT.counts(1)
        y = y + dy;
        TEXT.th1 = [TEXT.th1, text(x, y, '', 'Visible', 'off')];        
    end    
    y = y + dy/2;
    for jj=1:TEXT.counts(2)
        
        y = y + dy;
        TEXT.th2 = [TEXT.th2, text(x, y, '', 'Visible', 'off')];
    end
end

% Print list of variables on gui.
function PRINT_print(vars, th)
    for i_var =1:length(vars)
        if i_var<=length(th)          
            set(th(i_var), 'String', sprintf('%s = %.2f', vars{i_var}, eval(vars{i_var})));            
        end
    end
end

% Change gui text visibility.
function PRINT_show(onOff)
    for i=1:length(TEXT.th1)
        set( TEXT.th1(i) , 'Visible', onOff)
    end         
    for i=1:length(TEXT.th2)
        set( TEXT.th2(i) , 'Visible', onOff)
    end
end


% Command info.
CMD.Fuzzy = 0;
CMD.jumpCount = 0;
CMD.timeToJump = 0;
CMD.currTime = 0;
CMD.jumpWait = 0;
CMD.speedUpdating = 0;
CMD.relativeSpeed = 1;  


% Game diagnostics. 
DIAG.Game = 0;
DIAG.CurrentTime = 0;
DIAG.FRAME_DURATION = 0;
DIAG.timeToProcess = 0;
DIAG.deltaToProcess = 0;
DIAG.StageStartTime = 0;
DIAG.CurrentFrameNo = 0;
DIAG.speedUpdating = 0;


% Scanned environment info.
CMDENV.birdX = 0;
CMDENV.birdY = 0;
CMDENV.gapFront = ones(1,2)*1000;
CMDENV.gapBack = ones(1,2)*1000;
CMDENV.gapTop = ones(1,2)*1000;
CMDENV.gapCenter = ones(1,2)*1000;
CMDENV.gapBottom = ones(1,2)*1000;
CMDENV.toGround = 0;
CMDENV.colisions = 0;
CMDENV.jumps = 0;
CMDENV.score = 0;
CMDENV.overTube = false;
CMDENV.coliding = false;
CMDENV.gameover = false;

% Reset scanned environment info.
function CMD_reset()
    CMD.Fuzzy = 0;
    CMD.jumpCount = 0;
    CMD.timeToJump = 0;
    CMD.currTime = 0;
    CMD.jumpWait = 37;
    CMDENV.birdX = 0;
    CMDENV.birdY = 0;
    CMDENV.gapFront = ones(1,2)*1000;
    CMDENV.gapBack = ones(1,2)*1000;
    CMDENV.gapTop = ones(1,2)*1000;
    CMDENV.gapCenter = ones(1,2)*1000;
    CMDENV.gapBottom = ones(1,2)*1000;
    CMDENV.toGround = 0;
    CMDENV.colisions = 0;
    CMDENV.jumps = 0;
    CMDENV.score = 0;
    CMDENV.overTube = false;
    CMDENV.coliding = false;
    CMDENV.gameover = false;
end


% Scan environment.
function CMDENV_scan()    
    if ~CMDENV.gameover
        screenHeight = 195;
        CMDENV.jumps = CMD.jumpCount;
        CMDENV.birdX = Bird.ScreenPos(1);
        CMDENV.birdY = screenHeight - Bird.ScreenPos(2);    
        towersDistX = Tubes.ScreenX - CMDENV.birdX + TUBE.WIDTH;    
        CMDENV.gapBack(1) = min(towersDistX(towersDistX>0)); 
        index = find(towersDistX==CMDENV.gapBack(1));
        nextIndex = mod(index,3)+1;
        CMDENV.gapBack(2) = towersDistX(nextIndex);
        CMDENV.gapFront(1) = CMDENV.gapBack(1) - TUBE.WIDTH;
        CMDENV.gapFront(2) = CMDENV.gapBack(2) - TUBE.WIDTH;
        CMDENV.overTube = CMDENV.gapFront(1) < 10;    
        towerGap = GAME.FLOOR_TOP_Y - GAME.FLOOR_HEIGHT  - Tubes.VOffset(index);
        towerGapNext = GAME.FLOOR_TOP_Y - GAME.FLOOR_HEIGHT  - Tubes.VOffset(nextIndex);
        
        centerOffset = 10
        CMDENV.gapTop(1) = towerGap - 18;
        CMDENV.gapBottom(1) = towerGap + 32 ;
        CMDENV.gapCenter(1) = towerGap + centerOffset;    
        CMDENV.gapTop(2) = towerGapNext - 18;
        CMDENV.gapBottom(2) = towerGapNext + 32 ;
        CMDENV.gapCenter(2) = towerGapNext + centerOffset;

        dotIDX = 1;
        lineIDX = 1;
        rectIDX = RECT.RectIdx;

        if SET.scanVisu > 0
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(index), CMDENV.gapCenter(1), 1);
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(index), CMDENV.gapTop(1), 1);
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(index), CMDENV.gapBottom(1), 1);  
            if SET.scanVisu > 1
                dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(nextIndex), CMDENV.gapCenter(2), 0.7);
                dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(nextIndex), CMDENV.gapTop(2), 0.5);
                dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(nextIndex), CMDENV.gapBottom(2), 0.5);
            end
        end
        
    
        CMDENV.gapTop(1) = screenHeight - CMDENV.gapTop(1) - CMDENV.birdY;
        CMDENV.gapBottom(1) = screenHeight - CMDENV.gapBottom(1) - CMDENV.birdY;
        CMDENV.gapCenter(1) = screenHeight - CMDENV.gapCenter(1) - CMDENV.birdY;
        CMDENV.gapTop(2) = screenHeight - CMDENV.gapTop(2) - CMDENV.birdY;
        CMDENV.gapBottom(2) = screenHeight - CMDENV.gapBottom(2) - CMDENV.birdY;
        CMDENV.gapCenter(2) = screenHeight - CMDENV.gapCenter(2) - CMDENV.birdY;
        CMDENV.toGround =  CMDENV.birdY;

        if CMDENV.overTube    
            CMDENV.toGround = -CMDENV.gapBottom(1);
        end

        if SET.scanVisu > 0
            x = Bird.ScreenPos(1);
            y = Bird.ScreenPos(2);
            lineIDX = IMG_line(lineIDX, x, y+0, 1, CMDENV.gapFront(1), 'R');
            lineIDX = IMG_line(lineIDX, x, y+2, 1, CMDENV.gapBack(1), 'R');   

            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(1), y, 1, CMDENV.gapTop(1), 'U');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(1)-2, y, 1, CMDENV.gapBottom(1), 'U');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(1)-4, y, 1, CMDENV.gapCenter(1), 'U');

            lineIDX = IMG_line(lineIDX, x, y, 1, CMDENV.birdY, 'D');
            lineIDX = IMG_line(lineIDX, x+2, y, 1, CMDENV.toGround, 'D');

            if SET.scanVisu > 1
                lineIDX = IMG_line(lineIDX, x, 193, 1, CMDENV.gapFront(2), 'R');
                lineIDX = IMG_line(lineIDX, x, 195, 1, CMDENV.gapBack(2), 'R');
                lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(2), y, 1, CMDENV.gapTop(2), 'U');
                lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(2)-2, y, 1, CMDENV.gapBottom(2), 'U');
                lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(2)-4, y, 1, CMDENV.gapCenter(2), 'U');
            end
            
            if CMDENV.coliding
                rectIDX = IMG_line(rectIDX, x, y, 1, 10, 'all');
            else
                rectIDX = IMG_line(rectIDX, x, y, 1, 0, 'all');
            end
        
            if CMDENV.overTube
%                 dotIDX = IMG_dot(dotIDX, x, y, 4);
            else
                dotIDX = IMG_dot(dotIDX, x, y, 0.1);
            end
        end
   
    end
end

% Display variable values on GUI.
function CMDENV_report()

    PRINT_print({ 'CMD.Fuzzy', 'CMDENV.colisions', 'CMDENV.jumps', 'CMDENV.score' }, TEXT.th1);

%     PRINT_print({ 'INPUT.xGapFront', 'INPUT.yGapCenter','INPUT.yGapCenterDelta', 'CMD.jumpWait', 'CMD.currTime', 'CMD.timeToJump','INPUT.yAltitude', 'INPUT.yAdjGapCenter', 'HANDICAP.it'}, TEXT.th2);

end

% Count passed tubes. 
% TODO: remove game logic
function CMD_addScore()
    if Tubes.ScreenX(Tubes.FrontP) < 40 && Flags.NextTubeReady
        Flags.NextTubeReady = false;
        CMDENV.score = CMDENV.score + 1;
    end
end

% Collision scanner.
function CMD_colide()
    if ~CMDENV.gameover
        CMDENV.colisions = CMDENV.colisions + 1;
    end
    CMDENV.coliding = 1;
end

% Gameover scanner. 
function CMD_gameover()
    CMDENV.coliding = 1;
    CMDENV.gameover = 1;
    if ~CMDENV.gameover
        CMDENV.colisions = CMDENV.colisions + 1;
    end
end

% Flying scanner. 
function CMD_fly()
    CMDENV.coliding = 0;
    CMDENV.gameover = 0;
end
    

% Restarts game in 3s. Skips pregame.
function CMD_restart() 
    function press()
        FlyKeyStatus = 1;
        FlyKeyValid = 0;
        CMD.Fuzzy = 1;
    end    
    if ~Flags.PreGame
        gameover = true;
   
        T1 = timer('StartDelay',1.5,'TimerFcn',@(src,evt)press());
        T2 = timer('StartDelay',3,'TimerFcn',@(src,evt)press());

        start(T1);
        start(T2);
    end
end

% Scan and check if jump automatic jump should happen or not. 
function [okJump] = CMD_Jump(currTime)
    okJump = 0;
    CMD.currTime = currTime;
    if(CMD.timeToJump < CMD.currTime)
        CMD.jumpCount = CMD.jumpCount + 1;
        CMD.timeToJump = currTime + CMD.jumpWait;
        okJump = 1;
    end
end

% Add or subtract from game speed. (only in pregame)
function CMD_setSpeedX(sign)
    CMD.jumpWait = CMD.jumpWait + sign*2;
%     if ~CMD.speedUpdating && Flags.PreGame
%         step = 0.2;
%         speed = min(max(CMD.relativeSpeed + step*sign,step),30*step);
%         CMD.relativeSpeed = speed;    
%         GAME.N_UPDATE_PERSEC = 60*CMD.relativeSpeed;
%         GAME.FRAME_DURATION = 1/GAME.N_UPDATE_PERSEC;
%         GAME.CurrentFrameNo = GAME.CurrentFrameNo + sign*100;
%         CMD.speedUpdating = 1;
%         CMDENV_report();
%     end
end


PROCESSING.yNormRef = 190;
PROCESSING.xNormRef = 80;
INPUT.yGapCenter = 0;   % [-150 150]
INPUT.yAltitude = 0;    % [0    200]
INPUT.xGapFront = 0;
INPUT.yGapCenterNext = 0;
INPUT.yGapCenterDelta = 0;
INPUTHELP.yGapCenterPrev = 0;


function CMD_PreProcesing()
    INPUTHELP.yGapCenterDelta = 0;

%     INPUT.yGapCenterDelta = 
    INPUT.yGapCenter = CMDENV.gapCenter(1);
    INPUT.yGapCenterNext = CMDENV.gapCenter(2);

    INPUT.yAltitude = CMDENV.birdY;
    INPUT.xGapFront = CMDENV.gapFront(1);
    PLOT.data = [PLOT.data INPUT.yAltitude];
    
%     INPUT
%     INPUT.yGapCenter = CMDENV.gapCenter(1)/PROCESSING.yNormRef;
%     INPUT.yAltitude = CMDENV.toGround/PROCESSING.yNormRef;
%     INPUT.xGapFront = CMDENV.gapFront(1)/PROCESSING.xNormRef;
%     INPUT
%     CMDENV
    
end



PLOT.name = 'NA';
PLOT.data = [];
PLOT.fig = 0;
function PLOT_data()
%     if PLOT.fig ~=0
%         close(PLOT.fig)
%     end
    PLOT.fig = figure
    y = PLOT.data;
    x = 1:length(y);


    plot(x, y)


end

INPUT.sinceLastShift = 100;
TEMP.xGapFront = 0;
INPUT.xPrevGapFront = -1;
INPUT.yAdjGapCenterPos = 50;
INPUT.yAdjGapCenter = 50;
HANDICAP.i = -1;
HANDICAP.it= 0;
HANDICAP.cummulator= 0;
function CMD_Fuzzy()
    HANDICAP.i = HANDICAP.i + 1;
    if TEMP.xGapFront < 0 && 0 < INPUT.xGapFront
        INPUT.xPrevGapFront = -1;
    end
    if INPUT.xPrevGapFront == 5 
        INPUT.yAdjGapCenterPos = CMDENV.birdY + CMDENV.gapCenter(1);
    end
    
    INPUT.yAdjGapCenter = INPUT.yAdjGapCenterPos - CMDENV.birdY;
    
    INPUT.xPrevGapFront = INPUT.xPrevGapFront+1;   
    TEMP.xGapFront = INPUT.xGapFront;
    
    INPUT.yGapCenterDelta = -(INPUT.yGapCenter - INPUTHELP.yGapCenterPrev);
%     input = [INPUT.yGapCenter, INPUT.yAltitude, INPUT.xGapFront, INPUT.yGapCenterNext, INPUT.yGapCenterDelta];
    input = [INPUT.yAdjGapCenter,  INPUT.yGapCenterDelta, INPUT.yAltitude];

    
    
    delay = 20
    
    fis = readfis(RUN.fis);
    output = evalfis(input, fis);
    CMD.HOP = output;
%     CMD.jumpWait = output;
    CMD.jumpWait= -1
    CMD.jumpWait = delay;
    
%     if CMD.Fuzzy
%         IMG_dot(20, Bird.ScreenPos(1), Bird.ScreenPos(2), 1);
% 
%             
%         
%         
% %         HANDICAP.cummulator = 
%         if mod(HANDICAP.i, 20)==0
%             HANDICAP.it = HANDICAP.it + 1;
%             if CMD.jumpWait>0 
%                 IMG_dot(20, Bird.ScreenPos(1), Bird.ScreenPos(2), 4);
%             else
%                 IMG_dot(20, Bird.ScreenPos(1), Bird.ScreenPos(2), 6);
%             end
%             CMD.timeToJump = CMD.currTime + CMD.jumpWait;
%         end
%     end
    INPUTHELP.yGapCenterPrev = INPUT.yGapCenter;
end


function CMD_PipeLine()    
    CMDENV_scan()
    CMD_PreProcesing()    
    CMD_Fuzzy()
end


function CMD_keyManager(key)
    switch true
        case strcmp(key, FuzzyFly_Key) 
            CMD.Fuzzy = ~CMD.Fuzzy; 
        case strcmp(key, Restart_Key) 
            CMD_restart();
        case strcmp(key, GameSpeedUp_Key) 
            CMD_setSpeedX(1);
        case strcmp(key, GameSpeedDown_Key) 
            CMD_setSpeedX(-1); 
        case strcmp(key, PlotData_Key) 
            PLOT_data();            
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%









%% System Variables:
GameVer = '2.0';          
% 2.0 - Controllable game
% 1.0 - The first full playable game




%% Constant Definitions:
GAME.MAX_FRAME_SKIP = [];

GAME.RESOLUTION = [];       % Game Resolution, default at [256 144]
GAME.WINDOW_SCALE = 2;     % The actual size of the window divided by resolution
GAME.FLOOR_TOP_Y = [];      % The y position of upper crust of the floor.
GAME.N_UPDATES_PER_SEC = [];
GAME.FRAME_DURATION = [];
GAME.GRAVITY = 0.1356; %0.15; %0.2; %1356;  % empirical gravity constant
GAME.CurrentFrameNo = 0;      
GAME.CurrentTime = 0;
GAME.StageStartTime = 0;


TUBE.MIN_HEIGHT = [];       % The minimum height of a tube
TUBE.RANGE_HEIGHT = [];     % The range of the height of a tube
TUBE.SUM_HEIGHT = [];       % The summed height of the upper and low tube
TUBE.H_SPACE = [];           % Horizontal spacing between two tubs
TUBE.V_SPACE = [];           % Vertical spacing between two tubs
TUBE.WIDTH   = [];            % The 'actual' width of the detection box

GAMEPLAY.RIGHT_X_FIRST_TUBE = [];  % Xcoord of the right edge of the 1st tube


%% Handles
MainFigureHdl = [];
MainAxesHdl = [];
MainCanvasHdl = [];
BirdSpriteHdl = [];
TubeSpriteHdl = [];
FloorSpriteHdl = [];
FloorAxesHdl = [];
DotsHdl = [];
LinesHdl = [];

%% Game Parameters
MainFigureInitPos = [];
MainFigureSize = [];
MainAxesInitPos = []; % The initial position of the axes IN the figure
MainAxesSize = [];

InGameParams.CurrentBkg = 1;
InGameParams.CurrentBird = 1;

Flags.IsGameStarted = true;     %
Flags.IsFirstTubeAdded = false; % Has the first tube been added to TubeLayer
Flags.ResetFloorTexture = true; % Result the pointer for the floor texture
Flags.PreGame = true;
Flags.NextTubeReady = true;
CloseReq = false;

FlyKeyNames = {'space'};
FlyKeyStatus = false; %(size(FlyKeyNames));
FlyKeyValid = true(size(FlyKeyNames));     








%% Canvases:
MainCanvas = [];

% The scroll layer for the tubes
TubeLayer.Alpha = [];
TubeLayer.CData = [];


%% RESOURCES:
Sprites = [];

%% Positions:
Bird.COLLIDE_MASK = [];
Bird.INIT_SCREEN_POS = [45 100];                    % In [x y] order;
Bird.WorldX = [];
Bird.ScreenPos = [45 100]; %[45 100];   % Center = The 9th element horizontally (1based)
                                     % And the 6th element vertically 
Bird.SpeedXY = [ 0];
Bird.Angle = 0;
Bird.XGRID = [];
Bird.YGRID = [];
Bird.CurFrame = 1;
Bird.SpeedY = 0;
Bird.LastHeight = 0;

SinYRange = 44;
SinYPos = [];
SinY = [];


Tubes.FrontP = 1;              % 1-3
Tubes.ScreenX = [300 380 460]-2; % The middle of each tube
Tubes.VOffset = ceil(rand(1,3)*105); 





%% -- Game Logic --
initVariables();
initWindow();

% Initilize text elements for displaying variables on the GUI


PRINT_print_init();




% Main Game


CMD.HOP = 2.5

function hop(gameover)
    if ~gameover
        if CMD.HOP > 0
            Bird.SpeedY = -CMD.HOP;
        end
        FlyKeyStatus = false;
        Bird.LastHeight = Bird.ScreenPos(2);
        if Flags.PreGame
            Flags.PreGame = false;                    
            Bird.ScrollX = 0;
        end                
    else
        if Bird.SpeedY < 0
            Bird.SpeedY = 0;
        end
    end
end


while 1
DIAG.Game = DIAG.Game + 1;
initGame();
GAME.CurrentFrameNo = double(0);
collide = false;
fall_to_bottom = false;
gameover = false;
GAME.StageStartTime = tic;
IMG_initShape();
CMD_reset();
while 1
    loops = 0;
    GAME.CurrentTime = toc(GAME.StageStartTime);


    
    DIAG.CurrentTime = GAME.CurrentTime;
    DIAG.CurrentFrameNo = GAME.CurrentFrameNo;
    DIAG.FRAME_DURATION = GAME.FRAME_DURATION;
    DIAG.timeToProcess = GAME.CurrentFrameNo * GAME.FRAME_DURATION;
    DIAG.deltaToProcess = DIAG.CurrentTime - DIAG.timeToProcess ;
    DIAG.StageStartTime = GAME.StageStartTime;
    while (GAME.CurrentTime >= ((GAME.CurrentFrameNo) * GAME.FRAME_DURATION) && loops < GAME.MAX_FRAME_SKIP)
        
        CMD_PipeLine()

        if FlyKeyStatus  % If left key is pressed    
            hop(gameover);
        end
        if Flags.PreGame
            processCPUBird;
        else
            processBird;
            Bird.ScrollX = Bird.ScrollX + 1;
            if ~gameover
                scrollTubes(1);
            end
        end
        if CMD.Fuzzy
            okJump = CMD_Jump(GAME.CurrentFrameNo);
            if okJump
                hop(gameover);
            end
        end
        
        
        Bird.CurFrame = 3 - floor(double(mod(GAME.CurrentFrameNo, 9))/3);

      %% Cycling the Palette
        % Update the cycle variables
       collide = isCollide();
       if collide           
           gameover = true;
           CMD_reset();
       end
       GAME.CurrentFrameNo = GAME.CurrentFrameNo + 1;
       loops = loops + 1;
       frame_updated = true;
       
       % If the bird has fallen to the ground
       if Bird.ScreenPos(2) >= 200-5;
            Bird.ScreenPos(2) = 200-5;
            gameover = true;
            CMD_reset();
            CMD_gameover();

            if abs(Bird.Angle - pi/2) < 1e-3
                fall_to_bottom = true;
                FlyKeyStatus = false;
             
            end
       end
       CMD_addScore()
       

    end
    


    %% Redraw the frame if the world has been processed
    if frame_updated
        CMD.speedUpdating = 0;
        set(MainCanvasHdl, 'CData', MainCanvas(1:200,:,:));
        if fall_to_bottom
            Bird.CurFrame = 2;
        end
        refreshBird();
        refreshTubes();
        if (~gameover)
            refreshFloor(GAME.CurrentFrameNo);
        end

        drawnow;
         frame_updated = false;
        
        CMDENV_report();
    end
    if fall_to_bottom
        if FlyKeyStatus
            FlyKeyStatus = false;
            break;
        end
    end
       
    if CloseReq    
        delete(MainFigureHdl);
        clear all;
        return;
    end

    DIAG.speedUpdating = CMD.speedUpdating;

%     DIAG
end

end

    function initVariables()
        Sprites = load('sprites2.mat');
        GAME.MAX_FRAME_SKIP = 5;
        GAME.RESOLUTION = [256 144];
        GAME.WINDOW_RES = [256 144];
        GAME.FLOOR_HEIGHT = 56;
        GAME.FLOOR_TOP_Y = GAME.RESOLUTION(1) - GAME.FLOOR_HEIGHT + 1;
        GAME.N_UPDATE_PERSEC = 60*CMD.relativeSpeed;
        GAME.FRAME_DURATION = (1/GAME.N_UPDATE_PERSEC)*RUN.playSpeed;
        
        TUBE.H_SPACE = 80;           % Horizontal spacing between two tubs
        TUBE.V_SPACE = 48;           % Vertical spacing between two tubs
        TUBE.WIDTH   = 24;            % The 'actual' width of the detection box
        TUBE.MIN_HEIGHT = 36;
        
        TUBE.SUM_HEIGHT = GAME.RESOLUTION(1)-TUBE.V_SPACE-...
            GAME.FLOOR_HEIGHT;
        TUBE.RANGE_HEIGHT = TUBE.SUM_HEIGHT -TUBE.MIN_HEIGHT*2;
        
        TUBE.PASS_POINT = [1 44];
        
        %TUBE.RANGE_HEIGHT_DOWN;      % Sorry you just don't have a choice
        GAMEPLAY.RIGHT_X_FIRST_TUBE = 300;  % Xcoord of the right edge of the 1st tube
        
        %% Handles
        MainFigureHdl = [];
        MainAxesHdl = [];
        
        %% Game Parameters
        MainFigureInitPos = [500 100];
        MainFigureSize = GAME.WINDOW_RES([2 1]).*2;
        MainAxesInitPos = [0 0]; %[0.1 0.1]; % The initial position of the axes IN the figure
        MainAxesSize = [144 200]; % GAME.WINDOW_RES([2 1]);
        FloorAxesSize = [144 56];
        
        
        %% Canvases:
        MainCanvas = uint8(zeros([GAME.RESOLUTION 3]));
                
        bird_size = Sprites.Bird.Size;
        [Bird.XGRID, Bird.YGRID] = meshgrid([-ceil(bird_size(2)/2):floor(bird_size(2)/2)], ...
            [ceil(bird_size(1)/2):-1:-floor(bird_size(1)/2)]);
        Bird.COLLIDE_MASK = false(12,12);
        [tempx tempy] = meshgrid(linspace(-1,1,12));
        Bird.COLLIDE_MASK = (tempx.^2 + tempy.^2) <= 1;
        
        
        Bird.OSCIL_RANGE = [128 4]; % [YPos, Amplitude]
        
        SinY = Bird.OSCIL_RANGE(1) + sin(linspace(0, 2*pi, SinYRange))* Bird.OSCIL_RANGE(2);
        SinYPos = 1;
    end

%% --- Graphics Section ---
    function initWindow()
        IMG_initShape();
        % initWindow - initialize the main window, axes and image objects
        MainFigureHdl = figure('Name', ['Flappy Bird ' GameVer], ...
            'NumberTitle' ,'off', ...
            'Units', 'pixels', ...
            'Position', [MainFigureInitPos, MainFigureSize], ...
            'MenuBar', 'figure', ...
            'Renderer', 'OpenGL',...
            'Color',[0 0 0], ...
            'KeyPressFcn', @stl_KeyPressFcn, ...
            'WindowKeyPressFcn', @stl_KeyDown,...
            'WindowKeyReleaseFcn', @stl_KeyUp,...
            'CloseRequestFcn', @stl_CloseReqFcn);
        FloorAxesHdl = axes('Parent', MainFigureHdl, ...
            'Units', 'normalized',...
            'Position', [MainAxesInitPos, (1-MainAxesInitPos.*2) .* [1 56/256]], ...
            'color', [1 1 1], ...
            'XLim', [0 MainAxesSize(1)]-0.5, ...
            'YLim', [0 56]-0.5, ...
            'YDir', 'reverse', ...
            'NextPlot', 'add', ...
            'Visible', 'on',...
            'XTick',[], 'YTick', []);
        MainAxesHdl = axes('Parent', MainFigureHdl, ...
            'Units', 'normalized',...
            'Position', [MainAxesInitPos + [0 (1-MainAxesInitPos(2).*2)*56/256], (1-MainAxesInitPos.*2).*[1 200/256]], ...
            'color', [1 1 1], ...
            'XLim', [0 MainAxesSize(1)]-0.5, ...
            'YLim', [0 MainAxesSize(2)]-0.5, ...
            'YDir', 'reverse', ...
            'NextPlot', 'add', ...
            'Visible', 'on', ...
            'XTick',[], ...
            'YTick',[]);
        
        
        MainCanvasHdl = image([0 MainAxesSize(1)-1], [0 MainAxesSize(2)-1], [],...
            'Parent', MainAxesHdl,...
            'Visible', 'on');
        TubeSpriteHdl = zeros(1,3);
        for i = 1:3
            TubeSpriteHdl(i) = image([0 26-1], [0 304-1], [],...
            'Parent', MainAxesHdl,...
            'Visible', 'on');
        end
        
        IMG_initVisu()
        
        BirdSpriteHdl = surface(Bird.XGRID-100,Bird.YGRID-100, ...
            zeros(size(Bird.XGRID)), Sprites.Bird.CDataNan(:,:,:,1), ...
            'CDataMapping', 'direct',...
            'EdgeColor','none', ...
            'Visible','on', ...
            'Parent', MainAxesHdl);
        FloorSpriteHdl = image([0], [0],[],'Parent', FloorAxesHdl,'Visible', 'on ');
       
        
        
        
        end
    function initGame()
        % The scroll layer for the tubes
        TubeLayer.Alpha = false([GAME.RESOLUTION.*[1 2] 3]);
        TubeLayer.CData = uint8(zeros([GAME.RESOLUTION.*[1 2] 3]));

        Bird.Angle = 0;
        Flags.ResetFloorTexture = true;
        SinYPos = 1;
        Flags.PreGame = true;

        drawToMainCanvas();
        set(MainCanvasHdl, 'CData', MainCanvas);
        set(FloorSpriteHdl, 'CData',Sprites.Floor.CData);
        Tubes.FrontP = 1;              % 1-3
        Tubes.ScreenX = [300 380 460]-2; % The middle of each tube
        Tubes.VOffset = ceil(rand(1,3)*SET.YTubeOffsetRange);
        refreshTubes;
        for i = 1:3
            set(TubeSpriteHdl(i),'CData',Sprites.TubGap.CData,...
                'AlphaData',Sprites.TubGap.Alpha);
            redrawTube(i);
        end
        
        IMG_initVisuElements();
        
        PRINT_show('on')
    end
%% Game Logic
    function processBird()
        Bird.ScreenPos(2) = Bird.ScreenPos(2) + Bird.SpeedY;
        Bird.SpeedY = Bird.SpeedY + GAME.GRAVITY;
        if Bird.SpeedY < 0
            Bird.Angle = max(Bird.Angle - pi/10, -pi/10);
        else
            if Bird.ScreenPos(2) < Bird.LastHeight
                Bird.Angle = -pi/10; %min(Bird.Angle + pi/100, pi/2);
            else
                Bird.Angle = min(Bird.Angle + pi/30, pi/2);
            end
        end
    end
    function processCPUBird() % Process the bird when the game is not started
        Bird.ScreenPos(2) = SinY(SinYPos);
        SinYPos = mod(SinYPos, SinYRange)+1;
    end
    function drawToMainCanvas()
        % Draw the scrolls and sprites to the main canvas
        
        % Redraw the background
        MainCanvas = Sprites.Bkg.CData(:,:,:,InGameParams.CurrentBkg);
        
        TubeFirstCData = TubeLayer.CData(:, 1:GAME.RESOLUTION(2), :);
        TubeFirstAlpha = TubeLayer.Alpha(:, 1:GAME.RESOLUTION(2), :);
        % Plot the first half of TubeLayer
        MainCanvas(TubeFirstAlpha) = ...
            TubeFirstCData (TubeFirstAlpha);
    end
    function scrollTubes(offset)
        Tubes.ScreenX = Tubes.ScreenX - offset;
        if Tubes.ScreenX(Tubes.FrontP) <=-26
            off.FrontP = Tubes.FrontP;
            off.BackP = mod(Tubes.FrontP + 1,3)+1;
            off.minX = SET.XTubeOffsetMin;
            off.randomX = ceil(rand*SET.XTubeOffsetRange) ;
            off.randomY = ceil(rand*SET.YTubeOffsetRange) ;

            Tubes.ScreenX(Tubes.FrontP) = Tubes.ScreenX(off.BackP) + off.minX + off.randomX;
            Tubes.VOffset(Tubes.FrontP) = off.randomY;
            redrawTube(Tubes.FrontP);
            Tubes.FrontP = mod((Tubes.FrontP),3)+1;
            Flags.NextTubeReady = true;
        end
    end

    function refreshTubes()
        % Refreshing Scheme 1: draw the entire tubes but only shows a part
        % of each
        for i = 1:3
            set(TubeSpriteHdl(i), 'XData', Tubes.ScreenX(i) + [0 26-1]);
        end
    end
    
    function refreshFloor(frameNo)
        offset = mod(frameNo, 24);
        set(FloorSpriteHdl, 'XData', -offset);
    end

    function redrawTube(i)
        set(TubeSpriteHdl(i), 'YData', -(Tubes.VOffset(i)-1));
    end

%% --- Math Functions for handling Collision / Rotation etc. ---
    function collide_flag = isCollide()
        collide_flag = 0;
        if Bird.ScreenPos(1) >= Tubes.ScreenX(Tubes.FrontP)-5 && ...
                Bird.ScreenPos(1) <= Tubes.ScreenX(Tubes.FrontP)+6+25            
        else
            CMD_fly()
            return;
        end
        
        GapY = [128 177] - (Tubes.VOffset(Tubes.FrontP)-1);    % The upper and lower bound of the GAP, 0-based
        
        if Bird.ScreenPos(2) < GapY(1)+4 || Bird.ScreenPos(2) > GapY(2)-4
            collide_flag = SET.colision;
            CMD_colide()
        else
            CMD_fly()
        end
        
        return;
    end


    function refreshBird()
        % move bird to pos [X Y],
        % and rotate the bird surface by X degrees, anticlockwise = +
        cosa = cos(Bird.Angle);
        sina = sin(Bird.Angle);
        xrotgrid = cosa .* Bird.XGRID + sina .* Bird.YGRID;
        yrotgrid = sina .* Bird.XGRID - cosa .* Bird.YGRID;
        xtransgrid = xrotgrid + Bird.ScreenPos(1)-0.5;
        ytransgrid = yrotgrid + Bird.ScreenPos(2)-0.5;
        set(BirdSpriteHdl, 'XData', xtransgrid, ...
            'YData', ytransgrid, ...
            'CData', Sprites.Bird.CDataNan(:,:,:, Bird.CurFrame));
    end
    
        
%% -- Callbacks --
    function stl_KeyUp(hObject, eventdata, handles)
        keyU = get(hObject,'CurrentKey');
        % Remark the released keys as valid
        FlyKeyValid = FlyKeyValid | strcmp(keyU, FlyKeyNames);        
    end
    function stl_KeyDown(hObject, eventdata, handles)
        keyD = get(hObject,'CurrentKey');        
        % Has to be both 'pressed' and 'valid';
        % Two key presses at the same time will be counted as 1 key press
        down_keys = strcmp(keyD, FlyKeyNames);
        FlyKeyStatus = any(FlyKeyValid & down_keys);
        FlyKeyValid = FlyKeyValid & (~down_keys);        
    end
    function stl_KeyPressFcn(hObject, eventdata, handles)
        curKey = get(hObject, 'CurrentKey');
        switch true
            case strcmp(curKey, 'escape') 
                CloseReq = true; 
        end
        CMD_keyManager(curKey);
    end
    function stl_CloseReqFcn(hObject, eventdata, handles)
        CloseReq = true;
    end
end