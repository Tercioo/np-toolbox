

--[=[
Get a table with the r, g, b values by just giving the name of the color.

Create a new color, require a string with the name of the color and a table with 3 indexes with integers {r, g, b} 0 to 255.
	local colorTable = npt.CreateColor (colorName, table{r, g, b})
	
Get a color by its name, if the color doesn't exists defaultColor will be used, if no defaultColor passed and the colorName doesn't exists, returns nil.
	local colorTable = npt.GetColor (colorName, defaultColor)
	
Similar to GetColor but does more verification, accept a table with rgb values and color name, trow debug messages if invalid color name or table.
	local colorTable = npt.ValidateColor (colorNameOrTable, defaultColor)
	
--]=]

local npt = _G.NoPixelToolbox

local floor = math.floor
local unpack = table.unpack
local lower = string.lower

npt.colorTable = {
	['aliceblue'] = {239, 247, 255, 255},
	['antiquewhite'] = {249, 235, 214, 255},
	['aqua'] = {0, 255, 255, 255},
	['aquamarine'] = {126, 255, 212, 255},
	['azure'] = {239, 255, 255, 255},
	['beige'] = {244, 244, 219, 255},
	['bisque'] = {255, 228, 195, 255},
	['black'] = {0, 0, 0, 255},
	['blanchedalmond'] = {255, 235, 205, 255},
	['blue'] = {0, 0, 255, 255},
	['blueviolet'] = {137, 42, 226, 255},
	['brown'] = {165, 42, 42, 255},
	['burlywood'] = {221, 184, 135, 255},
	['cadetblue'] = {94, 158, 160, 255},
	['chartreuse'] = {126, 255, 0, 255},
	['chocolate'] = {209, 105, 29, 255},
	['coral'] = {255, 126, 79, 255},
	['cornflowerblue'] = {100, 149, 237, 255},
	['cornsilk'] = {255, 247, 219, 255},
	['crimson'] = {219, 20, 59, 255},
	['cyan'] = {0, 255, 255, 255},
	['darkblue'] = {0, 0, 138, 255},
	['darkcyan'] = {0, 138, 138, 255},
	['darkgoldenrod'] = {184, 133, 11, 255},
	['darkgray'] = {168, 168, 168, 255},
	['darkgreen'] = {0, 100, 0, 255},
	['darkkhaki'] = {188, 182, 107, 255},
	['darkmagenta'] = {138, 0, 138, 255},
	['darkolivegreen'] = {84, 107, 47, 255},
	['darkorange'] = {255, 140, 0, 255},
	['darkorchid'] = {153, 49, 204, 255},
	['darkred'] = {138, 0, 0, 255},
	['darksalmon'] = {232, 149, 121, 255},
	['darkseagreen'] = {142, 188, 142, 255},
	['darkslateblue'] = {72, 61, 138, 255},
	['darkslategray'] = {47, 79, 79, 255},
	['darkturquoise'] = {0, 205, 209, 255},
	['darkviolet'] = {147, 0, 211, 255},
	['deeppink'] = {255, 20, 147, 255},
	['deepskyblue'] = {0, 191, 255, 255},
	['dimgray'] = {105, 105, 105, 255},
	['dimgrey'] = {105, 105, 105, 255},
	['dodgerblue'] = {29, 144, 255, 255},
	['firebrick'] = {177, 33, 33, 255},
	['floralwhite'] = {255, 249, 239, 255},
	['forestgreen'] = {33, 138, 33, 255},
	['fuchsia'] = {255, 0, 255, 255},
	['gainsboro'] = {219, 219, 219, 255},
	['ghostwhite'] = {247, 247, 255, 255},
	['gold'] = {255, 214, 0, 255},
	['goldenrod'] = {218, 165, 31, 255},
	['gray'] = {128, 128, 128, 255},
	['green'] = {0, 128, 0, 255},
	['greenyellow'] = {172, 255, 47, 255},
	['honeydew'] = {239, 255, 239, 255},
	['hotpink'] = {255, 105, 179, 255},
	['indianred'] = {205, 91, 91, 255},
	['indigo'] = {75, 0, 130, 255},
	['ivory'] = {255, 255, 239, 255},
	['khaki'] = {239, 230, 140, 255},
	['lavender'] = {230, 230, 249, 255},
	['lavenderblush'] = {255, 239, 244, 255},
	['lawngreen'] = {124, 251, 0, 255},
	['lemonchiffon'] = {255, 249, 205, 255},
	['lightblue'] = {172, 216, 230, 255},
	['lightcoral'] = {239, 128, 128, 255},
	['lightcyan'] = {223, 255, 255, 255},
	['lightgoldenrodyellow'] = {249, 249, 209, 255},
	['lightgray'] = {211, 211, 211, 255},
	['lightgreen'] = {144, 237, 144, 255},
	['lightpink'] = {255, 181, 193, 255},
	['lightsalmon'] = {255, 160, 121, 255},
	['lightseagreen'] = {31, 177, 170, 255},
	['lightskyblue'] = {135, 205, 249, 255},
	['lightslategray'] = {119, 135, 153, 255},
	['lightsteelblue'] = {175, 195, 221, 255},
	['lightyellow'] = {255, 255, 223, 255},
	['lime'] = {0, 255, 0, 255},
	['limegreen'] = {49, 205, 49, 255},
	['linen'] = {249, 239, 230, 255},
	['magenta'] = {255, 0, 255, 255},
	['maroon'] = {128, 0, 0, 255},
	['mediumaquamarine'] = {102, 205, 170, 255},
	['mediumblue'] = {0, 0, 205, 255},
	['mediumorchid'] = {186, 84, 211, 255},
	['mediumpurple'] = {147, 112, 219, 255},
	['mediumseagreen'] = {59, 179, 112, 255},
	['mediumslateblue'] = {123, 103, 237, 255},
	['mediumspringgreen'] = {0, 249, 154, 255},
	['mediumturquoise'] = {72, 209, 204, 255},
	['mediumvioletred'] = {198, 20, 133, 255},
	['midnightblue'] = {24, 24, 112, 255},
	['mintcream'] = {244, 255, 249, 255},
	['mistyrose'] = {255, 228, 225, 255},
	['moccasin'] = {255, 228, 181, 255},
	['navajowhite'] = {255, 221, 172, 255},
	['navy'] = {0, 0, 128, 255},
	['none'] = {0, 0, 0, 255},
	['oldlace'] = {253, 244, 230, 255},
	['olive'] = {128, 128, 0, 255},
	['olivedrab'] = {107, 142, 35, 255},
	['orange'] = {255, 165, 0, 255},
	['orangered'] = {255, 68, 0, 255},
	['orchid'] = {218, 112, 214, 255},
	['palegoldenrod'] = {237, 232, 170, 255},
	['palegreen'] = {151, 251, 151, 255},
	['paleturquoise'] = {175, 237, 237, 255},
	['palevioletred'] = {219, 112, 147, 255},
	['papayawhip'] = {255, 239, 212, 255},
	['peachpuff'] = {255, 218, 184, 255},
	['peru'] = {205, 133, 63, 255},
	['pink'] = {255, 191, 202, 255},
	['plum'] = {221, 160, 221, 255},
	['powderblue'] = {175, 223, 230, 255},
	['purple'] = {128, 0, 128, 255},
	['red'] = {255, 0, 0, 255},
	['rosybrown'] = {188, 142, 142, 255},
	['royalblue'] = {65, 105, 225, 255},
	['saddlebrown'] = {138, 68, 18, 255},
	['salmon'] = {249, 128, 114, 255},
	['sandybrown'] = {244, 163, 96, 255},
	['seagreen'] = {45, 138, 86, 255},
	['seashell'] = {255, 244, 237, 255},
	['sienna'] = {160, 82, 45, 255},
	['silver'] = {191, 191, 191, 255},
	['skyblue'] = {135, 205, 235, 255},
	['slateblue'] = {105, 89, 205, 255},
	['slategray'] = {112, 128, 144, 255},
	['snow'] = {255, 249, 249, 255},
	['springgreen'] = {0, 255, 126, 255},
	['steelblue'] = {70, 130, 179, 255},
	['tan'] = {209, 179, 140, 255},
	['teal'] = {0, 128, 128, 255},
	['thistle'] = {216, 191, 216, 255},
	['tomato'] = {255, 98, 70, 255},
	['transparent'] = {0, 0, 0, 255},
	['turquoise'] = {63, 223, 207, 255},
	['violet'] = {237, 130, 237, 255},
	['wheat'] = {244, 221, 179, 255},
	['white'] = {255, 255, 255, 255},
	['whitesmoke'] = {244, 244, 244, 255},
	['yellow'] = {255, 255, 0, 255},
	['yellowgreen'] = {154, 205, 49, 255},
}

