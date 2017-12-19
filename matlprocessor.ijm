/* Hayden Knapp
 *  
 *  Dependent on ImageJ stitching plugin founded by Stephan Preibisch
 *  	https://imagej.net/Image_Stitching
 *  
 *  Use this to stitch irregular OIB files together with a MATL file.
 *  
 *  Note: This macro does dumb configuration so consider using the offset macro to move them so they overlap correctly
 *  
 *  Rough pseduocode on how this works:
 *  
 *  matlPath <- user specifies the MATL file location
 *  imagePath <- user specifies the image repository
 *  pixelLength <- user specifies the pixel length of each image (might be able to find this automatically)
 *  pattern <- user specifies a pattern for the image names (the ones in the MATL file are NOT correct for some odd reason)
 *  
 *  matlData <- the MATL file is opened
 *  width, height <- extract from matlData
 *  
 *  tileConfig <- a string that will later become tileConfiguration.registered.txt is created
 *  
 *  imagesProcessed <- 0, the number of image entries we have added to tileConfig (goal: width * height = n)
 *  
 *  for every image entry in the MATL file
 *  	xval <- get from matlData
 *  	yval <- get from matlData
 *  	
 *  	i <- xval + yval * width, the image's spot in the final stitched image as a 1D array
 *  	
 *  	while imagesProcessed < i + 1
 *  		save dummy images of name tiff{iiii}.tif, where iiii is the number of imagesprocessed + 1
 *  		add entry in the tileConfig string of coordinates x=pixelLength*imagesProcessed%width, y=pixelLength*imagesProcessed/width
 *  			with the name of the image saved above
 *  		increment imagesProcessed
 *  
 *  	add entry in the tileConfig string of coordinates x=pixelLength*imagesProcessed%width, y=pixelLength*imagesProcessed/width
 *  		with name of pattern with iiii set to imagesprocessed + 1
 *  	increment imagesProcessed
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

/* Fills the {ii} section of a string in with a number and returns it. */ 
function insertBetween(str, num) {
	/* The new string that will be returned */
	var newString = "";

	/* Add the front part, before the { */
	newString = substring(str, 0, indexOf(str, "{"));

	/* Correct the length of the {ii} part */
	num = correctLength(toString(num), indexOf(str, "}") - indexOf(str, "{") - 1);

	newString = newString + num;

	newString = newString + substring(str, indexOf(str, "}") + 1, lengthOf(str));
	
	return newString;
}

/* Get an entry for the tile config file given x, y and the name of the new picture. */
function getEntry(x, y, name) {
	return name + "; ; (" + x + ", " + y + ", 0.0)\n";
}

macro "MATL stitching"{
 	/* Specify location of the MATL files */
 	var matlPath = getString("Enter the path and name of the MATL file.", matlPath);

 	/* Specify location of the image files */
 	var imagePath = getString("Enter the path of the images with the last '/'", imagePath);

	
	/* Get the pixel length of each image. (consider removing and replacing with an automatic function. */
	var pixelLengthTemp = getString("Enter the pixel length of each image (or height as they should be square). E.g. 1024.", pixelLengthTemp);
	var pixelLength = parseInt(pixelLengthTemp);
	
	/* Get the pattern of the OIB files. Should be something like Image00{ii}_01.oib */
	var pattern = getString("Enter the pattern of the existing image names. E.g. Image00{ii}_01.oib.", pattern);

	/* Read in the matl data */
	var matlData = File.openAsString(matlPath);

	/* Read in the width and height of the image. */
	var width = parseInt(substring(matlData, indexOf(matlData,"XImages>") + 8, indexOf(matlData,"</XImages>")));
	var height = parseInt(substring(matlData, indexOf(matlData,"YImages>") + 8, indexOf(matlData,"</YImages>")));

	/* This is going to be our final output */
	var tileConfig = "dim = 3\n";

	/* Create a dummy black image so we can save it. */
	open(imagePath + insertBetween(pattern, 1));
	run("Set...", "value=0 stack");

	/* The current amount of images added to the tileConfig variable. */
	var imagesProcessed = 0;

	/* index to search from that only moves forward and tells us when to stop looking. */
	var searchIndex = 0;

	/* The index of the oib file that is currently being added. */
	var oibNum = 0;

	/* The index of the tiff file that is currently being added. */
	var tifNum = 1;
	
	/* Only continues to search if there is data left to */
	while (indexOf(matlData, "<ImageInfo>", searchIndex) > -1) {
		/* Fetch the x and y tile cooridinates of the next OIB file. */
		var xval = parseInt(substring(matlData, indexOf(matlData, "<Xno>", searchIndex) + 5, indexOf(matlData, "</Xno>", searchIndex)));
		var yval = parseInt(substring(matlData, indexOf(matlData, "<Yno>", searchIndex + 10) + 5, indexOf(matlData, "</Yno>", searchIndex + 10)));
		searchIndex = indexOf(matlData, "</Yno>", searchIndex + 10);

		/* The images index inside of the whole combinations. */
		var index = xval + width * yval;

		/* Fill in blank spots with empty images and add to result. Essentially a catch up. */
		while (imagesProcessed < index) {
			/* Make the name of the dummy image and add it to the config file. */
			var dummyXval = parseInt(imagesProcessed / width - 0.5) * pixelLength;
			var dummyYval = imagesProcessed % width * pixelLength;
			var dummyName = insertBetween("tiff{iiii}.tif", tifNum);
			tifNum++;
			var dummyEntry = getEntry(dummyXval, dummyYval, dummyName);
			tileConfig += dummyEntry;
			/* Save the dummy image to disk under the same name. */
			saveAs("Tiff", imagePath + dummyName);
			imagesProcessed++;
		}
		/* Increment the number of the oib. */
		oibNum++;
		var newEntry = getEntry(xval * pixelLength, yval * pixelLength, insertBetween(pattern, oibNum));
		tileConfig += newEntry;

		imagesProcessed++;
	}
	while(imagesProcessed < width * height) {
			/* Make the name of the dummy image and add it to the config file. */
			var dummyXval = parseInt(imagesProcessed / width - 0.5) * pixelLength;
			var dummyYval = imagesProcessed % width * pixelLength;
			var dummyName = insertBetween("tiff{iiii}.tif", tifNum);
			tifNum++;
			var dummyEntry = getEntry(dummyXval, dummyYval, dummyName);
			tileConfig += dummyEntry;
			/* Save the dummy image to disk under the same name. */
			saveAs("Tiff", imagePath + dummyName);
			imagesProcessed++;
	}
	print(tileConfig);






















