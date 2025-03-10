# battery-management-system
This repository is the Matlab code base behind the article **Comparative Analysis of Rule-Based and Model Predictive Control Algorithms in Reconfigurable Battery Systems for EV Fast-Charging Stations**

Enjoy! Please give credit to this project if you use the codes for inspiration, as stated by regulations and research ethics.

If you have comments or questions, you can reach me at https://www.linkedin.com/in/pinterzoltanmark/ or pinzo@dtu.dk

You can dig yourself to my research at https://www.researchgate.net/profile/Zoltan-Pinter or https://scholar.google.com/citations?user=No1DAJcAAAAJ&hl=en

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Main file: **comparison.m**

Before running, load the parameters from **param.m**

Please download the Gurobi version mentioned in the article for running the optimization codes

Written with Matlab 2021b

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

The **abstract** of the article:

Battery systems can be utilized for charging electric vehicles to prevent abrupt loads on the electrical grid. We investigate a commercial reconfigurable battery system (RBS), which eliminates the need for a DC/DC converter by adjusting voltage/current through engaging or bypassing individual cells. However, stacking the cell voltages introduces the problem of voltage granularity, causing current ripples during reconfiguration. Additionally, since these battery cells are in their second life, their parameters are heterogeneous, necessitating the balancing of state-of-charge (SoC) and state-of-health (SoH) to ensure robust capacity, power, and lifetime. This work compares a rule-based control (RBC) and a model-predictive control (MPC) algorithm for battery management. The control objectives consist of tracking the constant current–constant voltage (CCCV) reference, minimizing the current ripple, and balancing the SoC and the SoH of the cells. The RBC is inspired by an industrial battery management system, while the MPC solves a mixed-integer-linear-program (MILP) problem. A high fidelity stochastic simulation environment is presented, and the online performance of the control algorithms are compared via Monte Carlo method, considering realistic cell heterogeneity, car variations and probability of car arrivals. The MPC reduces current the ripple by 25% compared to the RBC, while both perform comparably on other objectives. The RBC is at least 100 times faster and is preferable for scenarios with limited time and resources, whereas the MPC is better suited for performance-sensitive applications or complex control objectives.
