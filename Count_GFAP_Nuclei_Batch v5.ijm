/* This macro needs a 3 colors image
 *  C1 =Nuclei C2= GFAP C3= CTIP2
 * It detectes nuclei on C1 C3 with StarDist
 * counts nuclei and CTIP2 on a large ROI
 * Make a mask of GFAP with C2
 * and count the number of positive nuclei in a CTIP2 rich ROI
 * it gives the number of nuclei / CTIP2 
 * positive nuclei in the large ROI and in the CTIP2 rich ROI
 *  
 */



var indexesROI=newArray();


macro "Count_GFAP_Nuclei  [F1]" {

run("Set Measurements...", "area mean shape display redirect=None decimal=3");
print ("Image    \t     nbNuclei in Cortex     \t     nbPositive in Cortex     \t     nbNuclei In Layer 5     \t     NbPositive Nuclei in Layer 5     \t     nbCTIP2    \t    NbCTIP2 in Layer5");


if (isOpen("ROI Manager")) roiManager("reset");
if(isOpen("Results")) run("Clear Results");

In=getDirectory("Folder for Images");
out=getDirectory("Folder to save results");

list = getFileList(In);

  for (j=0; j<list.length; j++) {
  	  	
		open(In+list[j]);

shortName=File.nameWithoutExtension;
title=getTitle();rename("Image");
newTitle=("Image");


run("Make Composite");
	
	for (i = 1; i <= nSlices; i++) {
   		 	setSlice(i);
    		run("Enhance Contrast", "saturated=0.35");
		}

setTool("rectangle");
run("Select All");
waitForUser("Draw ROI covering the cortex and click OK");
run("Crop");
run("Select All");
roiManager("Add");run("Select None");

waitForUser("Draw ROI covering Layer5  (CTIP2 rich)  and click OK");
roiManager("Add");run("Select None");

setTool("polygon");
waitForUser("Draw ROI covering blood vessels  add to ROI manager and click OK");
nROI=roiManager("count");
roiManager("Deselect");
roiManager("Remove Slice Info");
run("Split Channels");


filter ("C2-Image","Median","Gaussian Blur",1,20);
run("Duplicate...", "title=GFAP");
setAutoThreshold("Triangle dark");
waitForUser("Check Threshold");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Options...", "iterations=2 count=1 black do=Open");

/////////////// Remove Blood vessels fro the different images
cleanBloodVessels("GFAP",nROI);
cleanBloodVessels("C3-Image",nROI);
cleanBloodVessels("C1-Image",nROI);


///////////////////////////////// Measures Number of CTIP2 total
selectWindow("GFAP");
run("Analyze Particles...", "size=10-Infinity pixel circularity=0.00-1 show=Masks in_situ");

roiManager("Save", out+shortName+".zip");

///////////////////////////// STARDist Detection of CTIP2
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'C3-Image', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'5.0', 'percentileTop':'95.0', 'probThresh':'0.5', 'nmsThresh':'0.5', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
rename("CTIP2");
//setBatchMode(true);
///////////// Number of CTIP2 in whole ROI
nCTIP2=roiManager("count");


///////////////////////////////// Number of CTIP2 in layer5
run("From ROI Manager");
roiManager("reset");
roiManager("Open", out+"RoiSet.zip");
roiManager("select", 1);
run("Duplicate...", "title=Layer5CTIP2 duplicate");
CTIP2inLayer5=(Overlay.size);
close("Layer5CTIP2");

roiManager("reset");
//setBatchMode(false);

///////////////////////////// STARDist Detection of Nuclei
selectWindow("C1-Image");
run("Gaussian Blur...", "sigma=1");
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'C1-Image', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'5.0', 'percentileTop':'95.0', 'probThresh':'0.5', 'nmsThresh':'0.5', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
rename("Nuclei");run("From ROI Manager");

///////////// Number of Nuclei in whole ROI
nNuclei=roiManager("count");


///////////// Number of Positive Nuclei in whole ROI
selectWindow("GFAP");
run("From ROI Manager");
roiManager("Measure");



nGlial=getCol("Mean");
selectWindow("Results");
Table.sort("Mean");
wait(100);

IJ.renameResults("Cortex_Positive_Nuclei");


positiveGlial=0;
	
	for (i = 0; i < nGlial.length; i++)  if (nGlial[i]>0) positiveGlial=positiveGlial+1;
	
	
///////////////////////////////// Number of Nuclei in layer5
selectWindow("GFAP");
run("16-bit");

run("Merge Channels...", "c1=Nuclei c2=GFAP c3=C1-Image c4=C2-Image create"); rename("Nuclei_Stack");
run("From ROI Manager");
roiManager("reset");
roiManager("Open", out+"RoiSet.zip");
roiManager("select", 1);
run("Duplicate...", "title=Layer5Nuclei duplicate");
NucleiInLayer5=(Overlay.size);



/////////////////////// Value of Nuclei in layer5
roiManager("reset");
run("To ROI Manager");
setSlice(2);
roiManager("Measure");
GFAP=getCol("Mean");
//close("Layer5Nuclei");

positiveGFAPLayer5=0;
	
	for (i = 0; i < GFAP.length; i++)  if (GFAP[i]>0) positiveGFAPLayer5=positiveGFAPLayer5+1;

////////////////// Print Results
print (title+"     \t     "+nNuclei+"     \t     "+positiveGlial+"     \t     "+NucleiInLayer5 +"     \t     "+positiveGFAPLayer5+"     \t     "+nCTIP2+"     \t     "+CTIP2inLayer5);


selectWindow("C3-Image");
rename("CTIP2_Ori");

run("Merge Channels...", "c1=CTIP2_Ori c2=CTIP2 create");
Stack.setPosition(1,1,1); run("Red");
Stack.setPosition(2,1,1); run("Green");

saveAs("Tiff", out+"CTIP2_"+title);	


selectWindow("Nuclei_Stack");
Stack.setPosition(1,1,1); run("Red");
Stack.setPosition(2,1,1); run("Green");


Stack.setActiveChannels("1100");

for (i = 1; i <= nSlices; i++) {
   		 	setSlice(i);
    		run("Enhance Contrast", "saturated=0.35");
		}
saveAs("Tiff", out+"Nuclei_"+title);	

value=getCol("Mean");

for (i = 0; i < value.length; i++) {
 		roiManager("select", i);
 		roiManager("Rename", i+1);
 		}




for (i = indexesROI.length-1; i >=0; i--)  if (indexesROI[i]==0) {roiManager("select", i);roiManager("delete");}

selectWindow("Layer5Nuclei");	
saveAs("Tiff", out+"Layer5Nuclei_"+title);	

selectWindow("Results");saveAs("Results", out+shortName+"_Layer5.tsv");run("Close");
selectWindow("Cortex_Positive_Nuclei");saveAs("Results", out+shortName+"_Cortex.tsv");run("Close");
roiManager("reset");	
run("Close All");		

}
selectWindow("Log");
saveAs("Text", out+shortName+".txt");
}selectWindow("Results");

function getCol(s) {
  a=newArray(nResults);
  for(i=0; i<a.length; i++) a[i]=getResult(s,i);
  return a;
}


function cleanBloodVessels(image,ROInumber) {

selectWindow(image);
if (ROInumber>2) for (i = 2; i < ROInumber; i++) {
	setForegroundColor(0, 0, 0);
	roiManager("select", i);	
	run("Fill", "slice");
	run("Select None");
		}}


function filter (image,filter1,filter2,size1,size2) {
	selectWindow(image);
	run("Duplicate...", "title=1");
	run("Duplicate...", "title=2"); 
	if (filter1=="Median"){
		selectWindow("1");run(filter1+"...","radius="+size1);}
	if (filter1=="Gaussian Blur"){
		selectWindow("1");run(filter1+"...","sigma="+size1);} 

	if (filter2=="Median"){
		selectWindow("2");run(filter2+"...","radius="+size2);}
	if (filter2=="Gaussian Blur"){
	selectWindow("2");run(filter2+"...","sigma="+size2);} 

	imageCalculator("Subtract","1","2");
	selectWindow("2"); close();
	selectWindow(image);close();
	selectWindow("1"); rename (image);
}



