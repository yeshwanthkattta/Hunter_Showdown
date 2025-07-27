\m5_TLV_version 1d: tl-x.org
    \m5
       / This file implements a custom player for the Makerchip ASIC Design
       / Showdown (Space Battle) based on a triangular formation strategy.
       /
       / The strategy is as follows:
       /  1. Move each of the three ships to predefined coordinates that
       /     roughly form a triangle around the centre of the board.
       /  2. Once in formation (after a fixed number of cycles), fire a volley
       /     simultaneously from each ship along predetermined axes.  Firing
       /     costs 30 energy units【291063844880425†L21-L34】.
       /  3. Immediately cloak each ship for a few cycles.  Cloaking hides
       /     your position but costs 15 energy units per cycle【291063844880425†L31-L34】.  While
       /     cloaked, accelerate away from the centre so that the ships
       /     “split” and become harder targets.
       /  4. Repeat the process by reforming the triangle after the cloaking
       /     period expires.
       /
       / The board spans from −64 to +64 on both axes【291063844880425†L11-L19】, ships start near
       / the left side, and energy recharges by 15 per cycle up to a maximum
       / of 80【291063844880425†L21-L25】.  Maximum acceleration magnitude per axis is 4【291063844880425†L37-L39】.
       use(m5-1.0)

       var(viz_mode, devel)  /// Enables visualization for development; set to "demo" for competition.

       // -----------------------------------------------------------------------------
       // Macro defining the Verilog module that implements the triangular strategy.
       // The module name must be "team_triangle" to match the wrapper below.
       macro(team_triangle_module, [ '
          module team_triangle (
             // Clock and reset
             input  logic clk,
             input  logic reset,
             // Positions of your ships, updated each cycle after acceleration
             input  logic signed [7:0] x      [m5_SHIP_RANGE],
             input  logic signed [7:0] y      [m5_SHIP_RANGE],
             // Current energy levels for your ships
             input  logic        [7:0] energy [m5_SHIP_RANGE],
             // Flags indicating when ships have been destroyed
             input  logic        [m5_SHIP_RANGE] destroyed,
             // Enemy ship positions (unused in this simple strategy)
             input  logic signed [7:0] enemy_x_p [m5_SHIP_RANGE],
             input  logic signed [7:0] enemy_y_p [m5_SHIP_RANGE],
             input  logic        [m5_SHIP_RANGE] enemy_cloaked,
             input  logic        [m5_SHIP_RANGE] enemy_destroyed,
             // Outputs controlling your ships
             output logic signed [3:0] x_a [m5_SHIP_RANGE],  // X‑axis acceleration
             output logic signed [3:0] y_a [m5_SHIP_RANGE],  // Y‑axis acceleration
             output logic        [m5_SHIP_RANGE] attempt_fire,
             output logic        [m5_SHIP_RANGE] attempt_shield,
             output logic        [m5_SHIP_RANGE] attempt_cloak,
             output logic  [1:0] fire_dir [m5_SHIP_RANGE]    // Fire direction
          );

             // ------------------------------------------------------------------
             // Formation targets: three points that define a triangle.  These
             // coordinates are relative to the board centre (0,0).  Negative values
             // place ships to the left or below the centre, positive to the right
             // or above.  Adjust these offsets to tune your formation.
             localparam signed [7:0] TARGET_X0 = -20;
             localparam signed [7:0] TARGET_Y0 = -20;
             localparam signed [7:0] TARGET_X1 =  20;
             localparam signed [7:0] TARGET_Y1 = -20;
             localparam signed [7:0] TARGET_X2 =   0;
             localparam signed [7:0] TARGET_Y2 =  20;

             // Number of cycles spent moving into formation.  During these cycles
             // the ships accelerate toward their target coordinates.  A larger
             // value gives the ships more time to travel across the board.
             localparam int FORMATION_CYCLES = 30;
             // Number of cloaked cycles after firing.  Each cloaked cycle costs
             // 15 energy【291063844880425†L31-L34】, so keep this small to avoid draining energy.
             localparam int CLOAK_CYCLES     = 3;
             // Maximum acceleration magnitude per axis.  Defined in the library
             // as 4【291063844880425†L37-L39】.  Changing this value here makes the code easier
             // to read; the actual cap is enforced by the Showdown framework.
             localparam int MAX_ACCEL = 4;

             // State machine enumerations for the three phases of play.
             typedef enum logic [1:0] {
                STATE_FORMATION = 2'd0,
                STATE_FIRE      = 2'd1,
                STATE_CLOAK     = 2'd2
             } state_t;
             state_t state;
             logic [7:0] state_counter;

             // Predetermined fire directions for each ship.
             // For player 0: 0 = right, 1 = down, 2 = left, 3 = up.
             localparam logic [1:0] FIRE_DIR0 = 2'd0; // ship 0 fires right
             localparam logic [1:0] FIRE_DIR1 = 2'd2; // ship 1 fires left
             localparam logic [1:0] FIRE_DIR2 = 2'd1; // ship 2 fires down

             // State machine updates on clock edge.  Reset forces us back to
             // formation and clears the counter.  In formation we count up to
             // FORMATION_CYCLES, then fire for one cycle, then cloak for
             // CLOAK_CYCLES cycles.
             always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                   state        <= STATE_FORMATION;
                   state_counter <= 8'd0;
                end else begin
                   case (state)
                      STATE_FORMATION: begin
                         if (state_counter >= FORMATION_CYCLES - 1) begin
                            state        <= STATE_FIRE;
                            state_counter <= 8'd0;
                         end else begin
                            state_counter <= state_counter + 1;
                         end
                      end
                      STATE_FIRE: begin
                         // Remain in fire state for exactly one cycle
                         state        <= STATE_CLOAK;
                         state_counter <= 8'd0;
                      end
                      STATE_CLOAK: begin
                         if (state_counter >= CLOAK_CYCLES - 1) begin
                            state        <= STATE_FORMATION;
                            state_counter <= 8'd0;
                         end else begin
                            state_counter <= state_counter + 1;
                         end
                      end
                      default: begin
                         state        <= STATE_FORMATION;
                         state_counter <= 8'd0;
                      end
                   endcase
                end
             end

             // Combinational logic that produces outputs based on the current
             // state and inputs.  For each ship we compute desired acceleration
             // and actions.  Note: All arithmetic is signed and sized
             // appropriately to avoid synthesis warnings.
             always_comb begin
                // Default all outputs to zero.  They will be overwritten as
                // appropriate for each ship and state below.
                for (int i = 0; i < 3; i++) begin
                   x_a[i]          = 4'sd0;
                   y_a[i]          = 4'sd0;
                   attempt_fire[i]  = 1'b0;
                   attempt_shield[i] = 1'b0;
                   attempt_cloak[i] = 1'b0;
                   fire_dir[i]     = 2'd0;
                end

                // Loop over each ship and determine its actions
                for (int ship = 0; ship < 3; ship++) begin
                   if (destroyed[ship]) begin
                      // Destroyed ships take no action and produce no outputs.
                      x_a[ship]          = 4'sd0;
                      y_a[ship]          = 4'sd0;
                      attempt_fire[ship]  = 1'b0;
                      attempt_shield[ship] = 1'b0;
                      attempt_cloak[ship] = 1'b0;
                      fire_dir[ship]     = 2'd0;
                   end else begin
                      // Select per‑ship target coordinates and fire direction
                      signed [7:0] target_x;
                      signed [7:0] target_y;
                      logic [1:0]   dir;
                      case (ship)
                         0: begin
                            target_x = TARGET_X0;
                            target_y = TARGET_Y0;
                            dir      = FIRE_DIR0;
                         end
                         1: begin
                            target_x = TARGET_X1;
                            target_y = TARGET_Y1;
                            dir      = FIRE_DIR1;
                         end
                         default: begin
                            target_x = TARGET_X2;
                            target_y = TARGET_Y2;
                            dir      = FIRE_DIR2;
                         end
                      endcase

                      // Outputs depend on our current state
                      case (state)
                         STATE_FORMATION: begin
                            // Compute deltas to target position
                            signed [7:0] dx;
                            signed [7:0] dy;
                            dx = target_x - x[ship];
                            dy = target_y - y[ship];

                            // Desired acceleration values (signed 4‑bit)
                            signed [3:0] ax;
                            signed [3:0] ay;

                            // X‑axis acceleration toward target with saturation
                            if (dx > 0)
                               ax = (dx > MAX_ACCEL) ? MAX_ACCEL : dx[3:0];
                            else if (dx < 0)
                               ax = (dx < -MAX_ACCEL) ? -MAX_ACCEL : dx[3:0];
                            else
                               ax = 4'sd0;

                            // Y‑axis acceleration toward target with saturation
                            if (dy > 0)
                               ay = (dy > MAX_ACCEL) ? MAX_ACCEL : dy[3:0];
                            else if (dy < 0)
                               ay = (dy < -MAX_ACCEL) ? -MAX_ACCEL : dy[3:0];
                            else
                               ay = 4'sd0;

                            // Energy required equals sum of the absolute values of
                            // the acceleration components【291063844880425†L29-L30】.  If insufficient
                            // energy, we omit acceleration for this ship.
                            int unsigned abs_ax;
                            int unsigned abs_ay;
                            abs_ax = (ax < 0) ? -ax : ax;
                            abs_ay = (ay < 0) ? -ay : ay;
                            int unsigned energy_required;
                            energy_required = abs_ax + abs_ay;

                            if (energy[ship] >= energy_required) begin
                               x_a[ship] = ax;
                               y_a[ship] = ay;
                            end else begin
                               x_a[ship] = 4'sd0;
                               y_a[ship] = 4'sd0;
                            end

                            // During formation we neither fire nor cloak nor shield
                            attempt_fire[ship]   = 1'b0;
                            attempt_cloak[ship]  = 1'b0;
                            attempt_shield[ship] = 1'b0;
                            fire_dir[ship]       = dir;
                         end

                         STATE_FIRE: begin
                            // Attempt to fire if sufficient energy is available.
                            // Firing costs 30 energy units【291063844880425†L31-L34】.
                            if (energy[ship] >= 8'd30) begin
                               attempt_fire[ship] = 1'b1;
                               fire_dir[ship]     = dir;
                            end else begin
                               attempt_fire[ship] = 1'b0;
                               fire_dir[ship]     = dir;
                            end
                            // We remain stationary while firing
                            x_a[ship] = 4'sd0;
                            y_a[ship] = 4'sd0;
                            attempt_cloak[ship]  = 1'b0;
                            attempt_shield[ship] = 1'b0;
                         end

                         STATE_CLOAK: begin
                            // Cloak to conceal our position, provided we have the
                            // required 15 energy units per cycle【291063844880425†L31-L34】.
                            if (energy[ship] >= 8'd15) begin
                               attempt_cloak[ship] = 1'b1;
                            end else begin
                               attempt_cloak[ship] = 1'b0;
                            end

                            // Accelerate away from the centre to “split” the
                            // formation.  We decide the direction based on
                            // the sign of the current position: if the ship is
                            // on or to the right of the y‑axis, accelerate right;
                            // otherwise left.  Likewise for the y‑axis.  The
                            // magnitude of acceleration is capped at MAX_ACCEL.
                            signed [3:0] ax;
                            signed [3:0] ay;
                            if (x[ship] >= 0)
                               ax = MAX_ACCEL;
                            else
                               ax = -MAX_ACCEL;
                            if (y[ship] >= 0)
                               ay = MAX_ACCEL;
                            else
                               ay = -MAX_ACCEL;

                            // Check if we can afford the acceleration energy cost.
                            int unsigned abs_ax2;
                            int unsigned abs_ay2;
                            abs_ax2 = (ax < 0) ? -ax : ax;
                            abs_ay2 = (ay < 0) ? -ay : ay;
                            int unsigned energy_required2;
                            energy_required2 = abs_ax2 + abs_ay2;
                            if (energy[ship] >= energy_required2) begin
                               x_a[ship] = ax;
                               y_a[ship] = ay;
                            end else begin
                               x_a[ship] = 4'sd0;
                               y_a[ship] = 4'sd0;
                            end

                            // Do not fire or shield while cloaked
                            attempt_fire[ship]   = 1'b0;
                            attempt_shield[ship] = 1'b0;
                            fire_dir[ship]       = dir;
                         end

                         default: begin
                            // Should never happen, but default to safe behaviour
                            x_a[ship]          = 4'sd0;
                            y_a[ship]          = 4'sd0;
                            attempt_fire[ship]  = 1'b0;
                            attempt_cloak[ship] = 1'b0;
                            attempt_shield[ship] = 1'b0;
                            fire_dir[ship]     = dir;
                         end
                      endcase
                   end // not destroyed
                end // for each ship
             end // always_comb

          endmodule
       '])

    \SV
       // Include the showdown framework.  This brings in the definitions of
       // parameters such as m5_SHIP_RANGE, acceleration limits, and energy costs.
       m4_include_lib(https://raw.githubusercontent.com/rweda/showdown-2025-space-battle/main/showdown_lib.tlv)

    // [Optional]  Visualization of your logic for each ship.  When designing
    // your strategy, it can be helpful to visualize what your circuit is
    // commanding the ships to do.  Remove or comment out VIZ code for final
    // submission to avoid distracting from gameplay.
    \TLV team_triangle_viz(/_top, _team_num)
       m5+io_viz(/_top, _team_num)   /// Basic visualization of inputs/outputs
       \viz_js
          m5_DefaultTeamVizBoxAndWhere()
          // Custom visualization can be added here using fabric.js.  See the
          // VIZ documentation in the Makerchip IDE for details.
          render() {
             return [];
          },

    \TLV team_triangle(/_top)
       // Wrap our Verilog module so that it can interface with Makerchip.
       // The second argument, "triangle", is our GitHub/team identifier.  Do
       // **not** include the "team_" prefix here.
       m5+verilog_wrapper(/_top, triangle)

    // Compete!
    // The code below instantiates a simple battle for development and testing.
    // When used as a library in the actual tournament, this part is ignored.
    \SV
       m5_makerchip_module
    \TLV
       // Define the teams participating in this match.  Our team ID is
       // "triangle" and our team name is "Triangle_Masters".  Opponents are
       // selected using their GitHub IDs or sample names.
       m5_team(triangle, Triangle_Masters)
       // Uncomment one of the following lines to choose a sample opponent.
       // m5_team(random, Random)
       // m5_team(sitting_duck, Sitting_Duck)
       m5_team(demo1, Test_1)

       // Instantiate the Showdown environment.  This sets up the game board,
       // manages simulation, and provides the cycle count (*cyc_cnt).
       m5+showdown(/top, /secret)

       // End the simulation after either the game finishes or 100 cycles.
       *passed = /secret$passed || *cyc_cnt > 100;
       *failed = /secret$failed;
    \SV
       endmodule
       // Declare Verilog modules for the team(s) participating.  These macros
       // expand to instantiate the appropriate module definitions for each
       // team specified above.
       m4_ifdef(['m5']_team_\m5_get_ago(github_id, 0)_module,
                ['m5_call(team_\m5_get_ago(github_id, 0)_module)'])
       m4_ifdef(['m5']_team_\m5_get_ago(github_id, 1)_module,
                ['m5_call(team_\m5_get_ago(github_id, 1)_module)'])