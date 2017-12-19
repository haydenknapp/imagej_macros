/* Written for Biollogical Image processing
 * class Fall of 2017
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

/* This function returns a single string from a longer
 * string. This is a necessary function for now because I do not
 * know how to make arrays of strings, so they are for now
 * stored as one string.
 */
function getNameFromList(list, index, pattern) {
	// Subtract 2 for the curly brackets
	return substring(list, index * (lengthOf(pattern) - 2), index * (lengthOf(pattern) - 2) + lengthOf(pattern) - 2);
}

/* Assign a new filename with number, 0 to n-1, given
 * an x, y and width integer of the file within the
 * new set of images.
 */
function getNewName(x, y, width) {
	// The return string
	var newString = "";

	/* get number then convert to length 4 (assumption
	 * is that stitched images do not require more than
	 * 9999 images
	 */

	var ise = toString(x + y * width + 1);
	ise = correctLength(ise, 4);

	return "tiff" + ise + ".tif";
}

// insErt Between the brackets a string that corresponds to which number and removes brackets.
function insBet(str, num) {
	// The new string that will be returned
	var newString = "";

	// Add the front part, before the {
	newString = substring(str, 0, indexOf(str, "{"));

	newString = newString + num;

	newString = newString + substring(str, indexOf(str, "}") + 1, lengthOf(str));
	
	return newString;
}

macro "Irregular stitching"{
	var filepath = getString("Enter the filepath of the OIB files with the last /", filepath);
	var pattern = getString("Enter the pattern for the images(e.g. Image00{ii}_01.oib)", pattern);

	var matlFilepath = getString("Enter the filepath of the MATL file with the last along with the file name.", matlFilepath);
	var matlFile = File.openAsString(matlFilepath);

	/* Parse matl mosaic to get the width and height of the stitched image. */
	var width = substring(matlFile, indexOf(matlFile,"XImages>") + 8, indexOf(matlFile,"</XImages>"));
	var height = substring(matlFile, indexOf(matlFile,"YImages>") + 8, indexOf(matlFile,"</YImages>"));

	// Get a list of all the coordinates of the existing images
	/* Index of where we should be searching for new coordinates */
	var searchFrom = 1;		

	/* Location of the first images */
	var x, y;

	/* Make an array of xs and ys */
	var xsys = newArray(width * height * 2);
	var xsysi = 0;
	/* Amount of x and y pairs */
	var xsysn = 0;

	// Location of original images
	do {
		x = substring(matlFile, indexOf(matlFile, "<Xno>", searchFrom) + 5, indexOf(matlFile, "</Xno>", searchFrom));
		y = substring(matlFile, indexOf(matlFile, "<Yno>", searchFrom + 10) + 5, indexOf(matlFile, "</Yno>", searchFrom + 10));
		xsys[xsysi] = x;
		xsysi++;
		xsys[xsysi] = y;
		xsysi++;
		xsysn++;
		searchFrom = indexOf(matlFile,"</Yno>", searchFrom + 1);
	} while (searchFrom > 0 && indexOf(matlFile, "<Yno>", searchFrom + 10) + 5 < indexOf(matlFile, "</Yno>", searchFrom + 10));
	
	// Make a list of all of the names of the old files. Comes in the form of all strings combined seperated by spaces
	var oldFiles = "";

	// What will replace the {ii} section and the length of the ii
	var ii;
	var iin = indexOf(pattern, "}") - indexOf(pattern, "{") - 1;

	// Add the old filenames to the list
	for (i = 1; i <= xsysn; i++) {
		//oldFiles = oldFiles + " " + insBet(pattern, correctLength(toString(i), iin));
		oldFiles = oldFiles + insBet(pattern, correctLength(toString(i), iin));
	}

	// Save all of the good files as tiffs under a new name. Maybe, tiff{iiii}.tf is a good start
	for (i = 0; i < xsysi; i = i + 2) {
		open(filepath + getNameFromList(oldFiles, i / 2, pattern));
		saveAs("Tiff", filepath + getNewName(parseInt(xsys[i]), parseInt(xsys[i+1]), width));
	}

	// Now find the names of the files that need to be added as blacks
	//List of missing coordinates. It is in the same form as xsys
	var newCoordLen = (parseInt(width) * parseInt(height) - i / 2) * 2 + 2;
	var miss = newArray(newCoordLen);
	var missi = 0;

	xsysi = 0;
	for (i = 0; i < width * height; i++) {
		// x and y the for loop now about
		x = i % width;
		y = parseInt(i / width - 0.5);
		// If this at the current xsys then we will not add it but
		// will increment xsysi
		if (xsys[xsysi] == x && xsys[xsysi + 1] == y) {
			xsysi = xsysi + 2;
		}
		else {
			miss[missi] = x;
			missi++;
			miss[missi] = y;
			missi++;
		}
	}
	// Open a random oib file from the original files and make it black
	open(filepath + getNameFromList(oldFiles, 0, pattern));
	run("Set...", "value=0 stack");
	// Make new filenames for the blank images
	var blankNames = "";
	for (i = 0; i < newCoordLen - 2; i += 2) {
		saveAs("Tiff", filepath + getNewName(miss[i], miss[i + 1], width));
	}
	
}