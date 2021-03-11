Usage: this program takes instances in format .txt with problem specifications for the Vehicle Routing
Problem With Time Windows Time Windows and outputs the amount of cars and total distance covered.

=============================================================================================================

Files that accompany this hand-in and a brief explanation:

- 'best_run.txt': a text file with the results from the best run (600s per instance);
- 'best_tuning.txt': a text file with the results from the tune (30s per instance);
- 'Ie.txt': a text file with the results for inter-route relocation (10s per instance);
- 'Ie_Ia.txt':a text file with the results for inter and intra-route relocations (10s per instance);
- Instances folder: text files with all instances that serve as input for 'VRPTW.jl';
- 'bestKnown.jl': a Julia file containing dictionaries with the best known objective values for the
every instance inside the instances folder;
- 'myTuner.jl': a Julia file that is included in 'VRPTW.jl', that performs parameter tuning (alpha and temp
in this case);
- 'supportFunc.jl': a Julia file with supporting functions for the main file 'VRPTW.jl';
- 'VRPTW.jl': a Julia file which takes instances as input and outputs the amount of cars needed and distance
covered.

OBS.: all txt files are inside 'Results' folder.

============================================================================================================

Functionality 

- Tuning: in 'VRPTW.jl' go to line 361 and set the variable 'tune' to 1. Open the file 'myTuner.jl' and pick
which T set should be used on line 7, which alphas on line 8, the time limit per instance on line 9, the
amount of samples per instance on line 10, which group of instances should be used on line 11, which suffixes
will be the train set on line 15, and which will be the test set on line 16. If tuning is performed, the
variables T and alpha are overwritten by the results obtained from it when the program runs;
- Running all instances: in 'VRPTW.jl' go to line 363 and set the variable 'runAll' to 1. This will result in
running the 40 instances and printing the result for each. Set the time-limit for each on line 353;
- Running one instance: in 'VRPTW.jl' go to line 363 and set the variable 'runAll' to 0. This will run one 
specific instance, which can be specified on line 397. Plotting will occur by the default, showing cost
convergence for this instance;
- Plotting: by default, plotting only occurs when running one instance. If no plotting is wanted,
go to line 397 and set the last argument of that function to 0;
- How to re-do intra/inter analysis: Run 'VRPTW.jl' with the desired time-limit, and save the results
printed. Then, go to line 232 in 'VRPTW.jl' and follow the instructions. Run again, saving the results. The
first run was with both inter and intra-route relocation, whilst the second run was only with inter.

OBS.: all instance files should be in the same folder as the Julia files.