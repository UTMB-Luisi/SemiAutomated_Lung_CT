
macro "Measure_HU_From_CC_Image" {
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
	setSlice(500);
	Stack.getDimensions(iWidth, iHeight, iChannels, iMAXslice, iFrames);
	waitForUser("Bottom of lung");
	Stack.getPosition(channel, slice, frame);
	getStatistics(area, mean, min, max, std, histogram);	
	//print(min +" " + max);
	Dialog.create("Set Parameters");
	Dialog.addNumber("Connected Component number", max);
	Dialog.addNumber("Start Slice ", slice);
	Dialog.addNumber("End Slice", iMAXslice);
	Dialog.show();
	CC = Dialog.getNumber();
	startSlice = Dialog.getNumber();
	endSlice = Dialog.getNumber();
	//CC = getNumber("CC to keep: ", max);
	setThreshold(CC, CC);
	run("Convert to Mask", "method=Default background=Light black");
	run("Erode", "stack");
	//run("Fill Holes", "stack");
	CC_id = getImageID(); 
	CC_Name = getTitle();
	
	path = getDirectory("Image");
	CT_Image = replace(CC_Name, "CC_", "");
	CT_Image = path + replace(CT_Image, ".tiff", ".ct.img.hdr");
	print(CT_Image);
	if (File.exists(CT_Image) ){
		run("Bio-Formats Importer", "open=[" + CT_Image + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	}else {
		rawFile = File.openDialog("Select CT Data");
		run("Bio-Formats Importer", "open=[" + rawFile + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	}
	CT_ID = getImageID(); 


	
	HU_Bin(CT_ID, CC_Name, -1000, -700, startSlice, endSlice);

	HU_Bin(CT_ID, CC_Name, -700, -600, startSlice, endSlice);

	HU_Bin(CT_ID, CC_Name, -600, -500, startSlice, endSlice);

	HU_Bin(CT_ID, CC_Name, -500, -400, startSlice, endSlice);

	HU_Bin(CT_ID, CC_Name, -400, -300, startSlice, endSlice);
	
	HU_Bin(CT_ID, CC_Name, -300, -200, startSlice, endSlice);

	HU_Bin(CT_ID, CC_Name, -200, 0, startSlice, endSlice);

	name = replace(CC_Name, ".tiff", ".csv");
	saveAs("Results", path + name);
	
	run("Merge Channels...", "c1=-1000--700 c2=-700--600 c3=-600--500 c4=-500--400 c5=-400--300 c6=-300--200 c7=-200-0 create");
	//run("Channels Tool...");
	run("Make Composite");
	saveAs("Tiff", path + "Lung_Bin_" + CC_Name);
}
function HU_Bin(CT_ID, CC_Name, HUStart, HUEnd, sliceStart, sliceEnd) {
	selectImage(CT_ID);
	run("Duplicate...", "duplicate");
	//setThreshold(-32768, -700);
	setThreshold(HUStart, HUEnd);
	run("Convert to Mask", "method=Default background=Light black");
	Bin_ID = getImageID();
	Bin_Name = getTitle();
	
	
	imageCalculator("AND create stack", Bin_Name, CC_Name);
	Mask_ID = getImageID();
	
	rename(HUStart + "-" + HUEnd);

	//run("Set Measurements...", "area perimeter area_fraction stack display redirect=None decimal=3");
	run("Set Measurements...", "area perimeter integrated area_fraction stack display redirect=None decimal=3");
	for(i = sliceStart; i < sliceEnd; i++){
		setSlice(i);
		run("Measure");
	}
	
	selectImage(Bin_ID);
	close();
}