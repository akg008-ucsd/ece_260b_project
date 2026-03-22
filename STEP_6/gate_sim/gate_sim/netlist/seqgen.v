module \*SEQGEN* (clear, preset, next_state, clocked_on,
                   clocked_on_also, data_in, enable, Q,
                   synch_clear, synch_preset, synch_toggle, synch_enable);

    input clear, preset, next_state, clocked_on, clocked_on_also;
    input data_in, enable, synch_clear, synch_preset, synch_toggle, synch_enable;
    output reg Q;

    always @(posedge clocked_on or posedge clear or posedge preset) begin
        if (clear)             Q <= 1'b0;
        else if (preset)       Q <= 1'b1;
        else if (synch_clear)  Q <= 1'b0;
        else if (synch_preset) Q <= 1'b1;
        else if (synch_toggle) Q <= ~Q;
        else if (enable)       Q <= data_in;   // ¿ ADD THIS
        else if (synch_enable) Q <= next_state; // ¿ KEEP THIS
    end

endmodule
