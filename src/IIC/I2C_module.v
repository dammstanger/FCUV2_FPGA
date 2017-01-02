/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：I2C_module
工程描述：I2C 通信模块
作	 者：dammstanger
日	 期：20160815
*************************************************************************/	
module I2C_module (
input CLK,
input RSTn,

output SCL,
inout  SDA,
output Rx_RDY,
output ACK,
input WR,
input RD,
input [6:0]DIV_ADDR,
input [7:0]ADDR,
input [4:0]NUM,
input [7:0]DATA_IN,
output [7:0]DATA_OUT
);

reg rACK;
reg rSCL;
reg WF,RF;
reg FF;
reg Read_byte_Rdy;
reg [1:0]head_buf;
reg [1:0]stop_buf;
reg [7:0]sh8out_buf;
reg [8:0]sh8out_sta;
reg [10:0]sh8in_sta;
reg [2:0]head_sta;
reg [2:0]stop_sta;
reg [10:0]main_sta;
reg [7:0]data_from_rm;
reg link_sda;
reg link_head;
reg link_write;
reg link_stop;
reg [4:0]byte_cnt;

wire sda1,sda2,sda3,sda4;

//***************串行数据在开关的控制下有次序的输出或输入*******************
assign sda1 = (link_head)? head_buf[1]:1'b0;
assign sda2 = (link_write)? sh8out_buf[7]:1'b0;
assign sda3 = (link_stop)? stop_buf[1]:1'b0;
assign sda4 = (sda1|sda2|sda3);

assign SDA  = (link_sda)?sda4:1'bz;
assign DATA_OUT = data_from_rm;
assign Rx_RDY = Read_byte_Rdy;
//
parameter OPT_READ		= 1'b1;
parameter OPT_WRITE		= 1'b0;
//**********************主状态定义*****************************
parameter Idle				= 11'b00000000001, 
					Ready				= 11'b00000000010, 
					Write_start	= 11'b00000000100, 
					Ctrl_write	= 11'b00000001000, 
					Addr_write	= 11'b00000010000, 
					Data_write	= 11'b00000100000, 
					Read_start	= 11'b00001000000, 
					Ctrl_read 	= 11'b00010000000, 
					Data_read 	= 11'b00100000000, 
					Stop				= 11'b01000000000, 
					Ackn				= 11'b10000000000;
					
//*************并行数据串行输出状态********************
parameter sh8out_bit7		= 9'b000000001, 
					sh8out_bit6		= 9'b000000010, 
					sh8out_bit5		= 9'b000000100, 
					sh8out_bit4		= 9'b000001000, 
					sh8out_bit3		= 9'b000010000, 
					sh8out_bit2		= 9'b000100000, 
					sh8out_bit1		= 9'b001000000, 
					sh8out_bit0		= 9'b010000000, 
					sh8out_end		= 9'b100000000;


//*************串行数据并行输入状态********************
parameter sh8in_begin		= 11'b00000000001, 
					sh8in_bit7		= 11'b00000000010, 
					sh8in_bit6		= 11'b00000000100, 
					sh8in_bit5		= 11'b00000001000, 
					sh8in_bit4		= 11'b00000010000, 
					sh8in_bit3		= 11'b00000100000, 
					sh8in_bit2		= 11'b00001000000, 
					sh8in_bit1		= 11'b00010000000, 
					sh8in_bit0		= 11'b00100000000, 
					sh8in_ack			= 11'b01000000000,
					sh8in_end			= 11'b10000000000;

//*************启动状态********************
parameter head_begin		= 3'b001,
					head_bit			= 3'b010,
					head_end			= 3'b100;

//*************停止状态********************
parameter stop_begin		= 3'b001,
					stop_bit			= 3'b010,
					stop_end			= 3'b100;

parameter YES 					= 1'b1,
					NO						= 1'b0;



