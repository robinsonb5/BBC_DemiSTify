
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_rom2 is
generic
	(
		ADDR_WIDTH : integer := 15 -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.
	);
port (
	clk : in std_logic;
	reset_n : in std_logic := '1';
	addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
	q : out std_logic_vector(31 downto 0);
	-- Allow writes - defaults supplied to simplify projects that don't need to write.
	d : in std_logic_vector(31 downto 0) := X"00000000";
	we : in std_logic := '0';
	bytesel : in std_logic_vector(3 downto 0) := "1111"
);
end entity;

architecture rtl of controller_rom2 is

	signal addr1 : integer range 0 to 2**ADDR_WIDTH-1;

	--  build up 2D array to hold the memory
	type word_t is array (0 to 3) of std_logic_vector(7 downto 0);
	type ram_t is array (0 to 2 ** ADDR_WIDTH - 1) of word_t;

	signal ram : ram_t:=
	(

     0 => (x"00",x"07",x"0f",x"79"),
     1 => (x"49",x"7f",x"36",x"00"),
     2 => (x"00",x"36",x"7f",x"49"),
     3 => (x"49",x"4f",x"06",x"00"),
     4 => (x"00",x"1e",x"3f",x"69"),
     5 => (x"66",x"00",x"00",x"00"),
     6 => (x"00",x"00",x"00",x"66"),
     7 => (x"e6",x"80",x"00",x"00"),
     8 => (x"00",x"00",x"00",x"66"),
     9 => (x"14",x"08",x"08",x"00"),
    10 => (x"00",x"22",x"22",x"14"),
    11 => (x"14",x"14",x"14",x"00"),
    12 => (x"00",x"14",x"14",x"14"),
    13 => (x"14",x"22",x"22",x"00"),
    14 => (x"00",x"08",x"08",x"14"),
    15 => (x"51",x"03",x"02",x"00"),
    16 => (x"00",x"06",x"0f",x"59"),
    17 => (x"5d",x"41",x"7f",x"3e"),
    18 => (x"00",x"1e",x"1f",x"55"),
    19 => (x"09",x"7f",x"7e",x"00"),
    20 => (x"00",x"7e",x"7f",x"09"),
    21 => (x"49",x"7f",x"7f",x"00"),
    22 => (x"00",x"36",x"7f",x"49"),
    23 => (x"63",x"3e",x"1c",x"00"),
    24 => (x"00",x"41",x"41",x"41"),
    25 => (x"41",x"7f",x"7f",x"00"),
    26 => (x"00",x"1c",x"3e",x"63"),
    27 => (x"49",x"7f",x"7f",x"00"),
    28 => (x"00",x"41",x"41",x"49"),
    29 => (x"09",x"7f",x"7f",x"00"),
    30 => (x"00",x"01",x"01",x"09"),
    31 => (x"41",x"7f",x"3e",x"00"),
    32 => (x"00",x"7a",x"7b",x"49"),
    33 => (x"08",x"7f",x"7f",x"00"),
    34 => (x"00",x"7f",x"7f",x"08"),
    35 => (x"7f",x"41",x"00",x"00"),
    36 => (x"00",x"00",x"41",x"7f"),
    37 => (x"40",x"60",x"20",x"00"),
    38 => (x"00",x"3f",x"7f",x"40"),
    39 => (x"1c",x"08",x"7f",x"7f"),
    40 => (x"00",x"41",x"63",x"36"),
    41 => (x"40",x"7f",x"7f",x"00"),
    42 => (x"00",x"40",x"40",x"40"),
    43 => (x"0c",x"06",x"7f",x"7f"),
    44 => (x"00",x"7f",x"7f",x"06"),
    45 => (x"0c",x"06",x"7f",x"7f"),
    46 => (x"00",x"7f",x"7f",x"18"),
    47 => (x"41",x"7f",x"3e",x"00"),
    48 => (x"00",x"3e",x"7f",x"41"),
    49 => (x"09",x"7f",x"7f",x"00"),
    50 => (x"00",x"06",x"0f",x"09"),
    51 => (x"61",x"41",x"7f",x"3e"),
    52 => (x"00",x"40",x"7e",x"7f"),
    53 => (x"09",x"7f",x"7f",x"00"),
    54 => (x"00",x"66",x"7f",x"19"),
    55 => (x"4d",x"6f",x"26",x"00"),
    56 => (x"00",x"32",x"7b",x"59"),
    57 => (x"7f",x"01",x"01",x"00"),
    58 => (x"00",x"01",x"01",x"7f"),
    59 => (x"40",x"7f",x"3f",x"00"),
    60 => (x"00",x"3f",x"7f",x"40"),
    61 => (x"70",x"3f",x"0f",x"00"),
    62 => (x"00",x"0f",x"3f",x"70"),
    63 => (x"18",x"30",x"7f",x"7f"),
    64 => (x"00",x"7f",x"7f",x"30"),
    65 => (x"1c",x"36",x"63",x"41"),
    66 => (x"41",x"63",x"36",x"1c"),
    67 => (x"7c",x"06",x"03",x"01"),
    68 => (x"01",x"03",x"06",x"7c"),
    69 => (x"4d",x"59",x"71",x"61"),
    70 => (x"00",x"41",x"43",x"47"),
    71 => (x"7f",x"7f",x"00",x"00"),
    72 => (x"00",x"00",x"41",x"41"),
    73 => (x"0c",x"06",x"03",x"01"),
    74 => (x"40",x"60",x"30",x"18"),
    75 => (x"41",x"41",x"00",x"00"),
    76 => (x"00",x"00",x"7f",x"7f"),
    77 => (x"03",x"06",x"0c",x"08"),
    78 => (x"00",x"08",x"0c",x"06"),
    79 => (x"80",x"80",x"80",x"80"),
    80 => (x"00",x"80",x"80",x"80"),
    81 => (x"03",x"00",x"00",x"00"),
    82 => (x"00",x"00",x"04",x"07"),
    83 => (x"54",x"74",x"20",x"00"),
    84 => (x"00",x"78",x"7c",x"54"),
    85 => (x"44",x"7f",x"7f",x"00"),
    86 => (x"00",x"38",x"7c",x"44"),
    87 => (x"44",x"7c",x"38",x"00"),
    88 => (x"00",x"00",x"44",x"44"),
    89 => (x"44",x"7c",x"38",x"00"),
    90 => (x"00",x"7f",x"7f",x"44"),
    91 => (x"54",x"7c",x"38",x"00"),
    92 => (x"00",x"18",x"5c",x"54"),
    93 => (x"7f",x"7e",x"04",x"00"),
    94 => (x"00",x"00",x"05",x"05"),
    95 => (x"a4",x"bc",x"18",x"00"),
    96 => (x"00",x"7c",x"fc",x"a4"),
    97 => (x"04",x"7f",x"7f",x"00"),
    98 => (x"00",x"78",x"7c",x"04"),
    99 => (x"3d",x"00",x"00",x"00"),
   100 => (x"00",x"00",x"40",x"7d"),
   101 => (x"80",x"80",x"80",x"00"),
   102 => (x"00",x"00",x"7d",x"fd"),
   103 => (x"10",x"7f",x"7f",x"00"),
   104 => (x"00",x"44",x"6c",x"38"),
   105 => (x"3f",x"00",x"00",x"00"),
   106 => (x"00",x"00",x"40",x"7f"),
   107 => (x"18",x"0c",x"7c",x"7c"),
   108 => (x"00",x"78",x"7c",x"0c"),
   109 => (x"04",x"7c",x"7c",x"00"),
   110 => (x"00",x"78",x"7c",x"04"),
   111 => (x"44",x"7c",x"38",x"00"),
   112 => (x"00",x"38",x"7c",x"44"),
   113 => (x"24",x"fc",x"fc",x"00"),
   114 => (x"00",x"18",x"3c",x"24"),
   115 => (x"24",x"3c",x"18",x"00"),
   116 => (x"00",x"fc",x"fc",x"24"),
   117 => (x"04",x"7c",x"7c",x"00"),
   118 => (x"00",x"08",x"0c",x"04"),
   119 => (x"54",x"5c",x"48",x"00"),
   120 => (x"00",x"20",x"74",x"54"),
   121 => (x"7f",x"3f",x"04",x"00"),
   122 => (x"00",x"00",x"44",x"44"),
   123 => (x"40",x"7c",x"3c",x"00"),
   124 => (x"00",x"7c",x"7c",x"40"),
   125 => (x"60",x"3c",x"1c",x"00"),
   126 => (x"00",x"1c",x"3c",x"60"),
   127 => (x"30",x"60",x"7c",x"3c"),
   128 => (x"00",x"3c",x"7c",x"60"),
   129 => (x"10",x"38",x"6c",x"44"),
   130 => (x"00",x"44",x"6c",x"38"),
   131 => (x"e0",x"bc",x"1c",x"00"),
   132 => (x"00",x"1c",x"3c",x"60"),
   133 => (x"74",x"64",x"44",x"00"),
   134 => (x"00",x"44",x"4c",x"5c"),
   135 => (x"3e",x"08",x"08",x"00"),
   136 => (x"00",x"41",x"41",x"77"),
   137 => (x"7f",x"00",x"00",x"00"),
   138 => (x"00",x"00",x"00",x"7f"),
   139 => (x"77",x"41",x"41",x"00"),
   140 => (x"00",x"08",x"08",x"3e"),
   141 => (x"03",x"01",x"01",x"02"),
   142 => (x"00",x"01",x"02",x"02"),
   143 => (x"7f",x"7f",x"7f",x"7f"),
   144 => (x"00",x"7f",x"7f",x"7f"),
   145 => (x"1c",x"1c",x"08",x"08"),
   146 => (x"7f",x"7f",x"3e",x"3e"),
   147 => (x"3e",x"3e",x"7f",x"7f"),
   148 => (x"08",x"08",x"1c",x"1c"),
   149 => (x"7c",x"18",x"10",x"00"),
   150 => (x"00",x"10",x"18",x"7c"),
   151 => (x"7c",x"30",x"10",x"00"),
   152 => (x"00",x"10",x"30",x"7c"),
   153 => (x"60",x"60",x"30",x"10"),
   154 => (x"00",x"06",x"1e",x"78"),
   155 => (x"18",x"3c",x"66",x"42"),
   156 => (x"00",x"42",x"66",x"3c"),
   157 => (x"c2",x"6a",x"38",x"78"),
   158 => (x"00",x"38",x"6c",x"c6"),
   159 => (x"60",x"00",x"00",x"60"),
   160 => (x"00",x"60",x"00",x"00"),
   161 => (x"5c",x"5b",x"5e",x"0e"),
   162 => (x"86",x"fc",x"0e",x"5d"),
   163 => (x"f3",x"c2",x"7e",x"71"),
   164 => (x"c0",x"4c",x"bf",x"c4"),
   165 => (x"c4",x"1e",x"c0",x"4b"),
   166 => (x"c4",x"02",x"ab",x"66"),
   167 => (x"c2",x"4d",x"c0",x"87"),
   168 => (x"75",x"4d",x"c1",x"87"),
   169 => (x"ee",x"49",x"73",x"1e"),
   170 => (x"86",x"c8",x"87",x"e1"),
   171 => (x"ef",x"49",x"e0",x"c0"),
   172 => (x"a4",x"c4",x"87",x"ea"),
   173 => (x"f0",x"49",x"6a",x"4a"),
   174 => (x"c8",x"f1",x"87",x"f1"),
   175 => (x"c1",x"84",x"cc",x"87"),
   176 => (x"ab",x"b7",x"c8",x"83"),
   177 => (x"87",x"cd",x"ff",x"04"),
   178 => (x"4d",x"26",x"8e",x"fc"),
   179 => (x"4b",x"26",x"4c",x"26"),
   180 => (x"71",x"1e",x"4f",x"26"),
   181 => (x"c8",x"f3",x"c2",x"4a"),
   182 => (x"c8",x"f3",x"c2",x"5a"),
   183 => (x"49",x"78",x"c7",x"48"),
   184 => (x"26",x"87",x"e1",x"fe"),
   185 => (x"1e",x"73",x"1e",x"4f"),
   186 => (x"b7",x"c0",x"4a",x"71"),
   187 => (x"87",x"d3",x"03",x"aa"),
   188 => (x"bf",x"c8",x"d8",x"c2"),
   189 => (x"c1",x"87",x"c4",x"05"),
   190 => (x"c0",x"87",x"c2",x"4b"),
   191 => (x"cc",x"d8",x"c2",x"4b"),
   192 => (x"c2",x"87",x"c4",x"5b"),
   193 => (x"fc",x"5a",x"cc",x"d8"),
   194 => (x"c8",x"d8",x"c2",x"48"),
   195 => (x"c1",x"4a",x"78",x"bf"),
   196 => (x"a2",x"c0",x"c1",x"9a"),
   197 => (x"87",x"e6",x"ec",x"49"),
   198 => (x"4f",x"26",x"4b",x"26"),
   199 => (x"c4",x"4a",x"71",x"1e"),
   200 => (x"49",x"72",x"1e",x"66"),
   201 => (x"fc",x"87",x"f0",x"eb"),
   202 => (x"1e",x"4f",x"26",x"8e"),
   203 => (x"c3",x"48",x"d4",x"ff"),
   204 => (x"d0",x"ff",x"78",x"ff"),
   205 => (x"78",x"e1",x"c0",x"48"),
   206 => (x"c1",x"48",x"d4",x"ff"),
   207 => (x"c4",x"48",x"71",x"78"),
   208 => (x"08",x"d4",x"ff",x"30"),
   209 => (x"48",x"d0",x"ff",x"78"),
   210 => (x"26",x"78",x"e0",x"c0"),
   211 => (x"5b",x"5e",x"0e",x"4f"),
   212 => (x"f0",x"0e",x"5d",x"5c"),
   213 => (x"48",x"a6",x"c8",x"86"),
   214 => (x"ec",x"4d",x"78",x"c0"),
   215 => (x"80",x"fc",x"7e",x"bf"),
   216 => (x"bf",x"c4",x"f3",x"c2"),
   217 => (x"4c",x"bf",x"e8",x"78"),
   218 => (x"bf",x"c8",x"d8",x"c2"),
   219 => (x"87",x"e9",x"e4",x"49"),
   220 => (x"ca",x"49",x"ee",x"cb"),
   221 => (x"4b",x"70",x"87",x"d6"),
   222 => (x"e2",x"e7",x"49",x"c7"),
   223 => (x"05",x"98",x"70",x"87"),
   224 => (x"49",x"6e",x"87",x"c8"),
   225 => (x"c1",x"02",x"99",x"c1"),
   226 => (x"4d",x"c1",x"87",x"c1"),
   227 => (x"c2",x"7e",x"bf",x"ec"),
   228 => (x"49",x"bf",x"c8",x"d8"),
   229 => (x"73",x"87",x"c2",x"e4"),
   230 => (x"87",x"fc",x"c9",x"49"),
   231 => (x"d7",x"02",x"98",x"70"),
   232 => (x"c0",x"d8",x"c2",x"87"),
   233 => (x"b9",x"c1",x"49",x"bf"),
   234 => (x"59",x"c4",x"d8",x"c2"),
   235 => (x"87",x"fb",x"fd",x"71"),
   236 => (x"c9",x"49",x"ee",x"cb"),
   237 => (x"4b",x"70",x"87",x"d6"),
   238 => (x"e2",x"e6",x"49",x"c7"),
   239 => (x"05",x"98",x"70",x"87"),
   240 => (x"6e",x"87",x"c7",x"ff"),
   241 => (x"05",x"99",x"c1",x"49"),
   242 => (x"75",x"87",x"ff",x"fe"),
   243 => (x"e3",x"c0",x"02",x"9d"),
   244 => (x"c8",x"d8",x"c2",x"87"),
   245 => (x"ba",x"c1",x"4a",x"bf"),
   246 => (x"5a",x"cc",x"d8",x"c2"),
   247 => (x"0a",x"7a",x"0a",x"fc"),
   248 => (x"c0",x"c1",x"9a",x"c1"),
   249 => (x"d5",x"e9",x"49",x"a2"),
   250 => (x"49",x"da",x"c1",x"87"),
   251 => (x"c8",x"87",x"f0",x"e5"),
   252 => (x"78",x"c1",x"48",x"a6"),
   253 => (x"bf",x"c8",x"d8",x"c2"),
   254 => (x"87",x"e9",x"c0",x"05"),
   255 => (x"ff",x"c3",x"49",x"74"),
   256 => (x"c0",x"1e",x"71",x"99"),
   257 => (x"87",x"d4",x"fc",x"49"),
   258 => (x"b7",x"c8",x"49",x"74"),
   259 => (x"c1",x"1e",x"71",x"29"),
   260 => (x"87",x"c8",x"fc",x"49"),
   261 => (x"fd",x"c3",x"86",x"c8"),
   262 => (x"87",x"c3",x"e5",x"49"),
   263 => (x"e4",x"49",x"fa",x"c3"),
   264 => (x"d1",x"c7",x"87",x"fd"),
   265 => (x"c3",x"49",x"74",x"87"),
   266 => (x"b7",x"c8",x"99",x"ff"),
   267 => (x"74",x"b4",x"71",x"2c"),
   268 => (x"87",x"df",x"02",x"9c"),
   269 => (x"bf",x"c4",x"d8",x"c2"),
   270 => (x"87",x"dc",x"c7",x"49"),
   271 => (x"c0",x"05",x"98",x"70"),
   272 => (x"4c",x"c0",x"87",x"c4"),
   273 => (x"e0",x"c2",x"87",x"d3"),
   274 => (x"87",x"c0",x"c7",x"49"),
   275 => (x"58",x"c8",x"d8",x"c2"),
   276 => (x"c2",x"87",x"c6",x"c0"),
   277 => (x"c0",x"48",x"c4",x"d8"),
   278 => (x"c8",x"49",x"74",x"78"),
   279 => (x"87",x"ce",x"05",x"99"),
   280 => (x"e3",x"49",x"f5",x"c3"),
   281 => (x"49",x"70",x"87",x"f9"),
   282 => (x"c0",x"02",x"99",x"c2"),
   283 => (x"f3",x"c2",x"87",x"e9"),
   284 => (x"c0",x"02",x"bf",x"c8"),
   285 => (x"c1",x"48",x"87",x"c9"),
   286 => (x"cc",x"f3",x"c2",x"88"),
   287 => (x"c4",x"87",x"d3",x"58"),
   288 => (x"e0",x"c1",x"48",x"66"),
   289 => (x"6e",x"7e",x"70",x"80"),
   290 => (x"c5",x"c0",x"02",x"bf"),
   291 => (x"49",x"ff",x"4b",x"87"),
   292 => (x"a6",x"c8",x"0f",x"73"),
   293 => (x"74",x"78",x"c1",x"48"),
   294 => (x"05",x"99",x"c4",x"49"),
   295 => (x"c3",x"87",x"ce",x"c0"),
   296 => (x"fa",x"e2",x"49",x"f2"),
   297 => (x"c2",x"49",x"70",x"87"),
   298 => (x"f0",x"c0",x"02",x"99"),
   299 => (x"c8",x"f3",x"c2",x"87"),
   300 => (x"c7",x"48",x"7e",x"bf"),
   301 => (x"c0",x"03",x"a8",x"b7"),
   302 => (x"48",x"6e",x"87",x"cb"),
   303 => (x"f3",x"c2",x"80",x"c1"),
   304 => (x"d3",x"c0",x"58",x"cc"),
   305 => (x"48",x"66",x"c4",x"87"),
   306 => (x"70",x"80",x"e0",x"c1"),
   307 => (x"02",x"bf",x"6e",x"7e"),
   308 => (x"4b",x"87",x"c5",x"c0"),
   309 => (x"0f",x"73",x"49",x"fe"),
   310 => (x"c1",x"48",x"a6",x"c8"),
   311 => (x"49",x"fd",x"c3",x"78"),
   312 => (x"70",x"87",x"fc",x"e1"),
   313 => (x"02",x"99",x"c2",x"49"),
   314 => (x"c2",x"87",x"e9",x"c0"),
   315 => (x"02",x"bf",x"c8",x"f3"),
   316 => (x"c2",x"87",x"c9",x"c0"),
   317 => (x"c0",x"48",x"c8",x"f3"),
   318 => (x"87",x"d3",x"c0",x"78"),
   319 => (x"c1",x"48",x"66",x"c4"),
   320 => (x"7e",x"70",x"80",x"e0"),
   321 => (x"c0",x"02",x"bf",x"6e"),
   322 => (x"fd",x"4b",x"87",x"c5"),
   323 => (x"c8",x"0f",x"73",x"49"),
   324 => (x"78",x"c1",x"48",x"a6"),
   325 => (x"e1",x"49",x"fa",x"c3"),
   326 => (x"49",x"70",x"87",x"c5"),
   327 => (x"c0",x"02",x"99",x"c2"),
   328 => (x"f3",x"c2",x"87",x"ea"),
   329 => (x"c7",x"48",x"bf",x"c8"),
   330 => (x"c0",x"03",x"a8",x"b7"),
   331 => (x"f3",x"c2",x"87",x"c9"),
   332 => (x"78",x"c7",x"48",x"c8"),
   333 => (x"c4",x"87",x"d0",x"c0"),
   334 => (x"e0",x"c1",x"4a",x"66"),
   335 => (x"c0",x"02",x"6a",x"82"),
   336 => (x"fc",x"4b",x"87",x"c5"),
   337 => (x"c8",x"0f",x"73",x"49"),
   338 => (x"78",x"c1",x"48",x"a6"),
   339 => (x"f3",x"c2",x"4d",x"c0"),
   340 => (x"50",x"c0",x"48",x"c0"),
   341 => (x"c2",x"49",x"ee",x"cb"),
   342 => (x"4b",x"70",x"87",x"f2"),
   343 => (x"97",x"c0",x"f3",x"c2"),
   344 => (x"dd",x"c1",x"05",x"bf"),
   345 => (x"c3",x"49",x"74",x"87"),
   346 => (x"c0",x"05",x"99",x"f0"),
   347 => (x"da",x"c1",x"87",x"cd"),
   348 => (x"ea",x"df",x"ff",x"49"),
   349 => (x"02",x"98",x"70",x"87"),
   350 => (x"c1",x"87",x"c7",x"c1"),
   351 => (x"4c",x"bf",x"e8",x"4d"),
   352 => (x"99",x"ff",x"c3",x"49"),
   353 => (x"71",x"2c",x"b7",x"c8"),
   354 => (x"c8",x"d8",x"c2",x"b4"),
   355 => (x"dc",x"ff",x"49",x"bf"),
   356 => (x"49",x"73",x"87",x"c7"),
   357 => (x"70",x"87",x"c1",x"c2"),
   358 => (x"c6",x"c0",x"02",x"98"),
   359 => (x"c0",x"f3",x"c2",x"87"),
   360 => (x"c2",x"50",x"c1",x"48"),
   361 => (x"bf",x"97",x"c0",x"f3"),
   362 => (x"87",x"d6",x"c0",x"05"),
   363 => (x"f0",x"c3",x"49",x"74"),
   364 => (x"c6",x"ff",x"05",x"99"),
   365 => (x"49",x"da",x"c1",x"87"),
   366 => (x"87",x"e3",x"de",x"ff"),
   367 => (x"fe",x"05",x"98",x"70"),
   368 => (x"9d",x"75",x"87",x"f9"),
   369 => (x"87",x"e0",x"c0",x"02"),
   370 => (x"c2",x"48",x"a6",x"cc"),
   371 => (x"78",x"bf",x"c8",x"f3"),
   372 => (x"cc",x"49",x"66",x"cc"),
   373 => (x"48",x"66",x"c4",x"91"),
   374 => (x"7e",x"70",x"80",x"71"),
   375 => (x"c0",x"02",x"bf",x"6e"),
   376 => (x"cc",x"4b",x"87",x"c6"),
   377 => (x"0f",x"73",x"49",x"66"),
   378 => (x"c0",x"02",x"66",x"c8"),
   379 => (x"f3",x"c2",x"87",x"c8"),
   380 => (x"f2",x"49",x"bf",x"c8"),
   381 => (x"8e",x"f0",x"87",x"ce"),
   382 => (x"4c",x"26",x"4d",x"26"),
   383 => (x"4f",x"26",x"4b",x"26"),
   384 => (x"00",x"00",x"00",x"00"),
   385 => (x"00",x"00",x"00",x"00"),
   386 => (x"00",x"00",x"00",x"00"),
   387 => (x"ff",x"4a",x"71",x"1e"),
   388 => (x"72",x"49",x"bf",x"c8"),
   389 => (x"4f",x"26",x"48",x"a1"),
   390 => (x"bf",x"c8",x"ff",x"1e"),
   391 => (x"c0",x"c0",x"fe",x"89"),
   392 => (x"a9",x"c0",x"c0",x"c0"),
   393 => (x"c0",x"87",x"c4",x"01"),
   394 => (x"c1",x"87",x"c2",x"4a"),
   395 => (x"26",x"48",x"72",x"4a"),
   396 => (x"5b",x"5e",x"0e",x"4f"),
   397 => (x"71",x"0e",x"5d",x"5c"),
   398 => (x"4c",x"d4",x"ff",x"4b"),
   399 => (x"c0",x"48",x"66",x"d0"),
   400 => (x"ff",x"49",x"d6",x"78"),
   401 => (x"c3",x"87",x"d5",x"de"),
   402 => (x"49",x"6c",x"7c",x"ff"),
   403 => (x"71",x"99",x"ff",x"c3"),
   404 => (x"f0",x"c3",x"49",x"4d"),
   405 => (x"a9",x"e0",x"c1",x"99"),
   406 => (x"c3",x"87",x"cb",x"05"),
   407 => (x"48",x"6c",x"7c",x"ff"),
   408 => (x"66",x"d0",x"98",x"c3"),
   409 => (x"ff",x"c3",x"78",x"08"),
   410 => (x"49",x"4a",x"6c",x"7c"),
   411 => (x"ff",x"c3",x"31",x"c8"),
   412 => (x"71",x"4a",x"6c",x"7c"),
   413 => (x"c8",x"49",x"72",x"b2"),
   414 => (x"7c",x"ff",x"c3",x"31"),
   415 => (x"b2",x"71",x"4a",x"6c"),
   416 => (x"31",x"c8",x"49",x"72"),
   417 => (x"6c",x"7c",x"ff",x"c3"),
   418 => (x"ff",x"b2",x"71",x"4a"),
   419 => (x"e0",x"c0",x"48",x"d0"),
   420 => (x"02",x"9b",x"73",x"78"),
   421 => (x"7b",x"72",x"87",x"c2"),
   422 => (x"4d",x"26",x"48",x"75"),
   423 => (x"4b",x"26",x"4c",x"26"),
   424 => (x"26",x"1e",x"4f",x"26"),
   425 => (x"5b",x"5e",x"0e",x"4f"),
   426 => (x"86",x"f8",x"0e",x"5c"),
   427 => (x"a6",x"c8",x"1e",x"76"),
   428 => (x"87",x"fd",x"fd",x"49"),
   429 => (x"4b",x"70",x"86",x"c4"),
   430 => (x"a8",x"c2",x"48",x"6e"),
   431 => (x"87",x"f0",x"c2",x"03"),
   432 => (x"f0",x"c3",x"4a",x"73"),
   433 => (x"aa",x"d0",x"c1",x"9a"),
   434 => (x"c1",x"87",x"c7",x"02"),
   435 => (x"c2",x"05",x"aa",x"e0"),
   436 => (x"49",x"73",x"87",x"de"),
   437 => (x"c3",x"02",x"99",x"c8"),
   438 => (x"87",x"c6",x"ff",x"87"),
   439 => (x"9c",x"c3",x"4c",x"73"),
   440 => (x"c1",x"05",x"ac",x"c2"),
   441 => (x"66",x"c4",x"87",x"c2"),
   442 => (x"71",x"31",x"c9",x"49"),
   443 => (x"4a",x"66",x"c4",x"1e"),
   444 => (x"f3",x"c2",x"92",x"d4"),
   445 => (x"81",x"72",x"49",x"cc"),
   446 => (x"87",x"d8",x"cf",x"fe"),
   447 => (x"db",x"ff",x"49",x"d8"),
   448 => (x"c0",x"c8",x"87",x"da"),
   449 => (x"e4",x"e1",x"c2",x"1e"),
   450 => (x"ca",x"e9",x"fd",x"49"),
   451 => (x"48",x"d0",x"ff",x"87"),
   452 => (x"c2",x"78",x"e0",x"c0"),
   453 => (x"cc",x"1e",x"e4",x"e1"),
   454 => (x"92",x"d4",x"4a",x"66"),
   455 => (x"49",x"cc",x"f3",x"c2"),
   456 => (x"cd",x"fe",x"81",x"72"),
   457 => (x"86",x"cc",x"87",x"df"),
   458 => (x"c1",x"05",x"ac",x"c1"),
   459 => (x"66",x"c4",x"87",x"c2"),
   460 => (x"71",x"31",x"c9",x"49"),
   461 => (x"4a",x"66",x"c4",x"1e"),
   462 => (x"f3",x"c2",x"92",x"d4"),
   463 => (x"81",x"72",x"49",x"cc"),
   464 => (x"87",x"d0",x"ce",x"fe"),
   465 => (x"1e",x"e4",x"e1",x"c2"),
   466 => (x"d4",x"4a",x"66",x"c8"),
   467 => (x"cc",x"f3",x"c2",x"92"),
   468 => (x"fe",x"81",x"72",x"49"),
   469 => (x"d7",x"87",x"df",x"cb"),
   470 => (x"ff",x"d9",x"ff",x"49"),
   471 => (x"1e",x"c0",x"c8",x"87"),
   472 => (x"49",x"e4",x"e1",x"c2"),
   473 => (x"87",x"cc",x"e7",x"fd"),
   474 => (x"d0",x"ff",x"86",x"cc"),
   475 => (x"78",x"e0",x"c0",x"48"),
   476 => (x"4c",x"26",x"8e",x"f8"),
   477 => (x"4f",x"26",x"4b",x"26"),
   478 => (x"5c",x"5b",x"5e",x"0e"),
   479 => (x"86",x"fc",x"0e",x"5d"),
   480 => (x"d4",x"ff",x"4d",x"71"),
   481 => (x"7e",x"66",x"d4",x"4c"),
   482 => (x"a8",x"b7",x"c3",x"48"),
   483 => (x"87",x"e2",x"c1",x"01"),
   484 => (x"66",x"c4",x"1e",x"75"),
   485 => (x"c2",x"93",x"d4",x"4b"),
   486 => (x"73",x"83",x"cc",x"f3"),
   487 => (x"d4",x"c5",x"fe",x"49"),
   488 => (x"49",x"a3",x"c8",x"87"),
   489 => (x"d0",x"ff",x"49",x"69"),
   490 => (x"78",x"e1",x"c8",x"48"),
   491 => (x"48",x"71",x"7c",x"dd"),
   492 => (x"70",x"98",x"ff",x"c3"),
   493 => (x"c8",x"4a",x"71",x"7c"),
   494 => (x"48",x"72",x"2a",x"b7"),
   495 => (x"70",x"98",x"ff",x"c3"),
   496 => (x"d0",x"4a",x"71",x"7c"),
   497 => (x"48",x"72",x"2a",x"b7"),
   498 => (x"70",x"98",x"ff",x"c3"),
   499 => (x"d8",x"48",x"71",x"7c"),
   500 => (x"7c",x"70",x"28",x"b7"),
   501 => (x"7c",x"7c",x"7c",x"c0"),
   502 => (x"7c",x"7c",x"7c",x"7c"),
   503 => (x"7c",x"7c",x"7c",x"7c"),
   504 => (x"48",x"d0",x"ff",x"7c"),
   505 => (x"c4",x"78",x"e0",x"c0"),
   506 => (x"49",x"dc",x"1e",x"66"),
   507 => (x"87",x"d1",x"d8",x"ff"),
   508 => (x"8e",x"fc",x"86",x"c8"),
   509 => (x"4c",x"26",x"4d",x"26"),
   510 => (x"4f",x"26",x"4b",x"26"),
   511 => (x"c2",x"1e",x"c0",x"1e"),
   512 => (x"49",x"bf",x"d8",x"e0"),
   513 => (x"c2",x"87",x"f1",x"fd"),
   514 => (x"49",x"bf",x"dc",x"e0"),
   515 => (x"87",x"f6",x"dd",x"fe"),
   516 => (x"8e",x"fc",x"48",x"c0"),
   517 => (x"00",x"00",x"4f",x"26"),
   518 => (x"00",x"00",x"28",x"20"),
   519 => (x"00",x"00",x"28",x"2c"),
   520 => (x"20",x"43",x"42",x"42"),
   521 => (x"20",x"20",x"20",x"20"),
   522 => (x"00",x"44",x"48",x"56"),
   523 => (x"20",x"43",x"42",x"42"),
   524 => (x"20",x"20",x"20",x"20"),
   525 => (x"00",x"4d",x"4f",x"52"),
   526 => (x"00",x"00",x"1b",x"af"),
		others => (others => x"00")
	);
	signal q1_local : word_t;

	-- Altera Quartus attributes
	attribute ramstyle: string;
	attribute ramstyle of ram: signal is "no_rw_check";

begin  -- rtl

	addr1 <= to_integer(unsigned(addr(ADDR_WIDTH-1 downto 0)));

	-- Reorganize the read data from the RAM to match the output
	q(7 downto 0) <= q1_local(3);
	q(15 downto 8) <= q1_local(2);
	q(23 downto 16) <= q1_local(1);
	q(31 downto 24) <= q1_local(0);

	process(clk)
	begin
		if(rising_edge(clk)) then 
			if(we = '1') then
				-- edit this code if using other than four bytes per word
				if (bytesel(3) = '1') then
					ram(addr1)(3) <= d(7 downto 0);
				end if;
				if (bytesel(2) = '1') then
					ram(addr1)(2) <= d(15 downto 8);
				end if;
				if (bytesel(1) = '1') then
					ram(addr1)(1) <= d(23 downto 16);
				end if;
				if (bytesel(0) = '1') then
					ram(addr1)(0) <= d(31 downto 24);
				end if;
			end if;
			q1_local <= ram(addr1);
		end if;
	end process;
  
end rtl;

