
macro "CT_AutoHU_SelectBin" {
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
	Dialog.create("HU Bin Modes");
	Method = newArray("Default", "MOD", "Range","Cancel");
  	Dialog.addRadioButtonGroup("Select HU Bin", Method, 4, 1, "Default");
  	Dialog.addNumber("Min", -1000);
  	Dialog.addNumber("Max", 1);
  	Dialog.addNumber("Bin", 200);
  	Dialog.show();

  	method = Dialog.getRadioButton();
  	if (method == "Cancel") {
  		exit("Canceled");
  	}
  	min = Dialog.getNumber();
  	max = Dialog.getNumber();
  	bin = Dialog.getNumber();
  	
	list = getList("image.titles");
	if (list.length==0){	
		
		// get dir
		tmpdir= getDirectory("Choose a Directory");
		if (!File.exists(tmpdir))
		{
			exit();
			// directory error no point
		}
		list = getFileList(tmpdir);
		
		
		setBatchMode(true);
		
		OutputDir = tmpdir+"Output_Vol_tiff"+File.separator;
		if (!File.exists(OutputDir)){
			File.makeDirectory(OutputDir);
			//print("Directory Created", OutputDir);
		}
		
		counter = 0; 
		print ("File List size= " + list.length);
		for (i=0; i<list.length; i++){
			//convert .oct files 
			if (endsWith(list[i], ".hdr")){
					print("file " + list[i] + " number: " + i);
					run("Bio-Formats Importer", "open=[" + tmpdir + list[i] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
					if (method == "Default") {
						setDefaultBin();
					}
					else if (method == "MOD") {
						setModBin();
					}	//if mod
					else{
						HUbinRange(min, max, bin);
					}
					name = replace(list[i], ".ct.img.hdr", ".tiff");
					saveAs("Tiff", OutputDir + method +"_" + name);
					close();
			}
		}
	}else {
		if (method == "Default") {
			setDefaultBin();
		}	//if default
		else if (method == "MOD") {
			setModBin();
		}	//if mod
		else{
			HUbinRange(min, max, bin);
		}	//set by range 
		
	}	//end signle image 

	print("finished: "); 
}	//end macro 

function setDefaultBin(){
	myImageID = getImageID(); 
	imgName = getTitle();
	
	HU_Bin(myImageID, 1, -1000, -500);

	HU_Bin(myImageID, 2, -500, -400);

	HU_Bin(myImageID, 3, -400, -300);

	HU_Bin(myImageID, 5, -300, -200);

	HU_Bin(myImageID, 6, -200, 0);

	selectImage(myImageID); 
	run("Enhance Contrast...", "saturated=0 process_all use");
	run("8-bit");
	
	rename("C4");
	run("Channels Tool...");
	run("Merge Channels...", "c1=C1-HU-1000to-500 c2=C2-HU-500to-400 c3=C3-HU-400to-300 c4=C4 c5=C5-HU-300to-200 c6=C6-HU-200to0 create");
	rename(imgName);
}

function HUbinRange(min, max, bin) {
	myImageID = getImageID(); 
	imgName = getTitle();
	print("\\Clear");
	HUStart = min;
	channel = 1;
	channelNameList = "";
	
	while (HUStart + bin < max) {
		//
		if (channel != 4) {
			HUEnd = HUStart + bin;
			HU_Bin(myImageID, channel, HUStart, HUEnd);
			ChannelName = "C"+ channel + "-HU" + HUStart + "to" + HUEnd;
			channelNameList = channelNameList + "c" + channel + "=" + ChannelName + " ";
			print(channelNameList);
			HUStart = HUEnd;
		}else {
			// C4 
			channelNameList = channelNameList + "c4=C4 ";
		}
		
		channel = channel +1;
	}	//end while 
	selectImage(myImageID); 
	run("Enhance Contrast...", "saturated=0 process_all use");
	run("8-bit");
	
	rename("C4");
	run("Channels Tool...");
	run("Merge Channels...", channelNameList + " create");
	rename(imgName);
}	//end function hubinrange 

function setModBin(){
	myImageID = getImageID(); 
	imgName = getTitle();
	
	HU_Bin(myImageID, 1, -1000, -700);

	HU_Bin(myImageID, 2, -700, -600);

	HU_Bin(myImageID, 3, -600, -500);

	HU_Bin(myImageID, 4, -500, -400);

	HU_Bin(myImageID, 5, -400, -300);
	
	HU_Bin(myImageID, 6, -300, -200);

	HU_Bin(myImageID, 7, -200, 0);

	run("Channels Tool...");
	run("Merge Channels...", "c1=C1-HU-1000to-700 c2=C2-HU-700to-600 c3=C3-HU-600to-500 c4=C4-HU-500to-400 c5=C5-HU-400to-300 c6=C6-HU-300to-200 c7=C7-HU-200to0 create");
	rename("mod_" +imgName);
}
function HU_Bin(myImageID, channel, HUStart, HUEnd) {
	selectImage(myImageID);
	run("Duplicate...", "duplicate");
	setThreshold(HUStart, HUEnd);
	run("Convert to Mask", "method=Default background=Light black");
	rename("C"+ channel + "-HU" + HUStart + "to" + HUEnd);
}