--add a new color into the color table
function npt.CreateColor (colorName, colorTable)
	if (type (colorName) ~= "string") then
		return npt.DebugMessage ("CreateColor", "require a string as #1 argument.", 3)
	end
	
	if (type (colorTable) ~= "table") then
		return npt.DebugMessage ("CreateColor", "require a table as #2 argument.", 3)
	end
	
	colorTable [1] = colorTable [1] or 255
	colorTable [2] = colorTable [2] or 255
	colorTable [3] = colorTable [3] or 255
	colorTable [4] = colorTable [4] or 255
	
	npt.colorTable [lower (colorName)] = colorTable
	
	return colorTable
end

--get a color from the color table, can also use: local myColorRed = npt.colorTable ["red"]
--default color is optional
function npt.GetColor (colorName, defaultColor)
	local color = npt.colorTable [lower (colorName)]
	
	if (not color and type (defaultColor) == "table") then
		return defaultColor
	end
	
	return color
end

--check if the color passed is valid, can be a table or a string with the color name
--sometimes passing nil in the color makes the defaultColor also to be nil, this is FiveM related
function npt.ValidateColor (color, defaultColor)

	if (type (color) == "string") then
		--the color is a color name
		color = lower (color)
		local colorTable = npt.colorTable [color]
		
		if (not colorTable) then
			--color not found, use the default color and trow a warning
			npt.DebugMessage ("ValidadeColor", "color name not found.", 2)
			return defaultColor
		else
			return colorTable
		end
		
	elseif (type (color) == "table") then
		if (not color [1] or not color [2] or not color [3]) then
			npt.DebugMessage ("ValidadeColor", "invalid color table.", 2)
			return defaultColor
		
		elseif (not color [4]) then
			color [4] = 255
		end
		
		return color	
	else
		return defaultColor
	end
end