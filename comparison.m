%function nothing = comparison()
% -----------------------------------------------------------------------
% Zoltan Mark Pinter, 22.12.2022
% Ho-ho-hoooo, what has Santa brought for Christmas?
%   A code that does not crash (fingers crossed)
% -----------------------------------------------------------------------
clearvars, clc, close all

% -------------------------------------------------------------- Constants
global stochastic
stochastic = 1;
constants
% profile on -memory

% -------------------------------------------------------------- Heuristic
algorithm = 'heuristic';
initialvalues
% tic
heuristic
% toc
records.heuristic = record;
plotting

% ----------------------------------------------------------- Optimization
algorithm = 'optimization';
initialvalues
% tic
optimization
% toc
records.optimization = record;
plotting

% -------------------------------------------------------------- Constants
% stochastic = 0;
% constants_deterministic

% -------------------------------------------------------------- Heuristic
% algorithm = 'heuristic';
% initialvalues
% tic
% heuristic
% toc
% records.heuristic_det = record;
% plotting

% % ----------------------------------------------------------- Optimization
% algorithm = 'optimization';
% initialvalues
% optimization
% records.optimization_det = record;
% plotting



% ----------------------------------------------------------------- Saving
% profile report
saving(records)