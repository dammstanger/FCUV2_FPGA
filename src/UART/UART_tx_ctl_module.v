/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//ģ�����ƣ�UART_tx_baudrate_module
//���������������ʷ�����CLK=50MHz
//��	 �ߣ�dammstanger
//��	 �ڣ�20160426
/*************************************************************************/	
`define FRECLK	28'd50_000_000			//28bit
`define BAUDRATE 20'd115200
`define NONE_CHECK	2'd0
`define ODD_CHECK	2'd1					//��У��
`define EVEN_CHECK	2'd2				//żУ��
module UART_tx_ctl_module (CLK, RSTn, En,SBUF,Baudclk,FrameCheck,TX_pin,Enbaud,Doneflg);
	input CLK;
	input RSTn;
	input En;
	input Baudclk;
	input [1:0]FrameCheck;
	input [7:0]SBUF;
	output TX_pin;
	output Enbaud;
	output Doneflg;
	/********************************************/
	reg [3:0]sta;
	reg rTX_pin;
	reg checkbit;
	reg rEnbaud;
	reg rDoneflg;
	
always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
		begin
			sta <= 4'd0;
			rTX_pin <= 1'b1;				//����ʱ����
			checkbit <= 1'b0;
			rEnbaud <= 1'b0;
			rDoneflg <= 1'b0;
		end
	else 
		case (sta)
			4'd0:
				if(En)
					begin
						sta <= 4'd1;
						rEnbaud <= 1'b1;
					end
			4'd1:
			if(Baudclk)
					begin
					rTX_pin <= 1'b0;		//��ʼλ0
					sta <= 4'd2;
					end
			4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9:
				if(Baudclk)
					begin						
					rTX_pin <= SBUF[sta-2];		//����
					checkbit <= checkbit + SBUF[sta-2];
					sta <= sta + 4'd1;
					end
			4'd10:
				if(Baudclk)
					case (FrameCheck)
						`NONE_CHECK:
							begin
							rTX_pin <= 1'b1;			//ֹͣλ
							rDoneflg <= 1'b1;
							rEnbaud <= 1'b0;
							sta <= 4'd12;
							end			
						`ODD_CHECK:							//��У��
							begin
							if(checkbit)
								rTX_pin <= 1'b0;		//У��λ
							else
								rTX_pin <= 1'b1;
							sta <= 4'd11;
							end
						`EVEN_CHECK:						//żУ��
							begin
							if(!checkbit)
								rTX_pin <= 1'b0;		
							else
								rTX_pin <= 1'b1;
							sta <= 4'd11;
							end
					endcase
			4'd11:
				if(Baudclk)
					begin
					rTX_pin <= 1'b1;					//ֹͣλ		
					rDoneflg <= 1'b1;
					rEnbaud <= 1'b0;
					sta <= 4'd12;
					end			
			4'd12:
				begin
				checkbit <= 1'b0;
				rDoneflg <= 1'b0;
				sta <= 4'd0;
				end
		endcase
		
/***********************************/
	assign TX_pin = rTX_pin;
	assign Enbaud = rEnbaud;
	assign Doneflg = rDoneflg;

endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
