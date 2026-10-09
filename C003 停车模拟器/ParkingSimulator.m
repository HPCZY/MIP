function ParkingSimulator()

screens = get(groot, 'ScreenSize');
width = 875;
height = 600;
pos = [(screens(3)-width)/2,(screens(4)-height)/2,width,height];

warning off

%%
fig = uifigure('Name','倒车模拟器','Position',pos,'WindowButtonMotionFcn',@WBMFcn,...
    'WindowKeyPressFcn',@WKPFcn,'WindowKeyReleaseFcn',@WKRFcn);
gl = uigridlayout(fig,'RowHeight',{'1x'},'ColumnWidth',{165,'1x'},'RowSpacing',0,'ColumnSpacing',0);

%%
gl1 = uigridlayout(gl,'RowHeight',{'1x',40,75,75,40,75},'ColumnWidth',{75,75}, ...
    'RowSpacing',5,'ColumnSpacing',5,'padding',5);
setLayout(gl1,1,1)

fs = 14;
ut = uitextarea(gl1,'Value',{'A - 左';'D - 右';'W - 油门';'S - 刹车';'空格 - 前进/倒挡';'R  -  重置'},'FontSize',18);
%lb1 = uilabel(gl1,'Text','wsad方向，空格油门','FontSize',fs,'HorizontalAlignment','center');
setLayout(ut,1,[1,2])
lb1 = uilabel(gl1,'Text','生成停车场','FontSize',fs,'HorizontalAlignment','center');
setLayout(lb1,2,[1,2])
bt1 = uibutton(gl1,'Text','','Icon','.\icon\park1.png','ButtonPushedFcn',@BTPark1,'BackgroundColor',[0.95,0.95,0.95]);
bt2 = uibutton(gl1,'Text','','Icon','.\icon\park2.png','ButtonPushedFcn',@BTPark2,'BackgroundColor',[1,1,1]);
bt3 = uibutton(gl1,'Text','','Icon','.\icon\park3.png','ButtonPushedFcn',@BTPark3);
bt4 = uibutton(gl1,'Text','','Icon','.\icon\park4.png','ButtonPushedFcn',@BTPark4);
setLayout(bt1,3,1);
setLayout(bt2,3,2);
setLayout(bt3,4,1);
setLayout(bt4,4,2);

lb1 = uilabel(gl1,'Text','生成车辆','FontSize',fs,'HorizontalAlignment','center');
setLayout(lb1,5,[1,2])
bt5 = uibutton(gl1,'Text','','Icon','.\icon\car1.png','ButtonPushedFcn',@BTCar1);
bt6 = uibutton(gl1,'Text','','Icon','.\icon\car2.png','ButtonPushedFcn',@BTCar2);
setLayout(bt5,6,1);
setLayout(bt6,6,2);

%%
groundcolor = [1,1,1]*0.2;
gl2 = uigridlayout(gl,'RowHeight',{'1x'},'ColumnWidth',{100,'1x'}, ...
    'RowSpacing',5,'ColumnSpacing',5,'padding',5,'BackgroundColor',groundcolor);
worldsize = 15;
ax = uiaxes(gl2,'XLim',[-1,1]*worldsize,'Ylim',[-1,1]*worldsize,'XTick',[],'YTick',[]);
setLayout(ax,1,2)
axis(ax,'off')

%% 
gl3 = uigridlayout(gl2,'RowHeight',{'1x',30,30,90,90,90},'ColumnWidth',{90},'RowSpacing',10,'ColumnSpacing',0);
setLayout(gl3,1,1)
speedLimit = 30;
curlimit = 15;
lb3 = uilabel(gl3,'Text','限速','HorizontalAlignment','center','FontSize',16);
setLayout(lb3,2,1)

spn = uispinner(gl3,'Value',curlimit,'Limits',[5,30],'FontSize',16,'ValueChangedFcn',@changelimit);
setLayout(spn,3,1)
gg1 = uigauge(gl3,'Limits',[0,speedLimit],'ScaleColors',{'yellow','red'},...
                 'ScaleColorLimits', [0.6 0.8; 0.8 1]*speedLimit);
