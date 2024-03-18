# X-RayCalc 3

X-ray Calc 3 is a revised and improved version of the software for computer simulation of X-ray reflectivity, including normal incidence and grazing incidence X-ray reflectometry (NIXR and GIXR). Find more information about the previous version here https://linkinghub.elsevier.com/retrieve/pii/S2352711019303681

In this version, the automatic optimization based on a modified LFPSO algorithm was implemented (see https://ieeexplore.ieee.org/document/10066334/ and https://journals.iucr.org/j/issues/2024/02/00/te5127/index.html for further details).

The X-Ray Calc distribution contains several demonstration projects located in the Examples folder. To see the demos, click the Open button, navigate to the Examples folder, and select a project file.

## Help
You can find  manuals, troubleshooting, and lessons here:

https://github.com/OleksiyPenkov/X-RayCalc3/wiki

## Acknowledging

If you use X-Ray Calc in your research, please cite the following paper:

_O.V. Penkov, M. Li, S. Mikki, A.Devizenko, I. Kopylets. X-Ray Calc 3: improved software for simulation and inverse problem-solving for X-Ray reflectivity.	Journal of Applied Crystallography, 57(2):1-12 (2024)._
 http://dx.doi.org/10.1107/S1600576724001031



## Changelog
2024-03-18 3.1.1

Changed:
 - Layer editing logic

2024-01-19 3.1.0

Added:
 - AutoSave project after each successful fitting iteration
 - x64 version was added to the distribution

2023-08-08 3.0.6

Fixed:
 - Poly Fitting (using of high orders)
 - Drawing of NP profiles
 - Minor errors
 - Interface fixes
Added:
 - Profile Table viewer
 - Storing auto-generated tables in the project file
 - Copy structure as image (png) 
 - GIU improvements

2023-07-31 3.0.5

Fixed:
 - Poly Fitting
 - Shake (k2 error)
 - "Paired" check-box behavior
 - Deleting exp. curve
 - Decimal separator mismatch
 - Main graph scaling
 - Refactoring (dcc32 warnings)
Reworked
 - Defalt Shake LFPSO parameters

2023-07-18 3.0.4

Added:
 - Popup menu for stacks
 - Popup menu for layers
 - Some settings
Fixed/Reworked
 - Poly Fitting
 - Stack selection
 - Global refactoring (Clearing [dcc32 Warnings/Hints]) 

2023-07-12 3.0.4 beta
Fixed:
 - Memory leaking
Added:
 - Data curve smoothing
 - Undo for layer operations


2023-07-06 3.0.3

Fixed:
 - Bugs in the interface (GitHub #12,8,9,13,14,18)
 - internal LFPSO optimizations
Added: 
 - Fitting by polynomial distributions
Changed
 - "Gradient editor" replaced with general "Functional profile editor" 

2023-06-26 3.0.2

Fixed:
 - Bugs in the interface (GitHub #15, #19, #20, #22)
 - Re-seeding in Shake LFPSO
Changed
 - Adding a new material
 - Optimizations of fitting algorithms
Added:
  - Materials selection in "New materials" 

2023-06-19  3.0.1

Fixed: 
  -  Calculation by the wave is not working
Added:
  -  Simple text editor for structure's JSON
  -  Viewer/editor for binary Henke tables  


