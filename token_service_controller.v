module token_service_controller #(
    parameter integer DEBOUNCE_COUNT = 500000
)(
    input  wire       CLK_50MHZ,
    input  wire       KEY0,
    input  wire       SW0,
    input  wire       SW1,
    output wire [7:0] LED_DATA
);

    // ------------------------------------------------
    // 1. BUTTON SYNCHRONIZER
    // ------------------------------------------------

    reg key_sync1, key_sync2;

    always @(posedge CLK_50MHZ) begin
        if (SW0) begin
            key_sync1 <= 1'b1;
            key_sync2 <= 1'b1;
        end
        else begin
            key_sync1 <= KEY0;
            key_sync2 <= key_sync1;
        end
    end

    // ------------------------------------------------
    // 2. BUTTON DEBOUNCER
    // KEY0: 1 = released, 0 = pressed
    // ------------------------------------------------

    reg [18:0] debounce_count;
    reg button_state;
    reg next_pulse;

    always @(posedge CLK_50MHZ) begin
        if (SW0) begin
            debounce_count <= 0;
            button_state   <= 1'b1;
            next_pulse     <= 1'b0;
        end
        else begin
            next_pulse <= 1'b0;

            if (key_sync2 != button_state) begin
                if (debounce_count < DEBOUNCE_COUNT - 1) begin
                    debounce_count <= debounce_count + 1'b1;
                end
                else begin
                    debounce_count <= 0;
                    button_state   <= key_sync2;

                    // Generate one pulse when KEY0 is pressed
                    if (button_state == 1'b1 &&
                        key_sync2 == 1'b0)
                        next_pulse <= 1'b1;
                end
            end
            else begin
                debounce_count <= 0;
            end
        end
    end

    // ------------------------------------------------
    // 3. TWO-DIGIT BCD TOKEN COUNTER
    // Range: 00 to 99
    // ------------------------------------------------

    reg [3:0] token_tens;
    reg [3:0] token_ones;

    always @(posedge CLK_50MHZ) begin
        if (SW0) begin
            token_tens <= 4'd0;
            token_ones <= 4'd0;
        end
        else if (SW1 && next_pulse) begin
            if (token_ones == 4'd9) begin
                token_ones <= 4'd0;

                if (token_tens == 4'd9)
                    token_tens <= 4'd0;
                else
                    token_tens <= token_tens + 1'b1;
            end
            else begin
                token_ones <= token_ones + 1'b1;
            end
        end
    end

    // ------------------------------------------------
    // 4. ACTIVE-LOW LED OUTPUT
    // LED_DATA[7:4] = tens
    // LED_DATA[3:0] = ones
    // 0 = LED ON, 1 = LED OFF
    // ------------------------------------------------

    assign LED_DATA = {token_tens, token_ones};

endmodule