setLayout(gg1,4,1)
ax2 = uiaxes(gl3,'XLim',[-1,1],'Ylim',[-1,1],'XTick',[],'YTick',[]);
axis(ax2,'off')
setLayout(ax2,5,1)
steeling = imread('.\icon\steel.png');
[imgx,imgy] = meshgrid(linspace(-0.95,0.95,128));
imgz = zeros(size(imgx));
hST = surf(ax2,imgx,imgy,imgz,'EdgeAlpha',0);
set(hST,'CData',steeling,'FaceColor','texturemap')
view(ax2,0,-90)
% gg2 = uigauge(gl3,'linear','Limits',[-1,1]);
sw = uiswitch(gl3,'Items',{'D','R'},'ItemsData',{1,2},'Orientation','vertical','FontSize',18);
setLayout(sw,6,1)

%% park
parkWidth = 2.5;
parkLength = 5.3;


Hparkline = [];
Hparkcar = [];

ParkType = 1;
[Hparkline,parkingLine] = GeneParkLine(ax,ParkType,parkWidth,parkLength);
[Hparkcar,carList] = GeneParkCar(ax,parkingLine,ParkType);


%% car

% axle
FrontAxleWidth = 1.2;
RearAxleWidth = 1.5;
WheelBase = 2.7;
StreeringArmLength = 0.1;

hFAW = FrontAxleWidth/2;
hRAW = RearAxleWidth/2;
hWB = WheelBase/2;

carframe = [-hFAW,hWB;hFAW,hWB;-hRAW,-hWB;hRAW,-hWB];

% size
carhead = 0.6;
cartail = 0.6;
carflank = 0.2;
carshell = [-hRAW-carflank,hWB+carhead;
    hRAW+carflank,hWB+carhead;
    -hRAW-carflank,-hWB-cartail;
    hRAW+carflank,-hWB-cartail];

%
maxTheta = pi/4;
theta = 0;
Larm = [];
Rarm = [];

% wheel
WheelSize = [0.2,0.4]/2;
sqr = [-1,1;1,1;1,-1;-1,-1].*WheelSize;
Lfw = [];
Rfw = [];
Lrw = [];
Rrw = [];

% auxiliary line
rotateCenter = [];

% line
cirLen = 5;
dCirLen = 0.5;
pn = 32;
% pt = pi/40;
LFline = [];
RFline = [];
LRline = [];
RRline = [];

% world
ad = 0;
ws = 0;
wlocBegin = [-12,0];
wloc = wlocBegin;
wangle = 0;

caltheta(0);
calarm();
calline(0,1);

% car body
wheelgap = [0.12,0.075];
tmp = [hRAW,hWB+carhead;
    hRAW+WheelSize(1),hWB+carhead*0.75;
    hRAW+WheelSize(1),hWB+WheelSize(2)+wheelgap(2);
    hRAW-WheelSize(1)-wheelgap(1),hWB+WheelSize(2)+wheelgap(2);
    hRAW-WheelSize(1)-wheelgap(1),hWB-WheelSize(2)-wheelgap(2);
    hRAW+WheelSize(1),hWB-cartail*0.75;
    hRAW,hWB-cartail];

tmp = [tmp;flipud(tmp).*[1,-1]];
carbody = [tmp;flipud(tmp).*[-1,1]];

caricon = im2double(imread('.\icon\car.png'));
caricon = caricon(2:end,2:end-1,:);
caricon(caricon<4/255) = 0.2;
[iconrow,iconcol,~] = size(caricon);
[iconx,icony,iconz] = meshgrid(linspace(carshell(1,1),carshell(2,1),iconcol),...
                linspace(carshell(1,2),carshell(4,2),iconrow),0);


% plot
hold(ax,'on')
f = ones(1,pn);
v = [0,0];

Hlfcl = patch('Faces',f,'Vertices',v,'FaceVertexCData',getcolor([1,0,0],pn,groundcolor),...
    'FaceColor','interp','EdgeColor','none','Parent',ax);
Hrfcl = patch('Faces',f,'Vertices',v,'FaceVertexCData',getcolor([0,0,1],pn,groundcolor), ...
    'FaceColor','interp','EdgeColor','none','Parent',ax);
Hlrcl = patch('Faces',f,'Vertices',v,'FaceVertexCData',getcolor([0,1,0],pn,groundcolor), ...
    'FaceColor','interp','EdgeColor','none','Parent',ax);
Hrrcl = patch('Faces',f,'Vertices',v,'FaceVertexCData',getcolor([0,1,0],pn,groundcolor), ...
    'FaceColor','interp','EdgeColor','none','Parent',ax);

