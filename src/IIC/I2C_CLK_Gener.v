/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//ģ�����ƣ�I2C_CLK_Gener
//����������ʱ�ӷ�����CLK=200MHz,�������400k,
//				
//��	 �ߣ�dammstanger
//��	 �ڣ�20160815
/*************************************************************************/	
module I2C_CLK_Gener (CLK, RSTn, En,Clkout);
	input CLK;
	input RSTn;
	input En;
	output Clkout;
	/********************************************/
	parameter SPEED=9'd400;		//ͨ��ʱ��Ƶ��100:100k 400:400k
	
reg	[8:0]rcnt;
reg rBaudclk;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
	begin
		rcnt <= 1'b0;
		rBaudclk <= 1'b0;
	end
	else if((SPEED==400)&&(rcnt==124)||(SPEED==100)&&(rcnt==499))	begin		//125������ʱ��=0.625us F=800kHz 500������ʱ��Ϊ2.5us F=200kHz
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
