function Mapped_Value= Arduino_Map(x,in_min,in_max,out_min,out_max)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
Mapped_Value=(x - in_min)*(out_max - out_min)/(in_max - in_min)+out_min;
end

