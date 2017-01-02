/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：UART_datapkg_module
//工程描述：串口打包发送模块
//作	 者：dammstanger
//日	 期：20160427
//格式：16进制 
/*************************************************************************/	
`define FRECLK	28'd50_000_000			//28bit
`define BAUDRATE 20'd115200
`define NONE_CHECK	2'd0
`define ODD_CHECK	2'd1					//奇校验
`define EVEN_CHECK	2'd2				//偶校验
module UART_datapkg_module (CLK, RSTn, TX_pin, RX_pin, Dat_In, Dat_Rdy);
input CLK;
input RSTn;
input RX_pin;
output TX_pin;
input [87:0]Dat_In;
input Dat_Rdy;


wire [1:0]Framchk=`NONE_CHECK;			//无校验

wire Tx_fifo_Full_sig;

reg Tx_WR_Req_sig;

reg [7:0]datbuf[15:0];
reg [2:0]sta;
reg [4:0]i;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
		begin
			i <= 1'b0;
		sta <= 2'b0;
		Tx_WR_Req_sig <= 1'b0;
		end
	else
		case (sta)
		3'd0:begin
			if(Dat_Rdy)begin
				datbuf[0] <= Dat_In[10:8];
				datbuf[1] <= Dat_In[7:0];
				datbuf[2] <= Dat_In[21:19];
				datbuf[3] <= Dat_In[18:11];
				datbuf[4] <= Dat_In[32:30];
				datbuf[5] <= Dat_In[29:22];
				datbuf[6] <= Dat_In[43:41];
				datbuf[7] <= Dat_In[40:33];
				datbuf[8] <= Dat_In[54:52];
				datbuf[9] <= Dat_In[51:44];
				datbuf[10] <= Dat_In[65:63];
				datbuf[11] <= Dat_In[62:55];
				datbuf[12] <= Dat_In[76:74];
				datbuf[13] <= Dat_In[73:66];
				datbuf[14] <= Dat_In[87:86];
				datbuf[15] <= Dat_In[84:77];
				sta <= sta + 1'b1;
			end
			else
				sta <= 1'b0; 
		end
		3'd1:begin
			if(i==5'd16)begin
				i <= 1'b0;
				sta <= 3'd0;
			end
			else if(!Tx_fifo_Full_sig)begin
				Tx_WR_Req_sig <= 1'b1;				//s发送的FIFO未满则继续发送
				sta <= sta + 3'd1;
			end			
		end
		3'd2:begin
			i <= i +1'b1;
			sta <= 3'd1;
			Tx_WR_Req_sig <= 1'b0;
		end	
		default:begin
			i <= 0;
			sta <= 2'd0;
		end
		endcase

UART_tx_interface UART_tx_interface_1(
	.CLK(CLK),
	.RSTn(RSTn),
	.WR_Req_sig(Tx_WR_Req_sig),
	.BaudRate(`BAUDRATE),
	.FrameCheck(Framchk),
	.FIFO_WR_Dat(datbuf[i]),
	.Full_sig(Tx_fifo_Full_sig),
	.TX_pin(TX_pin)
);

endmodule


/**********************END OF FILE COPYRIGHT @2016************************/	
