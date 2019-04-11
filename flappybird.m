


function flappybird

%% System Variables:
GameVer = '1.0';          % The first full playable game

%% Constant Definitions:
GAME.MAX_FRAME_SKIP = [];

GAME.RESOLUTION = [];       % Game Resolution, default at [256 144]
GAME.WINDOW_SCALE = 2;     % The actual size of the window divided by resolution
GAME.FLOOR_TOP_Y = [];      % The y position of upper crust of the floor.
GAME.N_UPDATES_PER_SEC = [];
GAME.FRAME_DURATION = [];
GAME.GRAVITY = 0.1356; %0.15; %0.2; %1356;  % empirical gravity constant
      
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

FuzzyFlyKeyNames = {'uparrow'};







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




% Command
SET.colision = 0;
SET.frameDelay = 0; % ms
SET.scanVisu = 1; % Visualize the scanned values of CMDENV

DOT.CData = [];
DOT.Alpha = [];
DOT.R = 2;
DOT.Count = 30;

RECT.CData = [];
RECT.Alpha = [];
RECT.Alpha2 = [];
RECT.Count = 30;
RECT.RectIdx = RECT.Count - 5;
RECT.W = 0.3;




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


     
function IMG_initVisuElements()   
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


function IMG_initVisu()            
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

function [i] = IMG_dot(i, x, y, s)
    set(DotsHdl(i), 'XData', [x-DOT.R*s x+DOT.R*s], 'YData', [y-DOT.R*s y+DOT.R*s]);    
    i = i + 1;
end

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

CMD.Fuzzy = 0;
CMD.jumpCount = 0;
CMD.timeToJump = 0;
CMD.currTime = 0;
CMD.jumpWait = 0;

function CMD_reset()
    CMD.Fuzzy = 0;
    CMD.jumpCount = 0;
    CMD.timeToJump = 0;
    CMD.currTime = 0;
    CMD.jumpWait = 38;
end

CMDENV.birdX = 0;
CMDENV.birdY = 0;
CMDENV.gapFront = ones(1,2)*1000;
CMDENV.gapBack = ones(1,2)*1000;
CMDENV.gapTop = ones(1,2)*1000;
CMDENV.gapCenter = ones(1,2)*1000;
CMDENV.gapBottom = ones(1,2)*1000;
CMDENV.toGround = 0;
CMDENV.colisions = 0;
CMDENV.score = 0;
CMDENV.overTube = false;
CMDENV.coliding = false;
CMDENV.gameover = false;

