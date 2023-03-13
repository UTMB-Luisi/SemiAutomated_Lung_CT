macro "ConnectedLungRegions" {
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
		OutputDir = tmpdir;
		/*	OutputDir = tmpdir+"CC_tiff"+File.separator;
		if (!File.exists(OutputDir)){
			File.makeDirectory(OutputDir);
			//print("Directory Created", OutputDir);
		}	*/
		
		counter = 0; 
		print ("File List size= " + list.length);
		for (i=0; i<list.length; i++){
			//convert  
			if (endsWith(list[i], ".hdr")){
					getDateAndTime(year, month, week, day, hour, min, sec, msec);
					print("file " + list[i] + " number: " + i + "Time"+toString(hour)+":"+toString(min));
					startTime = getTime();
					run("Bio-Formats Importer", "open=[" + tmpdir + list[i] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
					CCImage();
					name = replace(list[i], ".ct.img.hdr", ".tiff");
					saveAs("Tiff", OutputDir + "CC_" + name);
					close();
					stopTime = getTime();
					print("CC RunTime: " + (stopTime - startTime)/1000);
			}
		}
	}else {
		imgName = getTitle();
		CCImage();
		rename(imgName + "_CC");
	}	//end signle image 
	//print("finished: " + getTime()/1000);
	getDateAndTime(year, month, week, day, hour, min, sec, msec);
	print("Finished at Time"+toString(hour)+":"+toString(min));
}	//end macro 

function CCImage() {
	//imgName = getTitle();
	run("Duplicate...", "duplicate");
	setThreshold(-32768, -200);
	run("Convert to Mask", "method=Default background=Light black");
	
	//run("Convert to Mask", "method=Default background=Light");//
	//run("Invert LUT");
	//run("Find Connected Regions", "allow_diagonal display_one_image display_results regions_for_values_over=100 minimum_number_of_points=100 stop_after=-1");
	myImageID = getImageID(); 
	Stack.getDimensions(width, height, channels, MAXslice, frames);
	print("frames " + frames);
	slice = 1;
	setSlice(slice);
	do {
			selectImage(myImageID);
			doWand(5, 5);
			floodFill(5, 5);
			slice = slice + 1; 
			setSlice(slice);
	
		}while (slice < MAXslice );
	//print("max: " + MAXslice + " Slice" + slice);
	run("Find Connected Regions", "allow_diagonal display_one_image display_results regions_for_values_over=100 minimum_number_of_points=10000 stop_after=-1");
	/*
	setTool("point");
	waitForUser("Select a Point");
	//makePoint(257, 265);
	run("Find Connected Regions", "allow_diagonal display_one_image display_results start_from_point regions_for_values_over=100 minimum_number_of_points=10000 stop_after=-1");
	*/
	
	//rename(imgName + "_CC");
}