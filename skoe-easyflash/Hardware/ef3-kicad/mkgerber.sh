#!/bin/sh

PROJECT=ef3-v1.3

rm -rf $PROJECT-gerber
mkdir $PROJECT-gerber
mv *.gtl $PROJECT-gerber/TopCopper.gtl
mv *.gbl $PROJECT-gerber/BottomCopper.gbl
mv *.gts $PROJECT-gerber/TopSolderMask.gts
mv *.gbs $PROJECT-gerber/BottomSolderMask.gbs
mv *.gbr $PROJECT-gerber/Outline.gbr
mv *.gto $PROJECT-gerber/TopSilkScreen.gto
mv *.drl $PROJECT-gerber/Drill.drl

rm $PROJECT-gerber.zip

cd $PROJECT-gerber
zip -u ../$PROJECT-gerber.zip *
cd ..

exit
#########################################

Generating GERBER Files 

Most professional board houses need GERBER files to produce your board. Kicad can easily generate theses, and also has a nice viewer that will allow you to double check that your board looks right. To generate them, click the Plot icon which pulls up the plot screen. You'll want to use the following options: 

Layers 
Copper 
Component 
SilkS Cmp 
Mask Copp 
Mask Cmp
?Edges?

Other Settings 
Leave the print $foo settings alone... most should be off and defaults are fine 
Plot format: GERBER
Plot origin: absolute
?? Spot min: 0.015 (default)
Lines Width: 0.001 (default) 
Plot silk screen texts

Click Save Options so you dont have to re-do it, and then click Plot. It will create .pho files in your board directory which are your GERBER files. You will need to send these to your manufacturer. Feel free to open them with the gerbview program Kicad provides. They look cool =) 

Generating Drill Files 
Bring up the Plot dialog again. This time, you will want to click the Create Drill File option. This will bring up another dialog. The settings in this dialog are very important. You will want to use: 

Units: inches 
Zeros Format: suppress trailing zeros 
?? Precision: 2.4 
Drill origin: absolute 
Drill sheet: none 
?? Via drill: .025 (default) 
Mirror Y axis: off 
Minimal header: on 

Then click the execute button. Your drill file will be created. It will have the extension .drl Its a text file, so feel free to take a look at it and marvel at the wonder of automation. 

Congratulations, you just prepared your board for manufacture! Generally you will create a zip file with the .pho and .drl files and send that off to the manufacturer. batchpcb.com has a great web tool that will run DRC checks and report any errors back to you. It is very handy indeed.