function CMDENV_scan()
    if ~CMDENV.gameover
        screenHeight = 195;
        CMDENV.birdX = Bird.ScreenPos(1);
        CMDENV.birdY = screenHeight - Bird.ScreenPos(2);    
        towersDistX = Tubes.ScreenX - CMDENV.birdX + TUBE.WIDTH;    
        CMDENV.gapBack(1) = min(towersDistX(towersDistX>0)); 
        index = find(towersDistX==CMDENV.gapBack(1));
        nextIndex = mod(index,3)+1;
        CMDENV.gapBack(2) = towersDistX(nextIndex);
        CMDENV.gapFront(1) = CMDENV.gapBack(1) - TUBE.WIDTH;
        CMDENV.gapFront(2) = CMDENV.gapBack(2) - TUBE.WIDTH;
        CMDENV.overTube = index == Tubes.FrontP && CMDENV.score > 0 ;    
        towerGap = GAME.FLOOR_TOP_Y - GAME.FLOOR_HEIGHT  - Tubes.VOffset(index);
        towerGapNext = GAME.FLOOR_TOP_Y - GAME.FLOOR_HEIGHT  - Tubes.VOffset(nextIndex);
        CMDENV.gapTop(1) = towerGap - 18;
        CMDENV.gapBottom(1) = towerGap + 32 ;
        CMDENV.gapCenter(1) = towerGap + 7;    
        CMDENV.gapTop(2) = towerGapNext - 18;
        CMDENV.gapBottom(2) = towerGapNext + 32 ;
        CMDENV.gapCenter(2) = towerGapNext + 7;

        dotIDX = 1;
        lineIDX = 1;
        rectIDX = RECT.RectIdx;

        if SET.scanVisu
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(index), CMDENV.gapCenter(1), 1);
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(index), CMDENV.gapTop(1), 1);
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(index), CMDENV.gapBottom(1), 1);        
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(nextIndex), CMDENV.gapCenter(2), 0.7);
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(nextIndex), CMDENV.gapTop(2), 0.5);
            dotIDX = IMG_dot(dotIDX, Tubes.ScreenX(nextIndex), CMDENV.gapBottom(2), 0.5);
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

        if SET.scanVisu 
            x = Bird.ScreenPos(1);
            y = Bird.ScreenPos(2);
            lineIDX = IMG_line(lineIDX, x, y+0, 1, CMDENV.gapFront(1), 'R');
            lineIDX = IMG_line(lineIDX, x, y+2, 1, CMDENV.gapBack(1), 'R');     
            lineIDX = IMG_line(lineIDX, x, 193, 1, CMDENV.gapFront(2), 'R');
            lineIDX = IMG_line(lineIDX, x, 195, 1, CMDENV.gapBack(2), 'R');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(1), y, 1, CMDENV.gapTop(1), 'U');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(1)-2, y, 1, CMDENV.gapBottom(1), 'U');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(1)-4, y, 1, CMDENV.gapCenter(1), 'U');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(2), y, 1, CMDENV.gapTop(2), 'U');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(2)-2, y, 1, CMDENV.gapBottom(2), 'U');
            lineIDX = IMG_line(lineIDX, x+CMDENV.gapFront(2)-4, y, 1, CMDENV.gapCenter(2), 'U');
            lineIDX = IMG_line(lineIDX, x, y, 1, CMDENV.birdY, 'D');
            lineIDX = IMG_line(lineIDX, x+2, y, 1, CMDENV.toGround, 'D');

            if CMDENV.coliding
                rectIDX = IMG_line(rectIDX, x, y, 1, 10, 'all');
            else
                rectIDX = IMG_line(rectIDX, x, y, 1, 0, 'all');
            end
        
            if CMDENV.overTube
                dotIDX = IMG_dot(dotIDX, x, y, 4);
            else
                dotIDX = IMG_dot(dotIDX, x, y, 0.1);
            end
        end
    end

%     Bird
%     Tubes
    CMDENV
%     TUBE
end

function CMDENV_report()
    print({'Bird.LastHeight', 'Bird.SpeedY'}, TEXT.th1);
end

function CMD_addScore()
    if Tubes.ScreenX(Tubes.FrontP) < 40 && Flags.NextTubeReady
        Flags.NextTubeReady = false;
        CMDENV.score = CMDENV.score + 1;
    end
end

function CMD_colide()
    if ~CMDENV.gameover
        CMDENV.colisions = CMDENV.colisions + 1;
    end
    CMDENV.coliding = 1;
end

function CMD_gameover()
    CMDENV.coliding = 1;
    CMDENV.gameover = 1;
    if ~CMDENV.gameover
        CMDENV.colisions = CMDENV.colisions + 1;
    end
end


function CMD_fly()
    CMDENV.coliding = 0;
    CMDENV.gameover = 0;

end

function [okJump] = CMD_Jump(currTime)
    okJump = 0;
    CMD.currTime = currTime;
    if(CMD.timeToJump < CMD.currTime)
        CMD.jumpCount = CMD.jumpCount + 1;
        CMD.timeToJump = CMD.timeToJump + CMD.jumpWait;
        okJump = 1;
    end
end




%% -- Game Logic --
initVariables();
initWindow();

% Initilize text elements for displaying variables on the GUI

TEXT.th1 = [];
TEXT.th2 = [];

function initPrint(i, j)
    x = 5;
    y = 0;
    dy = 9;
    for ii=1:i
        y = y + dy;
        TEXT.th1 = [TEXT.th1, text(x, y, '', 'Visible', 'off')];        
    end    
    y = y + dy/2;
    for jj=1:j
        y = y + dy;
        TEXT.th2 = [TEXT.th2, text(x, y, '', 'Visible', 'off')];
    end
