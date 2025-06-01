\m5_TLV_version 1d: tl-x.org
\m5
   / A competition template for:
   /
   / /----------------------------------------------------------------------------\
   / | The First Annual Makerchip ASIC Design Showdown, Summer 2025, Space Battle |
   / \----------------------------------------------------------------------------/
   /
   / Each player or team modifies this template to provide their own custom spacecraft
   / control circuitry. This template is for teams using Verilog. A TL-Verilog-based
   / template is provided separately. Monitor the Showdown Slack channel for updates.
   / Use the latest template for submission.
   /
   / Just 3 steps:
   /   - Replace all YOUR_GITHUB_ID and YOUR_TEAM_NAME.
   /   - Code your logic in the module below.
   /   - Submit by Sun. July 26, 11 PM IST/1:30 PM EDT.
   /
   / Showdown details: https://www.redwoodeda.com/showdown-info and in the reposotory README.

   use(m5-1.0)

\SV
   // Include the showdown framework.
   m4_include_lib(https://raw.githubusercontent.com/PigNeck/space-scuffle/refs/heads/main/showdown_lib.tlv)

   module team_YOUR_GITHUB_ID (
      // Inputs:
      input logic clk, input logic reset,
      input signed logic [m5_SHIP_RANGE][5:0] x_v, input signed logic [m5_SHIP_RANGE][7:0] y_v,   // Velocity of your ships.
      input logic [m5_SHIP_RANGE][7:0] energy,   // The energy supply of each ship.
      input logic [m5_SHIP_RANGE] destroyed,   // Asserted if and when the ships are destroyed.
      input signed logic [m5_SHIP_RANGE][7:0] prev_enemy_x_p, input signed logic [m5_SHIP_RANGE][7:0] prev_enemy_y_p,   // Positions of enemy ships as updated by their control logic last cycle.
      input logic [m5_SHIP_RANGE] prev_enemy_cloaked,   // Whether the enemy ships are cloaked, in which case their prev_enemy_x_p and prev_enemy_y_p will not update.
      // Outputs:
      output signed logic [m5_SHIP_RANGE][3:0] x_a, output signed logic [m5_SHIP_RANGE][3:0] y_a,  // Attempted acceleration for each of your ships.
      output logic [m5_SHIP_RANGE] attempt_fire, output logic [m5_SHIP_RANGE] attempt_shield, [m5_SHIP_RANGE] attempt_cloak,  // Attempted actions for each of your ships.
      output logic [m5_SHIP_RANGE][1:0] fire_dir   // Direction to fire (if firing). ( 0 = right, 1 = down, 2 = left, 3 = up)
   );
   
   // Parameters defining the valid ranges of input/output values can be found near the top of "showdown_lib.tlv".
   
   // /------------------------------\
   // | Your Verilog logic goes here |
   // \------------------------------/
   
   endmodule


\TLV team_YOUR_GITHUB_ID(/_top)
   m5+verilog_wrapper(/_top, YOUR_GITHUB_ID)




// Compete!
// This defines the competition to simulate (for development).
// When this file is included as a library (for competition), this code is ignored.
\SV
   m5_makerchip_module
\TLV
   // Enlist teams for battle.
   
   // Your team as Player 1. Provide:
   //   - your GitHub ID, (as in your \TLV team_* macro, above)
   //   - your team name--anything you like (that isn't crude or disrespectful)
   m5_team(YOUR_GITHUB_ID, YOUR_TEAM_NAME)
   
   // Choose your opponent.
   // Note that inactive teams must be commented with "///", not "//", to prevent M5 macro evaluation.
   ///m5_team(random, Random 1)
   ///m5_team(random, Random 2)
   ///m5_team(sitting_duck, Sitting Duck)
   m5_team(test1, Test 1)
   
   
   // Instantiate the Showdown environment.
   m5+showdown(/top, /secret)
   
   *passed = /secret$passed;
   *failed = /secret$failed;
\SV
   endmodule