Hbody = fill(carbody(:,1),carbody(:,2),[0.6,0.6,0.6],...
    'EdgeColor',[0.6,0.6,0.6],'FaceAlpha',0.3,'Parent',ax);


Hlfw = fill(Lfw(:,1),Lfw(:,2),[0.5,0.5,0.5],...
    'EdgeColor',[0.3,0.3,0.3],'FaceAlpha',0.5,'Parent',ax);
Hrfw = fill(Rfw(:,1),Rfw(:,2),[0.5,0.5,0.5],...
    'EdgeColor',[0.3,0.3,0.3],'FaceAlpha',0.5,'Parent',ax);

Hlrw = fill(Lrw(:,1),Lrw(:,2),[0.5,0.5,0.5],...
    'EdgeColor',[0.3,0.3,0.3],'FaceAlpha',0.5,'Parent',ax);
Hrrw = fill(Rrw(:,1),Rrw(:,2),[0.5,0.5,0.5],...
    'EdgeColor',[0.3,0.3,0.3],'FaceAlpha',0.5,'Parent',ax);

Hcar = surf(ax,iconx,icony,iconz,'EdgeAlpha',0);
set(Hcar,'CData',caricon,'FaceColor','texturemap')

Hcircenter = plot(0,0,'+','Color',[1,1,0.8],'MarkerSize',10,'Parent',ax);

hold(ax,'off')

caltheta(0);
calarm();
calline(0,1);
worldupdata(wloc,0);

flag_w = false;
flag_s = false;
flag_a = false;
flag_d = false;


Rbar = false;
speed = 0;
angle = 0;
while ishandle(fig)
    
    if flag_s
        speed = max(speed-0.2,0);        
    elseif flag_w 
        speed = min(speed+0.05,1);
    else
        speed = max(speed-0.05,0); 
    end

    if ~Rbar
        ws = speed;
    else
        ws = -speed;
    end

    if flag_a && ~flag_d
        angle = max(angle-0.05,-1);  
    elseif ~flag_a && flag_d
        angle = min(angle+0.05,1);
    end

    ad = angle;
    if ws==0 %%&& angle~=0
        if ~Rbar
            ws = 0.001;
        else
            ws = -0.001;
        end
    end
    
    calMotion();
    pause(0.025)

end


%% 回调
    function changelimit(src,~)
        curlimit = src.Value;
        dCirLen = curlimit/30;
    end


    function BTCar1(~,~)
        for i = 1:length(Hparkcar)
            delete(Hparkcar{i});
        end
        [Hparkcar,carList] = GeneParkCar(ax,parkingLine,ParkType);
        restart();
    end
    function BTCar2(~,~)
        restart();
    end

    function BTPark1(~,~)
        ParkType = 1;
        updatapark();
        restart();
    end
    function BTPark2(~,~)
        ParkType = 2;
        updatapark();
        restart();
    end
    function BTPark3(~,~)
        ParkType = 3;
        updatapark();
        restart();
    end
    function BTPark4(~,~)
        ParkType = 4;
        updatapark();
        restart();
    end

    function calMotion()
        caltheta(ad);
        calarm();
        ad = round(ad,3);
        ws = round(ws,3);

        calline(ad,ws);
        dt = abs(ws*dCirLen);
        if ws>0
            pa = getroute(rotateCenter,carframe(3,:),0,ws,ad,dt);
            pb = getroute(rotateCenter,carframe(4,:),0,ws,ad,dt);
            vab = pb-pa;
            nab = [-vab(2),vab(1)]/norm(vab);
            wloc = wloc+(nab*hWB+(pa+pb)/2)*[cos(wangle),sin(wangle);-sin(wangle),cos(wangle)];
            wangle = wangle+atan2(vab(2),vab(1));
        elseif ws<0
            pa = getroute(rotateCenter,carframe(3,:),0,ws,ad,dt);
            pb = getroute(rotateCenter,carframe(4,:),0,ws,ad,dt);
            vab = pb-pa;
            nab = [-vab(2),vab(1)]/norm(vab);
            wloc = wloc+(nab*hWB+(pa+pb)/2)*[cos(wangle),sin(wangle);-sin(wangle),cos(wangle)];
            wangle = wangle+atan2(vab(2),vab(1));
        end
        rotateCenter = wloc+rotateCenter*[cos(wangle),sin(wangle);-sin(wangle),cos(wangle)];

        if wloc(1)>worldsize
            wloc(1) = -worldsize;
        elseif wloc(1)<-worldsize
            wloc(1) = worldsize;
        end
        if wloc(2)>worldsize
            wloc(2) = -worldsize;
        elseif wloc(2)<-worldsize
            wloc(2) = worldsize;
        end


        updata();
        worldupdata(wloc,wangle);
    end

    function restart()
        flag_w = false;
        flag_s = false;
        flag_a = false;
        flag_d = false;
        ad = 0;
        ws = 0;
        wloc = wlocBegin;
        wangle = 0;
        calMotion();
    end

    function WKPFcn(~,event)
        switch event.Key
            case 'r'
                restart();
            case 'space'
                Rbar = ~Rbar;
                if Rbar
                    sw.Value = 2;
                else
                    sw.Value = 1;
                end
            case 'w'
                flag_w = true;
            case 's'
                flag_s = true;
            case 'a'
                flag_a = true;
            case 'd'
                flag_d = true;
        end

        calMotion();

    end


    function WKRFcn(~,event)
        switch event.Key
            case 'w'
                flag_w = false;
            case 's'
                flag_s = false;
            case 'a'
                flag_a = false;
            case 'd'
                flag_d = false;
        end
    end

    function WBMFcn(~,~)
        %         p = ax.CurrentPoint;
        %         tmp = block+p(1,1:2);
    end
