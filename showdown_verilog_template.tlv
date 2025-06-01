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
   m4_include_lib(https://raw.githubusercontent.com/rweda/showdown-2025-space-battle/a8e096c8901db15e33f809966a1754a8f3c7c3c3/showdown_lib.tlv)

   module team_YOUR_GITHUB_ID (
      // Inputs:
      input logic clk, input logic reset,
      input logic signed [7:0] x [m5_SHIP_RANGE], input logic signed [7:0] y [m5_SHIP_RANGE],   // Positions of your ships, as affected by last cycle's acceleration.
      input logic [7:0] energy [m5_SHIP_RANGE],   // The energy supply of each ship, as affected by last cycle's actions.
      input logic [m5_SHIP_RANGE] destroyed,   // Asserted if and when the ships are destroyed.
      input logic signed [7:0] enemy_x_p [m5_SHIP_RANGE], input logic signed [7:0] enemy_y_p [m5_SHIP_RANGE],   // Positions of enemy ships as affected by their acceleration last cycle.
      input logic [m5_SHIP_RANGE] enemy_cloaked,   // Whether the enemy ships are cloaked, in which case their enemy_x_p and enemy_y_p will not update.
      // Outputs:
      output logic signed [3:0] x_a [m5_SHIP_RANGE], output logic signed [3:0] y_a [m5_SHIP_RANGE],  // Attempted acceleration for each of your ships; capped by max_acceleration (see showdown_lib.tlv).
      output logic [m5_SHIP_RANGE] attempt_fire, output logic [m5_SHIP_RANGE] attempt_shield, output logic [m5_SHIP_RANGE] attempt_cloak,  // Attempted actions for each of your ships.
      output logic [1:0] fire_dir [m5_SHIP_RANGE]   // Direction to fire (if firing). ( 0 = right, 1 = down, 2 = left, 3 = up)
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
   
   // Your team as the first player. Provide:
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
