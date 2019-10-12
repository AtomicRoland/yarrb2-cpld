----------------------------------------------------------------------------------
-- Company:        Atomic Development Studio
-- Engineer:       Roland Leurs
-- 
-- Create Date:    21:14 09/10/2019 
-- Design Name: 
-- Module Name:    yarrb - Behavioral 
-- Project Name:   YARRB
-- Target Devices: XC95288XL
-- Tool versions:  
-- Description:    Yet Another Ram/Rom Board for the Acorn Atom revision 2
--
-- Dependencies: 
--
-- Revision: 288v0.1
-- Additional Comments: 
--		This version is for using 128kB ram and 128kB rom and
--		is supporting three memory profiles.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity decoder is
    Port ( 
		DD:		inout	STD_LOGIC_VECTOR (7 downto 0);
      leds:		out	STD_LOGIC_VECTOR (7 downto 0);

		RW: 		in		STD_LOGIC;
		Phi2:		in		STD_LOGIC;
		ClkIn:	in		STD_LOGIC;
		Reset:	in		STD_LOGIC;
		A15:		in		STD_LOGIC;
		A14:		in		STD_LOGIC;
		A13:		in		STD_LOGIC;
		A12:		in		STD_LOGIC;
		A11:		in		STD_LOGIC;
		A10:		in		STD_LOGIC;
		A9:		in		STD_LOGIC;
		A8:		in		STD_LOGIC;
		A7:		in		STD_LOGIC;
		A6:		in		STD_LOGIC;
		A5:		in		STD_LOGIC;
		A4:		in		STD_LOGIC;
		A3:		in		STD_LOGIC;
		A2:		in		STD_LOGIC;
		A1:		in		STD_LOGIC;
		A0:		in		STD_LOGIC;
		
		RA16: 	out	STD_LOGIC;
		RA15: 	out	STD_LOGIC;
		RA14: 	out	STD_LOGIC;
		RA13: 	out	STD_LOGIC;
		RA12: 	out	STD_LOGIC;
		CSRAM: 	out	STD_LOGIC;
		CSROM: 	out	STD_LOGIC;
		nBUFEN:	out	STD_LOGIC;
		NWDS:		out	STD_LOGIC;
		NRDS:		out	STD_LOGIC;
		ClkOut: 	out	STD_LOGIC
		);
end decoder;

