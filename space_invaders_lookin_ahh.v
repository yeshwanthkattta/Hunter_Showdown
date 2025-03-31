\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   macro(sign_extend, ['{{$3{$1[$2]}}, $1}'])
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;
   
   $count[7:0] = ($reset || >>1$reset) ? 8'b0 : >>1$count + 8'b1;
   
   /player[1:0]
      $player_id = #player[0];
      
      $reset = /top$reset;
      
      
      $xx_a[3:0] = >>1$reset ? 4'd5 :
         ((>>1$xx_p + 8'b10000000) > (8'd32 + 8'b10000000)) ? 4'b1111 :
         ((>>1$xx_p + 8'b10000000) < (- 8'd32 + 8'b10000000)) ? 4'b1 :
         4'b0;
      
      
      //$xx_a[3:0] = 4'b0;
      $yy_a[3:0] = >>1$reset ? 4'b1 : 4'b0;
      
      $xx_v[5:0] = $reset ? 6'b0 : >>1$xx_v + m5_sign_extend($xx_a, 3, 2);
      $yy_v[5:0] = $reset ? 6'b0 : >>1$yy_v + m5_sign_extend($yy_a, 3, 2);
      
      $xx_p[7:0] = $reset ? 8'b0 : >>1$xx_p + m5_sign_extend($xx_v, 5, 2);
      $yy_p[7:0] = $reset ? 8'd208 : >>1$yy_p + m5_sign_extend($yy_v, 5, 2);
      
      $attempt_fire = 1'b1;
      $fire_dir[1:0] = 2'b11; //0 = right, 1 = down, 2 = left, 3 = up
      
      $successful_fire = $attempt_fire && !>>1$bullet_exists && !>>1$lost;
      
      //bullet dimentions: 12x2
      $bullet_dir[1:0] = ($successful_fire) ? $fire_dir : >>1$bullet_dir;
      
      $bullet_x[7:0] = $successful_fire ? (($fire_dir == 2'b00) ? ($xx_p + 8'd13) : ($fire_dir == 2'b10) ? ($xx_p - 8'd13) : $xx_p) : (($bullet_dir == 2'b00) ? (>>1$bullet_x + 8'd16) : ($bullet_dir == 2'b10) ? (>>1$bullet_x - 8'd16) : >>1$bullet_x);
      
      $bullet_y[7:0] = $successful_fire ? (($fire_dir == 2'b01) ? ($yy_p - 8'd13) : ($fire_dir == 2'b11) ? ($yy_p + 8'd13) : $yy_p) : (($bullet_dir == 2'b01) ? (>>1$bullet_y - 8'd16) : ($bullet_dir == 2'b11) ? (>>1$bullet_y + 8'd16) : >>1$bullet_y);
      
      $bullet_exists = (>>1$bullet_exists || $successful_fire) ? (($bullet_dir[0] == 1'b0) ? ((($bullet_x < 8'd70) || ($bullet_x > 8'd186)) && (($bullet_y < 8'd65) || ($bullet_y > 8'd191))) : ((($bullet_y < 8'd70) || ($bullet_y > 8'd186)) && (($bullet_x < 8'd65) || ($bullet_x > 8'd191)))) : 1'b0;
      
      /other_player
         $ANY = /player[! /player$player_id]$ANY;
      
      $lost = $reset ? 1'b0 :
         >>1$lost ? 1'b1 :
         ($xx_p >= 8'd128 && $xx_p < 8'd197) ? 1'b1 :
         ($xx_p < 8'd128 && $xx_p > 8'd59) ? 1'b1 :
         ($yy_p >= 8'd128 && $yy_p < 8'd197) ? 1'b1 :
         ($yy_p < 8'd128 && $yy_p > 8'd59) ? 1'b1 :
         (/other_player$bullet_exists) ?
            (/other_player$bullet_dir[0] == 1'b1) ?
               ((($xx_p + 8'b10000000) >= (- /other_player$bullet_x + 8'b10000000 - 8'd6)) &&
               (($xx_p + 8'b10000000) <= (- /other_player$bullet_x + 8'b10000000 + 8'd6)) &&
               (($yy_p + 8'b10000000) >= (- /other_player$bullet_y + 8'b10000000 - 8'd13)) &&
               (($yy_p + 8'b10000000) <= (- /other_player$bullet_y + 8'b10000000 + 8'd13))) :
            ((($xx_p + 8'b10000000) >= (- /other_player$bullet_x + 8'b10000000 - 8'd13)) &&
            (($xx_p + 8'b10000000) <= (- /other_player$bullet_x + 8'b10000000 + 8'd13)) &&
            (($yy_p + 8'b10000000) >= (- /other_player$bullet_y + 8'b10000000 - 8'd6)) &&
            (($yy_p + 8'b10000000) <= (- /other_player$bullet_y + 8'b10000000 + 8'd6))) :
         1'b0;
      
      
      
      
      
      
      
      // =====================   VIZ SECTION   =====================
      
      \viz_js
         box: { left: -128, top: -128, width: 256, height: 256, strokeWidth: 0 },
         layout: { left: 256, top: 256, angle: 180 }, //Places both instances of viz over each other
      
         //Load all images
         init() {
            let ret = {};
            const player_id = (this.getIndex() == 1);
      
            // ------------  Load Background Image  ------------
      
            if (!player_id)
            {
               ret.background_img = this.newImageFromURL(
                  "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/back_grid_small.png",
                  "",
                  {
                     originX: "center", originY: "center",
                     left: 0, top: 0,
                     width: 128, height: 128,
                     imageSmoothing: false,
                  }
               );
            }




            // ------------  Load Ship Images  ------------

            ret.ship_sprite0_img = this.newImageFromURL(
               (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship0.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship0.png"),
               "",
               {
                  left: 0, top: 0,
                  width: 15, height: 18,
                  imageSmoothing: false,
               }
            );
            ret.ship_sprite0_img.set({ originX: "center", originY: "center" });

            ret.ship_sprite1_img = this.newImageFromURL(
               (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship1.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship1.png"),
               "",
               {
                  left: 0, top: 0,
                  width: 15, height: 18,
                  imageSmoothing: false,
               }
            );
            ret.ship_sprite1_img.set({ originX: "center", originY: "center" });

            ret.ship_sprite2_img = this.newImageFromURL(
               (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship2.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship2.png"),
               "",
               {
                  left: 0, top: 0,
                  width: 15, height: 18,
                  imageSmoothing: false,
               }
            );
            ret.ship_sprite2_img.set({ originX: "center", originY: "center" });

            ret.ship_sprite3_img = this.newImageFromURL(
               (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship3.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship3.png"),
               "",
               {
                  left: 0, top: 0,
                  width: 15, height: 18,
                  imageSmoothing: false,
               }
            );
            ret.ship_sprite3_img.set({ originX: "center", originY: "center" });




            // ------------  Load Bullet Image  ------------

            ret.bullet_img = this.newImageFromURL(
               (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/bullet_sprites/p2/bullet.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/bullet_sprites/p1/bullet.png"),
               "",
               {
                  left: 0, top: 0,
                  width: 3, height: 16,
                  imageSmoothing: false
               }
            );
            ret.bullet_img.set({ originX: "center", originY: "center" });




            // ------------  Hitbox Rectangles  ------------

            ret.ship_rect = new fabric.Rect({ width: 10, height: 10, strokeWidth: 0, fill: (player_id ? "#00ffb350" : "#ffff0050"), originX: "center", originY: "center" });
            ret.bullet_rect = new fabric.Rect({ width: 16, height: 2, strokeWidth: 0, fill: (player_id ? "#00ffb350" : "#ffff0050"), orginX: "center", originY: "center" });
            ret.bullet_rect.set({ originX: "center", originY: "center" });



            // ------------  Load Explosion Images  ------------

            ret.explody_sprite0 = this.newImageFromURL(
               "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/explody0.png",
               "",
               {
                  left: 0, top: 0,
                  width: 28, height: 28,
                  imageSmoothing: false,
                  
                  angle: player_id ? 180 : 0
               }
            );
            ret.explody_sprite0.set({ originX: "center", originY: "center", visible: false });
            
            ret.explody_sprite1 = this.newImageFromURL(
               "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/explody1.png",
               "",
               {
                  left: 0, top: 0,
                  width: 28, height: 28,
                  imageSmoothing: false,
                  
                  angle: player_id ? 180 : 0
               }
            );
            ret.explody_sprite1.set({ originX: "center", originY: "center", visible: false });
            
            ret.explody_sprite2 = this.newImageFromURL(
               "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/explody2.png",
               "",
               {
                  left: 0, top: 0,
                  width: 28, height: 28,
                  imageSmoothing: false,
                  
                  angle: player_id ? 180 : 0
               }
            );
            ret.explody_sprite2.set({ originX: "center", originY: "center", visible: false });
            
            ret.explody_sprite3 = this.newImageFromURL(
               "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/explody3.png",
               "",
               {
                  left: 0, top: 0,
                  width: 28, height: 28,
                  imageSmoothing: false,
                  
                  angle: player_id ? 180 : 0
               }
            );
            ret.explody_sprite3.set({ originX: "center", originY: "center", visible: false });
            
            ret.explody_sprite4 = this.newImageFromURL(
               "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/explody4.png",
               "",
               {
                  left: 0, top: 0,
                  width: 28, height: 28,
                  imageSmoothing: false,
                  
                  angle: player_id ? 180 : 0
               }
            );
            ret.explody_sprite4.set({ originX: "center", originY: "center", visible: false });
      
      
      
      
            // ------------  Background Masking and Picture Frame  ------------
            
            if (player_id)
            {
               ret.mask0 = new fabric.Rect({ left: 96, top: 0, width: 64, height: 256, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
               ret.mask1 = new fabric.Rect({ left: 0, top: 96, width: 256, height: 64, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
               ret.mask2 = new fabric.Rect({ left: -96, top: 0, width: 64, height: 256, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
               ret.mask3 = new fabric.Rect({ left: 0, top: -96, width: 256, height: 64, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
      
               ret.frame_img = this.newImageFromURL(
                  "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/gold_picture_frame.png",
                  "",
                  {
                     originX: "center", originY: "center",
                     left: 0, top: 0,
                     width: 190, height: 190,
                     imageSmoothing: false,
                  }
               );
            }
      
            return ret;
         },
      
         render() {
            let player_id = this.getIndex() != 0;
            let flip = 1;
      
            //Only works on even bit_counts (I think)
            function asSigned(val, bit_count) {
               if (val >= 2**(bit_count - 1)) {
                  val -= 2**bit_count;
               }
               return val;
            }
      
            let pseudo_this = this;
            function setExplosionFrame(frame_num) {
               pseudo_this.getObjects().explody_sprite0.set({visible: frame_num == 0});
               pseudo_this.getObjects().explody_sprite1.set({visible: frame_num == 1});
               pseudo_this.getObjects().explody_sprite2.set({visible: frame_num == 2});
               pseudo_this.getObjects().explody_sprite3.set({visible: frame_num == 3});
               pseudo_this.getObjects().explody_sprite4.set({visible: frame_num == 4});
               pseudo_this.getCanvas().requestRenderAll();
            }
      
      
            // ------------  Select Current Ship Image  ------------
      
            let current_ship_img;
            let accel_mag = ((asSigned('$xx_a'.asInt(), 4) ** 2) + (asSigned('$yy_a'.asInt(), 4) ** 2)) ** 0.5;
            if (accel_mag == 0)
            {
               current_ship_img = this.getObjects().ship_sprite0_img;
               this.getObjects().ship_sprite1_img.set({ visible: false });
               this.getObjects().ship_sprite2_img.set({ visible: false });
               this.getObjects().ship_sprite3_img.set({ visible: false });
            }
            else if (accel_mag < 1.75)
            {
               current_ship_img = this.getObjects().ship_sprite1_img;
               this.getObjects().ship_sprite0_img.set({ visible: false });
               this.getObjects().ship_sprite2_img.set({ visible: false });
               this.getObjects().ship_sprite3_img.set({ visible: false });
            }
            else if (accel_mag < 5)
            {
               current_ship_img = this.getObjects().ship_sprite2_img;
               this.getObjects().ship_sprite0_img.set({ visible: false });
               this.getObjects().ship_sprite1_img.set({ visible: false });
               this.getObjects().ship_sprite3_img.set({ visible: false });
            }
            else
            {
               current_ship_img = this.getObjects().ship_sprite3_img;
               this.getObjects().ship_sprite0_img.set({ visible: false });
               this.getObjects().ship_sprite1_img.set({ visible: false });
               this.getObjects().ship_sprite2_img.set({ visible: false });
            }
      
      
      
      
            // ------------  Set/Animate Ship  ------------
      
            const current_xx_p = asSigned('$xx_p'.asInt(), 8);
            const current_yy_p = -asSigned('$yy_p'.asInt(), 8);
      
            if (this.last_cycle <= this.getCycle()) // -------- If Moving Forward Cycles --------
            {
               //Determine the correct starting and ending angles for this cycle's animation
               let cycle_xx_a = '>>1$xx_a';
               let cycle_yy_a = '>>1$yy_a';
               while ((cycle_xx_a != unassigned) && (cycle_xx_a.asInt() == 0) && (cycle_yy_a.asInt() == 0))
               {
                  cycle_xx_a.step(-1);
                  cycle_yy_a.step(-1);
               }
               let set_angle = -(Math.atan2(asSigned(cycle_yy_a.asInt(), 4), asSigned(cycle_xx_a.asInt(), 4)) * 180 / Math.PI) + 90;
      
               let animate_angle;
               if (('$xx_a'.asInt() == 0) && ('$yy_a'.asInt() == 0))
               {
                  animate_angle = set_angle;
               }
               else
               {
                  animate_angle = -(Math.atan2(asSigned('$yy_a'.asInt(), 4), asSigned('$xx_a'.asInt(), 4)) * 180 / Math.PI) + 90;
               }
      
      
      
               // Set ship image:
               current_ship_img.set({
                  left: asSigned('>>1$xx_p'.asInt(), 8),
                  top: -asSigned('>>1$yy_p'.asInt(), 8),
                  angle: set_angle,
                  visible: !'>>1$lost'.asBool()
               });
      
               // Set ship rect:
               this.getObjects().ship_rect.set({
                  left: current_ship_img.left,
                  top: current_ship_img.top,
                  visible: current_ship_img.visible
               });
      
               let anim_finish_visible = !'$lost'.asBool();
               let anim_finish_last_visible = !'>>1$lost'.asBool();
               // Animate ship image:
               current_ship_img.animate({
                  left: current_xx_p,
                  top: current_yy_p,
                  angle: animate_angle,
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  onComplete: () => {
                     if (!anim_finish_visible)
                     {
                        current_ship_img.set({visible: false});
                        if (anim_finish_last_visible)
                        {
                           this.getObjects().explody_sprite0.set({left: current_xx_p, top: current_yy_p});
                           this.getObjects().explody_sprite1.set({left: current_xx_p, top: current_yy_p});
                           this.getObjects().explody_sprite2.set({left: current_xx_p, top: current_yy_p});
                           this.getObjects().explody_sprite3.set({left: current_xx_p, top: current_yy_p});
                           this.getObjects().explody_sprite4.set({left: current_xx_p, top: current_yy_p});
                           
                           setExplosionFrame(0);
                           setTimeout(setExplosionFrame, 75, 1);
                           setTimeout(setExplosionFrame, 241, 2);
                           setTimeout(setExplosionFrame, 407, 3);
                           setTimeout(setExplosionFrame, 573, 4);
                           setTimeout(setExplosionFrame, 739, 5);
                        }
                     }
                  },
                  easing: fabric.util.ease.easeOutCubic
               });
      
               // Animate ship rect:
               this.getObjects().ship_rect.animate({
                  left: current_xx_p,
                  top: current_yy_p,
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  onComplete: () => {this.getObjects().ship_rect.set({ visible: anim_finish_visible})},
                  easing: fabric.util.ease.easeOutCubic
               });
            }
            else // -------- If Moving Backward Cycles --------
            {
            //Determine the correct starting and ending angles for this cycle's animation
               let cycle_xx_a = '$xx_a';
               let cycle_yy_a = '$yy_a';
               while ((cycle_xx_a != unassigned) && (cycle_xx_a.asInt() == 0) && (cycle_yy_a.asInt() == 0))
               {
                  cycle_xx_a.step(-1);
                  cycle_yy_a.step(-1);
               }
               let animate_angle = -(Math.atan2(asSigned(cycle_yy_a.asInt(), 4), asSigned(cycle_xx_a.asInt(), 4)) * 180 / Math.PI) + 90;
      
               let set_angle;
               if (('$xx_a'.step().asInt() == 0) && ('$yy_a'.step().asInt() == 0))
               {
                  set_angle = animate_angle;
               }
               else
               {
                  set_angle = -(Math.atan2(asSigned('$yy_a'.step().asInt(), 4), asSigned('$xx_a'.step().asInt(), 4)) * 180 / Math.PI) + 90;
               }
      
      
      
               // Set ship image:
               current_ship_img.set({
                  left: asSigned('$xx_p'.step().asInt(), 8),
                  top: -asSigned('$yy_p'.step().asInt(), 8),
                  angle: set_angle,
                  visible: !'$lost'.asBool()
               });
      
               // Set ship rect:
               this.getObjects().ship_rect.set({
                  left: current_ship_img.left,
                  top: current_ship_img.top,
                  visible: current_ship_img.visible
               });
      
      
      
               // Animate ship image:
               current_ship_img.animate({
                  left: current_xx_p,
                  top: current_yy_p,
                  angle: animate_angle,
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  easing: fabric.util.ease.easeOutCubic
               });
      
               // Animate ship rect:
               this.getObjects().ship_rect.animate({
                  left: current_xx_p,
                  top: current_yy_p,
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  easing: fabric.util.ease.easeOutCubic
               });
            }
      
      
      
      
            // ------------  Set/Animate Bullet  ------------
      
            if (this.last_cycle < this.getCycle()) // -------- If Moving Forward Cycles --------
            {
               this.firing = '$successful_fire'.asBool();
      
               // Set bullet image:
               this.getObjects().bullet_img.set({
                  visible: this.firing ? true : this.getObjects().bullet_img.visible && '>>1$bullet_exists'.asBool(),
                  opacity: this.firing ? 0 : 1,
                  left: this.firing ? asSigned('>>1$xx_p'.asInt(), 8) : asSigned('>>1$bullet_x'.asInt(), 8),
                  top: this.firing ? -asSigned('>>1$yy_p'.asInt(), 8) : -asSigned('>>1$bullet_y'.asInt(), 8),
                  angle: ('$bullet_dir'.asInt() + 1) * 90,
               });
      
               // Set bullet rect:
               this.getObjects().bullet_rect.set({
                  visible: this.getObjects().bullet_img.visible,
                  opacity: this.getObjects().bullet_img.opacity,
                  left: this.getObjects().bullet_img.left,
                  top: this.getObjects().bullet_img.top,
                  angle: this.getObjects().bullet_img.angle - 90
               });
      
      
      
               let anim_finish_visible = '$bullet_exists'.asBool();
      
               // Animate bullet image:
               this.getObjects().bullet_img.animate({
                  opacity: 1,
                  left: asSigned('$bullet_x'.asInt(), 8),
                  top: -asSigned('$bullet_y'.asInt(), 8),
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  onComplete: () => {this.getObjects().bullet_img.set({ visible: anim_finish_visible})},
                  easing: fabric.util.ease.easeOutCubic
               });
      
               // Animate bullet rect:
               this.getObjects().bullet_rect.animate({
                  opacity: 1,
                  left: asSigned('$bullet_x'.asInt(), 8),
                  top: -asSigned('$bullet_y'.asInt(), 8),
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  onComplete: () => {this.getObjects().bullet_rect.set({ visible: anim_finish_visible})},
                  easing: fabric.util.ease.easeOutCubic
               });
            }
            else // -------- If Moving Backward Cycles --------
            {
               this.next_firing = '$successful_fire'.step().asBool();
      
               // Set bullet image:
               this.getObjects().bullet_img.set({
                  visible: '$bullet_exists'.asBool() || '$bullet_exists'.step().asBool(),
                  opacity: 1,
                  left: asSigned('$bullet_x'.step().asInt(), 8),
                  top: -asSigned('$bullet_y'.step().asInt(), 8),
                  angle: this.next_firing ? ('$bullet_dir'.step().asInt() + 1) * 90 : ('$bullet_dir'.asInt() + 1) * 90
               });
      
               // Set bullet rect:
               this.getObjects().bullet_rect.set({
                  visible: this.getObjects().bullet_img.visible,
                  opacity: this.getObjects().bullet_img.opacity,
                  left: this.getObjects().bullet_img.left,
                  top: this.getObjects().bullet_img.top,
                  angle: this.getObjects().bullet_img.angle - 90
               });
      
      
      
               let anim_finish_visible = '$bullet_exists'.asBool();
      
               // Animate bullet image:
               this.getObjects().bullet_img.animate({
                  opacity: this.next_firing ? 0 : 1,
                  left: this.next_firing ? asSigned('$xx_p'.asInt(), 8) : asSigned('$bullet_x'.asInt(), 8),
                  top: this.next_firing ? -asSigned('$yy_p'.asInt(), 8) : -asSigned('$bullet_y'.asInt(), 8),
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  onComplete: () => {this.getObjects().bullet_img.set({ visible: anim_finish_visible})},
                  easing: fabric.util.ease.easeOutCubic
               });

               // Animate bullet rect:
               this.getObjects().bullet_rect.animate({
                  opacity: this.next_firing ? 0 : 1,
                  left: this.next_firing ? asSigned('$xx_p'.asInt(), 8) : asSigned('$bullet_x'.asInt(), 8),
                  top: this.next_firing ? -asSigned('$yy_p'.asInt(), 8) : -asSigned('$bullet_y'.asInt(), 8),
               }, {
                  duration: 180,
                  onChange: () => {this.getCanvas().requestRenderAll()},
                  onComplete: () => {this.getObjects().bullet_rect.set({ visible: anim_finish_visible})},
                  easing: fabric.util.ease.easeOutCubic
               });
            }
         this.last_cycle = this.getCycle();
         }
   
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 600;
   *failed = 1'b0;
\SV
   endmodule
