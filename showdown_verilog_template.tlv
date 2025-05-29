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
   / template is provided separately.
   /
   /-------------------------------------------+-------------------------------------------\
   /                                                                                       |
   /      Your job is to write logic to pilot your ships to destroy the enemy ships!       |
   /                                                                                       |
   /                                                                                       |
   /   Your circuit should drive the following signals:                                    |
   /   - $xx_a: ship's x-axis acceleration                                                 |
   /   - $yy_a: ship's y_axis acceleration                                                 |
   /   - $attempt_shield: activate ship's shield if not on cooldown (The shield cools      |
   /   down for 4 cycles, charges up for 10, and stays active depending on how long it     |
   /   was changed up for)                                                                 |
   /   - $attempt_fire: fire one of the ship's bullets if one is available (each ship      |
   /   can have 3 bullets on screen at once)                                               |
   /   - $fire_dir: the direction in which the ship fires its bullet                       |
   /                                                                                       |
   /   Additional information:                                                             |
   /   - Ship dimensions are 10x10                                                         |
   /   - Bullet dimensions are 2x16                                                        |
   /   - Bullets move 16 tiles per cycle                                                   |
   /                                       Good luck!                                      |
   /                                                                                       |
   /-------------------------------------------+-------------------------------------------/

   use(m5-1.0)

\SV
   // Include the showdown framework.
   m4_include_lib(https://raw.githubusercontent.com/PigNeck/space-scuffle/refs/heads/main/showdown_lib.tlv)

   module team_YOUR_GITHUB_ID(
      // Inputs:
      input logic clk, input logic reset,
      input logic [m5_SHIP_RANGE][7:0] enemy_x_p, input logic [m5_SHIP_RANGE][7:0] enemy_y_p,   // Positions of enemy ships.
      input logic [m5_SHIP_RANGE][5:0] x_v, input logic [m5_SHIP_RANGE][7:0] y_v,   // Velocity of your ships.
      // Outputs:
      
      output logic [m5_SHIP_RANGE][3:0] x_a, output logic [m5_SHIP_RANGE][7:0] y_a,  // Attempted acceleration for each of your ships.
      output logic [m5_SHIP_RANGE] attempt_fire, output logic [m5_SHIP_RANGE] attempt_shield, [m5_SHIP_RANGE] attempt_cloak,  // Attempted actions for each of your ships.
      output logic [m5_SHIP_RANGE][1:0] fire_dir   // Direction to fire (if firing). ( 0 = right, 1 = down, 2 = left, 3 = up)
   );
   
   // Your Verilog logic goes here.
      
   endmodule

// TODO: Move this to showdown_lib.tlv.
// Search and replace all YOUR_GITHUB_ID with your GitHub ID, excluding non-word characters
// (alphabetic, numeric, and "_" only)
\TLV verilog_wrapper(/_top, _github_id)
   \SV_plus
      team_['']_github_id team_['']_github_id(
         // Inputs:
         .clk(clk),
         .reset(/_top$reset),
         .enemy_x_p(/enemy_ship[*]$xx_p),
         .enemy_y_p(/enemy_ship[*]$yy_p),
         .x_v(/ship[*]$xx_v),
         .y_v(/ship[*]$yy_v),
         // Outputs:
         .x_a($$xx_a_vect[4*m5_SHIP_CNT-1:0]),
         .y_a($$yy_a_vect[4*m5_SHIP_CNT-1:0]),
         .attempt_fire(/ship[*]$$attempt_fire),
         .attempt_shield(/ship[*]$$attempt_shield),
         .attempt_cloak(/ship[*]$$attempt_cloak),
         .fire_dir($$fire_dir_vect[2*m5_SHIP_CNT-1:0])
      );
   /ship[*]
      $xx_a[3:0] = /_top$xx_a_vect[4 * (#ship + 1) - 1 : 4 * #ship];
      $yy_a[3:0] = /_top$yy_a_vect[4 * (#ship + 1) - 1 : 4 * #ship];
      $fire_dir[1:0] = /_top$fire_dir_vect[2 * (#ship + 1) - 1 : 2 * #ship];


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
