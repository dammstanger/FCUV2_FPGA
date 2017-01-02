/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：RFdebug_module
工程描述：无线调试模块
注	 意： 32位分两次读出：低位在地址值，先被读出。如果只取低16位，则只读一次，
					arm程序只取高16位也会读两次取出完整的32位。
作	 者：dammstanger
日	 期：20160902
*************************************************************************/	
module RFdebug_module (
input CLK,
input RSTn,
input En,
input ADNS3080_Rdy,
input MPU_Rdy,
input AriPress_Rdy,
input Ultra_Rdy,
input [55:0]ADNS3080_Dat,		//7个字节
input [159:0]MPU_Dat,				//10个16bit字，
input [31:0]AriPress_Dat,		//1个32位字
input [15:0]Ultra_Dat,			//1个16位字

input  SPI2_MISO,
output SPI2_CLK,
output SPI2_MOSI,
output NRF_CE,
output NRF_CSN,
input  NRF_IRQ

);

	
//======================双口RAM==============================
wire[7:0]DRAM_R_dat;
wire [4:0]DRAM_R_addr;
reg [7:0]DRAM_W_dat;
reg [4:0]DRAM_W_addr;
reg DRAM_W_En;

DRAM_8_32	DRAM_8_32_inst (
	.clock ( CLK ),
	.data ( DRAM_W_dat ),
	.rdaddress ( DRAM_R_addr ),
	.wraddress ( DRAM_W_addr ),
	.wren ( DRAM_W_En ),
	.q ( DRAM_R_dat )
	);

`define RDY_MPU_BIT	   4'd0
`define RDY_3080_BIT	 4'd1
`define RDY_PRESS_BIT	 4'd2
`define RDY_ULTRA_BIT	 4'd3

reg [3:0]Rdy_flg;			//标记位寄存器
reg [3:0]Clr_Rdy_flg; 

always @ ( MPU_Rdy, Clr_Rdy_flg[`RDY_MPU_BIT], RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_MPU_BIT])
		Rdy_flg[`RDY_MPU_BIT] <= 1'b0;
  else if(MPU_Rdy) 
		Rdy_flg[`RDY_MPU_BIT] <= 1'b1;

always @ ( ADNS3080_Rdy, Clr_Rdy_flg[`RDY_3080_BIT], RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_3080_BIT])
		Rdy_flg[`RDY_3080_BIT] <= 1'b0;
  else if(ADNS3080_Rdy) 
		Rdy_flg[`RDY_3080_BIT] <= 1'b1;
	
always @ ( AriPress_Rdy, Clr_Rdy_flg[`RDY_PRESS_BIT], RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_PRESS_BIT])
		Rdy_flg[`RDY_PRESS_BIT] <= 1'b0;
  else if(AriPress_Rdy) 
		Rdy_flg[`RDY_PRESS_BIT] <= 1'b1;
	

always @ ( posedge Ultra_Rdy, posedge Clr_Rdy_flg[`RDY_ULTRA_BIT],negedge RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_ULTRA_BIT])
		Rdy_flg[`RDY_ULTRA_BIT] <= 1'b0;
  else if(Ultra_Rdy) 
		Rdy_flg[`RDY_ULTRA_BIT] <= 1'b1;
	
//==================================================
parameter MPU = 4'd3,
					A3080 = 4'd1,
					PRESS = 4'd5,
					ULTRA = 4'd7;