%% 功能

    function newpos = getroute(C,P,alpha,fws,fad,L)

        R = norm(P-C);
        if fad>0
            pt = L/norm(C);
            if fws>=0
                t = pi+alpha-pt;
            else
                t = pi+alpha+pt;
            end
            newpos = R*[cos(t),sin(t)]+C;
        elseif fad<0
            pt = L/norm(C);
            if fws>=0
                t = alpha+pt;
            else
                t = alpha-pt;
            end
            newpos = R*[cos(t),sin(t)]+C;
        else
            if fws>=0
                newpos = P+[0,L];
            else
                newpos = P-[0,L];
            end
        end

    end

    function caltheta(w)
        if w>0
            tR = -w*maxTheta;
            tL = atan2(-WheelBase,-WheelBase/tan(tR)+FrontAxleWidth);
        elseif w<0
            tL = -w*maxTheta;
            tR = pi+atan2(-WheelBase,-WheelBase/tan(tL)-FrontAxleWidth);
        else
            tL = 0;
            tR = 0;
        end
        theta = [tL,tR];
    end


    function calarm()
        Larm = [cos(pi+theta(1)),sin(pi+theta(1));0,0]*StreeringArmLength+carframe(1,:);
        Rarm = [cos(theta(2)),sin(theta(2));0,0]*StreeringArmLength+carframe(2,:);
        Lfw = sqr*[cos(theta(1)),sin(theta(1));-sin(theta(1)),cos(theta(1))]+Larm(1,:);
        Rfw = sqr*[cos(theta(2)),sin(theta(2));-sin(theta(2)),cos(theta(2))]+Rarm(1,:);
        Lrw = sqr+carframe(3,:);
        Rrw = sqr+carframe(4,:);
    end

    function pos = calpos(hangle,pos,loc,angle)
        pos = pos*[cos(angle),sin(angle);-sin(angle),cos(angle)]+loc;
        hangle.XData = pos(:,1);
        hangle.YData = pos(:,2);
    end

    function worldupdata(loc,angle)

        gg1.Value = ws*curlimit;
        TT = deg2rad(ad*540);
        x = imgx*cos(TT)-imgy*sin(TT);
        y = imgx*sin(TT)+imgy*cos(TT);
        hST.XData = x;
        hST.YData = y;

        x = iconx*cos(angle)-icony*sin(angle)+loc(1);
        y = iconx*sin(angle)+icony*cos(angle)+loc(2);
        Hcar.XData = x;
        Hcar.YData = y;

        calpos(Hbody,carbody,loc,angle);
        calpos(Hlfw,Lfw,loc,angle);
        calpos(Hrfw,Rfw,loc,angle);
        calpos(Hlrw,Lrw,loc,angle);
        calpos(Hrrw,Rrw,loc,angle);

        LFline = calpos(Hlfcl,LFline,loc,angle);
        RFline = calpos(Hrfcl,RFline,loc,angle);
        LRline = calpos(Hlrcl,LRline,loc,angle);
        RRline = calpos(Hrrcl,RRline,loc,angle);

        

        nowshell = carshell*[cos(angle),sin(angle);-sin(angle),cos(angle)]+loc;
        for i = 1:length(carList)
            if checkCollision(nowshell, carList{i})
                uialert(fig,'Duang！！','','Icon','error');
                restart();
                break
            end
        end
    end

    function updata(~,~)

        Hlfw.XData = Lfw(:,1);
        Hlfw.YData = Lfw(:,2);
        Hrfw.XData = Rfw(:,1);
        Hrfw.YData = Rfw(:,2);

        Hcircenter.XData = rotateCenter(1);
        Hcircenter.YData = rotateCenter(2);

        Hlfcl.XData = LFline(:,1);
        Hlfcl.YData = LFline(:,2);
        Hrfcl.XData = RFline(:,1);
        Hrfcl.YData = RFline(:,2);
        Hlrcl.XData = LRline(:,1);
        Hlrcl.YData = LRline(:,2);
        Hrrcl.XData = RRline(:,1);
        Hrrcl.YData = RRline(:,2);

    end


    function calline(ad,ws)
        if ad>0
            rotateCenter = [Rarm(1,1)-(Rarm(1,2)+hWB)/tan(theta(2)),-hWB];
        elseif ad<0
            rotateCenter = [Larm(1,1)-(Larm(1,2)+hWB)/tan(theta(1)),-hWB];
        else
            rotateCenter = [inf,inf];
        end

        LFline = getarc(rotateCenter,Larm(1,:),theta(1),cirLen,ad,ws,pn);
        RFline = getarc(rotateCenter,Rarm(1,:),theta(2),cirLen,ad,ws,pn);
        LRline = getarc(rotateCenter,carframe(3,:),0,cirLen,ad,ws,pn);
        RRline = getarc(rotateCenter,carframe(4,:),0,cirLen,ad,ws,pn);

    end


    function updatapark()

        delete(Hparkline)
        for i = 1:length(Hparkcar)
            delete(Hparkcar{i});
        end
        [Hparkline,parkingLine] = GeneParkLine(ax,ParkType,parkWidth,parkLength);
        [Hparkcar,carList] = GeneParkCar(ax,parkingLine,ParkType);

    end

    function setLayout(h,x,y)
        h.Layout.Row = x;
        h.Layout.Column = y;
    end

