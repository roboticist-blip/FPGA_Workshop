module SR_Latch(
input S,
input R,
output Q1
output Q1');

always(@posedge clk)
begin
Q1 = (~R&(S|Q1));
Q1` = ~Q1;
end