//*******************主状态机***************************
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		link_write 	<= NO;
		link_head 	<= NO;
		link_stop 	<= NO;
		link_sda	 	<= NO;
		data_from_rm<= 1'b0;
		sh8out_buf	<= 1'b0;
		head_buf		<= 2'b10;
		stop_buf		<= 2'b01;	
		rACK <= 0;
		RF  <= 0;
		WF  <= 0;
		FF  <= 0;
		Read_byte_Rdy <= 1'b0;
		byte_cnt <= 1'b0;
		main_sta <= Idle;
	end
	else begin
		case(main_sta)
		Idle:begin//---------------------------------------------------
			link_write 	<= NO;
			link_head 	<= NO;
			link_stop 	<= NO;
			link_sda	 	<= NO;	
			if(WR)begin
				WF <= 1'b1;
				main_sta <= Ready;
			end
			else if(RD)begin
				RF <= 1'b1;
				main_sta <= Ready;
			end
			else begin
				RF <= 1'b0;
				WF <= 1'b0;
				main_sta <= Idle;				
			end
		end
		Ready:begin//---------------------------------------------------
			link_write 	<= NO;
			link_head 	<= YES;
			link_stop 	<= NO;
			link_sda	 	<= YES;	
			head_buf		<= 2'b10;
			stop_buf		<= 2'b01;
			head_sta		<= head_begin;
			FF					<= 0;
			rACK					<= 0;
			main_sta		<= Write_start;
		end
		Write_start://---------------------------------------------------
			if(FF==0)
				shift_head;
			else begin
				sh8out_buf <= {DIV_ADDR,OPT_WRITE};
				link_write 	<= YES;
				link_head 	<= NO;	
				link_sda		<= YES;
				FF <= 0;
				sh8out_sta  <= sh8out_bit6;
				main_sta		<= Ctrl_write;
			end
		Ctrl_write://---------------------------------------------------
			if(FF==0)
				shift8_out;
			else begin
				sh8out_sta <= sh8out_bit7;
				sh8out_buf <= ADDR;
				FF				 <= 0;
				main_sta	 <= Addr_write;
			end
		Addr_write://---------------------------------------------------
			if(FF==0)
				shift8_out;
			else begin
				FF <= 0;
				if(WF)begin
					sh8out_sta	<= sh8out_bit7;
					sh8out_buf			<= DATA_IN;
					main_sta		<= Data_write;
				end
				else if(RF)begin
					head_sta		<= head_begin;
					head_buf		<= 2'b10;
					main_sta		<= Read_start;
				end
			end
		Data_write://---------------------------------------------------
			if(FF==0)
				shift8_out;
			else begin
				FF					<= 0;
				link_write	<= NO;
				stop_sta		<= stop_begin;
				main_sta		<= Stop;
			end
		Read_start://---------------------------------------------------
			if(FF==0)
				shift_head;
			else begin
				sh8out_buf <= {DIV_ADDR,OPT_READ};
				link_write 	<= YES;
				link_head 	<= NO;	
				link_sda		<= YES;
				FF <= 0;
				sh8out_sta  <= sh8out_bit6;
				main_sta		<= Ctrl_read;
			end
		Ctrl_read://---------------------------------------------------
			if(FF==0)
				shift8_out;
			else begin
				FF					<= 0;
				link_sda		<= NO;
				link_write	<= NO;
				sh8in_sta		<= sh8in_begin;
				main_sta		<= Data_read;
			end
		Data_read://---------------------------------------------------
			if(FF==0)
				shift8_in;
			else begin
				FF						<= 0;
				Read_byte_Rdy	<= 1'b0;
				link_write  	<= NO;			//禁止之后输出自动为0
				link_sda  		<= NO;
				if(byte_cnt==(NUM-1))begin
					byte_cnt		<= 1'b0;
					link_stop		<= YES;
					link_sda  	<= YES;
					stop_sta		<= stop_bit;
					main_sta		<= Stop;
				end
				else begin
					byte_cnt		<= byte_cnt +1'b1;
					sh8in_sta		<= sh8in_bit7;
					main_sta		<= Data_read;
				end
			end
		Stop://---------------------------------------------------
			if(FF==0)
				shift_stop;
			else begin
				FF					<= 0;
				rACK				<= 1;
				main_sta		<= Ackn;
			end
		Ackn:begin//---------------------------------------------------
			rACK 		<= 0;
			WF			<= 0;
			RF 			<= 0;
			main_sta<= Idle;
		end
		default:main_sta <= Idle;
		endcase
	end
	
//*****************任务：串行数据转换成并行数据 读时序*****************************	
	
task shift8_in;
begin
	casex(sh8in_sta)
	sh8in_begin:
		sh8in_sta <= sh8in_bit7;
	sh8in_bit7:
		if(SCL)begin
			data_from_rm[7]	<= SDA;
			sh8in_sta				<= sh8in_bit6;
		end
		else
			sh8in_sta				<= sh8in_bit7;
	sh8in_bit6:
		if(SCL)begin
			data_from_rm[6]	<= SDA;
			sh8in_sta				<= sh8in_bit5;
		end
		else
			sh8in_sta				<= sh8in_bit6;
	sh8in_bit5:
		if(SCL)begin
			data_from_rm[5]	<= SDA;
			sh8in_sta				<= sh8in_bit4;
		end
		else
			sh8in_sta				<= sh8in_bit5;
	sh8in_bit4:
		if(SCL)begin
			data_from_rm[4]	<= SDA;
			sh8in_sta				<= sh8in_bit3;
		end
		else
			sh8in_sta				<= sh8in_bit4;
	sh8in_bit3:
		if(SCL)begin
			data_from_rm[3]	<= SDA;
			sh8in_sta				<= sh8in_bit2;
		end
		else
			sh8in_sta				<= sh8in_bit3;
	sh8in_bit2:
		if(SCL)begin
			data_from_rm[2]	<= SDA;
			sh8in_sta				<= sh8in_bit1;
		end
		else
			sh8in_sta				<= sh8in_bit2;
	sh8in_bit1:
		if(SCL)begin
			data_from_rm[1]	<= SDA;
			sh8in_sta				<= sh8in_bit0;
		end
		else
			sh8in_sta				<= sh8in_bit1;
	sh8in_bit0:
		if(SCL)begin
			data_from_rm[0]	<= SDA;
			sh8in_sta				<= sh8in_ack;
		end
		else
			sh8in_sta				<= sh8in_bit0;
	sh8in_ack:
		if(!SCL)begin
			link_sda				<= YES;
			link_write  		<= YES;
			if(byte_cnt==(NUM-1))
				sh8out_buf[7]	<= 1'b1;
			else
				sh8out_buf[7]	<= 1'b0;
			sh8in_sta				<= sh8in_end;	
		end
		else
			sh8in_sta				<= sh8in_ack;
	sh8in_end:
		if(SCL)begin
			FF							<= 1;
			Read_byte_Rdy		<= 1'b1;
			sh8in_sta				<= sh8in_bit7;
		end
		else
			sh8in_sta				<= sh8in_end;
			
	default:begin
		sh8in_sta					<= sh8in_bit7;
	end
	endcase