end








%% 环境

function [Hparkline,parkingLine] = GeneParkLine(ax,ParkType,parkWidth,parkLength)

bias = 2;
switch ParkType
    case 1
        parkingLine.x = [-2,-2,-2,-2,-1,0,1,2,-2,-1,0,1,2;
            2,2,2,-2,-1,0,1,2,-2,-1,0,1,2]*parkWidth+bias;
        parkingLine.y = [0,1,-1,0,0,0,0,0,-1,-1,-1,-1,-1;
            0,1,-1,1,1,1,1,1,0,0,0,0,0]*parkLength;
    case 2
        parkingLine.x = [-2,-2,-2,-2,-1,0,1,2,-2,-1,0,1,2;
            2,2,2,-2,-1,0,1,2,-2,-1,0,1,2]*parkLength+bias;
        parkingLine.y = [0,1,-1,0,0,0,0,0,-1,-1,-1,-1,-1;
            0,1,-1,1,1,1,1,1,0,0,0,0,0]*parkWidth;
    case 3
        parkTheta = deg2rad(60);
        W = parkWidth/sin(parkTheta);
        L = parkWidth*cos(parkTheta)+parkLength*sin(parkTheta);
        G = L/tan(parkTheta);
        parkingLine.x = [-2,-1,-2,-2,-1,0,1,2,-2,-1,0,1,2;
            2,2,1,-2,-1,0,1,2,-2,-1,0,1,2]*W+bias+[0;G];
        parkingLine.y = [0,1,-1,0,0,0,0,0,-1,-1,-1,-1,-1;
            0,1,-1,1,1,1,1,1,0,0,0,0,0]*L;
    case 4
        parkTheta = deg2rad(45);
        W = parkWidth/sin(parkTheta);
        L = parkWidth*cos(parkTheta)+parkLength*sin(parkTheta);
        G = L/tan(parkTheta);
        parkingLine.x = [-2,-1,-2,-2,-1,0,1,2,-2,-1,0,1,2;
            2,2,1,-2,-1,0,1,2,-2,-1,0,1,2]*W+bias+[0;G];
        parkingLine.y = [0,1,-1,0,0,0,0,0,-1,-1,-1,-1,-1;
            0,1,-1,1,1,1,1,1,0,0,0,0,0]*L;
