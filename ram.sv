module ram #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 32
) (
    input logic clk,
    input logic w_en,
    input logic [1:0] select,
    input logic [ADDR_WIDTH-1:0] w_addr,
    input logic [ADDR_WIDTH-1:0] r_addr,
    input logic [(DATA_WIDTH*4)-1:0] w_data,
    output logic [(DATA_WIDTH*4)-1:0] r_data, 
	 output logic wr_exception_flag, 
	 output logic rd_exception_flag,
	 output logic [7:0] wr_exception_counter,
	 output logic [7:0] rd_exception_counter
);
    logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];
    logic wr_exception_flag_internal,rd_exception_flag_internal;
    logic [7:0] wr_exception_counter_internal,rd_exception_counter_internal;
    always_ff @(posedge clk) begin
        wr_exception_flag_internal = 1'b0; // Initialize internal flag
        if (w_en) begin
            // Write data based on the selected width
            case(select)
                2'b00: mem[w_addr] <= w_data[7:0];
                2'b01: begin
                            if ((w_addr[1:0] % 2) == 0) begin 
                                mem[w_addr] <= w_data[15:8];
                                mem[w_addr+1] <= w_data[7:0];
                            end else begin
                                wr_exception_flag_internal = 1'b1; // Set exception flag
                            end
                        end
                2'b10: begin
                            if ((w_addr[1:0] % 4) == 0) begin
                                mem[w_addr] <= w_data[31:24];
                                mem[w_addr+1] <= w_data[23:16];
                                mem[w_addr+2] <= w_data[15:8];
                                mem[w_addr+3] <= w_data[7:0];
                            end else begin
                                wr_exception_flag_internal = 1'b1; // Set exception flag
                            end
                        end
                default: mem[w_addr] <= w_data[7:0]; // Default to 8-bit write 
            endcase
        end
		  
        // Accumulate exceptions
        if (wr_exception_flag_internal) begin
            wr_exception_counter_internal = wr_exception_counter_internal + 1;
        end
    end
	always @(*) begin : read_logic
    rd_exception_flag_internal = 1'b0; // Initialize internal flag
    
    case (select)
        2'b00: r_data = mem[r_addr];
        2'b01: begin
                    if ((r_addr[1:0] % 2) == 0)
                        r_data = {mem[r_addr], mem[r_addr+1]};
                    else
                        rd_exception_flag_internal = 1'b1; // Set exception flag
                end
        2'b10: begin
                    if ((r_addr[1:0] % 4) == 0)
                        r_data = {mem[r_addr], mem[r_addr+1], mem[r_addr+2], mem[r_addr+3]};
                    else
                        rd_exception_flag_internal = 1'b1; // Set exception flag
                end
        default: r_data = mem[r_addr]; // Default to 8-bit read
    endcase
    
    if (rd_exception_flag_internal) begin
        rd_exception_counter_internal = rd_exception_counter_internal + 1;
    end
	end
 
 
    assign wr_exception_flag = wr_exception_flag_internal;
    assign wr_exception_counter = wr_exception_counter_internal;
	 assign rd_exception_flag = rd_exception_flag_internal;
    assign rd_exception_counter = rd_exception_counter_internal;

	
endmodule
