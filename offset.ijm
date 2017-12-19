/* Group 1
 *  Hayden Knapp, Akhil Koothal
 *  
 *  Email: hknapp4@kent.edu
 *  
 *  The purpose of this macro is to correct the dimensions determined by the ImageJ stitching
 *  plugin. Although the plugin generally works well, it is handy to be able to move all images
 *  by some pixel amount, or by a percentage.
 */

/* General Instructions:
 *  There are four steps to this plugin:
 *  1. You must have this macro installed along with the imagej stitching plugin
 *  2. Stitch your images; this creates the TileConfiguration.registered.txt file that
 *   is needed for this macro to work. Then, determine how many pixels the x and y coordinates
 *   are off by.
 *  3. Then, run this plugin, specifying the previously generated TileConfiguration.registered.txt
 *   file as the input. It will ask for x and y offsets along with the dimensions of the image
 *   in tiles.
 *  4. Now, the stitching plugin will have to be ran again, but this time with more specific
 *   instructions, or the result will be undesirable.
 *    a. Open the stitching plugin and specify under type, "Positions from file" then press OK.
 *    b. On this page, replace "TileConfiguration.txt" with "TileConfiguration.registered.txt"
 *    c. Also on this page, uncheck "Computer Overlap" then press OK.
 *   Note: there are other options on this page that have not been tested with this macro. The
 *   memory options do not seem to interfere, but use others at your own risk.
 *   
 *  At this point, the macro should have stitched the image together with the edited offsets.
 */


/* This function corrects the length of a number.
 * E.g. if a number is "1" but needs to be "0001",
 * (length = 4) then it will be adjusted as such.
 */
function correctLength(str, len) {
	while (lengthOf(str) < len) {
		str = "0" + str;
	}
	return str;
}

/* insErt Between the brackets a string that corresponds to which number and removes brackets. */
function insBet(str, num) {
	/* The new string that will be returned */
	var newString = "";

	/* correct num's length */
	length = indexOf(str, "}") - indexOf(str, "{") - 1;
	num = correctLength(toString(num), length);

	/* Add the front part, before the { */
	newString = substring(str, 0, indexOf(str, "{"));

	newString = newString + num;

	newString = newString + substring(str, indexOf(str, "}") + 1, lengthOf(str));
	
	return newString;
}


/* This is the main function of the macro. Here, the folder where the Tile Configuration files
 *  lie must be specified through a dialog box.
 */
macro "Offset Pixels"{
	/* This is the filepath of the TileConfiguration.registered.txt" */
	var filepath = getString("Enter the file name of the TileConfiguration.registered.txt file. Example: /home/username/Pictures/stitchedImage/ Be sure to add the last forward slash", filepath)

	/* get the pattern of the file. E.g. tif00{ii}.tif */
	var pattern = getString("Enter the pattern of the file. For example, tif00{ii}.tif", pattern);

	/* Tile config */
	var tileConfig = "TileConfiguration.registered.txt";
	
	/* Open the file */
	var reg = File.openAsString(filepath + tileConfig);
	
	/* These are the x and y offsets respectively that all of the images will be offset by. */
	var xoffset = getString("Enter the offset on the x axis", xoffset)
	var yoffset = getString("Enter the offset on the y axis", yoffset)

	/* These are the width and height of the image in amount of images (again, not pixels). */
	var width = getString("Enter the width (in images, not pixels)", width);
	var height = getString("Enter the width (in images, not pixels)", width);

	/* Seperate all of the images info into seperate strings.
	 *  This will be done width * height times
	 */
	var stringList = newArray(width * height);

	/* Inside of the opened file, search for the second semicolon, which corresponds
	 *  to the next entry in the list of coordinates. "curLoc" refers to the current
	 *  location that the loop is searching in.
	 */
	var curLoc = 0;
	for (var i = 0; i < width * height; ++i) {
		stringList[i] = substring(reg, indexOf(reg, "(", curLoc) + 1, indexOf(reg, ")", curLoc));
		curLoc = indexOf(reg, ")", curLoc) + 1;
	}

	/* Now, extract the floating point x and y values into two different arrays. */
	var xs = newArray(width * height);
	var ys = newArray(width * height);

	/* Use curLoc again to see where we are. */
	curLoc = 0;
	for (i = 0; i < width * height; ++i) {
		xs[i] = parseFloat(substring(stringList[i], 0, indexOf(stringList[i], ",", 0)));
		curLoc = indexOf(stringList[i], ",", 0) + 2;
		ys[i] = parseFloat(substring(stringList[i], curLoc, indexOf(stringList[i], ",", curLoc)));
		curLoc = 0;
	}

	/* This is where we will modify the previouslt aquired floating point numbers. The rule
	 *  is to only modify x if it is not in the 0th columnm and to only modify y if it is
	 *  not in the 0th row.
	 */
	for (i = 0; i < width * height; ++i) {
		if (i % width > 0) {
			xs[i] = xs[i] + xoffset * (i % width);
		}
		print(i % width * xoffset + ", " + parseInt(i / width - 0.5) * yoffset);
		if (i - width > 0) {
			ys[i] = ys[i] + (parseInt(i / width - 0.5) * yoffset);
		}
	}

	/* Inside of a string, organize the components of the file as they would be before the
	 *  modifications. Does not preserve comments
	 */
	var output = "";
	output = output + "dim = 3\n";
	for (i = 0; i < width * height; ++i) {
		output = output + insBet(pattern, i + 1) + "; ; ";
		output = output + "(" + toString(xs[i]) + ", " + toString(ys[i]) + ", 0.0)\n";
	}
	print(output);

	/* This saves the string to the file. */
	print(reg + tileConfig);
	File.saveString(output, filepath + tileConfig);
}








