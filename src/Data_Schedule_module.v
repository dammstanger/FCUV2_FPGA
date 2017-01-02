/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：Data_Schedule_module
工程描述：数据调度
注	 意： 32位分两次读出：低位在地址值，先被读出。如果只取低16位，则只读一次，
					arm程序只取高16位也会读两次取出完整的32位。
作	 者：dammstanger
日	 期：20160912
*************************************************************************/	
module Data_Schedule_module (
input CLK,
input RSTn,
input En,

input [63:0]Time_us,

//---3080--------
input [7:0]Dat_3080,
input [2:0]Dat_Num_3080,
input Time_Mark_3080,
output RD_Req_3080,
//----9150-------
input [7:0]Dat_9150,
input [4:0]Dat_Num_9150,
input Dat_Rdy_In_9150,
input Time_Mark_9150,
output RD_Req_9150,
//----5611-------
input [31:0]Dat_5611,
input Dat_Rdy_In_5611,
input Time_Mark_5611,
//---SR04----------
input [15:0]Dat_SR04,
input Dat_Rdy_In_SR04,
input Time_Mark_SR04,
//------output-----------
output DatRdy_3080,
output [1:0]DatRdy_9150,		//bit1 mag rdy  bit0 imu rdy
output DatRdy_5611,
output DatRdy_SR04,
output [119:0]ADNS3080_Dat,		//增加了64bit的时间戳
output [223:0]MPU9150_Dat,
output [95:0]MS5611_Dat,
output [79:0]SR04_Dat
);

//===================盖时间戳====================
reg [63:0]Timestamp_SR04;
reg [63:0]Timestamp_5611;
reg [63:0]Timestamp_3080;
reg [63:0]Timestamp_9150;
always @ ( posedge Time_Mark_3080 )
if(Time_Mark_3080)
	Timestamp_3080 = Time_us;
	
always @ ( posedge Time_Mark_9150 )
if(Time_Mark_9150)
	Timestamp_9150 = Time_us;

always @ ( posedge Time_Mark_5611 )
if(Time_Mark_5611)
	Timestamp_5611 = Time_us;

always @ ( posedge Time_Mark_SR04 )
if(Time_Mark_SR04)
	Timestamp_SR04 = Time_us;

//==================SR04========================
reg [15:0]Buf_SR04;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		Buf_SR04 <= 1'b0;
	end
	else if(Dat_Rdy_In_SR04)
		Buf_SR04 <= Dat_SR04;
		
assign SR04_Dat = {Timestamp_SR04,Buf_SR04};
assign DatRdy_SR04 = Dat_Rdy_In_SR04;

//==================5611========================
reg [31:0]Buf_5611;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		Buf_5611 <= 1'b0;
	end
	else if(Dat_Rdy_In_5611)
		Buf_5611 <= Dat_5611;
		
assign MS5611_Dat = {Timestamp_5611,Buf_5611};
assign DatRdy_5611 = Dat_Rdy_In_5611;


//==================3080========================
reg rRD_Req_3080;
reg rDatRdy_3080;
reg [7:0]Buf_3080[6:0];
reg [2:0]sta;
reg [3:0]i_3080;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
		begin
		Buf_3080[0] <= 8'h0;
		Buf_3080[1] <= 8'h0;
		Buf_3080[2] <= 8'h0;
		Buf_3080[3] <= 8'h0;
		Buf_3080[4] <= 8'h0;
		Buf_3080[5] <= 8'h0;
		Buf_3080[6] <= 8'h0;
		i_3080 <= 1'b0;
		sta <= 2'b0;
		rRD_Req_3080 <= 1'b0;
		rDatRdy_3080 <= 1'b0;
		end
	else begin
		rDatRdy_3080 <= 1'b0;		//脉冲信号复位
		case (sta)
		3'd0:begin
			if(Dat_Num_3080==7)begin		//没有数据就绪标志，只是根据FIFO内数据个数判断一次采集的完成
				sta <= 3'b1; 
				rRD_Req_3080 <= 1'b1;
			end
			else
				sta <= 1'b0; 
		end
		3'd1:
		sta <= sta + 1'b1;			//加一个延时，不然会读到总线上上一次的一个数
		3'd2:
			if(i_3080==7)begin
				i_3080 <= 1'b0;
				rRD_Req_3080 <= 1'b0;
				rDatRdy_3080 <= 1'b1;
				sta <= 1'b0;
			end
			else begin
				Buf_3080[i_3080] <= Dat_3080;
				i_3080 <= i_3080 + 1'b1;
			end
		endcase
	end
	
assign RD_Req_3080 = rRD_Req_3080;
assign DatRdy_3080 = rDatRdy_3080;
assign ADNS3080_Dat = {Timestamp_3080,Buf_3080[6],Buf_3080[5],Buf_3080[4],Buf_3080[3],Buf_3080[2],Buf_3080[1],Buf_3080[0]};



//============9150============================
reg rRD_Req_9150;
reg [1:0]rDatRdy_9150;
reg [7:0]Buf_9150[19:0];
reg [2:0]sta_9150;
reg [4:0]i_9150;
reg [4:0]Datnum;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
		begin
		Datnum		<= 1'b0;
		i_9150 <= 1'b1;
		sta_9150 <= 2'b0;
		rRD_Req_9150 <= 1'b0;
		rDatRdy_9150 <= 1'b0;
		end
	else begin
		rDatRdy_9150 <= 1'b0;	//脉冲信号复位
		case (sta_9150)
		3'd0:begin
			if(Dat_Rdy_In_9150)begin
				Datnum <= Dat_Num_9150;
				sta_9150 <= 3'b1; 
				rRD_Req_9150 <= 1'b1;
			end
			else
				sta_9150 <= 1'b0; 
		end
		3'd1:
		sta_9150 <= sta_9150 + 1'b1;			//加一个延时，不然会读到总线上上一次的一个数
		3'd2:
			if(i_9150==Datnum)begin
				if(Datnum==20)				
					rDatRdy_9150 <= 2'd3;
				else
					rDatRdy_9150 <= 2'd1;			  //仅陀螺仪加速度数据就绪
					
				rRD_Req_9150 <= 1'b0;
				i_9150 <= 1'b0;
				sta_9150 <= 1'b0;
			end
			else begin
				Buf_9150[i_9150] <= Dat_9150;
				i_9150 <= i_9150 + 1'b1;
			end
		endcase
	end
		
assign RD_Req_9150 = rRD_Req_9150;
assign DatRdy_9150 = rDatRdy_9150;
assign MPU9150_Dat = {Timestamp_9150,
											Buf_9150[19],Buf_9150[18],Buf_9150[17],Buf_9150[16],Buf_9150[15],
											Buf_9150[14],Buf_9150[13],Buf_9150[12],Buf_9150[11],Buf_9150[10],
											Buf_9150[9],Buf_9150[8],Buf_9150[7],Buf_9150[6],Buf_9150[5],
											Buf_9150[4],Buf_9150[3],Buf_9150[2],Buf_9150[1],Buf_9150[0]};


endmodule


//========================Debug Data Pkg=================================
//reg [2:0]sta_dbg;
//reg [3:0]i;
//always @ ( posedge CLK or negedge RSTn )
//	if( !RSTn )
//		begin



/**********************END OF FILE COPYRIGHT @2016************************/	
