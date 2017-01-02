/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//模块名称：I2C_CLK_Gener
//工程描述：时钟发生器CLK=200MHz,最大速率400k,
//				
//作	 者：dammstanger
//日	 期：20160815
/*************************************************************************/	
module I2C_CLK_Gener (CLK, RSTn, En,Clkout);
	input CLK;
	input RSTn;
	input En;
	output Clkout;
	/********************************************/
	parameter SPEED=9'd400;		//通信时钟频率100:100k 400:400k
	
reg	[8:0]rcnt;
reg rBaudclk;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
	begin
		rcnt <= 1'b0;
		rBaudclk <= 1'b0;
	end
	else if((SPEED==400)&&(rcnt==124)||(SPEED==100)&&(rcnt==499))	begin		//125半周期时间=0.625us F=800kHz 500半周期时间为2.5us F=200kHz
		rBaudclk <= ~rBaudclk;
		rcnt <= 1'b0;
	end
	else begin
		if(En)
			rcnt <= rcnt + 1'b1;
		else
			rcnt <= 1'b0;
	end




/***********************************/
 assign Clkout = rBaudclk;

endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
