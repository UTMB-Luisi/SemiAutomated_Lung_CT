macro "MeasureHU" {
	/*
	 * 
	 * Copyright 2023 Jonathan Luisi 
	 * 
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 * 
	 *   http://www.apache.org/licenses/LICENSE-2.0 
	 *   
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 * 
	 * 
	 * README: 
	 * 
	 */
	run("Clear Results");
	imageName = getTitle(); 
	imageID = getImageID();
	dir = getDirectory("image");
	Stack.getDimensions(iWidth, iHeight, iChannels, iMAXslice, iFrames);
	if (iWidth != 200) {
		//crop
		makeRectangle(207, 127, 200, 200);
		setTool("rectangle");
		waitForUser("Select Crop Area");
		roiManager("Add");
		roinum = roiManager("count");
		roiManager("Select", roinum -1);
		roiManager("Rename", "Crop_" + imageName);
		run("Crop");
	}

	Stack.getPosition(channel, slice, frame);
	OrthoProjecter(imageID, slice, dir);
	
	selectImage(imageID);
	Stack.setSlice(slice);
	run("Stack to RGB", "keep");
	//run("Duplicate...", "duplicate slices=" slice);
	//run("Stack to RGB");
	
	setTool("wand");
	run("Wand Tool...", "tolerance=3 mode=4-connected");
	//run("Properties... ", "  stroke=red width=.5");
	waitForUser("select area to measure");
	
	roiManager("Add");
	roinum = roiManager("count");
	roiManager("Select", roinum -1);
	roiName = "slice" + slice + "_" + imageName;
	roiManager("rename", roiName);
	roiManager("save selected", dir + roiName + ".roi");
	saveAs("TIFF", dir + roiName);
	selectWindow(imageName);
	run("Set Measurements...", "area perimeter integrated area_fraction stack display redirect=None decimal=3");

	MeasureSlice(imageID, slice);
	print(imageName + "\t slice: \t" + slice);
	
	MeasureSlice(imageID, slice -5);
	
	MeasureSlice(imageID, slice + 5);
/*	
	roinum = roiManager("count");
	roiManager("Select", roinum -1);
	for (i = 1; i < 7; i++) {
		Stack.setChannel(i);
		run("Measure");
	}
*/
saveAs("Results", dir + "slice_" + slice + "_" + imageName + ".csv");
}

function OrthoProjecter(imageID, sliceID, directory) {
	
	selectImage(imageID);
	imgName = getTitle();
	
	Stack.getDimensions(width, height, channels, MAXslice, frames);
	run("Orthogonal Views"); 
	//selectImage(imageID);
	Stack.setOrthoViews(floor(width/2), floor(height/2) , sliceID);
	

	selectImage(imageID);
	
	list = getList("image.titles");
	// print( list.length);
	 for (i=0; i<list.length; i++){
	 	//print("testing: " + list[i]);
	 	if ( startsWith(list[i] , "YZ"))
	 	{
	 		YZ = list[i];
	 		//print ("found " + YZ);
	 	}
	 	else if ( startsWith(list[i] , "XZ"))
	 	{
	 		XZ = list[i];
	 		//print ("found " + XZ);
	 	}
	 }
	//run("Reslice [/]...", "output=1.900 start=Top avoid");
	//selectWindow("Reslice of C22-093_OD-Pre");
	selectWindow(YZ);
	run("Overlay Options...", "stroke=yellow width=3 fill=none set apply");
	run("Flatten");
	YZ = getTitle();
	
	selectWindow(XZ);
	run("Overlay Options...", "stroke=yellow width=3 fill=none set apply");
	run("Flatten");
	XZ = getTitle();
	
	
	selectWindow(imgName);
	run("Overlay Options...", "stroke=yellow width=3 fill=none set apply");
	run("Flatten", "slice");
	flat = getTitle();
	
	run("Combine...", "stack1=[" + flat + "] stack2=[" + YZ + "]");
	run("Combine...", "stack1=[Combined Stacks] stack2=[" + XZ + "] combine");
	run("Subtract...", "value=20");
	//run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None*");
	saveAs("TIFF", directory +"Ortho_slice-" + sliceID + "-" + imgName);
}

function MeasureSlice(imageID, slice) {
		
	selectImage(imageID);
	imageName = getTitle(); 
	//Stack.setSlice(slice);
	run("Duplicate...", "title=" + slice + "_" + imageName + " duplicate slices=" + slice);
	sliceID = getImageID();
	roinum = roiManager("count");
	roiManager("Select", roinum -1);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	run("Select None");
	Stack.getDimensions(iWidth, iHeight, iChannels, iMAXslice, iFrames);
	for (i = 1; i <= iChannels; i++) {
		selectImage(sliceID);
		Stack.setChannel(i);
		run("Measure");
	}
}

