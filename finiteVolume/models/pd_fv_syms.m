function [model] = pd_fv_syms( )
% finite volume implementation 

model.param = 'log';
model.forward = true;
model.adjoint = false;

%% PDE discretization
n_grid = 300;
grid = linspace(0,1,n_grid);

h2inv = (1/(grid(2)-grid(1)))^2;

grid_x = linspace(grid(1)+(grid(2)-grid(1))/2,grid(end-1)+(grid(end)-grid(end-1))/2,n_grid-1); 
%% STATES
% create state syms: vector for x at each grid point
x = sym('x',[n_grid-1,1]);

%% PARAMETERS ( for these sensitivities will be computed )

% create parameter syms
syms D1 D2 D3 D4 D5 D6 D7 D8 D9 v1 v2 v3 v4 v5 v6 v7 v8 v9 a1 a2 a3 a4 a5 a6 a7 a8 a9

p = [D1,D2,D3,D4,D5,D6,D7,D8,D9,v1,v2,v3,v4,v5,v6,v7,v8,v9,a1,a2,a3,a4,a5,a6,a7,a8,a9];
[Db1,~] = simpleSplineSym((0:0.125:1)',log([D1;D2;D3;D4;D5;D6;D7;D8;D9]),grid(2:end-1));
Db1 = exp(Db1);

[vb1,dvb1dgrid] = simpleSplineSym((0:0.125:1)',log([v1;v2;v3;v4;v5;v6;v7;v8;v9]),grid(2:end-1));
vb1 = exp(vb1);
dvb1dgrid = vb1.*dvb1dgrid;

grid0 = 29;
[v_end_b1,~] = cspline_00(vb1(end-grid0),dvb1dgrid(end-grid0),grid(end-grid0),grid(end-1),grid(end-grid0:end-1));
vb1(end-grid0:end) = [v_end_b1,zeros(1,1)];

ab1 = simpleSplineSym((0:0.125:1)',log([a1;a2;a3;a4;a5;a6;a7;a8;a9]),grid_x);

%% CONSTANTS ( for these no sensitivities will be computed )
% this part is optional and can be ommited

% create parameter syms
k = sym('k',[n_grid-1,1]);

%% SYSTEM EQUATIONS

% create symbolic variable for time
syms t

xdot = sym(zeros(size(x)));
% xdot is finite volume approximation to PDE on grid
% Robin boundary on the left hand side and Dirichlet on the right hand side

% dynamic branch 1
xdot(1) = h2inv*(-Db1(1)*(x(1)-x(2))) - vb1(1)*1/2*(x(1)+x(2))*sqrt(h2inv) + ab1(1)*x(1);

xdot(n_grid-1) = h2inv*(Db1(end)*(x(n_grid-2)-x(n_grid-1)))+vb1(end)*1/2*(x(n_grid-2)+x(n_grid-1))*sqrt(h2inv) + ab1(n_grid-1)*x(n_grid-1);% 

for i = 2:n_grid-2
 xdot(i) = h2inv*(Db1(i-1)*(x(i-1)-x(i))-Db1(i)*(x(i)-x(i+1))) + sqrt(h2inv)*1/2*(vb1(i-1)*(x(i-1)+x(i))-vb1(i)*(x(i)+x(i+1))) + ab1(i)*x(i);
end
%% INITIAL CONDITIONS

x0 = sym(zeros(size(x)));

for i = 1:n_grid-1
    x0(i) = k(i);
end

%% OBSERVALES
N = sum(x/sqrt(h2inv));
y = [x;N];


%% SYSTEM STRUCT

model.sym.x = x;
model.sym.k = k;
model.sym.xdot = xdot;
model.sym.p = p;
model.sym.x0 = x0;
model.sym.y = y;
end

