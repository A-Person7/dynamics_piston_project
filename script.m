% Notes:
%   Vectors of the form r_AB refer to the position vector of A with respect to the position of B
%   All vectors are defined in terms of the given Cartesian basis vectors, with an additional 
%       elementary vector k defined such that i cross j = k to span three-space and describe 
%       rotation.
%   All positions and velocities without a subscript to indicate where they're defined with 
%       respect to are defined with respect to point O 
%       - e.g. v_A is the vector of the velocity of point A with respect to O 
%       - O is fixed, and therefore it has no velocity or acceleration 
%   MATLAB is very weird, and amongst its oddities, it's not strongly typed. 
%       Furthermore, since symbolic variables act like their corresponding Greek letters and 
%       add subscrips based on the literal name of the variable when outputting display text, 
%       it may be hard to differentiate what's a vector and what's a scalar. I have come to the 
%       executive decision that it's better to keep track in my head and in my code, then to 
%       Hungarian-type every variable name, which would likely decrease legibility even more.


%% Parameter initialization 
% t is time, theta_0 is the angle theta when t = 0 seconds, g is gravity,
%   other parameters are given in problem description
% aside from t, all of these parameters are constant with respect to the system's time evolution
syms R H L m_c m_p omega t theta_0 g

%% Kinetics
% define theta with respect to time (in radians)
theta = omega * t + theta_0;

% position of A with respect to O
%   define r in R^3 so we can take the cross product without adding on extra dimensions later
r_A = R*[cos(theta), sin(theta), 0];

% use the Pythagorean theorem to determine the vertical component of r_PA
r_PA = [H-R*cos(theta), sqrt(L^2 - (H-R*cos(theta))^2),0];
r_AP = -r_PA;

r_GA = 0.5 * r_PA;

r_P = r_A + r_PA;

r_G = r_A + r_GA;

% rearrange r_G = r_P + r_GP
r_GP = r_G - r_P;

v_A = diff(r_A, t);

% sanity check
assert(deep_equality(v_A, cross(omega*[0,0,1],r_A)), "Velocity of point A is not what's expected.");

% linear algebra solves every problem if you know what you're doing 

% this expression is dealing with a lot of MATLAB's poor design choices
%   for example, use planar_truncate to reduce R^3 vectors into the plane (just keeps the first two
%       elements),
%   .' is actually the transpose operator in MATLAB, ' is NOT and picks up a conjugate term 
% use \ instead of ^(-1) to allow MATLAB to optimize this and produce warnings for non-unique 
%   equations
temp = [planar_truncate(cross([0,0,1],r_PA)).',[0;-1]] \ (planar_truncate(-cross(omega*[0,0,1],r_A)).');
% temp = [planar_truncate(cross([0,0,1],r_PA)).',[0;-1]]^(-1)* (planar_truncate(-cross(omega*[0,0,1],r_A)).');
% MATLAB isn't clever enough to let you immediately assign these values
omega_AP = temp(1);
v_P = temp(2);
clear temp;


assert(deep_equality(v_P*[0,1,0], diff(r_P, t)), "Velocity of point P is not what's expected.");
assert(deep_equality(v_A + omega_AP*cross([0,0,1],r_GA), diff(r_G, t)), "Velocity of point G is not what's expected.");

a_A = -omega^2*r_A;

assert(deep_equality(diff(v_A,t), a_A), "Acceleration of point A is not what's expected.");


% temp = [planar_truncate(cross([0,0,1],r_PA)).',[0;-1]]^(-1)*(planar_truncate(omega_AP^2*r_PA - a_A).');
temp = [planar_truncate(cross([0,0,1],r_PA)).',[0;-1]] \ (planar_truncate(omega_AP^2*r_PA - a_A).');
alpha_AP = temp(1);
a_P = temp(2);
clear temp;


func_random_params = @() random_params();
func_check_equality_brute_force = @(expr1, expr2, num, tolerance) check_equality_brute_force(expr1, expr2, num, tolerance);
func_load_params = @(expr, params) load_params(expr, params);

