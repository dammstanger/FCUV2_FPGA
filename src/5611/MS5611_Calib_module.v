/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//�������ƣ�MS5611_Calib_module
//�������������ڴ������ģ��
//��	 �ߣ�dammstanger
//��	 �ڣ�20160820
//��	ע��//ע�⣺�Ӽ��˳������������ȼ���			PROM[0-5]��ӦC1-6
//				��ѹ��λmbar ������=����ֵ*100			�¶ȵ�λ��C�� ����Ŵ�100��
/*************************************************************************/	
module MS5611_Calib_module (CLK,RSTn,Rx_FIFO_RD_Dat,Dat_Num,Rx_FIFO_Full, Rx_RD_Req_sig, Dat_Rdy, Calib_Rdy, Calib_Pressure);
input  CLK;
input  RSTn;
input  [7:0]Rx_FIFO_RD_Dat;
input  [3:0]Dat_Num;
input  Rx_FIFO_Full;
output Rx_RD_Req_sig;
input  Dat_Rdy;
output Calib_Rdy;
output [31:0]Calib_Pressure;


//--------------------------------

reg signed[24:0]Mult_A;
reg signed[35:0]Mult_B;	
wire [60:0]Mult_Val;
Mult25_36	Mult25_36_5611 (
	.dataa ( Mult_A ),
	.datab ( Mult_B ),
	.result ( Mult_Val )
	);


reg unsigned[15:0]PROM[5:0];
reg [23:0]D1;						//pressure			25λ�Ӷ�һλ���λʼ��Ϊ0����֤Ϊ�޷�����
reg [23:0]D2;						//temperature		
reg signed[24:0]dT;
reg signed[41:0]OFF;
reg signed[41:0]SENS;
reg signed[31:0]TEMP_sub20;		//ʵ���¶�-20��ֵ�����ڼ���
reg signed[15:0]Ttmp;
reg signed[60:0]Ptmp;
reg signed[31:0]P;

//------------�ֲ����ֵ�����������--------------
//			PROM[0] <= 16'h9cbf;
//			PROM[1] <= 16'h903c;
//			PROM[2] <= 16'h5b15;
//			PROM[3] <= 16'h5af2;
//			PROM[4] <= 16'h82b8;
//			PROM[5] <= 16'h6e98;

reg rRx_RD_Req_sig;
reg rCalib_Rdy;

