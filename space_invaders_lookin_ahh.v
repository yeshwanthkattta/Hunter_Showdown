\m5_TLV_version 1d: tl-x.org
\m5
   
   // =================================================
   // Welcome!  New to Makerchip? Try the "Learn" menu.
   // =================================================
   
   use(m5-1.0)   /// uncomment to use M5 macro library.
   
   macro(sign_extend, ['{{$3{$1[$2]}}, $1}'])
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   $reset = *reset;
   
   \viz_js
      /*
      box: { width: 256, height: 256, strokeWidth: 0, fill: "darkblue" },
   
      /gridx[15:0]
         /gridy[15:0]
            /gridxx[15:0]
               /gridyy[15:0]
                  \viz_js
                     box: { fill: "hex" };
      */
      init() {
         //let img = "https://github.com/PigNeck/space-invader-lookin-ahh/blob/fe408bbb18ca5db451ded0adc7a0eee180a10db6/back_grid.png?raw=true";

         let rando_circle = new fabric.Circle(
            {originX: "center", originY: "center",
             radius: 10,
             fill: "#ffffff10"
            }
         )

         //let sprite_sheet_url = "https://www.pngfind.com/pngs/m/351-3516508_forget-the-gifs-heres-a-behind-the-scenes.png"
         let background_url = "https://github.com/PigNeck/space-invader-lookin-ahh/blob/fe408bbb18ca5db451ded0adc7a0eee180a10db6/back_grid.png"
         let background_img = new fabric.Image.fromURL(
            background_url,
            (img) => {
               this.getCanvas().add(img)
               this.getCanvas().renderAll()
            },
            {originX: "center", originY: "center",
             left: 0, top: 0,
             scaleX: 0.03, scaleY: 0.03,
             angle: -7,
            }
         )
         return {}
      },
   
   /player[1:0]
      $reset = /top$reset;
      
      $xx_a[3:0] = 4'b1;
      $yy_a[3:0] = 4'b1;
      
      $xx_v[5:0] = $reset ? $xx_a : >>1$xx_v + m5_sign_extend($xx_a, 3, 2);
      $yy_v[5:0] = $reset ? $yy_a : >>1$yy_v + m5_sign_extend($yy_a, 3, 2);
      
      $xx_p[7:0] = $reset ? $xx_v : >>1$xx_p + m5_sign_extend($xx_v, 5, 2);
      $yy_p[7:0] = $reset ? $yy_v : >>1$yy_p + m5_sign_extend($yy_v, 5, 2);
      
      \viz_js
         where: { top: 0, left: 0, width: 256, height: 256 },
         layout: { top: 0, left: 0 },
         box: { top: -128, left: -128, width: 256, height: 256, strokeWidth: 0 },
         
         template: { ship: ["Circle", { radius: 4, strokeWidth: 0, fill: "red", originX: "center", originY: "center" }] },
      
         render() {
            //Only works on even bit_counts (I think)
            function asSigned(val, bit_count) {
               if (val >= 2**(bit_count - 1)) {
                  val -= 2**bit_count;
               }
               return val;
            }
      
            this.getObjects().ship.left = asSigned('$xx_p'.asInt(), 8);
            this.getObjects().ship.top = asSigned('$yy_p'.asInt(), 8);
         }
   
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 600;
   *failed = 1'b0;
\SV
   endmodule