assert(deep_equality(a_P, diff(v_P, t)), "Acceleration of point P is not what's expected.");


a_G = a_A + alpha_AP*cross([0,0,1], r_GA) - omega_AP^2 * r_GA;

assert(deep_equality(a_G, diff(r_G, t, 2)), "Acceleration of point G is not what's expected.");


%% Kinetics
I_G = 1/12 * m_c*L^2;
I_A = I_G + (L/2)^2*m_c;

% this is probably in a simpler form than a_G is right now, use this to get 
%   nicer expressions, probably
% also can't just directly type out diff every time because MATLAB doesn't like you indexing 
%   expressions, just variables for some reason
temp_a_G = diff(r_G, t, 2);
%temp_a_G = a_G;

% get P_y from FBD about the piston
%   NOTE -- P_y points in the -i direction on this FBD, despite pointing in the +i dir on 
%       the FBD of the rod
P_y = -m_p*(a_P + g);
% get A_y from FBD of the rod
A_y = m_c * temp_a_G(2) - P_y;

% from sum of moments on the crank in the k dir about point A 
P_x = (-I_A * alpha_AP - m_c * g * (r_PA(1))/2 + P_y * r_PA(1))/(r_PA(2));
% from sum of forces of the crank
A_x = m_c * temp_a_G(1) - P_x;

clear temp_a_G;

% save a handle to the function load_params to keep it accessible after running the script
loadParams = @load_params;

%% Define cases

% TODO -- seperate case parameters from angular velocities, have a case-template with constants,
%   make a function that combines a case with an angular velocity to yield a full parameter 
%   (auto-generate t values for an appropriate range)
% Also want a function that writes to data files in a pgfplots readable format for display 
%   purposes

case1.R = 0.075;
case1.m_c = 0.3;
case1.m_p = 0.4;
case1.theta_0 = 0;
case1.g = 9.81;
case1.L = 3/2*case1.R;
case1.H = 0*case1.R;
case1.t = 0:0.001:0.25;
case1.omega = 1000;

case2.R = 0.075;
case2.m_c = 0.3;
case2.m_p = 0.4;
case2.theta_0 = 0;
case2.g = 9.81;
case2.L = 8/3*case1.R;
% This used to be 5/3, which resulted in some *interesting* graphs, as well as some divide
%   by zero errors when the offset ere too small for some reason
% Change it back if you want to see some steep force jumps and piecewise-esque behavior
case2.H = 1/3*case1.R;
case2.t = 0:0.0001:0.05;
case2.omega = 5000 * 2 * pi / 60;

% plot(case1.t, loadParams(A_x, case1))

% TODO -- sanity check even more


% utility function to convert a vector in R^3 to one in R^2. MATLAB is stupid and doesn't allow 
%   something of the form (expression that results in a vector) to be indexed directly
% MATLAB is an interpreted language, it should have all the weird, fun stuff other interpreted 
%   languages have. At least have swizzles...
% This function is stupid, and will literally just cut off every element after the first and second
% If you give it a vector that doesn't have two or more elements, that's UB 
%       (it'll probably throw an error but I'm not going to guarantee that)
function vec2 = planar_truncate(vec3) 
    vec2 = vec3(1:2);
end

