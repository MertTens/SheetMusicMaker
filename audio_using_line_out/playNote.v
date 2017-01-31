
module playNote (
	// Inputs
	CLOCK_50,
	KEY,
	LEDR,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK,
	SW,
			VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
);


wire [7:0]x;
wire [6:0]y;
wire [2:0]colour;
wire plot;




	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */ 
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";














/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input		[9:0]	SW;
output 	[9:0] LEDR;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;



	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers

reg [18:0] delay_cnt;
reg [18:0] delay;
reg snd;




// State Machine Registers

	wire reset;
	wire userPlayBack;
	wire go;
	wire clk;
	wire wren;
	reg [7:0]playNote;
	
	wire [7:0]ramOutput;
	reg [7:0]noteFromRam;
	reg [7:0]durationFromRam;
	
	reg ld_RAM_note, ld_RAM_dur, ld_finalCount, resetRam, resetCount, startCount, resetRamSlot, incrimentRamSlot, ld_note, ld_VGA, ld_wren, resetClearRam, startClearRamCount;
	reg ld_noteFromRam;
	reg ld_durationFromRam;
	reg incrimentDone;
	reg [24:0]clkCounter;
	reg [3:0]durationCounter;
	reg [5:0]ramSlot;
	reg [3:0]finalCount;
	reg [7:0]note;
	reg [7:0]ramData;
	reg [4:0]clearRamCount;
	reg newNote;
	reg playing;
	
	reg [7:0]ramOutputNote;
	
	//this reg is for user playback count
	reg [3:0] userPlayCount;
	reg startUserPlayCount;
	reg resetUserPlayCount;
	reg [3:0]countTo;
	reg ld_countTo;
	reg ld_playNote;
	
	assign reset = ~KEY[0];
	assign userPlayBack = ~KEY[1];
	assign go = ~KEY[3];
	assign clk = CLOCK_50; 
	assign wren = ld_wren;
	//assign playNote = playing ? ramOutputNote : SW[7:0];
	

	
	
	
	
/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					DONT TOUCH THE FUCKING AUDIO CONTROLS								  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/
	

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end else delay_cnt <= delay_cnt + 1;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

//assign delay = {SW[3:0], 15'd3000};


always @(*) begin
	case(playNote)
	//figure out the note values later
		8'b00000001: delay = 19'd97304;
		8'b00000010: delay = 19'd88304;
		8'b00000100: delay = 19'd79304;
		8'b00001000: delay = 19'd78554;
		8'b00010000: delay = 19'd71054;
		8'b00100000: delay = 19'd63554;
		8'b01000000: delay = 19'd56054;
		8'b10000000: delay = 19'd202477/2;
	endcase
end


wire [31:0] sound = (playNote == 0) ? 0 : snd ? 32'd10000000 : -32'd10000000;


assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= left_channel_audio_in+sound;
assign right_channel_audio_out	= right_channel_audio_in+sound;
assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[2]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.I2C_SCLK					(FPGA_I2C_SCLK),
	.I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[2])
);

/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					DONT TOUCH THE FUCKING AUDIO CONTROLS								  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/