reg [7:0]datbuf[6:0];
reg [3:0]sta_wsram;
reg [4:0]substp;
always @ ( negedge CLK or negedge RSTn )			//注意为配合DRAM时序，采用下降沿同步
	if( !RSTn )
		begin
		sta_wsram <= 1'b0;
		substp <= 1'b0;
		Clr_Rdy_flg <= 1'b0;
		DRAM_W_En <= 1'b0;
		end
	else begin
		Clr_Rdy_flg <= 1'b0;												//脉冲信号复位
		case (sta_wsram)
			4'd0:begin
				DRAM_W_En <= 1'b0;
				if(Rdy_flg[`RDY_3080_BIT])begin
					
					sta_wsram <=  A3080;
				end	
				else if(Rdy_flg[`RDY_MPU_BIT])begin
					
					sta_wsram <=  MPU;
				end
				else if(Rdy_flg[`RDY_PRESS_BIT])begin
					
					sta_wsram <=  PRESS;
				end
				else if(Rdy_flg[`RDY_ULTRA_BIT])begin
					Clr_Rdy_flg[`RDY_ULTRA_BIT] <= 1'b1;
					sta_wsram <=  ULTRA;
				end
				else
					sta_wsram <=  4'd0;
			end
			A3080:begin
				DRAM_W_En <= 1'b1;
				DRAM_W_addr <= 				5'd24;		
				DRAM_W_dat <= ADNS3080_Dat[15:8];	//dx	
				sta_wsram <= sta_wsram + 1'b1;
			end
			4'd2:begin
				DRAM_W_addr <= 				5'd25;
				DRAM_W_dat <= ADNS3080_Dat[23:16];//dy
				Clr_Rdy_flg[`RDY_3080_BIT] <= 1'b1;
				sta_wsram <= 1'b0;
			end
			MPU:begin
				DRAM_W_En <= 1'b1;
				DRAM_W_addr <= 5'd0;
				substp <= 1'b1;
				DRAM_W_dat <= MPU_Dat[7:0];
				sta_wsram <= sta_wsram + 1'b1;
			end
			4'd4:begin
				DRAM_W_addr <= substp;
				substp <= substp + 1'b1;
				case(substp)
				5'd1:begin DRAM_W_dat <= MPU_Dat[15:8];end		//ax
				5'd2:begin DRAM_W_dat <= MPU_Dat[23:16];end		//ay
				5'd3:begin DRAM_W_dat <= MPU_Dat[31:24];end	
				5'd4:begin DRAM_W_dat <= MPU_Dat[39:32];end		//az	
				5'd5:begin DRAM_W_dat <= MPU_Dat[47:40];end				
				5'd6:begin DRAM_W_dat <= MPU_Dat[71:64];end		//gx
				5'd7:begin DRAM_W_dat <= MPU_Dat[79:72];end		
				5'd8:begin DRAM_W_dat <= MPU_Dat[87:80];end		//gy
				5'd9:begin DRAM_W_dat <= MPU_Dat[95:88];end	
				5'd10:begin DRAM_W_dat <= MPU_Dat[103:96];end	//gz
				5'd11:begin DRAM_W_dat <= MPU_Dat[111:104];end		
				5'd12:begin DRAM_W_dat <= MPU_Dat[127:120];end	//mx
				5'd13:begin DRAM_W_dat <= MPU_Dat[119:112];end		
				5'd14:begin DRAM_W_dat <= MPU_Dat[143:136];end	//my
				5'd15:begin DRAM_W_dat <= MPU_Dat[135:128];end		
				5'd16:begin DRAM_W_dat <= MPU_Dat[159:152];end	//mz	
				5'd17:begin DRAM_W_dat <= MPU_Dat[151:144];end
				5'd18:begin DRAM_W_dat <= MPU_Dat[55:48];end	//temp
				5'd19:begin DRAM_W_dat <= MPU_Dat[63:56];Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;sta_wsram <= 1'b0;end			
				endcase
			end	
			PRESS:begin
				DRAM_W_En <= 1'b1;
				DRAM_W_addr <= 5'd28;
				DRAM_W_dat <= AriPress_Dat[15:8];	//Press H
				sta_wsram <= sta_wsram + 1'b1;
			end
			4'd6:begin
				DRAM_W_addr <= 5'd29;
				DRAM_W_dat <= AriPress_Dat[7:0];  //Press L
				Clr_Rdy_flg[`RDY_PRESS_BIT] <= 1'b1;
				sta_wsram <= 1'b0;
			end
			ULTRA:begin
				DRAM_W_En <= 1'b1;
				DRAM_W_addr <= 5'd30;
				DRAM_W_dat <= Ultra_Dat[15:8];	//Ultras H
				sta_wsram <= sta_wsram + 1'b1;
			end
			4'd8:begin
				DRAM_W_addr <= 5'd31;
				DRAM_W_dat <= Ultra_Dat[7:0];  //Ultras L
				Clr_Rdy_flg[`RDY_ULTRA_BIT] <= 1'b1;
				sta_wsram <= 1'b0;
			end
		endcase
	end

	
//===============2401======================================
parameter Tx_Dat_Num = 6'd32;
wire [7:0]SBUF_SPI2;
wire [7:0]RBUF_SPI2;
wire RD_Req_sig;
wire SPI2_RxDat_Rdy;
wire En_SPI2;
wire SPI2_Busy_Flg;
wire SPI2_Rdy;
wire dbg_2401;
wire dbg_2401_2;
SPI_2401_Driver SPI_2401_Driver_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En&SPI2_Rdy),																//需要外部的使能和底层的SPI模块就绪 二者共同作用
	.En_SPI( En_SPI2),
	.CE( NRF_CE),
	.CSN( NRF_CSN),
	.IRQ( NRF_IRQ),
	.SBUF( SBUF_SPI2),
	.RBUF( RBUF_SPI2),
	.Tx_Dat_Num( Tx_Dat_Num ),
	.Tx_Dat( DRAM_R_dat ),
	.Tx_Dat_Addr( DRAM_R_addr ),
//	.Rx_FIFO_RD_Req(  ),
//	.Rx_FIFO_dat(  ),
//	.Rx_FIFO_Full(  ),
	.SPI_Busy_Flg( SPI2_Busy_Flg ),
	.SPI_RxDat_Rdy( SPI2_RxDat_Rdy )
);

SPI_module #(1'b1,1'b0,8'd4)SPI_module_2401(		//主模式，CLK空闲为低，3分频 6.25MHz
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_SPI2),
	.PIN_MISO( SPI2_MISO ),
	.PIN_CLK(SPI2_CLK),
	.PIN_MOSI(SPI2_MOSI),	
	.SBUF(SBUF_SPI2),
	
	.RBUF(RBUF_SPI2),
	.Dat_Rdy_Sig(SPI2_RxDat_Rdy),
	.Busy_Flg(SPI2_Busy_Flg),
	.SPI_Rdy(SPI2_Rdy)
);
endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