% Checks if two symbolic functions are equivalent 
%   (well, really, it checks if they're functionally equivalent, or, if that fails to work, checks 
%       if they're significantly close).
function equal = deep_equality(expr1, expr2) 
    equal = true;
    if (length(expr1) ~= length(expr2)) 
        equal = false;
        return;
    end
    for i = 1:length(expr1) 
        s_expr1 = simplify(expr1(i));
        s_expr2 = simplify(expr2(i));


        % do a heuristical check to see if the expressions simplify into the same form
        if (isequal(s_expr1, s_expr2))
            break;
        end

        s_expr1 = simplify(combine(simplifyFraction(expr1(i))), 'Steps',50);
        s_expr2 = simplify(combine(simplifyFraction(expr2(i))), 'Steps',50);

        try 
            % make isAlways throw an error when it can neither prove nor disprove equality
            if (~isAlways(s_expr1 == s_expr2, Unknown="error"))
                equal = false;
                return;
            end
        catch ME 
            % if analytic methods fail, simply brute force check 50 points for approximate equality
            % TODO -- add justification for tolerance and discuss acceptable failure probabilities
            % What are the odds this *and* our calculationrs are wrong?
            equal = check_equality_brute_force(expr1(i), expr2(i), 50, 0.1); 
            if (~equal) 
                return;
            end
        end
    end
end

function equal = check_equality_brute_force(expr1, expr2, num, tolerance)
    equal = true;
    for i = 1:num 
        p = random_params();
        value1 = load_params(expr1, p);
        value2 = load_params(expr1, p);

        % complex values are only a problem if they're not equal, luckily
        % assert(isreal(value1) && isreal(value2), "Expression evaluation yields complex outputs.");

        % floating point numbers can't be compared against each other accurately, need a tolerance 
        %   value
        if (abs(value1 - value2) > tolerance) 
            equal = false;

            if (abs(value1) + abs(value2) <= tolerance) 
                fprintf("Passed expressions are (almost) exactly opposite. Did you make a sign error?\n");
            end

            return;
        end
    end
end

% generates a random, valid parameter list for the sake of testing equality
function params = random_params() 
    params.R = rand() * 10 + 0.1;
    params.H = rand() * 10 + params.R + 0.01;

    params.g = 9.81;

    params.m_c = rand() * 10 + 0.1;
    params.m_p = rand() * 10 + 0.1;

    params.theta_0 = 0;
    params.omega = rand() * 1000 + 100;
    params.t = rand()*10;
    params.L = rand() * 10 + (params.H - params.R) + 0.01;
end

% loads a struct called param defining every variable to get a numerical value out 
%   all (useful) fields of param must be initialized to an object that can be 
%       cast to a double
%   t is allowed to be a vector (array), everything else must be a scalar
%   g is allowed to be left uninitialized if you want it to default to 9.81 m/s^2
function out = load_params(expr, params) 
    syms R H L m_c m_p omega t theta_0 g
    % TODO -- conver top terms to ratios
    assert(isfield(params, 'H'), "Parameter field property 'H' is not defined.");
    assert(isfield(params, 'R'), "Parameter field property 'R' is not defined.");
    assert(isfield(params, 'L'), "Parameter field property 'L' is not defined.");

    assert(isfield(params, 'm_c'), "Parameter field property 'm_c' is not defined.");
    assert(isfield(params, 'm_p'), "Parameter field property 'm_p' is not defined.");
    assert(isfield(params, 'omega'), "Parameter field property 'omega' is not defined.");

    if(~isfield(params, 'theta_0'))
        fprintf("Defaulting to an initial angle of 0 radians for t = 0 seconds.\n");
        params.theta_0 = 0;
    end

    assert(isfield(params, 't'), "Parameter field property 't' is not defined.");

    if (~isfield(params, 'g'))
        fprintf("Defaulting gravity to 9.81 m/s^2. If you are not using SI base units, " ...
            + "please define this properly for your coherent unit system.\n");
        params.g = 9.81;
    end

    expr = subs(expr, "H", params.H);
    expr = subs(expr, "R", params.R);
    expr = subs(expr, "L", params.L);
    expr = subs(expr, "m_c", params.m_c);
    expr = subs(expr, "m_p", params.m_p);
    expr = subs(expr, "omega", params.omega);
    expr = subs(expr, "theta_0", params.theta_0);
    expr = subs(expr, "t", params.t);
    expr = subs(expr, "g", params.g);

    % cast result from symbolic expression to double
    % at this point, every variable in expr ought to have been substituded out with a numeric form 
    out = double(expr);
end