end
endtask
	
//*****************任务：并行数据转换成串行数据  读时序*****************************	
task shift8_out;
begin
	casex(sh8out_sta)
		sh8out_bit7:
			if(!SCL)begin
				link_sda			<= YES;
				link_write		<= YES;
				sh8out_sta		<= sh8out_bit6;
			end
			else
				sh8out_sta		<= sh8out_bit7;
		sh8out_bit6:
			if(!SCL)begin
				link_sda			<= YES;
				link_write		<= YES;
				sh8out_sta		<= sh8out_bit5;
				sh8out_buf		<= sh8out_buf<<1;
			end
			else
				sh8out_sta		<= sh8out_bit6;
		sh8out_bit5:
			if(!SCL)begin
				sh8out_sta		<= sh8out_bit4;
				sh8out_buf		<= sh8out_buf<<1;
			end
			else
				sh8out_sta		<= sh8out_bit5;
		sh8out_bit4:
			if(!SCL)begin
				sh8out_sta		<= sh8out_bit3;
				sh8out_buf		<= sh8out_buf<<1;
			end
			else
				sh8out_sta		<= sh8out_bit4;
		sh8out_bit3:
			if(!SCL)begin
				sh8out_sta		<= sh8out_bit2;
				sh8out_buf		<= sh8out_buf<<1;
			end
			else
				sh8out_sta		<= sh8out_bit3;
		sh8out_bit2:
			if(!SCL)begin
				sh8out_sta		<= sh8out_bit1;
				sh8out_buf		<= sh8out_buf<<1;
			end
			else
				sh8out_sta		<= sh8out_bit2;
		sh8out_bit1:
			if(!SCL)begin
				sh8out_sta		<= sh8out_bit0;
				sh8out_buf		<= sh8out_buf<<1;
			end
			else
				sh8out_sta		<= sh8out_bit1;
		sh8out_bit0:
			if(!SCL)begin
				sh8out_sta		<= sh8out_end;
				sh8out_buf		<= sh8out_buf<<1;
			end
			else
				sh8out_sta		<= sh8out_bit0;
		sh8out_end:
			if(!SCL)begin
				FF						<= 1;
				link_sda			<= NO;
				link_write		<= NO;
				end
			else
				sh8out_sta		<= sh8out_end;
	endcase
	end
endtask

//*********************任务：输出启动信号******************************
task shift_head;
begin
	casex(head_sta)
	head_begin:
		if(!SCL)begin
			link_write		<= NO;
			link_sda			<= YES;
			link_head			<= YES;
			head_sta			<= head_bit;
		end
		else
			head_sta			<= head_begin;
	head_bit:
		if(SCL)begin
			FF						<= 1;
			head_buf			<= head_buf<<1;
			head_sta			<= head_end;
		end
		else
			head_sta			<= head_bit;
	head_end:
		if(!SCL)begin
			link_write		<= YES;
			link_head			<= NO;
			head_sta			<= head_bit;
		end
		else
			head_sta			<= head_end;
	endcase		
end
endtask

//*********************任务：输出停止信号******************************
task shift_stop;
begin
	casex(stop_sta)
	stop_begin:
		if(!SCL)begin
			link_write		<= NO;
			link_sda			<= YES;
			link_stop			<= YES;
			stop_sta			<= stop_bit;
		end
		else
			stop_sta			<= stop_begin;
	stop_bit:
		if(SCL)begin
			stop_buf			<= stop_buf<<1;
			stop_sta			<= stop_end;
		end
		else
			stop_sta			<= stop_bit;
	stop_end:
		if(!SCL)begin
			FF						<= 1;
			link_sda			<= NO;
			link_stop			<= NO;
			stop_sta			<= stop_bit;
		end
		else
			stop_sta			<= stop_end;
	endcase
end
endtask

always@(negedge CLK or negedge RSTn )
	if(!RSTn)
		rSCL <= 1'b0;
	else
		rSCL <= ~rSCL;

		
assign ACK = rACK;
assign SCL = rSCL;




endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
