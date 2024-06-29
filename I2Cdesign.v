module I2c_slave(RESET_IN,SCL,SDA,DATA_OUT,ADRESS_OUT);
input RESET_IN;
output[6:0]ADRESS_OUT;
output[7:0]DATA_OUT;
inout SCL;
inout SDA;

wire wr_rd;
reg[7:0]adress_in;
reg[7:0]wr_data;
reg[7:0]rd_data;
reg[7:0]sipo_data;
reg[7:0]piso_data;
reg[3:0]count;
reg[3:0]present_state;
reg[3:0]next_state;

reg sda_out;
reg dir_en;
reg[7:0] mem[255:0];

reg wr_en;
reg rd_en;
reg start;
reg stop;
reg count_en;
reg sipo_en;
reg piso_en;
reg stop_en;
reg start_en;

parameter state_idle        =4'b0000,
          state_start       =4'b0001,
          state_reg_addr    =4'b0010,
          state_reg_addr_ack=4'b0011,
          state_write       =4'b0100,
          state_write_ack   =4'b0101,
          state_read        =4'b0110,
          state_read_ack    =4'b0111,
          state_stop        =4'b1000,
          state_stop_m      =4'b1001;

assign SDA=dir_en?sda_out:1'bz;
assign DATA_OUT=rd_data;
assign {ADRESS_OUT,wr_rd}=adress_in;

always @(negedge SCL or posedge RESET_IN) begin
    if(RESET_IN) present_state<=state_idle;
    else begin
                 present_state<=next_state;

    end
end  
always @(negedge SCL or posedge RESET_IN) begin
    if(RESET_IN) count<=0;
    else begin
      if(count_en) count<=count+1;
      else count<=0;
    end
end
always @(negedge SCL or posedge RESET_IN) begin
  if(RESET_IN)begin
    if(wr_en) mem[ADRESS_OUT]<=wr_data;
    else if(rd_en) rd_data<=mem[ADRESS_OUT];
  end
end
always @ (negedge SDA) begin
    if(SCL) start<=1;
   end
always @ (posedge SDA) begin
    stop<=0;
     if(SCL && stop_en) stop<=1;
   end
 always @(*)begin
    case(present_state)
     state_idle: begin
                    if (start) next_state=state_start;
                    else next_state=state_idle;
                  end
     state_start: begin
                     next_state=state_reg_addr;
                  end 
     state_reg_addr:begin
                     if(count>=0 && count<6)begin
                        next_state=state_reg_addr;
                     end
                     else begin
                        next_state=state_reg_addr_ack;
                     end
                 end      
     state_reg_addr_ack:begin
                           if(sda_out==0)begin
                            if(wr_rd==0) begin
                             next_state=state_write;
                            end
                            else begin
                              next_state=state_read;
                            end
                           end     
                          else begin    
                             next_state=state_stop_m;
                          end
                     end  
     state_write:begin
                   if(count>=0 && count<6)begin
                     next_state=state_write;
                   end
                   else begin
                    next_state=state_write_ack;
                   end
              end     
     state_write_ack:begin
       if(sda_out==0)  next_state=state_reg_addr;
                       else next_state=state_stop_m;
               end
     state_read:begin
                  if(count>=0 && count<6)begin
                     next_state=state_read;
                  end
                  else begin
                    next_state=state_read_ack;
                  end
               end
     state_read_ack:begin
                     if(SDA==0)next_state=state_reg_addr;
                      else next_state=state_stop_m;
               end
     state_stop_m:begin
                    if(stop) next_state=state_stop;
                    else if(start) next_state=state_start;   
               end
     state_stop:begin
                  if(start) next_state=state_start;    
                   else next_state=state_stop;
              end
        default:next_state=state_idle;
    endcase
 end

 always @(*) begin
  case(present_state)  
    state_idle      :begin
                       dir_en=0;
                       sda_out=0;
                       count_en=0;
                       piso_en=0;
                       sipo_en=0;
                       wr_en=0;
                       rd_en=0;
                       stop_en=0;
                       start_en=1;
                       adress_in=0;
                       wr_data=0;
                    end
    state_start     :begin 
                       dir_en=0;
                       sda_out=0;
                       count_en=0;
                       piso_en=0;
                       sipo_en=0;
                       wr_en=0;
                       rd_en=0;
                       start_en=0;
                       adress_in=0;
                       wr_data=0;
                    end 
    state_reg_addr  :begin                
                       dir_en=0;
                       sda_out=0;
                       count_en=1;
                       piso_en=0;
                       sipo_en=1;
                       wr_en=0;
                       rd_en=0;
                       start_en=0;
                       adress_in=0;
                       wr_data=0;
                    end 
    state_reg_addr_ack:begin
                                  adress_in=sipo_data;      
      
                        dir_en=1;
                        sda_out=0;
                        count_en=0;
                        piso_en=0;
                        sipo_en=0;
                        wr_en=0;
                        rd_en=0;
                        wr_data=0;
                    end
    state_write     :begin
                       dir_en=0;
                       sda_out=0;
                       count_en=1;
                       piso_en=0;
                       sipo_en=1;
                       wr_en=0;
                       rd_en=0;
                       adress_in=0;
                       wr_data=0;
                    end 
    state_write_ack :begin
                       dir_en=1;
                       sda_out=0;
                       count_en=0;
                       piso_en=0;
                       sipo_en=0;
                       wr_data=sipo_data;
                       wr_en=1;
                       rd_en=0;
                       adress_in=0;
                    end
    state_read      :begin
                       dir_en=1;
                       sda_out=piso_data[0];
                       count_en=1;
                       piso_en=1;
                       sipo_en=0;
                       wr_en=0;
                       rd_en=(count==0)?1:0;
                       adress_in=0;
                       wr_data=0;
                    end 
    state_read_ack  :begin
                       dir_en=0;
                       sda_out=0;
                       count_en=0;
                       piso_en=0;
                       sipo_en=0;
                       wr_en=0;
                       rd_en=0;
                       adress_in=0;
                       wr_data=0;
                    end 
    state_stop_m    :begin
                       dir_en=0;
                       sda_out=0;
                       count_en=0;
                       piso_en=0;
                       sipo_en=0;
                       wr_en=0;
                       rd_en=0;
                       stop_en=1;
                       adress_in=0;
                       wr_data=0;
                    end 
    state_stop       :begin
                       dir_en=0;
                       sda_out=0;
                       count_en=0;
                       piso_en=0;
                       sipo_en=0;
                       wr_en=0;
                       rd_en=0;
                       adress_in=0;
                       wr_data=0;
                    end 
      default        :begin
                       dir_en=0;
                       sda_out=0;
                       count_en=0;
                       piso_en=0;
                       sipo_en=0;
                       wr_en=0;
                       rd_en=0;
                       adress_in=0;
                       wr_data=0;
                    end 
  endcase
 end

 always@(negedge SCL)  begin
   if(RESET_IN) sipo_data<=0;
   else begin
      if(sipo_en)sipo_data<={SDA,sipo_data[7:1]};
   end
 end

 always@(negedge SCL) begin
   if(RESET_IN) piso_data<=0;
   else begin
      if(piso_en)begin
      if(count==0)piso_data<=rd_data;
      else piso_data<=piso_data>>1;
   end
 end
 end
endmodule