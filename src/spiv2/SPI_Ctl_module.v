/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：SPI_Ctl_module
//工程描述：SPI通信控制,负责发送接收模块，和波特率发生器的启停，CSN自动模式时的输出
//作	 者：dammstanger
//日	 期：20160811
/*************************************************************************/	
module SPI_Ctl_module 
(
    CLK, RSTn, En, EnTx_Sig, EnRx_Sig, Tx_Busy_Sig, Rx_Dat_Rdy, EnBuadcnt, CSN
);
	input CLK;
	input RSTn;
	input En;
	output EnTx_Sig;
	output EnRx_Sig;
	input Tx_Busy_Sig;
	input Rx_Dat_Rdy;
	output EnBuadcnt;
	output CSN;
	
	parameter CLK_FREE_LEVEL = 1'b0;
	 /**********************************/
	 reg rEnBuadcnt;
	 reg rCSN;
	 reg [3:0]sta_BDR;

	 /**********************************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta_BDR <= 1'b0;
		rEnBuadcnt <= 1'b0;
		rCSN <= 1'b1;
	end
	else begin
		case(sta_BDR)
		4'b0:begin
		if(En)begin									//收发使能
			rCSN <= 1'b0;
			rEnBuadcnt <= 1'b1;				//启动波特率发生器
			sta_BDR <= sta_BDR + 1'b1;
			end
		end
		4'd1:
		sta_BDR <= sta_BDR + 1'b1; 	//延时一个时钟
		4'd2:begin
			if(!CLK_FREE_LEVEL)begin
				if(!Tx_Busy_Sig)begin			//写模块在波特率发生时始终工作，以之判断结束
					rCSN <= 1'b1;
					rEnBuadcnt <= 1'b0;			//停止波特率发生器
					sta_BDR <= 1'b0;
				end
			end
			else
				if(Rx_Dat_Rdy)begin
					rCSN <= 1'b1;
					rEnBuadcnt <= 1'b0;			//停止波特率发生器
					sta_BDR <= 1'b0;
				end
		end
	endcase
	end

assign CSN = rCSN;
assign EnTx_Sig = En;
assign EnRx_Sig = En;
assign EnBuadcnt = rEnBuadcnt;
endmodule

