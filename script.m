%% Global variables
% global variables are always great practice and a good idea
global MACRO_TARGET_FILE
MACRO_TARGET_FILE="macro_regex";


%% Parameter initialization 
syms R H L m_c m_p omega time

initial_angle = 0;

% define theta with respect to time (in radians)
theta = omega * time + initial_angle;

% position of P with respect to O
%   define r in R^3 so we can take the cross product without adding on extra dimensions later
r_PO = R*[cos(theta), sin(theta), 0];

expand_macro("UNIQUEID_ALPHA", r_PO);

latex(r_PO);


% Searches through the file MACRO_TARGET_FILE, and replaces instances of unique_identifier with 
%   the LaTeX formatting generated from the syms variable expression expr
% To disable this functionality, define MACRO_TARGET_FILE as something other than a string
function expand_macro(unique_identifier, expr) 
    global MACRO_TARGET_FILE
   
    if (class(MACRO_TARGET_FILE) ~= 'string') 
        disp("Macro expansion disabled.");
        return;
    end

    fid = fopen(MACRO_TARGET_FILE);
    
    if (fid == -1) 
        % assert("Failed to find " + MACRO_TARGET_FILE + " in your working directory. Perhaps you " ...
        %   + "meant to cd into a different one, or meant to disable macro expansion?");
        % create file
        fid = fopen(MACRO_TARGET_FILE,'w');
    end

    f = join(string(fread(fid, '*char')),"");
    fclose(fid);
    
    %f = replace(join(string(f),""), unique_identifier, string(latex(expr)));

    % the 'w' here means the file is writable. It also does some weird stuff and erases it, so only 
    %   open it after the file has been read and edited
    fid = fopen(MACRO_TARGET_FILE,'w');
    if (fid == -1) 
        % I have no idea why this might happen, unless perhaps you are *very* quick deleting 
        %   files during script execution, or you put a permission scheme on it so it can be 
        %   read but not written to
        assert("?");
    end


    fprintf(fid, "%s\n=%s=%s=g;", f, unique_identifier, string(latex(expr)));
    fclose(fid);
end
