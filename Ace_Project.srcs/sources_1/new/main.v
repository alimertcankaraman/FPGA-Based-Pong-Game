`timescale 1ns / 1ps

module main(buzzer,xxx,CLK,RST_BTN,VGA_HS_O,VGA_VS_O,signal,VGA_R,VGA_G,VGA_B,vn,btnA,btnB,STOP_BTN);
input signal,vn;
input wire CLK;             // board clock: 100 MHz on Arty/Basys3/Nexys
input wire RST_BTN;         // reset button
input wire STOP_BTN;        //stop button
output wire VGA_HS_O;       // horizontal sync output
output wire VGA_VS_O;       // vertical sync output
output wire [4:0] VGA_R;    // 4-bit VGA red output
output wire [4:0] VGA_G;    // 4-bit VGA green output
output wire [4:0] VGA_B;     // 4-bit VGA blue output
input btnA;
input btnB;
output [3:0] xxx;
output wire buzzer;
//Light Sensor with xadc
reg [7:0] counter=0;

wire [11:0] adc;
wire [15:0] adc_out;
wire eoc_out,reset_in,drdy_out,channel_out,eos_out;
xadc_wiz_0 adconverter(
  .di_in(0),              // input wire [15 : 0] di_in
  .daddr_in(7'h1E),        // input wire [6 : 0] daddr_in
  .den_in(eoc_out),            // input wire den_in
  .dwe_in(0),            // input wire dwe_in
  .drdy_out(drdy_out),        // output wire drdy_out
  .do_out(adc_out),            // output wire [15 : 0] do_out
  .dclk_in(CLK),          // input wire dclk_in
  .reset_in(reset_in),        // input wire reset_in
  .vp_in(0),              // input wire vp_in
  .vn_in(0),              // input wire vn_in
  .vauxp14(signal),          // input wire vauxp14
  .vauxn14(vn),          // input wire vauxn14
  .channel_out(channel_out),  // output wire [4 : 0] channel_out
  .eoc_out(eoc_out),          // output wire eoc_out
  .alarm_out(0),      // output wire alarm_out
  .eos_out(eos_out),          // output wire eos_out
  .busy_out(0)        // output wire busy_out
);
assign adc = adc_out[15:4];

parameter p1 = 12'd500; //409
parameter p2 = 12'd1000; //819
parameter p3 = 12'd1500; //1228
parameter p4 = 12'd2000; //1638
wire [3:0] result;
assign xxx = ~result;
    wire sq_a, sq_c;
    wire [1:0] sq_b;
    wire [11:0] sq_a_x1, sq_a_x2, sq_a_y1, sq_a_y2;  // 12-bit values: 0-4095   moving red box 
    wire [23:0] sq_b_x1, sq_b_x2, sq_b_y1, sq_b_y2;  // Green boxes
    wire [11:0] sq_c_x1, sq_c_x2, sq_c_y1, sq_c_y2; // blue rect box   
   
    compareAll cmp1(adc,p1,result[0]);
    compareAll cmp2(adc,p2,result[1]);
    compareAll cmp3(adc,p3,result[2]);
    compareAll cmp4(adc,p4,result[3]);

   //Renklerin tonu için her bite bir veriyoruz
   assign VGA_R = {sq_a&&xxx[4],sq_a&&xxx[3],sq_a&&xxx[2],sq_a&&xxx[1],sq_a&&xxx[0]};//result;//{5{sq_a}};  // square a is red
   assign VGA_G = {sq_b&&xxx[4],sq_b&&xxx[3],sq_b&&xxx[2],sq_b&&xxx[1],sq_b&&xxx[0]};//result;//{5{sq_b}};  // square b is green
   assign VGA_B = {sq_c&&xxx[4],sq_c&&xxx[3],sq_c&&xxx[2],sq_c&&xxx[1],sq_c&&xxx[0]};//result;//{5{sq_c}};  // square c is blue
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
      
  
   wire rst = ~RST_BTN;    // reset is active low on Arty & Nexys Video
   // wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)
   wire [9:0] x;  // current pixel x position: 10-bit value: 0-1023
   wire [8:0] y;  // current pixel y position:  9-bit value: 0-511
   wire animate;  // high when we're ready to animate at end of drawing

   // generate a 25 MHz pixel strobe
   reg [15:0] cnt = 0;
   reg pix_stb = 0;
   always @(posedge CLK)
       {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000

   vga640x480 display (
       .i_clk(CLK),
       .i_pix_stb(pix_stb),
       .i_rst(rst),
       .o_hs(VGA_HS_O), 
       .o_vs(VGA_VS_O), 
       .o_x(x), 
       .o_y(y),
       .o_animate(animate)
   );


   square #(.H_SIZE(3),.IX_DIR(1)) sq_a_anim ( // initial horizontal position of square centre7
       .STOP_BTN(STOP_BTN), 
       .i_clk(CLK), 
       .i_ani_stb(pix_stb),
       .i_rst(rst),
       .i_animate(animate),
       .o_x1(sq_a_x1),
       .o_x2(sq_a_x2),
       .o_y1(sq_a_y1),
       .o_y2(sq_a_y2),
       .rectgreen_x1(sq_b_x1),
       .rectgreen_x2(sq_b_x2),
       .rectgreen_y1(sq_b_y1),
       .rectgreen_y2(sq_b_y2),
       
       .rectblue_x1(sq_c_x1),
       .rectblue_x2(sq_c_x2),
       .rectblue_y1(sq_c_y1),
       .rectblue_y2(sq_c_y2),
       .buzzer(buzzer)
   );

      rectalt #() sq_c_anim (
       .btnA(btnA),
       .btnB(btnB),
       .i_clk(CLK), 
       .i_ani_stb(pix_stb),
       .i_rst(rst),
       .i_animate(animate),
       .o_x1(sq_c_x1),
       .o_x2(sq_c_x2),
       .o_y1(sq_c_y1),
       .o_y2(sq_c_y2)
   );
   //Sabit kutular
   ////////////////////////////////////////////////////////////////////////////////////////
   rect #(.IX(50),.IY(50),.H_SIZE(20)) kutu1 (
          .i_clk(CLK), 
          .i_ani_stb(pix_stb),
          .i_rst(rst),
          .i_animate(animate),
          .o_x1(sq_b_x1[23:12]),
          .o_x2(sq_b_x2[23:12]),
          .o_y1(sq_b_y1[23:12]),
          .o_y2(sq_b_y2[23:12])
      );
    rect #(.IX(310),.IY(140),.H_SIZE(30)) kutu2 (
             .i_clk(CLK), 
             .i_ani_stb(pix_stb),
             .i_rst(rst),
             .i_animate(animate),
             .o_x1(sq_b_x1[11:0]),
             .o_x2(sq_b_x2[11:0]),
             .o_y1(sq_b_y1[11:0]),
             .o_y2(sq_b_y2[11:0])
         );
   //E?er koordinatlar?m karelerin s?n?rlar? içindeyse bir döndür, VGA'da görünsün, de?ilse 0;
   assign sq_a = ((x > sq_a_x1) & (y > sq_a_y1) &
       (x < sq_a_x2) & (y < sq_a_y2)) ? 1 : 0;
   assign sq_b[1] = ((x > sq_b_x1[23:12]) & (y > sq_b_y1[23:12]) &
       (x < sq_b_x2[23:12]) & (y < sq_b_y2[23:12])) ? 1 : 0;
      assign sq_b[0] = ((x > sq_b_x1[11:0]) & (y > sq_b_y1[11:0]) &
           (x < sq_b_x2[11:0]) & (y < sq_b_y2[11:0])) ? 1 : 0;    
   assign sq_c = ((x > sq_c_x1) & (y > sq_c_y1) &
       (x < sq_c_x2) & (y < sq_c_y2)) ? 1 : 0;
       
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

module vga640x480  (
    input wire i_clk,           // base clock
    input wire i_pix_stb,       // pixel clock strobe
    input wire i_rst,           // reset: restarts frame
    output wire o_hs,           // horizontal sync
    output wire o_vs,           // vertical sync
    output wire o_blanking,     // high during blanking interval
    output wire o_active,       // high during active pixel drawing
    output wire o_screenend,    // high for one tick at the end of screen
    output wire o_animate,      // high for one tick at end of active drawing
    output wire [9:0] o_x,      // current pixel x position
    output wire [8:0] o_y       // current pixel y position
    );

    // VGA timings https://timetoexplore.net/blog/video-timings-vga-720p-1080p
    localparam HS_STA = 16;              // horizontal sync start
    localparam HS_END = 16 + 96;         // horizontal sync end
    localparam HA_STA = 16 + 96 + 48;    // horizontal active pixel start
    localparam VS_STA = 480 + 11;        // vertical sync start
    localparam VS_END = 480 + 11 + 2;    // vertical sync end
    localparam VA_END = 480;             // vertical active pixel end
    localparam LINE   = 800;             // complete line (pixels)
    localparam SCREEN = 524;             // complete screen (lines)

    reg [9:0] h_count;  // line position
    reg [9:0] v_count;  // screen position
    // generate sync signals (active low for 640x480)
    assign o_hs = ~((h_count >= HS_STA) & (h_count < HS_END));
    assign o_vs = ~((v_count >= VS_STA) & (v_count < VS_END));

    // keep x and y bound within the active pixels
    assign o_x = (h_count < HA_STA) ? 0 : (h_count - HA_STA);
    assign o_y = (v_count >= VA_END) ? (VA_END - 1) : (v_count);

    // blanking: high within the blanking period
    assign o_blanking = ((h_count < HA_STA) | (v_count > VA_END - 1));

    // active: high during active pixel drawing
    assign o_active = ~((h_count < HA_STA) | (v_count > VA_END - 1)); 

    // screenend: high for one tick at the end of the screen
    assign o_screenend = ((v_count == SCREEN - 1) & (h_count == LINE));

    // animate: high for one tick at the end of the final active pixel line
    assign o_animate = ((v_count == VA_END - 1) & (h_count == LINE));

    always @ (posedge i_clk)
    begin
        if (i_rst)  // reset to start of frame
        begin
            h_count <= 0;
            v_count <= 0;
        end
        if (i_pix_stb)  // once per pixel
        begin
            if (h_count == LINE)  // end of line
            begin
                h_count <= 0;
                v_count <= v_count + 1;
            end
            else 
                h_count <= h_count + 1;

            if (v_count == SCREEN)  // end of screen
                v_count <= 0;
        end
    end
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
module rect #(
    H_SIZE=4,      // half square width (for ease of co-ordinate calculations)
    IX=320,         // initial horizontal position of square centre
    IY=474,         // initial vertical position of square centre
    D_WIDTH=640,    // width of display
    D_HEIGHT=480    // height of display
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2   // square bottom edge
    );

    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre

    assign o_x1 = x - 20 - H_SIZE;  // left: centre minus half horizontal size
    assign o_x2 = x + 20 + H_SIZE;  // right
    assign o_y1 = y - H_SIZE;  // top
    assign o_y2 = y + H_SIZE;  // bottom

    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x <= IX;
            y <= IY;
        end
        if (i_animate && i_ani_stb)
        begin

            if (x <= H_SIZE + 21)  // edge of square is at left of screen
               x <= x + 2 ;   // change direction to right
            if (x >= (D_WIDTH - H_SIZE - 21))  // edge of square at right
              x <= x - 2 ;   // change direction to left          
                  
        end
    end
endmodule

module rectalt #(
    H_SIZE=4,      // half square width (for ease of co-ordinate calculations)
    IXrect=320,         // initial horizontal position of square centre
    IYrect=474,         // initial vertical position of square centre
    D_WIDTH=640,    // width of display
    D_HEIGHT=480    // height of display
    )
    (
    input wire btnA,
    input wire btnB,
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2   // square bottom edge
    );

    reg [11:0] x = IXrect;   // horizontal position of square centre
    reg [11:0] y = IYrect;   // vertical position of square centre

    assign o_x1 = x - 20 - H_SIZE;  // left: centre minus half horizontal size
    assign o_x2 = x + 20 + H_SIZE;  // right
    assign o_y1 = y - H_SIZE;  // top
    assign o_y2 = y + H_SIZE;  // bottom

    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x <= IXrect;
            y <= IYrect;
        end
        if (i_animate && i_ani_stb)
        begin
        
        if (btnA==1)      
        x <= x + 2; 
        if (btnB==1) 
        x <= x - 2; 
        
            if (x <= H_SIZE + 21)  // edge of square is at left of screen
               x <= x + 2 ;   // change direction to right
            if (x >= (D_WIDTH - H_SIZE - 21))  // edge of square at right
              x <= x - 2 ;   // change direction to left          
                  
        end
    end
endmodule

module square #(
    H_SIZE=80,      // half square width (for ease of co-ordinate calculations)
    IX=320,         // initial horizontal position of square centre
    IY=40,         // initial vertical position of square centre
    IX_DIR=1,       // initial horizontal direction: 1 is right, 0 is left
    IY_DIR=1,       // initial vertical direction: 1 is down, 0 is up
    D_WIDTH=640,    // width of display
    D_HEIGHT=480    // height of display
    )
    (
    input wire STOP_BTN,
    input wire [23:0] rectgreen_x1,  // square left edge: 
    input wire [23:0] rectgreen_x2,  // square right edge
    input wire [23:0] rectgreen_y1,  // square top edge
    input wire [23:0] rectgreen_y2,   // square bottom edge
    
    input wire [11:0] rectblue_x1,  // square left edge: 12-bit value: 0-4095
    input wire [11:0] rectblue_x2,  // square right edge
    input wire [11:0] rectblue_y1,  // square top edge
    input wire [11:0] rectblue_y2,   // square bottom edge
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2,   // square bottom edge
    output wire buzzer
    );
   
    reg buzzerreg = 0;
    reg stopreg=0;
    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre
    reg x_dir = IX_DIR;  // horizontal animation direction
    reg y_dir = IY_DIR;  // vertical animation direction
    assign o_x1 = x - H_SIZE;  // left: centre minus half horizontal size
    assign o_x2 = x + H_SIZE;  // right
    assign o_y1 = y - H_SIZE;  // top
    assign o_y2 = y + H_SIZE;  // bottom

    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x <= IX;
            y <= IY;
            x_dir <= IX_DIR;
            y_dir <= IY_DIR;
        end
        if (i_animate && i_ani_stb)
        begin
            x <= (x_dir) ? x + 1 : x - 1;  // move right if positive x_dir
            y <= (y_dir) ? y + 1 : y - 1;  // move down if positive y_dir
            
            if(STOP_BTN==1)
            begin
            stopreg=0;
            buzzerreg=0;
            end
            else
            begin          
            if(stopreg==0)
            begin
            if (x <= H_SIZE + 1)  // edge of square is at left of screen
                x_dir <= 1;  // change direction to right
            if (x >= (D_WIDTH - H_SIZE - 1))  // edge of square at right
                x_dir <= 0;  // change direction to left          
            if (y <= H_SIZE + 1)  // edge of square at top of screen
                y_dir <= 1;  // change direction to down
            if (y >= (D_HEIGHT - H_SIZE -11) && (rectblue_x1-2<o_x1 && o_x2<rectblue_x2+2))  // edge of square at bottom
                 y_dir <= 0;  // change direction to up  
            if (y >= (D_HEIGHT - H_SIZE -11)&&~(rectblue_x1-2<o_x1 && o_x2<rectblue_x2+2))  
               begin 
               stopreg=1;  
               buzzerreg =1;
               end
            
            if ((rectgreen_x1[23:12]<o_x1) && (rectgreen_x2[23:12]>o_x2) && (rectgreen_y1[23:12]<o_y2) && (rectgreen_y2[23:12]>o_y2) && x_dir == 1 && y_dir == 1 ) y_dir <= 0;
            if ((rectgreen_x1[23:12]<o_x1) && (rectgreen_x2[23:12]>o_x2) && (rectgreen_y1[23:12]<o_y2) && (rectgreen_y2[23:12]>o_y2) && x_dir == 0 && y_dir == 1 ) y_dir <= 0;
            if ((rectgreen_x1[23:12]<o_x1) && (rectgreen_x2[23:12]>o_x2) && (rectgreen_y2[23:12]>o_y1) && (rectgreen_y1[23:12]<o_y1) && x_dir == 1 && y_dir == 0 ) y_dir <= 1;
            if ((rectgreen_x1[23:12]<o_x1) && (rectgreen_x2[23:12]>o_x2) && (rectgreen_y2[23:12]>o_y1) && (rectgreen_y1[23:12]<o_y1) && x_dir == 0 && y_dir == 0 ) y_dir <= 1;
                  
            if ((rectgreen_y1[23:12]<o_y1) && (rectgreen_y2[23:12]>o_y2) && (rectgreen_x1[23:12]<o_x2) && (rectgreen_x2[23:12]>o_x2) && x_dir == 1 && y_dir == 1 ) x_dir <= 0;
            if ((rectgreen_y1[23:12]<o_y1) && (rectgreen_y2[23:12]>o_y2) && (rectgreen_x1[23:12]<o_x2) && (rectgreen_x2[23:12]>o_x1) && x_dir == 0 && y_dir == 1 ) x_dir <= 1;
            if ((rectgreen_y1[23:12]<o_y1) && (rectgreen_y2[23:12]>o_y2) && (rectgreen_x1[23:12]<o_x2) && (rectgreen_x2[23:12]>o_x2) && x_dir == 1 && y_dir == 0 ) x_dir <= 0;
            if ((rectgreen_y1[23:12]<o_y1) && (rectgreen_y2[23:12]>o_y2) && (rectgreen_x1[23:12]<o_x2) && (rectgreen_x2[23:12]>o_x1) && x_dir == 0 && y_dir == 0 ) x_dir <= 1;
            
            if ((rectgreen_x1[11:0]<o_x1) && (rectgreen_x2[11:0]>o_x2) && (rectgreen_y1[11:0]<o_y2) && (rectgreen_y2[11:0]>o_y2) && x_dir == 1 && y_dir == 1 ) y_dir <= 0;
            if ((rectgreen_x1[11:0]<o_x1) && (rectgreen_x2[11:0]>o_x2) && (rectgreen_y1[11:0]<o_y2) && (rectgreen_y2[11:0]>o_y2) && x_dir == 0 && y_dir == 1 ) y_dir <= 0;
            if ((rectgreen_x1[11:0]<o_x1) && (rectgreen_x2[11:0]>o_x2) && (rectgreen_y2[11:0]>o_y1) && (rectgreen_y1[11:0]<o_y1) && x_dir == 1 && y_dir == 0 ) y_dir <= 1;
            if ((rectgreen_x1[11:0]<o_x1) && (rectgreen_x2[11:0]>o_x2) && (rectgreen_y2[11:0]>o_y1) && (rectgreen_y1[11:0]<o_y1) && x_dir == 0 && y_dir == 0 ) y_dir <= 1;
                                                                                                                     
            if ((rectgreen_y1[11:0]<o_y1) && (rectgreen_y2[11:0]>o_y2) && (rectgreen_x1[11:0]<o_x2) && (rectgreen_x2[11:0]>o_x2) && x_dir == 1 && y_dir == 1 ) x_dir <= 0;
            if ((rectgreen_y1[11:0]<o_y1) && (rectgreen_y2[11:0]>o_y2) && (rectgreen_x1[11:0]<o_x2) && (rectgreen_x2[11:0]>o_x1) && x_dir == 0 && y_dir == 1 ) x_dir <= 1;
            if ((rectgreen_y1[11:0]<o_y1) && (rectgreen_y2[11:0]>o_y2) && (rectgreen_x1[11:0]<o_x2) && (rectgreen_x2[11:0]>o_x2) && x_dir == 1 && y_dir == 0 ) x_dir <= 0;
            if ((rectgreen_y1[11:0]<o_y1) && (rectgreen_y2[11:0]>o_y2) && (rectgreen_x1[11:0]<o_x2) && (rectgreen_x2[11:0]>o_x1) && x_dir == 0 && y_dir == 0 ) x_dir <= 1;
            end      
            else begin   x<=(rectblue_x1+rectblue_x2)/2;   y <=rectblue_y1-3; x_dir <= 1;  y_dir <= 0; end //stopreg ==1 ise;
        end
        end
    end
    assign buzzer = buzzerreg;
endmodule

//COMPARING THE VALUES FROM XADC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module compareAll(parameters,adc,result);
input [11:0] parameters,adc;
output wire result;
wire [17:0] out;
Comparator cm1(adc[11:10],parameters[11:10],out[17:15]);
Comparator cm2(adc[9:8],parameters[9:8],out[14:12]);
Comparator cm3(adc[7:6],parameters[7:6],out[11:9]);
Comparator cm4(adc[5:4],parameters[5:4],out[8:6]);
Comparator cm5(adc[3:2],parameters[3:2],out[5:3]);
Comparator cm6(adc[1:0],parameters[1:0],out[2:0]);

assign result = 
 out[17] | (~out[15]&(out[16]&
(out[14] | (~out[12]&(out[13]&
(out[11] | (~out[9]&(out[10] &
(out[8]  | (~out[6]&(out[7]  &
(out[5]  | (~out[3]&(out[4]  &
(out[2]  | (~out[0]&(out[1])))))))))))))))));
endmodule

module Comparator(num,xadc,res);
input [1:0] num, xadc;
output [2:0] res;
 Mux_Greater gr(num,xadc,res[2]);
 Mux_Equal eq(num,xadc,res[1]);
 Mux_Less le(num,xadc,res[0]);
endmodule

module Mux_Less(in,slc,out);
input [1:0] in;
input [1:0] slc;
output out;
assign out = 
(~slc[1] & ~slc[0] & (in[1]|in[0])) 
| (~slc[1] & slc[0] & ((in[1]&~in[0])|(in[1]&in[0]))) 
| (slc[1] & ~slc[0] & (in[1]&in[0])) 
| (slc[1] & slc[0] & (in[0]&~in[0]));
endmodule

module Mux_Equal(in,slc,out);
input [1:0] in;
input [1:0] slc;
output out;
assign out = 
(~slc[1] & ~slc[0] & ~(in[1]|in[0])) 
| (~slc[1] & slc[0] & ((in[1]^in[0])&(~in[1]&in[0]))) 
| (slc[1] & ~slc[0] & ((in[1]^in[0])&(in[1]&~in[0]))) 
| (slc[1] & slc[0] & (in[1]&in[0]));
endmodule

module Mux_Greater(in,slc,out);
input [1:0] in;
input [1:0] slc;
output out;
assign out = 
(~slc[1] & ~slc[0] & (in[1]&~in[1])) 
| (~slc[1] & slc[0] & ~(in[1]|in[0]))
| (slc[1] & ~slc[0] & ~in[1])
| (slc[1] & slc[0] & ~(in[1]&in[0]));
endmodule