/*
	 * 
	 * Create the state table and the logic for switching states here
	 *
	 */
	reg  [3:0] current_state, next_state;
	
	localparam	RESET					= 4'd0, 
					NOTE_PLAY			= 4'd1,
					DURATION_DETECT	= 4'd2,
					STORE					= 4'd3,
					WAIT					= 4'd4,
					CLEAR_RAM			= 4'd5,
					CLEAR_RAM_SLOT		= 4'd6,
					NOTE_READ			= 4'd7,
					INCRIMENT_NOTE		= 4'd8,
					LOAD_COUNT			= 4'd9,
					COUNT					= 4'd10,
					INCRIMENT_DURATION= 4'd11;
					
	always @(*)
	begin: state_table
			case(current_state)
				RESET:	begin
							if(reset == 1'b1)
								next_state = RESET;
							else	begin
									if(go == 1'b1)
										next_state <= WAIT;
									else
										next_state <= WAIT;
									end
							end
				NOTE_PLAY:	begin
								if(go == 1'b1)
									next_state <= DURATION_DETECT;
								else
									next_state <= DURATION_DETECT;
								end
				DURATION_DETECT: next_state = (go) ? DURATION_DETECT : STORE;
				STORE: next_state <= WAIT;
				WAIT: begin
						if(reset == 1'b1)
								next_state = CLEAR_RAM;
							else	begin
									if (userPlayBack)
										next_state = CLEAR_RAM_SLOT;
									else if(go == 1'b1)
										next_state <= NOTE_PLAY;
									else
										next_state <= WAIT;
									end
						end
				CLEAR_RAM: begin
								if(clearRamCount == 5'd63)
									next_state <= RESET;
								else
									next_state <= CLEAR_RAM;
								end
				
				CLEAR_RAM_SLOT: next_state = NOTE_READ;
				
				NOTE_READ: next_state = INCRIMENT_NOTE;
				
				INCRIMENT_NOTE: next_state = LOAD_COUNT;
				
				LOAD_COUNT: next_state = COUNT;
				
				COUNT:	begin
							if(userPlayCount == countTo)
								next_state = WAIT;
							else
								next_state = COUNT;
							end
				
			default: next_state = RESET;
		endcase
	end
	
	
	//create the condition for a new note happening... this will signify whether or not to move onto the store state
	/*always @(*)
	begin
		if(note != SW[7:0] && SW[7:0] != 8'b00000000)
			newNote = 1'b1;
		else
			newNote = 1'b0;
	end
	
	/*
	 *
	 * Logic for datapath control signals
	 *
	 */
	
	always @(*)
	begin: enable_signals
		// Make certain signals 0 by default
		ld_RAM_note = 1'b0;
		ld_RAM_dur = 1'b0;
		ld_finalCount = 1'b0;
		incrimentRamSlot = 1'b0;
		resetRam = 1'b0;
		resetRamSlot = 1'b0;
		resetCount = 1'b0;
		startCount = 1'b0;
		ld_note = 1'b0;
		ld_wren = 1'b0;
		resetClearRam = 1'b0;
		startClearRamCount = 1'b0;
		ld_VGA = 1'b0;
		ld_noteFromRam = 1'b0;
		ld_durationFromRam = 1'b0;
		playing = 1'b0;
		resetUserPlayCount = 1'b0;
		ld_countTo = 1'b0;
		ld_playNote = 1'b0;

		
		case(current_state)
			RESET:				begin
									resetRam = 1'b1;
									resetCount = 1'b1;
									resetClearRam = 1'b1;
									resetRamSlot = 1'b1;
									resetUserPlayCount = 1'b1;
									end
			
			NOTE_PLAY:			begin
									ld_note <= 1'b1;
									ld_wren <= 1'b1;
									ld_RAM_note = 1'b1;
									end
			
			DURATION_DETECT:	begin
									startCount = 1'b1;
									//incrimentRamSlot = 1'b1;
									ld_wren = 1'b1;
									end
			
			STORE:				begin
									ld_wren = 1'b1;
									ld_RAM_dur = 1'b1;
									ld_finalCount = 1'b1;
									incrimentRamSlot = 1'b1;
									end
			
			WAIT:					begin
									incrimentRamSlot = 1'b1;
									resetCount = 1'b1;
									ld_VGA = 1'b1;
									resetUserPlayCount = 1'b1;
									end
			
			CLEAR_RAM:			begin
									startClearRamCount = 1'b1;
									ld_wren = 1'b1;
									end
			
			CLEAR_RAM_SLOT:	resetRamSlot = 1'b1;
			
			NOTE_READ:			begin
									ld_wren = 1'b0;
									ld_noteFromRam = 1'b1;
									playing = 1'b1;
									resetUserPlayCount = 1'b1;
									resetCount = 1'b1;
									end
			
			INCRIMENT_NOTE:	begin
									ld_wren = 1'b0;
									incrimentRamSlot = 1'b1;
									end
			
			LOAD_COUNT:			begin
									ld_countTo = 1'b1;
									end
									
			COUNT:				begin
									startUserPlayCount = 1'b1;
									startCount = 1'b1;
									ld_playNote = 1'b1;
									end
			
		endcase
	end
			
	always @(posedge clk)
	begin: state_FFs
		if(!reset)
			current_state <= next_state;
		else
			current_state <= RESET;
	end
	
	
	/*
	 *
	 * Datapath...????????? :)
	 *
	 */
	 
	 //start the counter that the thing
	 always @(posedge clk)
	 begin
		if(clkCounter == 25'd25000000 || resetCount == 1'b1)
			clkCounter = 25'd0;
		else if(startCount == 1'b1)
			clkCounter = clkCounter + 1;
	 end
	 
	 //do the duration counter that counts every quarter of a second
	 always @(posedge clk)
	 begin
		if(resetCount == 1'b1)
			durationCounter = 4'b0000;
		else 
			begin
			if(durationCounter == 4'b1000)
				durationCounter = 4'b1000;
			
			else if(clkCounter == 25'd25000000)
				durationCounter = durationCounter + 1;
			end
	end
	
	// Reset all values in RAM by systematically going through all 64 values... 
	always @(posedge clk)
	begin
		if(clearRamCount == 5'd63 || resetClearRam)
			clearRamCount = 5'd0;
		if(startClearRamCount)
			clearRamCount = clearRamCount + 1'b1;
	end
			
	//the playback counter
	always @(posedge clk)
	begin
		if(resetUserPlayCount)
			userPlayCount = 4'b0000;
		else
			begin
			
			if(userPlayCount == countTo)
				userPlayCount = userPlayCount;
			else if(clkCounter == 25'd25000000)
				userPlayCount = userPlayCount + 1'b1;
			end
	end	
	
	always @(posedge clk)
	begin
	if(reset)
		begin
		finalCount = 4'b0000;
		note = 4'b0000;

		end
	
	
	
	
	
	else	begin
			if(ld_finalCount) begin
				finalCount <= durationCounter;
				incrimentDone = 1'b1;
				end
			
			if(ld_note) begin
				note = SW[7:0];
				incrimentDone = 1'b1;
				end
				
			if(ld_RAM_note)
				ramData = {note};
			
			if(incrimentRamSlot && incrimentDone) begin
				ramSlot = ramSlot + 1'b1;
				incrimentDone = 1'b0;
				end
				
			if(resetRamSlot)
				ramSlot = 6'b000000;
			
			if(ld_RAM_dur)
				ramData = {4'b0000, finalCount};
			
			if(startClearRamCount) begin
				ramData = 8'd0;
				ramSlot = clearRamCount;
				end
			
			if(ld_noteFromRam)
				playNote = ramOutput;
				
			if(ld_VGA)
				playNote = SW[7:0];
				
			if(ld_countTo)
				countTo = ramOutput[3:0];
			
			if(ld_playNote)
				playNote = ramOutput;
				
			
			end
	end
	
	
	ram64x8 r0(
		.data(ramData),
		.wren(wren),
		.address(ramSlot),
		.clock(clk),
		.q(ramOutput)
		);
	
	wire [4:0]AHH;
	wire [3:0]pls;
	assign LEDR[3:0] = countTo;
	
	assign LEDR[9:6] = userPlayCount;


//assign LEDR[5:0] = ramOutput;



	sheetMusic s1(
		.CLOCK_50(CLOCK_50),
		.KEY(KEY),
		.SW(SW),
		.duration(finalCount),
		.x(x),
		.y(y),
		.colour(colour),
		.plot(plot),
		.current_state(AHH),
		.temp(pls)
		);
endmodule



module sheetMusic(CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,
		SW,
		duration,
		x,
		y,
		colour,
		plot,
		current_state,
		temp
		);
		
		input			CLOCK_50;				//	50 MHz
	// Declare your inputs and outputs here
	input			[3:0]KEY;
	input			[9:0]SW;
	input			[3:0]duration;
	output reg [7:0]x;
	output reg [6:0]y;
	output reg [2:0] colour;
	//the plot reg
	output reg plot;

wire reset;
	assign reset = ~KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire go;
	wire writeEn;
	//wire duration;
	//assign duration = SW[3:0];
	
	//make a wire that will get the duration at the appropriate time
	output [3:0]temp = durationCounter;
	reg [3:0]loadDuration;
	wire [8:0]note;
	assign note = SW[7:0];
	reg [5:0]noteDisplace;
	
	reg [7:0]xBGCounter = 8'd0;
	reg [6:0]yBGCounter = 8'd0;
	reg [15:0]bgCounter = 16'd0;
	
	
	reg [3:0]xEighthNoteCounter = 4'd0;
	reg [3:0]yEighthNoteCounter = 4'd0;
	reg [7:0]eighthNoteCounter = 8'd0;
	
	//the current note position counters
	reg [7:0]tempx;
	reg [6:0]tempy;
	
	
	
	output reg [4:0] current_state;
	reg [4:0]	next_state;
	
	reg reset_bgCount, start_bgCount;
	
	reg reset_eighth_noteCount, start_eighth_noteCount;
	
	
	
	wire [2:0]bgColour;
	wire [2:0]eighthNoteColour;
	wire [2:0]quarterNoteColour;
	wire [2:0]dottedQuarterNoteColour;
	wire [2:0]halfNoteColour;
	wire [2:0]halfNoteSlurColour;
	
	
	assign clk = CLOCK_50;
	assign go = ~KEY[3];
	
	
	/*
	 *COUNTER THINGS
	 */
	reg [24:0]clkCounter;
	reg [3:0]durationCounter;
	reg startCount, resetCount;

	/*
	 * 
	 * Create the state table and the logic for switching states here
	 *
	 */
	
	
	localparam	RESET								= 5'd0,
					PRINT_BG							= 5'd1,
					PRINT_BG_WAIT					= 5'd2,
					WAIT								= 5'd3,
					PRINT_EIGHTH					= 5'd4,
					PRINT_EIGHTH_WAIT				= 5'd5,
					INCRIMENT_X						= 5'd6,
					PRINT_QUARTER					= 5'd7,
					PRINT_QUARTER_WAIT			= 5'd8,
					PRINT_DOTTED_QUARTER			= 5'd9,
					PRINT_DOTTED_QUARTER_WAIT	= 5'd10,
					PRINT_HALF						= 5'd11,
					PRINT_HALF_WAIT				= 5'd12,
					PRINT_HALF_SLUR				= 5'd13,
					PRINT_HALF_SLUR_WAIT			= 5'd14,
					LOAD_DURATION					= 5'd15,
					DETECT_DURATION				= 5'd16;
	
	always @(*)
	begin: state_table
			case(current_state)
				RESET:	begin
							plot = 1'b1;
							if(reset == 1'b1)	
								next_state = RESET;
							else begin
								if(go)	
									next_state = PRINT_BG;
								else next_state = RESET;
							end
							end
				
				PRINT_BG:	begin
								x <= xBGCounter;
								y <= yBGCounter;
								colour <= bgColour;
								if(bgCounter == 16'd191999)
									next_state = PRINT_BG_WAIT;
								else
									next_state = PRINT_BG;
								end
				
				PRINT_BG_WAIT: next_state = ~go ? WAIT : PRINT_BG_WAIT;
				
				WAIT: begin
						plot = 1'b1;
						if(loadDuration == 4'b0001&& ~go)
							next_state = PRINT_EIGHTH;
						else if(loadDuration == 4'b0010 && ~go)
							next_state = PRINT_QUARTER;
						else if(loadDuration == 4'b0011 && ~go)
							next_state = PRINT_DOTTED_QUARTER;
						else if(loadDuration == 4'b0100 && ~go)
							next_state = PRINT_HALF;
						else if(loadDuration != 4'b0000 && ~go)
							next_state = PRINT_HALF_SLUR;
						else if(go)
							next_state = DETECT_DURATION;
						end
				
				PRINT_EIGHTH:	begin
									if(eighthNoteColour == 3'b111) begin
										plot = 1'b0;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= eighthNoteColour;
										end
									if(eighthNoteColour == 3'b000) begin
										plot = 1'b1;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= eighthNoteColour;
										end
									if(eighthNoteCounter == 8'd149)
										next_state = PRINT_EIGHTH_WAIT;
									else
										next_state = PRINT_EIGHTH;
									end
				PRINT_EIGHTH_WAIT: next_state = ~go ? PRINT_EIGHTH_WAIT : INCRIMENT_X;
				INCRIMENT_X:	begin
									
									next_state = WAIT;
									end
				PRINT_QUARTER:	begin
									if(quarterNoteColour == 3'b111) begin
										plot = 1'b0;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= quarterNoteColour;
										end
									if(quarterNoteColour == 3'b000) begin
										plot = 1'b1;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= quarterNoteColour;
										end
									if(eighthNoteCounter == 8'd149)
										next_state = PRINT_QUARTER_WAIT;
									else
										next_state = PRINT_QUARTER;
									end
				PRINT_QUARTER_WAIT: next_state = ~go ? PRINT_QUARTER_WAIT : INCRIMENT_X;
				
				PRINT_DOTTED_QUARTER:	begin
												if(dottedQuarterNoteColour == 3'b111) begin
										plot = 1'b0;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= dottedQuarterNoteColour;
										end
									if(dottedQuarterNoteColour == 3'b000) begin
										plot = 1'b1;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= dottedQuarterNoteColour;
										end
									if(eighthNoteCounter == 8'd149)
										next_state = PRINT_DOTTED_QUARTER_WAIT;
									else
										next_state = PRINT_DOTTED_QUARTER;
												end
												
				PRINT_DOTTED_QUARTER_WAIT: next_state = ~go ? PRINT_DOTTED_QUARTER_WAIT : INCRIMENT_X;
				
				PRINT_HALF:	begin
												if(halfNoteColour == 3'b111) begin
										plot = 1'b0;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= halfNoteColour;
										end
									if(halfNoteColour == 3'b000) begin
										plot = 1'b1;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= halfNoteColour;
										end
									if(eighthNoteCounter == 8'd149)
										next_state = PRINT_HALF_WAIT;
									else
										next_state = PRINT_HALF;
												end
				PRINT_HALF_WAIT: next_state = ~go ? PRINT_HALF_WAIT : INCRIMENT_X;
				
				PRINT_HALF_SLUR:	begin
												if(halfNoteSlurColour == 3'b111) begin
										plot = 1'b0;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= halfNoteSlurColour;
										end
									if(halfNoteSlurColour == 3'b000) begin
										plot = 1'b1;
										x <= xEighthNoteCounter + tempx;
										y <= yEighthNoteCounter + tempy - noteDisplace;
										colour <= halfNoteSlurColour;
										end
									if(eighthNoteCounter == 8'd149)
										next_state = PRINT_HALF_SLUR_WAIT;
									else
										next_state = PRINT_HALF_SLUR;
												end
				PRINT_HALF_SLUR_WAIT: next_state = ~go ? PRINT_HALF_SLUR_WAIT : INCRIMENT_X;
				
				DETECT_DURATION:	next_state = go ? DETECT_DURATION : LOAD_DURATION;
				
				LOAD_DURATION:		next_state = WAIT;
				
			default: next_state = RESET;
		endcase
	end
	
	
	always @(posedge clk)
	begin
		if(reset)
			current_state <= RESET;
		else
			current_state <= next_state;
	end
	
	
	/*
	 *
	 * deciding the displacement of a note
	 *
	 */
	 
	 always @(posedge clk) begin
		case(note)
			8'b00000001: noteDisplace = 6'd0;
			8'b00000010: noteDisplace = 6'd2;
			8'b00000100: noteDisplace = 6'd4;
			8'b00001000: noteDisplace = 6'd6;
			8'b00010000: noteDisplace = 6'd9;
			8'b00100000: noteDisplace = 6'd11;
			8'b01000000: noteDisplace = 6'd14;
			8'b10000000: noteDisplace = 6'd16;
			8'b00000000: noteDisplace = 6'd19;
			default: noteDisplace = 6'd0;
		endcase
	end
			
		
	
	
	/*
	 *
	 * Logic for datapath control signals
	 *
	 */
	 
	 always @(posedge clk)
	begin: enable_signals
		// Make certain signals 0 by default
		reset_bgCount = 1'b0;
		start_bgCount = 1'b0;
		reset_eighth_noteCount = 1'b0;
		start_eighth_noteCount = 1'b0;
		resetCount = 1'b0;
		startCount = 1'b0;
		
		case(current_state)
			
			RESET:	begin
						reset_bgCount = 1'b1;
						reset_eighth_noteCount = 1'b1;
						tempx = 8'd17;
						tempy = 7'd31;
						end
			
			PRINT_BG:	begin
							start_bgCount = 1'b1;
							end
							
			PRINT_EIGHTH:	begin
								start_eighth_noteCount = 1'b1;
								//start_bgCount = 1'b1;
								end
			WAIT:	begin
					reset_bgCount = 1'b1;
					reset_eighth_noteCount = 1'b1;
					resetCount = 1'b1;
					end
			INCRIMENT_X:	begin
								if(tempx == 7'd122) begin
									tempx = 8'd17;
									tempy = 7'd91;
									end
								else
									tempx = tempx+15;
								end
			PRINT_QUARTER:	begin
								start_eighth_noteCount = 1'b1;
								loadDuration = 4'b0000;
								end
			PRINT_DOTTED_QUARTER:	begin
								start_eighth_noteCount = 1'b1;
								loadDuration = 4'b0000;
								end
			PRINT_HALF:	begin
								start_eighth_noteCount = 1'b1;
								loadDuration = 4'b0000;
								end
			
			PRINT_HALF_SLUR:	begin
								start_eighth_noteCount = 1'b1;
								loadDuration = 4'b0000;
								end
			
			DETECT_DURATION: startCount = 1'b1;
			
			LOAD_DURATION: begin
								loadDuration = durationCounter;
								
								end
					
		endcase
	end
	

	
	
/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					BACKGROUND COUNTERS														  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/

	always @(posedge CLOCK_50) begin
		if(reset_bgCount)
			xBGCounter = 8'd0;
		else begin
		if(xBGCounter == 8'd159)
			xBGCounter = 8'd0;
		else if(start_bgCount)
			xBGCounter = xBGCounter + 1'b1;
		end
	end
	
	always @(posedge CLOCK_50) begin
		if(reset_bgCount)
			yBGCounter = 7'd0;
		else begin
		if(yBGCounter == 7'd119)
			yBGCounter = yBGCounter;
		else if(xBGCounter == 8'd159 && start_bgCount)
			yBGCounter = yBGCounter + 1'b1;
		end
	end
	
	always @(posedge CLOCK_50) begin
		if(reset_bgCount)
			bgCounter = 16'd0;
		else begin
		if(bgCounter == 16'd191999)
			bgCounter = bgCounter;
		else if(start_bgCount)
			bgCounter = bgCounter + 1'b1;
			end
	end
/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					BACKGROUND COUNTERS														  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/
 
 
 
 
 
 
 
/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					     NOTE COUNTERS														  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/
 
	always @(posedge CLOCK_50) begin
		if(reset_eighth_noteCount)
			xEighthNoteCounter = 4'd0;
		else begin
		if(xEighthNoteCounter == 4'd14)
			xEighthNoteCounter = 4'd0;
		else if(start_eighth_noteCount)
			xEighthNoteCounter = xEighthNoteCounter + 1'b1;
			end
	end
	
	always @(posedge CLOCK_50) begin
		if(reset_eighth_noteCount)
			yEighthNoteCounter = 4'd0;
		else begin
		if(yEighthNoteCounter == 4'd9)
			yEighthNoteCounter = yEighthNoteCounter;
		else if(xEighthNoteCounter == 4'd14 && start_eighth_noteCount)
			yEighthNoteCounter = yEighthNoteCounter + 1'b1;
		end
	end
	
	always @(posedge CLOCK_50) begin
		if(reset_eighth_noteCount)
			eighthNoteCounter = 8'd0;
		else begin
		if(eighthNoteCounter == 8'd149)
			eighthNoteCounter = eighthNoteCounter;
		else if(start_eighth_noteCount)
			eighthNoteCounter = eighthNoteCounter + 1'b1;
			end
	end
	
/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					     NOTE COUNTERS														  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/
 
 
 
/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					     DURATION COUNTERS													  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/
 
 
 
 always @(posedge clk)
	 begin
		if(clkCounter == 25'd25000000 || resetCount == 1'b1)
			clkCounter = 25'd0;
		else if(startCount == 1'b1)
			clkCounter = clkCounter + 1;
	 end
 
 always @(posedge clk)
	 begin
		if(resetCount == 1'b1)
			durationCounter = 4'b0000;
		else 
			begin
			if(durationCounter == 4'b1000)
				durationCounter = 4'b1000;
			
			else if(clkCounter == 25'd25000000)
				durationCounter = durationCounter + 1;
			end
 end
/*****************************************************************************
 *                         							                             *
 *																									  *
 *																									  * 
 *					     DURATION COUNTERS													  *
 *																									  *
 *																									  *
 *                                                                           *
 *****************************************************************************/
 
	background b1(
		.data(bgCounter),
		.wren(1'b0),
		.address(bgCounter),
		.clock(CLOCK_50),
		.q(bgColour)
		);
	
	eighthnote n1(
		.data(eighthNoteCounter),
		.wren(1'b0),
		.address(eighthNoteCounter),
		.clock(CLOCK_50),
		.q(eighthNoteColour)
		);
	
	quarternote n2(
		.data(eighthNoteCounter),
		.wren(1'b0),
		.address(eighthNoteCounter),
		.clock(CLOCK_50),
		.q(quarterNoteColour)
		);
		
	dottedquarternote n3(
		.data(eighthNoteCounter),
		.wren(1'b0),
		.address(eighthNoteCounter),
		.clock(CLOCK_50),
		.q(dottedQuarterNoteColour)
		);
	
	halfnote n4(
		.data(eighthNoteCounter),
		.wren(1'b0),
		.address(eighthNoteCounter),
		.clock(CLOCK_50),
		.q(halfNoteColour)
		);
	
	halfnoteslur n5(
		.data(eighthNoteCounter),
		.wren(1'b0),
		.address(eighthNoteCounter),
		.clock(CLOCK_50),
		.q(halfNoteSlurColour)
		);
	
	
endmodule
