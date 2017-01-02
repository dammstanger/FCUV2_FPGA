
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//�ļ����ƣ�delayNms_cyc_module
//��	 �ܣ�ѭ����ʱNms���һ������
//��	 �ߣ�dammstanger
//��	 �ڣ�201608010
/*************************************************************************/	
module delayNms_cyc_module 
(
    CLK, RSTn, vclk
);

   input CLK;
	 input RSTn;
	 output vclk;
	 
	 /****************************************/
	 parameter N_MS = 16'd100;						//Ҫ��ʱ�ĺ�����
	 parameter T1MSval = 16'd49999;		//DB4CE15������ʹ�õľ���Ϊ50MHz��50M*0.001-1=49_999
	 
	 /***************************************/
	 reg [15:0]Count;

	 always @ ( posedge CLK or negedge RSTn )
	     if( !RSTn )
		      Count <= 16'd0;
		  else if( Count == T1MSval )
		      Count <= 16'd0;
		  else
		      Count <= Count + 1'b1;
	
    /****************************************/	
				
    reg [15:0]Countms;
	    
	 always @ ( posedge CLK or negedge RSTn )
        if( !RSTn )
		      Countms <= 1'd0;
		  else if( Count == T1MSval )
		      Countms <= Countms + 1'b1;
		  else if( Countms==N_MS)
		      Countms <= 16'd0;
	
   /********************************************/
	 
	 assign vclk = (Countms==N_MS)? 1'b1 : 1'b0;
	 
	 /********************************************/
		      

endmodule