end
function print(vars, th)
    for i_var =1:length(vars)
        if i_var<=length(th)          
            set(th(i_var), 'String', sprintf('%s = %.2f', vars{i_var}, eval(vars{i_var})));            
        end
    end
end
function showPrint(onOff)
    for i=1:length(TEXT.th1)
        set( TEXT.th1(i) , 'Visible', onOff)
    end         
    for i=1:length(TEXT.th2)
        set( TEXT.th2(i) , 'Visible', onOff)
    end
end

initPrint(2, 8);




% Main Game


function hop(gameover)
    if ~gameover
        Bird.SpeedY = -2.5;
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
initGame();
CurrentFrameNo = double(0);
collide = false;
fall_to_bottom = false;
gameover = false;
stageStartTime = tic;
IMG_initShape();
CMD_reset();
while 1
    loops = 0;
    
    curTime = toc(stageStartTime);
    while (curTime >= ((CurrentFrameNo) * GAME.FRAME_DURATION) && loops < GAME.MAX_FRAME_SKIP)
        
        CMDENV_scan()
        pause(SET.frameDelay/1000);
        
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
            okJump = CMD_Jump(CurrentFrameNo);
            if okJump
                hop(gameover);
            end
        end
        
        
        Bird.CurFrame = 3 - floor(double(mod(CurrentFrameNo, 9))/3);

      %% Cycling the Palette
        % Update the cycle variables
       collide = isCollide();
       if collide           
           gameover = true;
           CMD_reset();
       end
       CurrentFrameNo = CurrentFrameNo + 1;
       loops = loops + 1;
       frame_updated = true;
       
       % If the bird has fallen to the ground
       if Bird.ScreenPos(2) >= 200-5;
            Bird.ScreenPos(2) = 200-5;
            gameover = true;
            CMD_reset();
            CMD_gameover()

            if abs(Bird.Angle - pi/2) < 1e-3
                fall_to_bottom = true;
                FlyKeyStatus = false;
             
            end
       end
       CMD_addScore()
       

    end
    
    %% Redraw the frame if the world has been processed
    if frame_updated
        set(MainCanvasHdl, 'CData', MainCanvas(1:200,:,:));
        if fall_to_bottom
            Bird.CurFrame = 2;
        end
        refreshBird();
        refreshTubes();
        if (~gameover)
            refreshFloor(CurrentFrameNo);
        end

        drawnow;
        frame_updated = false;

        
        CMDENV_report()

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
end
end

    function initVariables()
        Sprites = load('sprites2.mat');
        GAME.MAX_FRAME_SKIP = 5;
        GAME.RESOLUTION = [256 144];
        GAME.WINDOW_RES = [256 144];
        GAME.FLOOR_HEIGHT = 56;
        GAME.FLOOR_TOP_Y = GAME.RESOLUTION(1) - GAME.FLOOR_HEIGHT + 1;
        GAME.N_UPDATE_PERSEC = 60;
        GAME.FRAME_DURATION = 1/GAME.N_UPDATE_PERSEC;
        
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
        Tubes.VOffset = ceil(rand(1,3)*105);
        refreshTubes;
        for i = 1:3
            set(TubeSpriteHdl(i),'CData',Sprites.TubGap.CData,...
                'AlphaData',Sprites.TubGap.Alpha);
            redrawTube(i);
        end
        
        IMG_initVisuElements();
        
        showPrint('on')
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
            Tubes.ScreenX(Tubes.FrontP) = Tubes.ScreenX(Tubes.FrontP) + 240;
            Tubes.VOffset(Tubes.FrontP) = ceil(rand*105);
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
%         % Remark the released keys as valid
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
            case strcmp(curKey, FuzzyFlyKeyNames) 
                CMD.Fuzzy = ~CMD.Fuzzy; 
        end
    end
    function stl_CloseReqFcn(hObject, eventdata, handles)
        CloseReq = true;
    end
end