end

hold(ax,'on')
Hparkline = plot(ax,parkingLine.x,parkingLine.y,'-','color',[1,1,1],'LineWidth',2);
hold(ax,'off')

end

function [Hparkcar,carList] = GeneParkCar(ax,parkingLine,ParkType)
%
parkbody = [-1,-1;-1,1;1,1;1,-1]/2;
switch ParkType
    case 1
        parkbody = parkbody.*[1.7,4];
    case 2
        parkbody = parkbody.*[4,1.7];
    case 3
        pktt = deg2rad(60)-pi/2;
        parkbody = parkbody.*[1.7,4]*[cos(pktt),sin(pktt);-sin(pktt),cos(pktt)];
    case 4
        pktt = deg2rad(45)-pi/2;
        parkbody = parkbody.*[1.7,4]*[cos(pktt),sin(pktt);-sin(pktt),cos(pktt)];
end

%
num = randperm(8);
parkcar = num(1:randi(7));
i = parkcar>4;
parkcar(i) = parkcar(i)+1;

%
parkcarnum = length(parkcar);
carList = cell(parkcarnum,1);
for n = 1:parkcarnum
    dx = mean(parkingLine.x(:,3+parkcar(n):4+parkcar(n)),'all');
    dy = mean(parkingLine.y(:,3+parkcar(n):4+parkcar(n)),'all');
    carList{n} = parkbody+[dx,dy];
end

hold(ax,'on')
for n = 1:length(carList)
    Hparkcar{n} = fill(carList{n}(:,1),carList{n}(:,2),[1,0.6,0.6],...
        'EdgeColor',[1,0.6,0.6],'FaceAlpha',0.3,'Parent',ax);
end
hold(ax,'off')

end

%% 辅助导航线
function cpos = getarc(C,P,a,L,ad,ws,pn)
band = 0.08;
R = norm(P-C);
rad = L/R;
if ad>0
    a = pi+a;
    if ws>=0
        t = linspace(a,a-rad,pn)';
    else
        t = linspace(a,a+rad,pn)';
    end
    tmp = [cos(t),sin(t)];
    Lcpos = (R+band)*tmp+C;
    Rcpos = (R-band)*tmp+C;
elseif ad<0
    if ws>=0
        t = linspace(a,a+rad,pn)';
    else
        t = linspace(a,a-rad,pn)';
    end
    tmp = [cos(t),sin(t)];
    Lcpos = (R-band)*tmp+C;
    Rcpos = (R+band)*tmp+C;
else
    if ws>=0
        t = linspace(0,L,pn)';
    else
        t = linspace(0,-L,pn)';
    end
    Lcpos = [ones(pn,1)*P(1)-band,P(2)+t];
    Rcpos = [ones(pn,1)*P(1)+band,P(2)+t];
end
cpos = [Lcpos;flipud(Rcpos)];

end


function color = getcolor(pc,pn,groundcolor)

c = linspace(0,1,pn)';
color = [c;flipud(c)];
color = pc.*ones(pn*2,3)+color*(1-pc);

end

%% 碰撞检测

function isCollision = checkCollision(polygon1, polygon2)
edges1 = getEdges(polygon1);
edges2 = getEdges(polygon2);

for i = 1:length(edges1)
    for j = 1:length(edges2)
        if doSegmentsIntersect(edges1(i,:), edges2(j,:))
            isCollision = true;
            return;
        end
    end
end
isCollision = false;
end

function edges = getEdges(polygon)
% 计算多边形的边界线段

edges = [];
for i = 1:length(polygon)
    edge = [polygon(i,:), polygon(mod(i, length(polygon)) + 1,:)];
    edges = [edges; edge];
end

end

function intersects = doSegmentsIntersect(segment1, segment2)

x1 = segment1(1);
y1 = segment1(2);
x2 = segment1(3);
y2 = segment1(4);
x3 = segment2(1);
y3 = segment2(2);
x4 = segment2(3);
y4 = segment2(4);

intersects = ((x1 - x2) * (y3 - y1) - (y1 - y2) * (x3 - x1)) * ((x1 - x2) * (y4 - y1) - (y1 - y2) * (x4 - x1)) < 0 ...
    && ((x3 - x4) * (y1 - y3) - (y3 - y4) * (x1 - x3)) * ((x3 - x4) * (y2 - y3) - (y3 - y4) * (x2 - x3)) < 0;
end