reg [4:0]stp_calib;
reg [4:0]i;
reg [2:0]j;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
		begin
			PROM[0] <= 16'hB628;
			PROM[1] <= 16'hC08F;
			PROM[2] <= 16'h6EB2;
			PROM[3] <= 16'h657D;
			PROM[4] <= 16'h8189;
			PROM[5] <= 16'h6998;
			D1			<= 24'd0;
			D2			<= 24'd0;
			dT							<= 1'b0;
			OFF							<= 1'b0;
			SENS						<= 1'b0;
			TEMP_sub20			<= 1'b0;
			Ptmp						<= 1'b0;
			P								<= 1'b0;
			i 							<= 1'b0;
			j 							<= 1'b0;
			stp_calib 			<= 1'b0;
			rRx_RD_Req_sig 	<= 1'b0;
			rCalib_Rdy			<= 1'b0;
			Mult_A					<= 1'b0;
			Mult_B					<= 1'b0;
		end
	else begin
		rCalib_Rdy			<= 1'b0;
		case (stp_calib)
		5'd0:begin
			if(Dat_Rdy)begin
				stp_calib <= stp_calib + 1'b1;
				rRx_RD_Req_sig <= 1'b1;
			end
			else
				stp_calib <= 1'b0; 
		end
		5'd1://------------------------��һ����ʱ����Ȼ�����������һ�ε�һ����
			if(Rx_FIFO_Full)begin								//���FIFO����˵����PROM������
				stp_calib <= stp_calib + 1'b1;
			end
			else if(Dat_Num==4'd6)begin
				stp_calib <= stp_calib + 5'd2;		//�����6�ֽ�˵�����¶Ⱥ�ѹ������
			end
			else begin
				rRx_RD_Req_sig <= 1'b0;
				stp_calib <= 1'b0;
			end
		5'd2://-------------------------------------
			if(i==5'd14)begin
				i <= 1'b0;
				j <= 1'b0;
				rRx_RD_Req_sig <= 1'b0;
				stp_calib <= 5'b0;
			end
			else begin
				i <= i+1'b1;
				if(i>=2)begin
					if(i%2)begin
						PROM[j][7:0] <= Rx_FIFO_RD_Dat;
						j <= j + 1'b1;
					end
					else
						PROM[j][15:8] <= Rx_FIFO_RD_Dat;
				end
			end
		5'd3://-------------------------------------
			if(i==5'd6)begin
				i <= 1'b0;
				j <= 1'b0;
				rRx_RD_Req_sig <= 1'b0;
				//���㿪ʼ
				dT <= D2 - {PROM[4],8'b0};														//dT = D2 - Tref = D2 - C5*2^8;
//					dT <= -25'd16776960;
				stp_calib <= stp_calib + 5'd1;
			end
			else begin
				i <= i + 1'b1;
				case(i)
					5'd0: D2[23:16] <= Rx_FIFO_RD_Dat;
					5'd1: D2[15:8] 	<= Rx_FIFO_RD_Dat;
					5'd2: D2[7:0] 	<= Rx_FIFO_RD_Dat;
					5'd3: D1[23:16] <= Rx_FIFO_RD_Dat;
					5'd4: D1[15:8] 	<= Rx_FIFO_RD_Dat;
					5'd5: D1[7:0] 	<= Rx_FIFO_RD_Dat;
				endcase
			end
		5'd4:begin
			Mult_A <= dT;
			Mult_B <= PROM[3];
			stp_calib <= stp_calib + 5'd1;
		end	
		5'd5:begin
			Mult_B <= PROM[2];												//����SENS �� TCS*dt�Ĺ��̣�
			//OFFT1 + TCO*dT =C2*2^16 + (C4* dT)/2^7
			OFF <= {PROM[1],16'd0} + $signed({{7{Mult_Val[60]}},Mult_Val[60:7]});	//�����з���������λƴ�������λ	
			stp_calib <= stp_calib + 5'd1;
		end
		5'd6:begin
			Mult_B <= PROM[5];												//����TEMP �� TEMPSENS*dt�Ĺ��̣�
			SENS <= {PROM[0],15'd0} + $signed({{8{Mult_Val[60]}},Mult_Val[60:8]});
			stp_calib <= stp_calib + 5'd1;
		end
		5'd7:begin
			TEMP_sub20 <= $signed({{23{Mult_Val[60]}},Mult_Val[60:23]});
			stp_calib <= stp_calib + 5'd1;
		end
		5'd8:begin
		if(TEMP_sub20<0)begin										//��ʵ���¶�<20C��,����2�ײ���
//			Mult_A <= dT;
//			Mult_B <= dT;	
			stp_calib <= stp_calib + 5'd1;
		end
		else 
			stp_calib <= 5'd12;
		end
		5'd9:begin
			Mult_A <= TEMP_sub20;
			Mult_B <= TEMP_sub20;			
//			T2 <= $signed({{31{Mult_Val[60]}},Mult_Val[60:31]});			//dT^2/2^31
			stp_calib <= stp_calib + 5'd1;
		end
		5'd10:begin
			Mult_A <= 3'd5;
			Mult_B <= Mult_Val;			
			stp_calib <= stp_calib + 5'd1;
		end
		5'd11:begin
			OFF  <= OFF  - $signed({{1{Mult_Val[60]}},Mult_Val[60:1]});
			SENS <= SENS - $signed({{2{Mult_Val[60]}},Mult_Val[60:2]});
			stp_calib <= stp_calib + 5'd1;
		end
		5'd12:begin
			Mult_A <= D1;
			Mult_B <= SENS;			
			stp_calib <= stp_calib + 5'd1;
		end
		5'd13:begin
			Ptmp <= $signed({{21{Mult_Val[60]}},Mult_Val[60:21]})-OFF;
			stp_calib <= stp_calib + 5'd1;
		end
		5'd14:begin
			P <= {{15{Ptmp[60]}},Ptmp[60:15]};
			rCalib_Rdy <= 1'b1;
			stp_calib <= 5'd0;
		end
		default:begin
			i <= 0;
			stp_calib <= 2'd0;
		end
		endcase
	end




assign Calib_Pressure = P;
assign Rx_RD_Req_sig = rRx_RD_Req_sig;
assign Calib_Rdy = rCalib_Rdy;
endmodule


/**********************END OF FILE COPYRIGHT @2016************************/	
