module controller(input  logic       clk, reset,
                  input  logic [5:0] op, funct,
                  input  logic       zero,alusign,
                  output logic       pcen, memwrite, irwrite, regwrite,
                  output logic       alusrca, iord, memtoreg, regdst,
                  output logic [1:0] alusrcb, pcsrc,
                  output logic [2:0] alucontrol,
output logic [3:0] state,
output logic [14:0] controls);

  logic [1:0] aluop;
  logic       branch, pcwrite;

  // Main Decoder and ALU Decoder subunits.
  maindec md(clk, reset, op,
             pcwrite, memwrite, irwrite, regwrite,
             alusrca, branch, iord, memtoreg, regdst, 
             alusrcb, pcsrc, aluop,state,controls);
  aludec  ad(funct, aluop, alucontrol);
logic NotZero, branchsrc,ZeroOrNot; // a internal wire for the assigning the NOT of zero
  assign NotZero = ~zero; // assigning the wire to NOT of zero
  assign ZeroOrNot = op[0] ? NotZero : zero; // using a MUX to decide which to take, zero or NotZero. Signal line is the LSB of the opcode
  assign beqORble = op[1] ? (alusign | zero) : ZeroOrNot;
  assign branchsrc = branch & beqORble;
  assign pcen = (branchsrc | pcwrite);
endmodule

module datapath(input  logic        clk, reset,
                input  logic        pcen, irwrite, regwrite,
                input  logic        alusrca, iord, memtoreg, regdst,
                input  logic [1:0]  alusrcb, pcsrc, 
                input  logic [2:0]  alucontrol,
                output logic [5:0]  op, funct,
                output logic        zero,
                output logic [31:0] adr, writedata, 
                input  logic [31:0] readdata);

  // Below are the internal signals of the datapath module.

  logic [4:0]  writereg;
  logic [31:0] pcnext, pc;
  logic [31:0] instr, data, srca, srcb;
  logic [31:0] a;
  logic [31:0] aluresult, aluout;
  logic [31:0] signimm;   // the sign-extended immediate
  logic [31:0] signimmsh;	// the sign-extended immediate shifted left by 2
  logic [31:0] wd3, rd1, rd2;

  // op and funct fields to controller
  assign op = instr[31:26];
  assign funct = instr[5:0];
  assign alusign = aluresult [31];


  
  // datapath
  flopenr #(32) pc_reg(clk, reset, pcen, pcnext, pc);
  mux2    #(32) addr_mux(pc, aluout, iord, adr);
  flopenr #(32) instruct_reg(clk, reset, irwrite, readdata, instr);
  flopr   #(32) data_reg(clk, reset, readdata, data);
  mux2    #(5)  reg_dst_mux(instr[20:16], instr[15:11], regdst, writereg);
  mux2    #(32) wd_mux(aluout, data, memtoreg, wd3);
  regfile       rf(clk, regwrite, instr[25:21], instr[20:16], writereg, wd3, rd1, rd2);
  signext       sign_ext1(instr[15:0], signimm);
  sl2           immd_shift2(signimm, signimmsh);
  flopr   #(32) a_rf_reg(clk, reset, rd1, a);
  flopr   #(32) b_rf_reg(clk, reset, rd2, writedata);
  mux2    #(32) alusrca_mux(pc, a, alusrca, srca);
  mux4    #(32) alusrcb_mux(writedata, 32'd4, signimm, signimmsh, alusrcb, srcb);
  alu		alu(srca,srcb, alucontrol, aluresult, zero);
  flopr   #(32) aluout_reg(clk, reset, aluresult, aluout);
  mux3    #(32) pc_in_mux(aluresult, aluout, {pc[31:28], instr[25:0], 2'b00}, pcsrc, pcnext);

endmodule