architecture Behavioral of decoder is
	signal ClkDiv: 				STD_LOGIC_VECTOR(1 downto 0);
	signal regBFFE, regBFFF :	STD_LOGIC_VECTOR(7 downto 0);
   signal ledBFFD:            STD_LOGIC_VECTOR(7 downto 0);
   signal BFFX:               STD_LOGIC;
	signal RD, WR, WP:			STD_LOGIC;
	signal BS0, BS1, BS2:		STD_LOGIC;
	signal XMA0, XMA1, XMA2:	STD_LOGIC;
	signal MP0, MP1:				STD_LOGIC;
	signal ClkSel, TurboMode:	STD_LOGIC;
	
	begin	
      process (A15, A14, A13, A12, A11, A10, A9, A8, A7, A6, A5, A4, A3, A2)
      begin
      -- select #BFFx
         if (A15='1' and A14='0' and A13='1' and A12='1' and A11='1' and A10='1' and A9='1' and A8='1' and A7='1' and A6='1' and A5='1' and A4='1' and A3='0' and A2='0') then
            BFFX <= '1';
         else
            BFFX <= '0';
         end if;
      end process;
     
		process(Phi2, MP0, MP1, Reset, BFFX)
		begin
			-- write BFFD (control register)
			if falling_edge(Phi2) then
				if Reset = '0' then
					ledBFFD(7 downto 0) <= "00000000";
				else
					if BFFX = '1' and A1 = '0' and A0 = '1' and RW = '0' then
						ledBFFD <= DD;
					end if;
				end if;
			end if;

			-- write BFFE (control register)
			if falling_edge(Phi2) then
				if Reset = '0' then
					if (MP0 = '1' and MP1 = '1') then
						regBFFE(7 downto 0) <= "00000000";
					else
						regBFFE(6) <= '0';
						regBFFE(5) <= '0';
					end if;
				else
					if BFFX = '1' and A1 = '1' and A0 = '0' and RW = '0' then
						regBFFE <= DD;
					end if;
				end if;
			end if;
			
			-- write BFFF (bank switch register)
			if falling_edge(Phi2) then
				if Reset = '0' then
					regBFFF <= x"00";
				else
					if BFFX = '1' and A1 = '1' and A0 = '1' and RW = '0' then
						regBFFF <= DD;
					end if;
				end if;
			end if;

	end process;


	process (Phi2, RW, WP, A15, A14, A13, MP0, MP1)
	begin
		if (Phi2 = '1' and RW = '1') 
		then
			RD <= '0';
		else 
			RD <= '1';
		end if;

		if (Phi2 = '1' and RW = '0' and WP = '0')
			or (Phi2 = '1' and RW = '0' and WP = '1' and A15 = '0' and (MP1 = '1' or MP0 = '0'))
			or (Phi2 = '1' and RW = '0' and WP = '1' and A15 = '0' and MP1 = '0' and MP0 = '1' and A14 = '0')
			or (Phi2 = '1' and RW = '0' and WP = '1' and A15 = '0' and MP1 = '0' and MP0 = '1' and A14 = '1' and A13 = '0')
		then 
			WR <= '0';
		else 
			WR <= '1';
		end if;
	end process;

	process(ClkIn, TurboMode, ClkSel, ClkDiv)
	begin
		if falling_edge(ClkIn) then
			ClkDiv <= STD_LOGIC_VECTOR(unsigned(ClkDiv) + 1);
			-- read clock select bits from #BFFE when counter is zero,
			-- that way we can garantee that the PHI0 pin is low
			if ClkDiv = b"00" then
				TurboMode <= regBFFE(5);
				ClkSel <= regBFFE(6);
			end if;
		end if;
	
		-- Clock divider to 1, 2 and 4 MHz clock signals
		if (TurboMode = '0') then
			if (ClkSel = '0') then
				ClkOut <= ClkDiv(1);
			else
				ClkOut <= ClkDiv(0);
			end if;
		else
			ClkOut <= ClkIn;
		end if;
	end process;

	process (A15, A14, A13, A12, A11, A10, A9, A8, BS0, BS1, BS2, XMA0, XMA1, XMA2, MP0, MP1, BFFX)
	begin

		-- Memory profile 1: Atom RAM/ROM Board

		if (MP1 = '0' and MP0 = '0') then
			
			-- chip select rom 
			if (A15 = '1' and A14 = '1') 
				or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and XMA0 = '0')
				or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and XMA0 = '1' and (BS2 = '1' or BS1 = '1' or BS0 = '1'))
			then 
				CSROM <= '0';
			else
				CSROM <= '1';
			end if;	

			-- chip select ram (inverse logic!)
			if (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and XMA0 = '1' and BS2 = '0' and BS1 = '0' and BS0 = '0')
				or (A15 = '0' and XMA1 = '1')
				or (A15 = '0' and XMA1 = '0' and not (A14 = '0' and A13 = '0' and A12 = '0' and A11 = '1' and A10 = '0' and A9 = '1' and A8 = '0'))
			then
				CSRAM <= '1';
			else
				CSRAM <= '0';
			end if;

			-- RA16
			if (A15 = '1' and A14 = '1')
				or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and XMA0 = '1' and BS2 = '0' and BS1 = '0' and BS0 = '0')
			then 
				RA16 <= '1';
			else
				RA16 <= '0';
			end if;

			-- RA15 (always zero in this profile)
			RA15 <= '0';

			-- RA14
			if (A15 = '1' and A14 = '1' and XMA2 = '0')
				or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS2 = '1')
				or (A15 = '0' and A14 = '1')
			then
				RA14 <= '1';
			else
				RA14 <= '0';
			end if;	

			-- RA13
			if (A15 = '1' and A14 = '1' and A13 = '1')
				or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS1 = '1')
				or (A15 = '0' and A13 = '1')
			then 
				RA13 <= '1';
			else
				RA13 <= '0';
			end if;

			-- RA12
			if (A15 = '1' and A14 = '1' and A12 = '1')
				or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS0 = '1')
				or (A15 = '0' and A12 = '1')
			then 
				RA12 <= '1';
			else
				RA12 <= '0';
			end if;
		else

			-- Memory profile 2: BBC Basic
			if (MP1 = '0' and MP0 = '1') then
				
				-- rom select
				if (A15 = '1' and A14 = '1')
					or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '1' and XMA1 = '0')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and XMA0 = '0')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and XMA0 = '1' and (BS2 = '1' or BS1 = '1' or BS0 = '1'))
				then 
					CSROM <= '0';
				else
					CSROM <= '1';
				end if;

				--ram select (inverse logic!)
				if (A15 = '0' and A14 = '0')
					or (A15 = '0' and A14 = '1' and A13 = '0')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and XMA0 = '1' and BS2 = '0' and BS1 = '0' and BS0 = '0')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '1' and XMA1 = '1')
				then 
					CSRAM <= '1';
				else
					CSRAM <= '0';
				end if;

				-- RA16
				if (A15 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '1' and XMA1 = '0')
				then 
					RA16 <= '1';
				else 
					RA16 <= '0';
				end if;

				-- RA15 (always one in this profile)
				RA15 <= '1';

				-- RA14
				if (A15 = '1' and A14 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '1' and XMA1 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and BS2 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and XMA0 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '0')					
				then 
					RA14 <= '1';
				else
					RA14 <= '0';
				end if;

				-- RA13
				if (A15 = '1' and A13 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '1' and XMA1 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and BS1 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and XMA0 = '1')
					or (A15 = '0' and A14 = '0' and A13 = '1')
				then 
					RA13 <= '1';
				else 
					RA13 <= '0';
				end if;

				-- RA12
				if (A15 = '1' and A12 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '1' and A12 = '0' and BS0 = '1')
					or (A15 = '0' and A14 = '1' and A13 = '0' and A12 = '1')
					or (A15 = '0' and A14 = '0' and A13 = '1' and A12 = '1')
					or (A15 = '0' and A14 = '0' and A13 = '1' and A12 = '1')
					or (A15 = '0' and A14 = '0' and A13 = '0' and A12 = '1')
				then 
					RA12 <= '1';
				else
					RA12 <= '0';
				end if;

			else
			
			-- Memory profile 3: Atom 2015

				-- csrom (not used in the profile)
				csrom <= '1';

				-- csram (inverse logic!) 
				if (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '1')
					or (A15 = '0' and XMA2 = '0' and A14 = '0' and A13 = '0' and A12 = '0' and A11 = '1' and A10 = '0' and A9 = '1' and A8 = '0')
					or (A15 = '1' and A14 = '0' and A13 = '0')
				then
					csram <= '0';
				else	
					csram <= '1';
				end if;

				-- RA16
				if (A15 = '0' and A14 = '1' and XMA1 = '1')
					or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS2 = '1')
					or (A15 = '1' and A14 = '1')
				then
					RA16 <= '1';
				else
					RA16 <= '0';
				end if;

				-- RA15
				if (A15 = '0' and A14 = '1' and XMA0 = '1')
					or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS2 = '0')
					or (A15 = '1' and A14 = '1')
				then
					RA15 <= '1';
				else
					RA15 <= '0';
				end if;

				-- RA14
				if (A15 = '0' and A14 = '1' and XMA0 = '0')
					or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS2 = '0')
					or (A15 = '1' and A14 = '1')
				then
					RA14 <= '1';
				else
					RA14 <= '0';
				end if;
				
				-- RA13
				if (A15 = '0' and A13 = '1')
					or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS1 = '1')
					or (A15 = '1' and A14 = '1' and A13 = '1')
				then
					RA13 <= '1';
				else
					RA13 <= '0';
				end if;

				-- RA12
				if (A15 = '0' and A12 = '1')
					or (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '0' and BS0 = '1')
					or (A15 = '1' and A14 = '1' and A12 = '1') 
				then
					RA12 <= '1';
				else
					RA12 <= '0';
				end if;
			
			end if;
		end if;

		-- Bus Buffer control
		if (A15 = '1' and A14 = '0' and A13 = '1' and A12 = '1' and A11 = '1' and A10 = '1' and BFFX = '0') 
			or (A15 = '0' and A14 = '0' and A13 = '0' and A12 = '0' and A11 = '1' and A10 = '0' and A9 = '1' and A8 = '0' and XMA1 = '0')
		then
			nBUFEN <= '0';
		else 
			nBUFEN <= '1';
		end if;
	end process;


	-- Signals to output
	NRDS <= RD;
	NWDS <= WR;
	BS0  <= regBFFF(0);
	BS1  <= regBFFF(1);
	BS2  <= regBFFF(2);
	
	XMA0 <= regBFFE(0);
	XMA1 <= regBFFE(1);
	XMA2 <= regBFFE(2);
	MP0  <= regBFFE(3);
	MP1  <= regBFFE(4);
	WP   <= regBFFE(7);
	leds <= ledBFFD;
   
	-- read registers
 DD <= (others => 'Z') when BFFX = '0' or RW = '0' else
         ledBFFD         when A1 = '0' and A0 = '1'  else
         regBFFE         when A1 = '1' and A0 = '0'  else
         regBFFF         when A1 = '1' and A0 = '1'  else
         (others => '0');

end Behavioral;

